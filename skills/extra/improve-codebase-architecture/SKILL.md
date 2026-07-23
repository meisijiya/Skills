---
name: improve-codebase-architecture
description: "Periodic codebase architecture health check that surfaces shallow modules, coupling hotspots, and concept-sprawl using Ousterhout's deep/shallow scoring (interface area / impl-to-interface ratio / caller cost / test ease), then proposes deepening candidates without forcing edits. Use when on-boarding an unfamiliar codebase, doing a weekly or post-surge review, or when agents seem to produce worse output than the codebase warrants. NOT for single-file refactors (use remove-ai-slops or incremental-implementation), known bugs (use debugging-and-error-recovery), new feature design (use brainstorming + spec-driven-development), performance optimization (use performance-optimization), or security review (use security-and-hardening + security-devsecops). Load by user signal OR weekly-cadence prompt — does not gate any other skill; runs as a sidecar scan. (token cost: medium-to-high — codebase scan via librarian agent or manual grep)"
allowed-tools: "Read Edit Bash Glob Grep"
---

# improve-codebase-architecture

## Overview

扫一遍代码库,挑出结构上的痛点,产出 deepening 候选清单 —— **不改代码**。

**视角**:John Ousterhout 的 deep/shallow 模块框架。deep module = 接口简单 + 功能强大;shallow module = 接口跟实现一样复杂。每个候选按这个维度评分,而不是按"行数"或"美学"。

**为什么 proposal-only**:架构改造是高风险动作,不该在审查 skill 里顺手做。`incremental-implementation` 才是真正动刀的 skill。本 skill 只产出 `.planning/<id>/architecture-review.md`,由你 / 团队决定哪些候选上 Phase 3 切片。

## When to Use

**Use when:** (软触发 — 以下是典型场景,AI 按 description 匹配自决)
- 新接手一个陌生 codebase,在让 agent 大规模介入前先扫一遍
- 周期性回顾(每周 / 每两周 / 每个开发高峰后)
- 怀疑"agent 在烂 codebase 里产出更烂的代码"
- 跨文件耦合信号:加一个 feature 改了 5+ 个文件,感觉不对劲
- 团队扩张 / 新人 on-boarding

**NOT for:**(场景描述 —— 具体用哪个 skill 由 description 匹配决定,不硬指)
- 单文件 / 单函数的清理
- 已知 bug 修复
- 新功能设计
- 性能优化 / 安全审查
- 想直接动刀(本 skill 候选清单走 handoff)

## Process

### 1. Inventory the codebase

用 OMO `librarian` agent 或 `codegraph` 建一份模块 / 概念地图。问自己:
- 这个 codebase 有几个独立子系统?边界在哪?
- "理解一个概念"平均要跳几个文件?

如果连第一步都跑不通(没有 librarian / codegraph),退化为 `ls + find + grep` 的手工 inventory,接受不完整。

**omo Team Mode 加速**(可选):当 `team_mode.enabled = true` 时,Inventory 阶段(§1)可以分发给最多 8 个并行 `explore` 子 agent(每个负责一个 subsystem)。这能把 30 分钟的手工 inventory 压缩到 5 分钟。**默认 OFF** —— 仅当 codebase 有 5+ 个独立 subsystem 时再启用。这不是 proposal-only 纪律的替代;候选清单仍走人工优先级排序。

### 2. Surface confusions

对每个概念走 Matt Pocock 的三问:

1. **理解一个概念需要跳多少文件?** 5+ 跳 = 概念被切碎了
2. **有没有为了可测试性抽出的 pure function,真实 bug 藏在调用方式?** 调用图比函数体更复杂 = 抽象反向
3. **紧耦合的模块之间,集成风险点在哪?** 改 A 必须同时改 B,即使 B 不该知道 A 的存在

每条命中的混乱都记到候选清单。

### 3. Score candidates on deep/shallow axis

Ousterhout 框架 —— 不要按"行数"或"美学"打分:

| 维度 | deep(好) | shallow(差) |
|---|---|---|
| 接口面积 | 小 | 大 |
| 实现 / 接口比 | 实现复杂、接口简单 | 接口跟实现一样复杂 |
| 调用成本 | 调用方不需要懂实现细节 | 调用方必须懂实现细节 |
| 测试难易 | 接口测试即可覆盖 | 必须 mock 内部才能测 |

每个候选按这四个维度逐项评估。**不要给"差不多 deep"打分 —— 要么 deep 要么 shallow**。

### 4. Write candidates to `.planning/<id>/architecture-review.md`

输出模板:

```markdown
# Architecture Review — <date>

## Inventory
- 子系统: <list>
- 跨子系统边界: <list with file:line refs>

## Confusions
- [ ] 概念 #1 跨 X 文件 → candidate C1
- [ ] 调用图复杂度 > 实现复杂度 → candidate C2
- [ ] 紧耦合点 → candidate C3

## Deepening Candidates
### C1: <name>
- 现状: <deep 或 shallow,4 维评分>
- 改造方向: <把哪几个文件合并 / 哪个接口收窄>
- 估算影响: <slice 数,改动 LOC 范围>
- 风险: <数据迁移? 公共 API? 外部依赖?>
```

### 5. Hand off — do NOT execute inside this skill

候选清单写完就停。**不要**在本 skill 里开始改代码。

handoff 协议:
- 候选 ≥1 → 跟用户 / 团队讨论优先级
- 选中上 Phase 3 → invoke [`incremental-implementation`](~/.agents/skills/incremental-implementation/SKILL.md),把 `architecture-review.md` 作为 Phase 3 输入
- 全部不采纳 → 文档归档,等下次巡检再决定

## Common Rationalizations

| Excuse | Reality |
|---|---|
| "顺手把 shallow module 改了" | 本 skill 是 proposal-only;动手的是 `incremental-implementation` |
| "agent 已经知道要 refactor 哪里,不用写清单" | agent 的判断是局部视角;codebase-wide 视角才能发现跨文件耦合 |
| "每周都跑太机械了" | 节奏是建议,不是义务;触发场景满足就跑 |
| "Ousterhout 框架太学术" | 4 维度评分是反"差不多"机制 —— 没有这个,候选清单会塞一堆"我觉得该改" |
| "已经有 OMO refactor 系列了,干嘛再加一个" | OMO `refactor` / `ponytail-review` / `remove-ai-slops` 是 per-diff 清理,本 skill 是 codebase-wide 巡检 —— 不同视角,具体场景由 description 匹配 |
| "改架构风险太大,等出问题再说" | 出问题再改 = 救火;巡检 = 提前规划 |

## Red Flags

- 在本 skill 里跑 `Edit` 改代码(走错 skill 了)
- 候选清单写了一半就开始动刀
- 用"差不多 deep"评分 —— 要么 deep 要么 shallow
- Inventory 跳过了直接打分
- 把 `architecture-review.md` 写到 `OMO plan` 里(本 skill 是 sub-phase,不入 phase)
- 跳过 handoff 直接宣称"架构改完了"

## Verification

完成本 skill 后确认:
- [ ] `.planning/<id>/architecture-review.md` 已写,含 ≥3 个候选(codebase 太小可 <3,注明原因)
- [ ] 每个候选按 4 维度评分,**无"差不多"分**
- [ ] 本 skill 未产生 diff / 未运行 commit
- [ ] handoff 已同步(用户/团队 或 `OMO notepad`)

## omo Integration

Run the proposal scan with librarian/oracle or Team Mode, capture candidates in the OMO notepad, then hand approved work to `incremental-implementation` and Boulder.
## Related Skills

- 后续动刀:[`incremental-implementation`](~/.agents/skills/incremental-implementation/SKILL.md)
- 配套 on-boarding:[`source-driven-development`](~/.agents/skills/source-driven-development/SKILL.md)
- 完成门:[`verification-before-completion`](~/.agents/skills/verification-before-completion/SKILL.md)