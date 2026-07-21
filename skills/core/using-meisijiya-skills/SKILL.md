---
name: using-meisijiya-skills
description: "Dispatcher meta-skill for the meisijiya-skills collection. Forces the agent to check applicable skills before every response, coordinate with oh-my-openagent's Sisyphus + IntentGate, and initialize planning-with-files. Use when starting any session in a project where meisijiya-skills are installed, or when about to take any action on the user's behalf."
allowed-tools: "Read Bash Glob Grep"
---

<SUBAGENT-STOP>
If you were dispatched as a subagent to execute a specific task, ignore this skill.
</SUBAGENT-STOP>

<EXTREMELY-IMPORTANT>
If a Skill's description matches what you are about to do, you MUST invoke it before acting. If you are not sure whether a Skill applies, **stop and check the Skill catalog first**; do not default to skipping.

This is not optional. Skills encode team-validated discipline; bypassing them because "this is simple" is exactly when they matter.
</EXTREMELY-IMPORTANT>

## The Rule

**Invoke relevant skills BEFORE any response or action** — including clarifying questions, exploring the codebase, or checking files. If no Skill matches, say so explicitly and proceed.

**Before entering plan mode:** if you haven't already brainstormed, invoke [`brainstorming`](~/.agents/skills/brainstorming/SKILL.md) first.

Then announce **"Using [skill] to [purpose]"** and follow it exactly. If the Skill has a checklist, create a todo per item.

## Skill Priority (soft hints — not rules)

> **AI decides via description match.** Each skill's `description` field is the source of truth for whether to invoke it. This table is a **hint accelerator** for common request patterns — read it as "consider this skill first," not as "must invoke this skill." When multiple skills could apply, **process skills come first** (they're the discipline layer; the rest are tools).
>
> **Under omo**, Sisyphus's Intent Gate already classifies intent (research / implementation / investigation / fix / evaluation) before any skill routing happens. The table below covers the `implementation` branch where skill routing still matters; other branches are handled by omo's built-in dispatch (librarian / explore / oracle for `research`; debugging-and-error-recovery for `fix`).

| Trigger (user request pattern) | Consider first | Possible next |
|---|---|---|
| `ulw` / `ultrawork` / "just build it" / "do it" | (no skill — Sisyphus ultrawork mode handles) | [`brainstorming`](~/.agents/skills/brainstorming/SKILL.md) only if mid-flight scope emerges |
| "Let's build X" / "implement Y" / new feature (scope known) | [`incremental-implementation`](~/.agents/skills/incremental-implementation/SKILL.md) | [`brainstorming`](~/.agents/skills/brainstorming/SKILL.md) only if Sisyphus detects hidden ambiguity |
| "I want to do X but I'm not sure how" / "design X" / "what's the right way" | [`brainstorming`](~/.agents/skills/brainstorming/SKILL.md) | [`spec-driven-development`](~/.agents/skills/spec-driven-development/SKILL.md) → [`incremental-implementation`](~/.agents/skills/incremental-implementation/SKILL.md) |
| "Fix this bug" / "X is broken" / "X is wrong" | [`debugging-and-error-recovery`](~/.agents/skills/debugging-and-error-recovery/SKILL.md) | [`verification-before-completion`](~/.agents/skills/verification-before-completion/SKILL.md) |
| "About to claim done" / "ready to commit/PR" | [`verification-before-completion`](~/.agents/skills/verification-before-completion/SKILL.md) | (invoke OMO `review-work` per Stage 2) |
| "Write code that touches K+/v X / unfamiliar API" | [`source-driven-development`](~/.agents/skills/source-driven-development/SKILL.md) | [`test-driven-development`](~/.agents/skills/test-driven-development/SKILL.md) |
| "Write a skill" / "edit a skill" / "extract this workflow" | [`writing-skills`](~/.agents/skills/writing-skills/SKILL.md) | (test-first, red-green-refactor) |
| Codebase health scan / on-boarding unfamiliar codebase / weekly architecture review | [`improve-codebase-architecture`](~/.agents/skills/improve-codebase-architecture/SKILL.md) | (proposal-only output; defer to `incremental-implementation` for action) |
| Underspecified request / "interview me" / "grill me" | [`brainstorming`](~/.agents/skills/brainstorming/SKILL.md) | (one question at a time, see Process § 2) |

**Project-level AGENTS.md and direct user instructions override this table** — only skip Skills when the human partner has explicitly told you to.

## Red Flags — STOP, you're rationalizing

| Thought | Reality |
|---|---|
| "This is just a simple question" | Questions are tasks. Check for Skills. |
| "Let me explore the codebase first" | Skills tell you HOW to explore. Check first. |
| "I can check git/files quickly" | Files lack conversation context. Check for Skills. |
| "This doesn't need a formal skill" | If a Skill exists, use it. |
| "I remember this skill" | Skills evolve. Read current version. |
| "This doesn't count as a task" | Action = task. Check for Skills. |
| "The skill is overkill" | Simple things become complex. Use it. |
| "I'll just do this one thing first" | Check BEFORE doing anything. |
| "This feels productive" | Undisciplined action wastes time. Skills prevent this. |
| "1% chance applies, must load" (removed) | Only invoke when description matches; "not sure" still requires checking the catalog first, but not loading every adjacent Skill. |

## pwf Integration

This skill runs at session start, before any phase. May prompt for `init-session.sh` if pwf is not active.

## User Instructions

User instructions (AGENTS.md, direct requests) take precedence over skills, which in turn override default behavior. Only skip skill workflows or instructions when your human partner has explicitly told you to.
