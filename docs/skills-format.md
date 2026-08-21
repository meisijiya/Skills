# SKILL.md format reference

## Overview

`SKILL.md` is a Markdown file with YAML frontmatter, located at `skills/<name>/SKILL.md`.
Clients load it in three progressive tiers: metadata at startup, instructions on
activation, and resources on demand. This document expands the frontmatter table and
directory layout in `AGENTS.md` §"Frontmatter contract" / §"Directory layout" with
worked examples. When this file and `AGENTS.md` disagree, `AGENTS.md` wins.

## Tier 1: metadata (~100 tokens)

What clients load at **startup**, for every skill, before any task arrives: the YAML
frontmatter, principally `name` and `description`. This tier must stay tiny — it is
rendered into every prompt as an availability list. Example of how opencode surfaces it:

```xml
<skill>
  <name>pdf-extract</name>
  <description>Extract text and tables from PDF files. Use when the user mentions a .pdf file.</description>
  <location>/path/to/.agents/skills/pdf-extract/SKILL.md</location>
</skill>
```

The agent decides whether to activate a skill from this list alone. A frontmatter
`description` that omits the trigger half means the skill is never loaded, no matter
how good the body is.

## Tier 2: instructions (<5000 tokens recommended)

What clients load when a skill **activates**: the body of `SKILL.md` after the
frontmatter. Best practices:

- **Imperative voice.** Tell the agent what to do, not what the skill is about.
- **Concrete examples.** One runnable input → output pair beats three hypotheticals.
- **No marketing prose.** Every sentence should change agent behavior; cut the rest.
- **Default path first.** Name ONE reliable way to do the task; alternatives go in a
  trailing "If the default doesn't apply" note (see the design principles in
  `AGENTS.md` §"Skill design principles", *提供默认方案*).
- **End with verification.** A checklist or validation step so a failure produces a
  reusable correction, not a dead end (*内置反馈闭环*).

## Tier 3: resources (on demand)

What the agent reads **only when it needs them**:

- `references/` — deep dives, tables, checklists >~50 lines, API docs. Keep individual
  files <500 lines; link from `SKILL.md` with relative paths (e.g.
  `references/api.md`) and say when to read each.
- `scripts/` — executable code the skill runs. Reviewed as code, not prose; see the
  risk model in `README.md` §Security.
- `assets/` — non-instructional material: templates, images, sample data.

The tier exists because every line of the body is loaded on every activation; pushing
detail into `references/` keeps the body focused without losing the detail.

## Frontmatter field reference

| Field | Required | Constraint |
|---|---|---|
| `name` | yes | 1–64 chars, lowercase, hyphen separators, no leading/trailing `-`, no consecutive `--`. **Must match parent directory name exactly.** |
| `description` | yes | 1–1024 chars. **Keep ≤200 chars** for Claude.ai upload compatibility. State what the skill does AND when to use it. |
| `license` | no | SPDX identifier (e.g. `MIT`) or path to a LICENSE file |
| `compatibility` | no | ≤500 chars; environment requirements (target products, system packages, network access) |
| `metadata` | no | string→string map; ignored by clients unless client-specific keys are documented below |
| `allowed-tools` | no | **experimental**; do NOT use as a security boundary; client support varies |

Worked examples:

**Minimal (all you need for most skills):**

```yaml
---
name: pdf-extract
description: Extract text and tables from PDF files. Use when the user mentions a .pdf file or asks to pull content out of one.
license: MIT
---
```

**With optional fields:**

```yaml
---
name: browser-automation
description: Drive a headless browser to fill forms, take screenshots, and scrape pages. Use when a task needs real browser interaction.
license: MIT
compatibility: Requires Playwright and a Chromium install; needs network access for scraping.
metadata:
  trigger-words: "browser, screenshot, scrape, headless"
---
```

**`license`** as a path instead of an identifier (when a skill carries its own license text):

```yaml
license: LICENSE.md
```

**`compatibility`** states what the environment must provide; clients use it to warn
the user before installing a skill their setup can't run.

**`metadata`** is a string→string map. Generic keys are ignored by clients; a
client-specific key is only meaningful when that client documents it. The only
metadata-style key with real semantics in some clients is the forbidden
`metadata.internal` — see below.

### allowed-tools

`allowed-tools` is **experimental** and client support varies widely (the Vercel CLI
understands it; opencode and Claude Code currently do not enforce it the same way, if
at all). Use it as documentation of intent if you like, but NEVER as a security
boundary: an untrusted skill can simply omit the field, and enforcing clients disagree
on its semantics. The real security guidance lives in `README.md` §Security.

## Forbidden fields

- **`metadata.internal`** — a Vercel CLI-specific extension. Ignored by opencode and
  Claude Code, so a skill that relies on it is visible on one client and invisible on
  another. Leads to inconsistent visibility; do not use.
- **`allowed-tools` as security boundary** — experimental, inconsistent support (see
  §"allowed-tools"). Listing a tool here does not prevent an agent from using it.

## Naming rules

- Regex: `^[a-z0-9]+(-[a-z0-9]+)*$`
- 1–64 chars, lowercase letters, digits, single hyphens between segments
- **[enforced]** The directory name under `skills/` IS the skill name, and frontmatter
  `name` must equal it exactly (case-sensitive)

| Example | Verdict | Why |
|---|---|---|
| `pdf-extract` | good | lowercase, hyphenated, names a concrete task |
| `git-commit` | good | specific without being narrow |
| `PDF-Extract` | bad | uppercase |
| `pdf--extract` | bad | consecutive hyphens |
| `-leading` | bad | leading hyphen |
| `trailing-` | bad | trailing hyphen |
| `pdf_extract` | bad | underscore |
| `foo`, `test`, `temp` | bad | not real concepts |

## Why `.template/` is not a skill

Vercel CLI's discovery walks `skills/` looking for `SKILL.md` files — it does **not**
treat the leading dot as an exclusion marker (that is the conventional "scaffold"
naming only). The actual exclusion is in the frontmatter:

```yaml
metadata:
  internal: true
```

The Vercel CLI hides any skill with `metadata.internal: true` from default discovery
(skills with `INSTALL_INTERNAL_SKILLS=1`). This repo's CI also excludes `.template/`
explicitly from its enumeration, so the validator only runs over real skills. Both
mechanisms together keep `.template/` out of every install path without depending on
the Vercel CLI's walker defaults. The template's frontmatter `name:
<skill-name-kebab-case>` does not match its directory name, and its body is full of
`<!-- TODO: ... -->` placeholders; both would fail validation by design.
`scripts/new-skill.sh` renders the template into a real, valid skill directory;
hand-copying requires the rename + placeholder-replacement steps documented in
`skills/.template/README.md`.
