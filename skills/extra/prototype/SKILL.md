---
name: prototype
description: "Prototype / visual-decision skill for spec authoring. Use when the spec contains [PROTO-RESOLVE: <question>] markers and the user needs to pick between layout / density / motion alternatives for visual fidelity, or during Phase 1.2 of spec-driven-development when text-only specs cannot answer layout or interaction questions. Generates 3 default throwaway UI variants (max 5, MIN 2 valid else NEEDS_CONTEXT) to resolve spec authoring questions, captures choice in decisions.md, never ships to production. NOT for implementing production UI, deploying artifacts, or shipping design tokens (use designer-handoff + meisijiya-frontend-taste for that)."
allowed-tools: "Read Edit Bash Glob Grep"
---

# prototype

## Overview

Resolves visual / interaction decisions in spec authoring by generating throwaway UI variants. Three default variants (max 5, MIN 2 valid else `NEEDS_CONTEXT`); each differs on at least one axis (layout / density / motion). Status state machine: `triggered → generating → awaiting_selection → resolved` (alt: `need_context`, `bypassed`). Decisions land in `.omo/notepads/<plan>/decisions.md` as `[proto]` entries.

**Two rendering paths:**

- **Brownfield** — same existing route serves `?variant=A|B|C|E`; floating bottom-bar switcher for live comparison. Throwaway code lives in `.omo/throwaway/<feature>/` worktree.
- **Greenfield** — own static HTML generator outputs `.omo/prototypes/<plan>/{variant-A,B,C,index}.html`; does **not** delegate to `build-gate-visual-review` (its `<script>` ban is incompatible with the floating switcher).

> **职责边界**:`/prototype` is throwaway spec-authoring scaffolding. It does not produce production UI, does not deploy, and does not enforce `meisijiya-frontend-taste` in the same way `designer-handoff` does. The exemption template is `[taste:exempt]` (see §3.3). Selected variant feeds spec §3.5 via `[PROTO-RESOLVE]` marker replacement.

## When to Use

**Use when:**

- Phase 1 spec contains `[PROTO-RESOLVE: <one-sentence question>]` markers and the user needs to pick between visual / interaction alternatives
- A spec author needs layout / density / motion decisions resolved before `spec_approved` (text-only specs cannot answer these)
- A user explicitly invokes `/prototype` to compare variants for a feature
- A wayfinder `prototype` ticket dispatches to this skill

**NOT for:**

- Implementing production UI features → use `incremental-implementation` + `meisijiya-frontend-taste`
- Deploying artifacts or shipping to production → use `pre-ship-gate` / `closed-loop-delivery`
- Generating design tokens / handoff to designer for production work → use `designer-handoff` (separate contract)
- Auto-loading on every project with UI — the spec must carry a `[PROTO-RESOLVE]` marker
- Bypassing without reason — bypass default is TRIGGER; missing `[proto:bypass]` reason falls through to trigger

## Process

### 1. Detect trigger

A `[PROTO-RESOLVE: <question>]` marker in the spec, an explicit `/prototype` invocation, or a wayfinder `prototype` ticket. Without a marker, the spec is not ready for prototype gating — refuse with "no [PROTO-RESOLVE] markers in spec; refine spec first".

### 2. Initialize status.json

Create `.omo/prototypes/<plan>/status.json` with state `triggered`:

```json
{
  "plan": "<plan-slug>",
  "feature": "<feature-slug>",
  "state": "triggered",
  "ts_triggered": "<iso8601>",
  "variants": []
}
```

### 3. Generate variants

Default 3, max 5, MIN 2 valid (else `NEEDS_CONTEXT`). Each variant must differ from the others on **at least one axis**:

| Axis | Options |
|---|---|
| Layout | grid / single-column / asymmetric-bento / sidebar / modal-stack |
| Density | compact / comfortable / spacious |
| Motion | none / spring / parallax / scroll-driven |

Render order is not prescriptive; pick the inter-axis divergence that maximizes signal-to-noise for the question.

#### 3.1 Brownfield path

If the user has an existing route / component / page:

- Same route accepts `?variant=A|B|C|E` query param.
- Floating bottom-bar switcher (HTML+JS, single file, lives at `.omo/throwaway/<feature>/switcher.html`) shows all variants; clicking reloads the route with the new query param.
- Implementation lives in `.omo/throwaway/<feature>/` worktree (per `incremental-implementation` A2 cleanup).

#### 3.2 Greenfield path

No existing route; generate from scratch:

- Each variant → `.omo/prototypes/<plan>/variant-<A|B|C|E>.html`.
- `index.html` (same dir) lists all variants with thumbnails + links.
- Floating switcher inlined per-page (single HTML, no build step).

#### 3.3 Intra-variant taste enforcement

| Variant type | Taste enforcement | Status annotation |
|---|---|---|
| Marketing-grade (landing / portfolio / hero) | [`meisijiya-frontend-taste`](~/.agents/skills/meisijiya-frontend-taste/SKILL.md) **enforced** | (no annotation) |
| Data-heavy / dashboard / multi-step form / settings | `meisijiya-frontend-taste` **exempt** | `[taste:exempt]` in `status.json.variants[i].annotations` + corresponding `[proto:exempt] ts=... variant=... reason=...` in `decisions.md` |

Taste-exempt reason: ≤ 150 chars explaining why the variant targets a non-marketing surface.

### 4. Render-failure handling

If a variant fails to render (CSS parse error, JS exception, etc.):

- The variant is **still shown** in the index (so the user sees the failure, not a silent gap).
- `status.json.variants[i].annotations` includes `render:failed`.
- The variant is **counted invalid**.
- If fewer than 2 valid variants remain after failures → transition to `need_context` and surface error to user.

### 5. Await selection

Transition `status.json.state` to `awaiting_selection`. Stop and wait for the user to click / announce a variant choice. Selection format: `[PROTO-RESOLVE]` answer is one of `A | B | C | E` plus an optional ≤ 150-char rationale.

### 6. Record decision

Append to `.omo/notepads/<plan>/decisions.md` (append-only via `notepad-write-guard` hook):

```text
[proto] ts=<iso8601> feature=<slug> variant=<A|B|C|E> reason=<≤150char>
[proto:exempt] ts=<iso8601> variant=<A|B|C|E> reason=<为什么超 marketing-grade>
[proto:superseded] ts=<iso8601> prior=<prev ts> by=[amend:<ts>]
[proto:cleanup] worktree=<path> status=<obsolete|stale|deleted>
[proto:bypass] ts=<iso8601> feature=<slug> reason=<1-2 sentences>
```

Update `status.json.state` to `resolved`. Replace the spec's `[PROTO-RESOLVE]` marker with the chosen variant's text + rationale.

### 7. Bypass (default TRIGGER)

Bypass is opt-out, never opt-in. Conditions (all require explicit recorded reason):

- Trivially obvious (1-sentence justification, e.g. "single field, no layout decision")
- Constrained by existing ADR / conventions (cite the ADR)
- Unrenderable (pure algorithm / data model, e.g. backend service shape)

Bypass **mandatory** record: `[proto:bypass] ts=... feature=... reason=...` in `decisions.md` + spec marker replaced with `(bypassed <date>, reason: ...)`. **No bypass record = treated as triggered** (auto-call prototype).

## Common Rationalizations

| Excuse | Reality |
|---|---|
| "Variant A is obviously the best, skip generating B/C" | The whole point of the skill is to surface the user's preference, not the agent's. Generate ≥ 2. |
| "Bypass is faster than rendering 3 variants" | Bypass requires recorded reason; silent skip = auto-trigger. Don't shortcut. |
| "This is dashboard, taste rules don't apply" | Correct — but mark it: `[taste:exempt]` + `[proto:exempt]` entry, not silent skip. |
| "Just use `meisijiya-frontend-taste` directly" | That skill is for production UI; `/prototype` is for spec-authoring throwaway scaffolds. They overlap on rules but differ on lifetime. |
| "Render failed, just delete the variant" | The user must see the failure; mark it `render:failed` and keep it shown. |
| "User said they like A, ship it" | Until the user clicks / types the selection and you write `[proto]`, status is `awaiting_selection` not `resolved`. |
| "Spec amend retroactively replaces prototype" | Mark `[proto:superseded] ts=... prior=... by=[amend:...]` — the old choice stays in history, don't silently rewrite. |
| "Greenfield is just like brownfield, same HTML" | Greenfield lives in `.omo/prototypes/<plan>/`, brownfield lives in `.omo/throwaway/<feature>/`. Different lifetimes, different cleanup paths. |
| "1 valid variant is enough, decision is clear" | No — MIN 2 valid variants else `NEEDS_CONTEXT`. A single render means the other two failed; user must know. |

## Red Flags

- `[PROTO-RESOLVE]` markers in a `spec_approved` spec (status gate must be 0 remaining)
- Variant files generated but `[proto]` decision entry missing
- `status.json.state` flipped to `resolved` without an explicit user choice
- Bypass recorded without `reason` field
- `render:failed` variant silently removed from index
- Marketing-grade variant with `[taste:exempt]` (the exemption is for data-heavy / dashboard only)
- All variants share the same layout / density / motion — inter-axis divergence missing
- `/prototype` invoked without a plan slug
- Phase 1.2 prototype gating skipped, jumping straight to `spec_approved`
- Greenfield variants generated under `skills/` or other production paths instead of `.omo/prototypes/<plan>/`

## Verification

Before reporting selection / bypass / NEEDS_CONTEXT, confirm:

- [ ] `status.json` exists at `.omo/prototypes/<plan>/status.json` with valid state
- [ ] ≥ 2 valid variants (else state = `need_context`)
- [ ] Each variant differs on at least one axis (layout / density / motion)
- [ ] Marketing-grade variants pass `meisijiya-frontend-taste` rules; data-heavy variants carry `[taste:exempt]` annotation + `[proto:exempt]` decision entry
- [ ] `render:failed` variants remain visible in the index with annotation
- [ ] `[proto]` decision entry written to `.omo/notepads/<plan>/decisions.md` on `resolved`
- [ ] Spec `[PROTO-RESOLVE]` marker replaced with chosen variant text + rationale on `resolved`
- [ ] Bypass (if used) recorded with `reason` field, marker replaced with `(bypassed <date>, reason: ...)`
- [ ] No `status.json.state = resolved` without explicit user selection
- [ ] Greenfield variants under `.omo/prototypes/<plan>/`; brownfield under `.omo/throwaway/<feature>/`; neither under `skills/` or other production paths

## omo Integration

Use the Prometheus plan at `.omo/plans/<slug>.md` Phase 1.2 for gating context; record decisions in `.omo/notepads/<plan>/decisions.md` (append-only via `notepad-write-guard` hook); variants land in `.omo/prototypes/<plan>/` (greenfield) or `.omo/throwaway/<feature>/` worktree (brownfield); intra-variant taste enforcement routes through `meisijiya-frontend-taste`; status gate prevents `spec_approved` while `[PROTO-RESOLVE]` markers remain; Phase 2 startup A2 sweep cleans brownfield worktrees.
