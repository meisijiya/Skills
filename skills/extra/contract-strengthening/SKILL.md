---
name: contract-strengthening
description: "Use when the user-visible change touches contracts, shared state, timing, concurrency, or untrusted boundaries — even when the implementation feels small. Trigger conditions are open-world, non-exhaustive properties (contract completeness, state/timing/concurrency, boundary/dependency, blast-radius/reversibility, verification-blind-spot); absence from the list never proves ordinary L1 suitability, and newly discovered signals belong in scope. Use also when a global installation is being considered, when a verification backend has no project-local alternative, or when prior authorization is being cited for a new tool, version, or effect. Complements security-ownership-map (people↔file governance / bus-factor questions) and security-threat-model (adversarial-boundary questions) — different axes on the same sensitive-change surface. NOT for ordinary L1 work already covered by TDD + verification-before-completion, pre-Spec design exploration (use brainstorming), or one-line style changes."
allowed-tools: "Read Write Edit Bash Glob Grep"
---

# Contract Strengthening

## Overview

Optional extra skill that strengthens AI coding work via **open-world, non-exhaustive** risk classification. The risk catalog is illustrative only — new signals discovered during review must be added, never excluded by category. Does **not** replace [`brainstorming`](~/.agents/skills/brainstorming/SKILL.md), [`spec-driven-development`](~/.agents/skills/spec-driven-development/SKILL.md), [`test-driven-development`](~/.agents/skills/test-driven-development/SKILL.md), or [`verification-before-completion`](~/.agents/skills/verification-before-completion/SKILL.md); it sits **after** the attested Spec and **before** implementation slicing.

The skill provides **open-world risk classification**, **contract-gap review** (invariants, allowed/forbidden transitions, uncompiled requirements, explicit uncertainty), **counterexample design**, **property-driven L1/L2/L3 selection**, **tool-selection precedence (relevance → reuse → isolation → resource check → bounded execution)**, and a **GREEN/YELLOW/RED consent-gate** for global-install exceptions.

## When to Use

**Use when** the change visibly touches one or more of: shared/cached state, time or clocks, concurrency or async fan-out, external or untrusted boundaries, irreversible or blast-radius-sensitive operations, or any area where existing skills would otherwise skip risk escalation because the diff "looks small".

**NOT for:** ordinary L1 work already covered by TDD + verification-before-completion with no contract surface beyond functional behavior; pre-Spec design exploration ([`brainstorming`](~/.agents/skills/brainstorming/SKILL.md)); one-line style/formatting/comment-only changes; live failure triage ([`debugging-and-error-recovery`](~/.agents/skills/debugging-and-error-recovery/SKILL.md)); architecture-wide audits ([`improve-codebase-architecture`](~/.agents/skills/improve-codebase-architecture/SKILL.md)).

## Process

### 1. Open-world risk classification

Read the attested Spec. Enumerate observed risk signals across **non-exhaustive** axes: contract completeness · state/timing/concurrency · boundary/dependency · blast-radius/reversibility · verification-blind-spot. Record each signal as `[observed | absent | uncertain — needs follow-up]` — never collapse to "no risk". Absence from the axes is **not** evidence of safety; new signals discovered during review are added in place.

### 2. Contract-gap review (invariants, transitions, uncompiled requirements)

For each observed or `uncertain` signal from step 1, derive: invariants that must hold across every valid trace; allowed / forbidden transitions between states **only when the contract has a state surface (states, events, or transitions to enumerate)** — an empty forbidden set on a state-bearing contract is a defect, but contracts with no state surface record `not applicable` with the reason rather than inventing a state machine to satisfy the transition set; **uncompiled requirements** the Spec implies but did not state (timing bounds, retry/backoff semantics, partial-failure handling, ordering across boundaries), each tagged `[stated | inferred | unknown]`; and **explicit uncertainty** for every inferred or unknown entry — never collapsed. The review **forbids inventing domain thresholds, data shapes, or calibration constants** to fill uncertainty — record the gap and route it back to the user.

### 3. Counterexample design (per gap)

For each forbidden transition and each uncompiled requirement, name at least one **counterexample**: precondition + observable failure mode. A gap without a counterexample is `unaddressed`, not advanced. If writing the counterexample requires inventing a threshold or data shape, the gap stays `uncertain`; the invented value never ships silently.

### 4. Property-driven Level selection (L1 / L2 / L3)

Levels describe **minimum verification strength**, not domain categories or safety guarantees. Pick per gap, not per change. **L1** — ordinary tests cover the invariants without extra machinery. **L2** — triggered by observed contract completeness, state/timing/concurrency, boundary/dependency, blast-radius/reversibility, verification-blind-spot, or newly discovered signals; requires targeted property / fuzz / mutation / model-check tooling chosen in step 5. **L3** — requires **all six**: explicit property; bounded model or state space; stated environment assumptions; chosen backend (selected via step 5 / step 6 and recorded in the contract-review artifact); reproducible evidence (runnable artifact, not narrative); **a written reason ordinary tests are insufficient**. Perceived small size, deadline pressure, or delegated judgment **cannot** lower the level or skip a step; they can only raise it. Demotion requires explicit user approval recorded in the contract-review artifact.

### 5. Tool selection (relevance → reuse → isolation → resource check → bounded execution)

Pick the tool **after** inspecting the project's current environment. Environment labels (CI / dev / prod / "machine has N GB") are never decision criteria; only measured resources, permissions, and workload bounds are.

Decision order — each step may short-circuit to the next only after a documented check:
1. **Property relevance** — does the tool's API match the gap from steps 1-4?
2. **Reuse an existing project test tool** (project `package.json` / `pyproject.toml` / `Cargo.toml` dev-dependencies, project test runner).
3. **Add a project-local dev/test dependency** — preferred over global install; records the change in the project manifest.
4. **Project virtual / ephemeral environment or project-scoped container** — preferred over global install when isolation is required.
5. **Inspect actual resources before execution**: CPU, memory, disk, permissions, expected duration, concurrency, test/mutation counts, state-space bounds, timeout, cleanup.
6. **Bounded execution** — run with the inspected limits; stop and reassess if any actual effect exceeds the bound.

Loading this skill **never** installs or runs a verifier. Adding a new project dependency requires approval (out of scope here; see step 6). Global installation of a verification backend is **not** an option in step 5; it routes to step 6 only after every documented alternative is recorded as unavailable. Routing aid: `references/verification-backends.md` (guidance only — not permission to install).

### 6. Consent gate (GREEN / YELLOW / RED global-install exception)

Global install of a verification backend is the **exception**, not the default. Step 5's defaults are the rule. Step 6 fires only when **every** reasonable alternative is recorded as unavailable.

Before asking about any global install, record each option considered (yes/no) and why unavailable if no: (1) project-local dev/test dependency; (2) project virtual environment (venv / nix-shell / language-native env); (3) project ephemeral environment (worktree / scratch CI runner); (4) project-scoped container (Docker / Podman / devcontainer) with explicit cleanup.

Then produce a **feasibility / consequence assessment** naming all eleven fields: exact tool; version; official source URL; exact install + invoke + cleanup commands; privilege (user / sudo / system service); global effects (PATH, services, telemetry endpoints, post-install lifecycle scripts); CPU / memory / disk footprint and expected duration; concurrency, test/mutation counts, state-space bounds, timeout, cleanup; supply-chain / security (source signature, checksum, network endpoints); rollback plan (exact reversal and what does **not** roll back); residual risk after a successful install.

Assign a **traffic light** to inform the user; it never replaces consent. **GREEN** — lower assessed risk, *never* zero. **YELLOW** — proceed only with the listed conditions explicitly checked off. **RED** — recommend not proceeding and offer concrete alternatives.

**Approval binds** the exact tool/version/source/commands/privilege/effects/resource+execution bounds/cleanup/rollback/residual risk. Broad prior consent, "just install it", or generic authorization is invalid. Any change to tool/version/source/commands/privilege/effects requires a fresh assessment.

If actual installation or runtime impact **exceeds the approved boundary**, stop immediately, report the deviation, and do not continue verification. Loading this skill never performs the install.

## Common Rationalizations

| Excuse | Reality |
|---|---|
| "100-line diff, contract review is overhead" | Hidden state/timing/boundary signals appear in tiny diffs; small size is the most common rationalization observed in RED baselines. |
| "Deadline is tight — review later" | "Later" means the contract gap ships with the feature; review before any implementation slice starts. |
| "User said use judgment, skip the gate" | Delegated judgment raises, not lowers, the need to record explicit risk signals. |
| "Domain not on the risk list → safe" | The list is non-exhaustive. Absence from examples never proves L1 suitability. |
| "Counterexamples overkill for a 5-line change" (Scenario 1) | Hidden state/timing assumptions in 5-line diffs are the dominant RED gap; small LOC is not evidence of a small contract. |
| "Skip L2/L3 — deadline is tight, ordinary tests are enough" (Scenario 1) | Deadline pressure can only **raise** the level (more uncertainty → more evidence), not lower it. Ordinary tests are insufficient when the gap required step 2. |
| "User said use judgment, design gate not needed" (Scenario 3) | Delegated judgment expands the uncompiled-requirements list, it does not shrink it. The design gate is the place those requirements get stated. |
| "I picked a 5s timeout because Spec didn't say" (Scenario 3) | Inventing thresholds to fill `uncertain` gaps is forbidden. Record the gap as `uncertain` and route back to the user. |
| "Machine has 64GB, no need to isolate or cap" (Scenario 2) | Resource sufficiency ≠ isolation sufficiency. Environment labels and RAM/CPU headlines are not decision criteria; run step 5's actual resource check anyway. |
| "Skill said to verify, so I installed the verifier" | Loading this skill is never authorization. Every install follows step 5's order and (for global installs) the step 6 consent gate. |
| "Just run the property test, skip the timeout" | A missing timeout is not bounded execution; step 5's resource check covers expected duration, concurrency, and state-space bounds. |
| "User said just install it earlier, that's approval" | Broad prior consent is invalid. Approval binds the exact tool/version/source/commands/privilege/effects; any new tool/version/effect requires a fresh step 6 assessment. |
| "GREEN means zero risk" | GREEN = lower assessed risk, *never* zero. Residual risk is recorded explicitly in the assessment and presented to the user. |
| "YELLOW is just documentation" | YELLOW requires the listed conditions to be explicitly checked off before proceeding; it is a gate, not a comment. |
| "Skip the assessment, sudo anyway" | Privilege escalation without a step 6 assessment is RED. Stop, record the assessment, and route back to the user. |

## Red Flags

- Reviewer writes "no risks found" without enumerating each axis explicitly.
- Reviewer treats the risk axes as a closed checklist (new signal encountered → silently ignored).
- Review is skipped because the perceived diff is small or the deadline is tight.
- Contract-review artifact omits the `uncertain` state for any signal the reviewer could not confirm.
- A forbidden transition is marked addressed with no counterexample in step 3 (gap silently advanced).
- L3 chosen for a gap without all six required fields (property / bounded model / env assumptions / backend / evidence / insufficiency reason).
- A verifier was installed or run because the skill was loaded (skill load is never authorization).
- Resource label ("64GB RAM" / "prod" / "CI") used as a decision criterion in step 5 instead of measured bounds.
- Bounded execution skipped: no timeout, no mutation cap, no `max_examples` budget for the chosen backend.
- GREEN recorded in the contract-review artifact without the 11-field feasibility / consequence assessment.
- Approval recorded without all 11 assessment fields (tool / version / source / commands / privilege / effects / resource+execution bounds / cleanup / rollback / residual risk).
- Step 6 fired before every reasonable alternative in step 5 was recorded as unavailable with a reason.
- Installation or verification continued after actual impact exceeded the approved boundary.

## Verification

- [ ] `bash scripts/validate-skills.sh` reports OK for `skills/extra/contract-strengthening/SKILL.md`.
- [ ] `bash scripts/check-marketplace.sh` reports OK (entry present in `.claude-plugin/marketplace.json`).
- [ ] Skill↔eval bijection reports 24 (from CI workflow lines 32-50).
- [ ] `## omo Integration` states `Phase 1.25: Contract Review` and `.omo/notepads/<plan>/contract-review.md` (or equivalent named file under the per-plan notepad dir).
- [ ] Every forbidden transition and uncompiled requirement from step 2 has a counterexample in step 3, or is flagged `unaddressed`.
- [ ] Every L3 selection in step 4 lists all six required fields.
- [ ] Loading the skill did not install or run any verifier; every chosen tool went through step 5's order.
- [ ] Step 5's resource inspection covered CPU / memory / disk / permissions / duration / concurrency / test count / state-space / timeout / cleanup.
- [ ] Step 6 fired only after every reasonable alternative (project-local dep / virtual env / ephemeral env / project-scoped container) is recorded as unavailable with the reason.
- [ ] Traffic light and the 11-field feasibility/consequence assessment are documented in the contract-review artifact before any install question is asked.
- [ ] Approval binds the exact tool/version/source/commands/privilege/effects/resource+execution bounds/cleanup/rollback/residual risk; broad prior consent is rejected.
- [ ] If actual installation or runtime impact exceeded the approved boundary, the skill stopped, reported the deviation, and did not continue verification.

## omo Integration

Soft-routed via [`using-meisijiya-skills`](~/.agents/skills/using-meisijiya-skills/SKILL.md) — the dispatcher now contains the post-attested-Spec open-world risk row and loads this optional extra only when installed; its absence does not block the core flow. No dedicated plugin hook is required: the existing `meisijiya-skills.js` bootstrap reads that dispatcher dynamically. Deep audits of candidate verification backends route through OMO `oracle` agent (read-only high-IQ, gpt-5.6-sol xhigh); bounded empirical runs route through `sisyphus-junior` (focused executor, claude-sonnet-4-6) — note that OMO's Ultimate Edition has no `general` agent; `sisyphus-junior` is the standard delegate-target for empirical/QA work. Record risks in `.omo/notepads/<plan-name>/decisions.md` (append-only via `notepad-write-guard` hook) and `.omo/start-work/ledger.jsonl`, and require consent before `/start-work`.
