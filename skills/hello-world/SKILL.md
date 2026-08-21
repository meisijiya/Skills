---
name: hello-world
description: Explains the frontmatter and layout contract of this skills repo, with a worked glossary of terms. Use when asked how this repo works, how to add a skill, or what a SKILL.md must contain.
license: MIT
---

# Hello World

The example skill of this repository: a meta skill that explains the repo's own
contract. It exists as a smoke test for the install/validate/CI pipeline — if this
skill lints and is discovered, the contract machinery works.

## When to use

Trigger this skill when the user asks how this repository works: what a `SKILL.md`
must contain, how skills are discovered and installed, what `skills-ref` checks, or
how to add a new skill. Do not use it for questions about any *other* skill's domain.

## Quick start

1. Read the contract: [`AGENTS.md`](../../AGENTS.md) — it is the binding rulebook.
2. To add a new skill: `./scripts/new-skill.sh <kebab-case-name>` (use `--dry-run`
   first to preview).
3. Verify any skill locally: `skills-ref validate skills/<name>/`.
4. Install skills from this repo: `npx skills add <owner>/<repo>`.

## Workflow

1. A contributor scaffolds a skill with `scripts/new-skill.sh <name>`.
2. They replace every `<!-- TODO: ... -->` marker in the generated `SKILL.md`.
3. They run `skills-ref validate skills/<name>/` — it enforces the
   frontmatter contract (name matches directory, valid `description`, no forbidden
   fields).
4. CI (`lint-skills.yml`) runs the validator per skill **and** `npx skills@latest
   add . --list` to prove the repo is discoverable.
5. Users install via `npx skills add <owner>/<repo>`.

If validation fails, the error names the field and the rule — fix it, re-run, done.

## Examples

```bash
# Scaffold a new skill (prints actions, writes nothing)
./scripts/new-skill.sh pdf-extract --dry-run

# Validate an existing skill
skills-ref validate skills/hello-world/

# Install from the published repo
npx skills add <owner>/<repo> --skill hello-world
```

## References

- [`references/glossary.md`](references/glossary.md) — definitions of contract terms
  (frontmatter, progressive disclosure, `_template/`, `skills-ref`); read when a term
  in the contract is unclear.
