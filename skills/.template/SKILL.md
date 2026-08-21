---
name: <skill-name-kebab-case>
description: <One-sentence "what" + one-sentence "when to use it", ≤200 chars total>
license: MIT
metadata:
  internal: true
---

# <Skill Title>

<!-- TODO: replace <Skill Title> with the capitalized, human-readable title of the skill. -->

<!-- TODO: replace <skill-name-kebab-case> with the kebab-case skill name (MUST equal the parent directory name). -->

<!-- TODO: replace <One-sentence "what" + one-sentence "when to use it", ≤200 chars total> with a real description. State what the skill does AND when an agent should use it. -->

## When to use

<!-- TODO: replace with trigger conditions — the "when" half of the description, expanded.

Write this section FIRST. It is the single most miswritten section in practice: an agent
decides whether to load this skill based on the frontmatter description and this section.
List concrete signals (file types, user phrasing, task shapes) that should activate it,
and equally concrete signals that mean "not this skill". -->

Trigger this skill when <concrete signal 1> or <concrete signal 2>. Do not use it for
<adjacent-but-out-of-scope case>.

## Quick start

<!-- TODO: replace with numbered steps a fresh agent can follow cold, without reading
any other file. Each step is one action; paste the exact command or wording to use. -->

1. <First action, with the exact command or wording>
2. <Second action>
3. <Verification: what output proves it worked>

## Workflow

<!-- TODO: replace with detailed order-sensitive steps. Add this section only if Quick
start isn't enough; if the workflow is fully captured above, delete this section.

- Number irreversible, order-sensitive, or fragile steps; paste commands verbatim.
- For judgment calls, state the goal and the reason, leave room for discretion.
- Give ONE default path; alternatives go in a trailing "If the default doesn't apply" note. -->

1. <Step — irreversible/order-sensitive actions get numbered, verbatim commands>
2. <Step>
3. <Step>

If the default doesn't apply, <alternative path>.

## Examples

<!-- TODO: replace with fenced blocks showing concrete input → output. One example
that a reviewer can run end-to-end beats three hypothetical snippets. -->

```bash
<concrete command>
<expected output>
```

## References

<!-- TODO: replace with relative paths into references/ (tier-3 resources loaded on
demand), plus a one-line note of when to read each. Delete this section if there are
no reference files. -->

- [`references/<file>.md`](references/<file>.md) — <when to read it>
