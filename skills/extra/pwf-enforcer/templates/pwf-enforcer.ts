// pwf-enforcer.ts
// OpenCode plugin that hard-enforces planning-with-files (PWF) workflow.
//
//   Source: skills/.extra/pwf-enforcer/templates/pwf-enforcer.ts
//   Verified against @opencode-ai/plugin@1.17.18 d.ts +
//   https://opencode.ai/docs/plugins/
//
// Install:
//   cp templates/pwf-enforcer.ts ~/.config/opencode/plugins/pwf-enforcer.ts
//   # restart opencode
//
// If pwf is not installed at ~/.agents/skills/planning-with-files/,
// the plugin degrades to a no-op that logs a one-shot warning on each
// system-prompt transform.

import type { Plugin } from "@opencode-ai/plugin"
import { execSync } from "node:child_process"
import { existsSync } from "node:fs"
import { join } from "node:path"

const HOME = process.env.HOME || process.env.USERPROFILE || ""

// Resolve PWF directory: user-level first (canonical), project-level fallback.
// Falls back to project-level copies for dev/debug, vendor copies, CI sandboxes.
function resolvePwfDir(cwd: string): string {
  if (process.env.PWF_DIR) return process.env.PWF_DIR

  const probe = (dir: string) => existsSync(join(dir, "scripts", "inject-plan.sh"))
  const userDir = join(HOME, ".agents", "skills", "planning-with-files")
  if (probe(userDir)) return userDir

  for (const dir of [
    join(cwd, ".agents", "skills", "planning-with-files"),
    join(cwd, ".opencode", "skills", "planning-with-files"),
  ]) {
    if (probe(dir)) return dir
  }

  return userDir
}

function shQuote(s: string): string {
  return `'${s.replace(/'/g, "'\\''")}'`
}

function injectPlan(scriptPath: string, context: "userprompt" | "pretool" | "precompact"): string {
  if (!existsSync(scriptPath)) return ""
  try {
    return execSync(`sh ${shQuote(scriptPath)} --context=${context}`, {
      encoding: "utf-8",
      stdio: ["ignore", "pipe", "ignore"],
      timeout: 5000,
    })
  } catch {
    return ""
  }
}

function runCheckComplete(scriptPath: string): string {
  if (!existsSync(scriptPath)) return ""
  try {
    return execSync(`sh ${shQuote(scriptPath)}`, {
      encoding: "utf-8",
      stdio: ["ignore", "pipe", "ignore"],
      timeout: 5000,
    })
  } catch {
    return ""
  }
}

function planExists(cwd: string): boolean {
  if (existsSync(join(cwd, "task_plan.md"))) return true
  if (existsSync(join(cwd, ".planning", ".active_plan"))) return true
  try {
    const out = execSync(`ls -1 ${shQuote(join(cwd, ".planning"))}/*/task_plan.md 2>/dev/null`, {
      encoding: "utf-8",
      stdio: ["ignore", "pipe", "ignore"],
    })
    return out.trim().length > 0
  } catch {
    return false
  }
}

const PWF_REMINDER = `
## PWF enforcement (plugin-injected)

If a \`task_plan.md\` exists (project root or \`.planning/<id>/\`):
- **Phase discipline**: stay in the current \`in_progress\` phase; do not jump ahead.
- **After Write/Edit**: update \`progress.md\` with what you just did. If a phase completes, flip its status in \`task_plan.md\`.
- **Before /compact**: the plugin pushes plan head into the compaction prompt via \`experimental.session.compacting\` — plan survives context compression.
- **Stop**: advisory only on OpenCode (Tier 3). If phases incomplete, you decide whether to continue.

If no \`task_plan.md\`: this is a quick task, no PWF required.
`.trim()

export const PwfEnforcer: Plugin = async ({ client, directory }) => {
  const PWF_DIR = resolvePwfDir(directory)
  const INJECT_PLAN_SH = join(PWF_DIR, "scripts", "inject-plan.sh")
  const CHECK_COMPLETE_SH = join(PWF_DIR, "scripts", "check-complete.sh")
  if (!existsSync(PWF_DIR) || !existsSync(INJECT_PLAN_SH)) {
    return {
      "experimental.chat.system.transform": async (_input, output) => {
        output.system.push(
          "[pwf-enforcer] PWF skill not installed; plugin is a no-op. Install planning-with-files to enable enforcement.",
        )
      },
    }
  }

  return {
    // 1. Inject PWF reminder into every system prompt turn.
    "experimental.chat.system.transform": async (_input, output) => {
      output.system.push(PWF_REMINDER)
    },

    // 2. Rewrite write/edit tool descriptions so the model sees the reminder
    //    as part of the tool spec on every call.
    "tool.definition": async (input, output) => {
      if (input.toolID === "write" || input.toolID === "edit") {
        output.description =
          output.description +
          "\n\n[pwf-enforcer] After calling this tool, update progress.md (and task_plan.md status if a phase completes)."
      }
    },

    // 3. Before bash — prepend plan head echo so it appears in tool output.
    //    Fragile (multi-line strings, quoting); the system-prompt transform
    //    above is the primary channel. This is a best-effort reinforcement.
    "tool.execute.before": async (input, output) => {
      if (input.tool !== "bash") return
      const planHead = injectPlan(INJECT_PLAN_SH, "pretool")
      if (!planHead) return
      const original = typeof output.args === "string" ? output.args : ""
      output.args = `printf '%s\\n' ${JSON.stringify(planHead)} >&2; ${original}`
    },

    // 4. After write/edit — append reminder to tool output. The agent sees
    //    this in the tool result and cannot miss it.
    "tool.execute.after": async (input, output) => {
      if (input.tool !== "write" && input.tool !== "edit") return
      if (!planExists(directory)) return
      output.output =
        output.output +
        "\n\n[pwf-enforcer] Update progress.md with what you just did. If a phase is now complete, update task_plan.md status."
    },

    // 5. Compaction — push plan head into the compaction context. The most
    //    valuable hook: plan survives context compression.
    "experimental.session.compacting": async (_input, output) => {
      const planHead = injectPlan(INJECT_PLAN_SH, "precompact")
      if (planHead) output.context.push(planHead)
    },

    // 6. session.idle is an Event, not a hook in @opencode-ai/plugin d.ts.
    //    Catch via the generic event handler with event.type discriminator.
    //    OpenCode Tier 3 — notify only, cannot hard-block stop.
    event: async ({ event }) => {
      if (event.type !== "session.idle") return
      const out = runCheckComplete(CHECK_COMPLETE_SH).trim()
      if (out && !/complete|all phases done/i.test(out)) {
        try {
          await client.app.log({
            body: {
              service: "pwf-enforcer",
              level: "warn",
              message: `[pwf-enforcer] ${out}`,
            },
          })
        } catch {
          // advisory only, never throw
        }
      }
    },
  }
}
