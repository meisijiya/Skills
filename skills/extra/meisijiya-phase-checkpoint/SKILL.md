---
name: meisijiya-phase-checkpoint
description: "Use when the agent detects a phase boundary in `.omo/plans/<slug>.md` — soft-prompt user with 'Phase N 完成,要 /handoff 吗?还是继续?' notification. NOT for mid-phase work (mid-slice / mid-iteration), NOT for writing handoff doc (that's meisijiya-handoff), NOT for forcing user to split (this is notification, not auto-action)."
argument-hint: "<plan-slug> <completed-phase-number>(可选;agent 默认从 .omo/plans/<slug>.md 推断)"
allowed-tools: "Read Bash Glob Grep Write"
---

# meisijiya-phase-checkpoint

## Overview

`meisijiya-handoff` 的**通知层互补**:agent 在 phase 完成时主动 emit 软提示("Phase N 完成。三选一: /handoff / 继续 / 走 notepad")。**永远不替 user 写 handoff doc**;写 doc 由 handoff skill 接管(user-driven,`disable-model-invocation: true`)。本 skill 是 agent-driven,允许 model 在合适时机 invoke。

与 `meisijiya-handoff` 的契约分层:
- **本 skill**(通知层):agent-driven,emit 软提示,user 决策
- **handoff skill**(契约层):user-driven,写 `.omo/handoff/<slug>-<date>.md`

两层分工保持 accountability(`/handoff` 仍是 deliberate user choice)+ 缓解 user 遗忘(soft-prompt 提醒)+ 不破 `disable-model-invocation` 政策。

## When to Use

**Use when:**
- 当前 phase 的 acceptance criteria 全部满足(从 `.omo/plans/<slug>.md` 读出)
- 最近 commit 未明显在改下一 phase
- phase 段有 `- [ ]` 结构(否则跳过该 phase,见 §4 Process 3)
- 用户可能在 phase 边界未意识到

**NOT for:**
- **mid-slice / mid-iteration 工作** — phase 内部 sub-task 完成不打扰,仅 phase 整体 acceptance 全满足时 prompt
- **写 handoff doc** — 那是 [`meisijiya-handoff`](~/.agents/skills/meisijiya-handoff/SKILL.md) 的事(user-driven,`disable-model-invocation: true`)
- **user 显式触发 `/handoff` 或请求写 handoff doc**(含 "帮我 handoff 一下" 等措辞)— **直接路由 [`meisijiya-handoff`](~/.agents/skills/meisijiya-handoff/SKILL.md) skill**,phase-checkpoint 不介入(不 emit 边界 prompt)
- **替 user 切 session** — 只 emit 提示,user 决定
- **Plan 不存在状态** — 静默跳过(per §4 Process step 1)
- **Phase 0 Design 的"用户批准"判定** — Phase 0 由 [`brainstorming`](~/.agents/skills/brainstorming/SKILL.md) 的 HARD-GATE 管,不是 phase-completion 通知
- **ad-hoc work 跨 session** — 走 notepad 而非 phase-checkpoint(per handoff skill NOT-for rule)

## Process

### 1. 校验 plan-scoped

```bash
test -f .omo/plans/<slug>.md || exit 0  # 无 plan → 静默跳过
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
> 3. **走 notepad** — 记录暂停点到 `.omo/notepads/<slug>/decisions.md`(适合:小暂停 / 中断)
>
> 若不确定,默认选 2(继续)。

### 5. 等 user 决策

**严格不动手**:
- user 选 1 → 提示 user 手动 `/handoff`(handoff skill 接管,**user-driven,禁止替写**)
- user 选 2 → 继续推进 Phase <N+1>;**不再二次 prompt**
- user 选 3 → 写 `.omo/notepads/<slug>/decisions.md` 一段记录(per §7 step 7),不切 session

### 6. 二次 prompt 红线

user 选 2 后,本 phase 不再 prompt;即使后续 phase 全部完成前又有 sub-task,本 phase 阶段内不打扰。下次 prompt 必须等 Phase <N+1> 完成。

**绕过点**:agent 在 N+1 的 sub-task 完成时若误判全部完成 → Process §3 主判定本身防住(mid-phase criteria 未全勾)。

### 7. 文档化决策到 notepad(选 3 时)

```markdown
## Phase <N> → notepad @ <ISO-8601>

- user 选 3(走 notepad)
- 当前 Phase <N+1> 暂存,不切 session
- 恢复方式: 读本 notepad 段,继续 Phase <N+1>
```

写 `.omo/notepads/<slug>/decisions.md`,append-only。

**写完后向 user 确认续接状态**:输出一行明示,如 "已记录到 `.omo/notepads/<slug>/decisions.md`,继续当前 session(不切 session)。Phase <N+1> 推进时读本 notepad 段即可。" → 关闭 user 的 "切 session 没切" 不确定感。

## Common Rationalizations

| 借口 | 反驳 |
|---|---|
| "Phase 3 slices 全部完成就该 prompt" | phase-checkpoint 只对**phase 整体**完成 prompt;mid-slice completion 不打扰(Non-goal) |
| "User 没说 /handoff 我也帮写一份" | 本 skill 不写 handoff doc;那是 handoff skill 的契约层,user-driven;写 = 越权(见 omo Integration 段契约分层) |
| "Context 50% 也提示一下吧,安全" | 中段提示是噪音;phase 边界才有意义;50% 提示 → 每次都问 user 烦 → user 关闭 skill |
| "Plan 没 acceptance criteria,我自己判定" | 无 criteria 的 plan = phase 不清晰;agent 不替 user 判定完成度;提示 user 写 acceptance criteria 而非 prompt |
| "User 选了继续,过会再提醒一下" | 二次 prompt 红线(§6);user 已决策,信任其判断;反复提示 = 替代决策 |
| "Phase 0 / Phase 1.5 这些不重要,跳过" | phase-checkpoint 提示 [`phase-vocabulary`](../../../docs/phase-vocabulary.md) §2 表中所有 11 个 phase;Phase 7 撤出主流程按 §3.4 处理 |

## Red Flags

- 在 mid-slice / mid-iteration 时 prompt — phase-scoped 计数 `awk '/^## Phase N:/{f=1;next}/^## Phase/{if(f)exit} f' .omo/plans/<slug>.md | grep -c '\- \[x\]'` 应等于 phase 段 acceptance criteria 总数才算完成(全文件 `grep -c '\- \[x\]'` 会跨 phase 误报)
- prompt 后未等 user 决策就继续推进 — 必须等 user 选 1/2/3
- 写 handoff doc / plan / spec — 严格越权(见 omo Integration 段契约分层);phase-checkpoint 仅 emit prompt,最多在选 3 时 append-only 1 段到 `.omo/notepads/<slug>/decisions.md`(per Non-goal)
- notepad 超写 — 选 3 时必须只 1 段 append-only(4 行模板:header + 3 bullets),任何超出(learnings / issues / 进度记录)都是越权
- 预告 prompt — N+1 未完成就"提醒 user 准备 /handoff" 是 §6 红线的变体绕过
- prompt 夹带 agent 自身建议(如"我建议你 /handoff,context 快满了")— 违反 verbatim 文案,滑向替 user 判 context
- 二次 prompt(user 已选"继续"后再次提醒)— 违反 Process §6
- 对无 plan 状态报错 / 警告 — 静默跳过(per Non-goal)
- prompt 中 phase 编号与 `.omo/plans/<slug>.md` 不一致 — 必须从 plan 读取核对
- phase 段无 `- [ ]` 结构却 prompt — Process §3 必须跳过非 checkbox 形态的 phase
- user 显式 `/handoff` 时仍 emit phase-checkpoint prompt — 双重动作;user-driven handoff 契约层优先,phase-checkpoint 应完全跳过

## Verification

- [ ] `.omo/plans/<slug>.md` 存在(否则跳过,静默)
- [ ] 当前 phase 段有 `- [ ]` 结构(否则跳过)
- [ ] 当前 phase 段所有 acceptance criteria 已勾选(phase-scoped 计数,非全文件 grep — 跨 phase 的 `[x]` 会误报完成)
- [ ] 最近 commit 未明显在改下一 phase(可选软校验)
- [ ] emit verbatim 三选一 prompt,不带任何写文件动作(选 3 写 notepad 之前)
- [ ] user 选 1 → 提示 `/handoff`,**不替 user 写 handoff**
- [ ] user 选 2 → 继续推进,不再二次 prompt
- [ ] user 选 3 → 写 `.omo/notepads/<slug>/decisions.md` 1 段 + 已向 user 确认 "继续当前 session"
- [ ] prompt 中的 phase 编号与 plan 实际一致
- [ ] 不在 mid-phase 时误触发
- [ ] user 显式 `/handoff` 时直接路由 `meisijiya-handoff`,**不 emit phase-checkpoint prompt**

## omo Integration

**Dispatcher 集成**:`skills/core/using-meisijiya-skills/references/priority-table.md` Reading order 加一行 informational(不进入 routing)— phase-checkpoint 是 agent 判定时机,不是 dispatcher 路由输入。

**双 skill 仲裁**:Phase 4 verification 完成瞬间,`verification-before-completion`(priority-table 中"About to claim done" 行)与 phase-checkpoint 可能同时匹配。优先级:verification-before-completion 的 gate 优先(它是 evidence-based completion claim);phase-checkpoint 在 gate 通过后 emit 通知(让 user 决定是否 /handoff)。

**user 显式 `/handoff` 触发 handoff skill**(user-driven 契约层)时:phase-checkpoint **完全跳过** — 不 emit 三选一 prompt、不二次判定 phase 状态、直接路由 handoff skill 写 doc。phase-checkpoint 仅在 user **未主动提出 handoff**、phase 整体 acceptance 全满足时触发。这是双 skill 同时 match 时的仲裁规则。

**与 `meisijiya-handoff` 互补**:handoff skill 写 doc(user-driven,`disable-model-invocation: true`);phase-checkpoint 仅通知边界(agent-driven,无 `disable-model-invocation`)。选 1 时 phase-checkpoint **只提示** user 手动 `/handoff`,**不直接 invoke** handoff skill 写 doc。后续 user 授权施压("好,你来写")由 handoff 自身 Rationalizations 表(line 158)防线处理。

**Phase 词汇表**:prompt 中的 phase 编号必须与 [`docs/phase-vocabulary.md`](../../../docs/phase-vocabulary.md) §2 表一致;Phase 7 撤出主流程按 phase-vocabulary §3.4 处理。

**Plugin 不需要改动**:与 handoff skill 一样,phase-checkpoint 是 SKILL.md agent-driven,通过 model 的 description 自然触发,无需 `.opencode/plugins/` 新 hook。
