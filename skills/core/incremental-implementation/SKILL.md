---
name: incremental-implementation
description: "Decomposes a task into vertical slices — each slice is independently committable, testable, and rollback-safe. Under omo, delegates slice todo tracking to atlas agent and uses git-master skill for atomic commits. Use when any change touches more than one file, when the task has 3+ steps, or when refactoring/migrating existing code."
allowed-tools: "Read Edit Bash Glob Grep"
---

# incremental-implementation

## Overview

纵向切片 —— 每个 slice 独立可交付、可回滚、可单独 ship。横向分层(一口气全写完)是大忌,因为 debug 时找不到边界,rollback 时丢一片,review 时读 1000 行 diff。

Slice 的大小不是越小越好 —— 太碎浪费 commit overhead,太大失去切片价值。经验值:**30~100 行净 diff** 是甜区。

> **职责边界**:
> - **Slice 元数据**:`blockedBy` / `parallel` / `HITL|AFK` / `owner` / `verify` / `status` / `superseded_by` —— 让 OMO `atlas` / `team_task` 能读出真正可以并行的 frontier
> - **审慎 commit**:**任何 commit 都需项目 git 策略授权**;默认不强制每个 slice 自动 commit,只保留"为可回滚而 commit"的语义
> - **后置闭环**:Phase 3 全部完成后,**桥接 OMO 内置 `review-work`**——以全新上下文 5 个并行子代理审 diff 与 spec 对齐;不重复造新审查 skill
> - **中途变更路由**:见 § 9(五档分类 + 状态机 + amend 协议)
> - **回滚审计**:见 § 10(`[rollback]` 日志模板 + 6 态状态机扩展)

## When to Use

**Use when:**
- 任何改动超过 1 个文件
- 任务含 3+ 个步骤
- 重构 / 迁移
- 需要保留 rollback 能力
- 多人协作同一代码库

**NOT for:**
- 单文件改动
- 纯文档 / 配置修改
- 用户明确说"一次性写完"
- 已知 trivial 重命名(用 IDE rename)

## Process

### 1. Decompose into slices

Read `task_plan.md` Phase 3. Slice by **vertical capability**, not by technical layer:

❌ **Wrong (horizontal):**
- Slice 1: Add database schema
- Slice 2: Add API endpoint
- Slice 3: Add UI

Each slice breaks the system end-to-end. After slice 1 the app doesn't work.

✅ **Right (vertical):**
- Slice 1: Add minimal "create user" feature end-to-end (schema + endpoint + minimal UI)
- Slice 2: Add "read user" feature
- Slice 3: Add "update user" feature

Each slice ships a working capability. After slice 1 users can create accounts.

### 2. Size each slice

| Indicator | Target |
|---|---|
| Net diff (added + modified, minus deleted) | 30~100 lines |
| New files per slice | ≤ 3 |
| Touched existing files per slice | ≤ 5 |
| Test files per slice | ≥ 1 |
| Slice atomic commits | 0–1 (commit 时机由 git 策略决定,不强制每 slice commit) |

If a slice exceeds these, decompose further.

### 3. Annotate each slice with metadata

为每条 slice 写一份 OMO `atlas` / `team_task` 能消费的元数据:

| Field | Values | 含义 |
|---|---|---|
| `id` | `slice-<n>-<name>` | 稳定 ID,供 `Blocked by` / reviewer diff 用 |
| `blockedBy` | `[slice-1, ...]` 或 `[]` | 拓扑依赖。**前置 slice 全部 `complete` 才可启动** |
| `parallel` | `true` / `false` | 与 `blockedBy=[]` 的同组 slice 是否可同时执行(配 OMO `team_task`) |
| `HITL\|AFK` | `HITL` 或 `AFK` | HITL = 需人实时问答(设计决策);AFK = agent 可独立跑完(实现)。设计/取舍 slice 标 HITL |
| `owner` | `hephaestus` / `sisyphus-junior` / `omo-team` | 谁来跑 — 简单 AFK slice 委派给 sisyphus-junior 并行;Hephaestus 处理需要依赖上下文的 |
| `verify` | 见 § Verify 列 | `test --X` / `curl` / `smoke` 等可执行命令 |
| `status` | `pending` / `in_progress` / **`complete`** / **`deprecated`** / **`superseded`** | 见 § 9 中途变更路由与 § 10 回滚协议。`deprecated` = 旧实现仍保留但不再演化(用户改主意但旧分支不删);`superseded` = 被另一 slice 取代,必须填 `superseded_by`;`rolled_back` = post-complete rollback,见 § 10.3。OMO `atlas` 排 frontier 时跳过 deprecated / superseded / rolled_back |
| `superseded_by` | `slice-<n>-<name>` 或 `null` | **`status=superseded` 时必填**。指明哪个新 slice 接替此 slice 的 acceptance criteria;progress.md 应同时记录 `[amend] supersedes <old-id>` |

**字段集合的设计目的**:让 OMO `atlas` / `team_task` 能从元数据自动算出真正可并行的 frontier(`blockedBy=[]` 的同组 slice 都满足 → `parallel=true` 即可同时启动);`status + superseded_by` 让作废的 slice 在 frontier 之外被忽略,但 git history 与 progress.md 记录仍可 audit。

**示例表**(含作废状态):

| id | blockedBy | parallel | HITL/AFK | owner | verify | LOC | Tests | Status | superseded_by |
|----|-----------|----------|-----------|-------|--------|-----|-------|--------|----------------|
| slice-1-create-user | [] | ✅ | AFK | sisyphus-junior | pytest tests/test_user_create.py | 67 | ✓ | complete | null |
| slice-2-read-user | [slice-1-create-user] | ❌ | AFK | sisyphus-junior | pytest tests/test_user_read.py | 45 | ✓ | superseded | slice-2b-read-user-v2 |
| slice-2b-read-user-v2 | [slice-1-create-user] | ❌ | AFK | sisyphus-junior | pytest tests/test_user_read_v2.py | 50 | ✓ | in_progress | null |
| slice-3-error-taxonomy | [slice-2b-read-user-v2] | ❌ | HITL | hephaestus | pytest | 30 | ✓ | pending | null |
| slice-old-rest-api | [slice-1-create-user] | ❌ | AFK | sisyphus-junior | pytest tests/test_legacy_api.py | 40 | ✓ | **deprecated** | null |

**HITL slice 的特殊规则**:HITL slice 在执行前后都需要用户确认(对齐 spec 后才能跑、跑完后用户确认交付)。

### 4. Isolate each slice

For slices > 50 lines, use a feature branch or git worktree:

```bash
git worktree add ../project-slice-2 -b feat/slice-2-name
```

This lets you switch context, run tests in isolation, and rollback cleanly.

### 5. Implement + verify per slice

For each slice, follow the loop:
1. **omo**: load `git-master` skill (atomic commits, branch hygiene, rebase surgery)
2. **omo**: dispatch via `atlas` agent or `team_task` per metadata(`parallel=true` 的同组 slice 可同时发)
3. Implement the slice(走 [`test-driven-development`](~/.agents/skills/test-driven-development/SKILL.md) 强制 red→green)
4. Verify the slice ships end-to-end (not just unit tests,跑 metadata 里的 `verify` 命令)
5. **Commit 策略**:默认不自动 commit。仅在以下条件之一满足时由 `git-master` 落地一次原子 commit:
   - 项目有显式 git policy(`AGENTS.md` / 团队约定)
   - slice 满足 rollback drill 中"可独立 revert" 且 > 50 行需要保存 checkpoint
   - 用户在 brainstorm / spec 阶段明确要求每 slice 一个 commit
6. Append to `progress.md`:
   ```
   [slice] <id> → <commit-sha 或 "no-commit"> | <LOC> | verify: <stdout 节选>
   ```

### 6. Rollback drill

Before merging slices, mentally rehearse: "If slice 3 breaks production, can I revert just slice 3?" If no, the slice isn't actually independent — re-decompose.

### 7. After all slices done: hand off to OMO review-work

**桥接到 OMO 内置 `review-work` skill(不再自己造审查 skill)**:

1. Confirm:所有 slice 都已通过 `verify` 字段测试 + `progress.md` 有 `[slice]` 日志
2. Invoke `review-work`(OMO 内置,描述:`Launches 5 parallel background sub-agents`)。传入:`task_plan.md` 全文 + 当前分支 diff (`git diff main...HEAD`)。
3. **关键**:OMO 子代理是新上下文,无本会话历史污染 — 这就是 Matt Pocock "isolated fresh-context automated review" 的实现。
4. review-work 返回 5 份并行报告(goal / constraint / code quality / security / context mining),有 🔴→🟢 一键 fix 流程。
5. 把 🔴 转化为新 slice(via § 1-5 重新 spec + 实现);🟢 走 `verification-before-completion` 出最终结论。

如果该项目不安装 OMO `review-work`,降级为人工 review checklist(见 `verification-before-completion` § Red Flags)。

### 8. For UI-bearing changes: human visual QA

如果 slice 涉及 UI,**`build-gate-visual-review` 只管"代码前的设计对齐"**;真正的"代码后人工 QA + Taste 注入"由你(人)亲自跑:

1. 启动 dev server / build app
2. 手动走完本次 slice 的关键用户路径
3. 用 OMO `visual-qa`(浏览器/Playwright 截图 + 像素 diff)做客观对比;主观 taste 由人判断
4. 不合品味 → 新增 Blocking slice(§ 1-5 重做);合品味 → 走 `verification-before-completion`

### 9. Mid-build requirement changes

需求进入实施阶段后用户说"改成 X" / "其实应该是 Y" / "再加一条 Z"。**禁止假装没听见,继续按 Spec 写** —— 这等于把 Spec 与代码漂移、attest 失真、后续 review-work 必红的循环里。

#### 9.1 Classify the change (5 个类型 → 5 个路由)

| 改动类型 | 例 | 路由 | 副作用 |
|---|---|---|---|
| **Cosmetic** | "字段叫 `name` 改成 `fullName`" / "措辞 / 边界值调整" | 只改 Phase 1 文字;不 amend Spec、不动 slice | 无(attest 不变) |
| **Implementation detail (HOW)** | 换库 / 换算法 / 调实现顺序 | 不动 Spec;改既有 slice 的 `verify` 命令或加新 slice | slice 表更新;**不改** `blockedBy` 拓扑 |
| **Data-shape / API contract (WHAT)** | 加字段 / 改 schema / 改 endpoint 签名 | **重入 Phase 1 Spec**;amend + re-attest;旧 slice 标 `superseded` 由新 slice 替换 | 旧 slice 走 `git revert`(项目 git policy 下)+ 标 `status=superseded` 并填 `superseded_by`;新 slice 入 frontier |
| **Feature re-scope (WHY)** | 用户说"其实我们要做的不是 X,是 Y" | **重入 Phase 0 Brainstorming**;只保留 Phase 0 Design 的设计骨架;再走 § Phase 1 Spec 重写 | 大部分已有 slice 走 `status=superseded` 或 `deprecated`;新设计产出新 Phase 1 Spec |
| **Pure addition (orthogonal)** | "再加一个 Y,不影响已存在的 X" | append 到 Phase 1 Spec(amend + re-attest);**仅在 frontier 末尾追加新 slice**,旧 slice 不动 | frontier 增长;不改既有 `blockedBy` 拓扑 |

#### 9.2 Process for any requirement change

1. **Detect**:用户或 review-work 🔴 报告"需求 / 验收标准变了"。
2. **Classify**:用 § 9.1 的 5 档表对位(只取一行,不许混)。
3. **Halt in-flight slice**:`in_progress` 的 slice 若被 impacted,先停下,不要再 commit,记录当前进度 `progress.md` 加 `[halt] <slice-id> reason:<一句话>`。
4. **Route to the right phase**:
   - Cosmetic / HOW → 不出 Phase 3,仅修改既有 row 或 append row
   - **Data-shape / Pure addition →** invoke [`spec-driven-development`](~/.agents/skills/spec-driven-development/SKILL.md) Step 5.5 Amend + re-attest
   - **WHY changed →** invoke [`brainstorming`](~/.agents/skills/brainstorming/SKILL.md) Phase 0 重新对齐,完成后再走 Phase 1 amend
5. **Deprecate or supersede impacted slices**:用 § 9.3 的状态机更新 `status` + `superseded_by`;OMO `atlas` 自动把它们从 frontier 排除。
6. **Log amendment**:`progress.md` 加一行:
   ```
   [amend] <type> at <ts> by <actor> reason:<一句话>
        sections:  <Phase-1.Section-list, e.g. Acceptance / Test Strategy>
        hash:      <新 attestation hash, truncated 8 chars>
        affected:  <slice-id-1, slice-id-2 ...>
        action:    <deprecate / supersede / append / modify>
        spec:      task_plan.md#Phase-1.Section
   ```
   这是事后 audit"为什么 X 被作废"的唯一线索。`sections` + `hash` 是必备字段:前者定位改动位置,后者证明 hash 真更新(防止"amend 后忘了 attest")。
7. **Re-attest**:`bash scripts/attest-plan.sh`(已在 Step 5.5 描述)。新 hash 记录到 progress.md。**`pwf-enforcer` 插件下次 step 时会主动重 inject 新 plan head**(因为 hash 变了)。
8. **Resume**:**只在新 hash 与新 slice 表上**继续 frontier work。任何 `in_progress` 的旧 slice 必须 halt 并 supersede,绝不允许续写半成品。

#### 9.3 Slice status machine(含 halted 路径)

```
pending  ──► in_progress ──► complete
                │                  │
                │ halted           ├──► deprecated  (需求改但旧实现保留;git 不删)
                ▼                  │
            [halt]+superseded      └──► superseded  (需求改,新 slice 接替;必填 superseded_by)
               (halt 中途
                amendment 是合法
                路径,见 § 9.2 step 3 + 5)
```

**写代码纪律**:

- 禁止 `deprecated` ↔ `superseded` 的来回切换 — deprecated 是"被废弃保留",superseded 是"被替换",方向感不一样。
- 禁止无 `superseded_by` 的 `superseded` slice。
- 旧 slice 即使 `deprecated`,其 `verify` 命令仍应在 CI 通过 = "没坏但不再演化"。如果 verify 失败,先解 verify 再标 deprecated。
- `in_progress` slice 在 § 9.2 step 3 halt 后,只能:
  - 进 `superseded`(若新 slice 接替) — **必须**用 § 9.2 step 3 + step 5 的 [halt]+[amend] 协议,不能直接跳。
  - 退回 `pending`(若变更撤回) — 但这等于放弃已做的工作,通常由 OMO `git stash` 配合。
  - 不要从 `in_progress` 直接进 `complete`(已 halt 的不算完成)。
- 任何 status 变更必须 append 到 `progress.md` 的 `[amend]` 段。

### 10. Rollback protocol

Slice 上线后被判定需要回收时(数据丢失 / 安全洞 / correctness regression / 用户主动撤回 / fix-the-fix 反效果),按本协议收尾。

**注意**:rollback 是 § 9 amend 的姐妹协议 —— § 9 处理"需求变了,spec 与 slice 还没坏";本协议处理"已落地的 slice 必须撤回"。两者状态机独立,但共用 `progress.md` 日志约定。

#### 10.1 触发条件

满足下列任一即触发本协议:

1. OMO `review-work` Stage 2 报 **critical severity** `🔴`(数据丢失 / 安全 / 修复引入新 bug)
2. 用户主动说"回滚那一段"
3. [`debugging-and-error-recovery`](~/.agents/skills/debugging-and-error-recovery/SKILL.md) Step 4 fix 引入新 regression(reproduce 命令倒过来了)
4. § 9 amend 反向:某个 spec amendment 决定撤回上线分支
5. Pre-merge 检查发现主线 cherry-pick 错位(合并前最后一道关)

#### 10.2 协议(必须按顺序)

1. **HALT frontier** — 任何并行 slice 立即停下:`progress.md` 加 `[halt] <slice-id> reason:<一句话>`。正在 `in_progress` 的 slice 必须 halt 后才走后续步骤(进 `rolled_back`,不要直接 `complete`)。
2. **选择恢复方式**:
   - `git revert <sha>`(已 commit 但未 publish)
   - `git reset --hard <safe-sha>`(永远仅在 main 之外用)
   - `cherry-pick --abort` 或 `rebase --abort`
   - 删除 worktree 整目录(`git worktree remove`)
3. **更新 slice 状态**:见 § 10.3 状态机新增 6 态 `rolled_back`,必填 `rolled_back_at` / `rolled_back_reason`。
4. **Log `[rollback]`**(必写,模板见 § 10.4)。这是事后 audit "为什么 X 段被回收" 的唯一线索。
5. **(critical severity 必做)** Postmortem — 在 `[rollback]` 行后 append 一句"如何防再次发生"(action item:新增防漏测试 / 新 checklist / 新 spec 段落)。
6. **修 Spec(若根因是 spec 错)**:走 [`spec-driven-development`](~/.agents/skills/spec-driven-development/SKILL.md) Step 5.5 amend,re-attest 后再继续。任何"只回退代码不修 Spec"的捷径见 § 10.6 Red Flags。
7. **验证回滚真完成**:`[rollback]` 行写齐 7 个字段 / `verify` 命令重跑且退出 0 / 受影响的 sibling slice `verify` 仍过。

#### 10.3 slice 状态机扩展

```
pending  ──► in_progress ──► complete
                │   │              │
                │   │ halted       ├──► deprecated   (留旧不演化)
                │   ▼              │
                │  [halt]          └──► superseded   (被新 slice 接替)
                │   │
                │   └────► rolled_back (post-complete rollback;git history preserved)
                │              ↑
                │              outcome of incidents;详细见 § 10
                ▼
              (rollback 流程见 § 10)
```

**写代码纪律**(rollback 专属):

- 禁止无 `[rollback]` 日志就改 git 历史(`git reset` / `git rebase --interactive`)。
- 禁止 `rolled_back` slice 不填 `rolled_back_at` / `rolled_back_reason`。
- 禁止"只回退代码不回退 spec 假设" —— 若根因是 spec 错,amend 必走。
- `rolled_back` slice 不允许再回 `complete`(除非 amend 一遍后整个 acceptance 重做)。
- 多个 slice 同时被影响的"事件级 rollback":`[rollback]` 里 `affected:` 字段列多个,`postmortem` 写在最后一条。

#### 10.4 `[rollback]` 日志模板

```
[rollback] <slice-id | commit-sha> at <ts> by <actor>
     trigger:    <review-work-crit | user-request | fix-the-fix | spec-retro | pre-merge-cherry-pick>
     severity:   <critical | major | minor>
     recovered:  <git-revert <sha> | git-reset <sha> | rebase-abort | worktree-remove | cherry-pick-abort>
     reason:     <一句话 5-whys 第一层>
     affected:   <slice-id-1, slice-id-2 ...>
     action:     <fix-tests | amend-spec | new-blocking-slice | none-yet>
[postmortem] <一句话如何防再次发生>  ← critical severity 必写
[test-gap]    <新测试名 / 新 checklist / 新 spec 段落>  ← optional
```

#### 10.5 Common Rationalizations

| Excuse | Reality |
|---|---|
| "已经 git revert 了,日志可以省" | revert 只是个动作,不是 audit 入口。下次人看到 git log 时,**[rollback]** 是唯一的"为什么这段代码不再有效"说明。无日志 = 历史虚无。 |
| "只是个小 bug,不用 critical 严重度" | 严重度由后果定,不由大小定。"小 bug"如果导致 P95 latency 翻倍 → **major**;导致数据丢失 → **critical**。不分严重度 → § 10.2 step 5 的 postmortem 被跳过,下次同样坑。 |
| "[rollback] 之后再补日志吧,先恢复代码" | 事故发生时补日志最容易遗漏(上下文已切换)。本协议要求 revert 与 log 同步:revert 完立刻写 `progress.md`。 |
| "spec 不需要 amend,只是某个 edge case" | 如果触发是 spec 没覆盖到该 edge case,这就是"spec 错",amend 必走。否则下次同一个 edge case 又会出现。 |
| "rolled_back 跟 complete 差不多" | **错**:`rolled_back` 的 slice **不算** shipping 成功的能力,3 个月后看 planner 的人若把它当 `complete` 引用,会引入回归。状态机分清这两态是为了 audit,不是冗余。 |

#### 10.6 Red Flags

- `git reset --hard` 在 main 分支上
- `git push --force` 到 main/release
- 在没有 `[rollback]` log 的情况下改了 git history
- "git pull 失败了,直接 reset 到 origin" — 跳过 audit
- `rolled_back` slice 没填 `rolled_back_at` / `rolled_back_reason`
- rollback 后没跑 sibling slice `verify`(确认没有牵连破坏)
- critical rollback 没写 postmortem
- rollback 但没 amend spec(若 spec 是根因之一)

## Common Rationalizations

| Excuse | Reality |
|---|---|
| "一次写完更快" | 一次写完更快地制造 bug,而且 debug 时找不到边界。 |
| "slice 太小没必要" | 30 行的 slice 也有价值 —— 它把"已 working"边界画清楚。 |
| "git worktree 太麻烦" | 主分支污染更麻烦 —— 一次事故就够你怀念 worktree。 |
| "没有合适的 slice 边界" | 强制找。每个能力必有可独立交付的最小版本。 |
| "横着切更快看到进度" | 横着切给你"快"的错觉。系统依然不可运行到 slice 1 完成。 |
| "review 一次看完就行" | 1000 行 diff 的 review 几乎一定漏问题。多个 50 行 diff 的 review 抓得全。 |
| "我直接审 diff 就行,不必 review-work" | 你已经在当前上下文里,会被自己的 rationalization 拉偏。新上下文 5 子代理是 Matt Pocock 的解。 |
| "设计对齐 Gate (`build-gate-visual-review`) 已经替我 QA 过了" | 它**只检查设计前对齐**,**不替人工 QA**。运行代码看交互是你的活。 |
| "用户说改 X 就改 X,不用先分类" | § 9.1 不分类 = 你会改 Spec text 但不动 slice 拓扑 → Phase 3.7 的前端 slice 引用旧字段 → 上线即报错。 |
| "deprecated 就是 superseded,二者差不多" | **错**:deprecated 是"留旧不演化";superseded 是"被新 slice 取代"。前者可独立存在,后者必须填 `superseded_by`。 |
| "amend 写一段 [amend] + 改 slice status 就够了,不必 re-attest" | **错**:`attest-plan.sh` 不重跑 → hash 不变 → pwf-enforcer 下一轮 session 仍 inject **旧** plan head → audit 与运行时分裂。每次 amend 必须跑。 |
| "用户说改完了,我就改一下,然后说 OK" | amend 必须改 Spec 文字 + 改 slice 拓扑 + 写 `[amend]` log,三件齐了才算 amend。少任何一步 = 漂移。 |
| "[halt] 之后再决定怎么办,先停着" | halt 必须立即进 § 9.2 step 5(deprecate/supersede/append)之一 —— 不允许`in_progress` 长期悬挂。 |

## Red Flags

- 单个 slice > 100 行 net diff
- slice 之间互相依赖(必须先 A 才能 B)但 `blockedBy` 没标
- 没 commit 就跳到下一个 slice,且项目 policy 要求 commit
- 在 main 分支直接改
- slice 完成后没跑全链路 smoke test(`verify` 字段命令)
- 多个 slice 在同一个 commit 里
- 不写 metadata 的 slice 直接跑(必填 `id` / `blockedBy` / `parallel` / `HITL|AFK`)
- Phase 3 跑完不调用 OMO `review-work`(缺后置审查)
- UI slice 跑完不主动让用户跑一次(缺人工 taste 注入)
- 用户中途改需求不分类、不进 § 9 流程,而是"接着写旧的"→ Spec 与代码必漂
- `in_progress` 切片被影响却不 halt,继续 commit 半成品
- 把 `deprecated` / `superseded` 乱标(无 `superseded_by` 的 superseded,或被 deprecated ↔ superseded 来回切换)
- 改完 Spec 不 re-attest(`bash scripts/attest-plan.sh`)→ pwf `pwf-enforcer` 仍 inject 旧 hash 的 plan head
- 中途变更不在 `progress.md` 写 `[amend]` 段 → 事后 audit 无线索

## Verification

Before moving to the next slice, confirm:
- [ ] Slice metadata 完整(`id` / `blockedBy` / `parallel` / `HITL|AFK` / `owner` / `verify` / **`status`** / **`superseded_by`**)
- [ ] Slice net diff ≤ 100 lines
- [ ] Slice has ≥ 1 test file
- [ ] 若项目 git policy 要求,本次 slice 已 commit 且 `progress.md` 有 `[slice]` 行
- [ ] `verify` 命令真实跑过且退出 0(把 stdout 节选写进 progress.md)
- [ ] End-to-end smoke test passes (not just unit tests)
- [ ] Previous slices still work (no regression)

Before declaring task complete:
- [ ] All slices independent (rollback drill succeeds)
- [ ] 总 commits 数符合项目策略(不强制 ≥ slice 数)
- [ ] No slice contains code from a future slice
- [ ] **OMO `review-work` 已跑,5 份并行报告已收**(`🔴` 已转新 slice,`🟢` 已 summary)
- [ ] **如有 UI:用户已亲手运行一次关键路径,确认 Taste OK**
- [ ] 本任务期间若有中途需求变更,`progress.md` 有完整 `[amend]` log(包含 affected / action / spec-hash 字段)

## pwf Integration

Maps to `task_plan.md` **Phase 3: Slice**. Each slice gets a row in the phase's progress table:

```markdown
### Phase 3: Slice
| id | blockedBy | parallel | HITL/AFK | owner | verify | LOC | Tests | Status |
|----|-----------|----------|-----------|-------|--------|-----|-------|--------|
| slice-1-create-user | [] | ✅ | AFK | sisyphus-junior | pytest tests/test_user_create.py | 67 | ✓ | complete |
| slice-2-read-user | [slice-1-create-user] | ❌ | AFK | sisyphus-junior | pytest tests/test_user_read.py | 45 | ✓ | complete |
| slice-3-error-taxonomy | [slice-2-read-user] | ❌ | HITL | hephaestus | pytest | 30 | ✓ | in_progress |
```

See [pwf-integration.md](../../pwf-integration.md).

## Related Skills

- Predecessor: [`spec-driven-development`](~/.agents/skills/spec-driven-development/SKILL.md)
- Per-slice implementation: [`test-driven-development`](~/.agents/skills/test-driven-development/SKILL.md)
- Post-impl fresh-context review: **OMO 内置 `review-work`** (preferred)
- Completion gate: [`verification-before-completion`](~/.agents/skills/verification-before-completion/SKILL.md)
- Human QA / Taste: OMO `visual-qa` + 用户亲手运行 UI
