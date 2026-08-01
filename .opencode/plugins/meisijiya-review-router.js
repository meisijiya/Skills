#!/usr/bin/env node
/**
 * meisijiya-review-router.js
 * OpenCode plugin: per-user-turn reminder to invoke review-class skills
 * after Write/Edit/apply_patch tool calls.
 *
 * Install:
 *   cp meisijiya-review-router.js ~/.config/opencode/plugins/
 *   # restart opencode (plugins do NOT auto-reload)
 *
 * Reminder model (2026-07+): per-reminder skipPath / matchPath instead of
 * the prior global SKIP_PATH_RE. Each reminder opts into a path policy:
 *   - matchPath: ONLY trigger when the changed path matches the regex
 *                (use for narrow-purpose reminders like gha-security-review
 *                on .github/workflows/**)
 *   - skipPath:  trigger UNLESS the changed path matches
 *                (use for broad-purpose reminders that want to skip pure docs)
 *   - neither:   trigger on every Write/Edit/apply_patch
 *
 * apply_patch note: OpenCode stores the patch in args.patchText (not args.patch
 * or args.diff). The patch is OpenAI-style: `*** Begin Patch ... *** End Patch`
 * envelope containing one or more `*** Add File: PATH` / `*** Update File: PATH`
 * (optionally followed by `*** Move to: NEWPATH`) / `*** Delete File: PATH`
 * headers. We extract ALL affected paths (multi-file patches return multi-path
 * array) and run normal matchPath/skipPath logic per-path. A reminder fires if
 * ANY extracted path matches its matchPath. When extraction fails (rare; truly
 * malformed patches), we fall back to firing ALL matchPath-bound reminders as
 * a candidate batch with a `[review-router:patch-candidate]` marker.
 *
 * Per-edit token cost: ~21-23 tokens per reminder. Per-turn dedup via
 * state.reminded; per-result dedup via marker.
 */
import { existsSync } from 'node:fs'
import { join } from 'node:path'
import { homedir } from 'node:os'

const REMINDERS = [
  // Always-on core gate
  {
    name: 'verification-before-completion',
    text: 'Before claiming done, invoke `verification-before-completion`.',
  },
  // Skip pure doc/binary/lockfile/config (no executable code to audit)
  {
    name: 'security-and-hardening',
    text: 'Before claiming done, invoke `security-and-hardening` to audit trust boundaries in the diff.',
    skipPath: /\.(md|markdown|txt|rst|env|gitignore|lock|svg|png|jpe?g|gif|ico|woff2?|ttf|eot|map|wasm|pdf)(\.[^/\\]+)?$|^(package-lock\.json|yarn\.lock|pnpm-lock\.yaml|composer\.lock|Gemfile\.lock|Cargo\.lock|poetry\.lock|go\.sum|Gopkg\.lock)$/i,
  },
  // AI blindspots: same skip set (binary / doc / lockfile carry no AI-generated code to scan)
  {
    name: 'ai-code-blindspots',
    text: 'Before claiming done, invoke `ai-code-blindspots` for an AI-generated-diff blindspot scan.',
    skipPath: /\.(md|markdown|txt|rst|env|gitignore|lock|svg|png|jpe?g|gif|ico|woff2?|ttf|eot|map|wasm|pdf)(\.[^/\\]+)?$|^(package-lock\.json|yarn\.lock|pnpm-lock\.yaml|composer\.lock|Gemfile\.lock|Cargo\.lock|poetry\.lock|go\.sum|Gopkg\.lock)$/i,
  },
  // GHA workflow edits: narrow path — always remind when .github/workflows/** changes
  {
    name: 'gha-security-review',
    text: 'GHA workflow file changed; invoke `gha-security-review` to audit action-permission + expression-injection + supply-chain.',
    matchPath: /(?:^|\/)\.github\/workflows\//i,
  },
// Test files: AI-generated tests silently pass without test-quality gate
  // (.test. / .spec. / _test. / test_*.py / *Test.java / tests/ / __tests__/).
  {
    name: 'test-guard',
    text: 'Test file changed; invoke `test-guard` to audit for over-mocking / tautological assertions / lazy `toBeDefined` / fake deps / boundary coverage gaps.',
    matchPath: /(?:^|\/)(tests?|__tests__)\/|\.(test|spec)\.[a-z]+$|_test\.[a-z]+$|(?:^|\/)test_[^/\\]+\.py$|[Tt]est\.[a-z]+$/i,
  },
  // Stack-specific code: frontend UI + mobile native catch the layer
  // landmines. Backend (.py/.go/.java) is intentionally NOT matched —
  // description routes there; over-nudging on every .py edit would be noise.
  {
    name: 'stack-security-coder',
    text: 'Stack-specific code changed; invoke `stack-security-coder` for per-layer audit (frontend XSS-CSP-cross-origin / mobile WebView-certs-storage-biometric).',
    matchPath: /\.(tsx|jsx|vue|svelte|swift|dart)$/i,
  },
  // Frontend UI code (anti-slop second contract): fire alongside stack-security-coder.
  // Loads meisijiya-frontend-taste so the agent reads anti-AI-slop rules (Design Read +
  // three dials + non-default typography / color / layout / CTA / eyebrow / zigzag /
  // motion / image rules) before continuing. Pairs with designer-handoff spec as the
  // second contract layer; minimalist-ui fires when brief names Linear / Notion / editorial.
  {
    name: 'meisijiya-frontend-taste',
    text: 'Frontend UI file changed; load `meisijiya-frontend-taste` for anti-slop rules (Design Read + three dials + non-default typography / color / layout / CTA / eyebrow / zigzag / motion / image strategy) before continuing. Stack as the second contract on top of any `designer-handoff` spec.',
    matchPath: /\.(tsx|jsx|vue|svelte)$/i,
  },
  // Frontend UI / stylesheet changes on existing projects: audit-then-fix.
  // Fires alongside meisijiya-frontend-taste; the agent reads the 9-layer audit
  // (typography / color / layout / interactivity / content / components / icons / code
  // / strategic-omissions) + fix-priority ladder if the work is on existing UI rather
  // than greenfield.
  {
    name: 'meisijiya-redesign-ui',
    text: 'Frontend UI / stylesheet changed; load `meisijiya-redesign-ui` if this is an upgrade to existing UI (not greenfield) — 9-layer audit + fix-priority ladder (fonts → color → states → layout → components → states → polish) without migrating frameworks.',
    matchPath: /\.(tsx|jsx|vue|svelte|css|scss|less)$/i,
  },
]

const TRIGGER_TOOLS = new Set(['write', 'edit', 'apply_patch'])

const state = new Map()
const get = (sid) => {
  if (!state.has(sid)) state.set(sid, { lastMessageID: null, reminded: new Set() })
  return state.get(sid)
}

const installedCache = new Map()
const installed = (name) => {
  if (installedCache.has(name)) return installedCache.get(name)
  const ok = existsSync(join(homedir(), '.agents', 'skills', name, 'SKILL.md'))
  installedCache.set(name, ok)
  return ok
}

const marker = (name) => `[review-router:${name}]`

// Path extraction from apply_patch bodies. OpenCode's apply_patch tool uses an
// OpenAI-style format with `*** Begin Patch / *** End Patch` envelope containing
// one or more `*** Add File: PATH` / `*** Update File: PATH` (optionally
// followed by `*** Move to: NEWPATH`) / `*** Delete File: PATH` headers. We
// return ALL affected paths so multi-file patches trigger each path's reminders.
//
// Anchored to start-of-line with the `m` + `g` flag so the regex does NOT
// false-positive on in-source `matchPath: /pattern/` regex declarations and
// captures every occurrence (not just the first).
const PATH_RE_OAI_FILE = /^\*\*\* (?:Add|Update|Delete) File: (.+)$/gm
const PATH_RE_OAI_MOVE = /^\*\*\* Move to: (.+)$/gm
// Git format: capture BOTH a/OLD and b/NEW so renames register both paths
// (critical for gha-security-review on .github/workflows/ renames).
const PATH_RE_DIFF_GIT = /^diff --git a\/(.+?) b\/(.+?)$/gm
const PATH_RE_PLUS_PLUS = /^\+\+\+ b\/(.+?)(?:\t|$)/gm

function extractPathsFromPatch(patchBody) {
  if (typeof patchBody !== 'string' || patchBody.length === 0) return []
  const seen = new Set()
  const push = (p) => {
    if (typeof p === 'string' && p.length > 0) seen.add(p.trim())
  }
  // 1. OpenAI-style (*** Add/Update/Delete File: PATH) — primary, multi-file
  for (const m of patchBody.matchAll(PATH_RE_OAI_FILE)) push(m[1])
  // 2. *** Move to: PATH — secondary (paired with Update File rename)
  for (const m of patchBody.matchAll(PATH_RE_OAI_MOVE)) push(m[1])
  if (seen.size > 0) return [...seen]
  // 3. git format (diff --git a/OLD b/NEW) — fallback, multi-file, captures rename
  for (const m of patchBody.matchAll(PATH_RE_DIFF_GIT)) {
    push(m[1])
    push(m[2])
  }
  if (seen.size > 0) return [...seen]
  // 4. unified diff (+++ b/PATH) — last-resort, multi-file
  for (const m of patchBody.matchAll(PATH_RE_PLUS_PLUS)) push(m[1])
  return [...seen]
}

function shouldTriggerPathForAny(reminder, filePaths) {
  if (!filePaths || filePaths.length === 0) return !reminder.matchPath
  if (reminder.matchPath) {
    return filePaths.some((fp) => reminder.matchPath.test(fp))
  }
  if (reminder.skipPath) {
    return filePaths.some((fp) => !reminder.skipPath.test(fp))
  }
  return true
}

export const MeisijiyaReviewRouter = async ({ client, directory }) => {
  return {
    'chat.message': async (input, _output) => {
      const s = get(input.sessionID)
      if (input.messageID !== s.lastMessageID) {
        s.lastMessageID = input.messageID
        s.reminded = new Set()
      }
    },

    'tool.execute.after': async (input, output) => {
      if (!TRIGGER_TOOLS.has(String(input.tool).toLowerCase())) return
      if (typeof output?.output !== 'string') return

      const toolName = String(input.tool).toLowerCase()
      const s = get(input.sessionID)

      let fps = []
      let patchCandidateMode = false

      const directFp = String(input?.args?.filePath ?? input?.args?.filepath ?? '')
      if (directFp) {
        fps = [directFp]
      } else if (toolName === 'apply_patch') {
        // OpenCode's apply_patch stores the patch under args.patchText (NOT
        // args.patch / args.diff / args.content / args.body — those are wrong).
        const patchBody = String(input?.args?.patchText ?? '')
        const recovered = extractPathsFromPatch(patchBody)
        if (recovered.length > 0) {
          fps = recovered
        } else if (patchBody.length > 0) {
          patchCandidateMode = true
        }
      }

      for (const reminder of REMINDERS) {
        const { name, text } = reminder
        if (!installed(name)) continue
        if (s.reminded.has(name)) continue
        if (patchCandidateMode) {
          if (!reminder.matchPath) continue
          const m = `[review-router:patch-candidate] ${name}`
          if (output.output.includes(m)) continue
          output.output += `\n\n${m} (path unknown — apply_patch body could not be parsed; agent decides if this applies)`
          s.reminded.add(name)
          continue
        }
        if (!shouldTriggerPathForAny(reminder, fps)) continue
        const m = marker(name)
        if (output.output.includes(m)) continue
        output.output += `\n\n${m} ${text}`
        s.reminded.add(name)
      }
    },

    'event': async ({ event }) => {
      if (event?.type !== 'session.deleted') return
      const sessionID = event.properties?.info?.id
      if (sessionID) state.delete(sessionID)
      installedCache.clear()
    },
  }
}
