---
name: observability-and-instrumentation
description: "Instruments production systems so behavior is visible and diagnosable. Use when shipping any feature that runs in production, when production issues are reported but no data exists to diagnose, or when adding telemetry to a new service."
allowed-tools: "Read Edit Bash Glob Grep Write"
---

# observability-and-instrumentation

## Overview

Production behavior must be **可见 + 可诊断**。没有 telemetry 的系统 = 盲飞 —— 出了问题只能靠用户投诉和 grep 日志。

Instrument as you build, not after launch.Launch 后再加 = 加错位置(关键路径已经有性能 budget 压力)、错过 context(已经不知道当时为啥这么写)、来不及(事故已经发生)。

## When to Use

**Use when:**
- 任何新 service / endpoint 上 production
- 重构已有 service 的关键路径
- 加新 background job / cron / queue worker
- 性能 regression 调查中
- 准备 on-call rotation(需要 alerts + runbooks)

**NOT for:**(场景描述 —— 具体用哪个 skill 由 description 匹配决定,不硬指)
- 一次性脚本(用完就丢)
- 内部工具(用户量小)
- 还没决定上 prod 的 feature
- 纯前端静态页面

## Process

### 1. Structured logging

Use structured fields, not string concatenation:

```python
# GOOD
logger.info("user.created", extra={
    "user_id": user.id,
    "email_domain": email.split("@")[1],
    "invited_by": inviter.id,
})

# BAD
logger.info(f"Created user {user.id} with email {email}")
```

Why structured: queryable in log aggregation (`user_id:12345`), parseable by tools, no regex hell.

### 2. RED metrics (per service)

For every service, instrument:
- **Rate:** requests per second
- **Errors:** failed requests per second (5xx, exceptions)
- **Duration:** latency distribution (P50, P95, P99)

```python
# Per-request metric
metrics.counter("http_requests_total", tags={
    "method": request.method,
    "path": request.path,
    "status": str(response.status_code),
}).inc()
metrics.histogram("http_request_duration_seconds", tags={...}).observe(duration)
```

### 3. Tracing (cross-service)

For distributed systems, OpenTelemetry:
- Trace ID propagates through services
- Span per unit of work (HTTP handler, DB query, RPC)
- Parent/child relationships visible

Use sampling in production (1-10%) to control volume.

### 4. USE metrics (per resource)

For every resource (CPU, memory, disk, network):
- **Utilization:** % busy
- **Saturation:** queue depth / wait time
- **Errors:** error count

### 5. Symptom-based alerting

Alert on **user-visible symptoms**, not internal metrics:

| Bad alert | Good alert |
|---|---|
| CPU > 80% | Error rate > 1% over 5 min |
| Memory > 90% | P95 latency > 500ms |
| Disk full | User-facing flow failing |

Why: CPU alert at 3am when no user is affected = page fatigue = ignored alerts = real incident missed.

### 6. Log levels correctly used

| Level | Use for |
|---|---|
| ERROR | Operation failed, needs human attention |
| WARN | Recoverable issue, may need attention later |
| INFO | Significant state change (request handled, job completed) |
| DEBUG | Diagnostic info, off in prod |

Don't log secrets at any level. Don't log PII unless required (and then mask).

### 7. Pre-launch gate

Before shipping any new code path:
- [ ] Structured logging added at key state changes
- [ ] RED metrics instrumented
- [ ] Tracing spans added for cross-service calls
- [ ] Symptom-based alerts configured
- [ ] Runbook exists for known failure modes
- [ ] Dashboards show the new metrics

## Common Rationalizations

| Excuse | Reality |
|---|---|
| "我们上 prod 再加 telemetry" | 上 prod = 用户已经在用 = 出问题追不到。先加。 |
| "日志就够了,metrics 太重" | 日志是 forensic,metrics 是实时。两者互补,不是二选一。 |
| "我们没出过错,telemetry 不急" | "没出过"通常 = "没发现"。Telemetry 是发现手段。 |
| "加 telemetry 影响性能" | 不加 = 性能问题没人知道。加 = 5% overhead,可观测。可观测 > 5% perf。 |
| "用 string format 比 structured 简单" | 简单到 grep 都难。Structured 是 long-term 简单。 |
| "alert 越多越安全" | 越多 = 越多误报 = alert fatigue = 真实 alert 被忽略。少而准。 |

## omo Integration

For SLI/SLO design decisions (e.g., "is P99 or P95 the right SLO target?", "what's the burn-rate alert threshold for this service?"), dispatch to `oracle` agent for read-only high-IQ reasoning. For instrumenting code that touches hot paths identified by [`performance-optimization`](~/.agents/skills/performance-optimization/SKILL.md), the workflow chain is `brainstorming` → `spec-driven-development` → `incremental-implementation` (per slice: instrument + test). Capture SLI/SLO decisions in the Prometheus plan (`.omo/plans/<slug>.md`) and the per-event evidence stream at `.omo/start-work/ledger.jsonl`; use OMO task tools for rollout and `review-work` for production verification.

## Anti-Patterns

- 日志用 string format,不是 structured fields
- Log 里出现密码 / token / 信用卡号
- ERROR 日志没人看,永远不告警
- 告警基于内部指标(CPU > X%)而不是用户症状
- 没有 trace,跨服务调用像黑盒
- 没有 runbook,事故时现写
- "我们都用 INFO level" = DEBUG 不可用 = 排查困难
- 监控覆盖 dev 环境,不覆盖 prod

## Verification

Before declaring instrumented, confirm:
- [ ] Structured logging at key state changes
- [ ] RED metrics per service (rate / errors / duration)
- [ ] Distributed tracing for cross-service calls
- [ ] Symptom-based alerts (not internal-resource alerts)
- [ ] Log levels correctly used
- [ ] No secrets / PII in logs
- [ ] Dashboards show new metrics
- [ ] Runbook exists for the new failure modes
- [ ] On-call rotation acknowledged the new alerts
