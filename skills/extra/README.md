# Extra Skills(选装集 · 26 个)

按项目需求挑。**不必全装**。每个 skill 独立,装了就启用,不装就不影响其他。

## 怎么选

按 group 选,而不是逐个挑选。同一 group 的 skill 通常一起装。

| 你的项目... | 装这些 group |
|---|---|
| 任何代码 | `security` (应用层 / 供应链 / 事故响应 / AI 盲点 / GHA / threat-model / ownership-map / dep 信任 / 栈化编码) |
| 有 contract / 状态 / 时序 / 并发 / 不可逆 / verification-blind-spot 风险 | 在 `security` 之外加 `contract-strengthening`(Phase 1.25 open-world / non-exhaustive 风险分类;可选装) |
| 上线运营 | `cicd` (pre-ship-gate / closed-loop-delivery) + `observability` (observability / performance / k6 / incident-playbook) |
| 有 UI | `domain` 中加 `designer-handoff`;仅在明确要求视觉 deck 或教学 deck 时再加 `build-gate-visual-review` |
| 多人 / 长期 | `meta` 中加 `slice-review` + `test-guard`(测试质量) |
| 写技术文章要核查事实 | `domain` 中加 `verify-chain` |
| 把反复做的活动形式化成可执行 spec | `domain` 中加 `loop-me` |
| 创建/编辑 skill | `meta` 中加 `writing-skills` |
| AI 刚生成/修改了代码,要审查盲区 | `security` 中加 `ai-code-blindspots` |

## 26 个 skill 一览(按 group)

**注意**：`teacher-skill` 为本地适配型 skill(8 个含 `meisijiya-domain` 域),不计入 26 的统计;若安装到 `~/.agents/skills/teacher-skill/SKILL.md` 则自动被 OMO skill loader 发现,无需 marketplace 同步。

### security (9)
| Skill | 一句话 |
|---|---|
| [`security-and-hardening`](./security-and-hardening/) | 应用层信任边界检查 + 路由 OMO `security-research` 做深度审计;**应用层**代码(input / auth / 集成),supply chain / deployment 走 `security-devsecops` |
| [`security-devsecops`](./security-devsecops/) | 供应链 + 部署安全(deps / SBOM / secrets rotation / CI/CD / IaC / container / pre-deploy gate);与 [`supply-chain-risk-auditor`](./supply-chain-risk-auditor/) 一前一后(本 skill 跑 CVE 扫描,那个跑依赖维护者信号审计) |
| [`security-incident-response`](./security-incident-response/) | 事后响应(detect / triage / contain / eradicate / recover / postmortem,NIST CSF 简化);与 [`production-incident-playbook`](./production-incident-playbook/) 一起 —— 那个管非安全事故,这个管安全事故 |
| [`gha-security-review`](./gha-security-review/) | GitHub Actions workflow 文件审计(action-permission / expression-injection / unpinned actions / workflow_run / artifact-poisoning);每条 finding 必带 exploit scenario |
| [`security-threat-model`](./security-threat-model/) | AppSec 威胁建模(trust boundaries / STRIDE / attacker profile / file:line / prioritized mitigations);设计期与重大变更前运行 |
| [`security-ownership-map`](./security-ownership-map/) | git 历史人员↔文件拓扑(orphan sensitive / hidden owners / bus-factor / 维护者集中度);重大 refactor 前 + 事故后治理 |
| [`supply-chain-risk-auditor`](./supply-chain-risk-auditor/) | 依赖维护者信号审计(单维护者 / 弃坑 / 低热度 / 身份卫生 / 社工抵抗);加 dep 前 + 季度治理 |
| [`stack-security-coder`](./stack-security-coder/) | 前端 / 后端 / 移动三栈 coding checklist(XSS-CSP-cross-origin / SQL-NoSQL-authz-SSRF-webhook / WebView-certs-storage-biometric);`security-and-hardening` 的栈化补强 |
| [`ai-code-blindspots`](./ai-code-blindspots/) | AI 生成/修改代码盲区(边界检查 / 错误处理可见性 / 环境兼容 / deprecated API / 硬编码配置 / 不可见失败);互补 omo `remove-ai-slops`(各管一半) |

### cicd (2)
| Skill | 一句话 |
|---|---|
| [`pre-ship-gate`](./pre-ship-gate/) | 部署前只读审计 + 部署后 smoke 验证,捕"deploy exit 0 ≠ 真在跑"类(migrations / flags / CDN / canary / env / shadow);read-only |
| [`closed-loop-delivery`](./closed-loop-delivery/) | 5-gate 证据链(implemented / reviewed / deployed / healthy-at-runtime / reachable-by-users),把"完成"扩展到"在 prod 安全运行" |

### observability (4)
| Skill | 一句话 |
|---|---|
| [`observability-and-instrumentation`](./observability-and-instrumentation/) | 加日志/metrics/tracing,生产可见性 |
| [`performance-optimization`](./performance-optimization/) | 后端 profile + 优化(后端 / 数据库 / profiling;前端 CWV 走 OMO `frontend` skill);与 [`k6-load-testing`](./k6-load-testing/) 一前一后 |
| [`k6-load-testing`](./k6-load-testing/) | 部署前性能准入门(smoke / load / stress / spike / soak),latency-percentile + error-budget 阈值,PASS/FAIL gate |
| [`production-incident-playbook`](./production-incident-playbook/) | 端到端事故处理(in-flight runbook 阶段 + blameless postmortem 模板 + 5-whys + 结构化 action items) |

### meta (4)
| Skill | 一句话 |
|---|---|
| [`writing-skills`](./writing-skills/) | meta: 创建 / 编辑 skill 用 TDD-for-docs 流程 |
| [`slice-review`](./slice-review/) | per-slice 轻量审查(spec compliance + code quality,2 verdicts);与 OMO `review-work` 互补 |
| [`contract-strengthening`](./contract-strengthening/) | Phase 1.25 open-world / non-exhaustive 风险分类(contract / state / timing / concurrency / boundary / dependency / reversibility / verification-blind-spot);`disable-model-invocation: true` 仅用户触发 |
| [`test-guard`](./test-guard/) | 7-check AI 测试质量审计(skip / over-mocking / tautology / boundary / fake-deps / lazy-assert / flakiness);与 `test-driven-development` 互补 |

### domain (8)
| Skill | 一句话 |
|---|---|
| [`build-gate-visual-review`](./build-gate-visual-review/) | 意图门控的实现前对齐:普通设计对齐只输出 Markdown / 文本;明确要求响应式 HTML 页面时通过 OMO 内置 `frontend` 渲染;教学型内容叠加 [`teacher-skill`](./teacher-skill/) pedagogy overlay |
| [`designer-handoff`](./designer-handoff/) | designer → eng 的 UI/UX spec 交接(用 ui-ux-pro-max) |
| [`api-and-interface-design`](./api-and-interface-design/) | contract-first API 设计(REST/GraphQL/RPC) |
| [`documentation-and-adrs`](./documentation-and-adrs/) | 只记录重大架构决策(ADR,跨人 / 跨时 / 不可逆);日常文档走项目级 AGENTS.md / notepad |
| [`improve-codebase-architecture`](./improve-codebase-architecture/) | codebase-wide 健康巡检(weekly / post-surge / on-boarding);Ousterhout deep/shallow 评分;**proposal-only** —— 改架构走 `incremental-implementation` |
| [`verify-chain`](./verify-chain/) | 3 角色文章事实核查流水线(Critic → Verifier × N → Repairer);输出 `.verification/article-verified.md` + `.verification/verification-report.md` |
| [`loop-me`](./loop-me/) | 把反复做的活动形式化成可执行 workflow spec(stateful grilling session;产物 `workflows/*.md` + `NOTES.md`,**不是实现**);`disable-model-invocation: true` 仅用户 `/loop-me` 触发 |
| [Local] [`teacher-skill`](./teacher-skill/) | meisijiya-adapted 教学编排(6 阶段 SOP / 3 级诊断 / 4 类 quiz / 刻意练习 / 跨学科 / 反蒸馏);不自动加载,仅在 `build-gate-visual-review` HTML page 模式 + §5 reminder 中被提示;`allowed-tools: Read` only;安装在 `~/.agents/skills/teacher-skill/` |

## 依赖关系(顺序装才有效)

某些 skill 依赖其他东西,装之前先确认依赖到位:

| Skill | 需要先装 |
|---|---|
| `build-gate-visual-review` | 无外部依赖;HTML 页面用 OMO 内置 `frontend`(visual-engineering category);教学型 overlay 通过 [`teacher-skill`](./teacher-skill/) §5 reminder 加载 |
| `teacher-skill` (local) | 已合入 `~/.agents/skills/teacher-skill/SKILL.md`;上游为 `chentao326/teacher-skill`(MIT),本仓库只搬运教学概念(6 阶段 SOP / 3 级诊断 / 4 类 quiz 等),不带 `allowed-tools: Bash` 与 Python 脚本;不自动加载,仅在 `build-gate-visual-review` 教学 deck 模式中被提示 |
| `designer-handoff` | `ui-ux-pro-max-cli` 全局(`npm i -g ui-ux-pro-max-cli`) |
| `security-and-hardening` Step 6.5 | OMO `security-research` 内置 skill(默认随 omo 安装) |
| `security-devsecops` Process | OMO `security-research`(production-critical pre-deploy audit) + `oracle`(IaC 架构决策)+ `websearch`(最新 CVE)+ `context7`(安全工具文档)+ `grep_app`(in-the-wild fix 搜索) |
| `security-incident-response` Process | OMO `security-research`(post-incident PoC 验证)+ `oracle`(影响评估 / 决策链)+ `websearch`(CVE 公告 / 攻击 IOC)+ `context7`(IR 工具文档)+ `review-work`(post-incident code review) |
| `production-incident-playbook` Process | OMO `oracle`(root-cause 校准)+ `review-work`(postmortem 审)+ `websearch`(同行业类似事故)+ `context7`(runbook tooling docs) |
| `incremental-implementation` / `verification-before-completion` 的 OMO 桥接 | OMO `review-work` / `visual-qa` 内置 skill(默认随 omo 安装) |
| `verify-chain` | 仅需要 OMO `sisyphus-junior` 或 `librarian` agent(默认随 omo 安装)用于并行 Verifier subagents;`WebSearch` + `WebFetch` 工具 |
| `loop-me` | 无外部依赖(状态在用户工作区根 `workflows/` + `NOTES.md`);`disable-model-invocation: true` 仅 `/loop-me` 触发,防与 `brainstorming` 路由竞争;输出 spec 可喂 OMO `/goal` 或 `incremental-implementation` |
| `contract-strengthening` | 互补 core `spec-driven-development`(Phase 1.25 contract review)+ `verification-before-completion`(counterexample gate);external verifiers 工具是 optional,**永不**自动安装;可选 OMO `oracle`(候选 verification backend 调研)+ `general`(bounded empirical runs) |
| `ai-code-blindspots` | 必须先装 `verification-before-completion`(`core/`,默认随 omo 装,Layer 3 路由加载点);可选 OMO `deep` agent category 用于 sub-agent scan(失败时自动降级为 grep-only 模式) |
| `gha-security-review` / `stack-security-coder` | OMO `oracle` agent 用于"is this permissions: block actually minimal?" / "is this SQL finding actually exploitable?" 类判定 |
| `pre-ship-gate` / `closed-loop-delivery` / `k6-load-testing` | 部署平台工具已装(kubectl / helm / vercel / fly / aws / gcloud / k6 至少其一);无 OMO 必需依赖 |
| `closed-loop-delivery` Gate 4 | OMO `observability-and-instrumentation` (本组内) — 24h+ 监控数据来源 |
| `supply-chain-risk-auditor` | GitHub API access(公开仓库无需 token;私有需 `GITHUB_TOKEN` env);optional OMO `websearch` 查同行业事故 |
| `security-ownership-map` / `diagnosing-bugs` | git CLI 标准工具,无 OMO 必需依赖;可选 OMO `oracle` 校准假设 |

## 安装

按 group 或按 skill 装:

```bash
# 装特定几个
npx skills add https://github.com/meisijiya/Skills \
  --skill security-and-hardening --skill contract-strengthening

# 装整个 group(列出 group 内所有 skill 路径)
# 通过 `npx skills add` 的 picker 选;group 在 picker 中以 meisijiya-security /
# meisijiya-cicd / meisijiya-observability / meisijiya-meta / meisijiya-domain 形式展示

# 装全部(必装 + 选装)
# 见根 README 的 `## 安装 → 方式二` 段:6 条 group 命令依次复制粘贴执行
# 或用 interactive picker 逐个勾选:`npx skills add meisijiya/Skills`
```

完整写作规范见 [`skill-anatomy.md`](../../skill-anatomy.md)。