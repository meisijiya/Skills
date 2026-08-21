# Contributing

> This is a quickstart for human contributors. The authoritative contract is
> [AGENTS.md](./AGENTS.md) — if this file and AGENTS.md disagree, AGENTS.md wins.

## Prerequisites

You need nothing beyond what the repo already assumes:

- `git` — to clone, branch, and commit
- `python3` (≥3.10) — to run the `skills-ref` validator locally (see the install
  note in AGENTS.md §"Create workflow": the git source provides the `skills-ref`
  command; PyPI 0.1.1 names it `agentskills`)
- `node` (≥22.20) — only if you want to reproduce CI's discovery check with
  `npx skills@latest add . --list`
- a GitHub account — to open PRs

## Adding a new skill

1. **Scaffold** — run `./scripts/new-skill.sh <name>` (add `--dry-run` first to preview).
   The name must be kebab-case and match a real concept — see the naming checklist in
   [AGENTS.md](./AGENTS.md) §"Create workflow".
2. **Write the content** — replace every placeholder in the generated `SKILL.md`:
   frontmatter `name` (must equal the folder name) and `description` (≤200 chars,
   states "what" + "when to use it"). Follow the body skeleton and progressive
   disclosure tiers in [AGENTS.md](./AGENTS.md) §"Frontmatter contract" and
   `docs/skills-format.md`.
3. **Validate locally** — `skills-ref validate skills/<name>/` (or
   `pipx run skills-ref validate skills/<name>/`). Fix everything it reports.
4. **Commit** — Conventional Commits, one logical change per commit. New skills use
   `feat(skills): add <name>`.
5. **Push & open a PR** — branch `skill/<name>`, title `[skill] <name>: <summary>`,
   and paste the validator output in the PR body ("Skills-ref output: ..."). CI must
   be green; see [AGENTS.md](./AGENTS.md) §"Commit & PR conventions" for the reviewer
   checklist.

## Modifying an existing skill

1. **Edit** — change `skills/<name>/SKILL.md` (or its `references/`, `scripts/`,
   `assets/`). Keep frontmatter valid and `description` ≤200 chars.
2. **Validate** — `skills-ref validate skills/<name>/` before committing.
3. **Commit & push** — `fix(<name>): <summary>` on branch `fix/<name>-<issue>`,
   then open a PR with the validator output pasted in the body.

## Reviewing PRs

Reviews are open to anyone; the five-point checklist in [AGENTS.md](./AGENTS.md)
§"Commit & PR conventions" is the gate. Beyond it, judge prose and scope: does the
skill follow the six design principles in AGENTS.md §"Skill design principles", and
does its quick start run for a fresh agent with no hidden assumptions?

## Reporting issues

Found a broken install, a confusing skill, or a contract violation? Open a GitHub
issue describing the skill name, the `npx skills add` command you ran, and the full
error output. If you can, paste the output of
`skills-ref validate skills/<name>/` — it usually pinpoints the problem.

## Code of conduct

We expect contributors to be respectful, constructive, and patient with newcomers.
Reviews focus on the work, not the person; disagreement is fine, condescension is
not. A full CODE_OF_CONDUCT.md may be added later — until then, treat the spirit of
the Contributor Covenant as binding.

