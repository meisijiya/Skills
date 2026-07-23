# ADR-0001: Adopt OMO as the sole planning and runtime state owner

**Status:** accepted (2026-07-23)
**Date:** 2026-07-23

## Context

This fork (`meisijiya-skills`) was originally built around `planning-with-files` (PWF) as the persistent planning layer.
Skill methods (brainstorming → spec → slices → TDD → verification) were mapped onto PWF phases, and a dedicated
OpenCode plugin (`pwf-enforcer`) injected plan heads into prompts, reminded after Write/Edit, restored plan context
after compaction, and warned on incomplete plans at session idle.

OMO (`code-yeongyu/oh-my-openagent`, currently v4.19.x) has since grown into a full planning and runtime layer of
its own: Prometheus / ulw-plan write executable plans to `.omo/plans/<slug>.md`, Sisyphus / Atlas track work in
`.omo/boulder.json`, the `task_*` tools own the task DAG, `.omo/notepads/` carries working memory, `.omo/start-work/ledger.jsonl`
stores evidence, and the start-work skill defines DoneClaim / AdversarialVerify completion.

Operating both layers in parallel produces a dual-authority problem:

- `task_plan.md` and `.omo/plans/*.md` carry overlapping but non-interchangeable content.
- `/start-work` reads `.omo/plans/*.md` only; it never opens `task_plan.md`.
- PWF v3 ledger and `.start_blocks` were never enabled in practice here.
- The local slice state machine (6 states including `superseded` / `rolled_back`) does not match PWF's native
  3-state schema, so completion scripts silently misread status.
- PWF Tier 3 (OpenCode) cannot hard-block Stop; the strongest PWF gate is downgraded to advisory under the
  actual runtime.

## Decision

OMO is the sole planning and runtime state owner for `meisijiya-skills`.

PWF runtime artifacts, the `pwf-enforcer` Skill + OpenCode plugin, the SHA-256 attestation contract, and the
PWF file contract (`task_plan.md`, `findings.md`, `progress.md`, `.attestation`) are retired from the
active distribution. Existing `.planning/<id>/` directories stay on disk as read-only archives but are
not consumed by any current skill or plugin. No PWF/OMO dual-write compatibility layer is provided.

The retired PWF Skill + plugin are preserved for historical reference under a top-level
`skills-archived/` directory (sibling to `skills/`). It is intentionally not indexed by
`scripts/check-marketplace.sh` (`find skills -mindepth 2` excludes it), `scripts/install.sh`
(only scans `skills/core/` and `skills/extra/`), `scripts/inject-agents-md.sh`
(`./skills/...`), or by the `npx skills add` CLI (marketplace lists only `./skills/...`).
`sources/spec/dependencies/...` standard. The `skills-archived/` directory therefore requires no
blacklist configuration to stay hidden from active tooling.

Future retirements of skills for any reason default to this same archived path; deletion is no
longer the default archival disposition.

Skills continue to own their own method, professional workflow, and trigger conditions; they must not edit
runtime state (Boulder, task tools, plan checkboxes) directly. Handoff to OMO is declarative
("invoke plan through OMO", "verify via OMO review-work"), not procedural.

## Consequences

**Positive**

- Single state owner for planning, progress, evidence, and continuation.
- Plugin surface shrinks to OMO weaknesses only (no PWF duplicate).
- Skill ↔ runtime boundary becomes explicit and inspectable.
- Local Skill descriptions stop carrying PWF phase assumptions that no longer hold.
- Future Skill authoring does not have to negotiate two persistence contracts.

**Negative**

- Lose PWF SHA-256 attestation on Spec content.
- 23 `SKILL.md` files need `## pwf Integration` removed or rewritten as `## omo Integration`.
- `pwf-enforcer.ts` template, eval case, marketplace entry, and install.sh branch must be removed.
- Breaking workflow change: any project whose active plan lives in PWF will see Skill behavior shift on
  next session.

**Reversibility:** hard. Once plugins and Skill contracts are rewritten, restoring PWF requires reauthoring
23 skills, the marketplace, and three doc files.

## Alternatives considered

- **Keep PWF + OMO dual-layer.** Rejected. Dual-authority drift has already been observed; the gap
  will keep widening as OMO evolves.
- **Keep a thin PWF for Spec attestation only.** Rejected. OMO does not provide an equivalent hash lock,
  and the value of attestation does not justify the maintenance of a parallel planning layer.
- **OMO-only with a custom attestation helper built into Skill.** Deferred. Not adopted in this
  decision; revisit only if a real failure proves attestation matters in practice.