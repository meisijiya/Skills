---
name: closed-loop-delivery
description: "Closes the implementation-to-runtime loop so a task is not 'done' on diff-size but on evidence running in production without silent failure. Use when an implementation feels finished and the natural next move is 'merge and call it done', when a deploy passed CI but post-incident evidence suggests users saw the bug, or when establishing / auditing a team's Definition of Done. Complements incremental-implementation (slice dispatch) and verification-before-completion (PR-level Iron Law) by extending evidence past deploy into runtime."
allowed-tools: "Read Bash Glob WebFetch"
---

# closed-loop-delivery

## Overview

Incremental implementation dispatches slices; verification-before-completion gates the PR. Both stop at merge. What happens between merge and user-visible "the bug is gone" is a gap — the window where CI is green, the deploy returns 0, the diff is N+1, and a user *still* hits the bug because:

- the new code path is reached by 0.4% of traffic (canary hasn't ramped)
- a feature flag is set to the OLD variant server-side
- the new release is on staging, prod is on the old release
- the database migration ran in dev but not prod
- the new behavior requires a config the deploy forgot to set

Closed-loop-delivery enforces evidence through **five gates**: implemented → reviewed → deployed → healthy-at-runtime → reachable-by-users. A task is not done until all five hold.

This pairs with the existing skills:

| Skill | Stops at | closed-loop-delivery extends to |
|---|---|---|
| `incremental-implementation` | Slice merged | All 5 gates green |
| `verification-before-completion` | PR iron law (in-session + OMO review-work) | Post-deploy runtime evidence |
| `pre-ship-gate` | Phase A + Phase B (deploy-time evidence) | Phase C runtime evidence (24h+ post-deploy) |

The difference from `pre-ship-gate`: pre-ship-gate is read-only evidence within 5 min of release. This skill is 24h+ runtime evidence + user-reachability evidence (the sort that only monitoring data + flag-state + revert decisions can answer).

## When to Use

**Use when:**

- About to merge a slice / feature / change and the natural impulse is "diff is N+1, ship it"
- After a deploy that had green CI / Phase-A+B pass but user reports the bug is still present
- Establishing or auditing a team's Definition of Done (DoD) — codifying "done means running, not merged"
- Designing a release-process that includes post-deploy evidence as a hard gate (for high-risk or high-visibility changes)
- Capstone before declaring a release "shipped" — closes the loop the deploy started

**NOT for:** (scenario description — let description match decide)

- PR-level evidence gate (in-session + OMO review-work) → [`verification-before-completion`](~/.agents/skills/verification-before-completion/SKILL.md)
- Within-deploy-time evidence (< 5 min post-deploy) → [`pre-ship-gate`](~/.agents/skills/pre-ship-gate/SKILL.md)
- Vertical-slicing dispatch + per-slice review → [`incremental-implementation`](~/.agents/skills/incremental-implementation/SKILL.md) + [`slice-review`](~/.agents/skills/slice-review/SKILL.md)
- Routine clean-up / chore PRs (no user-observable behavior change) — DoD = merge is fine; only apply to changes that affect user-visible behavior

## Process

### 1. The five gates

For each change affecting user-visible behavior, gate the "done" claim on five independent checks. A green PR is **not** sufficient.

| # | Gate | Check | Tool / source |
|---|---|---|---|
| 1 | **Implemented** | Diff + tests + reviews on the change | PR + slice review |
| 2 | **Reviewed** | code review PASS at PR + whole-branch stage | OMO `review-work` |
| 3 | **Deployed** | Deploy returned 0 + Phase A + Phase B (pre-ship-gate) | k8s / fly / vercel status |
| 4 | **Healthy at runtime** | 24h+ post-deploy: error rate unchanged, p95 unchanged, no new alerts firing | observability platform |
| 5 | **Reachable by users** | The specific behavior the change is supposed to enable is reachable by 100% of intended traffic (not 0.4% canary, not 50% feature-flag) | feature-flag state + actual user journey |

If any gate is red, **the task is not done**. The "Done" claim is gated on all five, not on the diff size.

### 2. Per-gate evidence

#### Gate 1 — Implemented (PR-level, owned by incremental-implementation + verification-before-completion)

- Diff exists in the target branch
- Tests added / updated for new behavior paths
- Slice review verdict: spec compliance + code quality
- Verification-before-completion Iron Law: in-session self-check + Stage-2 review-work fresh-context audit
- AI-code-blindspots scanned for AI-coded diffs (if applicable)
- gha-security-review passed on workflow-file changes (if applicable)
- security-and-hardening passed on trust-boundary code (if applicable)

**Evidence artifact**: PR URL + commit SHA + check status IDs

#### Gate 2 — Reviewed (PR-level, owned by OMO `review-work` skill)

- review-work's 5 lanes (goal/constraint verification, code quality, security, hands-on QA, context mining) — all returned PASS or remediation applied
- Any Lane that returns BLOCKED re-dispatched fixers; the original review happens again after fix
- For multi-slice: slice-review's per-slice verdicts also PASS

**Evidence artifact**: review-work summary + lane pass/fail

#### Gate 3 — Deployed (deploy-time, owned by pre-ship-gate)

- Deploy job returned 0
- pre-ship-gate Phase A: migrations + config + flags + CDN + release pointer + shadow all green or ⚠ watch with rationale
- pre-ship-gate Phase B: canary healthy, release pointer flipped with build-hash marker, migrations in DB, flags flipped, CDN serving, env vars propagated

**Evidence artifact**: pre-ship-gate output + deploy-job status

#### Gate 4 — Healthy at runtime (24h+ post-deploy, NEW gate not in any other skill)

The only gate that's not a pre-existing skill's job. This is the gap this skill closes.

Configure monitoring query / dashboard for:

- **Error rate** by service + endpoint — must be within ±20% of the 7-day pre-deploy baseline (a small increase is normal during cache warmup; large increase = problem)
- **Latency percentile** p95 + p99 — must be within ±10% of pre-deploy baseline
- **Saturation metrics** (CPU / memory / connection count / queue depth) — must NOT trend upward over 24h
- **New alerts** fired against the deploy — count + names; non-zero is a problem until explained

Output: pass/fail for each metric with the comparison numbers.

If any metric fails: investigate root cause via `observability-and-instrumentation` + `performance-optimization`. **Don't claim done**; defer claim until metric is back in baseline or root cause is identified as unrelated.

#### Gate 5 — Reachable by users (NEW gate)

Distinguish "the deploy succeeded" from "the users are seeing the change":

- **Feature flag state** must be 100% (or the planned rollout %), not stuck at canary percentage
- **Cache invalidation** must have propagated (CDN purge + Redis cache flush) — first user after invalidation sees new behavior; do NOT assume "deploy back" implies "users forward"
- **DNS / load-balancer routing**: if using blue/green, verify the green pool is taking 100% of traffic
- **Specific behavior test from a real-client path**: open a fresh session, do the action the change enables, observe the new behavior

If the reachable-by-users gate fails: **the user is paying for a deploy they cannot see the benefits of**. Diagnose:

- Flag service: rollout_percent, updated_at, cache TTL
- CDN: cache purge execution, edge cache TTL
- DNS / LB: routing weights, pool health
- Application: feature flag evaluation, cache reads

### 3. Output as the "Done" claim evidence

A task is "done" when:

```markdown
## Closed-loop evidence — <task / feature / slice>

**Task**: <one-line description>
**Branch / PR**: <link>
**Release**: <version / tag>
**Date of done-claim**: <today>

### Gate 1: Implemented — PASS
- [PR URL]
- Tests: <+X / -Y>
- Slice-review verdict: PASS (spec compliance + code quality)
- verification-before-completion: PASS (Iron Law, 2 stages)
- ai-code-blindspots: PASS / N/A
- gha-security-review: PASS / N/A
- security-and-hardening: PASS / N/A

### Gate 2: Reviewed — PASS
- review-work lanes: 5/5 PASS
- slice-review: N/A (single slice) | all slices PASS (multi-slice)

### Gate 3: Deployed — PASS
- Deploy job: <id> returned exit 0
- pre-ship-gate Phase A: 6/6 categories green
- pre-ship-gate Phase B: 6/6 categories green with build-hash marker verified

### Gate 4: Healthy at runtime — PASS
- 24h post-deploy monitoring (window: 2026-XX-XX to 2026-XX-XX):
  - Error rate: <X>% (baseline: <Y>%, delta: <+/-Z>%, threshold: ±20%, status: PASS)
  - p95 latency: <X>ms (baseline: <Y>ms, delta: <+/-Z>%, threshold: ±10%, status: PASS)
  - Saturation (CPU/mem/conn): <X> (baseline: <Y>, status: PASS)
  - New alerts: 0 (status: PASS)
  - Saturation trend: <X> (status: PASS)

### Gate 5: Reachable by users — PASS
- Feature flag state: <X> at <percent>% (status: PASS)
- Cache invalidation: completed at <timestamp> (status: PASS)
- Routing: green pool at 100% (status: PASS)
- Manual user journey test: <description + observed behavior>

**All 5 gates PASS. Task done.**

Signed: <agent name + timestamp>
```

If any gate is FAIL: do NOT mark done. Explicit re-route:

- Gate 4 fail → diagnose via `observability-and-instrumentation` + `performance-optimization`; **defer the done claim**
- Gate 5 fail → manual intervention: flag flip / cache purge / LB weight; **defer the done claim** until reachable

### 4. Anti-patterns

| Anti-pattern | Consequence |
|---|---|
| "Diff is large, must be done" | Diff size ≠ runtime evidence |
| "CI green, ship it" | CI confirms artifact write, not users-reaching-new-behavior |
| "Canary at 5% means real test in prod" | 5% of N=10M = 500k users see an unverified change; this is not "real test", this is rolling out a regression |
| "If monitoring doesn't yell, we're fine" | Monitoring detects symptoms; it doesn't catch user-reachability failures (e.g. flag stuck server-side) |
| "Just trust feature flag to flip automatically" | Flag service cached; the new variant may not match what observability reports |
| "Monitor for a week then call it done" | Closed-loop is per-deploy, not per-quarter; one-week monitoring is a different concern (post-release regression) |
| "Skip Gate 5 for internal tools" | Internal users count; their escape is your bug |

## Common Rationalizations

| Excuse | Why it's wrong |
|---|---|
| "Phase B said it's healthy" | Phase B is 5-min post-deploy. Gate 4 covers 24h+ baseline comparison. Different windows, different evidence. |
| "No user complained in 24h" | Silence is not signal; 0.4% canary may mean no users reached the new path; bug is invisible to support channels. |
| "Monitoring is well-tuned; it'll catch anything" | Monitoring catches *symptoms*; Gate 5 catches *reachability*; both are needed. |
| "We've been shipping without this for years" | "Done = merged" is the historic norm; "done = running safely" is the higher bar. The historic norm lets bugs through (sometimes literally for years). |
| "Doing all 5 gates slows us down" | Doing 4 of 5 gates and skipping 1 has been the historic practice and has produced a non-trivial fraction of incidents. Net effect of the full 5 is *faster* recovery, not slower delivery. |
| "Gate 4 can be done in retrospect if a bug surfaces" | At that point it's an incident, not done. The loop closed because of failure, not success. |
| "Not all changes reach users (libraries, internal tools)" | Library change reaches users via dependents; internal tools' users are internal staff, still counts. |
| "Skip if change is small" | Small change to a hot path can shift the system by an order of magnitude. Apply the gates; adjust the monitoring thresholds for scope. |
| "Gate 5 takes manual user testing — too expensive" | A 60-second smoke test is enough to verify reachability; full user-journey testing is overkill. The gate is "the user can see it", not "the user signed off". |

## Red Flags

Closed-loop delivery is going wrong if:

- Task is reported as "done" within 5 min of merge (Gate 4 + 5 impossible to satisfy this fast)
- Only Gate 1 (Implemented) is checked before done-claim
- Gate 4 baseline is "yesterday's snapshot" (a deployment artifact, not the rolling 7-day baseline)
- Gate 5 has no real test — just "the deploy is done, it's reachable"
- Gate 4 / 5 are skipped because "no time"
- "Done" claim references CI check names instead of monitoring metric snapshots
- The same gate (Gate 4 / 5) consistently red — a sign the gate is real and the team is shipping bad changes; investigate, don't drop the gate

## Verification

Before claiming "task done", produce evidence:

- [ ] Gate 1 — PR merged + tests + slice review + verification-before-completion + relevant skill PASS
- [ ] Gate 2 — review-work 5/5 lanes PASS; slice-review (if multi-slice) PASS
- [ ] Gate 3 — pre-ship-gate Phase A + B all green
- [ ] Gate 4 — 24h+ post-deploy monitoring comparison vs 7-day baseline; all 4 metrics within threshold; 0 unexplained alerts
- [ ] Gate 5 — feature flag state confirmed; cache invalidation confirmed; routing weights confirmed; manual user journey test confirms new behavior
- [ ] Output document saved (closed-loop-evidence.md) per task
- [ ] The 5-gate evidence is sufficient for someone else to confirm the done claim by re-reading the artifact (without needing the implementer's memory)

**Acceptance criterion**: A second reviewer reading the closed-loop-evidence.md can confirm "yes, the task is done" without any follow-up questions to the implementer.
