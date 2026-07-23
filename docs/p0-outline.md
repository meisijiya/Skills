# core/ 5 个 P0 SKILL.md 大纲(归档)

> **状态**:✅ 已 ship(2026-07-11)。本文件保留作为设计记录。
> 实际 SKILL.md 已写入 `skills/core/{spec-driven-development,incremental-implementation,test-driven-development,debugging-and-error-recovery,source-driven-development}/SKILL.md`。

---

## 1. spec-driven-development

**Overview**:写 spec 不只是 PRD —— 是"动手前想清楚目标、边界、交付物、验收标准"的纪律。omo 的 Prometheus 是 planner 出 plan,但**没有强制 PRD**;plan ≠ spec。

**When to Use**:
- 新项目 / 新功能 / 重大变更
- 重构超过 1 个模块
- 涉及多人协作 / 跨团队

**NOT for**:
- 单文件 typo 修复
- 一行 hotfix
- 用户明确说"先做个最小版看看"

**Process**:
1. 检查 `task_plan.md`,创建 `Phase 1: Spec`
2. 加载 `interview-me` 处理不清楚的部分(可选)
3. 写 spec 模板:`目标` / `边界` / `验收标准` / `命令清单` / `测试策略` / `风险`
4. 写到 `.planning/<plan-id>/spec.md`(不进 task_plan.md,避免污染 attestation)
5. 跑 `attest-plan.sh` 锁定 task_plan.md(不是 spec.md)
6. 用户口头确认 → 推进 Phase 2

**Rationalizations**:
- "spec 太重,直接写代码更快" → spec 是省 debug 时间
- "用户没要求 spec" → 用户没拒绝 spec
- "我心里清楚就行" → 心里的不算交付物

**Red Flags**:
- agent 直接动手写代码
- spec 写得太抽象(没验收标准)
- 跳过 attestation

**Verification**:
- [ ] `spec.md` 存在,涵盖 6 个标准段
- [ ] `attest-plan.sh` 成功,hash 已记录
- [ ] 用户口头确认

---

## 2. incremental-implementation

**Overview**:纵向切片 —— 每个 slice 独立可交付、可回滚、可单独 ship。横向分层(一口气全写完)是大忌。

**When to Use**:
- 任何改动超过 1 个文件
- 任何含 3+ 个步骤的实现任务
- 重构 / 迁移

**Process**:
1. 在 `task_plan.md` 的 Phase 3 拆出 N 个 slice(每个 ≤ 100 行)
2. 每个 slice 用 `git worktree` 或 feature branch 隔离
3. slice 完成后跑 `test-driven-development` 红绿循环
4. slice commit 信息必须包含 `slice: <name>` 前缀
5. 每个 slice 写到 `progress.md` 一行摘要

**Rationalizations**:
- "一次写完更快" → 一次写完更快地制造 bug
- "slice 太小没必要" → 30 行的 slice 也有价值
- "git worktree 太麻烦" → 主分支污染更麻烦

**Red Flags**:
- 单个 slice > 100 行
- slice 之间互相依赖(必须先 A 才能 B)
- 没 commit 就跳到下一个 slice
- 在 main 分支直接改

**Verification**:
- [ ] 每个 slice 独立 commit
- [ ] 所有 slice 测试通过
- [ ] 任意 slice 回滚后其他 slice 仍能工作

---

## 3. test-driven-development

**Overview**:红绿重构 —— 先写失败的测试,再写最小代码让它通过,再重构。**禁止先写实现再补测试**。

**When to Use**:
- 实现任何新逻辑
- 修复任何 bug(先写 regression test 再 fix)
- 改任何行为

**Process**:
1. **红**:写一个失败的测试(必须是真实行为,不是类型检查)
2. **绿**:写最小代码让它通过(不能多写)
3. **重构**:消除重复,行为不变
4. **commit**:`test: add <test-name>` → `feat: implement <feature>`
5. 任何 API 边界检查用 `boundary test`(零值、空、超大、并发)

**Rationalizations**:
- "我先写代码再补测试" → 那叫"测试覆盖实现",不是 TDD
- "这个逻辑太简单,不需要测试" → 简单的逻辑最容易藏 bug
- "测试太多,跑得慢" → 单元测试 < 1s/100 个

**Red Flags**:
- 跳过"红"(直接写实现)
- 测试和实现一起提交,看不到先红
- 测试只验证类型/存在,不验证行为
- mock 多于真实代码

**Verification**:
- [ ] 测试金字塔 80/15/5(unit/integration/e2e)
- [ ] 每个 commit 有对应测试
- [ ] 修复 bug 时先有 failing regression test

---

## 4. debugging-and-error-recovery

**Overview**:五步排错 —— reproduce / localize / reduce / fix / guard。**禁止猜根因,改改看**。

**When to Use**:
- 测试失败
- 构建失败
- 行为异常(测试通过但运行错)

**Process**:
1. **Reproduce**:写一个能稳定复现的最小命令(一行能跑)
2. **Localize**:二分法找根因(关一半 / 开一半,定位到模块/函数/行)
3. **Reduce**:最小化复现用例(剥离无关代码)
4. **Fix**:根因修复,不打补丁
5. **Guard**:加 regression test(防止重犯)

**Rationalizations**:
- "我猜是 X,改改看" → 猜不是修
- "时间紧,先 fix 再说" → 没找到根因的 fix 会回来咬你
- "reproduce 太麻烦" → 没 reproduce 的 fix 是赌博

**Red Flags**:
- 不写复现命令
- 一次改多个地方
- 跳过 regression test
- 修完不留 root cause 笔记

**Verification**:
- [ ] 复现命令存在,任何人都能跑
- [ ] regression test 加进 test suite
- [ ] root cause 写到 `task_plan.md` 的 Errors 表

---

## 5. source-driven-development

**Overview**:框架 / 库的 API 必须先查官方文档,凭记忆写代码容易错(尤其大版本升级)。

**When to Use**:
- 用任何框架 / 库的 API
- 跨大版本升级
- 不熟悉的 API
- 调试"为什么这个 API 表现不对"

**Process**:
1. 识别当前用的框架 / 库 + 版本
2. 用 context7 MCP(或 web search)查官方文档
3. 把关键 API / 版本号 / breaking changes 写到 `findings.md`
4. 代码注释或 spec 里引用源 URL
5. **不查文档就别动手**

**Rationalizations**:
- "我用过 X 框架,知道 API" → 你的训练数据可能过时
- "文档太啰嗦" → 文档啰嗦比写错 API 强
- "这个 API 简单,不用查" → 简单的 API 也升级过 breaking change

**Red Flags**:
- 凭记忆写 API 调用
- 不引用源 URL
- 不查版本(用错版本的 API)
- 调试时凭感觉改 API 参数

**Verification**:
- [ ] `findings.md` 有查到的文档摘录 + URL
- [ ] 代码注释有源链接
- [ ] 引用的文档版本跟实际依赖版本匹配

---

## 风格定调

每个 SKILL.md 按以下结构(跟 `using-meisijiya-skills` 一致):

```yaml
---
name: <kebab-case>
description: <第三人称>"做 X。Use when Y。" (≤1024 字符)
allowed-tools: "Read Edit Bash Glob Grep"
---
# <Title>
## Overview
## When to Use (含 NOT for)
## Process
## Common Rationalizations (表格)
## Red Flags (列表)
## Verification (checkbox)
```

行数目标:每个 200~400 行。

---

## 待用户确认

| 维度 | 当前默认 | 是否要改? |
|---|---|---|
| 5 个 P0 范围 | spec / incremental / TDD / debug / source | 加?减?换? |
| 每个 skill 行数 | 200~400 行 | 太长?太短? |
| 风格 | 跟 using-meisijiya-skills 一致 | 要变? |
| language | 中文为主,英文术语保留 | 改? |

**用户点头后我批量写出 5 个完整 SKILL.md + 5 个 eval JSON。**