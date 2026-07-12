# Extra Skills(选装集 · 10 个)

按项目需求挑。**不必全装**。每个 skill 独立,装了就启用,不装就不影响其他。

## 怎么选

| 你的项目... | 装这些 |
|---|---|
| 任何代码 | `code-simplification` · `security-and-hardening` · `api-and-interface-design` |
| 有 UI | `designer-handoff` · `build-gate-visual-review` |
| 上线运营 | `observability-and-instrumentation` · `performance-optimization` |
| 多人 / 长期 | `documentation-and-adrs` · `interview-me` |
| 用了 planning-with-files | `pwf-enforcer`(把 PWF 软遵守升级为硬触发) |

## 10 个 skill 一览

| Skill | 一句话 |
|---|---|
| [`pwf-enforcer`](./pwf-enforcer/) | 把 PWF 的软遵守变硬触发(OpenCode plugin + AGENTS.md 软提醒) |
| [`build-gate-visual-review`](./build-gate-visual-review/) | build 前用 html-ppt-skill 生成 slide deck,让你可视化审视 |
| [`designer-handoff`](./designer-handoff/) | designer → eng 的 UI/UX spec 交接(用 ui-ux-pro-max) |
| [`interview-me`](./interview-me/) | 一个一个问题问清需求,达到 95% 信心才动手 |
| [`code-simplification`](./code-simplification/) | 不改行为前提下降低代码复杂度 |
| [`api-and-interface-design`](./api-and-interface-design/) | contract-first API 设计(REST/GraphQL/RPC) |
| [`security-and-hardening`](./security-and-hardening/) | 安全审计(用 omo security-research mode) |
| [`performance-optimization`](./performance-optimization/) | 性能调优(profile + 优化) |
| [`observability-and-instrumentation`](./observability-and-instrumentation/) | 加日志/metrics/tracing,生产可见性 |
| [`documentation-and-adrs`](./documentation-and-adrs/) | 记录架构决策,让团队后人能看懂 |

## 依赖关系(顺序装才有效)

某些 skill 依赖其他东西,装之前先确认依赖到位:

| Skill | 需要先装 |
|---|---|
| `build-gate-visual-review` | `html-ppt-skill` 到 `~/.agents/skills/`(`npx skills add https://github.com/lewislulu/html-ppt-skill`) |
| `designer-handoff` | `ui-ux-pro-max-cli` 全局(`npm i -g ui-ux-pro-max-cli`) |
| `pwf-enforcer` | `planning-with-files` 到 `~/.agents/skills/`(`npx skills add https://github.com/OthmanAdi/planning-with-files`) |

## 安装

按需装某个或某几个:

```bash
# 装特定几个
npx skills add https://github.com/meisijiya/Skills \
  --skill pwf-enforcer --skill interview-me

# 或展开 picker 手动选
npx skills add https://github.com/meisijiya/Skills
```

完整写作规范见 [`skill-anatomy.md`](../../skill-anatomy.md)。