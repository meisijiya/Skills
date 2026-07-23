---
name: slice-review
description: "Per-slice lightweight review (spec compliance + code quality — 2 verdicts in one reviewer). Use after each slice completes in incremental-implementation, before moving to the next slice. The reviewer reads the task-brief and review package produced by `task-brief.sh` and `review-package.sh`, then returns a verdict the orchestrator writes into the slice-progress.sh ledger. Dispatched in fresh subagent context (oracle / sisyphus-junior) so the verdict is not biased by orchestrator memory. Complements OMO `review-work` (which does whole-branch 5-lane review at the end). Triggers: 'review slice', 'slice review', 'task reviewer', 'per-slice review'. Adapted from Superpowers subagent-driven-development's `task-reviewer-prompt.md` (v6.0 merged the prior two-stage review into one reviewer, two ordered parts)."
allowed-tools: "Read Bash Grep"
---

# slice-review

Per-slice lightweight review. One reviewer (`task(subagent_type="oracle")` or
`task(category="unspecified-high")`) returns TWO ordered verdicts on a
single slice's diff:

1. **Spec compliance** — does the diff satisfy the brief's acceptance
   criteria and `Interfaces: Produces` contract?
2. **Code quality** — is the code well-written, consistent with
   neighboring files, no obvious smells?

This complements OMO's built-in `review-work` skill (which does
whole-branch 5-lane review at the end of the slice sequence). Per-slice
review catches mistakes early, before they compound across 5 more slices.

## When to Use

**Use after each slice completes**, before marking the slice complete in
`.omo/sdd/<slug>/progress.md` and moving to the next slice.

**NOT for:**
- Whole-branch review at end of slice sequence — use OMO `review-work`
- Cross-slice design questions — escalate to `oracle` agent
- Code-style-only review — use the language's linter / `ai-code-blindspots`

## Process

### 1. Generate the review package

Before dispatching the reviewer, the orchestrator (Atlas / Sisyphus)
must produce two files. Do NOT paste diffs inline — that pollutes the
orchestrator's context.

```bash
# Brief: structured metadata extracted to a file the executor read
BRIEF="$(~/.agents/skills/incremental-implementation/scripts/task-brief.sh <task-id>)"

# Record BASE before executor starts (or before reading the diff)
BASE="$(git rev-parse HEAD)"

# ... executor runs and produces commits ...

# Review package: commit list + stat + diff in one file
PKG="$(./scripts/review-package.sh <task-id> "$BASE" "$(git rev-parse HEAD)")"
```

Both scripts print the path on success. Embed the paths in the
reviewer's dispatch prompt below.

### 2. Dispatch the reviewer

The reviewer MUST be dispatched in a fresh sub-agent context (oracle or
unspecified-high) — NOT in the orchestrator's session, to avoid
inheritance of rationalization.

```
task(
  subagent_type="oracle",
  run_in_background=false,
  load_skills=[],
  description="Per-slice review for <task-id>",
  prompt="""
<role>You are a slice-reviewer returning TWO ordered verdicts on a single
slice's diff. Read these files once, then return your verdict.</role>

<brief_file>${BRIEF}</brief_file>
<review_package_file>${PKG}</review_package_file>
<global_constraints>
[paste verbatim from .omo/plans/<slug>.md Global Constraints section]
</global_constraints>

<inputs_summary>
The executor was dispatched to implement the slice described in the
brief above. Their commits are in the review package. Your job is
to verify the diff satisfies the brief and identify code quality issues.
DO NOT inherit the orchestrator's session context — you are a fresh
reviewer.
</inputs_summary>

<output_format>
Return exactly these two parts in this order:

**Part 1: Spec compliance** — ✅ / ❌ / ⚠️

For each acceptance criterion in the brief, mark ACHIEVED / MISSED /
PARTIAL with a one-line evidence reference (file:line in the diff).

For each item in the brief's `Interfaces: Produces`, confirm the
symbol is exported with the declared signature.

Mark ❌ if any acceptance criterion is unmet OR any production symbol
is missing or has a mismatched signature.

Mark ⚠️ for items you cannot verify from the diff alone (e.g.,
runtime behavior, unchanged-code references).

**Part 2: Code quality** — Approved / Needs fixes

Categorize findings:
- **Strengths** (1-3 bullets, optional)
- **Critical** (must-fix, blocks merge): correctness bug, security hole, data loss, broken acceptance
- **Important** (should-fix before merge): significant smell, pattern violation, type weakness
- **Minor** (nice-to-have): naming, doc, refactor opportunity

Each finding MUST cite `file:line` in the diff.

**Task quality verdict:** Approved / Needs fixes

If both verdicts pass → return the literal token `OK` on the last line.
Otherwise return `FAIL` and the orchestrator will dispatch a fixer
subagent.
</output_format>

<do_not>
- DO NOT trust the executor's self-reported "looks good" / "should pass"
  — re-verify from the diff.
- DO NOT re-run tests the executor already ran — read the GREEN
  evidence in the report file referenced by the brief, or the commit
  log in the review package.
- DO NOT pre-rate findings ("treat this as Minor at most") — you have
  full judgment authority.
- DO NOT add open-ended directives like "check all uses" — be
  specific.
</do_not>
"""
)
```

### 3. Triage verdict

| Part 1 | Part 2 | Action |
|---|---|---|
| ✅ | Approved | Mark slice complete in ledger; proceed to next slice |
| ❌ | any | Dispatch fixer subagent with all Critical + Important findings, then re-review |
| ⚠️ | any | Investigate the ⚠️ item manually (executor cannot verify it; usually requires reading unchanged code) — if real gap, treat as ❌; if false positive, treat as ✅ |
| any | Needs fixes | Dispatch fixer; re-review |
| ✅ or ⚠️ (after investigation) | any | Mark slice complete |

### 4. Mark complete in ledger

After the reviewer returns ✅ + Approved:

```bash
~/.agents/skills/incremental-implementation/scripts/slice-progress.sh mark-complete <task-id> <base-sha> <head-sha> \
    --review-verdict ok --plan <slug>
```

Never mark complete before review approves. Never re-dispatch a task
whose ledger row already says DONE — check the ledger + `git log` after
any compaction.

### 5. Re-review loops

If the fixer returns BLOCKED or the second review still finds Critical /
Important findings, do not loop indefinitely:

- After 2 fix attempts, dispatch `task(subagent_type="oracle")` with
  the full findings list and a request for an architectural decision
  (split the slice, change the spec, etc.).
- If the architectural decision is "the slice is wrong as specified,"
  return to brainstorming → spec → write a new slice with smaller scope.
- If it is "the implementation needs a different approach," dispatch
  the fix with the architectural hint.

## OMO Integration

| Layer | Mechanism |
|---|---|
| Per-slice review | **This skill** — `task(subagent_type="oracle")` or `task(category="unspecified-high")` |
| Whole-branch review | OMO built-in `review-work` skill — 5 parallel lanes |
| Dispatch isolation | Each slice-review happens in a fresh sub-agent context (oracle / unspecified-high inherit no session history) |
| Reviewer prompt template | Adapted from Superpowers v6.0 `task-reviewer-prompt.md` (one reviewer, two ordered parts) |
| Brief / review-package generation | `~/.agents/skills/incremental-implementation/scripts/task-brief.sh` + `./scripts/review-package.sh` (sibling skill `incremental-implementation` (paths above)) |
| Progress ledger | `~/.agents/skills/incremental-implementation/scripts/slice-progress.sh` — append-only, survives compaction |

**Complements OMO** by filling the per-slice gap; does not duplicate
`review-work`'s whole-branch 5-lane review.

## Why this layer exists

Without per-slice review, mistakes compound:

- Slice 1 introduces a wrong interface name
- Slice 2 builds on the wrong interface
- Slice 3 builds on Slice 2
- ...
- Whole-branch review at slice 10 finds 5 cascading bugs that all need
  rewrites

With per-slice review:

- Slice 1's wrong interface is caught before Slice 2 starts
- Slice 2's brief is regenerated with corrected Interfaces: Consumes
- Cascade is broken

Per-slice review adds ~30s per slice × N slices = cheap insurance against
hours of cascading rewrites.

## Red Flags

- Skip per-slice review "to save time" — single most common cause of
  cascading slice failures
- Trust executor's "looks good" without independent verification — by
  the time the whole-branch reviewer catches it, 5 slices have built on it
- Re-dispatch a slice whose ledger row already says DONE — check the
  ledger + `git log` after any compaction; trust them over your own
  recollection
- Pre-rate findings ("treat this as Minor at most") in the review
  prompt — the reviewer has full judgment authority
- Run tests the executor already ran in the review prompt — read the
  GREEN evidence from the executor's report file instead

## Verification

Before declaring slice-review complete for a slice, confirm:
- [ ] Brief path + review-package path embedded in reviewer dispatch
- [ ] Reviewer is a fresh sub-agent (oracle / unspecified-high), not the orchestrator's session
- [ ] Reviewer's output contains BOTH Part 1 (Spec compliance) AND Part 2 (Code quality)
- [ ] If both pass, ledger marked `DONE` for this task
- [ ] If either fails, fixer subagent dispatched with full findings + re-review loop
- [ ] Never re-dispatched a task whose ledger row says DONE
