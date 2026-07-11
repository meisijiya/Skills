---
name: performance-optimization
description: "Measure-first performance optimization with Core Web Vitals targets and profiling workflows. Use when performance requirements exist, when regressions are suspected, or when user-perceived latency is high."
allowed-tools: "Read Edit Bash Glob Grep Bash"
---

# performance-optimization

## Overview

Measure-first 性能优化 —— 不测量就别优化。"我觉得慢了"不是性能问题,**数字才是**。Profile 在真实负载下跑,不在 toy 数据集上跑。

omo 没有专门的 perf skill —— 这个 skill 填补,聚焦在 web 性能(Core Web Vitals)和后端性能(profile-guided optimization)。

## When to Use

**Use when:**
- 用户报"页面很慢"
- 性能预算被违反(Core Web Vitals 红)
- CI 检测到性能 regression
- 新功能引入明显慢点
- 生产监控显示 P95 latency 升高

**NOT for:**
- 凭空猜测的"代码可以更快"
- 单次慢请求的偶然事件
- 还没发布的功能(先 correctness)
- 没有 measurement infrastructure 的项目(先 observability-and-instrumentation)

## Process

### 1. Define the target metric

Vague target = no target. Specify:
- **Metric:** LCP / FID / CLS / TTI / P95 latency / throughput
- **Threshold:** < 2.5s (LCP good), < 100ms (TTFB), etc.
- **Measurement method:** Lighthouse / WebPageTest / k6 / custom

### 2. Measure baseline

Run the measurement tool. Record:
- Current value
- Confidence interval (run 3+ times)
- Environment (prod / staging / local; hardware; network)

```bash
# Example: Lighthouse
npx lighthouse https://example.com --output json --quiet | jq '.audits["largest-contentful-paint"].numericValue'
```

### 3. Profile, don't guess

Use a profiler. For:
- **Frontend:** Chrome DevTools Performance tab, Lighthouse, WebPageTest
- **Backend:** `perf`, `py-spy`, `clinic.js`, `pprof`, `async-profiler`
- **Database:** `EXPLAIN ANALYZE`, slow query log

Find the **actual bottleneck**. Most performance issues are in < 5% of the code.

### 4. Apply targeted fix

Fix the bottleneck, not everything:
- One change at a time
- One measurement per change
- Roll back if it didn't help

### 5. Measure after

Re-run the same measurement. Confirm improvement is real and within margin of error. If no improvement, revert.

### 6. Add a guard

Add the metric to CI / monitoring:
- Performance budget in CI (fail build if LCP > threshold)
- Production monitoring (alert on P95 latency drift)
- Regression test if possible

## Core Web Vitals Targets

| Metric | Good | Needs work | Poor |
|---|---|---|---|
| **LCP** (Largest Contentful Paint) | ≤ 2.5s | ≤ 4.0s | > 4.0s |
| **FID** (First Input Delay) / **INP** | ≤ 100ms / ≤ 200ms | ≤ 300ms | > 300ms |
| **CLS** (Cumulative Layout Shift) | ≤ 0.1 | ≤ 0.25 | > 0.25 |
| **TTFB** (Time to First Byte) | ≤ 800ms | ≤ 1.8s | > 1.8s |
| **TBT** (Total Blocking Time) | ≤ 200ms | ≤ 600ms | > 600ms |

## Common Anti-Patterns

- **Premature optimization** before measurement
- **Micro-optimization** of cold paths
- **Memoization everywhere** without measuring if it helps
- **Bundle splitting** when total bundle is already small
- **Database denormalization** before EXPLAIN shows the bottleneck
- **Async/await conversion** of CPU-bound code (doesn't help)

## Common Rationalizations

| Excuse | Reality |
|---|---|
| "我觉得这段代码慢" | 觉得 ≠ 测量。Profile 再说。 |
| "优化了肯定比没优化好" | 错误优化让代码更复杂,perf 没变。Measure 才知道。 |
| "用户的网络很慢,我没法" | 那就 fix 你的 payload size。User's network is their constraint, your payload is yours. |
| "我们用最新 framework,默认就快" | 默认 ≠ 优化。Lighthouse 跑一下才知道。 |
| "CI 跑 perf 太慢" | 跑 perf-on-diff(只测 changed code)而不是全量。 |
| "Production 数据敏感,不能 profile" | Anonymize + aggregate + retention policy。Profile 不需要原始数据。 |

## Red Flags

- 没测就改
- 改完没测
- 改了多个地方一次测一次(不知道哪个生效)
- 在 toy 数据集上 profile
- 优化了用户不走的功能路径
- 加了 "fast path" 代码但没测是不是真的快
- 没加 guard,下个 PR 又把 perf 弄坏了

## Verification

Before declaring optimized, confirm:
- [ ] Baseline measured (specific metric, threshold, method)
- [ ] Profile identified the actual bottleneck (not guessed)
- [ ] One change at a time, measured after each
- [ ] Improvement is statistically significant (> 1σ)
- [ ] No behavior change (tests still pass)
- [ ] Performance budget added to CI / monitoring
- [ ] Reverted changes that didn't help (not "kept them anyway")

## pwf Integration

Maps to `task_plan.md` **Phase 5.7: Performance** (sub-phase). The metric + baseline + result is recorded in `.planning/<plan-id>/perf-baseline.md` — separate file, not in task_plan.md (so plan attestation doesn't depend on perf numbers).

See [pwf-integration.md](../../pwf-integration.md).