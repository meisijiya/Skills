---
name: using-meisijiya-skills
description: "Dispatcher meta-skill for the meisijiya-skills collection. Forces the agent to check applicable skills before every response, initialize planning-with-files if not yet done, and coordinate with oh-my-openagent's Sisyphus + IntentGate. Delegates todo orchestration to omo's atlas agent. Use when starting any session in a project where meisijiya-skills are installed, or when about to take any action on the user's behalf."
allowed-tools: "Read Bash Glob Grep"
---

# Using meisijiya-skills

<SUBAGENT-STOP>
If you were dispatched as a subagent to execute a specific task, ignore this skill.
</SUBAGENT-STOP>

<EXTREMELY-IMPORTANT>
If you think there is even a 1% chance a skill might apply to what you are doing, you ABSOLUTELY MUST invoke the skill.

IF A SKILL APPLIES TO YOUR TASK, YOU DO NOT HAVE A CHOICE. YOU MUST USE IT.

This is not negotiable. You cannot rationalize your way out of this.
</EXTREMELY-IMPORTANT>

## The Rule

**Invoke relevant or requested skills BEFORE any response or action** — including clarifying questions, exploring the codebase, or checking files. If it turns out wrong for the situation, you don't have to use it.

**Before entering plan mode:** if you haven't already brainstormed, invoke the brainstorming skill first.

Then announce **"Using [skill] to [purpose]"** and follow it exactly. If it has a checklist, create a todo per item.

## Skill Priority

When multiple skills apply:

1. **Process first** (set the approach): [`brainstorming`](~/.agents/skills/brainstorming/SKILL.md) → [`spec-driven-development`](~/.agents/skills/spec-driven-development/SKILL.md)
2. **Implementation** (carry it out): [`incremental-implementation`](~/.agents/skills/incremental-implementation/SKILL.md) → [`test-driven-development`](~/.agents/skills/test-driven-development/SKILL.md)
3. **Discipline** (wrap it up): [`debugging-and-error-recovery`](~/.agents/skills/debugging-and-error-recovery/SKILL.md), [`verification-before-completion`](~/.agents/skills/verification-before-completion/SKILL.md)
4. **Meta** (when changing the system itself): [`writing-skills`](~/.agents/skills/writing-skills/SKILL.md)

## Red Flags — STOP, you're rationalizing

| Thought | Reality |
|---|---|
| "This is just a simple question" | Questions are tasks. Check for skills. |
| "I need more context first" | Skill check comes BEFORE clarifying questions. |
| "Let me explore the codebase first" | Skills tell you HOW to explore. Check first. |
| "I can check git/files quickly" | Files lack conversation context. Check for skills. |
| "Let me gather information first" | Skills tell you HOW to gather information. |
| "This doesn't need a formal skill" | If a skill exists, use it. |
| "I remember this skill" | Skills evolve. Read current version. |
| "This doesn't count as a task" | Action = task. Check for skills. |
| "The skill is overkill" | Simple things become complex. Use it. |
| "I'll just do this one thing first" | Check BEFORE doing anything. |
| "This feels productive" | Undisciplined action wastes time. Skills prevent this. |
| "I know what that means" | Knowing the concept ≠ using the skill. Invoke it. |

## pwf Integration

This skill runs at session start, before any `task_plan.md` phase exists. It writes one `[skill-check]` line to `progress.md` per response, and may prompt the user to run `init-session.sh` if pwf is not active.

See [pwf-integration.md](../../pwf-integration.md) for the full phase mapping.