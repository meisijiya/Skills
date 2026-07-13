---
name: writing-skills
description: "Use when creating a new skill, editing an existing skill, or extracting a repeated/abstractable workflow into a reusable skill during project development. Treats skill authoring as TDD for process documentation - write failing baseline test, write minimal skill addressing observed failures, close loopholes. Also use when noticing a workflow pattern that should be captured before the team forgets it."
allowed-tools: "Read Bash Glob Grep Write"
---

# Writing Skills

## Overview

**Writing skills IS Test-Driven Development applied to process documentation.**

You write test cases (pressure scenarios with subagents), watch them fail (baseline behavior), write the skill (documentation), watch tests pass (agents comply), and refactor (close loopholes).

**Core principle:** If you didn't watch an agent fail without the skill, you don't know if the skill teaches the right thing.

**This skill is meta.** Use it when:
- Creating a new skill
- Editing an existing skill that's not working as expected
- **Noticing a repeated/abstractable workflow in your project that should be a skill** — this is the "extract patterns into reusable skills" use case

## When to Use

**Use when:**
- Creating a new skill (always — no exceptions)
- Editing a skill that's been observed to fail under pressure
- Noticing a workflow the team / agent repeats often enough to be worth capturing
- Onboarding a new team member to a workflow that "everyone knows" but isn't documented
- Audit: a process that worked once but isn't codified

**NOT for:**
- One-off solutions that won't recur
- Standard practices already documented elsewhere (link instead)
- Project-specific conventions → put in your `AGENTS.md` instead
- Mechanical constraints (if enforceable with regex/validation, automate it — save documentation for judgment calls)

## Process: RED → GREEN → REFACTOR

### RED: Write the failing test (baseline)

Run a **pressure scenario with a subagent WITHOUT the skill**. Document:

- What choices did they make?
- What rationalizations did they use (verbatim)?
- Which pressures triggered violations (time, sunk cost, authority, exhaustion)?

This is "watch the test fail" — you must see what agents naturally do before writing the skill.

**Example baseline test for `verification-before-completion`:**
```
Scenario: agent just edited 3 files in a complex area and is about to tell user "done"
Pressure: user asked 4 hours ago, agent is tired
Without skill: agent says "done!" without running any verification
Rationalization observed: "I made the obvious change, no need to test"
```

### GREEN: Write the minimal skill

Write the skill addressing the **specific** rationalizations and failures observed in RED.

Don't add extra content for hypothetical cases. Address what you saw.

Run the same scenario WITH skill. Agent should now comply.

### REFACTOR: Close loopholes

Agent found new rationalization? Add explicit counter. Re-test until bulletproof.

Common refactor patterns:
- Close loopholes in the rule ("No exceptions" + list specific workarounds)
- Add rationalizations table (capture excuses + reality)
- Add red flags (make self-check easy)

## Skill Structure

```markdown
---
name: Skill-Name-With-Hyphens
description: Use when [specific triggering conditions and symptoms]
allowed-tools: "Read Bash Glob Grep"  # only if needed
---

# Skill Name

## Overview
What + core principle in 1-2 sentences.

## When to Use
Bullet list of triggering conditions + "NOT for" exclusions.

## Process
Numbered steps. Each step is a check or action.

## Common Rationalizations
| Excuse | Reality |
|---|---|
| (captured rationalizations from RED phase) | (counter) |

## Red Flags
- (early warning signs the rule is being violated)

## Verification
- [ ] (checkboxes for evidence-before-completion)
```

## Description Field: Critical for Discovery

**The `description` field is the only thing the agent reads to decide whether to load your skill.** Make it answer: "Should I read this skill right now?"

**Rules:**
1. **Start with "Use when..."** — focuses on triggering conditions
2. **Describe ONLY when to use, NOT what the skill does** — summaries cause agents to skip reading the skill body
3. **Include specific triggers, symptoms, contexts** — abstract descriptions don't match real situations
4. **Third person** — gets injected into system prompt
5. **≤ 1024 chars**

```yaml
# ❌ BAD: Summarizes workflow, agent may follow this instead of reading skill
description: Use when starting work - checks skill catalog and dispatches to relevant skill

# ✅ GOOD: Just triggering conditions, no workflow summary
description: Use when starting any new session or task - forces skill check before action
```

## Common Rationalizations (for the meta-skill of writing skills)

| Excuse | Reality |
|---|---|
| "Skill is obviously clear" | Clear to you ≠ clear to other agents. Test it. |
| "It's just a reference" | References can have gaps, unclear sections. Test retrieval. |
| "Testing is overkill" | Untested skills have issues. Always. 15 min testing saves hours. |
| "I'll test if problems emerge" | Problems = agents can't use skill. Test BEFORE deploying. |
| "I'm confident it's good" | Overconfidence guarantees issues. Test anyway. |
| "No time to test" | Deploying untested skill wastes more time fixing it later. |

## Anti-Patterns

- ❌ **Narrative example**: "In session 2025-10-03, we found X..." — too specific, not reusable
- ❌ **Multi-language dilution**: same example in 5 languages — mediocre quality, maintenance burden
- ❌ **Process summary in description**: makes agent skip reading the skill
- ❌ **Untested deployment**: "I'll add it to the catalog and see if anyone uses it" — they won't, or they'll misuse it
- ❌ **Project-specific skill for broad pattern**: convention goes in `AGENTS.md`, not in a skill (skills are cross-project)

## When to Extract a Workflow into a Skill

You're working on a project. You notice you keep doing X. **Should X become a skill?**

YES if:
- You (or the team) repeat X across multiple sessions / projects
- The pattern isn't already documented in `AGENTS.md`
- The pattern has judgment calls (not pure mechanical execution)
- Other agents / future-you would benefit

NO if:
- One-off solution
- Pure mechanical (script it, don't document it)
- Project-specific (put in project's `AGENTS.md`)
- Already documented elsewhere (link, don't duplicate)

## Verification

Before declaring a skill "done":
- [ ] I ran baseline scenarios WITHOUT the skill (RED phase)
- [ ] I documented observed failures and rationalizations verbatim
- [ ] I wrote the skill addressing those specific failures
- [ ] I ran the same scenarios WITH the skill — agent now complies (GREEN)
- [ ] I tested for new rationalizations after first GREEN pass (REFACTOR)
- [ ] Description starts with "Use when..." and is ≤ 1024 chars
- [ ] Description describes ONLY when to use, not what the skill does
- [ ] No "narrative example" anti-pattern
- [ ] No process summary in description
- [ ] Cross-references to related skills use the path convention: `~/.agents/skills/<name>/SKILL.md`

## Related Skills

- Builds on: [`verification-before-completion`](~/.agents/skills/verification-before-completion/SKILL.md) — test the skill like you test code
- Builds on: [`test-driven-development`](~/.agents/skills/test-driven-development/SKILL.md) — same RED-GREEN-REFACTOR discipline
- Cross-ref: [`using-meisijiya-skills`](~/.agents/skills/using-meisijiya-skills/SKILL.md) — meta dispatcher