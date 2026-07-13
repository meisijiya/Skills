---
name: brainstorming
description: "Use when starting any non-trivial feature, component, or behavior change, or when the user proposes a plan whose intent is unclear. HARD-GATE: do NOT write code, scaffold projects, or invoke implementation skills before presenting a design and getting user approval. Applies even to projects that feel 'simple'."
allowed-tools: "Read Bash Glob Grep"
---

# Brainstorming

## Overview

Every project — even "trivial" ones — goes through this. The design can be short (a few sentences for a true one-liner), but you MUST present it and get approval before any code. Unverified assumptions cause the most wasted work.

**Core principle:** HARD-GATE. No implementation before design + user approval.

**This skill precedes [`spec-driven-development`](~/.agents/skills/spec-driven-development/SKILL.md).** Brainstorm produces the design; spec-driven-development writes the formal spec; then implementation.

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

## Process

### 1. Explore project context

Before asking detailed questions, check what's already in flight:
- `task_plan.md` or `.planning/<id>/task_plan.md` (pwf state)
- Recent commits (`git log --oneline -10`)
- Related files (`grep -r "<keywords>" --include="*.md"`)
- Existing related specs (search for "spec" or "design" in docs)

If the request describes **multiple independent subsystems** ("build a platform with chat + file storage + billing + analytics"), flag this immediately. Help decompose into sub-projects first; then brainstorm each one through the normal flow. Each sub-project gets its own spec → plan → implementation cycle.

### 2. Ask clarifying questions

**One question at a time.** Never batch-ask 5 questions.

- Prefer **multiple choice** when possible (easier to answer than open-ended)
- Focus on: purpose, constraints, success criteria, edge cases, non-obvious decisions
- If a topic needs more exploration, break into multiple questions
- Don't ask questions whose answers you can find by reading the codebase

### 3. Propose 2-3 approaches

For each approach:
- Trade-offs (pros / cons)
- Your recommendation (lead with it, explain why)

If the user has implicit constraints (timeline, tech stack, team skills), make sure approaches respect them. Don't waste time proposing options that violate hard constraints.

### 4. Present the design

Scale each section to its complexity: a few sentences for simple, up to 200-300 words for nuanced.

Cover: architecture, components, data flow, error handling, testing strategy.

**Get user approval after each section**, not just at the end. Don't dump the entire design and ask "ok?" — section-by-section prevents the "I've read 200 lines, just say yes" pattern.

### 5. Write design doc

Save validated design to:
- `.planning/<id>/spec.md` (if pwf active)
- `task_plan.md` (legacy pwf mode)
- `docs/specs/YYYY-MM-DD-<topic>-design.md` (user preference override)

Commit the design document.

### 6. Spec self-review

After writing the spec, look at it with fresh eyes:

- **Placeholder scan**: any "TBD", "TODO", incomplete sections, vague requirements? Fix inline.
- **Internal consistency**: do sections contradict each other? Does the architecture match the feature descriptions?
- **Scope check**: focused enough for a single implementation plan, or does it need decomposition?
- **Ambiguity check**: could any requirement be interpreted two different ways?

Fix any issues inline. No need to re-review.

### 7. User reviews the written spec

```
Spec written and committed to <path>. Please review it and let me know
if you want to make any changes before we start writing the implementation plan.
```

Wait for the user's response. If they request changes, make them and re-run the spec review loop. Only proceed once approved.

### 8. Transition to implementation

Invoke [`spec-driven-development`](~/.agents/skills/spec-driven-development/SKILL.md) to create the implementation plan.

**DO NOT** invoke `incremental-implementation`, `test-driven-development`, or any other implementation skill directly. `spec-driven-development` is the next step.

## Common Rationalizations

| Excuse | Reality |
|---|---|
| "This is just a typo / one-line fix, no design needed" | Typos have hidden assumptions (where to apply, what to preserve). A 2-sentence design takes 30 seconds. |
| "I already know what the user wants" | You think you do. One clarifying question surfaces missing requirements in 80% of cases. |
| "The user said 'just do X'" | Even quick tasks have hidden decisions. Ask once, then do. |
| "I'll iterate the design during implementation" | Code written without spec = rework when user reveals they meant something different. |
| "The design will slow me down" | Writing code that gets thrown away is slower than a 2-minute design conversation. |
| "I'll skip the doc, just describe verbally" | Verbal design evaporates. Written spec is what you implement against. |

## Red Flags

- About to invoke [`incremental-implementation`](~/.agents/skills/incremental-implementation/SKILL.md) / [`test-driven-development`](~/.agents/skills/test-driven-development/SKILL.md) / any implementation skill without a written spec
- User asks "how should we do X" and you start coding instead of brainstorming
- Skipping clarifying questions because "the answer is obvious"
- Multiple parallel implementation tasks without decomposing first
- "I'll just fix this small thing" without checking the design doc
- Producing a long answer without first checking skill catalog

## Verification

Before invoking any implementation skill, confirm:
- [ ] I explored project context (commits, plans, related files)
- [ ] I asked clarifying questions one at a time until requirements are clear
- [ ] I proposed 2-3 approaches with trade-offs + my recommendation
- [ ] User approved the approach
- [ ] Design was written to a doc file (not just verbal)
- [ ] Spec self-review complete (no placeholders, no contradictions)
- [ ] User approved the written spec
- [ ] Next step is [`spec-driven-development`](~/.agents/skills/spec-driven-development/SKILL.md) (not implementation skill directly)

## pwf Integration

Corresponds to **Phase 0** (pre-Intake): no `task_plan.md` exists yet. Output: spec document. Transition to Phase 1 (Intake via [`spec-driven-development`](~/.agents/skills/spec-driven-development/SKILL.md)) after spec approval.

See [pwf-integration.md](../../pwf-integration.md) for full phase mapping.