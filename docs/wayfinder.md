# wayfinder — 1-page human guide

> Multi-session exploration and decision-mapping. Companion to [`brainstorming`](../../skills/core/brainstorming/SKILL.md); same Phase 0 slot, used when scope doesn't fit one session.

## What it is

A wayfinder is a **map of leaf-level tickets** that span multiple sessions. Each ticket has one of three types (`prototype` / `research` / `decision`) and resolves to a concrete outcome (a chosen variant, a cited finding, a decision). Tickets form a DAG via `blockedBy` edges. On close, the ticket resolutions compose Phase 0 of `.omo/plans/<slug>.md`, and the map archives to `.omo/wayfinder-archive/`.

## When to use it

| Scope shape | Use |
|---|---|
| One brainstorming session's worth of decisions | `brainstorming` |
| Multiple sessions, tickets blocking each other, research / prototype / decision mix | **wayfinder** |
| Single-file change, hotfix | skip design phase, go to `incremental-implementation` |
| Known shape, no exploration | `spec-driven-development` Phase 1 |
| Debug | `debugging-and-error-recovery` / `diagnosing-bugs` |
| Recurring activity to spec | `loop-me` |

## Storage layout

```
.omo/wayfinder/<slug>/
├── map.json           # parent index (goal, tickets, status, blocking_cycles)
├── tickets/           # one .md per ticket
└── sessions/          # per-session log (opt-in; small maps leave empty)
```

After close → `.omo/wayfinder-archive/<slug>/` (read-only history) + `.omo/plans/<slug>.md` (Phase 0).

## Lifecycle (deterministic scripts)

```bash
# 1. Scaffold (idempotent, exits 0 on re-run; rejects slugs not matching ^[a-z0-9][a-z0-9-]{0,39}$)
bash ../skills/extra/wayfinder/scripts/wayfinder-init.sh <slug>

# 2. Write/edit tickets/ as you resolve each leaf
#    Each ticket: frontmatter (id/type/status/ts_created/ts_resolved/blockedBy/title)
#    + body (## Description / ## Resolution)

# 3. Close (7-step protocol: validate types + DAG + status → generate plan → archive → log)
bash ../skills/extra/wayfinder/scripts/wayfinder-close.sh <slug>
```

The close script **exits non-zero** on: unresolved ticket, `blockedBy` cycle, unknown ticket type (anything outside `prototype` / `research` / `decision`), or missing scaffold. It is **idempotent on already-closed** (re-running exits 0 with "already closed").

## Ticket contract

Three types only — **no `task` type**:

| Type | Resolver | Output landing |
|---|---|---|
| `prototype` | `/prototype` skill (P0) | `decisions.md [proto] ...` + ticket `## Resolution` |
| `research` | `/research` skill (P2 future) or `librarian` agent | ticket `## Resolution` + `[research]` entry |
| `decision` | HITL dialogue (agent grills user, one question at a time) | ticket `## Resolution` + `[wayfinder:decision]` entry |

DAG rule: `blocking_cycles = false` is a hard precondition for close. If a cycle exists, refactor the `blockedBy` edges before re-running close — the script will not auto-resolve.

## Plan generation (deterministic)

On close, `scripts/wayfinder-close.sh` writes `.omo/plans/<slug>.md`:

| Section | Source |
|---|---|
| `## Goal` | `map.json.goal` |
| `## Approach` | resolved `decision` ticket `## Resolution` bodies (in id order) |
| `## Architecture` | all ticket summaries: `[id/type/status] title` |
| `## Open Questions` | `skipped` tickets (id + title) |

## Audit trail

Each close appends one line to `.omo/notepads/<slug>/decisions.md`:

```
[wayfinder] ts=<iso8601> close=1 plan_ref=.omo/plans/<slug>.md
```

This is the canonical "when was this closed" log. The `omo-state-index` plugin (TODO 1) reads it via the `[wayfinder]` shape and updates `.omo/.index.json` (decrement `open_wayfinders`, increment `closed_wayfinders` with `plan_ref`).

## Verification

```bash
# Lifecycle contract test (T1–T9: tree, schema, idempotent, types, cycle, unresolved, archive, plan, idempotent close)
bash ../skills/extra/wayfinder/scripts/test-wayfinder-lifecycle.sh

# Single-probe smoke
bash ../skills/extra/wayfinder/scripts/wayfinder-init.sh 'Bad_Slug!'   # expect: exit 1, regex error
bash ../skills/extra/wayfinder/scripts/wayfinder-init.sh qa-wayfinder   # expect: exit 0, scaffold created
bash ../skills/extra/wayfinder/scripts/wayfinder-close.sh qa-wayfinder  # expect: exit 0 (or 1 if unresolved tickets)
```

## Common mistakes

- Opening a wayfinder for single-session scope → use `brainstorming` instead.
- Adding a generic `task` ticket type → not allowed; classify into one of the 3 types or don't open the ticket.
- Re-opening a closed wayfinder → open a new one with a new slug; archives are read-only history.
- Manually `mv`-ing `.omo/wayfinder/<slug>/` to archive → bypasses the 7-step protocol; restore and use `wayfinder-close.sh`.

## See also

- [`skills/extra/wayfinder/SKILL.md`](../../skills/extra/wayfinder/SKILL.md) — full machine-readable spec (process, edge cases, omo integration).
- [`evals/cases/wayfinder.json`](../../evals/cases/wayfinder.json) — trigger phrases and behavioral scenarios.
- [`wayfinder-init.sh`](../../skills/extra/wayfinder/scripts/wayfinder-init.sh) / [`wayfinder-close.sh`](../../skills/extra/wayfinder/scripts/wayfinder-close.sh) / [`test-wayfinder-lifecycle.sh`](../../skills/extra/wayfinder/scripts/test-wayfinder-lifecycle.sh).
- Phase 0.b of `.omo/plans/skills-extension-v1.md` for the design rationale.