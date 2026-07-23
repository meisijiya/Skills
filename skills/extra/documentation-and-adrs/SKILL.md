---
name: documentation-and-adrs
description: "Records significant architectural decisions as ADRs (Markdown files in `docs/adr/`). Strictly limited to architecture-level decisions (data model, API contracts, dependency upgrades, deprecations). Daily project docs, READMEs, and inline comments belong in the project's own AGENTS.md or progress notes — not as ADRs."
allowed-tools: "Read Write Edit Bash Glob Grep"
---

# documentation-and-adrs

## Overview

**收紧范围**:ADR 只记**重大架构决策**(数据模型 / API 契约 / 依赖升降级 / 弃用 / 选型改变),不记日常文档 / README / 注释。这些走项目自己的 `AGENTS.md` 或 `.omo/notepads/<plan>/decisions.md`(短期日常记录),不进 ADR。

Why: 一个项目动辄 50+ ADRs 时,绝大多数是噪音,真正影响未来工程师的反而被埋住。一个 ADR 应当 5 年后回头看仍能让新人决策一致。

When to write an ADR:
- 选了 X 而非 Y,且未来人很可能再问"为什么不是 Y"(**不可逆 + 跨时间 + 跨人**)
- 影响 1+ 模块的契约 / 依赖 / 数据流

When NOT to write an ADR:
- 单文件改名
- 修 typo / 注释 / 文档格式
- 只是"今天做的改动" — 那是 git log + commit message 的活
- 临时决定,且文档里说"未来回头看再考虑" — 那就别写

## When to Use

**Use when:**
- 一个架构选型已经做出(选 React 不选 Vue / 选 Postgres 不选 Mongo / 选 REST 不选 gRPC),需要在团队内/跨时间留下"why"
- 决定弃用旧模块且未来人会问"为什么删它"
- 重大依赖升级(如 React 18 → 19),记录 breaking change 应对策略

**NOT for:**
- 项目 README / 简介 / onboarding — 那是 README + AGENTS.md,不是 ADR
- 单个函数行为修正 / bug fix — 那是 commit message
- API endpoint 列表 / 字段映射 / 数据字典 — 那是 spec / OpenAPI 文件
- 进度日志 / "今天做了什么" — 那是 `.omo/notepads/<plan>/decisions.md`

## Process

### 1. Decide if it deserves an ADR

Ask:

- 不可逆?**NOT**(可以轻易 revert)→ skip
- 跨时间 / 跨人?**NOT**(只本周/本人在意)→ skip
- 未来一年里仍有人会想知道"为什么"?**NOT** → skip

`如果答案是 NOT NOT NOT → 不写 ADR。` 反向测试:写完后给六个月后的自己看,会不会觉得"哦原来是这样"。

### 2. Use the Nygard template (lightly adapted)

```markdown
# ADR-<NNNN>: <title>

**Date:** YYYY-MM-DD
**Status:** proposed | accepted | deprecated | superseded by ADR-XXXX

## Context

<what problem we faced; what forces were in play; why now>

## Decision

<what we chose; key option(s) considered; how they're different>

## Consequences

**Positive:**
- <gain>

**Negative:**
- <cost / risk we accept>

**Reversibility:** <easy / medium / hard / irreversible>

## Alternatives considered

- <option>: <why not chosen>
```

存到 `docs/adr/<NNNN>-<slug>.md`(自增 NNNN)。

### 3. Cross-reference

- 被影响的 Spec / Phase:link 到 `.omo/plans/<slug>.md` 对应 Phase(Design / Spec / Slice)
- Supersede 旧 ADR 时:`superseded by ADR-XXXX`,并在 README 列出来

### 4. Do NOT auto-write ADRs at every phase

Phase 7 不再是默认必走(已撤出主流程)。只有真的产生"重大架构选型"的 phase 才走本 skill。

## Common Rationalizations

| Excuse | Reality |
|---|---|
| "这件事挺重要的,先写下来" | 重要 ≠ 架构决策。代码改动记录在 git log / commit message,不用 ADR。 |
| "未来可能有人问" | "可能" = 不写。等真有人问时再 backfill 也来得及。 |
| "ADR 写起来轻松" | 写 ADR 容易,但 ADRs 多到没人读 = 噪音更糟。只有不可逆 + 跨时间 + 跨人选型才值得。 |
| "参照 X 公司也这么写" | X 公司的策略对 X 公司合理。你的 ADR 列表应只有真正影响未来的。 |
| "我们文档少,补点 ADR" | 不是所有项目都需要 ADR。Bootstrap 阶段(< 50 个文件)大多数决定都 git log 就行。 |

## Red Flags

- 单文件改动也写 ADR — 浪费
- 一周内 5+ ADR — 节奏过快,大多数是噪声
- ADR 写得像 commit message(短 + 没 context)
- ADR 里没有 "Alternatives considered" — 决策没权衡就不算 ADR
- ADR 写到 `.omo/plans/<slug>.md`(那是 Phase 表 + status,不是 ADR 仓库)
- 把 ADR 当作 "task work" 写进 Phase 7 — Phase 7 已被撤出主流程

## Verification

Before declaring an ADR done:
- [ ] 写了 ADR,但**真的不可逆 + 跨时间 + 跨人**
- [ ] 用了 Nygard 模板的四个段(Context / Decision / Consequences / Alternatives)
- [ ] 文件命名 `docs/adr/<NNNN>-<slug>.md`,序号自增
- [ ] Cross-ref 到受影响 phase / 旧 ADR(如适用)
- [ ] 项目 README 列出 ADR 索引(可选,推荐 — 新人一眼能找到)

## omo Integration

Record the ADR decision by adding a cross-reference entry to `.omo/plans/<slug>.md` Phase 1 (link `docs/adr/<NNNN>-<slug>.md` from the affected phase); create a task via OMO `task_create` for any follow-up implementation if needed, and use `review-work` to verify cross-links and scope.

## Related Skills

- 跨时间决策模板:MADR / Nygard (本 skill 用了 Nygard 的微调版)
- 项目长期文档:`AGENTS.md`(项目级 convention),`README.md`(新人入口)
- 单次进度:`.omo/notepads/<plan>/decisions.md`
