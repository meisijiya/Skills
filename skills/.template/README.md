# Why `.template/` is not a skill

`skills/.template/` is the scaffold that `scripts/new-skill.sh` renders into new
skills — it is **not** a real skill and must never be installed or listed.

Three things keep it out of discovery:

1. **`metadata.internal: true` in the frontmatter.** This is the actual Vercel CLI
   exclusion mechanism: the CLI hides any skill marked `internal: true` from default
   discovery (visible only when `INSTALL_INTERNAL_SKILLS=1`). The leading-dot directory
   is a conventional naming marker — Vercel CLI's walker descends into `skills/.template/`
   the same way it descends into `skills/hello-world/`; what hides the template is the
   frontmatter flag, not the directory name.
2. **CI-level exclusion.** This repo's `lint-skills.yml` enumerates `skills/` and
   filters out `.template/` before running the validator and the `npx skills
   --list` discovery check, so the scaffold never reaches either gate.
3. **Deliberately invalid placeholders.** The template's `name: <skill-name-kebab-case>`
   does not match its directory name, and its body is full of `<!-- TODO: ... -->`
   markers. After `new-skill.sh` substitutes the real name, the skill becomes valid.

If you copy `.template/` by hand instead of using the script, you must:

- rename the directory to your kebab-case skill name,
- remove the `metadata.internal: true` line,
- replace `name:`, `description:`, and every `<!-- TODO: ... -->` marker,
- run `skills-ref validate skills/<name>/` before committing.

For the full rules, see [AGENTS.md](../../AGENTS.md) §"Create workflow".