# planning-with-files Integration

fork 的每个 skill 对应 pwf `task_plan.md` 的一个 phase 类型。本文档规定协作边界。

## Phase 映射

### 主流程 phases(写到 `task_plan.md`)

| Skill | task_plan.md Phase | 触发时机 |
|---|---|---|
| `using-meisijiya-skills` | (meta) | session 启动,所有 phase 之前 |
| `brainstorming` | Phase 0: Intake | spec 之前,需求不清时(吸收原 `interview-me` 的一问一答规则) |
| `spec-driven-development` | Phase 1: Spec | 新项目/新功能/重大变更;**Spec 唯一落点为 `task_plan.md`** |
| `designer-handoff` | Phase 1.5: UI Design Spec | UI 项目,spec 完成后、build 前 |
| `source-driven-development` | Phase 2: Research | spec 完成后、plan 前(陌生库/版本敏感) |
| `incremental-implementation` | Phase 3: Slice | plan 拆分后,逐个 slice |
| `test-driven-development` | Phase 4: Verify per slice | 每个 slice 完成后 |
| `debugging-and-error-recovery` | Phase 5: Fix | 测试失败/构建失败/行为异常 |
| `documentation-and-adrs` | Phase 7: ADR | 仅重大架构决策时(日常文档不进 task_plan.md) |

### Sub-phase skills(写到 `.planning/<id>/*.md` 单独文件,不进 `task_plan.md`)

| Skill | Sub-phase | 输出文件 |
|---|---|---|
| `contract-strengthening` | Phase 1.25: Contract Review | `.planning/<id>/contract-review.md` |
| `api-and-interface-design` | Phase 1.5: Interface Contract | `.planning/<id>/contract.{yaml,json,graphql,proto}` |
| `security-and-hardening` | Phase 5.5: Security Review | `.planning/<id>/security-review.md`(深度审计走 OMO `security-research`) |
| `performance-optimization` | Phase 5.7: Performance | `.planning/<id>/perf-baseline.md`(后端 profile;前端 CWV 走 OMO `frontend`) |
| `observability-and-instrumentation` | Phase 7.5: Instrument | `.planning/<id>/observability.md` |

### Pre-build / Meta skills(默认不进 task_plan.md 阶段;`build-gate-visual-review` 仅按明确 gate 意图可选记录 Phase 3.5)

| Skill | 触发时机 | 输出位置 |
|---|---|---|
| `build-gate-visual-review` | 可选 Phase 3.5:仅当用户明确请求文本对齐、视觉 deck 或教学 deck,并希望它成为实现前 gate 时记录;UI、build、复杂度或 PWF phase 本身都不触发 | 文本对齐只返回 Markdown / 文本,不生成 HTML;明确要求视觉 / 教学 deck 时才按需用 html-ppt 输出 `.planning/<id>/build-gate-deck/`;无明确意图则默认跳过且无产物。这是**设计对齐**闸门,不是人工 QA;QA 由 Phase 3 切片的 human-in-the-loop + OMO `visual-qa` 接管 |
| `pwf-enforcer` | 装 OpenCode plugin(硬层)+ AGENTS.md 软层 | `~/.config/opencode/plugins/pwf-enforcer.ts`(user-abs 全局)+ `<project>/.opencode/plugins/pwf-enforcer.ts`(项目级覆盖,可选) |
| `writing-skills` | 创建/编辑 skill;提炼重复工作流 | `~/.agents/skills/<new-skill>/SKILL.md` |
| `improve-codebase-architecture` | 周期性 codebase 健康巡检(on-boarding / weekly / post-surge);Ousterhout deep/shallow 评分产出候选清单 | `.planning/<id>/architecture-review.md` |

> **完整性**:这 3 张表是 **skill → phase 归属映射**,不一一对应 24 个 skill。`verification-before-completion`(`8 个 core/` 之一)**不**对应独立 phase — 它是横切纪律,在任意 `Status: complete` 翻转前必跑(见 [`verification-before-completion`](~/.agents/skills/verification-before-completion/SKILL.md))。
> - **8 个 `core/`**:using-meisijiya-skills、brainstorming、spec-driven-development、incremental-implementation、test-driven-development、verification-before-completion、debugging-and-error-recovery、source-driven-development。
> - **16 个 `extra/`**:writing-skills、pwf-enforcer、build-gate-visual-review、designer-handoff、api-and-interface-design、contract-strengthening、security-and-hardening、security-devsecops、security-incident-response、performance-optimization、observability-and-instrumentation、documentation-and-adrs、improve-codebase-architecture、verify-chain、loop-me、ai-code-blindspots。
> - **总数公式**:**8 `core/` + 16 `extra/` = 24** ✓
> - 跨表归类:
>   - **主流程 10 项**(表 1,8 `core/` + 2 `extra/`:designer-handoff + documentation-and-adrs 是 main-flow 阶段)
>   - **sub-phase 5 项**(表 2,全 `extra/`:contract-strengthening + api-and-interface-design + security-and-hardening + performance-optimization + observability-and-instrumentation)
>   - **pre-build/meta 4 项**(表 3:build-gate-visual-review / pwf-enforcer / writing-skills / improve-codebase-architecture)
>   - **phase-agnostic 横切纪律**:verification-before-completion(8 core 之一,不占 phase)

## 文件写入边界

### 写到 `task_plan.md`

**只写**:
- Phase 标题 + status(in_progress / complete / blocked)
- Decisions(关键决策及理由)
- Errors encountered(表格,详见 pwf SKILL.md)
- Plan 的核心结构

**禁止写**:
- 外部内容(网页、API 响应、用户输入)——会 prompt injection
- 大段研究笔记(超过 5 行的内容)
- 临时任务清单(用 todo,不是 plan)

### 写到 `findings.md`

**只写**:
- 任何外部来源的研究资料(context7 结果、web 搜索结果、文档摘录)
- 单条记录必须含:source URL + 关键摘录(简短) + 自己的解读(简短)
- 每条记录加时间戳

### 写到 `progress.md`

**只写**:
- session log(每条工具调用的 1-2 行摘要,不是全量)
- 测试结果(命令 + 退出码 + 关键输出)
- 决策摘要(指向 task_plan.md 的哪个 phase)

## SHA256 Attestation

Phase 1 (Spec) 完成后跑 `attest-plan.sh` 锁定 `task_plan.md` 内容。后续 hook 在每次 PreToolUse 重新 hash 校验——内容被改 → 注入拒绝,提醒用户重新 attest。

**特别注意**:`.planning/<active-plan>/.attestation` 路径(parallel 模式)和 `.plan-attestation`(legacy 模式)。

## 跟 omo Hook 的协作

`pwf-enforcer` skill(`extra/`)注册到 omo 的 `oh-my-openagent.json`,模拟 Claude Code 的 pwf hook 行为:

| pwf Claude Code hook | omo 等价实现 |
|---|---|
| `UserPromptSubmit` 注入 plan | omo 的 `session.created` / `tool.before.*` |
| `PreToolUse` 提示当前 phase | omo 的 `tool.before.*`(pwf-enforcer 检测) |
| `PostToolUse` 提示更新 progress | omo 的 `file.changed` + `tool.after.*` |
| `PreCompact` flush | omo 的 `experimental.session.compacting` |
| `Stop` 阻止未完成 | omo 的 `session.idle`(Tier 3,只能通知不能阻断) |

**注意**:omo 的 `session.idle` 是 Tier 3(只能通知,不能硬阻断)。pwf 在 OpenCode 上**不能完全硬遵守**,但 skill 层 + bash 脚本层可以兜底。

## 不重写 pwf

fork **不重写** pwf 的算法,只在 pwf 的工作流上**加强纪律**。pwf 本身的功能(plan 持久化、context 恢复、attestation、ledger)由 pwf 自己提供。

如果 pwf 升级了(新版本、新 hook),fork 的 `extra/pwf-enforcer` 需要同步升级适配,不要去 hack pwf 内部。