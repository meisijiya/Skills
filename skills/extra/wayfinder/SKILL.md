---
name: wayfinder
description: "Multi-session exploration and decision-mapping for projects whose scope exceeds a single brainstorming session. Opens a wayfinder map under `.omo/wayfinder/<slug>/` (map.json + tickets/ + sessions/), drives resolution across sessions, and on close generates Phase 0 of `.omo/plans/<slug>.md` then archives to `.omo/wayfinder-archive/`. Tickets form a blockedBy ticket DAG with cycle detection. Use when the user says 'wayfinder', 'decision mapping', 'multi-session planning', or when scope clearly spans multiple sessions with tickets blocking each other. NOT for single-session scope (use brainstorming), hotfixes / one-file changes (no design phase), known-shape work (go straight to spec-driven-development), or pure debugging (use debugging-and-error-recovery)."
allowed-tools: "Read Edit Bash Glob Grep"
---

# wayfinder

## Overview

把"超过一次 brainstorm 会话能装下"的项目**结构化成可跨 session 推进的 ticket 图**。每个 ticket 是 leaf-level 决策(resolve 了一个就前进),通过 `blockedBy` 边构成 DAG,关闭时把 ticket 决议组装成 Phase 0,落 `.omo/plans/<slug>.md`,然后整张图归档到 `.omo/wayfinder-archive/`。

与 `brainstorming` 的关系:`brainstorming` 是单会话 Phase 0;`wayfinder` 是多会话 Phase 0 —— **同一 slot,按 scope 选**。如果一次 grilling + 一次 plan 写完能搞定,不要开 wayfinder;**开了就要为多 session 推进而存在**。

3 个 ticket type:`prototype` / `research` / `decision`。**没有 `task`** —— 每个 ticket 必须有 resolution(选了哪个 prototype / 研究结果 / 决策),否则就还没到该开 ticket 的时候。

## When to Use

**Use when:**
- 用户明确说 `/wayfinder` 或 "open a wayfinder" / "decision mapping" / "multi-session planning"。
- scope 明显跨多次会话:多张 tickets、互相 blockedBy、有 phase 0 前的子决策需要先解决。
- 项目是"先搞清楚 X 才能动 Y"型(不确定的研究、跨多个领域的设计),且单会话 brainstorming 装不下。
- 用户已有多个 `brainstorming` 文档或会话上下文,需要把它们**显式结构化**成可推进的 ticket 图。

**NOT for:**
- **单会话 scope** → [`brainstorming`](~/.agents/skills/brainstorming/SKILL.md)。
- 单文件改动 / hotfix → 跳过 design phase,直接 `incremental-implementation`。
- 已知 shape 的工作 → `spec-driven-development` Phase 1。
- 纯 debug → [`debugging-and-error-recovery`](~/.agents/skills/debugging-and-error-recovery/SKILL.md) / [`diagnosing-bugs`](~/.agents/skills/diagnosing-bugs/SKILL.md)。
- 一次性文档 / ADR → [`documentation-and-adrs`](~/.agents/skills/documentation-and-adrs/SKILL.md)。
- 反复做的活动形式化 → [`loop-me`](~/.agents/skills/loop-me/SKILL.md)。

**与 brainstorming 的边界**:用户还没确认"这是个值得多 session 推进的项目"之前,先用 `brainstorming` 收敛 scope。一旦开了 wayfinder,scope 已经定,剩下的工作是把 tickets 推到 resolved。

## Process

### 1. Open session

```bash
bash scripts/wayfinder-init.sh <slug> [--root DIR]
```

Creates `.omo/wayfinder/<slug>/` with:

```
.omo/wayfinder/<slug>/
├── map.json           # parent index (schema below)
├── tickets/           # one .md per ticket
└── sessions/          # per-session log (light; opt-in for small maps)
```

Slug regex (binding, matches brainstorming): `^[a-z0-9][a-z0-9-]{0,39}$`. **Idempotent**: re-run exits 0 without rewriting `map.json`.

After init, **edit `map.json`** to set the `goal` field (one sentence describing the destination of Phase 0).

### 2. Map the territory

For each un-blocked leaf, write `tickets/<NN>-<slug>.md` (NN is zero-padded id; one ticket per leaf decision):

```yaml
---
id: "01"
type: prototype | research | decision
status: pending
ts_created: 2026-07-29T00:00:00Z
ts_resolved: null
blockedBy: []
title: <one line>
---

# <title>
## Description
<what decision / what to investigate / what variants to compare>
## Resolution
<decision made + why + link to artifacts>
```

**Three ticket types only:**

| Type | Resolver | HITL timing | Output landing |
|---|---|---|---|
| `prototype` | [`/prototype`](~/.agents/skills/prototype/SKILL.md) skill — variant generation + selection | variant selection end | `decisions.md [proto]` + ticket `## Resolution` |
| `research` | [`/research`](~/.agents/skills/research/SKILL.md) skill | mode selection sync; dispatch AFK (async or sync) | ticket `## Resolution` (≤8 words takeaway + path) |
| `decision` | interactive HITL dialogue (agent grills user on this specific decision) | always | ticket `## Resolution` |

**No generic `task` type** — every ticket must declare its resolver. If a future task can't be classified, **don't open it as a ticket**; defer to a follow-up wayfinder session.

**DAG validation:** before writing `blockedBy`, mentally trace: every ticket must trace to a leaf (no orphans that block on nothing AND are blocked by nothing — those should be merged or split). Cycles are forbidden (`blocking_cycles = false` is a hard precondition for close).

### 3. Resolve, leaf-first

Pick the highest-priority ticket where `blockedBy` is fully resolved (or empty):

- **`prototype` ticket**: invoke `/prototype` (P0 skill). Wait for variant selection. Update ticket `status: resolved`, fill `## Resolution` with chosen variant + reason. Append `[proto] ts=... feature=<slug> variant=<A|B|C|E> reason=<≤150char>` to `.omo/notepads/<slug>/decisions.md`.
- **`research` ticket**: invoke `/research` (P2 future) or `librarian` agent. Update ticket `## Resolution` with takeaway + path. Append `[research] ts=... topic=<slug> findings=<path> mode=async|sync` to `decisions.md`.
- **`decision` ticket**: HITL dialogue — agent asks the user **one question at a time**, each with a recommended answer. Update ticket `## Resolution` with the decision made. Append `[wayfinder:decision] ts=... ticket=<NN> ...` to `decisions.md`.

After each resolution, **re-evaluate blockedBy** for dependent tickets — they may now be un-blocked.

`sessions/<NNN>-<iso>.md` is opt-in for maps > 5 tickets (light log: which ticket was resolved, what landed where). Default: do not write session logs for small maps.

### 4. Close (mandatory protocol)

```bash
bash scripts/wayfinder-close.sh <slug> [--root DIR]
```

7-step protocol enforced by the script:

1. All tickets ∈ `{resolved, skipped}` (else exit non-zero).
2. `blocking_cycles = false` (DAG acyclic).
3. Ticket types ∈ `{prototype, research, decision}` (else exit non-zero).
4. Generate `.omo/plans/<slug>.md` Phase 0:
   - `## Goal` ← `map.json.goal`
   - `## Approach` ← resolved decision ticket `## Resolution` bodies
   - `## Architecture` ← all ticket summaries (`[id/type/status] title`)
   - `## Open Questions` ← skipped tickets (id + title)
5. Update `map.json`: `status: closed`, `ts_closed`, `ticket_count.by_status`.
6. `mv .omo/wayfinder/<slug>/ → .omo/wayfinder-archive/<slug>/`.
7. Append `[wayfinder] ts=<iso8601> close=1 plan_ref=.omo/plans/<slug>.md` to `.omo/notepads/<slug>/decisions.md`.

**Idempotent on already-closed**: if `wayfinder-archive/<slug>/` already exists, exit 0 without writing plan.md twice.

**Exits non-zero** on: unresolved ticket, blockedBy cycle, unknown ticket type, missing scaffold.

### 5. Hand off

After close, the generated `.omo/plans/<slug>.md` Phase 0 is **input** to [`spec-driven-development`](~/.agents/skills/spec-driven-development/SKILL.md) Phase 1 — feed `goal` / `approach` sections as the seed for `spec_approved` drafting. From there, [`incremental-implementation`](~/.agents/skills/incremental-implementation/SKILL.md) handles Phase 2/3 slices.

The `wayfinder-archive/<slug>/` becomes **read-only history** — never re-open a closed wayfinder; open a new one for follow-ups.

## Common Rationalizations

| Excuse | Reality |
|---|---|
| "Just a few tickets, I'll skip wayfinder" | If it's multi-session scope, **that's exactly what wayfinder is for**. Skipping means tickets live in chat history and resolve-and-forget. |
| "Let me add a generic `task` type" | No. Three types exist because each has a specific resolver + output landing. If you can't classify, the work isn't ticket-shaped yet. |
| "I'll keep the wayfinder open across plans" | One wayfinder ↔ one plan slug. New phase 0 = new wayfinder. Archives are not re-opened. |
| "Cycle is fine, the user will resolve it" | Cycle is a structural error in your map. Refactor the `blockedBy` edges; don't expect close to auto-resolve. |
| "Skip-condition says 'no design phase' for hotfixes" | Hotfixes don't even reach wayfinder. If scope is hotfix-shaped, the rule is "skip design phase entirely" — don't half-open a wayfinder. |
| "I'll write `sessions/<NNN>.md` for everything" | Default disable for maps ≤ 5 tickets. Only enable when the per-session audit trail is the value. |
| "Auto-close when all tickets resolve" | Close is **explicit** — user says "close map". Auto-close breaks the assumption that archive move = user-attested phase 0. |
| "Just keep wayfinder-{init,close}.sh inline" | Scripts are deterministic and testable (see `scripts/test-wayfinder-lifecycle.sh`). Don't reimplement the lifecycle in agent prose. |
| "Single-session scope, but let me use wayfinder for the file-per-ticket hygiene" | `brainstorming` produces ONE plan; wayfinder produces MANY tickets. If you only need one decision, you don't need the ticket graph. |

## Red Flags

- Wayfinder opened for scope that fits one brainstorming session → STOP, use `brainstorming`.
- Ticket type `task` appearing anywhere (map.json, ticket file, or chat) → STOP, classify into one of the 3 types or don't open a ticket.
- `blockedBy` cycle discovered only at close time → STOP, refactor DAG before re-running close.
- Same slug re-used for a different scope after close → STOP, open a new wayfinder (archives are not re-opened).
- `decisions.md` `[wayfinder]` entry appended before close script ran → STOP, the script owns the entry; manual appends double-log the event.
- `wayfinder-close.sh` re-run after a manual `mv` to archive → STOP, manual move bypasses the 7-step protocol; restore scaffold and use the script.
- `.omo/wayfinder/<slug>/` written directly without `wayfinder-init.sh` (map.json missing required keys) → STOP, scaffold via the script so post-write validation runs.

## Verification

Before opening a wayfinder session:
- [ ] Scope confirmed multi-session (more than one brainstorming session's worth of decisions).
- [ ] `goal` field written into `map.json` (one sentence describing Phase 0 destination).

Before closing:
- [ ] Every ticket has `status` ∈ `{resolved, skipped}` (no `pending` / `in_progress` / `blocked`).
- [ ] Every ticket has `type` ∈ `{prototype, research, decision}`.
- [ ] `blockedBy` DAG is acyclic (no cycles; `wayfinder-close.sh` enforces this).
- [ ] Each resolved ticket has a non-empty `## Resolution` body.
- [ ] `decisions.md` exists at `.omo/notepads/<slug>/decisions.md` (script creates it on close).

After close:
- [ ] `.omo/plans/<slug>.md` exists with `Goal` / `Approach` / `Architecture` / `Open Questions` sections populated.
- [ ] `.omo/wayfinder-archive/<slug>/` exists with `map.json` (status=closed), `tickets/`, `sessions/`.
- [ ] `[wayfinder] ts=... close=1 plan_ref=...` entry appended to `decisions.md`.
- [ ] Re-running `wayfinder-close.sh <slug>` exits 0 with "already closed" message (idempotent).

Cross-cutting:
- [ ] `bash scripts/test-wayfinder-lifecycle.sh` exits 0 (covers T1–T9 contract probes).
- [ ] `bash scripts/wayfinder-init.sh 'Bad_Slug!'` exits 1 with regex error.
- [ ] `bash scripts/wayfinder-close.sh <unknown-slug>` exits 1 with "not initialized" error.

## Examples

### Minimal map (3 tickets, all resolved decisions)

```
.omo/wayfinder/auth-revamp/
├── map.json              # goal: "Replace session auth with JWT + refresh cookie"
├── tickets/
│   ├── 01-token-strategy.md   (decision, resolved)
│   ├── 02-refresh-store.md    (decision, resolved)
│   └── 03-rate-limit.md       (decision, resolved)
└── sessions/             # empty for ≤5 tickets
```

After close:
```
.omo/plans/auth-revamp.md       # Phase 0 with Goal + 3 Approach decisions
.omo/wayfinder-archive/auth-revamp/  # read-only history
.omo/notepads/auth-revamp/decisions.md  # [wayfinder] ts=... close=1
```

### Mixed-type map (prototype + research + decision)

```
.omo/wayfinder/dashboard-redesign/
├── map.json
├── tickets/
│   ├── 01-layout-prototypes.md   (prototype → 3 variants; pick B)
│   ├── 02-density-research.md    (research → notion-vs-linear density finding)
│   ├── 03-cta-copy.md            (decision → HITL grilling, picked "Try it free")
│   └── 04-build.md               (decision → greenlight build, blockedBy: 01,02,03)
└── sessions/
    └── 001-2026-07-29.md         # opted-in session log
```

Close generates plan.md with `## Approach` containing all 4 ticket resolutions (only `decision` ones land in the bullet section; prototype/research land in `## Architecture` summary).

## omo Integration

- **Agent dispatch**: `librarian` agent for `research` tickets (AFK; default fallback until `/research` skill ships). No OMO agent owns ticket resolution end-to-end — `prototype` goes through `/prototype` skill; `decision` is HITL.
- **Hook integration**: when `[wayfinder]` entries append to `decisions.md`, the `omo-state-index` plugin (TODO 1) auto-updates `.omo/.index.json` (decrement `open_wayfinders`; increment `closed_wayfinders` with `plan_ref`). No additional hook needed for the wayfinder package itself.
- **Notepad**: `.omo/notepads/<slug>/decisions.md` is the canonical append-only log; uses existing `[proto]` / `[research]` / `[wayfinder]` / `[wayfinder:decision]` entry shapes (parallel format with `[build-gate]` / `[amend]`).
- **Plan handoff**: closed wayfinder generates Phase 0 of `.omo/plans/<slug>.md`; downstream `spec-driven-development` Phase 1 consumes `Goal` + `Approach` as seed.
- **Scripts**:
  - `scripts/wayfinder-init.sh` — scaffold creator (idempotent, exits 0 on re-init).
  - `scripts/wayfinder-close.sh` — close orchestrator (7-step protocol, idempotent on already-closed).
  - `scripts/test-wayfinder-lifecycle.sh` — 9-probe contract test (T1 tree+schema, T2 invalid slug, T3 idempotent init, T4 3 valid types, T5 task refused, T6 cycle refused, T7 unresolved refused, T8 archive+plan, T9 close idempotent).
- **Catalog placement**: `meisijiya-domain` group (per Phase 1 Cross-cutting Open Questions #1, TODO 6 owns the catalog edits — wayfinder SKILL.md does not edit marketplace.json / AGENTS.md / README).
- **Boulder**: throwaway worktrees from `/prototype` resolution → `status=archived` flag on close (per plan § "Integration with existing", TODO 1 plugin hook handles the actual mutation).
- **No direct OMO MCP bridge** beyond `librarian` for `research` fallback. `context7` / `websearch` reach indirectly via `/research` once it ships.