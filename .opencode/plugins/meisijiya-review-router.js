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
 * apply_patch note: its args.filePath is not available; reminders with
 * matchPath cannot fire from apply_patch edits, since the path is hidden
 * inside the patch body. Use write/edit for security-critical CI files.
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

function shouldTriggerPath(reminder, filePath) {
  // No filePath (e.g. apply_patch) — matchPath-only reminders cannot decide.
  // Fire everything else (broad reminders fall back to default).
  if (!filePath) return !reminder.matchPath
  if (reminder.matchPath) return reminder.matchPath.test(filePath)
  if (reminder.skipPath) return !reminder.skipPath.test(filePath)
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

      const fp = String(input?.args?.filePath ?? input?.args?.filepath ?? '')
      const s = get(input.sessionID)

      for (const reminder of REMINDERS) {
        const { name, text } = reminder
        if (!installed(name)) continue
        if (s.reminded.has(name)) continue
        if (!shouldTriggerPath(reminder, fp)) continue
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
