---
name: performance-optimization
description: "Measure-first post-hoc performance optimization for backend / database / profiling-heavy code. Under omo, uses lsp MCP for bottleneck localization in large codebases and analyze mode for focused audits. Use when production p99 / p95 has regressed, when a k6 gate has fired and you need to find the bottleneck, or when user-perceived latency is high and you need root-cause diagnosis. For pre-deploy perf gates (synthetic-load evidence before merge), load `k6-load-testing` first — this skill is the post-hoc partner, not the gate."
allowed-tools: "Read Edit Bash Glob Grep Bash"
---

# performance-optimization

## Overview

Measure-first 性能优化 —— 不测量就别优化。"我觉得慢了"不是性能问题,**数字才是**。Profile 在真实负载下跑,不在 toy 数据集上跑。

> **职责边界**:
> - 前端 Core Web Vitals(LCP / FID / CLS / TBT / TTFB)+ Lighthouse + Playwright + perf budgets → OMO 内置 `frontend` skill(自带 perfection ruleset + Lighthouse / Playwright 集成)
> - **本 skill 保留**:后端 profile(`perf` / `py-spy` / `clinic.js` / `pprof` / `async-profiler`)+ 数据库慢查询(`EXPLAIN ANALYZE` / slow query log)+ OMO `lsp` MCP 大代码库的瓶颈定位

## When to Use

**Use when:**
- 用户报"接口/API 慢"
- CI 检测到后端 P95 latency regression
- 新功能引入明显慢点
- 生产监控显示 P95/P99 latency 升高
- 数据库慢查询堆积

**NOT for:**(场景描述 —— 具体用哪个 skill 由 description 匹配决定,不硬指)
- 前端页面 LCP/CLS 慢
- 凭空猜测的"代码可以更快"
- 单次慢请求的偶然事件
- 还没发布的功能(先 correctness)
- 没有 measurement infrastructure 的项目

## Process

### 1. Define the target metric (backend)

Vague target = no target. Specify:

- **Metric:** P50 / P95 / P99 latency / throughput (RPS / QPS) / error rate / DB slow query count
- **Threshold:** e.g. P95 < 200ms, throughput > 1000 RPS, slow query count < 0.1%
- **Measurement method:** k6 / Locust / vegeta / wrk + Sentry / Prometheus / Grafana / SkyWalking / `pg_stat_statements` / etc.

```bash
# Example: k6 smoke load test
k6 run --vus 10 --duration 30s loadtest.js
```

### 2. Measure baseline

Run the measurement tool. Record:
- Current value (P50 / P95 / P99, error rate)
- Confidence interval (run 3+ times)
- Environment (prod / staging / local; hardware; data size)

### 3. Profile, don't guess (backend tooling)

| Surface | Tools |
|---|---|
| CPU hotspot | `perf` (Linux), Instruments (macOS), `py-spy`, `clinic.js`, `pprof` (Go), `async-profiler` (JVM) |
| DB | `EXPLAIN ANALYZE`, slow query log, `pg_stat_statements` |
| Network / syscalls | `bpftrace`, `strace`, Wireshark |
| Code intelligence (large repos) | OMO `lsp` MCP: `mcp__lsp__goto_definition` (trace hot path) / `mcp__lsp__find_references` (find callers) |

**Find the actual bottleneck.** 80% 的 perf 问题在 < 5% 的代码里。

### 4. Apply targeted fix

Fix the bottleneck, not everything:
- One change at a time
- One measurement per change
- Roll back if it didn't help

### 5. Measure after

Re-run the same benchmark. Confirm improvement is real and within margin of error (≥ 1σ). If no improvement, **revert**.

### 6. Add a guard

Add the metric to CI / monitoring:
- Performance budget in CI(fail build if P95 > threshold)
- Production monitoring(alert on P99 latency drift)
- Regression test if possible
- **omo: trigger `analyze` mode** for thorough perf reviews on suspicious changes (delegates to ultrabrain category for hard perf reasoning)

## Common Anti-Patterns

- **Premature optimization** before measurement
- **Micro-optimization** of cold paths
- **Memoization everywhere** without measuring if it helps
- **Database denormalization** before EXPLAIN shows the bottleneck
- **Async/await conversion** of CPU-bound code (doesn't help — async ≠ fast)
- **Async-of-sync-to-async chain**:把同步 SQL query 套一层 asyncio,结果还是阻塞

## Common Rationalizations

| Excuse | Reality |
|---|---|
| "我觉得这段代码慢" | 觉得 ≠ 测量。Profile 再说。 |
| "优化了肯定比没优化好" | 错误优化让代码更复杂,perf 没变。Measure 才知道。 |
| "DB 索引一定加比不加好" | 错 — 索引让写慢、占存储、可能被优化器选错。EXPLAIN 看完再说。 |
| "Connection pool 加 100 倍准没错" | 错 — 池过大 = 内存爆 + 锁竞争 + DB 连接数满。Load test 调优。 |
| "我们用最新 framework,默认就快" | 默认 ≠ 优化。Benchmark 跑一下才知道。 |
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
- 在 CWV / Lighthouse / frontend 上花时间 → 改走 OMO `frontend` skill

## Verification

Before declaring optimized, confirm:
- [ ] Baseline measured (specific metric, threshold, method)
- [ ] Profile identified the actual bottleneck (not guessed)
- [ ] One change at a time, measured after each
- [ ] Improvement is statistically significant (≥ 1σ)
- [ ] No behavior change (tests still pass)
- [ ] Performance budget added to CI / monitoring
- [ ] Reverted changes that didn't help (not "kept them anyway")

## omo Integration

Use an OMO task to record baseline, bottleneck evidence, and regression checks; librarian/oracle advise, Boulder tracks the slice, and `review-work` verifies gains.
## Related Skills

- **Frontend CWV / Lighthouse / Playwright** → OMO 内置 `frontend` skill(perfection ruleset)
- 监控埋点前置:[`observability-and-instrumentation`](~/.agents/skills/observability-and-instrumentation/SKILL.md)
- 找到瓶颈后用 [`test-driven-development`](~/.agents/skills/test-driven-development/SKILL.md) 写回归测试
- 完成验证:[`verification-before-completion`](~/.agents/skills/verification-before-completion/SKILL.md)
