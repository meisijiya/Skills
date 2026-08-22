# Agent Skills

A public repository of agent skills, distributed through **Vercel `npx skills`**. Each
skill in `skills/<name>/` is a self-contained `SKILL.md` conforming to the
[agentskills.io](https://agentskills.io/specification) spec, installable with a single
command:

```bash
npx skills add <!-- TODO: replace OWNER/REPO -->OWNER/REPO<!-- /TODO -->
```

The binding contract for adding or installing skills lives in [AGENTS.md](./AGENTS.md) —
read it before opening a PR.

## Install

Project-local install (all skills):

```bash
npx skills add <!-- TODO: replace OWNER/REPO -->OWNER/REPO<!-- /TODO -->
```

Global install (all skills, available to every project):

```bash
npx skills add <!-- TODO: replace OWNER/REPO -->OWNER/REPO<!-- /TODO --> -g
```

Install a single skill:

```bash
npx skills add <!-- TODO: replace OWNER/REPO -->OWNER/REPO<!-- /TODO --> --skill hello-world
```

## Repository layout

```
skills/
├── .template/       # SKILL.md scaffold (not a real skill; uses metadata.internal to exclude from Vercel CLI discovery)
└── hello-world/     # example skill
AGENTS.md            # the contract (read this)
CONTRIBUTING.md      # contributor-facing quickstart
docs/skills-format.md # full SKILL.md format spec
scripts/new-skill.sh  # create a new skill from template
.github/workflows/lint-skills.yml # CI lint
docs/awesome-skills.md   # curated pointers to license-incompatible upstream skills
```

## Contributing

See [CONTRIBUTING.md](./CONTRIBUTING.md) for the quickstart; the authoritative contract
is [AGENTS.md](./AGENTS.md).

## License

[MIT](./LICENSE)

## Security

**Risk model.** SKILL.md descriptions influence skill selection; the body changes agent
behavior; `scripts/` can read files, call networks, and touch credentials. Before
installing: skim the SKILL.md, audit `scripts/`, pin a tag/commit for reproducibility.
Format-valid frontmatter is NOT a security guarantee.

See [AGENTS.md](./AGENTS.md) for the full contract.
