---
name: using-meisijiya-skills
description: "Dispatcher meta-skill for the meisijiya-skills collection. Forces the agent to check applicable skills before every response, coordinate with oh-my-openagent's Sisyphus + IntentGate, and initialize OMO. Use when starting any session in a project where meisijiya-skills are installed, or when about to take any action on the user's behalf."
allowed-tools: "Read Bash Glob Grep"
---

<SUBAGENT-STOP>
If you were dispatched as a subagent to execute a specific task, ignore this skill.
</SUBAGENT-STOP>

<EXTREMELY-IMPORTANT>
If a Skill's description matches what you are about to do, you MUST invoke it before acting. If you are not sure whether a Skill applies, **stop and check the Skill catalog first**; do not default to skipping.

This is not optional. Skills encode team-validated discipline; bypassing them because "this is simple" is exactly when they matter.
</EXTREMELY-IMPORTANT>

## Overview

Meta dispatcher. Hard-injected every session by the OpenCode plugin (`~/.config/opencode/plugins/meisijiya-skills.js`) so the model actively invokes skills instead of letting them sit in `<available_skills>`. Coordinates with omo Sisyphus + IntentGate; this skill does NOT do work — it routes.

## When to Use

**Use when:**
- Starting any session in a project where meisijiya-skills are installed (you're in one right now)
- About to take any action on the user's behalf — every turn, before responding

**NOT for:**
- Sub-agents (you were dispatched to execute a specific task; ignore this skill — the controller should not have forwarded it)
- Executors — receive domain-specific skills in the dispatch prompt, NOT this dispatcher

## Process

1. Consult `<available_skills>` (injected by the harness) for the current session's skill roster + each skill's `description`.
2. Match the incoming request against each skill's `description` field. The `description` is the source of truth for routing.
3. For cross-skill trigger hints (one row per common request pattern), read [`references/priority-table.md`](references/priority-table.md).
4. For multi-stage work sequences (design → spec → impl → test → review; fix; ship; perf gate; etc.), read [`references/process-chains.md`](references/process-chains.md).
5. For the sub-agent controller/executor split, read [`references/controller-executor.md`](references/controller-executor.md). For model selection by task type, read [`references/model-selection.md`](references/model-selection.md).
6. Announce **"Using [skill] to [purpose]"** when invoking, and follow the invoked skill's checklist exactly.

## Common Rationalizations

| Thought | Reality |
|---|---|
| "This is just a simple question" / "Let me explore first" / "I can check files quickly" | Questions are tasks. Skills tell you HOW to explore. Files lack conversation context. |
| "This doesn't need a formal skill" / "I remember this skill" / "The skill is overkill" | If a Skill exists, use it. Skills evolve — read current version. Simple things become complex. |
| "I'll just do this one thing first" / "This feels productive" | Check BEFORE doing anything. Undisciplined action wastes time. |
| "1% chance applies, must load" | Only invoke when description matches; "not sure" still requires checking the catalog, but not loading every adjacent Skill. |

## Red Flags

- Invoking `using-meisijiya-skills` from a sub-agent (means the controller forgot to filter — see `<SUBAGENT-STOP>`).
- Reading skill SKILL.md files when the description alone would suffice (wastes tokens — read on demand after description match).
- Treating the Priority table as authoritative (it's a hint accelerator; the `description` field wins).
- Skipping the announce step — without "Using [skill] to [purpose]" the user can't see the routing.

## Plugin layer (where this bootstrap comes from)

- `~/.config/opencode/plugins/meisijiya-skills.js` reads this `SKILL.md` on session start, strips frontmatter, wraps in `<EXTREMELY-IMPORTANT>`, and `unshift`s into `firstUser.parts` once per session (idempotent against compaction re-fires).
- `~/.config/opencode/plugins/meisijiya-review-router.js` injects per-Edit reminders for `ai-code-blindspots` + `security-and-hardening` + `verification-before-completion` after `write` / `edit` / `apply_patch` (deduped per turn).

**Editing rules** — Changes to `SKILL.md` do **not** auto-reload; OpenCode plugins load once at process start. Restart OpenCode after editing. If `<EXTREMELY-IMPORTANT>` is missing, the bootstrap plugin is not installed — fix the install before assuming this skill is active.

## User Instructions

User instructions (AGENTS.md, direct requests) take precedence over skills, which override default behavior. Only skip skill workflows when your human partner has explicitly told you to.

## Verification

Before responding, confirm:
- [ ] You have either invoked a matching skill OR explicitly stated no skill matches
- [ ] You announced "Using [skill] to [purpose]" when invoking
- [ ] The invoked skill's `allowed-tools` covers the tools you need (otherwise escalate)