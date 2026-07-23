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

## The Rule

**Invoke relevant skills BEFORE any response or action** — including clarifying questions, exploring the codebase, or checking files. If no Skill matches, say so explicitly and proceed.

**Before entering plan mode:** if you haven't already brainstormed, invoke [`brainstorming`](~/.agents/skills/brainstorming/SKILL.md) first.

Then announce **"Using [skill] to [purpose]"** and follow it exactly. If the Skill has a checklist, create a todo per item.

## Skill Catalog Source

This file is a routing policy, not a catalog. Consult `<available_skills>` (injected by the harness) before routing — the Priority table below is a hint accelerator, and extras are part of the same system, loaded on demand.

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
| AI just generated/edited code, in `verification-before-completion` stage | [`verification-before-completion`](~/.agents/skills/verification-before-completion/SKILL.md) | [`ai-code-blindspots`](~/.agents/skills/ai-code-blindspots/SKILL.md) (extra/) |
| "Write code that touches K+/v X / unfamiliar API" | [`source-driven-development`](~/.agents/skills/source-driven-development/SKILL.md) | [`test-driven-development`](~/.agents/skills/test-driven-development/SKILL.md) |
| "Write a skill" / "edit a skill" / "extract this workflow" | [`writing-skills`](~/.agents/skills/writing-skills/SKILL.md) | (test-first, red-green-refactor) |
| Codebase health scan / on-boarding unfamiliar codebase / weekly architecture review | [`improve-codebase-architecture`](~/.agents/skills/improve-codebase-architecture/SKILL.md) | (proposal-only output; defer to `incremental-implementation` for action) |
| Post-attested-Spec work with observed open-world contract/state/timing/concurrency/boundary/dependency/reversibility/verification-blind-spot signals | If installed, [`contract-strengthening`](~/.agents/skills/contract-strengthening/SKILL.md) | Missing optional extra never blocks the core flow; continue with the attested Spec, TDD, and completion gate |
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
| "The diff/LOC is small, so contract strengthening cannot apply" | Size is not a risk signal; route on the observed contract properties above. |
| "I'll just do this one thing first" | Check BEFORE doing anything. |
| "This feels productive" | Undisciplined action wastes time. Skills prevent this. |
| "1% chance applies, must load" (removed) | Only invoke when description matches; "not sure" still requires checking the catalog first, but not loading every adjacent Skill. |

## omo Integration

OMO dispatcher owns routing; use the `ulw-plan` skill (triggered by `plan this` / `ulw-plan` / `just make it good` / `/plan` keyword), OMO task tools (`task_create` / `task_update` for task DAG at `$OPENCODE_CONFIG_DIR/tasks/<list-id>/T-{uuid}.json`), Boulder (`.omo/boulder.json` schema v2 with multi-work / session_ids / worktree_path), notepads (`.omo/notepads/<plan>/{learnings,decisions,issues,problems}.md` — **append-only** via `notepad-write-guard` hook), `compaction-context-injector` hook (8-section context prompt for state survival across compaction), and `review-work` (5 parallel lanes) for execution and verification.

## Controller vs Executor Identity Contract

When dispatching work via `task(subagent_type="...", ...)`, the **controller** (Sisyphus / Atlas / Sisyphus-Junior) and the **executor** (sisyphus-junior / hephaestus / general agent) have strictly different roles:

| Concern | Controller (session owner) | Executor (dispatched sub-agent) |
|---|---|---|
| Plan / spec / brief | Reads full plan, holds cross-task context | Reads only `brief` file (via `task-brief.sh`) — sees NOTHING else |
| Cross-slice state | Maintains Boulder + notepad | Reads notepad append-only, never edits |
| Review gates | Schedules `slice-review` (per slice) + `review-work` (whole-branch) | Receives review verdicts; re-dispatches fixers if BLOCKED |
| Decision authority | Owns design / scope / architectural calls | 4-status return only (DONE / DONE_WITH_CONCERNS / NEEDS_CONTEXT / BLOCKED) — never invents scope |
| Context pollution | Stays in session, accumulates | Fresh per dispatch (the whole point of subagent isolation) |

**Why this matters**: this skill is bound by `<SUBAGENT-STOP>` — when
invoked as a sub-agent, ignore it. The controller is the only entity
that should ever invoke the meta dispatcher. Executors receive
domain-specific skills (e.g. `incremental-implementation`, `slice-review`)
in their dispatch prompt, NOT `using-meisijiya-skills`.

## Model Selection by Task Type (when dispatching sub-agents)

OpenCode does not support per-call dynamic `model` fields
([issue #1776](https://github.com/code-yeongyu/oh-my-openagent/issues/1776)
is still open). Instead, OMO routes through **agent / category
selection** — each agent has a fixed model chain, so picking the agent
indirectly picks the model.

| Task type | Recommended agent / category | Rationale |
|---|---|---|
| Mechanical implementation (1-2 files, complete spec in brief) | `sisyphus-junior` (sonnet-4-6) — or category `quick` (gpt-5.4-mini) | Transcription + testing; cheap model suffices |
| Integration / coordination (multi-file, dependency awareness) | `sisyphus-junior` (sonnet-4-6) | Mid-tier; can't be cheap because cross-file judgment needed |
| Architectural / design decisions | `oracle` (gpt-5.6-sol xhigh) — read-only consultant | High judgment; cheapest models recommend DRY as YAGNI per Superpowers cost experiments |
| Final whole-branch review | OMO built-in `review-work` (5 parallel lanes) | Multi-lane = broader coverage than any single reviewer |

**Cheapest ≠ always-better**: Superpowers' cost experiments showed cheap
reviewers approve DRY violations as YAGNI and pass tests with no
assertions. Mid-tier is the floor for reviewers; cheap only works for
implementers with **complete code in brief** (i.e. transcription, not
judgment).
## User Instructions

User instructions (AGENTS.md, direct requests) take precedence over skills, which in turn override default behavior. Only skip skill workflows or instructions when your human partner has explicitly told you to.
