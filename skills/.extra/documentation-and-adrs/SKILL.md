---
name: documentation-and-adrs
description: "Records decisions and documentation that future engineers and agents need. Use when making architectural decisions, changing public APIs, shipping features, or when context needs to outlive the current session."
allowed-tools: "Read Edit Bash Glob Grep Write"
---

# documentation-and-adrs

## Overview

文档是**为什么**的载体,不是**什么**的复述。Code 说"做了什么",docs 说"为什么这么做"。没 docs = 3 个月后没人知道当时为啥这么选 = 重写或者凑合保留错误决策。

ADR(Architecture Decision Record)是核心 —— 记录重要决策的**context + options chosen + consequences**,让未来人(包括未来的你)能理解决策。

## When to Use

**Use when:**
- 选型(框架、库、database、API style)
- 架构决策(monolith vs microservice, sync vs async, SQL vs NoSQL)
- 改 public API(breaking change)
- 重大重构(影响多个模块)
- 引入新的开发流程 / 工具

**NOT for:**
- 内部 helper 命名(代码 itself 就够)
- trivial bug fix
- 纯 cosmetic 改动
- 临时 spike(用完就丢)

## Process

### 1. Identify the decision

State it in one sentence:
- "We use [X] instead of [Y] for [purpose]"
- "We chose [architecture] because [reason]"

If you can't state it in one sentence, the decision isn't clear yet. Use `interview-me` to clarify.

### 2. Capture context

What was the situation when this decision was made?
- Constraints (time, team, existing tech)
- Requirements (scale, latency, cost)
- Assumptions (what we believe to be true)

### 3. List options considered

For each option:
- Pros
- Cons
- Risk

### 4. Document the decision

What we chose. **One** decision, not a compromise that tries to satisfy all options.

### 5. List consequences

Both positive and negative:
- "We get [X] but lose [Y]"
- "Future changes will need [Z]"

### 6. State reversibility

- **Reversible** (e.g., library choice): write ADR but don't over-invest
- **Hard to reverse** (e.g., monolith → microservice migration): write detailed ADR, get peer review

### 7. ADR template

```markdown
# ADR-NNN: <Title>

**Date:** <YYYY-MM-DD>
**Status:** proposed | accepted | superseded | deprecated
**Deciders:** <names>

## Context

<What was the situation? What problem are we solving?>

## Options Considered

### Option 1: <Name>
- Pros: ...
- Cons: ...
- Risk: ...

### Option 2: <Name>
- ...

## Decision

We chose **Option X** because <reason>.

## Consequences

- Positive: ...
- Negative: ...
- Future implications: ...

## Reversibility

<How easy/hard is it to reverse this decision?>

## References

- <links to relevant docs, issues, discussions>
```

Store ADRs in `10_docs/adr/` (per `agent-project-structure` convention) or `docs/adr/`.

## Other Doc Types

### API docs

- Generated from code where possible (OpenAPI, TypeDoc, etc.)
- Hand-written for the "why" and examples
- Always include a "Quick start" that actually works

### Inline comments

- Comment the **why**, not the **what**
- `// fetch with retry: API has transient 503s on deploy` (why) ≠ `// fetch` (what)
- Remove commented-out code (git has history)

### README

- What is this?
- Why does it exist?
- How do I run / test / deploy?
- Where do I look for X?

### Changelog

- One line per user-visible change
- Link to PR / commit
- Group by version, newest first

## Common Rationalizations

| Excuse | Reality |
|---|---|
| "代码 self-documenting" | 代码说"什么",不说"为什么"。Decision context 永远在 docs。 |
| "我们以后补文档" | 以后 = context 丢失 = 写得不准。先写。 |
| "ADR 太重,issue 讨论够了" | Issue 散落。ADR 集中且 immutable。Issue 可以改 / 被 close。 |
| "就我们俩,不用 docs" | "我们俩"会变。Docs 让团队扩容不需要 redo context。 |
| "改一行也要 ADR 吗" | 不用。ADR 用于重要决策。trivial 不需要。 |
| "文档写完就过期" | 写在 commit 里,跟代码一起演化。文档脱节 = 治理失败。 |

## Red Flags

- ADR 写了"我们选了 X"但没写"为什么不选 Y"
- Doc 跟代码脱节(commit 改代码,doc 没动)
- Inline comment 解释 what(代码已经说明)不解释 why
- README 没"Quick start"或"Quick start" 跑不通
- Changelog 缺版本 / 日期 / 链接
- ADR 没有 status(不知道是否还有效)
- Doc 用过时截图 / 旧 UI 描述

## Verification

Before declaring documented, confirm:
- [ ] ADR has Context / Options / Decision / Consequences / Reversibility
- [ ] Doc updated in same commit as code change
- [ ] Inline comments explain why, not what
- [ ] README Quick start actually works (tested)
- [ ] Changelog entry added for user-visible changes
- [ ] Doc has author + date + status where relevant
- [ ] No orphan docs (referenced from somewhere)

## pwf Integration

ADRs complement pwf: pwf handles session-level planning, ADRs handle cross-session architectural decisions. ADRs go in `10_docs/adr/` (project-level), never in `task_plan.md` (session-level).

See [pwf-integration.md](../../pwf-integration.md).