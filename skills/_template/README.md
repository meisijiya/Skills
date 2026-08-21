# Why `_template/` is not a skill

`skills/_template/` is the scaffold that `scripts/new-skill.sh` renders into new
skills — it is **not** a real skill and must never be installed or listed.

Three things keep it out of discovery:

1. **The leading underscore.** Vercel `npx skills` and the repo's own CI (`lint-skills.yml`)
   both exclude directories under `skills/` whose names start with `_`. The underscore is
   the conventional "scaffold, not a skill" marker for this repo (and Vercel CLI treats
   it as excluded from discovery).
2. **Deliberately invalid frontmatter.** The template's `name: <skill-name-kebab-case>`
   does not match its directory name, so any validator that did see it would fail it —
   by design. It is only valid after `new-skill.sh` substitutes the real name.
3. **`<!-- TODO: ... -->` markers everywhere.** A template full of placeholders is not
   runnable content; the TODOs exist to force a contributor to replace every placeholder.

If you copy `_template/` by hand instead of using the script, you must:

- rename the directory to your kebab-case skill name,
- replace `name:`, `description:`, and every `<!-- TODO: ... -->` marker,
- run `skills-ref validate skills/<name>/` before committing.

For the full rules, see [AGENTS.md](../../AGENTS.md) §"Create workflow".
