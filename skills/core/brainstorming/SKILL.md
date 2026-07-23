---
name: brainstorming
description: "HARD-GATE pre-design exploration: do NOT write code, scaffold projects, or invoke implementation skills before presenting a design and getting user approval. Applies even to projects that feel 'simple'. Use when starting any non-trivial feature, component, or behavior change, or when the user proposes a plan whose intent is unclear. Under omo, this is the in-context counterpart to Prometheus Mode (Tab / @plan); prefer it when the user has not explicitly invoked Prometheus and you are inside a Sisyphus-driven session."
allowed-tools: "Read Bash Glob Grep"
---

# Brainstorming

## Overview

Every project — even "trivial" ones — goes through this. The design can be short (a few sentences for a true one-liner), but you MUST present it and get approval before any code. Unverified assumptions cause the most wasted work.

**Core principle:** HARD-GATE. No implementation before design + user approval.

**This skill precedes [`spec-driven-development`](~/.agents/skills/spec-driven-development/SKILL.md).** Brainstorm produces the design and appends it as **Phase 0** of the Prometheus plan at `.omo/plans/<slug>.md` (or draft at `.omo/drafts/<slug>.md` if you go through `ulw-plan`); spec-driven-development then refines it into **Phase 1 (Spec)** of the same plan file. **One approval gate, not two.**

## When to Use

**Use when:**
- Starting any non-trivial feature, component, or behavior change
- User proposes a plan whose intent is unclear or has hidden assumptions
- Scope ambiguity exists (multiple subsystems? what order? what counts as in/out?)
- Before invoking [`spec-driven-development`](~/.agents/skills/spec-driven-development/SKILL.md), [`incremental-implementation`](~/.agents/skills/incremental-implementation/SKILL.md), or any other implementation skill
- Multiple reasonable interpretations exist for "how to do X"

**NOT for:**
- User explicitly said "no design, just do it" (rare; respect this)
- Pure trivia Q&A with no implementation implied
- Already inside an active brainstorming session for this task
- Single-line typo / rename / formatting (skip this skill)

## Process

### 1. Explore project context

Before asking detailed questions, check what's already in flight:
- `.omo/plans/*.md` (Prometheus plans — current OMO state)
- Recent commits (`git log --oneline -10`)
- Related files (`grep -r "<keywords>" --include="*.md"`)
- Existing related specs (search for "spec" or "design" in docs)

If the request describes **multiple independent subsystems** ("build a platform with chat + file storage + billing + analytics"), flag this immediately. Help decompose into sub-projects first; then brainstorm each one through the normal flow. Each sub-project gets its own spec → plan → implementation cycle.

### 2. Ask clarifying questions — one at a time, decision-tree convergence

Before asking, form a hypothesis: "I think the user actually wants X, right?" Then:

- **One question at a time.** Never batch-ask 5 questions.
- Use the AskUserQuestion tool (or equivalent) with **2-4 mutually exclusive options** (no "other" trap, no open-ended "what do you want?").
- Each option must include a recommended answer (user can reply "agree" to advance).
- Focus on: purpose, constraints, success criteria, edge cases, non-obvious decisions.
- **Facts self-check, decisions ask the user.** If you can read code or grep for it, don't ask.
- **Walk the decision tree, not a fixed questionnaire.** A later question's premise may depend on an earlier answer — batch-asking would force you to assume undecided parent nodes. After each answer, decide whether the open question set has shifted; only ask questions whose prerequisites are settled.
- **Convergence criterion**: stop when no open question has a prerequisite that is still unresolved AND you can summarize the design space in 2-3 sentences and the user confirms "yes, that's right."
- **No hard upper bound on questions.** The Matt Pocock `grilling` primitive's philosophy: walk down every branch of the decision tree until shared understanding is reached. The earlier "3-7 typical, >10 → switch to spec-driven" rule was a questionnaire cap — replaced by decision-tree convergence because the cap was forcing closure on undecided branches.
- **If the tree obviously exceeds one session** (e.g., 15+ open decisions with deep dependency chains), the scope is wrong — switch to [`spec-driven-development`](~/.agents/skills/spec-driven-development/SKILL.md) with TODOs to break into sub-projects, then brainstorm each.
- When you reach ~95% confidence, summarize in 2-3 sentences and ask "我理解的对吗?" — if yes, proceed.

### 3. Propose 2-3 approaches

For each approach:
- Trade-offs (pros / cons)
- Your recommendation (lead with it, explain why)

If the user has implicit constraints (timeline, tech stack, team skills), make sure approaches respect them. Don't waste time proposing options that violate hard constraints.

### 4. Present the design

Scale each section to its complexity: a few sentences for simple, up to 200-300 words for nuanced.

Cover: architecture, components, data flow, error handling, testing strategy.

**Get user approval after each section**, not just at the end. Don't dump the entire design and ask "ok?" — section-by-section prevents the "I've read 200 lines, just say yes" pattern.

### 5. Append design as Phase 0 of the Prometheus plan (no separate file)

Append the validated design as **Phase 0: Design** of `.omo/plans/<slug>.md` (or `.omo/drafts/<slug>.md` if you went through `ulw-plan --draft-only`):

```markdown
## Phase 0: Design

**Goal:** <一句话目标>
**Approach:** <the recommended approach from Step 3>
**Architecture:** <key components + flow>
**Components & data flow:**
- <A> → <B> → <C>
**Error handling:** <strategy>
**Testing strategy:** <unit / integration / e2e split>
**Open questions:** <anything still ambiguous — defer to Phase 1>

**Status:** design_approved_pending_spec
```

**Why no separate file?** `.omo/plans/<slug>.md` is the durable state file OMO reads from. Splitting design into a sibling file means the plan Prometheus / ulw-plan tracks and the design you wrote diverge. Phase 1 (Spec) refines the same content in the same file; one approval, one artifact.

> **Do NOT auto-commit** the design. OMO's Boulder state (`.omo/boulder.json`) plus the plan file itself are the durable record; commits are governed by the project's git policy (often only on slice-level commits per [`incremental-implementation`](~/.agents/skills/incremental-implementation/SKILL.md)).

> **append-only for the plan file.** OMO's `notepad-write-guard` hook enforces append-only on `.omo/notepads/*`; for `.omo/plans/*.md` use `Edit` (not `Write`) when adding phases so phase ordering and script-emitted headers are preserved (see `ulw-plan` skill: never rewrite script-emitted headers).

### 6. Design self-review

After writing, look with fresh eyes:
- **Placeholder scan**: any "TBD", "TODO", incomplete sections, vague requirements? Fix inline.
- **Internal consistency**: do sections contradict each other? Does the architecture match the feature descriptions?
- **Scope check**: focused enough for a single implementation plan, or does it need decomposition?
- **Ambiguity check**: could any requirement be interpreted two different ways?

Fix any issues inline. No need to re-review.

### 7. Hand off to spec-driven-development

Tell the user:

```
Design appended as Phase 0 of `.omo/plans/<slug>.md`. Next: invoke
spec-driven-development to refine into the formal PRD/Spec
(Phase 1), get your final approval, then run.
No separate design-doc file needed.
```

Wait for the user's confirmation, then invoke [`spec-driven-development`](~/.agents/skills/spec-driven-development/SKILL.md).

**DO NOT** invoke `incremental-implementation`, `test-driven-development`, or any other implementation skill directly.

## Common Rationalizations

| Excuse | Reality |
|---|---|
| "This is just a typo / one-line fix, no design needed" | Typos have hidden assumptions (where to apply, what to preserve). A 2-sentence design takes 30 seconds. |
| "I already know what the user wants" | You think you do. One clarifying question surfaces missing requirements in 80% of cases. |
| "The user said 'just do X'" | Even quick tasks have hidden decisions. Ask once, then do. |
| "I'll iterate the design during implementation" | Code written without spec = rework when user reveals they meant something different. |
| "The design will slow me down" | Writing code that gets thrown away is slower than a 2-minute design conversation. |
| "I'll skip the doc, just describe verbally" | Verbal design evaporates. Written spec is what you implement against. |
| "I'll ask 5 questions at once to save time" | The user answers the easiest and skips the consequential. One at a time. |

## Red Flags

- About to invoke [`incremental-implementation`](~/.agents/skills/incremental-implementation/SKILL.md) / [`test-driven-development`](~/.agents/skills/test-driven-development/SKILL.md) / any implementation skill without a written spec
- User asks "how should we do X" and you start coding instead of brainstorming
- Skipping clarifying questions because "the answer is obvious"
- Multiple parallel implementation tasks without decomposing first
- Writing the design into a separate file (`docs/specs/...`, `.planning/<id>/spec.md`) instead of `.omo/plans/<slug>.md` — plan and design diverge
- Producing a long answer without first checking skill catalog
- Asking 2+ questions in one round (use AskUserQuestion once with mutually exclusive options)
- Auto-committing the design doc (commits are governed by slice-level policy)

## Verification

Before invoking any implementation skill, confirm:
- [ ] I explored project context (commits, plans, related files)
- [ ] I asked clarifying questions one at a time until requirements are clear (or zero questions if already clear)
- [ ] I proposed 2-3 approaches with trade-offs + my recommendation
- [ ] User approved the approach
- [ ] Design appended as Phase 0 of `.omo/plans/<slug>.md` (not a separate file)
- [ ] Design self-review complete (no placeholders, no contradictions)
- [ ] User approved the written design
- [ ] Next step is [`spec-driven-development`](~/.agents/skills/spec-driven-development/SKILL.md) (not implementation skill directly)

## omo Integration

This skill is the **in-context** counterpart of omo's **Prometheus Mode**:

| Mode | Trigger | Where it runs |
|---|---|---|
| **Prometheus Mode** | Tab / `@plan "task"` | New subagent context (no prior rationalization pollution) |
| **This skill** (brainstorming) | description match | Current Sisyphus context |

**When to use which:**
- **Prometheus Mode** — non-trivial projects needing multi-day planning, fresh-context discipline, or when user explicitly wants interview mode
- **This skill (brainstorming)** — sub-decisions inside an ongoing session, smaller features, or when the user already has a Prometheus plan and needs to drill into one branch

After brainstorming produces the design, the downstream chain is the same in both modes:
1. Spec via [`spec-driven-development`](~/.agents/skills/spec-driven-development/SKILL.md)
2. Momus plan review (omo built-in; `momus` agent validates plan against clarity/verification/context criteria)
3. Phase 3: Slice via [`incremental-implementation`](~/.agents/skills/incremental-implementation/SKILL.md)
4. `/start-work` to dispatch to Atlas

**NOT**: Do not invoke this skill and Prometheus Mode in parallel — pick one. If user typed Tab or `@plan`, defer to Prometheus. Otherwise, run this skill inline.

## Related Skills

- Successor: [`spec-driven-development`](~/.agents/skills/spec-driven-development/SKILL.md) — refines Design into formal Spec (Phase 1 of the same plan file)
- Cross-references meta: [`using-meisijiya-skills`](~/.agents/skills/using-meisijiya-skills/SKILL.md)