---
name: spec-driven-development
description: "Forces the agent to write a spec (goal, boundaries, acceptance criteria, command list, test strategy, risks) before any code on a non-trivial task. Use when starting a new project, new feature, or significant change; refactoring across modules; or any work touching 3+ files."
allowed-tools: "Read Edit Bash Glob Grep"
---

# spec-driven-development

## Overview

写 spec 不是写 PRD —— 是"动手前把目标、边界、交付物、验收标准想清楚"的纪律。omo 的 Prometheus 是 planner 出 plan,但**没有强制 PRD**;plan ≠ spec。Spec 是合同,plan 是排期。

## omo Integration

**Spec vs Prometheus Plan**: Prometheus writes a YAML/structured plan for `atlas` execution. `brainstorming` (or Prometheus interview) writes the Design into `task_plan.md` Phase 0. This skill writes the **PRD/Spec** into `task_plan.md` Phase 1 — the contract that comes BEFORE the Prometheus plan. Order:

1. Phase 0: Design ([`brainstorming`](~/.agents/skills/brainstorming/SKILL.md) — or Prometheus Mode)
2. Phase 1: Spec (this skill, with `attest-plan.sh` attestation)
3. Momus plan review (omo built-in; `momus` agent validates plan against clarity/verification/context criteria)
4. Phase 2: Research, Phase 3: Slice ([`incremental-implementation`](~/.agents/skills/incremental-implementation/SKILL.md))
5. `/start-work` to dispatch to Atlas

**`attest-plan.sh` vs Prometheus**: Prometheus writes its plan to its own format. Our `attest-plan.sh` hashes `task_plan.md` (Phases 0-3). If running under omo, Momus reviews the Prometheus plan; we still attest `task_plan.md` (the source of truth). **Do not skip attestation** because "Prometheus approved it" — those are separate gates.

没有 spec 就动手 = 边写边猜 = 返工概率 100%。Spec 是省 debug 时间的工具,不是负担。

> **职责边界**:
> - **唯一落点**:PRD/Spec 写到 `task_plan.md` **Phase 1**。不允许独立 `spec.md` / `docs/specs/*.md` 文件(会破坏 pwf attestation 链)。
> - **唯一审批门**:本 skill 是 `brainstorming` 之后的唯一一次"Spec 写完请用户确认"。`brainstorming` 已批准 Design,本 skill 只需批准最终 Spec。
> - **诚实标注**:OpenCode 是 Tier 3,PreToolUse / Stop 不能硬阻断;PreCompact / 实验性 hook 才能注入上下文。

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

### 2. Read Phase 0: Design (from brainstorming)

The [`brainstorming`](~/.agents/skills/brainstorming/SKILL.md) skill wrote Phase 0 into `task_plan.md`. Read it; don't re-derive. Your job is to **refine** the design into a verifiable Spec, not redo the conversation.

### 3. Append Phase 1: Spec to `task_plan.md`

```markdown
## Phase 1: Spec

**Goal:** <一句话目标,继承 Phase 0>

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
- Unit: <覆盖率目标 / 关键 seam>
- Integration: <关键路径>
- E2E: <用户场景>

**Risks:**
- <风险 1> → <缓解策略>
- <风险 2> → <缓解策略>

**Risk Review:**
- Risk level: <L1 | L2 | L3 — minimum verification strength, not a domain label or safety guarantee>
- Risk signals: <open-world observed/absent/uncertain signals; contract completeness, state/timing/concurrency, boundary/dependency, reversibility, and verification blind spots are explicitly non-exhaustive examples; absence from examples never proves L1>
- Contract gaps / uncompiled requirements / uncertainty: <stated, inferred, and unknown obligations; do not invent thresholds or data shapes>
- Phase 1.25 route: <when any signal is observed or uncertain, after attestation load [`contract-strengthening`](~/.agents/skills/contract-strengthening/SKILL.md) if installed; a missing optional extra does not block the core flow>

**Status:** in_progress
```

Fill every section — don't leave "TBD". If you don't know something, that's a question for the user via [`brainstorming`](~/.agents/skills/brainstorming/SKILL.md) (one at a time), not an excuse to skip.

The Spec lives in `task_plan.md` Phase 1 — Phase 0 (Design) above, Phase 2 (Research) below. **No separate spec file.**

### 4. Clarify ambiguity (if needed)

If any section can't be filled confidently, return to the [`brainstorming`](~/.agents/skills/brainstorming/SKILL.md) one-question-at-a-time protocol. **Do NOT batch-ask five questions.** Delegated judgment may recommend an answer, but never approves unresolved design or contract choices and cannot bypass the user-approved Design gate.

### 5. Attest the plan

Once Spec is complete:

```bash
sh scripts/attest-plan.sh
```

This locks `task_plan.md` content (SHA-256). Subsequent hooks will detect tampering.

> **Honest tier limits (OpenCode)**:
> - On OpenCode, the **hash check is advisory** (Tier 3); it doesn't hard-block Write/Edit.
> - The durable record is `task_plan.md` itself, not the plugin gate. Keep the file under VCS.
> - The pwf `pwf-enforcer` plugin (extra) hard-injects the plan head via `experimental.chat.system.transform` and `experimental.session.compacting` — but cannot hard-stop on incomplete phases.

### 5.5 Amend Spec mid-build

需求进入 Phase 3 后用户改主意 / review-work 报告变更 / 验收标准漂移 — 必走 amend 协议。**禁止**继续按旧 Spec 写,因为旧 hash 仍是 plan head,新改动不被 pwf 注入,attest 失真。

#### 何时调用

由 [`incremental-implementation`](~/.agents/skills/incremental-implementation/SKILL.md) § 9 (Mid-build requirement changes) 路由而来:
- **Data-shape / API contract** 改动 → 直接进 § 5.5
- **Pure addition (orthogonal)** → append 一段到 Phase 1 后也进 § 5.5
- **WHY changed(feature re-scope)** → 不进 § 5.5;先回 [`brainstorming`](~/.agents/skills/brainstorming/SKILL.md) Phase 0 重对齐,完成后再走 § 1-5 全新流程
- **Cosmetic / HOW** → 不进 § 5.5(只在 `task_plan.md` 字面改文字;不重跑 attest,或不 hash 化)

#### 流程

1. **对照原 Spec** (`task_plan.md` Phase 1) 标出**仅被影响的 section**(Acceptance / Scope / Test Strategy / 等)。**不重写无关段**。
2. **就地编辑** `task_plan.md` Phase 1 的对应 section。`Status: in_progress` 行保留(attest 后再变回 `amended`)。
3. **同步增量**到 Spec 影响的所有 slice(由 [`incremental-implementation`](~/.agents/skills/incremental-implementation/SKILL.md) § 9.3 的状态机执行):新 slice append / 旧 slice 标 `superseded` / 旧 slice 改 `verify`。
4. **Re-attest**(同 § 5):
   ```bash
   sh scripts/attest-plan.sh
   ```
   新 SHA-256 写到 `.planning/<id>/.attestation` 或 `.plan-attestation`(取决于 parallel / legacy 模式,见 [`pwf-integration.md`](../../pwf-integration.md))。**`pwf-enforcer` 下次 step 会主动重 inject 新 plan head**(因为 hash 变了)。
5. **Log amendment**:`progress.md` 加一段:
   ```
   [amend] <type> at <ts> by <actor> reason:<一句话>
        sections: <Phase-1.Section-list>
        hash:     <新 attestation hash, truncated 8 chars>
        affected: <slice-id-1, slice-id-2 ...>
   ```
   这是事后 audit"为什么 Spec 改了"的唯一线索。

> **Honest tier limits** 同样适用:`attest-plan.sh` 在 OpenCode 上是软校验(advise),不能硬阻断 Write/Edit。但 pwf `pwf-enforcer` 插件会在下次 system prompt transform 时**自动用新 hash 替换 plan head** —— 这是 Tier 1 hook 的等价行为。

#### 不允许的捷径

- ❌ 跳过 § 5.5 amend、直接告知 Phase 3 "改一下 field 名吧" → 写代码用旧字段名,attest 失效,review-work 必红
- ❌ amend 时只改 Spec 文字,不动 slice 拓扑 → Phase 3 后端仍引用旧字段名
- ❌ amend 后不 re-attest → hash 不变 → pwf-enforcer 仍 inject 旧计划 → session 上下文分裂
- ❌ amend 过程不写 `[amend]` 段 → 事后 audit 无线索

### 6. Get user confirmation (single approval)

> **Note on re-approval**:初次 Spec 已确认后,**日常 amend 不需要再走"用户全量批准"** —— 用户已经在来源(直接说"改成 X")给了批准,§ 5.5 amend 在 `progress.md` 留日志即可。仅当 amend 同时触发了 § 5 整段重写、attest 重置、或 Phase 0 WHY 变更时,才需要再次"用户全量批准"。

Show the Spec to the user. Ask once: confirm or modify. **No re-approval in later phases** — downstream phases (incremental-implementation, etc.) follow the attested Spec.

```
Spec written into task_plan.md Phase 1 + attested.
Please review and confirm or request changes. After approval,
hand off to incremental-implementation for vertical slicing.
```

The user is the contract holder — not you.

## Common Rationalizations

| Excuse | Reality |
|---|---|
| "Spec 太重,直接写代码更快" | Spec 省的是 debug 时间,不是写代码时间。没 spec 的代码 90% 要返工。 |
| "用户没要求 spec" | 用户没拒绝 spec。提出 spec 跟用户对齐,才是真正的"快"。 |
| "我心里清楚就行" | 心里的不算交付物,也不在 attestation 保护范围内。 |
| "这是个 trivial 改动" | 跨 3 文件的改动不 trivial。Trivial 改动不需要 spec 也不需要这个 skill。 |
| "spec 写完用户还要看,慢" | 用户看 spec 5 分钟,你看错重写 50 分钟,这是杠杆。 |
| "Plan 不是已经覆盖 spec 了吗" | Plan 是"分几步做",spec 是"做完长什么样"。两者正交。 |
| "把 Spec 写到独立文件更整洁" | 破坏 pwf attestation 链;`task_plan.md` 是 source of truth。 |

## Red Flags

- Agent 跳过 spec 直接写代码
- Spec 写得太抽象(没具体验收标准 / 没具体命令)
- Spec 留"TBD"或空白字段
- Spec 没 attestation
- Spec 写完没给用户看就开始 Phase 2
- Spec 里出现代码片段(spec 描述"做什么",不描述"怎么做")
- **Spec 写到独立文件**(违反唯一落点规则)
- **承诺 PreToolUse / Stop 能硬阻断**(OpenCode Tier 3 是软约束)

## Verification

Before proceeding to Phase 2, confirm:
- [ ] `task_plan.md` Phase 1 section complete (no TBD)
- [ ] Phase 0 (Design from brainstorming) preserved above Phase 1
- [ ] `scripts/attest-plan.sh` exited 0, hash recorded (advisory on OpenCode)
- [ ] User has reviewed the Spec and confirmed (single approval, no repeats later)
- [ ] At least 3 concrete acceptance criteria listed
- [ ] At least 1 build / test / lint command listed (real, runnable)
- [ ] 若 Phase 3 之后做过 amend:每次 amend 都重新跑了 `attest-plan.sh` 且新 hash 写入 attestation 文件 + `progress.md` 含完整 `[amend]` 段(含 sections / hash / affected 字段)

## pwf Integration

Maps to `task_plan.md` **Phase 1: Spec**. The Spec lives inside `task_plan.md`, not a separate file — this keeps attestation simple.

| pwf hook | Effect on OpenCode (Tier 3) |
|---|---|
| `UserPromptSubmit` (plan head inject) | ✅ via `experimental.chat.system.transform` (real) |
| `PreToolUse` (Write/Edit gate) | ⚠️ advisory only — hash check warns, doesn't block |
| `PreCompact` (plan flush) | ✅ via `experimental.session.compacting` (real hard inject — killer feature) |
| `Stop` (block incomplete) | ❌ notify-only on OpenCode |

See [pwf-integration.md](../../pwf-integration.md) for the full phase map.

## Related Skills

- Predecessor: [`brainstorming`](~/.agents/skills/brainstorming/SKILL.md) — Design + first approval
- Successor: [`incremental-implementation`](~/.agents/skills/incremental-implementation/SKILL.md) — vertical slicing
- Companion: [`pwf-enforcer`](~/.agents/skills/pwf-enforcer/SKILL.md) — hard-enforce PWF on OpenCode
