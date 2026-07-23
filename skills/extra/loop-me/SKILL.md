---
name: loop-me
description: "Designs a recurring workflow spec via a stateful grilling session (one question at a time, each with a recommended answer) whose only output is the spec — not the implementation. Use when the user wants to specify a loop they keep doing manually so an implementer can build it without asking a single question. Hand off the finished spec to OMO /goal or incremental-implementation for execution."
disable-model-invocation: true
argument-hint: "A workflow to design, or nothing to go find one"
allowed-tools: "Read Write Edit Bash Glob Grep"
---

# loop-me

## Overview

把你反复做的活动**形式化**成可执行的 spec —— 不是写代码，是**写一份 implementer agent 不需要再问问题就能构建的 workflow spec**。

**核心动作**：跑一个 stateful `/grilling` session（一问一答，每问必带推荐答案），产出物是 `workflows/*.md` 与 `NOTES.md`，**不是代码、不是 OMO phase、不是 incremental slice**。

**与现有 skill 的粒度差异**：

| Skill | 阶段 | 产物 |
|---|---|---|
| [`brainstorming`](~/.agents/skills/brainstorming/SKILL.md) | 通用设计前 Q&A | 用户批准的设计意图 |
| [`spec-driven-development`](~/.agents/skills/spec-driven-development/SKILL.md) | 任意非平凡任务 spec | `.omo/plans/<slug>.md` Phase 1(编程任务 PRD/Spec) |
| **loop-me** | **recurring workflow spec** | **`workflows/*.md`（活动形式化）** |
| [`incremental-implementation`](~/.agents/skills/incremental-implementation/SKILL.md) | 编程任务切片实施 | 原子 commit + slice 元数据 |
| OMO `/goal <objective>` | 目标执行 | 持续运行的 loop |

loop-me 与上下游 skill **正交互补**：
- 上游 `brainstorming` 决定"要不要做这个 workflow"；loop-me 决定"这个 workflow 怎么 spec"
- 下游 OMO `/goal` 拿 loop-me 产出的 spec 当 objective 跑；或 `incremental-implementation` 拿它当实施输入

**为什么 `disable-model-invocation: true`**：本 skill 是 stateful 交互会话，模型不可自动触发 —— 必须用户主动 `/loop-me` 进入，避免与 [`brainstorming`](~/.agents/skills/brainstorming/SKILL.md) 的自动描述匹配产生路由竞争。

## When to Use

**Use when:**
- 用户说 `/loop-me [workflow description]` 或 `/loop-me`（无参，从 NOTES.md 找候选）
- 用户描述"我每周/每天反复做 X，想自动化"
- 用户给一个重复活动，希望写成可被 agent 执行的 spec
- 用户已存在 `NOTES.md`（模糊术语积累），希望打磨成 canonical workflow spec

**NOT for:**
- 一次性、单次的任务（走 [`brainstorming`](~/.agents/skills/brainstorming/SKILL.md) 或 [`spec-driven-development`](~/.agents/skills/spec-driven-development/SKILL.md)）
- 纯代码实现（走 [`incremental-implementation`](~/.agents/skills/incremental-implementation/SKILL.md)）
- 调试 bug（走 [`debugging-and-error-recovery`](~/.agents/skills/debugging-and-error-recovery/SKILL.md)）
- 用户已经知道完整 spec，只需要 review（走 [`build-gate-visual-review`](~/.agents/skills/build-gate-visual-review/SKILL.md) 的 Text alignment 模式）

**与 brainstorming 的边界**：`brainstorming` 处理"该不该做 + 做什么"；loop-me 处理"这个 recurring workflow 怎么 spec"。如果用户还没确认"想自动化 X"，先用 `brainstorming`。

## Process

### 1. Inspect `NOTES.md` first

进 loop-me 第一件事：**读 `NOTES.md`**（用户工作区根，与 `workflows/` 平行）。如果文件薄或空，先 grilling 用户关于他的"世界" —— 工具、渠道、术语。**不要**在 NOTES 空的时候直接 spec workflow。

把模糊术语打磨成 canonical 形式并写回 NOTES（例如 "the bot" → "GitHub triage bot (see workflows/triage.md)"）。

### 2. Use the loop lens

**Loop** = 用户生活/工作里反复出现的模式（career / week / morning / 单次重复活动）。**Workflow** = 某个 loop 的 spec 形式化。

用这个 lens **主动找**用户没注意到的 loop：
- "你每天早上 9 点都做什么？" → 也许是"开 GitHub Notifications inbox、按 priority 回复、归档"
- "你每周一上午都做什么？" → 也许是"review 上周 merged PRs + 列本周 priorities"

每个 loop 都有可能需要 spec。先列清单，跟用户对一遍。

### 3. Pick one workflow; enter grilling

一次 loop-me session **只处理一个 workflow**。从 NOTES 摘出最清晰的那个（用户已经提名的优先），用 grilling 风格追问：

- **每问只问一件事**
- **每问必带推荐答案**（推荐答案不是"正确答案"，是节省用户思考时间的"先想这个"）
- **不要罗列 checklist** —— Vocabulary 4 术语是 reach-for-when-needed，不是模板
- **没问清楚之前不写 spec**

**强制问到底**：Definition of done 是"implementer agent 不需要再问任何问题就能构建"。只要 spec 里还有任何隐含问题（"X 算完成吗？"、"失败怎么办？"、"多久跑一次？"），grilling 都不该结束。

### 4. Use Vocabulary only when needed

**Mandate nothing structural**：workflow 可以没有 AI、没有 Checkpoint、没有 Schedule —— 直到 grilling 表明它需要。

| 术语 | 含义 | 何时用 |
|---|---|---|
| **Trigger** | 每次运行的触发器：**event**（新邮件 / 新 issue）或 **schedule**（每天早上）。Event-trigger 通常更高效 | grilling 讨论"workflow 怎么跑起来"时 |
| **Checkpoint** | Human-in-the-loop 点，让用户验证或决策。有的 workflow 没 Checkpoint 也能跑 | grilling 讨论"用户需要在哪一步介入"时 |
| **Push right** | 把 Checkpoint 推得尽可能晚 —— 最大工作量先做掉，用户一次性签字 | 默认规则 |
| **Brief** | Checkpoint 呈现的内容：紧凑、决策就绪的摘要（产出 + 理由 + 链接到完整资产）——**永远不展示原始输出** | 设计任何 Checkpoint 时 |

### 5. Push right by default

不要在流程早期设 Checkpoint。**先做完所有可自动化的工作**，把 Checkpoint 推到最后的"签字"位置，让用户一次读完就批准。

错误：每次循环跑都问用户"这条要不要这样做？"
正确：跑完整个流程，brief 用户一次"以下 N 项已自动完成，是否批准继续？"

### 6. Write the spec to `workflows/<name>.md`

文件路径：**用户工作区根**的 `workflows/` 目录（与 `.planning/<id>/` 平行但不重叠）。

最小 spec 结构：

```markdown
# <Workflow name>

## Trigger
- [ ] event: <what fires it>
- [ ] schedule: <cron / interval>  ← 如果是 schedule

## Inputs
- <来源 1>: <取什么>
- <来源 2>: <取什么>

## Steps
1. <具体动作 1 — implementer 不需要再问>
2. <具体动作 2>
3....

## Checkpoint(s)
- 在 <位置> 让用户审 / 决策
- Brief: <决策就绪摘要模板>

## Outputs
- <输出 1>: <格式 + 目的地>
- <输出 2>:...

## Failure modes
- <失败 1>: <处理>
- <失败 2>:...

## Definition of done
[Implementer 拿这份 spec 走 incremental-implementation 应不再问任何问题]
```

每个 section 都必须**自包含** —— implementer 不需要读 NOTES 也能构建。

### 7. Verify Definition of done

写完 spec 后，**自己**走一遍"我是 implementer，看这份 spec 我会问什么？"：

- 还有隐含假设（"X 是什么格式？"、"Y 在哪个 API？"）→ 回 § 3 继续 grilling
- 涉及未指明的失败处理 → 加 § Failure modes
- Trigger 不明确 → 加 § Trigger 的精确条件
- Checkpoint 没 Brief → 补 Brief 模板

**只有 implementer 不再有问题，loop-me session 才结束**。

### 8. Hand off

Spec 完成后，把下一步留给用户：

- 想让 agent **持续执行**这个 workflow → OMO `/goal <objective>`，把 spec 链接塞进 goal 描述
- 想让 implementer **构建脚本**实现 → [`incremental-implementation`](~/.agents/skills/incremental-implementation/SKILL.md)，spec 作为 Phase 1 PRD 输入
- 想先把 spec 当通用方法沉淀 → 走 [`writing-skills`](~/.agents/skills/writing-skills/SKILL.md)（meta-only）

**loop-me 自身到此结束** —— 不进入实施阶段。

## Common Rationalizations

| Excuse | Reality |
|---|---|
| "用户描述已经够清楚了，直接写 spec 就行" | 描述 ≠ spec。grilling 阶段暴露的模糊术语必须先打磨；跳过 = implementer 阶段还要回头问 |
| "先列个模板让用户填空" | 模板是 reach-for-when-needed，不是 checklist。Mandate nothing structural —— workflow 不一定需要 AI / Checkpoint / Schedule |
| "Trigger 不重要，spec 主体对就行" | 没 Trigger 怎么 implementer 知道何时跑？每个 spec 必须明确 event 或 schedule |
| "Checkpoint 设 3 个保险点" | 反 Push right 原则。最大工作量先做，Checkpoint 推到最后。Checkpoint 多 = 用户疲于签字 |
| "Brief 直接放原始输出" | 用户读 brief 而非 draft。原始输出让 brief 失焦 |
| "Spec 不需要定义 done，implementer 自己会判断" | Definition of done 是 loop-me session 的退出条件；implementer 没这条会问"什么时候算做完" |
| "用户 NOTES.md 是空的，先猜几个典型 workflow" | NOTES 空 = 用户的"世界"还没建模。先 grilling 用户的工具/渠道/术语，不在空白处猜 |
| "spec 写完就够了，不做 hand off 提示" | 下游链路（`/goal` / `incremental-implementation` / `writing-skills`）用户未必知道。spec 写完不告诉用户下一步 = 走一半 |
| "loop-me 不属于 OMO，写到 `.planning/<id>/workflows/` 算了" | `.planning/` 是 OMO phase 划分；loop-me 是 workflow spec 设计期产物，不进 OMO phase。**用户工作区根 `workflows/`** 是上游规定路径 |

## Red Flags

- spec 草稿出现问号 "?" / "TODO" / "TBD" —— Definition of done 未达，回 § 3
- spec 含 `?` 不明确的 trigger / 没有 Trigger 段 —— implementer 无法开始
- spec 含 "等用户决定" 类内容但没 Checkpoint 段 —— 用户决策点没结构化
- Checkpoint > 1 个且没解释为什么 —— Push right 没做到位
- Brief 包含完整日志、原始输出或长清单 —— Brief 不是 draft
- `NOTES.md` 空但直接 spec workflow —— 用户"世界"没建模，spec 必然猜
- spec 涉及未列出的工具、API、术语 —— 回 § 1 NOTES
- 把 `workflows/` 写到 `.planning/<id>/workflows/` —— 越界（OMO phase 命名空间）
- loop-me session 跑完直接进 incremental-implementation 实施 —— **走错 skill 了**；loop-me 只到 spec，实施交给下游

## Verification

完成本 skill 后确认：

- [ ] `NOTES.md` 已读、必要时已更新（术语打磨 + 工具/渠道清单）
- [ ] 本次 session 处理的 workflow spec 写入 `workflows/<name>.md`（用户工作区根）
- [ ] spec 含 Trigger / Inputs / Steps / Checkpoints / Outputs / Failure modes / Definition of done 7 段
- [ ] **Definition of done 验证**：以 implementer 视角重读 spec，至少 2 个 grep-style 检查（"spec 里有没有 TBD / ? / TODO"、"Trigger 段是否自包含"）
- [ ] Checkpoint 数 ≤ 1（除非用户明确要求多个）
- [ ] Brief 段（如果有）不包含原始输出 / 完整日志
- [ ] 已提示用户下一步：OMO `/goal` / `incremental-implementation` / `writing-skills`
- [ ] 本 session **未**修改代码 / 未跑 commit / 未写 `.planning/<id>/`

## omo Integration

The resulting workflow spec can be handed to OMO `/goal <objective>` (persistent per-session state at `.omo/goal/<sessionID>.json`) or a Prometheus plan (`.omo/plans/<slug>.md`); OMO task tools and `/start-work` execute it only after the user approves.

> **Deprecation note (OMO PR #6184)**: legacy `/ralph-loop` / `/ulw-loop` / `/cancel-ralph` builtin slash commands were removed in favor of `/goal`. If a downstream consumer still references `ralph-loop`, migrate: `ralph_loop` config auto-migrates to `goal` at load time with a deprecation warning; behavioral parity preserved via `default_max_iterations` (default 100). Don't hand the spec to `/ralph-loop` — it no longer exists.
## Related Skills

- **上游（决定"做不做"）**：[`brainstorming`](~/.agents/skills/brainstorming/SKILL.md) —— 用户还没确定"想自动化 X"之前先用 brainstorming 收口设计意图
- **上游（通用 spec）**：[`spec-driven-development`](~/.agents/skills/spec-driven-development/SKILL.md) —— 任意非平凡编程任务的 spec-first；loop-me 是它的 recurring 专门化
- **下游（执行）**：OMO `/goal <objective>` —— 把 spec 链接塞进 goal 描述，让 agent 持续运行这个 workflow
- **下游（构建）**：[`incremental-implementation`](~/.agents/skills/incremental-implementation/SKILL.md) —— spec 当 Phase 1 PRD 输入，做 Tracer Bullet 切片
- **Meta（提炼）**：[`writing-skills`](~/.agents/skills/writing-skills/SKILL.md) —— 当 spec 重复出现成模式时，把它提炼成 skill（meta-only）
- **不相关**：[`verification-before-completion`](~/.agents/skills/verification-before-completion/SKILL.md) —— 完成门禁，针对编程完成声明；loop-me 不需要它的二段验证