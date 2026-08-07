# `/prototype` — spec authoring visual-decision skill

Resolves layout / density / motion decisions that text-only specs cannot answer. Generates throwaway UI variants during Phase 1.2 of [`spec-driven-development`](~/.agents/skills/spec-driven-development/SKILL.md); user picks; the choice lands in `decisions.md` and replaces the `[PROTO-RESOLVE]` marker in the spec. **Never ships to production.**

## When to use

- Spec contains `[PROTO-RESOLVE: <question>]` markers
- User invokes `/prototype` to compare variants
- A wayfinder `prototype` ticket dispatches here

**Not for:** implementing production UI (use `incremental-implementation` + `meisijiya-frontend-taste`), deploying artifacts (`pre-ship-gate`), or generating design tokens for handoff (`designer-handoff`).

## How it works

```
[PROTO-RESOLVE] marker
  ↓
Phase 1.2 — Visual Gating
  ├─ status.json: triggered → generating → awaiting_selection → resolved
  │   (alt: need_context, bypassed)
  ├─ 3 default variants (max 5, MIN 2 valid)
  ├─ each variant differs on ≥ 1 axis: layout / density / motion
  ├─ brownfield: ?variant=A|B|C|E + floating switcher (.omo/throwaway-worktree/<feature>/)
  ├─ greenfield: own static HTML generator (.omo/prototypes/<plan>/{variant-*,index}.html)
  ├─ marketing-grade: meisijiya-frontend-taste enforced
  │   data-heavy/dashboard/multi-step: [taste:exempt] annotation
  └─ render-failed: [render:failed] annotation, still shown, counted invalid
  ↓
[proto] decision entry in decisions.md
  ↓
spec [PROTO-RESOLVE] marker replaced with chosen variant text
```

## Decisions format

```text
[proto] ts=<iso8601> feature=<slug> variant=<A|B|C|E> reason=<≤150char>
[proto:exempt] ts=<iso8601> variant=<A|B|C|E> reason=<为什么超 marketing-grade>
[proto:superseded] ts=<iso8601> prior=<prev ts> by=[amend:<ts>]
[proto:cleanup] worktree=<path> status=<obsolete|stale|deleted>
[proto:bypass] ts=<iso8601> feature=<slug> reason=<1-2 sentences>
```

## Bypass policy (default TRIGGER)

Bypass is opt-out, never opt-in. Conditions (all require explicit reason):

- Trivially obvious (1-sentence justification)
- Constrained by existing ADR / conventions (cite)
- Unrenderable (pure algorithm / data model)

Bypass **mandatory** record: `[proto:bypass]` in `decisions.md` + spec marker replaced with `(bypassed <date>, reason: ...)`. No bypass record → treated as triggered (auto-call).

## Storage

- Status: `.omo/prototypes/<plan>/status.json` (per-plan, state machine)
- Variants: `.omo/prototypes/<plan>/{variant-A,B,C,index}.html` (greenfield) OR `.omo/throwaway-worktree/<feature>/` worktree (brownfield)
- Decisions: `.omo/notepads/<plan>/decisions.md` (append-only)
- Spec: original `[PROTO-RESOLVE]` marker replaced with chosen variant text

## Hard rules

- ≥ 2 valid variants else `NEEDS_CONTEXT` (state = `need_context`)
- Each variant differs on ≥ 1 axis (layout / density / motion)
- Marketing-grade → `meisijiya-frontend-taste` enforced; data-heavy → `[taste:exempt]` annotation
- `render:failed` variants stay visible; not silently deleted
- Bypass requires `reason`; silent bypass = auto-trigger
- Greenfield under `.omo/prototypes/`, never under `skills/` or other production paths
- Brownfield under `.omo/throwaway-worktree/`, never under `skills/` or other production paths

## Related skills

- Spec authoring context: [`spec-driven-development`](~/.agents/skills/spec-driven-development/SKILL.md) — Phase 1.2 visual gating
- Production UI taste: [`meisijiya-frontend-taste`](~/.agents/skills/meisijiya-frontend-taste/SKILL.md) — intra-variant enforcement
- Wayfinder dispatch: [`wayfinder`](~/.agents/skills/wayfinder/SKILL.md) (P1) — `prototype` ticket type
- Cleanup: [`incremental-implementation`](~/.agents/skills/incremental-implementation/SKILL.md) — Phase 2 A2 startup sweep for brownfield worktrees
