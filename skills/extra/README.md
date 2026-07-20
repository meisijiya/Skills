# Extra Skills(选装集 · 12 个)

按项目需求挑。**不必全装**。每个 skill 独立,装了就启用,不装就不影响其他。

> **v0.5.0 调整**:`writing-skills` 从 `core/` 迁入;`interview-me` 与 `code-simplification` 改为对应 OMO/核心 Skill 的薄别名;`documentation-and-adrs` 聚焦重大架构 ADR;`build-gate-visual-review` 明确为"设计对齐闸门"而非"人工 QA";`security-and-hardening` 路由至 OMO `security-research`;`performance-optimization` 卸下 CWV。

## 怎么选

| 你的项目... | 装这些 |
|---|---|
| 任何代码 | `code-simplification` · `security-and-hardening` · `api-and-interface-design` · `improve-codebase-architecture` |
| 有 UI | `designer-handoff` · `build-gate-visual-review` |
| 上线运营 | `observability-and-instrumentation` · `performance-optimization` |
| 多人 / 长期 | `documentation-and-adrs` |
| 用了 planning-with-files | `pwf-enforcer`(把 PWF 软遵守升级为硬触发) |
| 创建/编辑 skill | `writing-skills` |

## 12 个 skill 一览

| Skill | 一句话 |
|---|---|
| [`writing-skills`](./writing-skills/) | meta: 创建 / 编辑 skill 用 TDD-for-docs 流程。也用于"我老做 X,把 X 提炼成 skill"(**v0.5.0 从 core/ 迁出**) |
| [`pwf-enforcer`](./pwf-enforcer/) | 把 PWF 的软遵守变硬触发(OpenCode plugin + AGENTS.md 软提醒) |
| [`build-gate-visual-review`](./build-gate-visual-review/) | 设计对齐闸门:spec/plan 完成后、任何代码之前用 html-ppt-skill 生成 slide deck,**不是人工 QA**(v0.5.0 明确) |
| [`designer-handoff`](./designer-handoff/) | designer → eng 的 UI/UX spec 交接(用 ui-ux-pro-max) |
| [`interview-me`](./interview-me/) | **v0.5.0 改为别名**:请直接使用 `brainstorming`(已吸收一问一答规则) |
| [`code-simplification`](./code-simplification/) | **v0.5.0 改为别名**:请直接使用 OMO 内置 `refactor` / `ponytail-review` / `remove-ai-slops` |
| [`api-and-interface-design`](./api-and-interface-design/) | contract-first API 设计(REST/GraphQL/RPC) |
| [`security-and-hardening`](./security-and-hardening/) | 设计时信任边界检查 + 路由 OMO `security-research` 做深度审计(v0.5.0 纠正 OMO 能力描述) |
| [`performance-optimization`](./performance-optimization/) | 后端 profile + 优化(**v0.5.0 卸下 CWV**:前端 CWV 走 OMO `frontend` skill) |
| [`observability-and-instrumentation`](./observability-and-instrumentation/) | 加日志/metrics/tracing,生产可见性 |
| [`documentation-and-adrs`](./documentation-and-adrs/) | **v0.5.0 聚焦**:只记录重大架构决策(ADR);日常文档走项目级 AGENTS.md / progress.md |
| [`improve-codebase-architecture`](./improve-codebase-architecture/) | codebase-wide 健康巡检(weekly / post-surge / on-boarding);Ousterhout deep/shallow 评分;**proposal-only** —— 改架构走 `incremental-implementation` |

## 依赖关系(顺序装才有效)

某些 skill 依赖其他东西,装之前先确认依赖到位:

| Skill | 需要先装 |
|---|---|
| `build-gate-visual-review` | `html-ppt-skill` 到 `~/.agents/skills/`(`npx skills add https://github.com/lewislulu/html-ppt-skill`) |
| `designer-handoff` | `ui-ux-pro-max-cli` 全局(`npm i -g ui-ux-pro-max-cli`) |
| `pwf-enforcer` | `planning-with-files` 到 `~/.agents/skills/`(`npx skills add https://github.com/OthmanAdi/planning-with-files`) |
| `security-and-hardening` Step 6.5 | OMO `security-research` 内置 skill(默认随 omo 安装) |
| `incremental-implementation` / `verification-before-completion` 的 OMO 桥接 | OMO `review-work` / `visual-qa` 内置 skill(默认随 omo 安装) |

## 安装

按需装某个或某几个:

```bash
# 装特定几个
npx skills add https://github.com/meisijiya/Skills \
  --skill pwf-enforcer --skill security-and-hardening

# 或展开 picker 手动选
npx skills add https://github.com/meisijiya/Skills
```

完整写作规范见 [`skill-anatomy.md`](../../skill-anatomy.md)。