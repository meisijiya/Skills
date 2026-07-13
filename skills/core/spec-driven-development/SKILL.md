---
name: spec-driven-development
description: "Forces the agent to write a spec (goal, boundaries, acceptance criteria, command list, test strategy, risks) before any code on a non-trivial task. Use when starting a new project, new feature, or significant change; refactoring across modules; or any work touching 3+ files."
allowed-tools: "Read Edit Bash Glob Grep"
---

# spec-driven-development

## Overview

写 spec 不是写 PRD —— 是"动手前把目标、边界、交付物、验收标准想清楚"的纪律。omo 的 Prometheus 是 planner 出 plan,但**没有强制 PRD**;plan ≠ spec。Spec 是合同,plan 是排期。

没有 spec 就动手 = 边写边猜 = 返工概率 100%。Spec 是省 debug 时间的工具,不是负担。

## When to Use

**Use when:**
- 新项目 / 新功能 / 重大变更
- 重构超过 1 个模块
- 涉及多人协作 / 跨团队
- 用户明确要求"先对齐再动手"
- 改动跨越 3 个以上文件

**NOT for:**
- 单文件 typo 修复
- 一行 hotfix
- 用户明确说"先做个最小版看看"
- 纯文档 / 注释修改
- 完全已知的 trivial 重命名

## Process

### 1. Check pwf state

```bash
test -f task_plan.md && echo "pwf legacy" || \
  ls .planning/*/task_plan.md 2>/dev/null && echo "pwf parallel" || \
  echo "pwf NOT initialized"
```

If not initialized AND the task is non-trivial, prompt the user to run `init-session.sh` before proceeding.

### 2. Create Phase 1: Spec

Append to `task_plan.md`:

```markdown
## Phase 1: Spec

**Goal:** <一句话目标>

**Scope:**
- In: <做 X / Y / Z>
- Out: <不做 A / B / C>

**Acceptance Criteria:**
- [ ] <可验证的交付物 1>
- [ ] <可验证的交付物 2>
- [ ] <可验证的交付物 3>

**Commands to Run:**
- <构建命令>: 退出 0
- <测试命令>: 退出 0
- <lint 命令>: 退出 0

**Test Strategy:**
- Unit: <覆盖率目标>
- Integration: <关键路径>
- E2E: <用户场景>

**Risks:**
- <风险 1> → <缓解策略>
- <风险 2> → <缓解策略>

**Status:** in_progress
```

### 3. Write the spec

Use the template above. Fill every section — don't leave "TBD". If you don't know something, that's a question for the user, not an excuse to skip.

The spec goes in `task_plan.md` (NOT a separate file). This keeps the plan + spec colocated for attestation.

### 4. Clarify ambiguity (if needed)

If any section can't be filled confidently, load [`interview-me`](~/.agents/skills/interview-me/SKILL.md) and ask **one question at a time**. Never batch-ask five questions.

### 5. Attest the plan

Once spec is complete:

```bash
sh scripts/attest-plan.sh
```

This locks `task_plan.md` content. Subsequent hooks will detect tampering.

### 6. Get user confirmation

Show the spec. Ask the user to confirm or modify **before** proceeding to Phase 2. The user is the contract holder — not you.

## Common Rationalizations

| Excuse | Reality |
|---|---|
| "Spec 太重,直接写代码更快" | Spec 省的是 debug 时间,不是写代码时间。没 spec 的代码 90% 要返工。 |
| "用户没要求 spec" | 用户没拒绝 spec。提出 spec 跟用户对齐,才是真正的"快"。 |
| "我心里清楚就行" | 心里的不算交付物,也不在 attestation 保护范围内。 |
| "这是个 trivial 改动" | 跨 3 文件的改动不 trivial。Trivial 改动不需要 spec 也不需要这个 skill。 |
| "spec 写完用户还要看,慢" | 用户看 spec 5 分钟,你看错重写 50 分钟,这是杠杆。 |
| "Plan 不是已经覆盖 spec 了吗" | Plan 是"分几步做",spec 是"做完长什么样"。两者正交。 |

## Red Flags

- Agent 跳过 spec 直接写代码
- Spec 写得太抽象(没具体验收标准 / 没具体命令)
- Spec 留"TBD"或空白字段
- Spec 没 attestation
- Spec 写完没给用户看就开始 Phase 2
- Spec 里出现代码片段(spec 描述"做什么",不描述"怎么做")

## Verification

Before proceeding to Phase 2, confirm:
- [ ] `task_plan.md` Phase 1 section complete (no TBD)
- [ ] `scripts/attest-plan.sh` exited 0, hash recorded
- [ ] User has reviewed the spec and confirmed (verbal or in `progress.md`)
- [ ] At least 3 concrete acceptance criteria listed
- [ ] At least 1 build / test / lint command listed (real, runnable)

## pwf Integration

Maps to `task_plan.md` **Phase 1: Spec**. The spec lives inside `task_plan.md`, not a separate file — this keeps attestation simple.

| pwf hook | Effect |
|---|---|
| `UserPromptSubmit` | Inject task_plan.md (attestation-verified) so agent reads the current spec |
| `PreToolUse` | Allow Write/Edit only after spec attestation exists |
| `PreCompact` | Flush spec state to progress.md so post-compaction agent can re-read |

See [pwf-integration.md](../../pwf-integration.md) for the full phase map.