# `scripts/` in this skill directory — SDD (Subagent-Driven Development) layer

Three shell scripts that fill the gap between OMO's task tools and
Superpowers-style per-slice discipline. Each script is dependency-light
(`bash` + `jq` + `git`) and prints a single output path on success for
easy embedding into dispatch prompts.

## Why this layer exists

OMO 4.19.1 provides:

| OMO mechanism | Path |
|---|---|
| Task tools | `task_create` / `task_update` / `task_list` / `task_get` → JSON at `$OPENCODE_CONFIG_DIR/tasks/<list-id>/T-<uuid>.json` |
| Boulder state | `.omo/boulder.json` (schema v2) |
| Notepad | `.omo/notepads/<plan>/{learnings,decisions,issues,problems}.md` (append-only) |
| Review | OMO built-in `review-work` skill — 5 parallel lanes, whole-branch only |

Superpowers' SDD layer provides three things OMO lacks:

1. **`task-brief`** — extract one task's structured metadata into a single
   brief file the executor reads in one Read. Without this, executor
   either gets the entire plan (context pollution) or a free-text
   description (executor invents requirements).
2. **`review-package`** — package `git diff BASE..HEAD` + commit list +
   stat into a single file the reviewer reads in one Read. Without
   this, diffs are pasted inline and pollute the orchestrator's context.
3. **`progress.md`** — append-only ledger surviving compaction, so the
   orchestrator after `/clear` knows which tasks are done and where to
   resume. Without this, the orchestrator re-dispatches completed tasks
   (single most expensive failure observed in real sessions).

These scripts add the SDD layer on top of OMO without modifying OMO.

## Scripts

### `task-brief.sh <task-id> [--output <path>]`

Reads the OMO task's `metadata` field and writes a brief file containing:

- Subject + description (verbatim)
- `## Global Constraints` (verbatim from plan, copied into brief)
- `## Interfaces` (Consumes / Produces, exact signatures + file:line)
- `## Bite-sized steps` (TDD 5-step with exact code)
- `## Executor contract` (4-status return)
- `## No placeholders` (binding contract)

Outputs the path. Embed it in the dispatch prompt so the executor does
one Read of its brief.

Exit code 4 = missing required metadata (brief written anyway as a
recovery aid; fix the plan and re-run before dispatching).

### `review-package.sh <task-id> <base-sha> <head-sha>`

Generates a single review-package file:

- Commit list `git log --reverse BASE..HEAD`
- `git diff --stat`
- `git diff -U10` (full diff with 10 lines of context)

Plus reviewer instructions for the **2-verdict schema** (Spec compliance
+ Code quality — one reviewer, two ordered parts, per Superpowers v6.0).

**CRITICAL:** Use the BASE you recorded BEFORE dispatching the
implementer. NEVER use `HEAD~1` — that silently drops all but the last
commit of a multi-commit task.

### `slice-progress.sh list | mark-complete | mark-blocked`

Appends a single Markdown row to `.omo/sdd/<slug>/progress.md`:

```
| ts | task_id | status | commits | review | notes |
```

Mark a task complete AFTER its task-reviewer returns ✅ + Code quality
Approved. Never re-dispatch a task whose row already says DONE — check
the ledger + `git log` after any compaction.

## Example SDD loop

```bash
# 1. Plan has slice tasks in Phase 3 with metadata.biteSizedSteps etc.
#    Atlas / Sisyphus dispatch loop:
for TASK_ID in $(omo task list --plan "$PLAN_SLUG" | jq -r '.id'); do
    # 2. Write the brief to a unique path; executor will Read this
    BRIEF="$(./task-brief.sh "$TASK_ID")"

    # 3. Record BASE so review-package can diff correctly
    BASE="$(git rev-parse HEAD)"

    # 4. Dispatch executor with brief path (inline prompt, not a file)
    sisyphus-junior --prompt "Read $BRIEF first. Status: DONE | DONE_WITH_CONCERNS | NEEDS_CONTEXT | BLOCKED."

    # 5. After executor returns, package the diff
    HEAD="$(git rev-parse HEAD)"
    PKG="$(../slice-review/scripts/review-package.sh "$TASK_ID" "$BASE" "$HEAD")"

    # 6. Dispatch task-reviewer with package path
    oracle --prompt "Read $PKG once. Return spec compliance + code quality verdicts."

    # 7. Append to ledger (AFTER review approves)
    ./slice-progress.sh mark-complete "$TASK_ID" "$BASE" "$HEAD" \
        --review-verdict ok --plan "$PLAN_SLUG"
done

# 8. After all slices, dispatch whole-branch review-work (existing OMO skill)
review-work --plan "$PLAN_SLUG"
```

## What this layer does NOT do

- Does not modify OMO. All scripts are read-only against `.omo/boulder.json`,
  `$OPENCODE_CONFIG_DIR/tasks/`, and `.omo/plans/*.md`.
- Does not auto-dispatch. Orchestrator (Atlas / Sisyphus) decides when to
  call each script. The scripts are tools, not agents.
- Does not store credentials or send anything over the network.
- Does not require jq strictly — but task-brief.sh does, since OMO
  task JSON is structured.

## Exit codes

All three scripts share:

- 0 = ok
- 1 = usage / arg error
- 2 = plan file or OMO task file not found
- 3 = empty git range (review-package only)
- 4 = missing required metadata (task-brief only)

Errors write to stderr and include remediation hints.

## Tests

After implementing a slice, smoke-test the scripts in the project's
`.omo/sdd/<slug>/` directory:

```bash
# Did the brief get generated?
ls .omo/sdd/<slug>/task-<id>-brief.md

# Is the ledger coherent?
./slice-progress.sh list --plan <slug>

# Does the review package contain the diff?
../slice-review/scripts/review-package.sh <id> <base> <head> | xargs cat | head -50
```
