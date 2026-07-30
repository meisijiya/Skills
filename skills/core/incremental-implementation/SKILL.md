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
> - **Slice 元数据**:`title` / `goal` / `scope` / `acceptance` / `blockedBy` / `parallel` / `HITL|AFK` / `owner` / `verify` / `status` / `superseded_by` —— 让 OMO `atlas` / `team_task` 能读出真正可以并行的 frontier
> - **审慎 commit**:**任何 commit 都需项目 git 策略授权**;默认不强制每个 slice 自动 commit,只保留"为可回滚而 commit"的语义
> - **后置闭环**:Phase 3 全部完成后,**桥接 OMO 内置 `review-work`**——以全新上下文 5 个并行子代理审 diff 与 spec 对齐;不重复造新审查 skill。slice 全部 ship 后,运行时证据(24h+ 健康 + 用户可达)由 [`closed-loop-delivery`](~/.agents/skills/closed-loop-delivery/SKILL.md) 单独负责 —— 本 skill 停在 PR 闭环,不在运行时闭环
> - **中途变更路由**:见 [`references/mid-build-changes.md`](references/mid-build-changes.md)(五档分类 + 状态机 + amend 协议)
> - **回滚审计**:见 [`references/rollback-protocol.md`](references/rollback-protocol.md)(`[rollback]` 日志模板 + 6 态状态机扩展)
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
### 0. Phase 2 startup state sweep (A2)

Before reading the executable frontier, run this non-destructive inventory:
```bash
ls -d .omo/{drafts,sdd,build-gate,prototypes,throwaway,wayfinder,wayfinder-archive,research,architecture-review,incidents}/* 2>/dev/null
```
Cross-check every result against `.omo/.index.json` field `stale_artifacts`. Show the filesystem-only, index-only, and matched stale candidates before any action. Prompt exactly `Delete stale artifacts? y/n`; never auto-delete. `n`, empty input, a missing/corrupt index, or an interrupted prompt preserves every path; `y` only authorizes the explicitly listed paths for a separate, auditable cleanup action.
### 1. Decompose into slices

Phase 3 是 Kanban ticket board —— 每条 ticket 是 § 3 的可执行单元,`blockedBy` 构成 DAG,`status` 跟踪生命周期。Read `.omo/plans/<slug>.md` Phase 3 (Prometheus task rows),按 **vertical capability** 切片(同一条 ticket 贯穿 data / service / consumer),而非按技术层切:

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

为每条 slice 写一份 OMO `atlas` / `team_task` 能消费的元数据(等同 Kanban ticket 契约):

| Field | Values | 含义 |
|---|---|---|
| `id` | `slice-<n>-<name>` | 稳定 ID,供 `Blocked by` / reviewer diff 用 |
| `title` | `<短句,动词 + 名词>` | 看板卡片标题;一行讲清 ticket 做什么 |
| `goal` | `<一句话>` | 这条 ticket 在 slice 列表里要达成的业务目标(why) |
| `scope` | `<in/out 列表>` | ticket 涵盖什么 / 不涵盖什么;防止 scope creep |
| `acceptance` | `[<可验证条款>]` | 验收条件(可被 `verify` 命令逐条断言);hit 全部条款才标 `complete` |
| `blockedBy` | `[slice-1,...]` 或 `[]` | 拓扑依赖。**前置 slice 全部 `complete` 才可启动** |
| `parallel` | `true` / `false` | 与 `blockedBy=[]` 的同组 slice 是否可同时执行(配 OMO `team_task`) |
| `HITL\|AFK` | `HITL` 或 `AFK` | HITL = 需人实时问答(设计决策);AFK = agent 可独立跑完(实现)。设计/取舍 slice 标 HITL |
| `owner` | `hephaestus` / `sisyphus-junior` / `omo-team` | 谁来跑 — 简单 AFK slice 委派给 sisyphus-junior 并行;Hephaestus 处理需要依赖上下文的 |
| `verify` | 见 § Verify 列 | `test --X` / `curl` / `smoke` 等可执行命令 |
| `status` | `pending` / `in_progress` / **`complete`** / **`deprecated`** / **`superseded`** | 见 § 9 中途变更路由与 § 10 回滚协议。`deprecated` = 旧实现仍保留但不再演化(用户改主意但旧分支不删);`superseded` = 被另一 slice 取代,必须填 `superseded_by`;`rolled_back` = post-complete rollback,见 § 10.3。OMO `atlas` 排 frontier 时跳过 deprecated / superseded / rolled_back |
| `superseded_by` | `slice-<n>-<name>` 或 `null` | **`status=superseded` 时必填**。指明哪个新 slice 接替此 slice 的 acceptance criteria;.omo/notepads/<plan-name>/ 应同时记录 `[amend] supersedes <old-id>` |

**字段集合的设计目的**:让 OMO `atlas` / `team_task` 能从元数据自动算出真正可并行的 frontier(`blockedBy=[]` 的同组 slice 都满足 → `parallel=true` 即可同时启动);`status + superseded_by` 让作废的 slice 在 frontier 之外被忽略,但 git history 与 .omo/notepads/<plan-name>/ 记录仍可 audit。

**示例表**(含作废状态):

| id | title | blockedBy | parallel | HITL/AFK | owner | verify | acceptance | LOC | Tests | Status | superseded_by |
|----|-------|-----------|----------|-----------|-------|--------|------------|-----|-------|--------|----------------|
| slice-1-create-user | Create user end-to-end | [] | ✅ | AFK | sisyphus-junior | pytest tests/test_user_create.py | POST /users → 201 + DB row + UI shows row | 67 | ✓ | complete | null |
| slice-2-read-user | Read user list | [slice-1-create-user] | ❌ | AFK | sisyphus-junior | pytest tests/test_user_read.py | GET /users → 200 contains created row | 45 | ✓ | superseded | slice-2b-read-user-v2 |
| slice-2b-read-user-v2 | Read user list v2 | [slice-1-create-user] | ❌ | AFK | sisyphus-junior | pytest tests/test_user_read_v2.py | GET /users → 200 contains created row | 50 | ✓ | in_progress | null |
| slice-3-error-taxonomy | Map error codes | [slice-2b-read-user-v2] | ❌ | HITL | hephaestus | pytest | 400/404/500 map to documented codes | 30 | ✓ | pending | null |
| slice-old-rest-api | Maintain legacy REST API | [slice-1-create-user] | ❌ | AFK | sisyphus-junior | pytest tests/test_legacy_api.py | Legacy /api/v1/* returns 200/4xx as before; CI green | 40 | ✓ | **deprecated** | null |
#### 3.1 Ticket DAG 与 executable frontier

ticket 集合是 DAG:`blockedBy` 是有向边,跨 ticket 的环 = 错。**executable frontier = 所有 `status=pending` 且 `blockedBy` 全部 `complete` 的 ticket**,OMO `atlas` 据此排程 + 决定同 frontier 内 `parallel=true` 的 ticket 一并派出。frontier 空 ⇒ Phase 3 收尾,转 § 7 review-work。`deprecated` / `superseded` / `rolled_back` 的 ticket 自动从 frontier 排除。
#### 3.2 NO horizontal decomposition

禁止按技术层切分 ticket:`slice-db-schema`、`slice-api-endpoint`、`slice-ui-form`、`slice-frontend-page` 是**反例** —— slice 1 完成后系统仍不可运行,集成反馈推迟到最后。Phase 3 的每条 ticket 必须跨至少 **data + service + 真实 consumer(API caller / UI / CLI)** 三层中的两层,见 § 1 正例。
#### 3.3 Tracer Bullet first-ticket

**第一条 ticket 必须是 Tracer Bullet**:最小范围贯穿 data → service → real consumer(可用最简 UI / curl / CLI 触发),跑通整条调用链,产出最早的全链路集成反馈。范围小于完整业务功能,允许 stub 数据 / 假数据 / TODO 边界;目的是验证集成假设而非交付价值。后续 ticket 在 tracer 路径上加深。

**HITL slice 的特殊规则**:HITL slice 在执行前后都需要用户确认(对齐 spec 后才能跑、跑完后用户确认交付)。
#### 3.4 Plan-level Global Constraints(Superpowers 吸收)

**每个 slice 的元数据之上,必须有一个 plan-level 段**显式列出全局约束 — 这是 sub-agent 执行时唯一可信赖的"上下文边界"。子 agent 在不同上下文里工作,只能读 brief,看不到 plan 全貌,所以 brief 里**必须**把以下约束 verbatim 复制:
```markdown
## Global Constraints

- Node ≥ 20.10 (来自 package.json engines)
- TypeScript strict mode,no implicit any
- 不引入新依赖;复用现有 ESM-only 路径
- 命名规则:kebab-case 文件名,PascalCase 类名,camelCase 变量
- 平台:仅 server(Node),无浏览器代码
- API 契约:`POST /api/users` 必须返回 RFC 7807 problem+json 错误格式
- 不要 mock 数据库;使用 docker-compose.test.yml 的真实 Postgres
```
**WHY**(来自 Superpowers writing-plans 实证):子 agent "几乎不懂我们的工具集",plan 假设"implementer 是 skilled developer but knows almost nothing about our toolset or problem domain"。Global Constraints 是把跨 slice 的隐性约束转成显性契约,防止 executor 重复发明或偏离。
#### 3.5 Slice Interfaces: Consumes / Produces

每个 slice 必须有精确的接口契约,**这是 executor 知道"邻居依赖什么"的唯一通道**(executor 不读完整 plan,只看 brief):
```markdown
### Slice: slice-2b-read-user-v2

**Interfaces:**

- **Consumes** (from earlier slices):
  - `createUser(input: CreateUserInput): Promise<User>` — exported from `src/users/service.ts:42`
  - `User` type — `src/users/types.ts:5-12` (id: string, email: string, createdAt: Date)

- **Produces** (for later slices):
  - `getUserById(id: string): Promise<User | null>` — `src/users/service.ts` new export
  - `GET /api/users/:id` handler — `src/api/users/[id].ts` new file
```
**强约束**:
- **exact signature**:函数名 / 参数类型 / 返回类型 / 抛错类型**逐字**写,executor 不会发明
- **file:line 引用**:Consumes 引用已存在的 symbol,**禁止**"用 service layer 的方法"这种模糊引用
- **Produces 也要写**:后续 slice 依赖的 contract,executor 看不到,所以 brief 必须替它声明

如果 slice 之间接口不匹配(consumes 期望的方法名 vs produces 导出的方法名不一致),executor 跑挂。**MUST** 在 § 5 实施前用 `~/.agents/skills/slice-review/scripts/review-package.sh --check-interfaces` 验证一致性。
#### 3.6 Bite-sized steps: TDD 5 步 + exact code

每个 slice 必须用 TDD 5 步分解(每步 2-5 分钟):write failing test → run to verify fail → write minimal impl → run to verify pass → commit。**完整模板 + TypeScript 示例 + 6 项强约束**(禁 "TBD" / 禁 "Similar to Task N" / 必填 exact paths + complete code + Expected: PASS/FAIL) 见 [`references/bite-sized-steps.md`](references/bite-sized-steps.md)。

**WHY**:executor 在 fresh context,看不到 plan 全貌,无法"参考前面步骤",只能照猫画虎。每步必须独立可执行。
#### 3.7 Executor status contract(4 态)

executor 跑完 slice **必须**返回 4 态之一(`DONE` / `DONE_WITH_CONCERNS` / `NEEDS_CONTEXT` / `BLOCKED`),不是 free text。详细 4 态含义表 + Controller action + 实现约束(< 200 字符总结 + report 文件) 见 [`references/executor-status-contract.md`](references/executor-status-contract.md)。

**WHY**:允许 free text 时 executor 会写"looks good"等 self-assessment → controller 盲信 → phantom completion。4 态契约 + 强制 report + reviewer 独立 re-run 是反 phantom completion 的核心机制。
#### 3.8 OMO task metadata 结构化字段

OMO `task_create` 的 `metadata: record<string, unknown>` 字段传结构化 brief(consumes / produces / biteSizedSteps / statusContract),不是塞 free text description。完整字段 schema + TypeScript 示例 见 [`references/task-metadata.md`](references/task-metadata.md)。`scripts/task-brief.sh` 直接从 metadata 提取 brief 文件给 executor。
### 4. Isolate each slice

For slices > 50 lines, use a feature branch or git worktree:
```bash
git worktree add../project-slice-2 -b feat/slice-2-name
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
6. Append to `.omo/notepads/<plan-name>/issues.md` (slice-implementation log):
   ```
   [slice] <id> → <commit-sha 或 "no-commit"> | <LOC> | verify: <stdout 节选>
   ```
   `notepad-write-guard` hook 强制 `.omo/notepads/*` 只能 append(用 `Edit`,不要 `Write`),保留 audit trail。
### 6. Rollback drill

Before merging slices, mentally rehearse: "If slice 3 breaks production, can I revert just slice 3?" If no, the slice isn't actually independent — re-decompose.
### 7. After all slices done: hand off to OMO review-work

> **omo dispatch**:`/start-work` is the slash command that activates Atlas on the latest Prometheus plan. Atlas reads this skill's Phase 3 slice table as the executable frontier. If running in omo, invoke `/start-work` once Phase 1 Spec has `Status: spec_approved`; if not, follow the manual `review-work` bridge below.

**桥接到 OMO 内置 `review-work` skill(不再自己造审查 skill)**:

1. Confirm:所有 slice 都已通过 `verify` 字段测试 + `.omo/notepads/<plan-name>/` 有 `[slice]` 日志
2. Invoke `review-work`(OMO 内置,描述:`Launches 5 parallel background sub-agents`)。传入:`.omo/plans/<slug>.md` 全文 + 当前分支 diff (`git diff main...HEAD`)。
3. **关键**:OMO 子代理是新上下文,无本会话历史污染 — 这就是 "isolated fresh-context automated review" 的实现。
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

完整 5 档分类 + 状态机 + amend 协议见 [`references/mid-build-changes.md`](references/mid-build-changes.md):

- **9.1** 5 类变更(Cosmetic / HOW / WHAT / WHY / Pure addition)的路由规则
- **9.2** 标准处理流程(Detect → Classify → Halt → Route → Deprecate → Log → Resume)
- **9.3** Slice 状态机扩展(含 halted 路径 + `[amend]` 日志模板)
### 10. Rollback protocol

Slice 上线后被判定需要回收时(数据丢失 / 安全洞 / correctness regression / 用户主动撤回 / fix-the-fix 反效果),按本协议收尾。

完整协议见 [`references/rollback-protocol.md`](references/rollback-protocol.md):

- **10.1** 触发条件(5 种)
- **10.2** 7 步协议(HALT → 恢复方式 → 状态更新 → Log → Postmortem → Spec 修复 → 验证)
- **10.3** 状态机扩展(`rolled_back` 6 态)
- **10.4** `[rollback]` 日志模板 + 10.5 Rationalizations + 10.6 Red Flags

**注意**:rollback 是 § 9 amend 的姐妹协议 —— § 9 处理"需求变了,spec 与 slice 还没坏";本协议处理"已落地的 slice 必须撤回"。两者状态机独立,但共用 `.omo/notepads/<plan-name>/` 日志约定。
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
| "amend 写一段 [amend] + 改 slice status 就够了,不必 re-review" | **错**:Momus 不重跑 → plan 未验证 → 下一轮 session 仍 inject **旧** plan → audit 与运行时分裂。每次 amend 必须重跑 Momus 拿 `[OKAY]`。 |
| "用户说改完了,我就改一下,然后说 OK" | amend 必须改 Spec 文字 + 改 slice 拓扑 + 写 `[amend]` log,三件齐了才算 amend。少任何一步 = 漂移。 |
| "[halt] 之后再决定怎么办,先停着" | halt 必须立即进 § 9.2 step 5(deprecate/supersede/append)之一 —— 不允许`in_progress` 长期悬挂。 |
## Red Flags

- 单个 slice > 100 行 net diff
- slice 之间互相依赖(必须先 A 才能 B)但 `blockedBy` 没标
- 没 commit 就跳到下一个 slice,且项目 policy 要求 commit
- 在 main 分支直接改
- slice 完成后没跑全链路 smoke test(`verify` 字段命令)
- 多个 slice 在同一个 commit 里
- 不写 metadata 的 slice 直接跑(必填 `title` / `goal` / `scope` / `acceptance` / `id` / `blockedBy` / `parallel` / `HITL|AFK`)
- Phase 3 跑完不调用 OMO `review-work`(缺后置审查)
- UI slice 跑完不主动让用户跑一次(缺人工 taste 注入)
- 用户中途改需求不分类、不进 § 9 流程,而是"接着写旧的"→ Spec 与代码必漂
- `in_progress` 切片被影响却不 halt,继续 commit 半成品
- 把 `deprecated` / `superseded` 乱标(无 `superseded_by` 的 superseded,或被 deprecated ↔ superseded 来回切换)
- 改完 Spec 不重跑 Momus → 下一轮 session 仍 inject 旧 plan head
- 中途变更不在 `.omo/notepads/<plan-name>/` 写 `[amend]` 段 → 事后 audit 无线索
## Verification

Before moving to the next slice, confirm:
- [ ] Phase 2 startup sweep 已列出并对照 `stale_artifacts`;任何清理前都收到显式 `y`,且未自动删除
- [ ] Slice metadata 完整(`title` / `goal` / `scope` / `acceptance` / `id` / `blockedBy` / `parallel` / `HITL|AFK` / `owner` / `verify` / **`status`** / **`superseded_by`**)
- [ ] Slice net diff ≤ 100 lines
- [ ] Slice has ≥ 1 test file
- [ ] 若项目 git policy 要求,本次 slice 已 commit 且 `.omo/notepads/<plan-name>/` 有 `[slice]` 行
- [ ] `verify` 命令真实跑过且退出 0(把 stdout 节选写进 .omo/notepads/<plan-name>/)
- [ ] End-to-end smoke test passes (not just unit tests)
- [ ] Previous slices still work (no regression)

Before declaring task complete:
- [ ] All slices independent (rollback drill succeeds)
- [ ] 总 commits 数符合项目策略(不强制 ≥ slice 数)
- [ ] No slice contains code from a future slice
- [ ] **OMO `review-work` 已跑,5 份并行报告已收**(`🔴` 已转新 slice,`🟢` 已 summary)
- [ ] **如有 UI:用户已亲手运行一次关键路径,确认 Taste OK**
- [ ] 本任务期间若有中途需求变更,`.omo/notepads/<plan-name>/` 有完整 `[amend]` log(包含 affected / action / spec-hash 字段)
## omo Integration

Record vertical slices in an .omo/plans/<slug>.md, create the task DAG with task tools, and hand approved slices to `start-work`; atlas/Boulder track execution and `review-work` closes each slice.
## Related Skills

- Predecessor: [`spec-driven-development`](~/.agents/skills/spec-driven-development/SKILL.md)
- Per-slice implementation: [`test-driven-development`](~/.agents/skills/test-driven-development/SKILL.md)
- Post-impl fresh-context review: **OMO 内置 `review-work`** (preferred)
- Completion gate: [`verification-before-completion`](~/.agents/skills/verification-before-completion/SKILL.md)
- Human QA / Taste: OMO `visual-qa` + 用户亲手运行 UI
