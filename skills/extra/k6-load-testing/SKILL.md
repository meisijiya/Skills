---
name: k6-load-testing
description: "Performance acceptance gate before any production rollout. Designs and runs k6 load tests (smoke / load / stress / spike / soak) for HTTP, gRPC, and WebSocket services; captures latency-percentile + error-budget thresholds; produces PASS/FAIL evidence with concrete regression diagnosis. Use before merging a perf-sensitive change, when establishing a release baseline, when adding a new endpoint and you need to prove it holds under advertised load, when capacity-planning a deploy, or when an existing endpoint's latency-percentile regressed and you need to find the breaking point. Distinct from performance-optimization (post-hoc bottleneck hunting): this skill gates a deploy on concrete load-test evidence."
allowed-tools: "Read Bash Glob WebFetch"
---

# k6-load-testing

## Overview

`performance-optimization` is a **post-hoc** skill — "the prod p99 is 2× last week, hunt the bottleneck". This skill is the **pre-deploy acceptance gate**: "we just rewrote the auth middleware; prove it holds 1k req/s at p95 < 200ms with <0.1% errors before merging". The two are paired front-back: load-test sets the bar; optimization tells you how to clear it.

This skill uses [k6](https://k6.io/) (Grafana's load-testing tool) as the default runner because it has a single-binary deploy, JS scenario syntax, and rich threshold/threshold-breach output. **The runner is interchangeable** — the methodology (smoke / load / stress / spike / soak, plus percentile + error-budget thresholds) is the actual content. Adapt the runner if your stack requires Locust, Gatling, Vegeta, or k8s-based tools; the test categories below apply unchanged.

**OMO integration**: `analyze` mode for post-run bottleneck diagnosis (p99 tails, GC pressure, connection-pool exhaustion); `oracle` agent for "is this regression expected given the change set?" judgment; `websearch` MCP for k6 syntax + threshold pattern lookup.

## When to Use

**Use when:**

- About to merge a change that touches a hot path (auth, API gateway, payment, search, anything user-blocking)
- Establishing a baseline for a service that has never had explicit performance targets
- Adding a new endpoint or surface and you need to prove it can handle advertised load
- Capacity-planning a deploy (you expect traffic to grow 3× next quarter; what's the headroom?)
- Existing endpoint's latency-percentile regressed (e.g. p99 jumped 200ms) and you need to find the breaking-point load
- A new region / new instance-type / new service mesh is being rolled out and you need to confirm it matches the baseline's curve
- Building a CI perf-gate (this skill's output template is the input your CI gate consumes)

**NOT for:** (scenario description — let description match decide)

- Post-hoc production-bottleneck investigation (service is slow *now*) → [`performance-optimization`](~/.agents/skills/performance-optimization/SKILL.md)
- Frontend Core Web Vitals (LCP / FID / CLS) → OMO built-in `frontend` skill (frontend perf is browser-side, different runner)
- Load test of an external third-party service whose rate limit you'd violate → coordinate first; consider also [`pre-ship-gate`](~/.agents/skills/pre-ship-gate/SKILL.md)
- Capacity recommendation for production traffic that already exists → use real RUM / APM data, not synthetic load
- Unit-test style "test this function under 10k iterations" → that's `test-driven-development` territory

## Process

### 1. Define the target

Before writing the k6 script, answer these 4 questions — they drive every threshold:

| Question | Example answer | Drives |
|---|---|---|
| **Throughput target** | 1000 RPS sustained, peak 1500 | `rps` / `vus` parameters |
| **Latency percentile + budget** | p95 < 200ms, p99 < 500ms | `thresholds` in the script |
| **Error budget** | <0.1% errors (HTTP 5xx), <1% non-2xx | `thresholds` |
| **Steady-state duration** | 5 minutes sustained at peak | `duration` parameter |

Anti-patterns:

- "Make the test fast, let's just hammer it for 30s" — under-samples percentile distribution; p99 from 30s is meaningless
- "We'll tune thresholds after we see what fails" — defeats the gate; the threshold IS the gate
- "1M concurrent users" — without thinking about the test-side load-generator capacity; k6 has per-instance limits

### 2. Pick the test category (5 canonical types)

| Type | Purpose | Pattern |
|---|---|---|
| **Smoke** | Verify the system runs at all | 1-2 VUs, 30s, low RPS |
| **Load** | Verify SLA at expected peak | Target RPS, 5-10 min sustained |
| **Stress** | Find the breaking point | Step up RPS past expected peak, observe where p99 explodes |
| **Spike** | Verify graceful degradation | Sudden burst (5× peak) for 30s, observe behaviour + recovery |
| **Soak** | Catch memory leaks / connection-pool drift | Target RPS, 1-4 hours |

For a pre-deploy acceptance gate, **smoke + load** is the minimum. Stress and spike are for capacity-planning runs. Soak is for catching leaks pre-merge when the change touches persistent state (DB connection, file handle, cache size).

### 3. Write the k6 script

Minimum viable k6 script:

```js
import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate, Trend } from 'k6/metrics';

const errorRate = new Rate('errors');
const p95 = new Trend('latency_p95', true);

export const options = {
  stages: [
    { duration: '30s', target: 50 },    // ramp-up
    { duration: '5m',  target: 1000 },  // sustained peak
    { duration: '30s', target: 0 },     // ramp-down
  ],
  thresholds: {
    'http_req_duration': ['p(95)<200', 'p(99)<500'],
    'http_req_failed':   ['rate<0.001'],
    'errors':            ['rate<0.001'],
  },
};

export default function () {
  const res = http.get('https://api.example.com/v1/endpoint');
  errorRate.add(res.status !== 200);
  p95.add(res.timings.duration);
  check(res, {
    'status is 200': (r) => r.status === 200,
  });
  sleep(1);
}
```

Adaptations per surface:

- **gRPC**: `k6.net.Connect()` + `client.invoke()`. Add `grpc_req_duration` threshold.
- **WebSocket**: `ws.connect()`; track `ws_session_duration` + `ws_msgs_received`.
- **Auth'd endpoints**: read token from `__ENV.TOKEN`; never inline secrets in the script.
- **Multi-step flows** (login → fetch → submit): chain stages in `default`; each step a separate request with its own check.

### 4. Run the test

```bash
# Local quick run
k6 run --vus 10 --duration 30s script.js

# CI run with results output
k6 run --out json=test-results.json script.js

# Distributed run for >1k RPS
# 1. Start the k6 cloud or private grid
# 2. Run with --out cloud
k6 cloud script.js
```

Capture:

- `k6 run --summary-export=summary.json` (always export summary)
- `--out json=results.json` for time-series detail
- Exit code: k6 returns non-zero if any threshold fails — **CI must fail the build on threshold breach**

### 5. Read the output

Threshold breach is the answer. k6 prints which threshold failed:

```
✗ http_req_duration............: p(95)=420ms (threshold: p(95)<200ms)
✓ http_req_failed..............: 0.04%   (threshold: rate<0.001)
```

If only one threshold breached, the diagnosis narrows:

- `p(95)` high + `p(99)` much higher → long tail (cache miss / DB slow query / GC pause)
- `p(50)` high + `p(95)` proportional → uniformly slow (CPU-bound / connection-pool exhausted)
- `http_req_failed` rate high + `http_req_duration` ok → error returned fast (auth / rate limit)
- `http_req_duration` ok + `http_req_waiting` high → backend slow (DB, downstream)
- `http_req_duration` ok + `http_req_connecting` high → connection establishment slow

For deeper diagnosis, hand off to [`performance-optimization`](~/.agents/skills/performance-optimization/SKILL.md) with the k6 summary as input.

### 6. Output as gate decision

A test run produces a **PASS / FAIL** with the threshold summary:

```markdown
## Load-test gate — <feature / endpoint>

- Test: k6 script: <path>
- Target: <throughput> RPS sustained, p95 < <Xms>, <error_rate>%
- Run duration: <real time>
- Result: **PASS** | **FAIL**
- Summary:
  - p(50): <X>ms | p(95): <X>ms | p(99): <X>ms
  - throughput achieved: <X> RPS
  - error rate: <X>%
  - iteration rate: <X> it/s
- Threshold breaches: <list, or "none">
- Comparison vs baseline: <+X% / -X% / unchanged>
- Recommendation: <merge | hold | fail>

<k6 stdout summary attached>
```

If PASS: this becomes the merge evidence; record the summary.json as an artifact.
If FAIL: do not merge; diagnose via performance-optimization, fix, re-test.

## Common Rationalizations

| Excuse | Why it's wrong |
|---|---|
| "It worked in dev with 5 users" | Dev traffic profile is meaningless; the question is "does it hold at advertised load", not "does it work at all" |
| "We have load tests in CI from 2022" | Test suite age has nothing to do with whether it matches current SLA targets. Re-validate. |
| "It's just a small change, doesn't need a perf gate" | Small changes to hot paths (auth, cache, ORM call) can shift the perf curve by 10×. The gate is per-change-class, not per-LOC. |
| "We can't reproduce the production traffic profile" | Even an imperfect synthetic load beats no load. Use the closest profile you have; flag the gap explicitly in the report. |
| "k6 says it failed but it's just a hot cache, try again" | If the test is flaky, the system has a flake; fix the system, don't re-run. |
| "We're at p95=200ms which is exactly the threshold, ship it" | On the threshold = no margin. Target should be 30-50% under the threshold for headroom; otherwise a normal workload variance pushes you over. |
| "Stress test broke prod last time, let's skip it" | Stress tests are supposed to find the breaking point; that's the value. The fix is to run them on a load-test environment, not to skip them. |
| "Soak test would take 4 hours, blocking the deploy" | Soak tests run in background on a dedicated runner; the deploy gate uses smoke + load (5-10 min). Soak is for capacity-planning, not the merge gate. |

## Red Flags

A k6 load test is going wrong if:

- Script has no `thresholds` block — the test "succeeds" without proving anything
- Test duration is <1 min — under-samples the percentile distribution
- One VU — cannot generate meaningful RPS or surface connection-pool issues
- Threshold is "p95 < 1000ms" with no error budget — anything below 1s is "fine" without rationale
- Test-side bottleneck (k6 instance maxes CPU before target RPS) — your measurement is of k6, not the system
- Auth token inlined in script instead of `__ENV` — leaked via git
- Ignoring the exit code — k6 returns non-zero on breach but Jenkins often doesn't fail on non-zero
- Comparing runs across different hardware / network paths without noting the env diff
- "Tests passed locally, will probably pass in prod" — local usually means your laptop, prod is real traffic

## Verification

Before claiming the perf gate is set, produce evidence:

- [ ] §1 Target defined: throughput, latency percentile + budget, error budget, steady-state duration
- [ ] §2 Test category picked (smoke + load minimum; stress / spike / soak by use case)
- [ ] §3 k6 script has explicit `thresholds` block — not "tune later"
- [ ] §4 Test run exported summary.json + json results
- [ ] §5 Output read with concrete percentile numbers, not "looks OK"
- [ ] §6 PASS/FAIL gate decision written with the exact thresholds
- [ ] Auth tokens / secrets read from `__ENV`, never inlined in the script
- [ ] CI fails the build on non-zero exit (verified by intentionally introducing a threshold breach and confirming the build fails)
- [ ] summary.json archived as the release artifact for this change
- [ ] If PASS, the result is committed (or referenced) in the merge PR's evidence chain

**Acceptance criterion**: A second reviewer can rerun the k6 script with `summary.json` exported, see the same PASS/FAIL decision, and confirm the threshold table matches the gate requirement.

## Anti-patterns in k6 script writing (call out and fix)

| Anti-pattern | Fix |
|---|---|
| `http.batch()` for sequential calls in the same iteration | Use sequential `http.get()` — batch is for parallel, not chained |
| `check()` without thresholds | `check()` only logs; use `Trend` / `Counter` + `thresholds` for gate enforcement |
| `sleep(Math.random())` to simulate "user think time" | Use `sleep()` from `k6` (not from JS); it pauses the VU properly |
| Hard-coded URL in script | Read from `__ENV.TARGET_URL` so the same script runs in staging + prod |
| Sharing one client across VUs | `http.get()` already pools; don't manually manage connections |
| Closing connection per request | Don't disable keep-alive unless you're measuring handshake cost; keep-alive is the default and matches real clients |
