---
name: using-meisijiya-skills
description: "Dispatcher meta-skill: forces the agent to check applicable skills before every response, coordinate with sub-agent dispatch (load_skills), and announce routing. Use when starting any session or about to take action in a project with meisijiya-skills installed."
allowed-tools: "Read Bash Glob Grep"
---

<SUBAGENT-STOP>
If you were dispatched as a subagent to execute a specific task, ignore this skill.
</SUBAGENT-STOP>

<EXTREMELY-IMPORTANT>
If a Skill's description matches what you are about to do, you MUST invoke it before acting. If you are not sure whether a Skill applies, **stop and check the Skill catalog first**; do not default to skipping.

**IMPORTANT**: When dispatching sub-agents via `task()`, ALWAYS pass the COMPLETE `load_skills` set from the Category × Skill Matrix main table ([`references/category-matrix.md`](references/category-matrix.md)) — never `[]` for matrix-mapped categories. The dispatch-gate plugin will console.warn if you pass an incomplete list.

This is not optional. Skills encode team-validated discipline; bypassing them because "this is simple" is exactly when they matter.
</EXTREMELY-IMPORTANT>

## Overview

Meta dispatcher. Hard-injected every session by the OpenCode plugin (`~/.config/opencode/plugins/meisijiya-skills.js`) so the model actively invokes skills instead of letting them sit in `<available_skills>`. Coordinates with omo Sisyphus + IntentGate; this skill does NOT do work — it routes. SOT: each skill's `description` field; cross-skill hints in [`references/priority-table.md`](references/priority-table.md).

## When to Use

**Use when:**
- Starting any session in a project where meisijiya-skills are installed (you're in one right now)
- About to take any action on the user's behalf — every turn, before responding

**NOT for:**
- Sub-agents (you were dispatched to execute a specific task; ignore this skill — see `<SUBAGENT-STOP>`)
- Executors — receive domain-specific skills in the dispatch prompt, NOT this dispatcher
- Doing the work itself — this skill only routes (PROCESS); the `<EXTREMELY-IMPORTANT>` discipline applies to the invoked skill

## Process

1. **Check `.omo/handoff/` for unconsumed documents** (cross-session resumption). If any `.md` file has `consumed: false`, this takes precedence over trigger matching — user expects `RESUME FROM PHASE <to_phase>`, not fresh routing. Wait for `consumed` or `consume --reject <reason>` before proceeding. See [`meisijiya-handoff`](~/.agents/skills/meisijiya-handoff/SKILL.md).
2. **Consult `<available_skills>`** (injected by the harness) for the session's skill roster + each skill's `description`.
3. **Match the incoming request against each skill's `description`** — the description is the source of truth for routing.
4. **Cross-skill hints**: [`references/priority-table.md`](references/priority-table.md) (trigger patterns); [`references/process-chains.md`](references/process-chains.md) (multi-stage sequences); [`references/controller-executor.md`](references/controller-executor.md) + [`references/model-selection.md`](references/model-selection.md) (sub-agent split / model selection).
5. **Announce "Using [skill] to [purpose]"** when invoking, and follow the invoked skill's checklist exactly.
6. **When delegating to sub-agents, follow the Sisyphus Dispatch Protocol** — always specify the COMPLETE `load_skills` set from the Category × Skill Matrix main table (Hard Rule; see [`references/category-matrix.md`](references/category-matrix.md)). If the dispatch-gate plugin warns "matrix recommends X" while you have an existing list, evaluate whether X is missing and add it.

## Category × Skill Matrix

→ See [`references/category-matrix.md`](references/category-matrix.md) (matrix + Security 5-lane fan-out + specialist agents + Common Dispatch Scenarios + Sisyphus Dispatch Protocol).

> **dispatch-gate SOT note**: the plugin header comment says "Sync with SKILL.md §Category × Skill Matrix" — that section now lives in `references/category-matrix.md`. When the matrix changes, update BOTH the reference file and `RECOMMENDED` in `.opencode/plugins/meisijiya-dispatch-gate.js`.

## Plugin layer (where this bootstrap comes from)

This SKILL.md is injected into firstUser.parts each session — see `meisijiya-skills.js:113-132` (Editing rules below). The `EXTREMELY_IMPORTANT` marker guard makes re-injection idempotent after compaction.

- `~/.config/opencode/plugins/meisijiya-skills.js` reads this `SKILL.md` on session start, strips frontmatter, wraps in `<EXTREMELY-IMPORTANT>`, and `unshift`s into `firstUser.parts` once per session (idempotent against compaction re-fires).
- `~/.config/opencode/plugins/meisijiya-review-router.js` injects per-Edit reminders for `ai-code-blindspots` + `security-and-hardening` + `verification-before-completion` after `write` / `edit` / `apply_patch` (deduped per turn).
- `~/.config/opencode/plugins/meisijiya-dispatch-gate.js` is the hard-layer fallback for `load_skills` completeness — SOT for its `RECOMMENDED` constant is `references/category-matrix.md` (see cross-ref above).

**Editing rules** — Changes to `SKILL.md` do **not** auto-reload; OpenCode plugins load once at process start. Restart OpenCode after editing. If `<EXTREMELY-IMPORTANT>` is missing, the bootstrap plugin is not installed — fix the install before assuming this skill is active.

## User Instructions

User instructions (AGENTS.md, direct requests) take precedence over skills, which override default behavior. Only skip skill workflows when your human partner has explicitly told you to.

## Verification

Before responding, confirm:
- [ ] You have either invoked a matching skill OR explicitly stated no skill matches
- [ ] You announced "Using [skill] to [purpose]" when invoking
- [ ] The invoked skill's `allowed-tools` covers the tools you need (otherwise escalate)
- [ ] For sub-agent dispatches: `load_skills=[...]` is specified (consult [`references/category-matrix.md`](references/category-matrix.md))
- [ ] Rationalizations / Red Flags checked (see [`references/dispatcher-rationalizations.md`](references/dispatcher-rationalizations.md)) — no skipped skill on "this is simple" grounds
