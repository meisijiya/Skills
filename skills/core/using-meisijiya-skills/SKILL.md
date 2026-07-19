---
name: using-meisijiya-skills
description: "Dispatcher meta-skill for the meisijiya-skills collection. Forces the agent to check applicable skills before every response, coordinate with oh-my-openagent's Sisyphus + IntentGate, and initialize planning-with-files. Use when starting any session in a project where meisijiya-skills are installed, or when about to take any action on the user's behalf."
allowed-tools: "Read Bash Glob Grep"
---

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

When multiple skills apply, process skills come first.

- "Let's build X" → [`brainstorming`](~/.agents/skills/brainstorming/SKILL.md) → [`spec-driven-development`](~/.agents/skills/spec-driven-development/SKILL.md) → implementation
- "Fix this bug" → [`debugging-and-error-recovery`](~/.agents/skills/debugging-and-error-recovery/SKILL.md) → [`verification-before-completion`](~/.agents/skills/verification-before-completion/SKILL.md)
- "About to claim done" → [`verification-before-completion`](~/.agents/skills/verification-before-completion/SKILL.md)

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

This skill runs at session start, before any phase. May prompt for `init-session.sh` if pwf is not active.

## User Instructions

User instructions (AGENTS.md, direct requests) take precedence over skills, which in turn override default behavior. Only skip skill workflows or instructions when your human partner has explicitly told you to.
