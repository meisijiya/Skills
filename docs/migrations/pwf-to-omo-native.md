# PWF → OMO-native Migration

> Phase 0 Design for ADR-0001. Status: `design_approved_pending_spec`.

## 1. What PWF + the Skill system used to look like

The Skill system and PWF were integrated as three layers:

**Skill layer** — methods mapped onto PWF phases:

| Skill | PWF phase |
|---|---|
| `brainstorming` | Phase 0: Design (in `task_plan.md`) |
| `spec-driven-development` | Phase 1: Spec + `attest-plan.sh` SHA lock |
| `source-driven-development` | Phase 2: Research (writes `findings.md`) |
| `incremental-implementation` | Phase 3: Slices (rows in the phase table) |
| `test-driven-development` | Phase 4: Per-slice verification |
| `debugging-and-error-recovery` | Phase 5: Fix (errors table) |
| `verification-before-completion` | cross-cutting gate |

Extra Skills mapped to sub-phases (`designer-handoff`, `api-and-interface-design`, `contract-strengthening`,
`security-and-hardening`, `security-devsecops`, `performance-optimization`, `observability-and-instrumentation`,
`ai-code-blindspots`, `build-gate-visual-review`, etc.) and wrote side artifacts into `.planning/<id>/`.

**PWF file layer** — three files in project root or `.planning/<id>/`:

- `task_plan.md` — Goal / Next Step / Phases (status) / Decisions / Errors.
- `findings.md` — research notes; treated as untrusted content.
- `progress.md` — session log, test results, decision summaries.

Plus attestation metadata:

- `.attestation` — SHA-256 of `task_plan.md`, the "spec is frozen" lock.
- `.mode` / `.nonce` / `.stop_blocks` / `.gate_last_ledger` — v3 autonomous/gated gate machinery (not enabled here in practice).
- `ledger-<agent>.jsonl` — machine-progress events (not enabled here).

**Plugin hard layer** (`skills/extra/pwf-enforcer/templates/pwf-enforcer.ts`, an OpenCode plugin):

- `experimental.chat.system.transform` — inject PWF reminder into every system prompt.
- `chat.message` — per-turn dedup state reset.
- `tool.definition` — rewrite `write`/`edit` tool descriptions to remind about `progress.md`.
- `tool.execute.before` — `printf` plan head into stderr (fragile backup channel).
- `tool.execute.after` — append `[pwf-enforcer] Update progress.md` marker to Write/Edit tool output.
- `experimental.session.compacting` — push plan head into compaction context (the "killer feature").
- `event(session.idle)` — run `check-complete.sh`, log warn if incomplete (advisory only on OpenCode Tier 3).

A second plugin (`.opencode/plugins/meisijiya-skills.js`) injected `using-meisijiya-skills` bootstrap content
into the first user message, so dispatch always fired.

## 2. Problems this integration solved

- Skills had durable phase anchors beyond the chat context.
- Design, research, and slice state survived `/clear` and compaction via PWF files.
- External research was quarantined from Spec text via the `findings.md` vs `task_plan.md` boundary.
- Spec content was hash-locked via `attest-plan.sh`; tampering surfaced immediately.
- Skill methods landed as visible state rows, not just chat history.
- Per-Edit reminders reduced the "I forgot to update the plan" failure mode.

## 3. Why it stopped fitting

- OMO grew into the same capability surface: Prometheus / ulw-plan, Boulder, task tools, notepads,
  evidence ledger, compaction hooks, start-work completion. PWF did not gain any new capability that
  OMO lacks.
- `/start-work` reads only `.omo/plans/*.md`; it never inspects `task_plan.md`. The intended
  "PWF Spec → OMO execution" bridge never existed in code.
- The PWF v3 ledger, `.mode` gated mode, and stall detector were never enabled in this fork; PWF was
  effectively running v2 behavior on top of a v3 binary.
- Local slice status (6 states including `superseded` / `rolled_back`) did not match PWF's 3-state
  schema; `check-complete.sh` could report "all complete" while slices were in mid-amend.
- PWF Tier 3 (OpenCode) cannot hard-block Stop; the strongest PWF gate degraded to advisory.
- Two parallel persistence contracts meant every Skill that touched state had to decide which side
  to write to. Drift was inevitable.
- Maintenance cost tracked both PWF upstream changes and OMO plugin API changes.

## 4. Target layering after migration

| Layer | Owns |
|---|---|
| **Skill** | Method, professional workflow, trigger conditions, OMO handoff statements. Never edits runtime state directly. |
| **OMO** | Plans, drafts, Boulder work state, task DAG, notepads, evidence ledger, review-work, continuation, compaction. |
| **Plugin (local)** | Only where OMO has no native equivalent and the failure mode is real and observed. Not a second planning/runtime layer. |
| **ADR / migration doc** | Architecture decisions and historical context. Not consulted by runtime. |

## 5. Migration phases

Each phase is independently verifiable and does not require the next to be done.

- **Phase A — Documentation deposit (current phase)**
  - ADR 0001 (this repo).
  - This migration document (this repo).
  - `AGENTS.md` Section A: drop PWF/Sisyphus stack phrasing; replace `pwf-enforcer` entry with the next
    routing note.
  - `README.md`: drop PWF installation prerequisite; keep PWF reference link for historical readers.
  - `docs/omo-agent-skill-config.md`: keep; update only if a Skill is removed.
  - `docs/agents-md-guide.md`: no changes (already forbids historical narrative in injected blocks).

- **Phase B — Marketplace + install + retire plugin**
  - Remove `pwf-enforcer` from `.claude-plugin/marketplace.json`.
  - Remove `pwf-enforcer` from `install.sh` and `skills/extra/README.md` "how to choose" tables
    (the `for d in skills/extra/*/` and `for d in skills/core/*/` globs in `install.sh` and the
    `find skills -mindepth 2` in `check-marketplace.sh` do not match `skills-archived/`, so they
    already exclude it; no script edits are needed to keep those tools blind to archived skills).
  - Move `skills/extra/pwf-enforcer/` to `skills-archived/pwf-enforcer/` (Skill + `templates/pwf-enforcer.ts` + any subdirectory references).
  - Move `evals/cases/pwf-enforcer.json` to `evals/cases-archived/pwf-enforcer.json`.
  - Add `skills-archived/README.md` explaining: archived skills are read-only historical reference,
    never installed, never listed, never auto-discovered. Cross-link to ADR 0001 and to this doc.
  - Add `evals/cases-archived/README.md` explaining the same for archived eval cases.

- **Phase C — Core Skill rewrite (8 files)**
  - Replace `## pwf Integration` with `## omo Integration` in:
    `using-meisijiya-skills`, `brainstorming`, `spec-driven-development`,
    `incremental-implementation`, `test-driven-development`,
    `verification-before-completion`, `debugging-and-error-recovery`, `source-driven-development`.
  - Replace PWF phase references in Process sections with OMO handoff statements.
  - Re-check `description` triggers to keep ≤ 1024 chars.

- **Phase D — Extra Skill rewrite (15 files)**
  - Same rewrite for: `designer-handoff`, `api-and-interface-design`, `contract-strengthening`,
    `security-and-hardening`, `security-devsecops`, `security-incident-response`,
    `performance-optimization`, `observability-and-instrumentation`,
    `documentation-and-adrs`, `improve-codebase-architecture`, `verify-chain`,
    `loop-me`, `ai-code-blindspots`, `build-gate-visual-review`, `writing-skills`.

- **Phase E — Eval case rewrite**
  - For each `evals/cases/*.json` with `task_plan.md` / `progress.md` / `findings.md` / `attest` /
    "PWF" / "pwf" strings, rewrite `behavioral_evals.expected_behavior` to refer to OMO artifacts
    and intent gate, not PWF files.
  - Keep 3 positive + 3 negative triggers minimum; preserve intent.

- **Phase F — Historical archive**
  - Leave existing `.planning/<id>/` directories in place.
  - Add a top-level `README.md` inside `.planning/` noting that contents are read-only archive
    from before OMO-native migration and are not consumed by current Skills.

- **Phase G — Release hygiene**
  - Update `CHANGELOG.md` with a "OMO-native migration" entry under Unreleased.
  - Bump version tag per repo policy.
  - Re-run `scripts/validate-skills.sh` + `scripts/check-marketplace.sh` + skill eval CI.

## 6. PWF ideas worth keeping (without the PWF runtime)

These principles survive the migration as part of Skill philosophy; they do not need PWF to enforce them.

- Design precedes implementation.
- External research is quarantined from Spec text.
- Critical decisions are traceable.
- Evidence precedes completion claims.
- State must survive context boundaries.
- Workers do not edit the orchestrator's plan.
- Runtime state has exactly one owner; if two systems both claim it, fix the ownership, not the sync.

## 7. Reusable lessons (for the next runtime migration)

If `meisijiya-skills` ever moves off OMO, run this audit before writing code:

- Does the new runtime already provide plans / drafts, task DAG, progress, evidence, continuation,
  compaction recovery, approval gates, and subagent review? List each, with the module that owns it.
- For each persistence concept, who writes, who reads, who restores, who declares completion, and
  who owns user approval? If two answers exist, ownership is wrong — fix it, do not sync.
- Plugins exist only where the runtime has a real gap. A plugin that duplicates the runtime is a
  liability, not a defense.
- Do not preserve a dual-layer. Compatibility layers restore the very drift the migration exists to
  remove.
- Document the migration in two files: an ADR (the why) and a retrospective (the how + reusable
  lessons). Never mix the two.

## 8. Open questions (defer to Phase 1)

- How exactly does `brainstorming` declare "the design is captured" once PWF phases no longer exist?
  Defer to Phase 1.
- Does any extra Skill need its own state beyond OMO notepads? If yes, where does that state live
  and who owns it? Defer to Phase 1.
- Should the ADR propose a follow-up ADR if a custom attestation helper is later justified? Deferred
  per the Alternatives section.

## 9. Transitional note (between Phase A and Phase B)

Until Phase B moves `skills/extra/pwf-enforcer/` into `skills-archived/`, `scripts/install.sh`
and existing copies of the plugin at `~/.config/opencode/plugins/pwf-enforcer.ts` keep the
legacy behavior: per-Edit `[pwf-enforcer] Update progress.md` reminders may still appear in
sessions running against the current codebase. This is expected: design landed in Phase A, the
archival move lands in Phase B. Sessions whose plugin was already installed before Phase B will
stop getting reminders after the user manually removes the cached plugin file, or after a fresh
install + restart of OpenCode. Do not interpret the transitional reminder as a contradiction;
treat it as the work that Phase B has to finish.

## Phase 1: Spec

> Spec location note
> The default rule from `spec-driven-development` would write this Spec into `task_plan.md`. Per
> the brainstorming Phase 0 decision, this Spec is written into the migration document because
> the Spec itself retires `task_plan.md` as a planning artifact. Keep this file readable in
> isolation; if you ever replicate this migration, treat the Phase 1 sections below as the
> authoritative contract for what Phase A–G must produce.

**Goal:** Make OMO the single planning and runtime state owner of `meisijiya-skills`, retire the
PWF Skill/plugin/runtime footprint from active distribution, preserve `pwf-enforcer` as a
historical reference under `skills-archived/`, and keep all repo automation (CI scripts, marketplace
manifest, install script, AGENTS.md inject) consistent with the new boundary.

**Scope:**

- In:
  - Move `skills/extra/pwf-enforcer/` → `skills-archived/pwf-enforcer/` (Skill + `templates/pwf-enforcer.ts`).
  - Move `evals/cases/pwf-enforcer.json` → `evals/cases-archived/pwf-enforcer.json`.
  - Remove `pwf-enforcer` from `.claude-plugin/marketplace.json` and from `skills/extra/README.md` / `skills/core/README.md` cross-references.
  - Rewrite 8 core + 15 extra `SKILL.md` files: drop `## pwf Integration` sections, replace `task_plan.md` / `findings.md` / `progress.md` / `attest-plan.sh` / `.attestation` references in `Process` and other sections with OMO equivalents (Prometheus plan, Boulder, task tools, notepads, evidence ledger, start-work, review-work, `compaction-context-injector`).
  - Rewrite `evals/cases/*.json` behavioral_evals that mention PWF artifacts.
  - Update `README.md` (drop PWF install prerequisite and `--skill pwf-enforcer` example), `AGENTS.md` Section A (drop "omo + pwf stack" phrasing, drop `pwf-enforcer` from extra catalog, replace `No direct omo bridge (yet)` block), `docs/agents-md-guide.md` cross-reference (drop `pwf-integration.md` line), `docs/omo-agent-skill-config.md` (per-Skill skill list stays valid; only one missing-skill entry needs removing), `pwf-integration.md` → archive or delete (deferred to Phase G).
  - Add `skills-archived/README.md` and `evals/cases-archived/README.md` per Phase B recipe.
  - Add `.planning/README.md` per Phase F recipe.
  - Update `CHANGELOG.md` Unreleased section.
  - Keep `.planning/<id>/` directories on disk without modification.
  - Keep ADR 0001 status updated to `accepted` on Phase G.

- Out:
  - No new state machine, no new planning tool, no rewritten OMO behavior.
  - No `attest-plan.sh` replacement.
  - No deletion of `.planning/<id>/` directories.
  - No new eval case construction (existing cases are rewritten in place).
  - No changes to OMO upstream.
  - No compatibility layer that reads `task_plan.md` as a fallback.
  - No edits to `docs/skill-design-principles.md`'s "If meta-skill" guidance or its 6-section rule (the rule stays valid; only the per-Skill `## pwf Integration` sections are removed).
  - No edits to `docs/agents-md-guide.md`'s narrative hygiene rules.

**Acceptance Criteria:**

- [ ] `git grep -l pwf-enforcer skills/ evals/cases/ marketplace.json scripts/ docs/` returns no `skills/` or `evals/cases/` hits outside the `skills-archived/` and `evals/cases-archived/` tree.
- [ ] `git grep -nE 'task_plan\.md|progress\.md|findings\.md' skills/ evals/cases/ docs/ README.md AGENTS.md` shows zero matches inside any active SKILL.md, any active eval case, or `AGENTS.md` Section A. (`docs/migrations/pwf-to-omo-native.md` may reference them by name for historical reason only.)
- [ ] `scripts/validate-skills.sh` exits 0.
- [ ] `scripts/check-marketplace.sh` exits 0 with `(N skills)` matching the count of `./skills/core/*` plus `./skills/extra/*` in `marketplace.json`.
- [ ] `scripts/inject-agents-md.sh --dry-run` prints `(8 core + 15 extra)` because the derive step reads `N_CORE` and `N_EXTRA` from marketplace.json; running with no flag against a clean target writes a block whose catalog count matches marketplace.json. (Numeric derivation is verified by inspection, no shell test.)
- [ ] `.opencode/plugins/pwf-enforcer.ts` template file no longer exists under `skills/extra/`; the canonical source for the archived plugin is `skills-archived/pwf-enforcer/templates/pwf-enforcer.ts`. No install or plugin-loader path points at it.
- [ ] `skills-archived/README.md` exists and explicitly states: archived skills are read-only historical reference, never installed, never auto-discovered.
- [ ] `evals/cases-archived/README.md` exists, matching the same convention for archived eval cases.
- [ ] `.planning/README.md` exists, labelling the directory as read-only archive.
- [ ] `AGENTS.md` Section A's "omo integration" block no longer says `(yet)` next to `pwf-enforcer` or names PWF phases.
- [ ] Each rewritten core Skill's `Process` section contains an explicit handoff statement that names an OMO capability (Prometheus plan, Boulder, task, notepad, evidence, start-work, review-work, or `compaction-context-injector`).
- [ ] Each rewritten extra Skill has either no handoff needed (it produces static project artifacts only) or an OMO handoff statement naming an OMO capability.
- [ ] Each rewritten `description` frontmatter is ≤ 1024 chars and still parses as YAML (visible from `validate-skills.sh` exit 0).
- [ ] `CHANGELOG.md` Unreleased contains a short bullet naming the OMO-native migration and the Skill it removes (`pwf-enforcer`) without narrating pre-migration state.

**Commands to Run:**

- `bash scripts/validate-skills.sh` — exit 0.
- `bash scripts/check-marketplace.sh` — exit 0.
- `bash scripts/install.sh --list` — lists 15 extra skills (one fewer than before; `pwf-enforcer` absent).
- `bash scripts/install.sh --dry-run --target /tmp/mjs-spec-$TS` and confirm the target has no `pwf-enforcer` directory. (Tarball-style smoke run.)
- `bash scripts/inject-agents-md.sh --dry-run` — no error, block line count consistent with marketplace counts.
- `node --check .opencode/plugins/meisijiya-skills.js` and `node --check .opencode/plugins/meisijiya-review-router.js` — exit 0 (verifies plugins untouched by migration remain valid).
- `grep -r "pwf" skills/ evals/cases/ AGENTS.md scripts/ README.md 2>/dev/null` (excluding `skills-archived/`, `evals/cases-archived/`, and `docs/migrations/`, `docs/adr/`) returns no matches. The historical `pwf-integration.md` is removed by Phase G and is the only file that should disappear during the migration, not stay as a historical doc.
- `grep -rE "task_plan\.md|progress\.md|findings\.md" skills/ evals/cases/ AGENTS.md README.md scripts/` (excluding `skills-archived/`, `evals/cases-archived/`) returns no matches.
- `grep -rE "task_plan\.md|progress\.md|findings\.md" skills/ evals/cases/ AGENTS.md README.md` returns no matches outside the historical/migration docs (allowed: `docs/migrations/`, `docs/adr/`, `CHANGELOG.md`).

**Test Strategy:**

- *Static*: scripts above exit 0; greps return the documented empty/positive results.
- *Skill eval CI*: the existing per-Skill `evals/cases/*.json` JSON shapes must remain valid (`bash scripts/validate-skills.sh` includes a JSON parse step). Behavioral_evals content is rewritten under Phase E; CI just enforces well-formed JSON plus the marketplace bijection, not behavioral correctness.
- *Skill description content*: the regex check in `validate-skills.sh` requires `name` ≤ 1024 chars and matches the directory; per-Skill rewrite must keep both constraints.
- *Plugin smoke*: `node --check` on both shipped `.js` plugins; any syntactic regression fails CI even if the migration does not touch them.
- *Archive directory*: a fresh shell expansion test (`ls skills-archived/pwf-enforcer/`) confirms the moved Skill is on disk; `ls evals/cases-archived/` confirms the moved eval case.
- *User journey*: a manual smoke of `npx skills add meisijiya/Skills --list` (or equivalent local install) must not surface `pwf-enforcer` in the picker.

**Risks:**

- *Risk*: A rewritten SKILL.md accidentally softens an existing skill, e.g. by dropping a step that was only justified in `## pwf Integration`.
  → *Mitigation*: Phase C/D edits the `## pwf Integration` section and references in `Process`; the rest of each SKILL.md stays unchanged and is re-read in the same PR.
- *Risk*: Removing `pwf-enforcer` from marketplace breaks a downstream project's reference to `~/.agents/skills/pwf-enforcer/`.
  → *Mitigation*: The Skill was a no-op without the plugin, and the plugin's OpenCode Tier 3 behavior was advisory only; the migration doc (Section 9) tells the reader how to delete the cached plugin manually.
- *Risk*: AGENTS.md Section A still references `pwf-enforcer` after Phase A if the auto-derive counter is not updated.
  → *Mitigation*: `scripts/inject-agents-md.sh` derives counts from marketplace.json at every run; once `marketplace.json` no longer lists `pwf-enforcer`, the auto-derive removes it from rendered Section A.
- *Risk*: Hard-coded `grep "skills/extra/pwf-enforcer/"` patterns appear in third-party tools or user memory.
  → *Mitigation*: `skills-archived/` keeps the source available at a stable path; the URL of the archived Skill is documented in its `skills-archived/pwf-enforcer/SKILL.md` frontmatter (a single `archived: true` line).
- *Risk*: Hidden references in `README.md`, `CHANGELOG.md`, or older planning examples keep `progress.md` / `task_plan.md` alive semantically.
  → *Mitigation*: `grep` checks above; Phase F archives them under `.planning/README.md`.

**Status:** spec_approved (2026-07-23). ADR 0001 advanced to `accepted` on the same date. Hand off to `incremental-implementation` for vertical-slice execution.