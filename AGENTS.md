# Agent Development Contract

## Purpose

This repo is a public skills repository anchored to **Vercel `npx skills`** (v1.5.23+). Every skill in `skills/<name>/` is a SKILL.md file conforming to the [agentskills.io](https://agentskills.io/specification) spec. `AGENTS.md` (this file) is the binding contract for adding new skills or installing existing ones. Read it fully before opening a PR.

The contract exists because a skill repository fails silently: a frontmatter typo, a name mismatch, or a directory placement error means `npx skills add` either skips the skill or crashes with a confusing error. Everything below is either enforceable by tooling (the `skills-ref` validator, CI, the scaffold script) or is a convention that tooling cannot check (prose quality, scope discipline). Enforceable rules are marked **[enforced]**; conventions are marked **[convention]**.

### What the contract covers

Three audiences share this file:

- **Skill authors** follow §"Frontmatter contract", §"Create workflow", and §"Commit & PR conventions" to ship a skill that CI accepts and every agent can load.
- **Repo maintainers** use §"Commit & PR conventions" and the reviewer checklist to keep the repository discoverable and consistent.
- **End users** follow §"Install workflow" to install skills; the risk model in `README.md` §Security tells them what to audit before they trust a skill.

### What the contract does NOT cover

The contract governs skill *format and process*, not skill *content quality* beyond the six design principles in §"Skill design principles". A skill can pass `skills-ref validate` and CI and still be a bad skill — confusing prose, wrong tool choices, or missing gotchas are judgment calls for reviewers, not linters.

## Skill discovery

Vercel `npx skills` discovers skills by walking the repo for `**/SKILL.md` files (per its [skill discovery rules](https://github.com/vercel-labs/skills/blob/main/README.md#skill-discovery)). We adopt the `skills/<name>/SKILL.md` convention (one folder per skill) for monorepo-style multi-skill repos. The `_template/` directory is a scaffold and is **excluded** from discovery (see `docs/skills-format.md` §"Why `_template/` is not a skill").

End users install via: `npx skills add <owner>/<repo>`. This symlinks (or copies with `--copy`) each skill into the user's chosen agent's discovery path (e.g. `.agents/skills/` for opencode, `.claude/skills/` for Claude Code).

Implications you must internalize:

- **[enforced]** The directory name under `skills/` IS the skill name. No exceptions, no aliases.
- **[enforced]** A `SKILL.md` placed anywhere else (e.g. repo root, `docs/`) is not a skill — it is documentation.
- **[convention]** One skill = one folder = one `SKILL.md`. Do not nest skills inside skills.
- **[convention]** Everything a skill needs (scripts, references, assets) lives inside its own folder, so installing the folder installs the whole skill.

### Discovery is the entire distribution channel

There is no registry, no publish step, no manifest to update. When the repo is pushed to GitHub, every valid `SKILL.md` under `skills/` is immediately installable. This is why the contract is strict about placement: a typo'd folder name (`skills/PDF-extract/`) or a misplaced file (`docs/SKILL.md`) is not a broken build — it is a silently undiscoverable skill, which is worse.

### The two failure modes this contract prevents

1. **Silent skip.** The CLI walks the tree, finds a `SKILL.md` whose frontmatter or location doesn't conform, and skips it without an error the author will ever see. `skills-ref validate` + CI exist to make this failure loud, in the PR, before merge.
2. **Confusing crash.** A malformed YAML block or a `name` that doesn't match its directory can make `npx skills add` fail partway through install, leaving the user's agent directory half-populated. The validator catches these before they ship.

## Frontmatter contract

Every `SKILL.md` starts with YAML frontmatter delimited by `---` lines. The following table is authoritative for this repo; `docs/skills-format.md` expands it with worked examples.

| Field | Required | Constraint |
|---|---|---|
| `name` | yes | 1–64 chars, lowercase, hyphen separators, no leading/trailing `-`, no consecutive `--`. **Must match parent directory name exactly.** |
| `description` | yes | 1–1024 chars. **Keep ≤200 chars** for Claude.ai upload compatibility. State what the skill does AND when to use it. |
| `license` | no | SPDX identifier (e.g. `MIT`) or path to a LICENSE file |
| `compatibility` | no | ≤500 chars; environment requirements (target products, system packages, network access) |
| `metadata` | no | string→string map; ignored by clients unless client-specific keys are documented in `docs/skills-format.md` |
| `allowed-tools` | no | **experimental**; do NOT use as a security boundary; client support varies (see `docs/skills-format.md` §"allowed-tools") |

> **Forbidden fields**: `metadata.internal` (Vercel CLI-specific extension; ignored by opencode and Claude Code, leads to inconsistent visibility), `allowed-tools` as security boundary.

Additional frontmatter rules:

- **[enforced]** The frontmatter block MUST be the first thing in the file, starting at line 1 with `---` and ending with a closing `---` line. No comments, no BOM, no text above it.
- **[enforced]** `name` MUST equal the parent directory name exactly (case-sensitive). `skills/pdf-extract/` requires `name: pdf-extract`.
- **[enforced]** `name` MUST match `^[a-z0-9]+(-[a-z0-9]+)*$`. This is stricter than the raw spec (which allows 1–64 chars, lowercase, hyphen separators) — we deliberately reject names with consecutive `--`, leading/trailing hyphens, underscores, or uppercase.
- **[enforced]** `description` MUST state two things: what the skill does, and when an agent should use it. A description that only names the domain ("Git helper") is rejectable.
- **[convention]** YAML values are plain scalars unless documented otherwise. Keep the whole frontmatter ≤10 lines; put long prose in the body.

The `skills-ref` validator enforces the `name`/directory match and the frontmatter shape. CI runs it against every skill on every push and PR (see `.github/workflows/lint-skills.yml`).

### Why the `name`/directory rule is the single most important rule

Every client — Vercel CLI, opencode, Claude Code — identifies a skill by the directory it lives in. The frontmatter `name` exists so the skill can identify *itself* consistently when its instructions are read without filesystem context. When the two disagree, clients disagree on what the skill is called, and features that route by name (invocation, listing, telemetry) silently misroute. That is why the rule is **[enforced]** and why CI fails the PR rather than warning.

### Minimal valid frontmatter example

```markdown
---
name: pdf-extract
description: Extract text and tables from PDF files. Use when the user mentions a .pdf file or asks to pull content out of one.
license: MIT
---
```

Three lines, two required fields. Everything below the closing `---` is tier-2 body. If you add more fields (`compatibility`, `metadata`), keep the whole block ≤10 lines — long prose belongs in the body.

### Description writing guide

A good `description` is two sentences: capability first, trigger second.

- Good: "Extract text and tables from PDF files. Use when the user mentions a .pdf file or asks to produce one."
- Bad: "Git helper" (no trigger — the agent never loads it)
- Bad: "A comprehensive, flexible, multi-purpose utility for working with version control systems in a wide variety of scenarios" (no capability clarity, marketing prose, >200 chars risk)

Count characters before you commit: `printf '%s' "$(grep '^description:' skills/<name>/SKILL.md)" | wc -c` must be ≤200 for Claude.ai upload safety.

### Why `description` has two jobs

The `description` is loaded at discovery time — before the body — and is the only text a client sees when deciding whether to load the skill. It must therefore answer two questions in ≤200 chars:

1. **What** the skill does (its capability).
2. **When** an agent should use it (its trigger conditions).

A description that says only "Helps with git" fails job two: the agent cannot know when to load it, so it never does. Write both halves; see `skills/_template/SKILL.md` for the pattern.

### Common frontmatter mistakes (all caught by `skills-ref` or CI)

- `name: pdf_extract` — underscore; must be `pdf-extract`
- `name: PDF-Extract` — uppercase; must be lowercase
- `name: pdf--extract` — consecutive hyphens; rejected by our stricter regex
- `name: -pdf-extract` or `pdf-extract-` — leading/trailing hyphen
- `description: Git helper` — no "when to use it" half
- frontmatter not at line 1 — a comment or blank line above `---`
- `metadata.internal:` present — forbidden field, inconsistent client support
- `allowed-tools:` used to enforce security — experimental; see `docs/skills-format.md` §"allowed-tools"

### Skill design principles

These six principles govern how to write a *good* skill. They are **verbatim** from [libukai/awesome-agent-skills](https://github.com/libukai/awesome-agent-skills/blob/main/README.md) §"设计原则" (verified via raw README fetch 2026-08-21).

- **从真实任务中提炼**：优先使用实际执行步骤、人工纠正、项目文档、故障案例和历史修复，而不是让模型凭通用知识生成空泛流程。 (Extract from real tasks: prefer real execution steps, human corrections, project docs, failure cases, and historical fixes over generic model-generated flow.)
- **保持边界完整**：一个 Skill 应覆盖一个可组合、可独立验收的任务单元；过窄会增加加载和冲突成本，过宽则难以准确触发。 (Keep boundaries complete: one skill = one composable, independently verifiable task unit; too narrow costs loading/conflict overhead, too wide fails to trigger accurately.)
- **节约上下文**：只写 Agent 容易做错或无法自行知道的内容，把细节拆到聚焦的引用文件，并明确何时读取。 (Save context: write only what agents get wrong or cannot know themselves; push details into focused reference files and say when to read them.)
- **校准控制强度**：脆弱、不可逆或顺序敏感的步骤写得严格；存在多种合理路径的任务说明目标与原因，保留判断空间。 (Calibrate control strength: write fragile, irreversible, or order-sensitive steps strictly; for tasks with multiple reasonable paths, state goals and reasons and leave room for judgment.)
- **提供默认方案**：优先给出一个可靠默认和必要的退出路径，使用可复用流程，不要堆砌平级选项或只针对单次任务的答案。 (Provide a default: give one reliable default plus a necessary exit path, use reusable flows; don't pile up sibling options or one-off answers.)
- **内置反馈闭环**：使用 Gotchas、输出模板、检查清单、验证循环和 plan-validate-execute，让失败能够产生下一轮可复用的修正。 (Build in feedback loops: use Gotchas, output templates, checklists, verification loops, and plan-validate-execute so failures produce reusable corrections.)

How the six principles map to this repo's structure:

- *从真实任务中提炼* → write skills from real sessions and real fixes, not imagination. Before writing, collect the actual commands that worked and the actual errors that occurred.
- *保持边界完整* → one folder = one verifiable task unit. Split or merge skills until each one passes "could a reviewer verify this skill independently?"
- *节约上下文* → tier-1 frontmatter stays tiny; tier-2 body stays focused; tier-3 `references/` holds the detail (see `docs/skills-format.md` §"Progressive disclosure tiers").
- *校准控制强度* → order-sensitive steps (irreversible deletes, credential rotations) get numbered, verbatim commands; judgment calls get goals and reasons.
- *提供默认方案* → every workflow names ONE default path. Alternatives go in a "If the default doesn't apply" note, not as sibling options at the top.
- *内置反馈闭环* → skills carry gotchas, checklists, and validation steps so a failure produces a reusable correction, not a dead end.

> Source: [libukai/awesome-agent-skills](https://github.com/libukai/awesome-agent-skills) §设计原则. Reused with intent — these are general principles refined from Anthropic/Google internal guides, not libukai-original.

## Directory layout

Each skill follows this shape:

```
<skill-name>/
├── SKILL.md          # required; frontmatter + instructions
├── references/       # optional; tier-3 resources loaded on demand
├── scripts/          # optional; executable code
├── assets/           # optional; templates, images, data
└── ...               # anything else the skill needs
```

- `SKILL.md` is the only required file. Everything else exists to keep `SKILL.md` small.
- `references/` holds detail the agent loads only when the task needs it (deep dives, tables, checklists >~50 lines, API docs).
- `scripts/` holds executable code. Anything that runs MUST be reviewed as code, not prose — see the risk model in `README.md` §Security.
- `assets/` holds non-instructional material: templates, images, sample data.
- Empty subdirectories are kept in git with `.gitkeep` so the scaffold survives checkout.

See `docs/skills-format.md` §"Progressive disclosure tiers" for the loading-cost rationale (metadata → instructions → resources).

### Why this shape and not a flat file

A single-file skill forces a trade: either the `SKILL.md` grows until it costs thousands of tokens every time the skill loads, or the detail that would have prevented a mistake gets cut. The directory shape breaks that trade by loading tiers:

1. Frontmatter (always loaded — must be cheap)
2. Body (loaded on activation — must be focused)
3. `references/` (loaded on demand — can be as deep as needed)

`scripts/` and `assets/` are the *things the skill needs to run*, not prose. Keep them out of the body; reference them by relative path so the skill works when symlinked into another agent's directory.

## Install workflow (引入)

To install one skill from this repo:

1. `cd <this-repo>` (or clone it)
2. Verify the skill exists: `ls skills/<name>/SKILL.md`
3. Install locally: `npx skills add <owner>/<repo> --skill <name>`

### Global install

Add `-g` to make skills available across every project on the machine:

```bash
npx skills add <owner>/<repo> -g
```

Notes:

- Install is a symlink by default (updates propagate); use `--copy` for a frozen snapshot.
- To pin a specific version, install from a tag or commit: `npx skills add <owner>/<repo>@<tag-or-sha>`.
- If the skill doesn't show up, re-check discovery: the folder must be directly under `skills/`, named `skills/<name>/SKILL.md`.

### What install actually does

`npx skills add` fetches the repo, walks it for `SKILL.md` files, and links each skill into the target agent's discovery directory (`.agents/skills/` for opencode, `.claude/skills/` for Claude Code, and so on). From that moment the agent sees the skill's frontmatter at startup and loads its body on activation. Uninstalling is just removing the link; removing a symlinked skill does not touch the source repo.

### What agents actually see

At startup, an agent's client loads only each skill's frontmatter and renders it as a short availability list (opencode-style):

```xml
<skill>
  <name>pdf-extract</name>
  <description>Extract text and tables from PDF files. Use when the user mentions a .pdf file.</description>
  <location>/path/to/.agents/skills/pdf-extract/SKILL.md</location>
</skill>
```

The agent decides to activate a skill based on this list alone — which is exactly why `description` must state both "what" and "when". The body is only read after activation, so a bad description means the skill is never loaded even though the body is perfect.

### Troubleshooting a skill that doesn't show up

In order:

1. Confirm the folder is `skills/<name>/SKILL.md` — not `skills/<name>/docs/SKILL.md`, not repo-root `SKILL.md`.
2. Confirm frontmatter `name` equals the folder name exactly.
3. Confirm the frontmatter block starts at line 1 with no text above it.
4. Run `skills-ref validate skills/<name>/` — if it fails, the fix is what it reports.
5. Re-run install with a pinned ref: `npx skills add <owner>/<repo>@<tag-or-sha> --skill <name>`.

## Create workflow (创建)

To add a new skill:

1. Verify name is kebab-case, ≤64 chars, matches a real concept (no `test`, `temp`, `foo`, `bar`)
2. Run `./scripts/new-skill.sh <name>` (or copy `skills/_template/SKILL.md` manually)
3. Fill in frontmatter (`name`, `description` MUST; `license`, `compatibility`, `metadata` OPTIONAL); write body following progressive disclosure tiers
4. Local self-check before committing: `skills-ref validate skills/<name>/` (or `pipx run skills-ref validate skills/<name>/`)

   > Install note: the git source of `skills-ref` provides the `skills-ref` console
   > script; the PyPI package (0.1.1) currently installs it as `agentskills`
   > (verified 2026-08-21). If your `skills-ref` command is missing, check
   > `agentskills` or reinstall from git:
   > `pip install git+https://github.com/agentskills/agentskills.git#subdirectory=skills-ref`.

### What the scaffold script does and does not do

`scripts/new-skill.sh` creates `skills/<name>/` with `SKILL.md` rendered from `skills/_template/SKILL.md` and empty `references/`, `scripts/`, `assets/` subdirs. It validates the name and refuses to overwrite an existing skill. It does NOT write your content — every placeholder in the rendered `SKILL.md` is your job to replace. Run it with `--dry-run` first if you want to see what it will create.

### Naming checklist

A good name is what a user would type to find the skill:

- `pdf-extract` — good: lowercase, hyphenated, names a concrete task
- `git-commit-message` — good: specific without being narrow
- `PDF-Extract` — bad: uppercase (rejected by regex)
- `git--commit` — bad: consecutive hyphens (rejected by our stricter regex)
- `-leading` / `trailing-` — bad: edge hyphens
- `test`, `temp`, `foo`, `bar` — bad: not real concepts
- `agent-skill-generic-helper-do-everything` — bad: too wide to trigger accurately (see §"Skill design principles", *保持边界完整*)

### Writing the body: an annotated skeleton

After the scaffold renders, the body of your `SKILL.md` should follow this shape (sections are templates, not mandates — drop the ones you don't need):

```markdown
# <Skill Title>            # H1 derived from the name

## When to use             # trigger conditions — the "when" half of description, expanded
## Quick start             # numbered steps a fresh agent can follow cold
## Workflow                # detailed order-sensitive steps (add if Quick start isn't enough)
## Examples                # fenced blocks showing concrete input → output
## References              # relative paths into references/ (tier-3, loaded on demand)
```

Writing rules, in order of importance:

1. Write the `## When to use` section first — it is the in-body mirror of the frontmatter trigger and the single most miswritten section in practice.
2. Give ONE default path per workflow. Alternatives go in a trailing "If the default doesn't apply" note.
3. Move anything longer than ~50 lines of detail into `references/` and link it with a relative path.
4. End with a verification step or checklist so a failure produces a correction, not a dead end (see §"Skill design principles", *内置反馈闭环*).
5. Run `skills-ref validate` before committing; paste its output in the PR body.

### PR workflow

Branch → commit → push → open PR → CI green → review. CI runs `skills-ref validate` on every skill plus a Vercel CLI discovery check; both must pass before review. The PR body must paste the validator output (see §"Commit & PR conventions").

## Commit & PR conventions

- Branch naming: `skill/<name>` for new skills, `fix/<skill>-<issue>` for fixes
- Commit messages: Conventional Commits (`feat:`, `fix:`, `docs:`, `chore:`, `refactor:`, `test:`)
- PR title format: `[skill] <name>: <imperative summary>` or `[fix] <skill>: <imperative summary>`
- PR body MUST include: "Skills-ref output: <paste validator output>"

Reviewer checklist:

- [ ] Frontmatter passes `skills-ref validate skills/<name>/` (paste output in PR body)
- [ ] `description` ≤200 chars and states "what" + "when to use it"
- [ ] No `metadata.internal` (or other forbidden fields) present
- [ ] Progressive disclosure respected — tier-1 metadata is small, tier-2 body is focused, tier-3 resources are on-demand
- [ ] Example runnable — the skill's quick-start steps can be executed by a fresh agent without hidden assumptions

### Why the PR body must paste validator output

CI enforces the validator, but CI output is ephemeral and reviewers shouldn't have to navigate to the Actions tab to see whether lint passed. The pasted output makes the check part of the review record — and if the CI job and the local run disagree, the paste shows which one the author actually ran.

### Commit hygiene

One logical change per commit. A new skill is one commit (`feat(skills): add <name>`); a fix to an existing skill is one commit (`fix(<name>): <summary>`). Do not bundle unrelated skill edits in one commit — the commit list IS the changelog for a repo this small.

### What CI checks (and what it can't)

CI runs two gates on every PR (see `.github/workflows/lint-skills.yml`):

1. **`lint`** — a matrix job running `skills-ref validate skills/<name>/` over every skill (dynamically enumerated from `skills/`, `_template/` excluded). Catches: frontmatter shape errors, `name`/directory mismatch, forbidden fields, kebab-case violations.
2. **`discover-skills`** — runs `npx skills@latest add . --list` with the Vercel CLI itself. Catches the failure mode the validator cannot see: a repo that lints clean but is not discoverable by the actual installer (bad folder placement, `SKILL.md` somewhere the CLI doesn't look).

Neither gate checks prose quality, tool choice, or scope discipline — that's the reviewer checklist above.

## Distribution & discovery

Once the repo is pushed to GitHub, **anyone** can install skills via `npx skills add <owner>/<repo>`. No registry submission required.

Vercel `npx skills` automatically reports install telemetry (opt-out: `DISABLE_TELEMETRY=1`), which populates the [skills.sh](https://skills.sh) leaderboard. We do not opt out — discoverability is a feature.

### What discoverability depends on

Nothing beyond a pushed repo and valid `SKILL.md` files. That means the contract IS the publication process: conform to it, push, done. It also means a broken skill ships instantly to anyone who installs the repo — which is why CI's `discover-skills` job re-runs the Vercel CLI's own discovery on every PR, so the repo can never claim to be installable while actually failing discovery.

### Local discovery self-check

Before pushing, reproduce what CI will do, from the repo root:

```bash
skills-ref validate skills/<name>/   # format gate
npx skills@latest add . --list                   # installer gate (lists skills, excludes _template)
```

If the first passes but the second doesn't list your skill, the problem is placement (folder name, file location) — see §"Troubleshooting a skill that doesn't show up".

## References

- [agentskills.io specification](https://agentskills.io/specification) — canonical frontmatter spec
- [Vercel skills CLI README](https://github.com/vercel-labs/skills/blob/main/README.md) — discovery rules, install flags
- [opencode skills docs](https://opencode.ai/docs/skills/) — agent-side skill loading
- [libukai/awesome-agent-skills](https://github.com/libukai/awesome-agent-skills) — source of the §"Skill design principles" section
- [docs/skills-format.md](./docs/skills-format.md) — full format reference
- [CONTRIBUTING.md](./CONTRIBUTING.md) — human-facing quickstart
