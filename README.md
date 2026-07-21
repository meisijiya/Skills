# meisijiya-skills

Personal fork of [addyosmani/agent-skills](https://github.com/addyosmani/agent-skills), adapted for the [oh-my-openagent](https://github.com/code-yeongyu/oh-my-openagent) (omo) + [planning-with-files](https://github.com/OthmanAdi/planning-with-files) (pwf) stack.

## 与上游的差异

- **omo 之上补足**:omo 已内置的(frontend-ui-ux, git-master, playwright, review-work, remove-ai-slops, init-deep …)不重复。
- **omo 深度集成**:fork 的每个 skill 显式利用 omo 的 MCPs( context7 / grep_app / websearch / lsp)、agents( sisyphus / prometheus / atlas / oracle / librarian / multimodal-looker )、built-in skills( git-master / frontend-ui-ux / review-work / init-deep )和 modes( hyperplan / security-research / ultrawork )。完整 omo ↔ skills 跨参考图见 `~/.config/opencode/AGENTS.md`(`meisijiya-extras` 段)。
- **pwf 硬遵守加强**:装 OpenCode 插件(`pwf-enforcer` 提供模板)把 pwf 的软遵守升级为硬触发 hook。
- **意图门控的构建前对齐**:普通设计对齐只输出 Markdown / 文本；只有用户明确要求视觉 deck 或教学 deck 时才按需使用 [html-ppt-skill](https://github.com/lewislulu/html-ppt-skill) 渲染 HTML。项目有 UI、即将 build、复杂或使用 PWF 都不会单独触发 HTML 生成。
- **designer 协作**:用 [ui-ux-pro-max-skill](https://github.com/nextlevelbuilder/ui-ux-pro-max-skill) 为 designer 类 agent 生成 UI/UX design spec。
- **双目录结构**:`core/` 必装集 + `extra/` 选装集。仓库根的 `.claude-plugin/marketplace.json` 是 `vercel-labs/skills` CLI 原生的 skill 发现 + 展示分组 source(`meisijiya-core` / `meisijiya-extra` 两组);它是 skills CLI 的概念,**不是 OpenCode Plugin Marketplace** — OpenCode plugin 走 `~/.config/opencode/plugins/`,不经此文件。

## 仓库结构

```
meisijiya-skills/
├── README.md                  ← 本文件
├── AGENTS.md                  ← 仓库自描述 + skill 元信息 source(inject 脚本从这里读)
├── skill-anatomy.md           ← SKILL.md 写作规范
├── pwf-integration.md         ← 跟 pwf 协作的约定(8+4+3+2 phase 映射)
├── docs/
│   ├── omo-agent-skill-config.md   ← 各 omo agent 的 skill 列表配置指南(20 SKILL.md 索引)
│   └── p0-outline.md              ← 归档(已 ship)
├── skills/
│   ├── core/                 ← 必装集(8 个)
│   │   ├── README.md          ← 8 个 skill 详情 + 必装理由
│   │   ├── using-meisijiya-skills/
│   │   ├── brainstorming/                  ← HARD-GATE pre-design exploration(adapted from superpowers)
│   │   ├── spec-driven-development/        ← spec-before-code,lock PRD to task_plan.md
│   │   ├── incremental-implementation/    ← vertical slices with dep/HITL-AFK metadata,bridge to OMO review-work
│   │   ├── test-driven-development/
│   │   ├── verification-before-completion/  ← Iron Law;bridge to OMO review-work/visual-qa (adapted from superpowers)
│   │   ├── debugging-and-error-recovery/
│   │   └── source-driven-development/       ← verify API against docs (narrowed triggers)
│   └── extra/                ← 选装集(10 个,按需装)
│       ├── README.md          ← 10 个 skill + "怎么选" 决策表
│       ├── writing-skills/                 ← meta-only;create/edit skills (TDD-for-docs)
│       ├── pwf-enforcer/
│       ├── build-gate-visual-review/        ← intent-gated pre-build alignment (Markdown by default; html-ppt only for explicit visual/teaching decks)
│       ├── designer-handoff/
│       ├── api-and-interface-design/
│       ├── security-and-hardening/          ← trust-boundary hardening;depth audit via OMO security-research
│       ├── performance-optimization/        ← backend profile + measure-first
│       ├── observability-and-instrumentation/
│       ├── documentation-and-adrs/          ← architectural ADRs only
│       └── improve-codebase-architecture/   ← codebase-wide 健康巡检,Ousterhout deep/shallow 评分,proposal-only
├── scripts/
│   ├── validate-skills.sh          ← YAML frontmatter + 结构检查
│   ├── install.sh                 ← 默认装到 .opencode/skills/(项目级);--global 装到 ~/.agents/skills/(高级)
│   └── inject-agents-md.sh        ← 把 skill meta-info 追加到 AGENTS.md(opt-in,幂等)
├── bin/
│   └── meisijiya                  ← lite CLI:plugin list / plugin verify
└── evals/
    └── cases/                 ← 每个 skill 的 eval case(18 个)
```

## 安装

### 快速安装(推荐:`vercel-labs/skills` CLI)

`npx skills add <repo>` 默认装到当前目录 `./.agents/skills/`(项目级),加 `-g` 装到 `~/.agents/skills/`(用户级,canonical 路径)。OpenCode 作为 universal agent 直接读 canonical 的 `.agents/skills/`;非 universal agent 可能拿到 canonical 副本的 symlink。

```bash
# 交互式(展示 meisijiya-core / meisijiya-extra 两组,按需挑选)
npx skills add meisijiya/Skills

# 装某个选装
npx skills add meisijiya/Skills --skill pwf-enforcer

# 装多个选装
npx skills add meisijiya/Skills --skill pwf-enforcer --skill security-and-hardening

# 看仓库有哪些 skill 可装
npx skills add meisijiya/Skills --list

# 装到项目级(cwd 下的 .agents/skills/)
npx skills add meisijiya/Skills

# 全局装(到 ~/.agents/skills/)
npx skills add meisijiya/Skills -g
```

`.agents/skills` 是 `vercel-labs/skills` CLI 的 canonical 路径;**universal agent**(如 OpenCode)直接读它,**non-universal agent** 可能收到 canonical 副本的 symlink。如需强制 direct copy 而不要 symlink,用 `--copy`。

## Skills

按用途拆成两个子目录,每个有自己的 README 详细解释:

- **必装集**(8 个,所有项目都装):[`skills/core/README.md`](./skills/core/README.md) — 工作流骨架
- **选装集**(10 个,按项目需求挑):[`skills/extra/README.md`](./skills/extra/README.md) — 含"怎么选"决策表 + 依赖关系

> 不确定装哪个 → 先看 [`skills/extra/README.md`](./skills/extra/README.md) 的"怎么选"表,按你项目特征对号入座。

### 高级:`scripts/install.sh`(项目级 install / 自定义路径)

仅当你**不能或不想**用 skills CLI、或者需要非标准路径时,才用这个脚本:

```bash
# 项目级 install: 装到 cwd 的 .opencode/skills/(omo 原生路径)
scripts/install.sh

# 装到指定项目
scripts/install.sh --target /path/to/your-project

# 装 core/ + 指定的几个 extra/
scripts/install.sh --extra pwf-enforcer --extra security-and-hardening

# 装全部(必装 + 选装)
scripts/install.sh --all-extra

# 看可选的 extra/
scripts/install.sh --list

# 全局装(到 ~/.agents/skills/,跟 npx skills add 同位置 — 统一管理)
scripts/install.sh --global

# 预览但不复制
scripts/install.sh --dry-run
```

> 注意:只有 `scripts/install.sh --global` 跟 `npx skills add -g` 共享 `~/.agents/skills/`。**project-level 安装**有两条目标不同的路径:`scripts/install.sh` 项目级默认到 `<project>/.opencode/skills/`(omo 原生),`npx skills add` 项目级到 `<project>/.agents/skills/`(skills CLI 原生)。OpenCode 原生扫描两者 — **但每个项目推荐只选一种安装方法**:同时并存会导致同名 Skill 出现两份副本,且 `update-source` 模糊(不知道该 pull 哪个)。

### Lite CLI:`bin/meisijiya`(OpenCode plugin 管理)

skill 安装用 `npx skills add`(已存在),**plugin 管理没有现成 CLI**,所以做了个 65 行 lite 工具,只覆盖痛的两件事:

```bash
# 列出已装 plugin(在 ~/.config/opencode/plugins/,匹配 *.ts 和 *.js)
./bin/meisijiya plugin list

# 验证 .ts plugin(走 bun check;*.js 不在范围内)
./bin/meisijiya plugin verify

# 装到 PATH(任意一处)
ln -s "$(pwd)/bin/meisijiya" ~/.local/bin/meisijiya
```

**只做 `plugin list` + `plugin verify`,不做 plugin add/remove/inject/status/update**(那些是 YAGNI,等真痛了再加)。`plugin verify` 走 `bun check`,没有 bun 会报错提示安装。**注意:**本 README 文档化的 hard-layer plugin(`meisijiya-skills.js`)是 `.js`,**不被 `plugin verify` 覆盖**。

### OpenCode Plugin(硬层 skill 注入)

`.opencode/plugins/meisijiya-skills.js` 是 hard-layer OpenCode 插件,跟 [`obra/superpowers` 的 `superpowers.js`](https://github.com/obra/superpowers/blob/main/.opencode/plugins/superpowers.js) 同款机制 — 让 `using-meisijiya-skills` 在 LLM 每个调用前都出现在 firstUser.parts 里,触发模型真正高频 invoke skills(否则只在 `<available_skills>` 列表里软躺着,模型不会主动 invoke)。

**安装:**

```bash
mkdir -p ~/.config/opencode/plugins
cp .opencode/plugins/meisijiya-skills.js \
   ~/.config/opencode/plugins/meisijiya-skills.js
```

> 本 README 文档化的是 `cp` 实复制路径(经验证可工作);`ln -sf` 软链路径行为未做独立验证,若需使用请自行核对 plugin loader 当前实现。

**Reload:** OpenCode 不会自动重读 plugins 目录。改完插件或 bootstrap 内容后,**退出 / 重启 OpenCode 后重开 session**。

**禁用:** `rm ~/.config/opencode/plugins/meisijiya-skills.js`

**机制**(与 superpowers 同款):

- `config` hook — 重新声明 `~/.agents/skills` 到 OpenCode skill tool(OpenCode 已原生扫描该路径,此 re-registration 属 defensive / redundant,不是发现 skill 的前提)
- `experimental.chat.messages.transform` hook — 每 step 把 bootstrap 内容 unshift 到 `firstUser.parts`
- **In-memory only,不持久化 DB**:OpenCode 每 step 从 DB 重载 messages,bootstrap 每次重新注入(不是 bug,是 superpowers 同款设计)
- **bootstrap 锚定在 firstUser**:只第一条 user message 含 bootstrap,后续 user message 不污染;LLM 通过 conversation history 每步都看到
- 严格 in-place mutation([issue #25754](https://github.com/anomalyco/opencode/issues/25754):`output.messages = ...` 是静默 no-op)

**Acceptance test:** 开新 session,发 `let's make X`(X 任意),期望模型先 announce `"Using brainstorming to ..."` 或其他 skill,再问需求。**不要直接 dive in 写代码**。

**已知限制**(per [superpowers issue #54](https://github.com/obra/superpowers/issues/54)):即使 hard-layer + superpowers-grade 强措辞,调用率仍 ~80-90%,不是 100%。模型有时仍能反 rationalization 绕过。

**SDK 验证**(2026-07):hook 名 + 签名匹配 OpenCode 官方 [`packages/plugin/src/index.ts`](https://raw.githubusercontent.com/anomalyco/opencode/dev/packages/plugin/src/index.ts)。

## 前置依赖

- **oh-my-openagent** 必须安装(`bunx oh-my-openagent install`,本 fork 围绕 omo 设计)
- **planning-with-files**(完整 PWF 工作流推荐):`npx skills add OthmanAdi/planning-with-files --skill planning-with-files -g`。注:`/plugin marketplace add ...` 是 Claude Code 专属命令,OpenCode 用 skills CLI(`npx skills add`)
- **可选**:`npm i -g ui-ux-pro-max-cli`(designer-handoff 需要)
- **可选**:`npx skills add https://github.com/lewislulu/html-ppt-skill -g`(仅 `build-gate-visual-review` 的显式视觉 / 教学 deck 模式需要,装到 `~/.agents/skills/`;文本对齐与默认跳过不需要)

## 写作规范

参见 [skill-anatomy.md](./skill-anatomy.md)。

## 跟 pwf 的协作

参见 [pwf-integration.md](./pwf-integration.md)。

## License

MIT

---

## 当前状态

最近 tag: **v0.5.2**(19 个 SKILL.md / 19 个 eval case;**8 `core/` + 11 `extra/`**)

### Unreleased

- 22 个 SKILL.md / 22 个 eval case;**8 `core/` + 14 `extra/`**
- **OMO-native alignment Phase 2**:根据 [omo.dev/zh](https://omo.dev/zh) 框架深度融合。`using-meisijiya-skills` Priority 表 8 行,加 `ulw` / `ultrawork` 触发(明示无 skill,Sisyphus ultrawork mode 处理)+ omo Intent Gate 互斥说明;`AGENTS.md` Section A "omo integration" 块从 6→14 个 skill;`observability-and-instrumentation` / `pwf-enforcer` (boulder bridge 占位) / `incremental-implementation` §7 (`/start-work` 显式触发) / `improve-codebase-architecture` §1 (Team Mode 加速) 各加 `## omo Integration` 段。
- **OMO-native alignment Phase 1**:`brainstorming` description + `## omo Integration` 章节明确"in-context 对应 Prometheus Mode (Tab / `@plan`)";`spec-driven-development` 加 omo 集成段(Spec vs Prometheus Plan / Momus 评审边界);`docs/omo-agent-skill-config.md` 修过期(18→22 + 6 个新 skill 加入 per-agent 表)。
- **新增 security-incident-response**([`skills/extra/security-incident-response/`](./skills/extra/security-incident-response/SKILL.md)):事后响应流程,按 NIST CSF 简化为 6 阶段(Detect / Triage / Contain / Eradicate / Recover / Postmortem)。OMO 集成:`security-research` mode 跑 post-incident PoC 验证漏洞彻底修补;`oracle` agent 决策链(影响评估 / 通知时机);`websearch` MCP 查 CVE 公告 / 攻击 IOC;`context7` MCP 查 IR 工具文档;`review-work` skill 跑 post-incident code review。**对非专业个人开发者价值**:假设自己会遭遇事件,流程确保"出问题时还能做对事"——blameless postmortem + 5 whys 防止下次同原因再来。
- **新增 security-devsecops**([`skills/extra/security-devsecops/`](./skills/extra/security-devsecops/SKILL.md)):供应链 + 部署安全。6 步 Process(dep scan / SBOM / secrets rotation / CI/CD pipeline / IaC + container / pre-deploy gate)。OMO 集成:`security-research` mode 跑 production-critical pre-deploy audit;`oracle` agent 答 IaC 架构问题;`websearch` MCP 查最新 supply chain CVE;`context7` MCP 查安全工具文档(trivy / gitleaks / OPA);`grep_app` MCP 搜 GitHub 找 CVE in-the-wild fix。与 `security-and-hardening`(应用层)和 `security-incident-response`(事后)三分安全生命周期。
- **security-and-hardening 瘦身**:从 application-layer + supply chain + deployment 三合一收窄为 application-layer only。删除原 `Step 5` Dependency hygiene(挪至独立 skill);`Step 7` 改名为 `Pre-merge code review gate`,去掉 dependency / deploy 部分;Common Rationalizations / Red Flags / Verification 同步收紧。eval case 第 3 个 behavioral 重写为 app-layer focused(原 "Before deploying our auth refactor" → "Before merging our auth refactor")。
- **新增 loop-me**([`skills/extra/loop-me/`](./skills/extra/loop-me/SKILL.md)):把反复做的活动形式化成可执行 workflow spec —— stateful grilling session(一问一答、每问带推荐答案),产物 `workflows/*.md` + `NOTES.md`(用户工作区根),**不是实现**。`disable-model-invocation: true` 仅用户 `/loop-me` 触发,防与 `brainstorming` 路由竞争;下游可喂 OMO `/goal`(持续执行)或 `incremental-implementation`(构建脚本)。fork 自 [`mattpocock/skills@in-progress/loop-me`](https://github.com/mattpocock/skills/tree/main/skills/in-progress/loop-me),按 meisijiya-skills 6 段式 + OMO 生态适配。
- **AGENTS.md 同步修复**:`fdad98a` 加 verify-chain 后 Section A 计数停在 `(10)`(实际 11),本 commit 一并修到 `(12)` 并在 catalog 列表补 verify-chain + loop-me
- **新增 verify-chain**([`skills/extra/verify-chain/`](./skills/extra/verify-chain/SKILL.md)):3 角色文章事实核查流水线 —— Critic 提断言 → Verifier × N 并行联网核查(独立 context)→ Repairer 最小化修复。输入 IT 技术文章,输出 `.verification/article-verified.md` + `.verification/verification-report.md`。`prompts/{critic,verifier,repairer}.md` 3 个支撑文件随 `npx skills add` 完整递归复制(per `vercel-labs/skills` v1.5.19+ `installSkillForAgent` → `copyDirectory` 实现)
- **skill-anatomy.md 新增** `## 安装完整性(Install Integrity)` 节,说明 `npx skills add` 递归复制原理、硬排除集(`metadata.json` + `.git/` + `__pycache__/` + `__pypackages__/`)、手验方法;引用 `pwf-enforcer/templates/pwf-enforcer.ts` 作为既有非扁平 skill 范例
- **删除 alias**(`skills/extra/interview-me` 与 `skills/extra/code-simplification`):两个 backward-compat alias 已下线,active 引用全部迁至 `brainstorming` 与 OMO `refactor` / `ponytail-review` / `remove-ai-slops`;`incremental-implementation` 增强为 Kanban ticket board + Tracer Bullet 首条全链路切片
- **新增 improve-codebase-architecture**([`skills/extra/improve-codebase-architecture/`](./skills/extra/improve-codebase-architecture/SKILL.md),Matt Pocock 风格):codebase-wide 周期性健康巡检,Ousterhout deep/shallow 评分,**proposal-only** —— 改架构仍走 `incremental-implementation`
- **Refactor**:9 个 SKILL.md 的 NOT for 段去硬指(17 个 skill cross-refs 移除),改为纯场景描述,具体哪个 skill 由 description 匹配决定。`using-meisijiya-skills` Skill Priority 表改软:`First Skill to invoke` → `Consider first`;`Then` → `Possible next`;表头加 soft-hints 说明。**原则**:routing 不写死,AI 按 description 自决(per `docs/skill-design-principles.md` 反对过度工程化)

### v0.5.2 — 全量 narrative hygiene

- 19 个 `SKILL.md` 全部清空历史叙事(原本 / 以前 / previously / v0.X 之类的标记等)
- 详细语义保留,但所有"过去 vs 现在"的对比描述改成纯净的 "When X, do Y" 指令式
- 仅 `CHANGELOG.md` / `git log` / `git tag` / 本 README 末段保留版本叙事(per [`docs/agents-md-guide.md`](./docs/agents-md-guide.md) 第 86-95 行的四载规则)
- `validate-skills.sh`: 19 / 19 OK;`check-marketplace.sh`: OK 19 skills in sync;独立 Oracle 审查确认无叙事残留

### v0.5.1 — 中途需求变更路由

- 18 项审计问题闭合(`brainstorming` 吸收 `interview-me`;`spec-driven-development` 锁定 PRD 唯一落点;`incremental-implementation` 增加 Slice 依赖 / HITL-AFK 元数据;`verification-before-completion` 二段验证)

### v0.5.0 — Skill 系统重构 + OMO 桥接

- 文档漂移修复(`pwf-integration.md` 计数、已删除 skill 引用、构建闸门时序冲突全部对齐)
- 核心流程去重:`brainstorming` 吸收 `interview-me` 的一问一答规则;`spec-driven-development` 锁定 PRD 唯一落点;`incremental-implementation` 桥接 OMO `review-work` 新上下文审查;`verification-before-completion` 桥接 OMO `visual-qa`
- 选装瘦化:`interview-me` / `code-simplification` 改为 OMO 内置薄别名;`documentation-and-adrs` 聚焦重大架构 ADR;`build-gate-visual-review` 明确为设计对齐闸门;`security-and-hardening` 路由至 OMO `security-research`;`performance-optimization` 卸下前端 CWV
- `writing-skills` 迁出 `core/`(meta-only,按需装):core 9 → 8,extra 10 → 11

### v0.4.0 — Superpowers 集成 + AGENTS.md 增强

- vendor 3 个 superpowers skill 到 `.core/`: `brainstorming`、`verification-before-completion`、`writing-skills`
- `using-meisijiya-skills` 加 EXTREMELY-IMPORTANT 框架 + Skill Priority 链
- `AGENTS.md` Section A 加 Discipline layer + Skill chains 子段;Section C 加项目级 AGENTS.md skill 引用规范(含失败检测 grep)

详见 `CHANGELOG.md` 与 `git log --oneline`。