# Skill Design Principles

Distilled rules for writing/maintaining skills in the meisijiya-skills repository. **Not** a runtime skill — this is a contributor/developer reference for future PRs.

## Source

Primary reference: [`obra/superpowers` `skills/writing-skills/SKILL.md`](https://github.com/obra/superpowers/blob/main/skills/writing-skills/SKILL.md). We vendored a copy at `skills/.core/writing-skills/` (the vendored version is authoritative for the full ruleset; this doc distills the must-follow items).

## Core Principles (must-follow)

### 1. Description format: "Use when..." only

The `description` field in YAML frontmatter describes **when to use** the skill, not what it does or how.

```yaml
# ✓ good
description: "Use when starting any conversation - establishes how to find and use skills"

# ✗ bad (summarizes workflow)
description: "Use when executing plans - dispatches subagent per task with code review between tasks"
```

**Why**: testing in superpowers' `writing-skills` showed that description workflow summary causes agents to follow the description instead of reading the full skill content. Keep `description` ≤500 chars if possible, hard cap 1024 chars total frontmatter.

### 2. Body composition: concise, no redundancy

Target body size:

| Skill type | Target | Hard cap |
|---|---|---|
| Meta-skill (e.g., `using-*`) | <70 lines | 100 lines |
| Process skill (e.g., `brainstorming`) | <100 lines | 200 lines |
| Domain skill | <150 lines | 300 lines |

Reference: `using-superpowers` itself is 62 lines. Our trimmed `using-meisijiya-skills` is 58 lines. Both demonstrate the principle: **no section should be deducible from another section or from external context** (e.g., `<available_skills>`, other skills).

### 3. One workflow per skill

Each skill = one triggerable workflow. If you find yourself writing "this skill also does X and Y", split into multiple skills.

Counter-example: a "frontend-design" skill that also does code review, deploy, and testing → split into 3 skills.

### 4. Strong imperatives for meta-skills

Meta-skills (dispatchers like `using-meisijiya-skills`) use:

- `<EXTREMELY-IMPORTANT>` XML wrapper (LLM attention bias)
- "1% chance" / "not negotiable" / "cannot rationalize" framings
- `<SUBAGENT-STOP>` block to exempt subagents
- "Use when..." instructions repeated in body, not only description
- Anti-rationalization table ("STOP, you're rationalizing")

Reference implementation: [`using-superpowers/SKILL.md`](https://github.com/obra/superpowers/blob/main/skills/using-superpowers/SKILL.md) (62 lines, exemplifying all four).

### 5. Frontmatter + format compliance

Per existing `skill-anatomy.md` + OpenCode skill spec:

- `name`: lowercase, hyphens only, matches directory
- `description`: third-person, ≤1024 chars total
- `allowed-tools`: specify when skill needs tool restrictions
- 6 standard sections (Overview / When to Use / Process / Common Rationalizations / Red Flags / Verification) for process skills; meta-skills can be more flexible

## Anti-patterns

| Anti-pattern | Why bad |
|---|---|
| Description summarizes workflow | Agent follows description, skips reading skill |
| Body duplicates `<available_skills>` listing | Token waste; OpenCode shows it automatically |
| Body duplicates content of another skill | Point to the other skill via `~/.agents/skills/<name>/SKILL.md` link instead |
| "When to Use" section repeats description | Description IS the trigger; section adds nothing |
| Core Process section has 80 lines of operational steps | Operational detail belongs in another skill or reference doc |
| Skill Catalog table inside bootstrap | OpenCode's system prompt already lists |
| Verification checklist model won't follow | Models don't follow checklists in practice |

## Existing repo standards (do not duplicate)

This doc complements but does NOT replace:

- `skill-anatomy.md` — frontmatter format + 6 standard sections + file structure rules
- `docs/agents-md-guide.md` — different scope (AGENTS.md writing, not SKILL.md writing)
- `AGENTS.md` Section B — contributor guide for adding skills to this repo

Read those alongside this doc. They cover orthogonal concerns (file format vs design philosophy vs repo contribution workflow).

## Worked example: `using-meisijiya-skills`

This skill went through 3 iterations:

1. **v0.5.0**: 198 lines, included full Skill Catalog table, Core Process details, Verification checklist. Token cost: 12 KB / 3000 tokens per injection.
2. **v0.5.2**: trimmed to 58 lines, removed redundant sections. Token cost: 3 KB / 821 tokens.
3. **v0.5.3**: production-clean, no diagnostic logs. No content change.

Lesson: every line in a skill body has a token cost *per injection per step*. Multiply by 100 steps and you get 800K tokens just for one skill. **Conciseness is not aesthetic — it's a billing concern.**

## Checklist for new/edit skill PR

Before opening a PR that adds or significantly edits a skill:

- [ ] Description: "Use when..." only, ≤500 chars if possible
- [ ] Body size within target (see table above)
- [ ] No section deducible from `<available_skills>` or other skills
- [ ] No workflow summary in description
- [ ] One workflow per skill (split if multi-purpose)
- [ ] Frontmatter per `skill-anatomy.md`
- [ ] 6 standard sections (for process skills)
- [ ] If meta-skill: EXTREMELY-IMPORTANT + Red Flags table
- [ ] Eval case added at `evals/cases/<name>.json` (3 positive + 3 negative + ≥1 behavioral)

## References

- [`obra/superpowers` `writing-skills`](https://github.com/obra/superpowers/blob/main/skills/writing-skills/SKILL.md) — full ruleset
- [`skill-anatomy.md`](./skill-anatomy.md) — file format spec
- [`AGENTS.md` Section B](./AGENTS.md#section-b-adding-skills-contributor-guide) — repo contribution workflow
- [`docs/agents-md-guide.md`](./docs/agents-md-guide.md) — sibling doc on AGENTS.md writing