# .planning/ — read-only archive

This directory contains historical plan artifacts from before the OMO-native
migration (ADR 0001, accepted 2026-07-23). It is **frozen** — no current skill
or script reads from any `.planning/<id>/*` file.

## Why kept on disk

These are the working files for past planning sessions. Removing them would
orphan historical context that may still be useful for retrospective analysis
or fork archaeology. Migration does not delete them; it labels them.

## Contents

Each subdirectory is a self-contained plan with its own `task_plan.md`,
`findings.md`, `progress.md`, and (where attested) `.attestation`.

- `2026-07-20-add-verify-chain-skill/` — 3-role IT article verification pipeline (Critic / Verifier / Repairer)
- `2026-07-20-readme-opencode-audit/` — README audit pass before OMO-native alignment
- `2026-07-20-remove-legacy-aliases-and-kanban-slices/` — retired `interview-me` + `code-simplification` aliases
- `2026-07-20-teaching-gate-document-design/` — design rationale for build-gate-visual-review
- `2026-07-21-add-ai-code-blindspots-skill/` — 7-category blindspots scan for AI-generated code
- `2026-07-21-add-loop-me-skill/` — recurring-workflow spec authoring (`/loop-me`)
- `2026-07-22-ai-agent-guardrails-research/` — research notes on guardrail patterns (pre-spec)
- `2026-07-22-contract-strengthening-skill/` — Phase 1.25 open-world contract review

### Attestation shas (historical reference)

5 of 8 plans carry an `.attestation` file recording a sha256 at completion.
The remaining 3 were not formally attested; their `progress.md` is the source
of truth for what shipped.

| Plan | Attestation sha256 |
| --- | --- |
| `2026-07-20-add-verify-chain-skill` | `6d79e16e60699d3414990922b9afce66a35cc758bcd2c8186d36ad31dbbdaec4` |
| `2026-07-20-remove-legacy-aliases-and-kanban-slices` | `77df78dcff2671f5a697b91bfba7911435e30521544515cbd387c3fdd474474c` |
| `2026-07-20-teaching-gate-document-design` | `baafd4bdada07928582e71028aec8f89137957dcfb9719d4e8665964ea3c84df` |
| `2026-07-21-add-ai-code-blindspots-skill` | `d17d283bf90385fa11bc489b5096e7415e5acae95d71a6052c9a5b3cf98fbd5a` |
| `2026-07-22-contract-strengthening-skill` | `c811a97a6ad547feae6387c10eb2e9e7f8afff1d2dbc9abb6a33a07b70138326` |

Not attested: `2026-07-20-readme-opencode-audit`, `2026-07-21-add-loop-me-skill`, `2026-07-22-ai-agent-guardrails-research`.

## `.active_plan`

The `.active_plan` file (40 bytes) names `2026-07-22-contract-strengthening-skill`
as the most recent active plan. After the OMO-native migration, this pointer
is **historical reference only**; OMO uses its own plan/notepad system under
`.omo/plans/` and Boulder state, not `.planning/<id>/task_plan.md`.

## See also

- [`docs/adr/0001-adopt-omo-native-state.md`](../docs/adr/0001-adopt-omo-native-state.md) — the ADR that retired PWF as a planning layer
- [`docs/migrations/pwf-to-omo-native.md`](../docs/migrations/pwf-to-omo-native.md) — migration SPEC with Phase-by-Phase record