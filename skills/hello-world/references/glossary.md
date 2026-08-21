# Glossary

Contract terms used across this repo, in the order the contract introduces them.

- **frontmatter** — the YAML block delimited by `---` lines at the top of a
  `SKILL.md`. Contains `name` (required) and `description` (required), plus optional
  `license`, `compatibility`, `metadata`, `allowed-tools`.
- **progressive disclosure** — the three-tier loading model: tier-1 metadata is loaded
  at startup, tier-2 body on activation, tier-3 `references/` files on demand. Keeps
  the always-loaded surface tiny while retaining depth.
- **`_template/`** — the scaffold directory under `skills/`. Not a real skill: its
  `_` prefix excludes it from Vercel CLI discovery and CI, and its placeholders are
  deliberately invalid frontmatter. `scripts/new-skill.sh` renders it into real
  skills.
- **`skills-ref`** — the official Python validator (`skills-ref validate <path>`)
  that enforces the frontmatter contract: `name` matches the parent directory,
  valid `description`, kebab-case naming, no forbidden fields.
- **discovery** — the process by which `npx skills` walks the repo for `**/SKILL.md`
  files. There is no registry or publish step; being discoverable IS being published.
