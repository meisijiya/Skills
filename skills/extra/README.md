# Extra Skills(选装集 · 16 个)

按项目需求挑。**不必全装**。每个 skill 独立,装了就启用,不装就不影响其他。

## 怎么选

| 你的项目... | 装这些 |
|---|---|
| 任何代码 | `security-and-hardening` · `security-devsecops` · `security-incident-response` · `api-and-interface-design` · `improve-codebase-architecture` |
| 有 contract / 状态 / 时序 / 并发 / 不可逆 / verification-blind-spot 风险 | `contract-strengthening`(Phase 1.25 open-world / non-exhaustive 风险分类;可选装) |
| 有 UI | `designer-handoff`;仅在明确要求实现前文本对齐、视觉 deck 或教学 deck 时再装 `build-gate-visual-review` |
| 上线运营 | `observability-and-instrumentation` · `performance-optimization` |
| 多人 / 长期 | `documentation-and-adrs` |
| 写技术文章要核查事实 | `verify-chain` |
| 把反复做的活动形式化成可执行 spec | `loop-me` |
| 创建/编辑 skill | `writing-skills` |
| AI 刚生成/修改了代码,要审查盲区 | `ai-code-blindspots` |

## 16 个 skill 一览

| Skill | 一句话 |
|---|---|
| [`writing-skills`](./writing-skills/) | meta: 创建 / 编辑 skill 用 TDD-for-docs 流程。也用于"我老做 X,把 X 提炼成 skill" |
| [`build-gate-visual-review`](./build-gate-visual-review/) | 意图门控的实现前对齐:普通设计对齐只输出 Markdown / 文本;明确要求视觉 deck 或教学 deck 时才按需使用 html-ppt;UI、build、复杂度或 PWF phase 单独出现时默认跳过,**不是人工 QA** |
| [`designer-handoff`](./designer-handoff/) | designer → eng 的 UI/UX spec 交接(用 ui-ux-pro-max) |
| [`api-and-interface-design`](./api-and-interface-design/) | contract-first API 设计(REST/GraphQL/RPC) |
| [`security-and-hardening`](./security-and-hardening/) | 设计时信任边界检查 + 路由 OMO `security-research` 做深度审计;**应用层**代码(input / auth / 集成),supply chain / deployment 走 `security-devsecops` |
| [`security-devsecops`](./security-devsecops/) | 供应链 + 部署安全(deps / SBOM / secrets rotation / CI/CD / IaC / container / pre-deploy gate);OMO `security-research` + `oracle` + `websearch` + `context7` 增强 |
| [`security-incident-response`](./security-incident-response/) | 事后响应(detect / triage / contain / eradicate / recover / postmortem,NIST CSF 简化);OMO `security-research` 跑 post-incident PoC + `oracle` 决策链 + `websearch` 查 IOC |
| [`performance-optimization`](./performance-optimization/) | 后端 profile + 优化(后端 / 数据库 / profiling;前端 CWV 走 OMO `frontend` skill) |
| [`observability-and-instrumentation`](./observability-and-instrumentation/) | 加日志/metrics/tracing,生产可见性 |
| [`documentation-and-adrs`](./documentation-and-adrs/) | 只记录重大架构决策(ADR,跨人 / 跨时 / 不可逆);日常文档走项目级 AGENTS.md / notepad |
| [`improve-codebase-architecture`](./improve-codebase-architecture/) | codebase-wide 健康巡检(weekly / post-surge / on-boarding);Ousterhout deep/shallow 评分;**proposal-only** —— 改架构走 `incremental-implementation` |
| [`verify-chain`](./verify-chain/) | 3 角色文章事实核查流水线(Critic 提断言 → Verifier × N 联网核查 → Repairer 修复);输出 `.verification/article-verified.md` + `.verification/verification-report.md` |
| [`loop-me`](./loop-me/) | 把反复做的活动形式化成可执行 workflow spec(stateful grilling session;产物 `workflows/*.md` + `NOTES.md`,**不是实现**);`disable-model-invocation: true` 仅用户 `/loop-me` 触发 |
| [`contract-strengthening`](./contract-strengthening/) | 可选装 extra:open-world / non-exhaustive 风险分类(contract / state / timing / concurrency / boundary / dependency / reversibility / verification-blind-spot),Phase 1.25 contract review(attested Spec 之后、implementation 之前);resource/isolation-first,external verifiers **永不**自动安装;global-install 例外需 GREEN/YELLOW/RED consent gate;**不做** correctness guarantee |
| [`ai-code-blindspots`](./ai-code-blindspots/) | 审查 AI 生成/修改代码的盲区(7 类:边界检查 / 错误处理可见性 / 环境兼容 / deprecated API / 硬编码配置 / 不可见失败);互补 omo 内置 `remove-ai-slops`(各管一半);4 层软路由触发(description 严格化 + dispatcher Priority + `verification-before-completion` Process 嵌入 + plugin hook 暂缓) |

## 依赖关系(顺序装才有效)

某些 skill 依赖其他东西,装之前先确认依赖到位:

| Skill | 需要先装 |
|---|---|
| `build-gate-visual-review` | 仅显式视觉 / 教学 deck 模式需要 `html-ppt-skill` 到 `~/.agents/skills/`(`npx skills add https://github.com/lewislulu/html-ppt-skill`);文本对齐与默认跳过不需要 |
| `designer-handoff` | `ui-ux-pro-max-cli` 全局(`npm i -g ui-ux-pro-max-cli`) |
| `security-and-hardening` Step 6.5 | OMO `security-research` 内置 skill(默认随 omo 安装) |
| `security-devsecops` Process | OMO `security-research`(production-critical pre-deploy audit) + `oracle`(IaC 架构决策)+ `websearch`(最新 CVE)+ `context7`(安全工具文档)+ `grep_app`(in-the-wild fix 搜索) |
| `security-incident-response` Process | OMO `security-research`(post-incident PoC 验证)+ `oracle`(影响评估 / 决策链)+ `websearch`(CVE 公告 / 攻击 IOC)+ `context7`(IR 工具文档)+ `review-work`(post-incident code review) |
| `incremental-implementation` / `verification-before-completion` 的 OMO 桥接 | OMO `review-work` / `visual-qa` 内置 skill(默认随 omo 安装) |
| `verify-chain` | 仅需要 OMO `general` agent(默认随 omo 安装)用于并行 Verifier subagents;`WebSearch` + `WebFetch` 工具 |
| `loop-me` | 无外部依赖(状态在用户工作区根 `workflows/` + `NOTES.md`);`disable-model-invocation: true` 仅 `/loop-me` 触发,防与 `brainstorming` 路由竞争;输出 spec 可喂 OMO `/goal` 或 `incremental-implementation` |
| `contract-strengthening` | 互补 core `spec-driven-development`(Phase 1.25 contract review)+ `verification-before-completion`(counterexample gate);external verifiers 工具是 optional,**永不**自动安装;可选 OMO `oracle`(候选 verification backend 调研)+ `general`(bounded empirical runs) |
| `ai-code-blindspots` | 必须先装 `verification-before-completion`(`core/`,默认随 omo 装,Layer 3 路由加载点);可选 OMO `deep` agent category 用于 sub-agent scan(失败时自动降级为 grep-only 模式) |

## 安装

按需装某个或某几个:

```bash
# 装特定几个
npx skills add https://github.com/meisijiya/Skills \
  --skill security-and-hardening --skill contract-strengthening

# 或展开 picker 手动选
npx skills add https://github.com/meisijiya/Skills
```

完整写作规范见 [`skill-anatomy.md`](../../skill-anatomy.md)。