# meisijiya-skills

Personal fork of [addyosmani/agent-skills](https://github.com/addyosmani/agent-skills), adapted for the [oh-my-openagent](https://github.com/code-yeongyu/oh-my-openagent) (omo) stack.

## 30 秒上手

```bash
# 项目级装 6 个最常用 core + 1 个 extra
npx skills add meisijiya/Skills \
  --skill brainstorming --skill spec-driven-development \
  --skill test-driven-development --skill verification-before-completion \
  --skill incremental-implementation --skill debugging-and-error-recovery \
  --skill ai-code-blindspots
```

装好后开新 session,模型会从 `using-meisijiya-skills` dispatcher 自动加载 `brainstorming` 这种 `HARD-GATE` 的 skill;先 brainstorming → spec → 切 implementation,流程骨架才完整。完整列表走 [`skills/core/`](./skills/core/) + [`skills/extra/`](./skills/extra/) 各自的 README。

## 与上游的差异

- **omo 之上补足**:omo 已内置的(frontend-ui-ux, git-master, playwright, review-work, remove-ai-slops, init-deep …)不重复。
- **omo 深度集成**:fork 的每个 skill 显式利用 omo 的 MCPs( context7 / grep_app / websearch / lsp)、agents( sisyphus / prometheus / atlas / oracle / librarian / multimodal-looker )、built-in skills( git-master / frontend-ui-ux / review-work / init-deep )和 modes( hyperplan / security-research / ultrawork )。完整 omo ↔ skills 跨参考图见 `~/.config/opencode/AGENTS.md`(`meisijiya-extras` 段)。
- **意图门控的构建前对齐**:普通设计对齐只输出 Markdown / 文本；只有用户明确要求响应式 HTML 页面（项目可视化 / 自学习 / 教学型）时才通过 OMO 内置 `frontend` 渲染单文件 HTML；教学型内容额外叠加 `teacher-skill` pedagogy overlay。项目有 UI、即将 build、复杂都不会单独触发 HTML 生成。
- **designer 协作**:用 [ui-ux-pro-max-skill](https://github.com/nextlevelbuilder/ui-ux-pro-max-skill) 为 designer 类 agent 生成 UI/UX design spec。
- **双目录 + 多 group**:`core/` 必装集 (9 个) + `extra/` 选装集 (29 个,按需装)。`.claude-plugin/marketplace.json` 把 `extra/` 拆为 6 个 plugin entry(`meisijiya-security` / `meisijiya-cicd` / `meisijiya-observability` / `meisijiya-meta` / `meisijiya-domain` / `meisijiya-frontend`)让 `npx skills add` picker 按 group 选。`core/` 保留单 entry(`meisijiya-core`)保留必装视觉信号。它是 skills CLI 的概念,**不是 OpenCode Plugin Marketplace** — OpenCode plugin 走 `~/.config/opencode/plugins/`,不经此文件。

## 仓库结构

```
meisijiya-skills/
├── README.md                  ← 本文件
├── AGENTS.md                  ← 仓库自描述 + skill 元信息 source(inject 脚本从这里读)
├── skill-anatomy.md           ← SKILL.md 写作规范
├── docs/
│   ├── omo-agent-skill-config.md   ← 各 omo agent 的 skill 列表配置指南(20 SKILL.md 索引)
│   └── p0-outline.md              ← 归档(已 ship)
├── skills/
│   ├── core/                 ← 必装集(9 个)
│   │   ├── README.md          ← 9 个 skill 详情 + 必装理由
│   │   ├── using-meisijiya-skills/
│   │   ├── brainstorming/                  ← HARD-GATE pre-design exploration(adapted from superpowers)
│   │   ├── spec-driven-development/        ← spec-before-code,lock PRD
│   │   ├── incremental-implementation/    ← vertical slices with dep/HITL-AFK metadata,bridge to OMO review-work
│   │   ├── test-driven-development/
│   │   ├── verification-before-completion/  ← Iron Law;bridge to OMO review-work/visual-qa (adapted from superpowers)
│   │   ├── debugging-and-error-recovery/    ← 5-step triage protocol
│   │   ├── diagnosing-bugs/                  ← symptom-driven diagnosis loop (pairs with debugging-and-error-recovery)
│   │   └── source-driven-development/       ← verify API against docs (narrowed triggers)
│   └── extra/                ← 选装集(29 个,按 group 组织在 picker 中)
│       ├── README.md          ← 29 个 skill + group-aware "怎么选" 决策表
│       ├── security-and-hardening/          # security group (9)
│       ├── security-devsecops/
│       ├── security-incident-response/
│       ├── gha-security-review/
│       ├── security-threat-model/
│       ├── security-ownership-map/
│       ├── supply-chain-risk-auditor/
│       ├── stack-security-coder/
│       ├── ai-code-blindspots/
│       ├── pre-ship-gate/                   # cicd group (2)
│       ├── closed-loop-delivery/
│       ├── observability-and-instrumentation/ # observability group (4)
│       ├── performance-optimization/
│       ├── k6-load-testing/
│       ├── production-incident-playbook/
│       ├── writing-skills/                  # meta group (4)
│       ├── slice-review/
│       ├── contract-strengthening/
│       ├── test-guard/
│       ├── build-gate-visual-review/        # domain group (7)
│       ├── designer-handoff/
│       ├── api-and-interface-design/
│       ├── documentation-and-adrs/
│       ├── improve-codebase-architecture/
│       ├── verify-chain/
│       └── loop-me/
├── scripts/
│   ├── validate-skills.sh          ← YAML frontmatter + 结构检查(repo 本地工具,不随 skill 一起分发)
│   ├── check-marketplace.sh        ← marketplace.json ↔ skills/ 双射检查
│   └── inject-agents-md.sh        ← 把 skill meta-info 追加到 AGENTS.md(opt-in,幂等)
│   └── (per-skill `scripts/` 子目录跟随 skill 一起分发 — `npx skills add` 会复制整目录)
│       ├── skills/core/incremental-implementation/scripts/{task-brief.sh,slice-progress.sh}
│       └── skills/extra/slice-review/scripts/{review-package.sh}
├── bin/
│   └── meisijiya                  ← lite CLI:plugin list / plugin verify
└── evals/
    └── cases/                 ← 每个 skill 的 eval case(39 个)
```

## 安装

### 方式一:`vercel-labs/skills` CLI(推荐)

默认装到 `<cwd>/.agents/skills/`(项目级),加 `-g` 装到 `~/.agents/skills/`(用户级)。OpenCode 扫描 `.agents/skills/`,这是 skills CLI 的最终落点。

```bash
# 交互式(展示 7 个 group:meisijiya-core / -security / -cicd / -observability / -meta / -domain / -frontend,按需挑)
npx skills add meisijiya/Skills

# 装某个选装
npx skills add meisijiya/Skills --skill ai-code-blindspots

# 装多个选装
npx skills add meisijiya/Skills --skill security-and-hardening --skill ai-code-blindspots

# 看有哪些 skill 可装
npx skills add meisijiya/Skills --list

# 全局装(到 ~/.agents/skills/)
npx skills add meisijiya/Skills -g
```

### 方式二:`git clone`(纯 git,无 npm 依赖)

不想用 npm 工具时,直接 clone 仓库 + **平铺**到目标 skills 目录。本仓库是 monorepo,git clone 会带仓库根目录层(`<target>/<repo>/skills/<group>/<skill>/SKILL.md`),**OpenCode 不识别这种带父目录的形式** — 必须把 `<skill>` 目录直接移到 `<target>/` 下才是平铺结构。

> 下面所有命令的逻辑都一样:先 clone 到 `/tmp`,再 `mv` 出内部的 skill 目录,最后 `rm -rf /tmp/...` 清理。

#### 项目级(进项目根目录执行)

```bash
# 装 meisijiya-core(9 个,工作流骨架)
mkdir -p .opencode/skills
git clone --depth 1 https://github.com/meisijiya/Skills.git /tmp/meisijiya-core
mv /tmp/meisijiya-core/skills/core/* .opencode/skills/
rm -rf /tmp/meisijiya-core

# 装 meisijiya-security(9 个,审计 / 加固)
mkdir -p .opencode/skills
git clone --depth 1 https://github.com/meisijiya/Skills.git /tmp/meisijiya-security
mv /tmp/meisijiya-security/skills/extra/{security-and-hardening,security-devsecops,security-incident-response,ai-code-blindspots,gha-security-review,security-threat-model,security-ownership-map,supply-chain-risk-auditor,stack-security-coder} .opencode/skills/
rm -rf /tmp/meisijiya-security

# 装 meisijiya-cicd(2 个)
mkdir -p .opencode/skills
git clone --depth 1 https://github.com/meisijiya/Skills.git /tmp/meisijiya-cicd
mv /tmp/meisijiya-cicd/skills/extra/{pre-ship-gate,closed-loop-delivery} .opencode/skills/
rm -rf /tmp/meisijiya-cicd

# 装 meisijiya-observability(4 个)
mkdir -p .opencode/skills
git clone --depth 1 https://github.com/meisijiya/Skills.git /tmp/meisijiya-observability
mv /tmp/meisijiya-observability/skills/extra/{observability-and-instrumentation,performance-optimization,k6-load-testing,production-incident-playbook} .opencode/skills/
rm -rf /tmp/meisijiya-observability

# 装 meisijiya-meta(4 个)
mkdir -p .opencode/skills
git clone --depth 1 https://github.com/meisijiya/Skills.git /tmp/meisijiya-meta
mv /tmp/meisijiya-meta/skills/extra/{writing-skills,contract-strengthening,slice-review,test-guard} .opencode/skills/
rm -rf /tmp/meisijiya-meta

# 装 meisijiya-domain(7 个)
mkdir -p .opencode/skills
git clone --depth 1 https://github.com/meisijiya/Skills.git /tmp/meisijiya-domain
mv /tmp/meisijiya-domain/skills/extra/{build-gate-visual-review,designer-handoff,api-and-interface-design,documentation-and-adrs,improve-codebase-architecture,verify-chain,loop-me} .opencode/skills/
rm -rf /tmp/meisijiya-domain

# 装 meisijiya-frontend(3 个,反 AI 味 + 美学方向)
mkdir -p .opencode/skills
git clone --depth 1 https://github.com/meisijiya/Skills.git /tmp/meisijiya-frontend
mv /tmp/meisijiya-frontend/skills/extra/{meisijiya-frontend-taste,meisijiya-redesign-ui,meisijiya-minimalist-ui} .opencode/skills/
rm -rf /tmp/meisijiya-frontend
```

#### 用户级(全局,所有项目共享)

把上面的 `.opencode/skills` 都换成 `~/.config/opencode/skills`,`mkdir -p` 也对应换成用户目录即可。例如:

```bash
# 用户级 - 装 meisijiya-core
mkdir -p ~/.config/opencode/skills
git clone --depth 1 https://github.com/meisijiya/Skills.git /tmp/meisijiya-core
mv /tmp/meisijiya-core/skills/core/* ~/.config/opencode/skills/
rm -rf /tmp/meisijiya-core
```

> **一次装多组**:把 `mv` 改成 `cp -rn`(已存在的 skill 不覆盖),每个 group 用不同的 `/tmp` 目录名,就能在一次会话里装多组而不冲突。

## Skills

按用途拆成两个子目录,每个有自己的 README 详细解释:

- **必装集**(9 个,所有项目都装):[`skills/core/README.md`](./skills/core/README.md) — 工作流骨架。`diagnosing-bugs` 在 0.6.x 加入 core(协议 vs 学科二分:`debugging-and-error-recovery` 是 5 步协议,`diagnosing-bugs` 是 symptom-driven 学科)
- **选装集**(29 个,按项目需求挑):[`skills/extra/README.md`](./skills/extra/README.md) — 含 6-group "怎么选" 决策表(`security` / `cicd` / `observability` / `meta` / `domain` / `frontend`) + 依赖关系。`npx skills add` picker 按这 6 个 group 展示,可整组装或单选

> 不确定装哪个 → 先看 [`skills/extra/README.md`](./skills/extra/README.md) 的"怎么选"表 + group-aware 章节,按你项目特征对号入座。

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

### OpenCode Plugins(硬层 · 3 个)

本仓库有 **2 个 OpenCode plugin**(全部 hard-layer, 注入到 LLM 调用层,不是 soft 挂载的 SKILL.md)。二者机制互补、不冲突,可独立装:

| Plugin | 触发层 | 安装命令 |
|---|---|---|
| `meisijiya-skills.js` | 每 session 首条 user message(bootstrap 注入) | `cp .opencode/plugins/meisijiya-skills.js ~/.config/opencode/plugins/` |
| `meisijiya-review-router.js` | Write/Edit/apply_patch(per-Edit reminder) | `cp .opencode/plugins/meisijiya-review-router.js ~/.config/opencode/plugins/` |

> `cp` 实复制路径(经验证可工作);`ln -sf` 软链路径行为未做独立验证,若需使用请自行核对 plugin loader 当前实现。

**Reload:** OpenCode 不会自动重读 plugins 目录。改完 plugin 或 bootstrap 后,**退出 / 重启 OpenCode 后重开 session**。

**禁用:** `rm ~/.config/opencode/plugins/<plugin-name>`

**SDK 验证**(2026-07):所有 plugin 的 hook 名 + 签名匹配 OpenCode 官方 [`packages/plugin/src/index.ts`](https://raw.githubusercontent.com/anomalyco/opencode/dev/packages/plugin/src/index.ts)。

#### `meisijiya-skills.js` — skill bootstrap 注入

跟 [`obra/superpowers` 的 `superpowers.js`](https://github.com/obra/superpowers/blob/main/.opencode/plugins/superpowers.js) 同款机制 — 让 `using-meisijiya-skills` 在 LLM 每个调用前都出现在 firstUser.parts 里,触发模型真正高频 invoke skills(否则只在 `<available_skills>` 列表里软躺着,模型不会主动 invoke)。

**机制:**

- `config` hook — 重新声明 `~/.agents/skills` 到 OpenCode skill tool(OpenCode 已原生扫描该路径,此 re-registration 属 defensive / redundant,不是发现 skill 的前提)
- `experimental.chat.messages.transform` hook — 每 step 把 bootstrap 内容 unshift 到 `firstUser.parts`
- **In-memory only,不持久化 DB**:OpenCode 每 step 从 DB 重载 messages,bootstrap 每次重新注入(不是 bug,是 superpowers 同款设计)
- **bootstrap 锚定在 firstUser**:只第一条 user message 含 bootstrap,后续 user message 不污染;LLM 通过 conversation history 每步都看到
- 严格 in-place mutation([issue #25754](https://github.com/anomalyco/opencode/issues/25754):`output.messages = ...` 是静默 no-op)

**Acceptance test:** 开新 session,发 `let's make X`(X 任意),期望模型先 announce `"Using brainstorming to ..."` 或其他 skill,再问需求。**不要直接 dive in 写代码**。

**已知限制**(per [superpowers issue #54](https://github.com/obra/superpowers/issues/54)):即使 hard-layer + superpowers-grade 强措辞,调用率仍 ~80-90%,不是 100%。模型有时仍能反 rationalization 绕过。

#### `meisijiya-review-router.js` — per-Edit reminder 注入

Write/Edit/apply_patch 工具调用完成后,在 tool result 末尾追加 reminder 引导 invoke `ai-code-blindspots` + `security-and-hardening`(REMINDERS 数组可扩展)。

- **per-turn dedup**:同 turn 多次 edit 只一次提醒(`Map<sessionID, Set>` + `chat.message` hook 重置 state)
- **per-result marker check**:同一次 tool result 已有 marker 跳过
- 单 reminder ~21-23 tokens,2 skill = ~50 tokens/turn max

## 前置依赖

### 必装

- **oh-my-openagent** 必须安装(`bunx oh-my-openagent install`,本 fork 围绕 omo 设计)
- **Node.js 18+**(`ui-ux-pro-max-cli` 需要 npm 全局安装能力)

### UI/UX Pro Max(`designer-handoff` 的硬依赖)

[`designer-handoff`](./skills/extra/designer-handoff/) skill 通过 [ui-ux-pro-max-skill](https://github.com/nextlevelbuilder/ui-ux-pro-max-skill) 的 reasoning engine(161 行业规则 / 84 样式 / 192 调色板 / 74 字体配对 / 22 框架)生成 design spec。**项目有 UI 且要走 build 流程就必须装**;不装则 `designer-handoff` 跑不动,只能 fallback 到 `meisijiya-frontend-taste` 单 layer。

```bash
# 1. 装 CLI(全局,~30MB,纯 Python 标准库,无网络调用以外的副作用)
npm install -g ui-ux-pro-max-cli

# 2. 初始化到 OpenCode(skill 文件落到 ~/.opencode/skills/ui-ux-pro-max/)
uipro init --ai opencode --global

# 3. 验证:SKILL.md 落到 ~/.opencode/skills/ui-ux-pro-max/SKILL.md
test -f ~/.opencode/skills/ui-ux-pro-max/SKILL.md && echo "✓ ui-ux-pro-max ready"

# 4. 装好后**重启 OpenCode** 开新 session,模型会发现并自动加载
```

**调用入口**:`designer-handoff` 内部用 `uipro generate --product-type ... --stack ... --mood ... --output ...` 生成 spec。CLI 自带 BM25 search,不需要任何外部网络/数据库。

**卸载**:
```bash
uipro uninstall --ai opencode --global
# 或只删本 skill,保留其他(见下):
rm -rf ~/.opencode/skills/ui-ux-pro-max/
```

> **同伴 skill**:`uipro init --ai opencode --global` 会同步装 6 个同伴 skill 到 `~/.opencode/skills/`:`banner-design` / `brand` / `design` / `design-system` / `slides` / `ui-styling`。与本 fork 体系不重叠、由上游独立维护,按需保留或单独 `rm -rf ~/.opencode/skills/<name>/` 删除。

> **不是 meisijiya skill**:ui-ux-pro-max 不是本仓库 skill,不上 `npx skills add`,不计入 9 + 29 的 SKILL.md 总数;只通过 npm CLI 分发。

### Hallmark(营销 / 落地页 · 与 UI/UX Pro Max 并列)

[`hallmark`](https://github.com/Nutlope/hallmark)(Nutlope / Together AI, MIT, 17.4k★) 是反 AI 味落地的另一条路线 — **直接产出 self-contained HTML + CSS 落地页**(20 套 catalog 主题,4 套有 `references/themes/` 详解 + Custom 分支 + **58 个 slop-test 闸门** + 发射前自审)。**与 UI/UX Pro Max 不重叠、不替代**,按 brief 类型二选一:

| brief 类型 | 走哪个 |
|---|---|
| 营销页 / 落地页 / portfolio / 个人主页 | **hallmark**(输出即产物) |
| 产品 UI / dashboard / 设计系统 / 接口契约 | UI/UX Pro Max(`designer-handoff` 默认路由,产出 spec) |
| 现存 UI 改造 / 重做 | `meisijiya-redesign-ui`(9 层审计 + 优先级修复) |
| 任何"反 AI 味"输出 | 二者皆可;hallmark 闸门更密 |

**4 verbs**:`(default)` build new UI / `hallmark audit <target>` / `hallmark redesign <target>` / `hallmark study <url|screenshot>`(抽 design DNA 到 portable `design.md`,拒绝像素克隆)。

```bash
# 装(vercel-labs/skills CLI 全局模式,落到 ~/.agents/skills/,与本仓库 meisijiya 系同路径)
npx skills add -g -y nutlope/hallmark

# 验证:SKILL.md 落到 ~/.agents/skills/hallmark/SKILL.md(67KB / 558 行 + references/ 5 子目录 + 24 .md 文件)
test -f ~/.agents/skills/hallmark/SKILL.md && echo "✓ hallmark ready"

# 卸载(只卸 hallmark,不影响其他 npx skills add 装的 skill)
npx skills remove -g hallmark
# 或
rm -rf ~/.agents/skills/hallmark/
```

> **Skills CLI 落点 = `~/.agents/skills/`**:`npx skills add -g` 是 vercel-labs/skills CLI 的全局模式,落 `~/.agents/skills/<skill>/`,与本仓库 meisijiya 系同路径;**不要**用 `uipro init`(那是 UI/UX Pro Max 的专属 CLI,落到 `~/.opencode/skills/`,无 `--skills-dir` 选项)。

> **不是 meisijiya skill**:hallmark 不在 `9 + 29` 仓库总数里,上游独立维护。

> **安全审计**:Gen / Socket / Snyk 均评 Safe / 0 alerts / Low Risk,详见 [skills.sh/nutlope/hallmark](https://skills.sh/nutlope/hallmark)。输出纯 HTML+CSS,无运行时副作用。

### 可选

- **Python 3.x**(ui-ux-pro-max 内置 BM25 搜索脚本依赖;装 Node 22 + 上面的 npm CLI 时通常已自带,缺则单独装)
- **bun**(跑 `./bin/meisijiya plugin verify` 用;`.js` plugin 不在 verify 范围内)

## 写作规范

参见 [skill-anatomy.md](./skill-anatomy.md)。

## License

MIT

---

## 当前状态

最近 tag: **v0.8.0** — meisijiya-frontend triad (Leonxlnx/taste-skill absorption)(详细见 [`CHANGELOG.md`](./CHANGELOG.md) 与 `git log`)

### v0.6.0 — 11-skill roadmap + marketplace 6-group refactor (2026-07-24)

- **36 个 SKILL.md / 36 个 eval case** — `core/` 9 + `extra/` 27(9 security + 2 cicd + 4 observability + 4 meta + 8 domain)
- **11 个新 skill**(源已 cite;description ≤500 chars;6 段式 + `## omo Integration` 段;2 个 eval 升至 verified-level):
  - `gha-security-review` (security) — GHA workflow 文件审计;每条 finding 必带 exploit scenario
  - `pre-ship-gate` (cicd) — 部署前只读审计 + 部署后 smoke 验证,捕"deploy exit 0 ≠ 真在跑"
  - `security-threat-model` (security) — AppSec 威胁建模(trust boundaries / STRIDE / file:line)
  - `k6-load-testing` (observability) — 部署前性能准入门(smoke / load / stress / spike / soak)
  - `security-ownership-map` (security) — git 历史人员↔文件拓扑(bus-factor / orphans)
  - `closed-loop-delivery` (cicd) — 5-gate 证据链(run → runtime → reachable),把"完成"扩展到 prod 安全运行
  - `supply-chain-risk-auditor` (security) — 依赖维护者信号审计(不是 CVE 扫描)
  - `stack-security-coder` (security) — 前/后/移动三栈 coding checklist
  - `test-guard` (meta) — 7-check AI 测试质量审计
  - `production-incident-playbook` (observability) — in-flight runbook + blameless postmortem
  - `diagnosing-bugs` (joins core) — symptom-driven diagnosis loop(协议 vs 学科二分,配 `debugging-and-error-recovery`)
- **Marketplace 拆为 6 group**:`.claude-plugin/marketplace.json` 现在 6 个 plugin entry(`meisijiya-core` + `meisijiya-security` / `-cicd` / `-observability` / `-meta` / `-domain`),`npx skills add` picker 按 group 展示,可选整组团或单 skill。`scripts/inject-agents-md.sh` 自动从 manifest 派生每组 `(N)` 计数
- **Plugin P0 fix**(`a8d9fae`):`meisijiya-review-router.js` 从全局 `SKIP_PATH_RE` 改成 per-reminder `matchPath` / `skipPath`;原 `.yml` 路径会让 `gha-security-review` reminder 0% 触发,现在改 `.github/workflows/ci.yml` 会同时 fire 4 个 reminder
- **Plugin reminders 扩到 6**:在初版 `ai-code-blindspots` + `security-and-hardening` 基础上加 `verification-before-completion`(per Edit 触发)+ `gha-security-review`(`.github/workflows/`)+ `test-guard`(test files)+ `stack-security-coder`(`.tsx/.jsx/.vue/.svelte/.swift/.dart`)
- **Plugin reminders 扩到 8 (v0.8.0)**:加 `meisijiya-frontend-taste`(`.tsx/.jsx/.vue/.svelte`)+ `meisijiya-redesign-ui`(`.tsx/.jsx/.vue/.svelte/.css/.scss/.less`);与 `stack-security-coder` 共存于同 path 上,模型一次收到多个 reminder 按顺序读
- **CI 改进**:verified eval 的 `positive_keywords` 关键字覆盖率检查(任何 `verified: true` eval 缺关键词即 `::error` 阻断 merge)
- **Oracle audit**:release 前跑全面审查,patch 了 2 个 BLOCKER(`gha-security-review` + `diagnosing-bugs` description 关键词缺失导致 CI 红)+ 1 个 GROUP_SUFFIXES 不匹配(`ci-cd` → `cicd`)+ 2 个 MAJOR stale count + 3 个 MINOR;全 9 项 finding 在 commit `baf5529` + `51d1c81` 闭合

### v0.8.0 — meisijiya-frontend triad (Leonxlnx/taste-skill absorption) (2026-07-25)

- **3 个新 skill** 入新 group `meisijiya-frontend`(共 7 个 plugin entry:`core` + 6 extra,SKILL.md 总数 36 → 39),针对 LLM 前端写作的同质化 / AI 味 / 审美塌化三个缺口:
  - `meisijiya-frontend-taste` — 反 slop 输入侧规则合集;Brief 推断 + 三拨盘(variance / motion / density) + 硬规则(禁 lila 渐变 / 禁 premium-beige 默认 / 禁 eyebrow 每段 / 禁 zigzag 超过 2 段 / 禁 Fraunces / Instrument_Serif 默认 / 禁半角破折号 / 禁 Inter 默认 / 禁 Lucide 默认 / 禁 pure-black 背景 / 禁 `h-screen` 等);与 `designer-handoff` 叠加为项目规范上的"反 slop 第二合同"
  - `meisijiya-redesign-ui` — 现存 UI 的 audit-then-fix 工作流;9 层审计清单(typography / color / layout / interactivity / content / components / icons / code / strategic-omissions)+ 修复优先级阶梯;不迁移框架 / 不破坏功能
  - `meisijiya-minimalist-ui` — Linear/Notion 风格的具体美学方向;warm monochrome + spot pastels + 三段字体(sans body + serif display + mono)+ 不对称 bento + 8–12px 边框 + 静默 spring 动作
- **Marketplace 第 7 个 plugin entry**:`.claude-plugin/marketplace.json` 加 `meisijiya-frontend` plugin,`scripts/inject-agents-md.sh` `GROUP_SUFFIXES` 加 `frontend` 后缀,自动派生 `(3)` 计数;`scripts/check-marketplace.sh` 现在管 39 个 skill 双向同步
- **归 属**:3 个 skill 全部基于 [Leonxlnx/taste-skill](https://github.com/Leonxlnx/taste-skill) (MIT, Leon Linnx / Leonxlnx);每篇 SKILL.md 顶部加完整归属段 + 来源链接,README + CHANGELOG 加致谢。原 taste-skill 仓库 11 个子 skill,我们**只吸收 3 个核心**(补 3 个缺口),其他 `soft-skill` / `brutalist-skill` / `image-to-code-skill` / `gpt-taste` / `output-skill` / `stitch-skill` / `imagegen-*` / `taste-skill-v1` 暂不吸收(单选性美学 / 与 main 重叠 / 依赖外部工具 / 与体系无关)
- **新装命令**:README 加 `meisijiya-frontend` 组的 git clone / mv 流程;`npx skills add meisijiya/Skills` picker 现在展示 7 个 group

### v0.5.3 — Plugin runtime sync

- `meisijiya-review-router.js` 同步到 omo 运行时:`tool.execute.after` hook 返回的 part 不再 spread 原始 part(避免泄漏 `toolCall` / `toolResult` 字段)+ 移除诊断日志(`f2ddcb8` + `6caa7f7`)

### v0.5.2 — 全量 narrative hygiene

- 19 个 `SKILL.md` 全部清空历史叙事(原本 / 以前 / previously / v0.X 之类的标记等)
- 详细语义保留,但所有"过去 vs 现在"的对比描述改成纯净的 "When X, do Y" 指令式
- 仅 `CHANGELOG.md` / `git log` / `git tag` / 本 README 末段保留版本叙事(per [`docs/agents-md-guide.md`](./docs/agents-md-guide.md) 第 86-95 行的四载规则)
- `validate-skills.sh`: 19 / 19 OK;`check-marketplace.sh`: OK 19 skills in sync;独立 Oracle 审查确认无叙事残留

### v0.5.1 — 中途需求变更路由

- 18 项审计问题闭合(`brainstorming` 吸收 `interview-me`;`spec-driven-development` 锁定 PRD 唯一落点;`incremental-implementation` 增加 Slice 依赖 / HITL-AFK 元数据;`verification-before-completion` 二段验证)

### v0.5.0 — Skill 系统重构 + OMO 桥接

- 文档漂移修复(已删 skill 引用、构建闸门时序冲突全部对齐)
- 核心流程去重:`brainstorming` 吸收 `interview-me` 的一问一答规则;`spec-driven-development` 锁定 PRD 唯一落点;`incremental-implementation` 桥接 OMO `review-work` 新上下文审查;`verification-before-completion` 桥接 OMO `visual-qa`
- 选装瘦化:`interview-me` / `code-simplification` 改为 OMO 内置薄别名;`documentation-and-adrs` 聚焦重大架构 ADR;`build-gate-visual-review` 明确为设计对齐闸门;`security-and-hardening` 路由至 OMO `security-research`;`performance-optimization` 卸下前端 CWV
- `writing-skills` 迁出 `core/`(meta-only,按需装):core 9 → 8,extra 10 → 11

### v0.4.0 — Superpowers 集成 + AGENTS.md 增强

- vendor 3 个 superpowers skill 到 `.core/`: `brainstorming`、`verification-before-completion`、`writing-skills`
- `using-meisijiya-skills` 加 EXTREMELY-IMPORTANT 框架 + Skill Priority 链
- `AGENTS.md` Section A 加 Discipline layer + Skill chains 子段;Section C 加项目级 AGENTS.md skill 引用规范(含失败检测 grep)

详见 `CHANGELOG.md` 与 `git log --oneline`。