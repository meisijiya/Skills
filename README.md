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
- **双目录 + 多 group**:`core/` 必装集 (9 个) + `extra/` 选装集 (35 个,按需装)。`.claude-plugin/marketplace.json` 把 `extra/` 拆为 6 个 plugin entry(`meisijiya-security` / `meisijiya-cicd` / `meisijiya-observability` / `meisijiya-meta` / `meisijiya-domain` / `meisijiya-frontend`)让 `npx skills add` picker 按 group 选。`core/` 保留单 entry(`meisijiya-core`)保留必装视觉信号。它是 skills CLI 的概念,**不是 OpenCode Plugin Marketplace** — OpenCode plugin 走 `~/.config/opencode/plugins/`,不经此文件。

## 仓库结构

```
meisijiya-skills/
├── README.md                  ← 本文件
├── AGENTS.md                  ← 仓库自描述 + skill 元信息 source(inject 脚本从这里读)
├── skill-anatomy.md           ← SKILL.md 写作规范
├── docs/
│   ├── omo-agent-skill-config.md   ← omo skill 配置参考(3 层加载机制 + 真实 schema;using-meisijiya-skills 的姊妹文档)
│   └── p0-outline.md              ← 归档(已 ship)
├── skills/
│   ├── core/                 ← 必装集(9 个)
│   │   ├── README.md          ← 9 个 skill 详情 + 必装理由
│   │   ├── using-meisijiya-skills/      ← **dispatcher**(Sisyphus 路由唯一决策点;含 Category × Skill Matrix + Dispatch Protocol)
│   │   ├── brainstorming/                  ← HARD-GATE pre-design exploration(adapted from superpowers)
│   │   ├── spec-driven-development/        ← spec-before-code,lock PRD
│   │   ├── incremental-implementation/    ← vertical slices with dep/HITL-AFK metadata,bridge to OMO review-work
│   │   ├── test-driven-development/
│   │   ├── verification-before-completion/  ← Iron Law;bridge to OMO review-work/visual-qa (adapted from superpowers)
│   │   ├── debugging-and-error-recovery/    ← 5-step triage protocol
│   │   ├── diagnosing-bugs/                  ← symptom-driven diagnosis loop (pairs with debugging-and-error-recovery)
│   │   └── source-driven-development/       ← verify API against docs (narrowed triggers)
│   └── extra/                ← 选装集(35 个,按 group 组织在 picker 中)
│       ├── README.md          ← 35 个 skill + group-aware "怎么选" 决策表
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
│       ├── build-gate-visual-review/        # domain group (13,含 teacher-skill)
│       ├── designer-handoff/
│       ├── api-and-interface-design/
│       ├── documentation-and-adrs/
│       ├── improve-codebase-architecture/
│       ├── verify-chain/
│       ├── loop-me/
│       ├── prototype/
│       ├── wayfinder/
│       └── research/
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
    └── cases/                 ← 每个 skill 的 eval case(44 个)
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

# 装 meisijiya-domain 新增的 3 个 skill (prototype / wayfinder / research)
npx skills add meisijiya/Skills \
  --skill prototype --skill wayfinder --skill research

# 装 meisijiya-frontend (反 AI 味 + 美学方向,3 个)
npx skills add meisijiya/Skills \
  --skill meisijiya-frontend-taste --skill meisijiya-redesign-ui --skill meisijiya-minimalist-ui

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

# 装 meisijiya-domain(13 个,teacher-skill 已合入 marketplace;因 `allowed-tools: Read` only 保持默认不装,若项目需要教学型 overlay 可显式追加 ,teacher-skill)
mkdir -p .opencode/skills
git clone --depth 1 https://github.com/meisijiya/Skills.git /tmp/meisijiya-domain
mv /tmp/meisijiya-domain/skills/extra/{build-gate-visual-review,designer-handoff,api-and-interface-design,documentation-and-adrs,improve-codebase-architecture,verify-chain,loop-me,prototype,wayfinder,research,meisijiya-handoff,meisijiya-phase-checkpoint} .opencode/skills/
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
- **选装集**(35 个,按项目需求挑):[`skills/extra/README.md`](./skills/extra/README.md) — 含 6-group "怎么选" 决策表(`security` / `cicd` / `observability` / `meta` / `domain` / `frontend`) + 依赖关系。`npx skills add` picker 按这 6 个 group 展示,可整组装或单选

> 不确定装哪个 → 先看 [`skills/extra/README.md`](./skills/extra/README.md) 的"怎么选"表 + group-aware 章节,按你项目特征对号入座。

### Lite CLI:`bin/meisijiya`(OpenCode plugin 管理)

skill 安装用 `npx skills add`(已存在),**plugin 管理没有现成 CLI**,所以做了个 65 行 lite 工具,只覆盖痛的两件事:

```bash
# 列出已装 plugin(在 ~/.config/opencode/plugins/,匹配 *.ts 和 *.js)
./bin/meisijiya plugin list

# 验证 plugin(.ts 走 bun check,.js 走 node --check;零额外依赖)
./bin/meisijiya plugin verify

# 装到 PATH(任意一处)
ln -s "$(pwd)/bin/meisijiya" ~/.local/bin/meisijiya
```

**只做 `plugin list` + `plugin verify`,不做 plugin add/remove/inject/status/update**(那些是 YAGNI,等真痛了再加)。`plugin verify` 走 `bun check` (.ts) + `node --check` (.js),两者缺一会报错提示安装。`plugin list` 会列出 `~/.config/opencode/plugins/` 下所有 `*.js` + `*.ts`(当前默认应有 4 个,见下)。**注意:**本 README 文档化的 4 个 hard-layer plugin 全部走 `plugin verify`(无类型门禁盲点)。

### OpenCode Plugins(硬层 · 4 个)

本仓库有 **4 个 OpenCode plugin**(全部 hard-layer, 注入到 LLM 调用层,不是 soft 挂载的 SKILL.md)。四者机制互补、不冲突,可独立装:

| Plugin | 触发层 | 安装命令 |
|---|---|---|
| `meisijiya-skills.js` | 每 session 首条 user message(bootstrap 注入) | `cp .opencode/plugins/meisijiya-skills.js ~/.config/opencode/plugins/` |
| `meisijiya-review-router.js` | Write/Edit/apply_patch(per-Edit reminder) | `cp .opencode/plugins/meisijiya-review-router.js ~/.config/opencode/plugins/` |
| `meisijiya-dispatch-gate.js` | `task()` 工具调用前(`load_skills` 完整性兜底) | `cp .opencode/plugins/meisijiya-dispatch-gate.js ~/.config/opencode/plugins/` |
| `omo-state-index.js` | 任意 `.omo/**` 写入(防抖 500ms 重建 `.omo/.index.json`)+ 每 session 首条 user message(3 行压缩态摘要) | `bash scripts/install.sh` |

> `cp` 实复制路径(经验证可工作);`ln -sf` 软链路径行为未做独立验证,若需使用请自行核对 plugin loader 当前实现。
>
> `omo-state-index.js` 推荐用 `scripts/install.sh`(原子复制 + SHA-256 校验 + 幂等)。手动 `cp` 等价但无 SHA 漂移保护。`install.sh` 仅复制**这一个文件**(不覆盖 `meisijiya-skills.js` / `meisijiya-review-router.js`),带 `--dry-run` 预览和 `--force` 强制覆盖。退出码:`0` 已装/未变,`1` SHA 漂移或源缺失,`2` 写盘失败。

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

#### `meisijiya-dispatch-gate.js` — `load_skills` 完整性兜底

兜底 Sisyphus 在 `task()` 派发时漏传/部分传 `load_skills=[...]` 的硬层 hard-layer fallback——和 SKILL.md §Hard Rule(soft 层 LLM 训练)形成双层保险。

**机制:**

- `tool.execute.before` hook — 拦截 `task()` 工具调用,检查 `args.load_skills`
- 漏传(空 / undefined)+ matrix-mapped category → 按 Category × Skill Matrix 主表注入(visual-engineering / deep MVP)
- 已传 list → **不动 args**(避免 LLM "我说 a 被塞 b" 困惑),仅 `console.warn` 显示 matrix 推荐
- `installed()` 过滤(防止 matrix 推荐但未装的 skill 进入 → omo `resolveSkillContent` notFound 硬失败)
- 永不 throw 出 hook(整体 try/catch)
- mutate 字段(`args.load_skills = recommended`),不复 reassign 整对象(OpenCode SDK issue #25754)

**SOT sync:** Plugin 头部注释声明 SOT → `~/.agents/skills/using-meisijiya-skills/SKILL.md` §Category × Skill Matrix;matrix 变更时同步更新 plugin `RECOMMENDED` 常量。

**MVP 范围:** 仅 `visual-engineering` / `deep`;扩到其他 category 需 (a) matrix 同步 (b) RECOMMENDED 加行 (c) 单测加正例 (d) eval case 评估是否加 behavioral。

详细行为表见 [`docs/omo-agent-skill-config.md`](./docs/omo-agent-skill-config.md) § L4 + spec [`docs/meisijiya-dispatch-gate-design-spec.md`](./docs/meisijiya-dispatch-gate-design-spec.md) § 4.3。

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

> **不是 meisijiya skill**:ui-ux-pro-max 不是本仓库 skill,不上 `npx skills add`,不计入 9 + 35 的 SKILL.md 总数;只通过 npm CLI 分发。

### Hallmark(营销 / 落地页 · 与 UI/UX Pro Max 并列)

[`hallmark`](https://github.com/Nutlope/hallmark)(Nutlope / Together AI, MIT, 17.4k★) 是反 AI 味落地的另一条路线 — **直接产出 self-contained HTML + CSS 落地页**(20 套 catalog 主题,4 套有 `references/themes/` 详解 + Custom 分支 + **58 个 slop-test 闸门** + 发射前自审)。**与 UI/UX Pro Max 不重叠、不替代**,按 brief 类型二选一:

| brief 类型 | 走哪个 |
|---|---|
| 营销页 / 落地页 / portfolio / 个人主页 | **hallmark**(输出即产物) |
| 产品 UI / dashboard / 设计系统 / 接口契约 | UI/UX Pro Max(`designer-handoff` 默认路由,产出 spec) |
| 现存 UI 改造 / 重做 | `meisijiya-redesign-ui`(9 层审计 + 优先级修复) |
| 任何"反 AI 味"输出 | 二者皆可;hallmark 闸门更密 |

**4 verbs**:`(default)` build new UI / `hallmark audit <target>` / `hallmark redesign <target>` / `hallmark study <url|screenshot>`(抽 design DNA 到 portable `design.md`,拒绝像素克隆)。

> ⚠️ **本仓库 `npx skills add meisijiya/Skills` 不会装 hallmark** — hallmark 不在 `.claude-plugin/marketplace.json` 7 个 plugin 块里,跑 `npx skills add` 选 7 group 都装不上;必须按下方 bash 块手动从上游 `nutlope/hallmark` 拉,且不进入项目 lockfile(全局 user-level,跨机器需各自执行)。

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

> **不是 meisijiya skill**:hallmark 不在 `9 + 35` 仓库总数里,上游独立维护。

> **安全审计**:Gen / Socket / Snyk 均评 Safe / 0 alerts / Low Risk,详见 [skills.sh/nutlope/hallmark](https://skills.sh/nutlope/hallmark)。输出纯 HTML+CSS,无运行时副作用。

### 可选

- **Python 3.x**(ui-ux-pro-max 内置 BM25 搜索脚本依赖;装 Node 22 + 上面的 npm CLI 时通常已自带,缺则单独装)
- **bun**(跑 `./bin/meisijiya plugin verify` 用;`.js` plugin 不在 verify 范围内)

## 写作规范

- **SKILL.md 写作规范** — 参见 [skill-anatomy.md](./skill-anatomy.md)(frontmatter / 6 段结构 / 行数限制 / 命名 / marketplace 同步 / 安全约束)
- **Sisyphus Dispatcher 协议** — 参见 [`using-meisijiya-skills`](./skills/core/using-meisijiya-skills/SKILL.md) § Sisyphus Dispatch Protocol + Category × Skill Matrix(Sisyphus 在 `task(category=..., load_skills=[...])` 时读此协议)
- **OMO 配置参考** — 参见 [`docs/omo-agent-skill-config.md`](./docs/omo-agent-skill-config.md)(3 层加载机制 + 真实 schema + 6 个新 skill 全局配置示例)

## License

MIT

---

## 当前状态

最近 tag: **v0.8.0** — meisijiya-frontend triad (Leonxlnx/taste-skill absorption)(详细见 [`CHANGELOG.md`](./CHANGELOG.md) 与 `git log`)

### Unreleased — dispatch-gate ship (R5, 2026-08-05)

- **双层保险架构**(软层训练 + 硬层兜底)落地,dispatcher SKILL.md 强化为协议级 SOT:
  - **软层**:`skills/core/using-meisijiya-skills/SKILL.md` 加 `§Hard Rule (mandatory)` 至 `§Sisyphus Dispatch Protocol` 段首;`§Category × Skill Matrix` 主表重构(`Main` / `+modifier` / `→substitute` 三记号 legend),visual-engineering + deep 2 行升级到 Main+Modifier 形式;`§Process step 8` 改写引用 Hard Rule;`§Common Dispatch Patterns` → `§Common Dispatch Scenarios`(过渡标记 + 6 cross-refs);Plugin layer 段首补注入机制说明;EXTREMELY_IMPORTANT 块加 1 行 dispatch 提示(双拷贝同步 `~/.agents/skills/`)
  - **硬层**:新增 `.opencode/plugins/meisijiya-dispatch-gate.js`(`tool.execute.before` hook,visual-engineering + deep MVP,`installed()` 过滤防 notFound,mutate 字段不 reassign,永不 throw,`console.warn` 注入/警告双模式)
- **bin CLI 升级**:`bin/meisijiya plugin verify` 扩 `.js` 通道(`node --check` 零依赖);require node (for .js) + bun (for .ts)
- **测试覆盖**:17 个 `node --test` 单测(`tests/plugins/meisijiya-dispatch-gate.test.js`)覆盖 4 类 + 引用恒等断言;`evals/cases/using-meisijiya-skills.json` +2 behavioral_evals(Hard Rule completeness + plugin regression)
- **跨文件同步**:README 插件表 3→4 + 新增 #### meisijiya-dispatch-gate.js 子段;`docs/omo-agent-skill-config.md` TL;DR + 标题 3→4 机制 + 新增 ### L4 段,`Common Dispatch Patterns` 全改 `Common Dispatch Scenarios`
- **设计 SOT 落库**:`docs/meisijiya-dispatch-gate-design-spec.md` 535 行 design spec(从 prior session handoff 转移,作为本 work 的 single source of truth)

**未做项 + 待解决问题**(per prior handoff §Open issues + 本 session 新发现):

- ⚠️ **E2E smoke 未做真实 OpenCode session 验证** — 17 单测覆盖 plugin hook 4 类行为,但 spec §6 要求 "真实 OpenCode session 跑 4 场景"。OpenCode 仅在 process start 扫描 plugins(`README.md` "Reload" 段),本 session 进程早于 commit `fc1ec66`,plugin hook 在本进程不触发。**next session 必做**:user 重启 OpenCode + 触发 `task(category='visual-engineering', load_skills=[])`,期望 console 输出 `[meisijiya-dispatch-gate] injected ["meisijiya-frontend-taste"]` + sub-agent 收到该 SKILL.md body
- ❌ **SKILL.md 双拷贝同步机制缺失** — 仓库无 sync script;R5 commit 仍手工 cp + diff(YAGNI per prior handoff D6,但已是 4th 复审共识阻断点)
- ❌ **MVP 扩张时机未定义** — `visual-engineering` + `deep` 仅覆盖 2/8 categories;何时扩到全表需 (a) matrix 同步 (b) RECOMMENDED 加行 (c) 单测加正例 (d) eval 评估。具体阈值未在本 spec 锁定
- ❌ **`ultrabrain` / `unspecified-high` 行的消歧策略** — "pick 1 of 3 by prompt keyword" 在 hook 不可靠;保留 LLM-only(不进 plugin)或未来消歧
- ⚠️ **Plugin 对 omo 内部派发的影响未实测** — gate 无 opt-out,omo 内部 `task()` 也会被注入;无明显问题但 E2E 应观察
- ⚠️ **Step 8 "above" vs 实际地理关系** — `§Process step 8` 写 "follow the Sisyphus Dispatch Protocol above",但 Protocol 在 step 8 之后(L50+)。Per spec §3.5 严格 verbatim 应用,可能是 spec typo;若 user 发现请告知
- ❌ **`bun 1.3.14` 移除 `bun check` 子命令** — pre-existing,`bin/meisijiya plugin verify` 跑 `rtk.ts` 失败("Script not found check")。非本 commit regressions,建议另开 issue
- ❌ **`scripts/sync-plugins.sh` 永久 fix 未做** — 当前 `cp` 手工操作,root-owned 老 plugin mtime 不可刷(见 sync 输出 Permission denied)。建议:加 chown + sync 一步脚本

**验证**(全部 PASS):
- `bash scripts/validate-skills.sh` → 44/44 OK,0 fail,0 warning
- `bash scripts/check-marketplace.sh` → OK 44 skills in sync
- `bash scripts/check-doc-drift.sh` → OK doc-vs-marketplace in sync
- `node --check .opencode/plugins/meisijiya-dispatch-gate.js` → OK
- `node --test tests/plugins/meisijiya-dispatch-gate.test.js` → 17/17 pass
- `./bin/meisijiya plugin verify` → 4 .js OK(rtk.ts pre-existing fail)

**总改动**:5 commits(本 R5 + 前 4 原子 `042f871` / `fc1ec66` / `28f431d` / `dc052df`)+ 7 文件 + 411 inserts / 23 deletes + 1 spec doc 入库 + .gitignore +1 行

**follow-up handoff**:`.omo/handoff/meisijiya-dispatch-gate-E2E-followup-2026-08-05.md`(下 session 接续)

### Unreleased — skill audit & dispatch protocol (R1-R4, 2026-07-30)

- **R1 9 项合规修复**: description 触发条件(`documentation-and-adrs`) / 6 段结构(`slice-review` 加 Overview + Rationalizations) / 我方文档一致性(`skill-anatomy.md` 描述规则 + 安全段) / 删 untracked 空目录(`git-worktree-isolation`) / 4 个 eval case 各 +1 negative / `validate-skills.sh` 加 §8 allowed-tools 一致性 + name 正则(WARN 级)
- **R2 清理 + 数字漂移**: `teacher-skill` frontmatter 清理(移除 Claude Code/Codex 扩展字段 `argument-hint` / `user-invocable` / `triggers` / 旧 `version`) / `skill-anatomy.md` 数字修复(domain 7→11 / 补 frontend group / 共 33 个 7 entry) / 3 个 frontend triad 加 `allowed-tools: "Read"` / 13 个 ≥250 行 skill 加 `version: 0.1.0`(Anthropic best-practices 推荐)
- **R3 文档同步**: README + `skills/extra/README.md` 删 "teacher-skill 不计入 26"过时注释 / `docs/omo-agent-skill-config.md` 数字 36→42 / §8 WARN 负面词表(50% false positive → 0%)
- **R4 Dispatch 协议**(核心架构变更): `using-meisijiya-skills` 加 4 个新段(Sisyphus Dispatch Protocol + Category × Skill Matrix 8 omo category × 推荐 `load_skills` + Common Dispatch Patterns 6 个新 skill 模板 + 扩展 Red Flags) / `docs/omo-agent-skill-config.md` 整段重写(基于 omo 真实 schema,删错误 `agents.<name>.skills` 假设)

**关键架构变化**: 所有 skill 路由收敛到 `using-meisijiya-skills` 一个 dispatcher skill(SOT);omo schema 不支持 per-agent skill 列表,实际靠 `<available_skills>` 全可见 + `task(load_skills=[...])` 显式加载 + `meisijiya-review-router.js` 文件路径触发 3 层机制

**Oracle 审核历程**: 4 次 Oracle 审核(1 次发现 P0 全部降级 + 1 次发现文档基于错误假设 + 1 次确认 R1-R4 修复 + 1 次 Oracle B5-2 事实错误核查);最终验证 validate-skills.sh 42/42 OK + check-marketplace.sh 42 skills in sync

**总改动**: 35 文件 + 5 commits(`chore(audit-core)` / `chore(skill-metadata)` / `docs(repo)` / `feat(dispatch)` / `docs(changelog)`)

### Unreleased — agent-driven loop capability (loop-omo-handoff, 2026-07-31)

- **`loop-me` 加 `runner: agent` + 5 spec runtime fields**: `runner` (`human` 默认 / `agent` 显式声明)、`max_rounds` (默认 100)、`consecutive_failures_max` (默认 5,独立安全阀)、`failure_policy` (`stop` / `continue` / `pause_ask`,默认 `pause_ask` 替换 `escalate`)、`completion_signal` (external-verifiable + cool-down 2 连续通过);Checkpoint 双语义 (Human-mode 签收 / Agent-mode exit condition);§ Red Flags 加 6 条 HITL rules + 4 行 adversarial prompt coverage
- **`closed-loop-delivery` Gate 4 in-loop variant**: 新增 per-round 监控变体(anomaly → log + brief + loop continues;hard failure → halt per `failure_policy: pause_ask`);明确"distinct from the post-deploy Gate 4 above" 与 "Do NOT conflate the two" 边界;原 post-deploy Gate 4 段(line 94-108)逐字保留
- **`verification-before-completion` loop-done ≠ task-done 边界**: 显式区分 loop 完成(state-machine event)与 task 完成(outcome claim,需 Gate 4-5 + 二段验证)
- **Dispatcher 路由**: `using-meisijiya-skills/references/priority-table.md` line 43 加 "Agent-driven loop (monitoring / CI-CD / audit)" row → `loop-me` → `/goal` → `verification-before-completion`
- **3 eval cases 扩展**: `loop-me.json` +1/+2/+3(HITL rule #2/#3/#4 behavioral); `using-meisijiya-skills.json` +1 positive; `closed-loop-delivery.json` +1/+1(Gate 4 in-loop variant 正/负)

**HITL L1 严格**: 用户必须显式 `/goal <workflow>` 才能启动 loop;agent 永不代发;spec 描述 how,invocation 是 when — 两件事不可混淆。Adversarial prompt 4 类全部封堵(隐式调用 / 社交压力 / 自陈述 completion_signal / 轮询伪装 Trigger)

**关键架构变化**: 完全 declarative handoff to OMO(0 新 SKILL.md / 0 新插件 / 0 marketplace 变更 / 0 新状态机 — ADR-0001 合规)。OMO `/goal` 提供 persistence + iteration cap + audit substrate;agent 在对话中执行每轮(re-read spec → execute → evaluate `completion_signal` → continue/break per `failure_policy`)

**软层上限**: doc-level 强措辞 + 4-row adversarial coverage + 6 红标条目 + 3 eval behavioral scenarios,~80-90% per project docs。**Full L1 enforcement 需要 OMO runtime `requireUserInvocation: true`**(Phase 1 ask #7 已 defer)

**OMO review-work 5-lane 全 PASS**: Goal+Constraint Oracle / QA Execution / Code Quality Oracle / Security Oracle / Context Mining,所有 lane HIGH confidence(除 Security LOW severity 仍 PASS);total ~10m 11s parallel;**0 BLOCKING issues**

**总改动**: 7 文件 + 135/-1(4 SKILL.md + 1 reference + 3 eval JSON,无 frontmatter / marketplace / plugin 变化)

**待解析(本次 deferred)**: `skills/extra/loop-me/SKILL.md ## Related Skills` 末行仍标 `verification-before-completion` 为 "不相关",与新 `## omo Integration` 引用轻微矛盾;plan 严格 preservation 规则要求保留 Related Skills 原文;resolution 推到后续独立 slice

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