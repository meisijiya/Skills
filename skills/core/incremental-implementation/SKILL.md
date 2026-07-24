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

**每个 slice 必须用 TDD 5 步分解**(每步 2-5 分钟):

```markdown
**Steps:**

- [ ] **Step 1: Write the failing test**

```typescript
// tests/users/getUserById.test.ts
import { getUserById } from '@/users/service';
import { setupTestDB, teardownTestDB } from '../helpers/db';

describe('getUserById', () => {
  beforeEach(setupTestDB);
  afterEach(teardownTestDB);

  test('returns user when id exists', async () => {
    const created = await createUser({ email: 'a@b.co' });
    const found = await getUserById(created.id);
    expect(found?.email).toBe('a@b.co');
  });

  test('returns null when id does not exist', async () => {
    const found = await getUserById('nonexistent');
    expect(found).toBeNull();
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `pnpm test tests/users/getUserById.test.ts`
Expected: FAIL with "Cannot find module '@/users/service' or its corresponding type declarations." (or "getUserById is not a function")

- [ ] **Step 3: Write minimal implementation**

```typescript
// src/users/service.ts
export async function getUserById(id: string): Promise<User | null> {
  const row = await db.users.findUnique({ where: { id } });
  return row ? toUser(row) : null;
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `pnpm test tests/users/getUserById.test.ts`
Expected: PASS — 2/2 tests

- [ ] **Step 5: Commit**

```bash
git add tests/users/getUserById.test.ts src/users/service.ts
git commit -m "feat(users): add getUserById"
```
```

**强约束**(从 Superpowers No Placeholders 直接吸收):

- ❌ 禁止 "TBD" / "TODO" / "implement later" / "fill in details"
- ❌ 禁止 "Add appropriate error handling" / "add validation" / "handle edge cases"
- ❌ 禁止 "Similar to Task N" — 必须重复代码,executor 可能乱序读
- ❌ 禁止 "Write tests for the above" without actual test code
- ❌ 禁止 描述 "做什么" 而不展示 "怎么做" — 代码块必填
- ❌ 禁止 引用未定义的类型/函数/方法
- ✅ exact paths 必填 (`tests/exact/path/test.ts`)
- ✅ complete code in every step — 即使代码已在 Step 1 写过,Step 3 仍需重新展示
- ✅ exact commands with expected output(每个 command 必带 Expected: PASS/FAIL 行)

**WHY**:executor 在 fresh context,看不到 plan 全貌,无法"参考前面步骤",只能照猫画虎。每步必须独立可执行。

#### 3.7 Executor status contract(4 态)

executor 跑完 slice **必须**返回 4 态之一,不是 free text:

| Status | Meaning | Controller action |
|---|---|---|
| `DONE` | slice 完成 + 全部测试通过 + commit 落地 | 派 review-slice / 进入下一个 slice |
| `DONE_WITH_CONCERNS` | 完成 + 测试通过,但发现潜在的边缘 case / 设计疑问 | Controller 读 concerns → 决定补 spec / 跳到下个 slice |
| `NEEDS_CONTEXT` | executor 需要超出 brief 的信息(consumes 不够 / produce 缺上下文) | Controller 补 brief → 重派 executor |
| `BLOCKED` | executor 撞到 blocker(dependency 错 / 设计错 / 任务过大) | Controller 评估:补 ctx / 升模型 / 拆任务 / 回到 brainstorming |

**实现**:executor 在 dispatch prompt 里**只能**返回 4 态 + 1 行总结(< 200 字符)。详细 RED/GREEN evidence、commit、concerns 写到 report 文件(`~/.agents/skills/incremental-implementation/scripts/task-brief.sh` 生成 brief,executor 写 report)。

**WHY**(来自 Superpowers 实验):允许 free text status 时,executor 会写"looks good" / "should pass" 等 self-assessment,controller 盲信导致 phantom completion(实测案例:verifier 报告 "tests pass" 但代码是 stub,只有独立 run test 才能抓到)。4 态契约 + 强制 report 文件 + mandatory re-run by reviewer 是反 phantom completion 的核心机制。

#### 3.8 OMO task metadata 结构化字段(我们的实现)

OMO `task_create` 工具已经支持 `metadata: record<string, unknown>` 字段。我们**用 metadata 传结构化 brief** 而不是塞 free text description:

```typescript
task_create({
  subject: "slice-2b-read-user-v2: Read user list v2",
  metadata: {
    globalConstraints: [/* 引用 Phase 1 Global Constraints 段 */],
    interfaces: {
      consumes: [
        { symbol: "createUser", file: "src/users/service.ts:42" },
        { symbol: "User", file: "src/users/types.ts:5-12" }
      ],
      produces: [
        { symbol: "getUserById", file: "src/users/service.ts", signature: "(id: string) => Promise<User | null>" }
      ]
    },
    biteSizedSteps: [
      { step: 1, action: "Write failing test", files: ["tests/users/getUserById.test.ts"], code: "...", verify: "pnpm test tests/users/getUserById.test.ts", expected: "FAIL: Cannot find module" },
      { step: 2, action: "Run test to verify fails", command: "pnpm test tests/users/getUserById.test.ts", expected: "FAIL with 'getUserById is not a function'" },
      // ...
    ],
    noPlaceholders: true,  // 写入即 commit 此契约
    statusContract: "DONE | DONE_WITH_CONCERNS | NEEDS_CONTEXT | BLOCKED"
  }
})
```

**为什么不写 `description` 字段**:OMO 的 task description 是 free text,executor 看到的是 description 而不是 metadata。**metadata 是结构化的、可被脚本读取的**。我们的 `~/.agents/skills/incremental-implementation/scripts/task-brief.sh` 直接从 metadata 提取 brief 文件,executor 拿到的 brief 包含完整 step-by-step 代码。

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

#### 9.1 Classify the change (5 个类型 → 5 个路由)

| 改动类型 | 例 | 路由 | 副作用 |
|---|---|---|---|
| **Cosmetic** | "字段叫 `name` 改成 `fullName`" / "措辞 / 边界值调整" | 只改 Phase 1 文字;不 amend Spec、不动 slice | 无 |
| **Implementation detail (HOW)** | 换库 / 换算法 / 调实现顺序 | 不动 Spec;改既有 slice 的 `verify` 命令或加新 slice | slice 表更新;**不改** `blockedBy` 拓扑 |
| **Data-shape / API contract (WHAT)** | 加字段 / 改 schema / 改 endpoint 签名 | **重入 Phase 1 Spec**;amend + 重新跑 Momus 拿 `[OKAY]`;旧 slice 标 `superseded` 由新 slice 替换 | 旧 slice 走 `git revert`(项目 git policy 下)+ 标 `status=superseded` 并填 `superseded_by`;新 slice 入 frontier |
| **Feature re-scope (WHY)** | 用户说"其实我们要做的不是 X,是 Y" | **重入 Phase 0 Brainstorming**;只保留 Phase 0 Design 的设计骨架;再走 § Phase 1 Spec 重写 | 大部分已有 slice 走 `status=superseded` 或 `deprecated`;新设计产出新 Phase 1 Spec |
| **Pure addition (orthogonal)** | "再加一个 Y,不影响已存在的 X" | append 到 Phase 1 Spec(amend + Momus);**仅在 frontier 末尾追加新 slice**,旧 slice 不动 | frontier 增长;不改既有 `blockedBy` 拓扑 |

#### 9.2 Process for any requirement change

1. **Detect**:用户或 review-work 🔴 报告"需求 / 验收标准变了"。
2. **Classify**:用 § 9.1 的 5 档表对位(只取一行,不许混)。
3. **Halt in-flight slice**:`in_progress` 的 slice 若被 impacted,先停下,不要再 commit,记录当前进度 `.omo/notepads/<plan-name>/issues.md` 加 `[halt] <slice-id> reason:<一句话>`。
4. **Route to the right phase**:
   - Cosmetic / HOW → 不出 Phase 3,仅修改既有 row 或 append row
   - **Data-shape / Pure addition →** invoke [`spec-driven-development`](~/.agents/skills/spec-driven-development/SKILL.md) Step 5.5 Amend + re-attest
   - **WHY changed →** invoke [`brainstorming`](~/.agents/skills/brainstorming/SKILL.md) Phase 0 重新对齐,完成后再走 Phase 1 amend
5. **Deprecate or supersede impacted slices**:用 § 9.3 的状态机更新 `status` + `superseded_by`;OMO `atlas` 自动把它们从 frontier 排除。
6. **Log amendment**:`.omo/notepads/<plan-name>/decisions.md` append 一段(用 `Edit`,不要 `Write` —— `notepad-write-guard` hook 强制 append-only):
   ```
   [amend] <type> at <ts> by <actor> reason:<一句话>
        sections:   <Phase-1.Section-list, e.g. Acceptance / Test Strategy>
        momus-verdict: <OKAY | REJECT — issues>
        affected:   <slice-id-1, slice-id-2...>
        action:     <deprecate / supersede / append / modify>
        spec:       .omo/plans/<slug>.md#Phase-1.Section
   ```
   这是事后 audit"为什么 X 被作废"的唯一线索。`sections` + `momus-verdict` 是必备字段:前者定位改动位置,后者证明 amend 经过了 Momus 评审(防止"amend 后忘了评审")。
7. **Resume**:**只在 Momus 通过新 plan + 新 slice 表上**继续 frontier work。任何 `in_progress` 的旧 slice 必须 halt 并 supersede,绝不允许续写半成品。

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
- 任何 status 变更必须 append 到 `.omo/notepads/<plan-name>/` 的 `[amend]` 段。

### 10. Rollback protocol

Slice 上线后被判定需要回收时(数据丢失 / 安全洞 / correctness regression / 用户主动撤回 / fix-the-fix 反效果),按本协议收尾。

**注意**:rollback 是 § 9 amend 的姐妹协议 —— § 9 处理"需求变了,spec 与 slice 还没坏";本协议处理"已落地的 slice 必须撤回"。两者状态机独立,但共用 `.omo/notepads/<plan-name>/` 日志约定。

#### 10.1 触发条件

满足下列任一即触发本协议:

1. OMO `review-work` Stage 2 报 **critical severity** `🔴`(数据丢失 / 安全 / 修复引入新 bug)
2. 用户主动说"回滚那一段"
3. [`debugging-and-error-recovery`](~/.agents/skills/debugging-and-error-recovery/SKILL.md) Step 4 fix 引入新 regression(reproduce 命令倒过来了)
4. § 9 amend 反向:某个 spec amendment 决定撤回上线分支
5. Pre-merge 检查发现主线 cherry-pick 错位(合并前最后一道关)

#### 10.2 协议(必须按顺序)

1. **HALT frontier** — 任何并行 slice 立即停下:`.omo/notepads/<plan-name>/decisions.md` append `[halt] <slice-id> reason:<一句话>`。正在 `in_progress` 的 slice 必须 halt 后才走后续步骤(进 `rolled_back`,不要直接 `complete`)。
2. **选择恢复方式**:
   - `git revert <sha>`(已 commit 但未 publish)
   - `git reset --hard <safe-sha>`(永远仅在 main 之外用)
   - `cherry-pick --abort` 或 `rebase --abort`
   - 删除 worktree 整目录(`git worktree remove`)
3. **更新 slice 状态**:见 § 10.3 状态机新增 6 态 `rolled_back`,必填 `rolled_back_at` / `rolled_back_reason`。
4. **Log `[rollback]`**(必写,模板见 § 10.4,append 到 `.omo/notepads/<plan-name>/decisions.md`)。这是事后 audit "为什么 X 段被回收" 的唯一线索。
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
     affected:   <slice-id-1, slice-id-2...>
     action:     <fix-tests | amend-spec | new-blocking-slice | none-yet>
[postmortem] <一句话如何防再次发生>  ← critical severity 必写
[test-gap]    <新测试名 / 新 checklist / 新 spec 段落>  ← optional
```

#### 10.5 Common Rationalizations

| Excuse | Reality |
|---|---|
| "已经 git revert 了,日志可以省" | revert 只是个动作,不是 audit 入口。下次人看到 git log 时,**[rollback]** 是唯一的"为什么这段代码不再有效"说明。无日志 = 历史虚无。 |
| "只是个小 bug,不用 critical 严重度" | 严重度由后果定,不由大小定。"小 bug"如果导致 P95 latency 翻倍 → **major**;导致数据丢失 → **critical**。不分严重度 → § 10.2 step 5 的 postmortem 被跳过,下次同样坑。 |
| "[rollback] 之后再补日志吧,先恢复代码" | 事故发生时补日志最容易遗漏(上下文已切换)。本协议要求 revert 与 log 同步:revert 完立刻写 `.omo/notepads/<plan-name>/`。 |
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
