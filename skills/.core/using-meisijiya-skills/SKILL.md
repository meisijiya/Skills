---
name: using-meisijiya-skills
description: "Dispatcher meta-skill for the meisijiya-skills collection. Forces the agent to check applicable skills before every response, initialize planning-with-files if not yet done, and coordinate with oh-my-openagent's Sisyphus + IntentGate. Delegates todo orchestration to omo's atlas agent. Use when starting any session in a project where meisijiya-skills are installed, or when about to take any action on the user's behalf."
allowed-tools: "Read Bash Glob Grep"
---

# Using meisijiya-skills

## Overview

This meta-skill is the **entry point** of meisijiya-skills. It enforces three non-negotiable habits:

1. Before every response, check whether a meisijiya skill applies.
2. Before every non-trivial task, ensure planning-with-files is initialized.
3. Coordinate with oh-my-openagent's Sisyphus — don't fight it.

Without this skill, agents skip skills entirely — even when one is exactly what the user asked for. The skill catalog is in the agent's context, but agents default to the shortest path (answer directly), and "shortest" rarely means "load the right skill first."

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

## Core Process

### 1. Check pwf state (every session start)

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

### 2. List applicable skills

The Skill tool injects the catalog automatically. For each incoming task, identify:

- Which `.core/` skill matches (always available, load it)
- Which `.extra/` skill might apply (load on demand)

If you're about to take action without naming a skill, **stop and check the catalog**.

### 3. Before every response — ask yourself

1. **Does a skill match what the user asked?** If yes, load it via the Skill tool *before* producing the answer.
2. **Is this the middle of an active skill workflow?** Continue that skill, don't restart.
3. **Is this a Q&A with no implied action?** Answer directly.

### 4. Defer to omo Sisyphus

When running under [oh-my-openagent](https://github.com/code-yeongyu/oh-my-openagent), `using-meisijiya-skills` is the **fallback dispatcher**:

- omo's **Sisyphus + IntentGate** handle routing upstream (IntentGate classifies intent, Sisyphus orchestrates)
- This skill is the safety net for when omo is absent or for omo's edge cases
- **omo atlas agent** handles todo orchestration — defer multi-step task tracking to atlas, don't manually maintain task lists
- Don't fight Sisyphus — if Sisyphus delegated to a category agent, let that agent finish
- If Sisyphus is stuck or unsure, **prompt Sisyphus to consult oracle** (read-only reasoning) for architectural decisions

### 5. Record what you considered

After deciding, append a single line to `progress.md`:

```
[skill-check] <task summary> → loaded <skill-name> | no skill needed
```

This makes the decision traceable for later review.

## Skill Catalog

### `.core/` (Required)

| Skill | Load when |
|---|---|
| `using-meisijiya-skills` | (this skill — meta, always-on) |
| `spec-driven-development` | Starting a new project, feature, or significant change |
| `incremental-implementation` | Any change touching more than one file |
| `test-driven-development` | Implementing logic, fixing bugs, changing behavior |
| `debugging-and-error-recovery` | Tests fail, build breaks, or behavior is unexpected |
| `source-driven-development` | Working with any framework or library where correctness matters |

### `.extra/` (Optional, loaded on demand)

| Skill | Load when |
|---|---|
| `pwf-enforcer` | Hard-enforce pwf via omo hooks (A scheme: omo hook only) |
| `build-gate-visual-review` | Before final delivery, render project state as HTML for user review |
| `designer-handoff` | UI projects — generate design spec for frontend agent |
| `agent-project-structure` | Initializing a new project, want canonical doc structure |
| `interview-me` | User request is underspecified |
| `code-simplification` | Code works but is harder to read than it should be |
| `api-and-interface-design` | Designing APIs, module boundaries, public interfaces |
| `security-and-hardening` | Handling user input, auth, data storage, external integrations |
| `performance-optimization` | Performance requirements exist or regressions suspected |
| `observability-and-instrumentation` | Shipping anything that runs in production |
| `documentation-and-adrs` | Making architectural decisions, changing public APIs |

## Common Rationalizations

| Excuse | Reality |
|---|---|
| "The user just asked a simple question, no skill needed" | Even simple questions may need `source-driven-development` (framework docs) or `interview-me` (clarify ambiguity). When in doubt, check. |
| "I already loaded the right skill earlier" | Skills don't persist across `/clear`. Re-check after compaction. |
| "omo Sisyphus will route for me" | Yes — but this skill is the **fallback**. If omo is absent or disabled, this is the only dispatcher. |
| "Loading skills costs tokens" | Skipping a relevant skill costs more — wrong answers, rework, debugging time, user frustration. |
| "The user said 'just do X quickly'" | Quickly ≠ sloppily. Load the skill, then execute. The skill is faster than recovery. |
| "I'm inside another skill, no need to re-check" | Correct — finish the active skill first. But record what you considered in `progress.md`. |

## Red Flags

- Agent produces a long answer without first checking the skill catalog
- Agent skips pwf initialization on a 3+ step task
- Agent answers "the user just asked X" without considering what skill fits X
- Agent restarts a skill workflow mid-stream (e.g., reloads `test-driven-development` while already inside it)
- Agent loads multiple skills at once instead of one at a time
- Agent invokes `using-meisijiya-skills` recursively to "double-check"

## Verification

Before responding to the user, confirm:

- [ ] I checked whether a meisijiya skill matches the task
- [ ] I checked whether pwf is initialized (for non-trivial tasks)
- [ ] If a skill applies, I loaded it *before* producing the answer
- [ ] If no skill applies, I answered directly without loading anything
- [ ] I appended a `[skill-check]` line to `progress.md`

## pwf Integration

This skill does not correspond to a single `task_plan.md` phase — it runs at session start, before any phase exists. It writes one `[skill-check]` line to `progress.md` per response, and may prompt the user to run `init-session.sh` if pwf is not active.

See [pwf-integration.md](../../pwf-integration.md) for the full phase mapping.