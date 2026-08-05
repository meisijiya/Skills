# meisijiya-phase-checkpoint — Design Spec (DRAFT,待 user 批准)

> **状态**:Design 草案。skill 本体尚未写。批准后 → 进 RED-GREEN-REFACTOR(`writing-skills` 路径)。
>
> **依赖**:本文档引用 [`phase-vocabulary.md`](phase-vocabulary.md) 的 11 phase 编号;**与 [`meisijiya-handoff`](handoff-design-spec.md) 互补不替代**——handoff 负责"写 doc"(user-driven,`disable-model-invocation: true`),本 skill 负责"通知 phase 边界"(agent-driven,无 `disable-model-invocation`)。
>
> **触发对话**:user 在 2026-08-05 提问"phase 边界自动 prompt 是否可行" + 明确认可分层设计("agent 通知 / user 决定 / 写 doc 由 handoff skill")。

---

## 1. 为什么需要这个 skill

### 1.1 gap(meisijiya-handoff 单独存在的局限)

meisijiya-handoff skill 已 ship(commit `91e824b` + 7 个 follow-up),提供 cross-session checkpoint 协议。但设计上是 `disable-model-invocation: true` 强制 user-triggered——**user 必须自己意识到 phase 边界 + 主动 `/handoff`**。

实际 gap:
- user 写 phase 工作时不会主动想"该切 session 了" → context 撑到 80%+ → OMO 同 session compaction 触发(不是 handoff)
- user 多个 phase 累积后注意力漂移 → 忘了 `/handoff` → 失去 cross-person / cross-day 续接能力
- skill 体系不替 user 做"什么时候该切 session"的判断(也不应该——accountability 在 user)

### 1.2 分层解决方案(2 个 skill 互补)

| 层 | skill | 触发模式 | 职责 |
|---|---|---|---|
| **通知层** | `meisijiya-phase-checkpoint` | **agent-driven**(无 `disable-model-invocation`) | 检测 phase 边界,soft-prompt user "Phase N 完成。要 /handoff 吗?" |
| **契约层** | `meisijiya-handoff` | **user-driven**(`disable-model-invocation: true`) | user 显式触发后写 `.omo/handoff/<slug>-<date>.md` |

**关键边界**:通知层**永远不替 user 写 handoff doc**;只是提示"你可以考虑切 session"。写 doc 这一动作永远 user 显式触发——保持 accountability 与 `disable-model-invocation` 政策一致性。

### 1.3 与"auto agent invoke handoff"方案的对比

| 维度 | auto agent invoke handoff | 本方案(soft-prompt + user-driven handoff) |
|---|---|---|
| Accountability | 责任分散 | user 仍是 session 边界决策者 |
| Context 判断 | agent 只能数 token%,不知 user 状态 | user 知道自己的多任务/疲劳/OK |
| Anti-AI-slop | 每 phase 写一次 → .omo/handoff/ 累积噪音 | 仅在 user 决定时写,doc 数量最小 |
| Cognitive ritual | autopilot | `/handoff` 是 deliberate pause point |
| disable-model-invocation | 政策被绕过(agent 触发写) | 写 doc 这一步仍 user-triggered |
| Anti-forgotten | ✅ agent 不忘 | ⚠️ user 可能忘(soft-prompt 部分缓解) |

**结论**:soft-prompt 方案取"通知 + 不替决策"的中道,既帮 user 不忘,又保持 accountability 与 policy 一致。

---

## 2. Goals / Non-goals

### 2.1 Goals(本 skill 必须做到)

1. **Phase 边界自动检测**:agent 读 `.omo/plans/<slug>.md`,识别当前 phase 与 phase N acceptance criteria 状态
2. **Soft-prompt,not write**:检测到 phase 完成时,emit 一句 "Phase N 完成" 通知 + 询问 user 决策(继续 / `/handoff` / 走 notepad);**不写任何文件**
3. **不打扰 mid-phase 工作**:仅在"phase 整体完成"时 prompt,不打扰 mid-slice / mid-iteration 工作
4. **不替 user 决策**:3 选项(user 选其一)— agent 严格遵守 user 决策,即使选"继续"也不二次 prompt
5. **可与 handoff skill 串联**:prompt 文案引用 `/handoff` slash 命令,user 直接接续
6. **计划有 plan-scoped**:仅在 `.omo/plans/<slug>.md` 存在时启动;无 plan → 跳过
7. **Phase 词汇表引用**:prompt 中的 phase 编号与 [`phase-vocabulary.md`](phase-vocabulary.md) 一致;Phase 7 撤出主流程的提醒也嵌入

### 2.2 Non-goals(本 skill **不做** 什么)

- ❌ **不写 handoff doc** — 那是 handoff skill 的事
- ❌ **不替 user 切 session** — 只 prompt
- ❌ **不强制 mid-phase 也 prompt** — 必须 phase 整体完成
- ❌ **不替 user 判定 phase 完成度** — agent 读 plan acceptance criteria 自动化判定,但 plan 是 user 写的(user 仍是 phase 完成度的最终决策者)
- ❌ **不替代 brainstorming 的 HARD-GATE** — Phase 0 Design 仍由 brainstorming skill 管(其本身是 hard-gate pre-design exploration,不是 phase-completion 通知)
- ❌ **不修改 plan / spec** — plan 与 spec 由 user 在 normal flow 维护
- ❌ **notepad 仅选 3 时 append-only 1 行** — 写到 `.omo/notepads/<slug>/decisions.md` 一行决策记录(per Process §7);任何超出 1 行的 notepad 写入、修改 plan/spec、写 handoff doc 都是越权
- ❌ **不做 plan-scoped fallback** — 无 plan 时直接跳过;handoff 需求由 handoff skill 自己的 fallback 流程处理(per handoff skill §1 ask user confirm fallback)

---

## 3. frontmatter 设计

```yaml
---
name: meisijiya-phase-checkpoint
description: "Use when the agent detects a phase boundary in .omo/plans/<slug>.md — soft-prompt user with 'Phase N 完成,要 /handoff 吗?还是继续?' notification. NOT for mid-phase work (mid-slice / mid-iteration), NOT for writing handoff doc (that's meisijiya-handoff), NOT for forcing user to split (this is notification, not auto-action)."
argument-hint: "<plan-slug> <completed-phase-number>(可选;agent 默认从 .omo/plans/<slug>.md 推断)"
allowed-tools: "Read Bash Glob Grep"
# 注意: 无 disable-model-invocation — agent 应在 phase 完成时主动 invoke
# 但 description 含硬触发词 "phase boundary" + 硬排除词 "NOT for mid-phase" 让 agent 仅在合适时机调用
---
```

**关键决策**:

- **不写 `disable-model-invocation: true`** — 与 handoff skill 的硬契约分层:本 skill 是通知层(agent-driven),handoff 是契约层(user-driven)
- **`allowed-tools` 只读 + Bash** — 不写文件(Bash 仅用于 `test` / `find` 检查),不改任何状态
- **`argument-hint` 可选** — agent 默认从 plan 推断 phase;user 显式提供 phase 时优先用

---

## 4. Process(7 步)

### 1. 校验 plan-scoped

```bash
test -f .omo/plans/<slug>.md || exit 0  # 无 plan → 静默跳过(per Non-goal)
```

### 2. 读 plan 识别当前 phase 与 acceptance criteria

读 `.omo/plans/<slug>.md`,提取:
- 当前 phase 编号(从 Phase N 段标题)
- 该 phase 的 acceptance criteria 列表(`- [ ] <criterion>` 格式)
- 哪些已勾选(`[x]`)、哪些未勾选(`[ ]`)

### 3. 判定 phase 完成度

**主判定**:`Phase N 段所有 acceptance criteria 已勾选`(`- [x]`)。**唯一可靠信号**:plan 是 user 写的权威进度源。

**软校验(可选,不是 hard gate)**:`git log -n 5` 检查最近 commit 是否明显在改 N+1 工作(如 commit message 含 N+1 phase 关键词 / 改了 N+1 段的关联文件)。若明显在改 → 视为 N+1 已开始,不 prompt。**不要把这个软校验当 hard AND**:commit message 无 phase 标记时无法可靠判断归属,以 criteria 为准。

**Phase 段无 `- [ ]` 结构适配**:某些 phase(Phase 3 ticket DAG / Phase 0 Design 用户批准 / Phase 5 异常分支)的 plan 段可能无 `- [ ]` checkbox 形态。**若 phase 段无 `- [ ]` 结构 → 跳过该 phase 的自动判定,不 prompt**(避免误报)。这些 phase 的完成态由 user 显式判断。

**避免 false positive**:phase 内部有 sub-task(Phase 3 slices),不应每 sub-task 完成 prompt;只在"phase 整体 acceptance criteria 全部满足"时 prompt。"criteria 全勾但工作没真做完" 风险可接受(user 选 "继续" 兜底)。

### 4. 软提示 soft-prompt

若 phase 完成,**emit verbatim 三选一**(不写文件):

> **Phase <N> 完成**(所有 acceptance criteria 已勾选)。
>
> 三选一:
>
> 1. `/handoff` — 写 cross-session checkpoint(适合:context 撑不住 / 跨人交接 / 跨天续接)
> 2. **继续** — 在当前 session 推进 Phase <N+1>(适合:context 健康 / 还要做几件事)
> 3. **走 notepad** — 暂存当前进度但不切 session(适合:小暂停 / 中断)

> 若不确定,默认选 2(继续)。

### 5. 等 user 决策

**严格不动手**:
- user 选 1 → 提示 user 手动 `/handoff`(handoff skill 接管,user-driven)
- user 选 2 → 继续推进 Phase <N+1>
- user 选 3 → 写入 `.omo/notepads/<slug>/decisions.md` 一行记录 + 不切 session

### 6. 二次 prompt 红线

**user 选 2(继续)后,本 phase-checkpoint skill 在该 phase 不再 prompt**。即使后续 phase 全部完成前又有 sub-task,本 phase 阶段内不打扰。下次 prompt 必须等 Phase <N+1> 完成。

**避免反复打扰**:user 已决策"继续",phase-checkpoint 信任 user 判断,不再二次确认(等同于 handoff skill 不替 user 写 doc 的语义)。

### 7. 文档化决策到 notepad(选 3 时)

```markdown
## Phase <N> → notepad @ <ISO-8601>

- user 选 3(走 notepad)
- 当前 Phase <N+1> 暂存,不切 session
- 恢复方式: 读本 notepad 段,继续 Phase <N+1>
```

写 `.omo/notepads/<slug>/decisions.md`,append-only。

---

## 5. Common Rationalizations(6 行)

| 借口 | 反驳 |
|---|---|
| "Phase 3 slices 全部完成就该 prompt" | phase-checkpoint 只对**phase 整体**完成 prompt;mid-slice completion 不打扰(Non-goal #3) |
| "User 没说 /handoff 我也帮写一份" | 本 skill 不写 handoff doc;那是 handoff skill 的契约层,user-driven;写 = 越权 |
| "Context 50% 也提示一下吧,安全" | 中段提示是噪音;phase 边界才有意义;50% 提示 → 每次都问 user 烦 → user 关闭 skill |
| "Plan 没 acceptance criteria,我自己判定" | 无 criteria 的 plan = phase 不清晰;agent 不替 user 判定完成度;提示 user 写 acceptance criteria 而非 prompt |
| "User 选了继续,过会再提醒一下" | 二次 prompt 红线(Process §6);user 已决策,信任其判断;反复提示 = 替代决策 |
| "Phase 0 / Phase 1.5 这些不重要,跳过" | phase-checkpoint 提示 phase-vocabulary.md §2 表中所有 11 个 phase;Phase 7 撤出主流程按 §3.4 处理 |

---

## 6. Red Flags

- 在 mid-slice / mid-iteration 时 prompt — `grep -c '\- \[x\]' .omo/plans/<slug>.md` 应等于 phase 段 acceptance criteria 总数才算完成
- prompt 后未等 user 决策就继续推进 — 必须等 user 选 1/2/3
- 写 handoff doc / plan / spec — 严格越权(契约 §10);phase-checkpoint 仅 emit prompt,最多在选 3 时 append-only 1 行到 `.omo/notepads/<slug>/decisions.md`(per Non-goal #4)
- notepad 超写 — 选 3 时必须只 1 行 append-only,任何超出(learnings / issues / 进度记录)都是越权
- 预告 prompt — N+1 未完成就"提醒 user 准备 /handoff" 是 §6 红线的变体绕过
- prompt 夹带 agent 自身建议(如"我建议你 /handoff,context 快满了")— 违反 verbatim 文案,滑向替 user 判 context
- 二次 prompt(user 已选"继续"后再次提醒)— 违反 Process §6
- 对无 plan 状态报错 / 警告 — 静默跳过(per Non-goal)
- prompt 中 phase 编号与 `.omo/plans/<slug>.md` 不一致 — 必须从 plan 读取核对

---

## 7. Verification

- [ ] `.omo/plans/<slug>.md` 存在(否则跳过)
- [ ] 当前 phase 段所有 acceptance criteria 已勾选
- [ ] 最近 commit 不在改下一 phase
- [ ] emit verbatim 三选一 prompt,不带任何写文件动作
- [ ] user 选 1 → 提示 `/handoff`,**不替 user 写 handoff**
- [ ] user 选 2 → 继续推进,不再二次 prompt
- [ ] user 选 3 → 写 `.omo/notepads/<slug>/decisions.md` 一行
- [ ] prompt 中的 phase 编号与 plan 实际一致
- [ ] 不在 mid-phase 时误触发

---

## 8. eval case 设计(RED → GREEN → REFACTOR 第一步)

### 8.1 3 positive triggers

```json
[
  {
    "input": "Phase 3 的 slice 1-5 全部完成,acceptance criteria 都勾选了",
    "expected_skill": "meisijiya-phase-checkpoint",
    "reason": "Phase 整体完成 → 触发 soft-prompt"
  },
  {
    "input": "我刚把 Phase 4 verification 的 7 个 checkbox 都勾了,verification 看起来过了",
    "expected_skill": "meisijiya-phase-checkpoint",
    "reason": "Phase 4 完成 + acceptance criteria 全勾 → soft-prompt"
  },
  {
    "input": "Phase 1 spec 已经 attestation 了(.omo/plans/<slug>.md Phase 1 段全 [x])",
    "expected_skill": "meisijiya-phase-checkpoint",
    "reason": "Phase 1 完成 → soft-prompt,user 选 /handoff 或继续进 Phase 3"
  }
]
```

### 8.2 3 negative triggers

```json
[
  {
    "input": "我刚完成 Phase 3 slice 3,继续 slice 4",
    "expected_no_skill": true,
    "reason": "mid-phase(Phase 3 内 sub-task),不打扰 user"
  },
  {
    "input": "我想 /handoff 一下,从 Phase 3 到 Phase 4",
    "expected_skill": "meisijiya-handoff",
    "reason": "user 主动触发 handoff 写 doc → 走 handoff skill 而非 phase-checkpoint"
  },
  {
    "input": ".omo/plans/<slug>.md 不存在,我在做新项目",
    "expected_no_skill": true,
    "reason": "无 plan → 静默跳过,user 应走 brainstorming 先建 Phase 0 Design"
  }
]
```

### 8.3 ≥ 1 behavioral scenario

```json
[
  {
    "scenario": "Agent 检测到 Phase 3 acceptance criteria 全勾选,emit 三选一 prompt",
    "expected_behavior": [
      "Agent reads .omo/plans/<slug>.md Phase 3 section,确认所有 - [x]",
      "Agent verifies latest commit is Phase 3 related (not Phase 4 work)",
      "Agent emits verbatim 三选一: /handoff / 继续 / 走 notepad",
      "Agent does NOT write handoff doc, does NOT modify plan",
      "Agent waits for user decision; does NOT proceed automatically"
    ]
  },
  {
    "scenario": "User 在 prompt 后选 2(继续),agent 进入 Phase 4 后又完成一些 sub-task",
    "expected_behavior": [
      "Agent does NOT re-prompt during Phase 4 work",
      "Phase 4 整体 acceptance criteria 全勾后才再触发一次 prompt"
    ]
  }
]
```

---

## 9. dispatcher 集成(轻量)

**不改** `using-meisijiya-skills/SKILL.md` Process 的 step 1-8。原因:
- phase-checkpoint 是 agent-driven,无固定触发时机
- dispatcher 不应替 agent 决定"什么时候该 prompt"
- agent 的 normal planning flow(读 plan + 推进 phase)自然会调用

**只在 priority-table.md Reading order 加一行**:

```markdown
6. (informational) `meisijiya-phase-checkpoint` 由 agent 在 phase 完成时主动调用,user 决策后路由到 `meisijiya-handoff`(选 1)或 normal flow(选 2/3)
```

不进入"Consider first"列——phase-checkpoint 是 agent 自己判定的时机,不是 dispatcher 路由的输入。

---

## 10. 与 meisijiya-handoff 的契约

| 维度 | handoff skill(契约层) | phase-checkpoint(通知层) |
|---|---|---|
| `disable-model-invocation` | **true**(user-driven) | **false**(agent-driven) |
| 写文件 | ✅ `.omo/handoff/<slug>-<date>.md` | ❌(除选 3 写 notepad) |
| 跨 session 续接 | ✅ 提供 doc 协议 | ❌ |
| Phase 边界通知 | ❌ | ✅ |
| 触发条件 | user `/handoff` slash 命令 | agent 检测 phase 完成 |
| accountability | user 完全负责 | user 完全负责(决策),agent 仅通知 |

**严格边界**:
- phase-checkpoint 选 1 时**只提示** `/handoff`,**不直接 invoke** handoff skill 写 doc
- phase-checkpoint 选 2/3 时**不调用** handoff skill
- 两者 plugin/dispatcher 互不耦合,各自按 description 触发

---

## 11. anti-pattern

| 反模式 | 后果 | 检测 |
|---|---|---|
| agent 在 mid-slice 完成时 prompt | user 被打断,选 "继续" 累积噪音 | `grep -c '\- \[x\]' .omo/plans/<slug>.md` 必须 == acceptance criteria 总数 |
| agent 替 user 写 handoff doc | 违反 handoff skill 的 `disable-model-invocation` 政策 | phase-checkpoint SKILL.md Process 明确不写 handoff |
| agent 二次 prompt(user 已选继续) | 替代 user 决策 | Process §6 明确红线 |
| agent 对无 plan 状态报错 | 噪声,破坏 dispatch flow | Process §1 静默跳过 |
| prompt 文案不带 phase 编号 | user 不知道哪个 phase | verification 段强制 |
| agent 在 prompt 中替 user 写 handoff doc | 违反 accountability + disable-model-invocation | §10 契约禁止 |

---

## 12. 不做的事(再次明确)

- ❌ **不写 handoff doc** — handoff skill 唯一职责
- ❌ **不创建新 plugin** — phase-checkpoint 是 SKILL.md agent-driven,无需 plugin 层
- ❌ **不改 dispatcher Process step 1-8** — phase-checkpoint 是 informational,不进 routing
- ❌ **不替代 brainstorming HARD-GATE** — Phase 0 Design 仍由 brainstorming 管
- ❌ **不修改 plan / spec / handoff doc** — 只读 plan + emit prompt + (选 3 时)写 notepad
- ❌ **不做 plan-scoped fallback** — 无 plan 静默跳过

---

## 13. 实现 checklist(批准后)

按顺序执行:

1. [ ] 跑 §8 的 eval case baseline(RED)— 用 deep agent 模拟 3+3+1 场景,看 agent **没** skill 时怎么乱写
2. [ ] 写 `skills/extra/meisijiya-phase-checkpoint/SKILL.md`(GREEN)— frontmatter + body 严格按 §3 + §4
3. [ ] 写 `evals/cases/meisijiya-phase-checkpoint.json`(3+3+1)— 跟 §8 一致(路径在仓库根,validate-skills.sh 第 208 行 `${skill_name}.json` 固定从 `evals/cases/` 读取,**不能放 skill 子目录**)
4. [ ] 改 `.claude-plugin/marketplace.json`(`meisijiya-domain` group +1,domain 12→13)
5. [ ] 改 `skills/extra/README.md`(计数 12→13)+ `AGENTS.md`(同)+ `README.md`(同)+ `skill-anatomy.md`(description 格式保持 1024 字符内)
6. [ ] 改 `skills/core/using-meisijiya-skills/references/priority-table.md` Reading order §9(informational 行)
7. [ ] 跑 `validate-skills.sh` + `check-marketplace.sh` + `check-doc-drift.sh` — 三项全 PASS
8. [ ] 跑 §8 eval case(GREEN)— agent **有** skill 后,行为与 §8.3 expected_behavior 一致
9. [ ] 7-lane review(a-architecture / b-omo-compat / c-state / d-eval / e-migration / f-security / g-yagni)— 至少 5 lane APPROVE 才算 close

---

## 14. 一句话总结

> **`meisijiya-phase-checkpoint` 是 meisijiya-handoff 的通知层互补**:agent-driven 软提示 phase 边界,user-driven 决策,写 doc 由 handoff skill 接管。两层分工保持 accountability(`/handoff` 仍是 deliberate user choice)+ 缓解 user 遗忘(soft-prompt 提醒)+ 不破 disable-model-invocation 政策(写 doc 这一步永远 user 触发)。批准本 spec 后进入 RED-GREEN-REFACTOR,预计 9 步落地。