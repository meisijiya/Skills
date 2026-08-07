# State-file Governance (A1)

> **Scope:** A1 — single discovery entry for `.omo/**` state. Pairs with A2–A5 (existing-skill text patches, no new cleanup skill).
> **Status:** TODO 1 of [`skills-extension-v1`](../../.omo/plans/skills-extension-v1.md) — shipped.
> **Plugin:** `.opencode/plugins/omo-state-index.js`

This document describes the A1 state-file governance foundation: the
`omo-state-index` OpenCode plugin, the `.omo/.index.json` schema, and
the install / test surface. It does **not** cover A2–A5 (those are
separate slices / TODOs in the same plan).

## Why

`.omo/` accumulates state across plans: `plans/`, `notepads/`, `drafts/`,
`wayfinder/`, `wayfinder-archive/`, `throwaway-worktree/`, `throwaway-proto/`. Without a single
discovery entry, every skill must re-scan the filesystem to know what's
in flight — and stale state silently rots. (`research/` and `incidents/`
moved to `docs/` per the docs/ vs `.omo/` two-axis rebalancing — git
tracked project-level audit logs, not `.omo/` state.)

A1 fixes that with **one** JSON file (`.omo/.index.json`) that mirrors
the on-disk state of `.omo/**`. The file is maintained by a single
hard-layer OpenCode plugin that listens to file writes and rebuilds on a
500ms debounce.

## Plugin name

`omo-state-index` — exposed by `.opencode/plugins/omo-state-index.js`,
installed to `~/.config/opencode/plugins/omo-state-index.js` via
`scripts/install.sh`.

The plugin is a sibling of (not a replacement for) the two existing
meisijiya plugins:

| Plugin | Concern | Hook surface |
|---|---|---|
| `meisijiya-skills.js` | bootstrap skills into first user message | `config`, `experimental.chat.messages.transform` |
| `meisijiya-review-router.js` | per-Edit reminder to invoke review skills | `chat.message`, `tool.execute.after`, `event` |
| `omo-state-index.js` *(this slice)* | maintain `.omo/.index.json` | `config`, `tool.execute.after`, `experimental.chat.messages.transform` |

All three install into `~/.config/opencode/plugins/` and coexist without
modifying OMO or OpenCode sources.

## Hooks

The plugin returns three hooks:

### `config(config)` — registration

Mutates the in-memory config object in place, mirroring the pattern in
`meisijiya-skills.js`. Registers:

```js
config.omoStateIndex = {
  debounceMs: 500,
  schemaVersion: '1.1.0',
  indexPath: '.omo/.index.json',
  requiredArrays: [/* eight array names */],
};
```

This is **introspection only** — it doesn't change OpenCode's runtime
behavior, but other plugins / hosts can read it to discover the index
contract.

### `experimental.tool.execute.after` — debounced rebuild

After every `Write` / `Edit` / `apply_patch` tool call, if the changed
path contains `.omo/` **and** is not the index file itself, schedule a
debounced rebuild (500ms). Multiple writes within the window collapse
into one rebuild.

The hook never throws. A failed rebuild simply delays the next attempt
— the next write to `.omo/**` will retry.

### `experimental.chat.messages.transform` — compaction summary

Emits a **3-line** Markdown summary of `.omo/.index.json` into the
first user message, using the same in-place-mutation pattern as
`meisijiya-skills.js` (OpenCode retains the original `parts` array
reference, so reassigning `parts` is a silent no-op — see
[opencode#25754](https://github.com/code-yeongyu/oh-my-openagent/issues/25754)).

Example 3-line summary:

```markdown
## OMO state (schema 1.1.0)
- active_plans=3, open_wayfinders=1, throwaway_worktrees=0, throwaway_protos=0
- drafts_to_resolve=2, stale_artifacts=0, closed_plans=0
```

Idempotent: if the marker `## OMO state` is already present on the
target message, the hook skips — safe across session compaction re-fires.

## Debounce contract

| Property | Value | Source |
|---|---|---|
| Default debounce | **500ms** | `DEBOUNCE_MS_DEFAULT` |
| Min debounce | 0 (tests use 50ms / 200ms for fast feedback) | `opts.debounceMs` override |
| State keying | per-`omoDir` (absolute path) | `debounceState: Map<string, …>` |
| Self-write guard | `.omo/.index.json` writes are rejected | `scheduleRebuild(omoDir, filePath)` |
| Cancel-on-new-event | any new event clears the prior timer | `clearTimeout(prior.timer)` |

Within the debounce window:

1. Event 1 arrives → timer scheduled for `now + 500ms`.
2. Event 2 arrives (50ms later) → prior timer cleared, new timer
   scheduled for `now + 500ms`. `eventCount` increments to 2.
3. Timer fires → **one** `rebuildIndex(omoDir)` call.
4. Map entry cleared.

The net effect: 100 events in a 400ms burst produce **one** rebuild,
not 100.

## Schema (1.1.0)

`.omo/.index.json` is a JSON object with the following required shape.
All eight arrays must be present, even if empty. `ts_rebuilt` is the
ISO 8601 timestamp of the most recent rebuild.

```jsonc
{
  "schema_version": "1.1.0",
  "ts_rebuilt": "2026-07-29T16:42:00.000Z",
  "active_plans":       [{ "slug": "skills-extension-v1", "path": ".omo/plans/skills-extension-v1.md" }],
  "closed_plans":       [],
  "open_wayfinders":    [{ "slug": "demo-map", "path": ".omo/wayfinder/demo-map/" }],
  "closed_wayfinders":  [],
  "throwaway_worktrees":[],
  "throwaway_protos":   [],
  "drafts_to_resolve":  [{ "slug": "unfinished-spec", "path": ".omo/drafts/unfinished-spec.md" }],
  "stale_artifacts":    []
}
```

### Field semantics

| Field | Source on disk | Empty semantics |
|---|---|---|
| `active_plans` | `.omo/plans/*.md` (each `slug` = filename without `.md`) | No plans yet |
| `closed_plans` | `.omo/plans-archive/*.md` | No archive yet |
| `open_wayfinders` | `.omo/wayfinder/*/` (each `slug` = directory name) | No open wayfinders |
| `closed_wayfinders` | `.omo/wayfinder-archive/*/` | No archived wayfinders |
| `throwaway_worktrees` | `.omo/throwaway-worktree/*/` | No throwaway worktrees |
| `throwaway_protos` | `.omo/throwaway-proto/*/` | No throwaway protos |
| `drafts_to_resolve` | `.omo/drafts/*.md` | No drafts |
| `stale_artifacts` | entries inside `throwaway-worktree/` or `throwaway-proto/` that are **empty** or lack `.git` | Nothing stale |

A2 (the next-slice existing-skill text patches) is responsible for
marking plans as `closed` (via the `.omo/plans-archive/` directory) and
for the Phase 2 startup sweep that surfaces `stale_artifacts` to the
user with an explicit `y/n` confirmation before any deletion.

## Edge cases

### 1. Corrupt `.index.json`

**Symptom:** `.index.json` exists but isn't valid JSON, or is missing
`schema_version`, or is missing one of the eight required arrays.

**Behavior:** `rebuildIndex()` flags `fromCorrupt: true` and overwrites
the file with a fresh scan. The hook caller can log the corruption for
audit, but does **not** abort — the index self-heals.

**Test coverage:** case (b) in `scripts/test-omo-state-index.js`.

### 2. Self-write to `.index.json`

**Symptom:** the plugin's own `rebuildIndex` writes to `.index.json`,
which the `tool.execute.after` hook would otherwise observe as a
`.omo/**` write and re-schedule.

**Behavior:** `scheduleRebuild()` resolves both the incoming `filePath`
and `indexPathOf(omoDir)` to absolutes and compares. If equal, returns
`{ cancelled: true, self_write: true }` and does **not** schedule. No
recursion.

**Test coverage:** case (c) in `scripts/test-omo-state-index.js`.

### 3. Two writes within 500ms

**Symptom:** user fires two `Edit .omo/notepads/demo/decisions.md`
events 50ms apart.

**Behavior:** the first event arms a 500ms timer; the second clears
that timer and arms a fresh one. Exactly one `rebuildIndex` fires
500ms after the *second* event. `ts_rebuilt` advances by one tick; no
spurious intermediate writes.

**Test coverage:** case (d) in `scripts/test-omo-state-index.js`.

### 4. Absent `.omo/` directory

**Symptom:** user has no `.omo/` yet (greenfield repo).

**Behavior:** `rebuildIndex` returns an empty index (all eight arrays
empty, `schema_version: "1.1.0"`) and writes it. The first
`scheduleRebuild` call creates `.omo/.index.json` from scratch.

**Test coverage:** case (a) starts with an empty `.omo/` (the test
seeds `.omo/plans/demo.md` and verifies the index reflects it).

### 5. Plugin loaded for a directory without `.omo/`

**Symptom:** OpenCode starts the plugin in a project that has no
`.omo/` directory at all.

**Behavior:** `omoDir = path.join(directory, '.omo')` may not exist.
`scheduleRebuild` will still call `rebuildIndex` on the next `.omo/**`
write, which will create the directory tree as a side effect of
`writeFileSync` on `.omo/.index.json`. Idempotent and safe.

### 6. Concurrent rebuilds in two repos

**Symptom:** OpenCode process hosts two projects, each with its own
`.omo/`.

**Behavior:** `debounceState` is keyed by `path.resolve(omoDir)`, so
each repo gets its own independent debouncer. Writes in repo A do not
delay writes in repo B.

## Test surface

`scripts/test-omo-state-index.js` is a pure-Node smoke test (no
vitest, no new deps) covering the four required cases:

- **(a)** absent index + first `.omo/**` write → schema 1.1.0 + 8 arrays
- **(b)** corrupt index → rebuilt from filesystem
- **(c)** self-write → no recursion
- **(d)** two events within 500ms → exactly one rebuild

Run: `node scripts/test-omo-state-index.js` → exit 0 on pass, 1 on
fail. Output is human-readable assertion lines; no test framework.

The plugin's public API is also the test surface:

```js
const plugin = require('.opencode/plugins/omo-state-index.js');
plugin.rebuildIndex(omoDir)         // synchronous
plugin.scheduleRebuild(omoDir, p)   // debounced, returns { scheduled, debounceMs, eventCount }
plugin.summarizeIndex(omoDir)       // 3-line array
```

## Install

```bash
bash scripts/install.sh              # install (or no-op if up to date)
bash scripts/install.sh --dry-run    # preview
bash scripts/install.sh --force      # overwrite on SHA drift
```

The installer:

- copies **only** `.opencode/plugins/omo-state-index.js` to
  `~/.config/opencode/plugins/`
- refuses to overwrite on SHA drift unless `--force` is set
- writes atomically (temp file + rename)
- re-runs idempotently (no work to do → exit 0)

**Restart OpenCode** after install — plugins are loaded once at process
start, not on file change.

## What this plugin does **not** do

- **No deletions.** Stale artifacts are *listed* in
  `stale_artifacts`; the plugin never removes files. A2 owns the
  user-confirmed cleanup sweep.
- **No modifications to OMO or OpenCode source files.** Lives entirely
  in this repo's `.opencode/plugins/` and `~/.config/opencode/plugins/`.
- **No `compaction-context-injector` write.** The 3-line summary uses
  the same `experimental.chat.messages.transform` hook as the
  bootstrap plugin; there is no separate compaction-context-injector
  (that's an OMO-internal concept, out of scope here).
- **No new eval case.** The plan explicitly excludes
  `evals/cases/omo-state-index.json` because this is a plugin, not a
  skill. Plugin behavior is verified by `scripts/test-omo-state-index.js`.

## See also

- Plan: `.omo/plans/skills-extension-v1.md` (TODO 1 of 6, plus
  final-wave F1–F4 verifiers)
- Sibling plugin (bootstrap): `.opencode/plugins/meisijiya-skills.js`
- Sibling plugin (review reminders): `.opencode/plugins/meisijiya-review-router.js`
- A2–A5 (next slice): existing-skill text patches in
  `skills/core/{brainstorming,incremental-implementation,debugging-and-error-recovery,spec-driven-development}/SKILL.md`
  plus `skills/extra/build-gate-visual-review/SKILL.md` and
  `skills/extra/security-incident-response/SKILL.md`.
