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
 * Extending: add 1 line to REMINDERS array (must match a skill installed
 * at ~/.agents/skills/<name>/SKILL.md).
 *
 * Per-edit token cost: ~21-23 tokens per reminder × N skills (one
 * reminder per turn per skill); SKIP_PATH_RE cuts noise for non-code
 * edits so real-world cost is much lower than the worst case.
 */
import { existsSync } from 'node:fs'
import { join } from 'node:path'
import { homedir } from 'node:os'

const REMINDERS = [
  { name: 'ai-code-blindspots',          text: 'Before claiming done, invoke `ai-code-blindspots`.' },
  { name: 'security-and-hardening',      text: 'Before claiming done, invoke `security-and-hardening`.' },
  { name: 'verification-before-completion', text: 'Before claiming done, invoke `verification-before-completion`.' },
]

const TRIGGER_TOOLS = new Set(['write', 'edit', 'apply_patch'])

// Skip reminders when the changed path is clearly not source code:
// docs / config / data / fixtures / etc. The set mirrors the most common
// extension mistakes — adding more is a single regex entry.
const SKIP_PATH_RE = /\.(md|markdown|txt|rst|json|ya?ml|toml|csv|env|gitignore|lock)(\.[^/\\]+)?$/i

const installed = (name) =>
  existsSync(join(homedir(), '.agents', 'skills', name, 'SKILL.md'))

const marker = (name) => `[review-router:${name}]`

export const MeisijiyaReviewRouter = async ({ client, directory }) => {
  // Per-session state: { sessionID -> { lastMessageID, reminded: Set<skill> } }
  const state = new Map()
  const get = (sid) => {
    if (!state.has(sid)) state.set(sid, { lastMessageID: null, reminded: new Set() })
    return state.get(sid)
  }

  return {
    // Per-turn reset: when a new user message arrives, clear the reminded set
    'chat.message': async (input, _output) => {
      const s = get(input.sessionID)
      if (input.messageID !== s.lastMessageID) {
        s.lastMessageID = input.messageID
        s.reminded = new Set()
      }
    },

    'tool.execute.after': async (input, output) => {
      if (!TRIGGER_TOOLS.has(String(input.tool).toLowerCase())) return
      if (typeof output?.output !== 'string') return  // shape guard (MCP tools)

      // Skip reminders when the changed path is a doc/config/data file —
      // those don't belong under code-blindspot review. The shape varies by
      // tool: write/edit usually expose args.filePath, apply_patch hides
      // the target inside its patch body (we don't try to parse that).
      const fp = String(input?.args?.filePath ?? input?.args?.filepath ?? '')
      if (fp && SKIP_PATH_RE.test(fp)) return

      const s = get(input.sessionID)

      for (const { name, text } of REMINDERS) {
        if (!installed(name)) continue                       // graceful skip if missing
        if (s.reminded.has(name)) continue                   // per-turn dedup
        const m = marker(name)
        if (output.output.includes(m)) continue               // per-result dedup
        output.output += `\n\n${m} ${text}`
        s.reminded.add(name)
      }
    },

    'event': async ({ event }) => {
      if (event?.type !== 'session.deleted') return
      const sessionID = event.properties?.info?.id
      if (sessionID) state.delete(sessionID)
    },
  }
}