# skills-archived/

Read-only archive of retired skills. These skills are **never installed**, **never
auto-discovered**, and **never indexed** by the marketplace, install script, or
AGENTS.md inject.

## Contents

- `pwf-enforcer/` — OpenCode plugin template that hard-enforced the
  [planning-with-files](https://github.com/OthmanAdi/planning-with-files) workflow.
  Retired on 2026-07-23 per ADR 0001 (OMO-native migration). The plugin source
  (`templates/pwf-enforcer.ts`) is preserved as a historical reference for users
  who want to write a similar Tier-3 advisory plugin for another workflow.

## Why archived (not deleted)

External forks, blog posts, and user memory may still reference the old skill
name. Keeping the source at this stable path makes a single
`git mv ... && rm .opencode/plugins/pwf-enforcer.ts` cleanup possible for any
user who wants to fully excise it.