---
name: agent-project-structure
description: "Initializes and maintains a canonical agent-project/ folder structure for AI-assisted development. Defines where plans, memory, tools, knowledge, agent configs, evaluation, observability, deployment, examples, and docs live. Use when starting a new project, or when the project has accumulated ad-hoc doc files that need consolidating."
allowed-tools: "Read Edit Bash Glob Grep Write"
---

# agent-project-structure

## Overview

Agent 项目骨架模板 —— 定义 `agent-project/` 目录下 10 个分类目录(plan / memory / tools / knowledge / agent_core / evaluation / observability / deployment / examples / docs),每个目录放什么类型的内容。

不是 skill 系统的 skill,是**项目层骨架**的 init / 维护纪律。跟 pwf 互补:pwf 管 plan 持久化,这个 skill 管其他 9 类内容。

## When to Use

**Use when:**
- 启动新 agent / LLM 项目
- 项目里散落着 ad-hoc 文档不知道放哪
- 团队多人协作需要统一 doc 约定
- 准备开源 / 教学一个 agent 项目
- 想给 pwf 的 plan / findings / progress 之外建立更多 doc 类别

**NOT for:**
- 非 agent 项目(纯 web app / CLI 工具)
- 已经建立稳定结构、改起来成本高
- 用户明确说"先不要管结构"

## Process

### 1. Apply the canonical 10-folder structure

```
agent-project/
├── 01_planner/          # 长期路线、目标、task breakdown
│   ├── goal.md
│   ├── plan.md
│   ├── task-breakdown.md
│   └── roadmap.md
├── 02_memory/           # 长期/短期/实体记忆、知识图谱
│   ├── long-term-memory.md
│   ├── short-term-memory.md
│   ├── entity-memory.md
│   └── knowledge-graph.md
├── 03_tools/            # 工具描述(API/code/custom)
│   ├── api-tools/       (search.md, weather.md, calculator.md, news.md)
│   ├── code-tools/      (code-executor.md, file-reader.md, terminal.md)
│   └── custom-tools/    (db-query.md, notion.md, slack.md)
├── 04_knowledge/        # RAG、embeddings、向量存储
│   ├── documents/
│   ├── embeddings/
│   ├── vector-store.md
│   ├── rag-pipeline.md
│   └── index-strategy.md
├── 05_agent_core/       # agent 角色、persona、prompt
│   ├── agent.md
│   ├── roles.md
│   ├── persona.md
│   ├── workflow.md
│   ├── system-prompt.md
│   └── prompt-template.md
├── 06_evaluation/       # eval metrics、test cases、benchmarks
│   ├── eval-metrics.md
│   ├── test-cases.md
│   ├── benchmarks.md
│   └── result-analysis.md
├── 07_observability/    # logs、traces、monitoring、alerts
│   ├── logs/
│   ├── traces.md
│   ├── monitoring.md
│   └── alert-rules.md
├── 08_deployment/       # docker、k8s、deploy、env
│   ├── docker/
│   ├── k8s/
│   ├── deploy.md
│   └── env.example
├── 09_examples/         # use cases、demo flows
│   ├── use-cases/
│   └── demo-flows.md
└── 10_docs/             # architecture、best practices、FAQ、changelog
    ├── architecture.md
    ├── best-practices.md
    ├── FAQ.md
    └── changelog.md
```

### 2. Initialize on demand

Not every project needs all 10. Initialize only what's relevant:

- Agent LLM project → all 10
- Tool-using agent → 03_tools + 05_agent_core + 07_observability
- RAG project → 04_knowledge + 05_agent_core + 06_evaluation
- Production agent → + 07_observability + 08_deployment

### 3. Bridge to pwf

The `01_planner/` directory **complements** pwf's `task_plan.md`:

| Where | What |
|---|---|
| pwf `task_plan.md` | Current session phases, in-flight work |
| pwf `findings.md` | Untrusted research data |
| pwf `progress.md` | Session log, test results |
| `01_planner/plan.md` | Long-term plan (multi-session, multi-week) |
| `01_planner/roadmap.md` | Quarter-level milestones |
| `01_planner/goal.md` | Persistent project goals |

**Don't duplicate.** If info lives in pwf, don't write it to `01_planner/` too.

### 4. Naming conventions inside folders

- Markdown files: `lowercase-hyphenated.md`
- Configs: `lowercase-hyphenated.{yaml,json,toml}`
- Scripts: `lowercase-hyphenated.{py,sh,ts}`
- Folders: numbered prefix (`01_`, `02_`) for stable ordering

### 5. Each folder gets a README

`05_agent_core/` → `README.md` (or `agent.md`) describing what goes there. This is the meta-doc — describes the folder's purpose, not its content.

### 6. Keep docs in sync

When code changes, docs change in the **same commit** (or branch). Out-of-sync docs are worse than no docs — they mislead.

## Common Rationalizations

| Excuse | Reality |
|---|---|
| "结构太重了,我直接放根目录" | 直接放根目录 = 散落 = 找不到 = 文档腐烂。结构是检索的索引。 |
| "我只做 RAG,不需要 10 个文件夹" | 只需要 3-4 个。Don't apply the full template, apply what you need. |
| "README.md 在每个文件夹都太多" | 没有 README 的文件夹 = 没人知道里面该放什么。一句话 README 比没有强。 |
| "跟 pwf 的 task_plan.md 重复了" | 不重复:task_plan.md 是 session 内,01_planner/ 是 session 外。 |
| "编号前缀丑,我用字母序" | 字母序不稳定。新加文件夹就乱。数字前缀给稳定顺序。 |

## Red Flags

- 10 个文件夹全空(over-init)
- 文档跟代码脱节(commit 里代码变了,doc 没动)
- `01_planner/plan.md` 跟 `task_plan.md` 内容重复
- 散落在根目录的 `.md` 文件(没进对应目录)
- 没有 README 的文件夹(没人知道里面该放啥)
- 命名不统一(同一概念有 3 种拼写)

## Verification

Before declaring structure initialized, confirm:
- [ ] Relevant subset of folders created (not all 10 by default)
- [ ] Each folder has README / meta doc explaining its purpose
- [ ] pwf files (`task_plan.md` / `findings.md` / `progress.md`) NOT inside `01_planner/`
- [ ] Naming convention consistent across folders
- [ ] No orphan `.md` files in repo root (except README, LICENSE, etc.)

## pwf Integration

Complements pwf by handling **non-plan** docs. The `01_planner/` folder is for long-term planning artifacts; pwf files are for in-session work. They never overlap.

See [pwf-integration.md](../../pwf-integration.md).