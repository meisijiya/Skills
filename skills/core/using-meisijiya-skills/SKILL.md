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

## When to Use

**Use when:**
- Starting any new session
- Receiving a new task from the user
- About to take any action on the user's behalf
- Resuming after `/clear` or context compaction
- Unsure whether a meisijiya skill applies

**NOT for:**
- Already inside an active skill workflow (the active skill is already loaded — finish it first)
- Pure trivia Q&A with no action implied
- Tasks that the user explicitly framed as "no skill, just answer"

## Overview

This meta-skill is the **entry point** of meisijiya-skills. It enforces non-negotiable habits:

1. Before every response, check whether a meisijiya skill applies.
2. Before every non-trivial task, ensure planning-with-files is initialized.
3. Coordinate with oh-my-openagent's Sisyphus — don't fight it.
4. Before any completion claim, invoke [`verification-before-completion`](~/.agents/skills/verification-before-completion/SKILL.md).

Without this skill, agents skip skills entirely — even when one is exactly what the user asked for. The skill catalog is in the agent's context, but agents default to the shortest path (answer directly), and "shortest" rarely means "load the right skill first."

## Skill Priority

When multiple skills could apply, invoke them in this order:

1. **Process skills first** (set the approach): [`brainstorming`](~/.agents/skills/brainstorming/SKILL.md) → [`spec-driven-development`](~/.agents/skills/spec-driven-development/SKILL.md)
2. **Implementation skills** (carry it out): [`incremental-implementation`](~/.agents/skills/incremental-implementation/SKILL.md) → [`test-driven-development`](~/.agents/skills/test-driven-development/SKILL.md)
3. **Discipline skills** (wrap it up): [`debugging-and-error-recovery`](~/.agents/skills/debugging-and-error-recovery/SKILL.md), [`verification-before-completion`](~/.agents/skills/verification-before-completion/SKILL.md)
4. **Meta skills** (when changing the system itself): [`writing-skills`](~/.agents/skills/writing-skills/SKILL.md)

## Core Process

### 0. Check pwf state (every session start)

```bash
# Is planning-with-files active in this project?
if [ -f task_plan.md ]; then
  echo "pwf: legacy mode (task_plan.md at project root)"
elif ls .planning/*/task_plan.md >/dev/null 2>&1; then
  echo "pwf: parallel mode (.planning/<date>-<slug>/)"
else
  echo "pwf: NOT initialized"
fi
```

Decision:
- **Initialized** → read `task_plan.md` + `progress.md` + `findings.md`, continue from current phase
- **Not initialized + task is 3+ steps** → prompt user with `init-session.sh` offer before proceeding
- **Not initialized + trivial task** → proceed without pwf

### 1. List applicable skills

The Skill tool injects the catalog automatically. For each incoming task, identify:

- Which `core/` skill matches (always available, load it)
- Which `extra/` skill might apply (load on demand)

If you're about to take action without naming a skill, **stop and check the catalog**.

### 2. Before every response — ask yourself

1. **Does a skill match what the user asked?** If yes, load it via the Skill tool *before* producing the answer, then announce "Using [skill] to [purpose]".
2. **Is this the middle of an active skill workflow?** Continue that skill, don't restart.
3. **Is this a Q&A with no implied action?** Answer directly.
4. **Am I about to claim completion?** If yes, invoke [`verification-before-completion`](~/.agents/skills/verification-before-completion/SKILL.md) FIRST.

### 3. Defer to omo Sisyphus

When running under [oh-my-openagent](https://github.com/code-yeongyu/oh-my-openagent), `using-meisijiya-skills` is the **fallback dispatcher**:

- omo's **Sisyphus + IntentGate** handle routing upstream (IntentGate classifies intent, Sisyphus orchestrates)
- This skill is the safety net for when omo is absent or for omo's edge cases
- **omo atlas agent** handles todo orchestration — defer multi-step task tracking to atlas, don't manually maintain task lists
- Don't fight Sisyphus — if Sisyphus delegated to a category agent, let that agent finish
- If Sisyphus is stuck or unsure, **prompt Sisyphus to consult oracle** (read-only reasoning) for architectural decisions

### 4. Record what you considered

After deciding, append a single line to `progress.md`:

```
[skill-check] <task summary> → loaded <skill-name> | no skill needed
```

This makes the decision traceable for later review.

### 5. Capture repeated workflows as skills (proactive)

If during execution you notice a workflow you do repeatedly (2+ times across sessions), invoke [`writing-skills`](~/.agents/skills/writing-skills/SKILL.md) to extract it. The threshold: "if I had to onboard someone new, would I need to teach them this?" — if yes, it's a skill candidate.

## Skill Catalog

### `core/` (Required, load always)

| Skill | Load when |
|---|---|
| [`using-meisijiya-skills`](~/.agents/skills/using-meisijiya-skills/SKILL.md) | (this skill — meta, always-on) |
| [`brainstorming`](~/.agents/skills/brainstorming/SKILL.md) | Starting any non-trivial work; HARD-GATE before implementation |
| [`spec-driven-development`](~/.agents/skills/spec-driven-development/SKILL.md) | Starting a new project, feature, or significant change |
| [`incremental-implementation`](~/.agents/skills/incremental-implementation/SKILL.md) | Any change touching more than one file |
| [`test-driven-development`](~/.agents/skills/test-driven-development/SKILL.md) | Implementing logic, fixing bugs, changing behavior |
| [`verification-before-completion`](~/.agents/skills/verification-before-completion/SKILL.md) | Before any completion claim (commit, PR, "done") |
| [`debugging-and-error-recovery`](~/.agents/skills/debugging-and-error-recovery/SKILL.md) | Tests fail, build breaks, or behavior is unexpected |
| [`source-driven-development`](~/.agents/skills/source-driven-development/SKILL.md) | Working with any framework or library where correctness matters |
| [`writing-skills`](~/.agents/skills/writing-skills/SKILL.md) | Creating/editing skills, or extracting a repeated workflow into a skill |

### `extra/` (Optional, loaded on demand)

| Skill | Load when |
|---|---|
| [`pwf-enforcer`](~/.agents/skills/pwf-enforcer/SKILL.md) | Hard-enforce pwf via omo hooks (A scheme: omo hook only) |
| [`build-gate-visual-review`](~/.agents/skills/build-gate-visual-review/SKILL.md) | Before final delivery, render project state as HTML for user review |
| [`designer-handoff`](~/.agents/skills/designer-handoff/SKILL.md) | UI projects — generate design spec for frontend agent |
| [`interview-me`](~/.agents/skills/interview-me/SKILL.md) | User request is underspecified |
| [`code-simplification`](~/.agents/skills/code-simplification/SKILL.md) | Code works but is harder to read than it should be |
| [`api-and-interface-design`](~/.agents/skills/api-and-interface-design/SKILL.md) | Designing APIs, module boundaries, public interfaces |
| [`security-and-hardening`](~/.agents/skills/security-and-hardening/SKILL.md) | Handling user input, auth, data storage, external integrations |
| [`performance-optimization`](~/.agents/skills/performance-optimization/SKILL.md) | Performance requirements exist or regressions suspected |
| [`observability-and-instrumentation`](~/.agents/skills/observability-and-instrumentation/SKILL.md) | Shipping anything that runs in production |
| [`documentation-and-adrs`](~/.agents/skills/documentation-and-adrs/SKILL.md) | Making architectural decisions, changing public APIs |

## Red Flags — STOP, you're rationalizing

These thoughts mean **STOP, you're rationalizing**:

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

## Common Rationalizations (project-specific)

| Excuse | Reality |
|---|---|
| "omo Sisyphus will route for me" | Yes — but this skill is the **fallback**. If omo is absent or disabled, this is the only dispatcher. |
| "Loading skills costs tokens" | Skipping a relevant skill costs more — wrong answers, rework, debugging time, user frustration. |
| "The user said 'just do X quickly'" | Quickly ≠ sloppily. Load the skill, then execute. The skill is faster than recovery. |
| "I'm inside another skill, no need to re-check" | Correct — finish the active skill first. But record what you considered in `progress.md`. |
| "This is too simple to need brainstorming" | Even one-liners have hidden assumptions. [`brainstorming`](~/.agents/skills/brainstorming/SKILL.md) takes 30 seconds for trivial work; the design doc catches misalignments. |
| "I'm about to claim done — but I'm confident" | Confidence ≠ evidence. Invoke [`verification-before-completion`](~/.agents/skills/verification-before-completion/SKILL.md), run the test, read the output. |
| "I keep doing X manually; this is just normal workflow" | If you do it more than twice, invoke [`writing-skills`](~/.agents/skills/writing-skills/SKILL.md) and capture it as a skill. |

## Verification

Before responding to the user, confirm:
- [ ] I checked whether a meisijiya skill matches the task
- [ ] I checked whether pwf is initialized (for non-trivial tasks)
- [ ] If a skill applies, I loaded it *before* producing the answer, and announced "Using [skill] to [purpose]"
- [ ] If no skill applies, I answered directly without loading anything
- [ ] I appended a `[skill-check]` line to `progress.md`
- [ ] If I'm about to claim completion, I invoked [`verification-before-completion`](~/.agents/skills/verification-before-completion/SKILL.md) and ran the verification

## pwf Integration

This skill does not correspond to a single `task_plan.md` phase — it runs at session start, before any phase exists. It writes one `[skill-check]` line to `progress.md` per response, and may prompt the user to run `init-session.sh` if pwf is not active.

See [pwf-integration.md](../../pwf-integration.md) for the full phase mapping.