---
name: pre-ship-gate
description: "Guards against 'deploy exit 0 ≠ actually running'. Read-only pre-deploy audit + post-deploy smoke verification for migrations, feature flags, CDN/cache invalidation, canary/progressive delivery, env vars, release pointer, and shadow traffic. Use before any production rollout, after a deploy returned exit 0 but you suspect silent failure, when a canary is stuck at 0%, or to confirm a release is live vs cached. Each finding ships with concrete evidence commands plus expected output."
allowed-tools: "Read Bash WebFetch"
---

# pre-ship-gate

## Overview

CI says the deploy job returned exit 0. The pipeline succeeded. **But the rollback rate is 3× higher than the green pipeline would suggest** — because "exit 0" only proves the deploy artifact was written, not that:

- migrations were actually applied (vs skipped silently)
- the new release is the one serving requests (vs the old version still in CDN / load balancer)
- feature flags flipped at the right time (not 30 minutes late due to stale KV)
- env vars survived the rollout (not silently defaulted to a fallback)
- canary is making progress (vs stuck at 0% due to a label selector mismatch)
- shadow traffic is being mirrored correctly (not silently dropped)

This skill combines **pre-deploy read-only audit** (catch silent misconfig before rollout) and **post-deploy smoke verification** (catch the same class of issues in the first 5 minutes after rollout). Source material draws on the antigravity `pre-release-review` + `pre-ship-gate` pair, merged into one workflow.

**Distinction from `verification-before-completion`**: `verification-before-completion` is the per-PR code-change gate (Iron Law). `pre-ship-gate` is the per-rollout runtime gate — it runs *after* the green CI, against the deployed artifact, against the live system state.

## When to Use

**Use when:**

- About to roll out a release (deploy tag, build promotion, container rollout)
- Just deployed and `kubectl rollout status`, `flyctl releases`, Vercel deployment status all say "ready" but you want evidence the new code is actually serving
- Canary / progressive-delivery rollout is stuck at 0% or moving slowly
- Migrations are part of the deploy and you need to confirm they ran (not just queued)
- Feature flags should have flipped but telemetry says users still see the old UI
- CDN / edge cache might be serving the old bundle (cache-control headers wrong, new immutable path not honored)
- Env vars or secrets were added/changed in this deploy and you want to confirm the new values propagate
- You want a pre-deploy read-only review of migrations / config / secrets / shadow traffic to catch the silent-misconfig class before rollout

**NOT for:** (scenario description — let description match decide)

- CI green-/red-/purple-checking of the code itself → [`verification-before-completion`](~/.agents/skills/verification-before-completion/SKILL.md) (Iron Law)
- Application-layer source code review → [`security-and-hardening`](~/.agents/skills/security-and-hardening/SKILL.md)
- GHA workflow file audit → [`gha-security-review`](~/.agents/skills/gha-security-review/SKILL.md)
- Supply-chain / IaC / dependency scan → [`security-devsecops`](~/.agents/skills/security-devsecops/SKILL.md)
- Post-incident (silent failure already happening to users) → [`security-incident-response`](~/.agents/skills/security-incident-response/SKILL.md) or [`observability-and-instrumentation`](~/.agents/skills/observability-and-instrumentation/SKILL.md)
- Load-test / performance verification before deploy → only run this skill AFTER baseline metrics are established; see `performance-optimization`

## Process

### Phase A — Pre-deploy read-only audit (do this BEFORE clicking release)

For each release, capture the diff between the previous release and the candidate:

1. **Migrations**
   - List migration jobs in the deploy manifest: `kubectl get jobs -n <ns> -l app.kubernetes.io/component=migrate --sort-by=.metadata.creationTimestamp` (or Helm/Kustomize/Terraform equivalent)
   - For each migration: read its `command` and confirm it has an idempotency check (`IF NOT EXISTS`, hash of applied schema)
   - **Check**: did the previous release's migration run? (compare timestamps of the `migrate` CronJob / Jobs to the deploy timestamp). If skipped, the new release's migration will fail or, worse, silently no-op
   - **Evidence**: `kubectl logs -n <ns> job/<previous-migration>` last 50 lines should show "migrations applied" or similar success line

2. **Config + env vars**
   - diff `deployment.yaml` env between previous and candidate — note added/changed/removed
   - For each new env var: confirm a default exists or the deploy hard-fails; a silent fallback to empty/zero/`undefined` is exactly the class of bug this skill catches
   - **Evidence**: `kubectl get deploy/<app> -o yaml | yq '.spec.template.spec.containers[0].env'` should reflect the candidate env (and not the previous one)

3. **Feature flags**
   - List all flag toggles this release expects (read release notes / PR description / spec)
   - For each: confirm the flag service has the rollout state ready (not in a stale KV, not reverted mid-deploy by another team)
   - **Evidence**: `curl -s https://flags.example.com/api/v1/flags/<name>` should return the expected `state`, `updated_at` close to deploy time, `rollout_percent` not stuck

4. **CDN / edge cache**
   - If the release changes JS bundles, CSS, or any `immutable` content: confirm the new asset path differs (`app.<hash>.js` not `app.js`); otherwise cache will serve old bytes
   - **Evidence**: `curl -sI https://<cdn>/<new-bundle-path>` should return 200 with `cache-control: public, max-age=31536000, immutable`
   - For HTML: confirm `cache-control: no-cache` or short-TTL so the next user request revalidates

5. **Release pointer / traffic shift**
   - Identify the load-balancer / ingress rule that points to this service: capture a copy of the current pointer before deploy
   - **Evidence**: save the current `selector` / `weight` / `host` to a temp file so you can confirm post-deploy that the pointer flipped (and not just rotated on a side-effect)

6. **Shadow traffic / dark launch**
   - If shadow-mirroring is configured: confirm the mirror target is the new version, not a dead sink, and traffic IS being copied (`mirror_percent` not 0, mirror service is healthy)
   - **Evidence**: `<mirror-target>.requests_total` counter should increase during a smoke load

**Output of Phase A**: a numbered list of these 6 categories with status (✅ ready / ⚠ watch / 🚫 block). Each `🚫 block` MUST include a concrete fix before proceeding to Phase B.

### Phase B — Post-deploy smoke verification (run within 5 minutes of release)

For each item in the deploy manifest, run a smoke check that asserts the deployed artifact is actually serving:

1. **Canary health**
   - `kubectl get pods -n <ns> -l app=<app>,release=<new> --field-selector=status.phase=Running` — pods Ready
   - `kubectl logs -n <ns> -l app=<app>,release=<new> --tail=100 --since=2m | grep -E "started|listening|ready"` — the app's own startup banner
   - Avoid relying on pod-phase alone; many apps crash in the constructor without setting phase=CrashLoopBackOff until the second probe failure

2. **Release pointer flipped (and is staying flipped)**
   - `kubectl get svc/<service> -o yaml | yq '.spec.selector'` — verify label matches the NEW release
   - `kubectl get pods -n <ns> -l release=<new> --no-headers | wc -l` — the new release has actual pods
   - Sample a load-balancer-routed request: `curl -s -H "Host: <route>" http://<lb-endpoint>/health` returns 200 AND the response includes a marker unique to the new build (e.g. `X-Build-Hash: <new-sha>`)

3. **Migrations applied (if applicable)**
   - `kubectl logs -n <ns> -l app.kubernetes.io/component=migrate --tail=100` — tail shows success line
   - Database-side: `SELECT MAX(version) FROM schema_migrations` matches the candidate's `head` migration version

4. **Feature-flag state**
   - For each flag toggled: `curl -s https://flags.example.com/api/v1/flags/<name>` returns the expected `state`
   - Compare against the state in Phase A — if it differs (someone rolled back mid-deploy), this is a Phase B finding

5. **CDN serving the new bundle**
   - `curl -sI https://<cdn>/<new-bundle-path>` returns 200 + `immutable`
   - For HTML pages: response should reflect new release (look for new content SHA / release tag)
   - **If CDN is serving stale content**: bust cache via `curl -X PURGE https://<cdn>/<path>` or trigger revalidation; do not assume the next-deploy will fix

6. **Env var propagation**
   - For each env var changed: `kubectl exec -n <ns> deploy/<app> -- env | grep <KEY>` returns the expected value (NOT a default fallback)
   - **Common silent failure**: a ConfigMap was updated, but the Deployment was not annotated to re-roll (`kubectl rollout restart` was forgotten, env stays at the old value)

7. **Shadow traffic flow (if applicable)**
   - `<mirror-target>.requests_total` delta during smoke test → confirm shadow request count matches the expected mirror_percent of the live request count

**Output of Phase B**: per-category evidence (one line each). Any "no / partial / wrong" answer is a 🚫 finding — list concrete remediation.

### Phase C — Failure hold (after Phase B finds an issue)

If any Phase B check fails:

1. **Don't auto-rollback blindly** — confirm scope first (canary %, blast radius)
2. If canary: flip `release=<old>` selector / pause progressive delivery; new pods stay drain
3. If fully rolled: trigger explicit rollback (`kubectl rollout undo`, `helm rollback`, Vercel "promote previous", fly `releases rollback v<N-1>`)
4. Capture which Phase B check caught it — add to Phase A checklist for next release

## Common Rationalizations

| Excuse | Why it's wrong |
|---|---|
| "CI green means safe" | CI confirms `kubectl apply` succeeded; not that the new code serves. The most expensive outages of the last 5 years all had green pipelines. |
| "We have Prometheus alerts; SRE will catch it" | Alerts catch sustained outages 1-15 minutes after user impact. This skill aims for zero user impact, no SRE escalation. |
| "It's a small change, no migration" | Non-migration changes still have: new env var, new feature flag, new CDN path, canary weight shift. The 6 categories catch all of them. |
| "We deploy 30 times a day, can't audit each" | The Phase A checklist for a no-migration-release is ~5 minutes; failures caught in Phase A save the 30-90 minute rollback-fail-forward-loop. |
| "Canary at 0% is fine, will ramp overnight" | Canary at 0% after 1 hour means: bad metrics are filtering, label selector is wrong, or the new release's metrics endpoint isn't reporting. Don't assume sleep-then-proceed. |
| "Feature flags auto-rollback; don't worry" | Flag services cache; a deploy during a flag rollback can land in mid-state where each request gets a different version. Confirm post-deploy. |
| "Just check pod phase = Running and trust it" | Pod phase doesn't surface startup crashes that don't trip the liveness probe until the second failure. Read the app's own startup banner. |
| "Smoke test through load balancer isn't realistic" | It's exactly the path users take. Post at: `curl -sv --resolve <host>:<lb-ip> https://<route>/` if needed. The point is to bypass any local cache. |

## Red Flags

A pre-ship gate is going wrong if:

- Phase A is skipped because "we always deploy this way" → run it anyway, even if all 6 categories show green; **the act of running is the evidence**
- Phase B uses only `kubectl rollout status` and considers deployment "done" on "Complete" → that flag means the ReplicaSet rolled; it does not mean requests reach the new pods
- "Build hash marker" check absent → you have no way to tell which build is serving; add a marker in the deploy template (commit SHA in footer / `X-Build-Hash` header) before this skill is useful for your stack
- Migration verification reads only the deploy job logs, not the database state → migrations can succeed in logs but not commit (e.g., distributed-tx issue); cross-check with `SELECT MAX(version)`
- Phase B findings are listed without remediation command → call out `kubectl rollout undo` / `helm rollback` / `vercel rollback --to <id>` per stack
- You're "too tired to do Phase A" → still do it; the audit is automated in your deployment template anyway, the cost is reading it

## Verification

Before claiming the rollout is healthy, produce evidence:

- [ ] Phase A: all 6 categories captured with status + evidence command
- [ ] Phase A `🚫 block` items — none, OR remediation applied and re-verified
- [ ] Phase B run within 5 min of release
- [ ] Phase B "release pointer flipped" — confirmed via LB-routed curl with `X-Build-Hash` matching candidate
- [ ] Phase B "migrations applied" — confirmed in DB, not just job logs
- [ ] Phase B "feature flags" — state matches Phase A snapshot
- [ ] Phase B "CDN" — new bundle path returns 200 + `immutable`; HTML response reflects new release
- [ ] Phase B "env vars" — live exec shows new value, not default fallback
- [ ] Phase C: any failure captured with stack-specific rollback command (e.g. `kubectl rollout undo`, `helm rollback`, `vercel rollback`)
- [ ] Saved copy of Phase A evidence-captured URLs/commands for the post-deploy audit trail

**Acceptance criterion**: A second reviewer should be able to reproduce the Phase B checks within 5 minutes using only the captured evidence commands, and reach the same conclusion about the rollout's health.
