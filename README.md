# meisijiya-skills

Personal fork of [addyosmani/agent-skills](https://github.com/addyosmani/agent-skills), adapted for the [oh-my-openagent](https://github.com/code-yeongyu/oh-my-openagent) (omo) + [planning-with-files](https://github.com/OthmanAdi/planning-with-files) (pwf) stack.

## 与上游的差异

- **omo 之上补足**:omo 已内置的(frontend-ui-ux, git-master, playwright, review-work, remove-ai-slops, init-deep …)不重复。
- **omo 深度集成**(v0.2.0+):fork 的每个 skill 显式利用 omo 的 MCPs( context7 / grep_app / websearch / lsp)、agents( sisyphus / prometheus / atlas / oracle / librarian / multimodal-looker )、built-in skills( git-master / frontend-ui-ux / review-work / init-deep )和 modes( hyperplan / security-research / ultrawork )。完整 omo ↔ skills 跨参考图见 `~/.config/opencode/AGENTS.md`(`meisijiya-extras` 段)。
- **pwf 硬遵守加强**:装 OpenCode 插件(`pwf-enforcer` 提供模板)把 pwf 的软遵守升级为硬触发 hook。
- **教学化门控**:build 之前用 [html-ppt-skill](https://github.com/lewislulu/html-ppt-skill) 把项目状态生成 HTML slide deck,让用户可视化审视。
- **designer 协作**:用 [ui-ux-pro-max-skill](https://github.com/nextlevelbuilder/ui-ux-pro-max-skill) 为 designer 类 agent 生成 UI/UX design spec。
- **双目录结构**:`core/` 必装集 + `extra/` 选装集,适配 `vercel-labs/skills` CLI。

## 仓库结构

```
meisijiya-skills/
├── README.md                  ← 本文件
├── AGENTS.md                  ← 仓库自描述 + skill 元信息 source(inject 脚本从这里读)
├── skill-anatomy.md           ← SKILL.md 写作规范
├── pwf-integration.md         ← 跟 pwf 协作的约定
├── docs/
│   ├── omo-agent-skill-config.md   ← 各 omo agent 的 skill 列表配置指南
│   └── p0-outline.md              ← 归档(已 ship)
├── skills/
│   ├── core/                 ← 必装集(9 个)
│   │   ├── README.md          ← 9 个 skill 详情 + 必装理由
│   │   ├── using-meisijiya-skills/
│   │   ├── brainstorming/                  ← v0.4.0(adapted from superpowers)
│   │   ├── spec-driven-development/
│   │   ├── incremental-implementation/
│   │   ├── test-driven-development/
│   │   ├── verification-before-completion/  ← v0.4.0(adapted from superpowers)
│   │   ├── debugging-and-error-recovery/
│   │   ├── source-driven-development/
│   │   └── writing-skills/                 ← v0.4.0(adapted from superpowers)
│   └── extra/                ← 选装集(10 个,按需)
│       ├── README.md          ← 10 个 skill + "怎么选" 决策表
│       ├── pwf-enforcer/
│       ├── build-gate-visual-review/
│       ├── designer-handoff/
│       ├── interview-me/
│       ├── code-simplification/
│       ├── api-and-interface-design/
│       ├── security-and-hardening/
│       ├── performance-optimization/
│       ├── observability-and-instrumentation/
│       └── documentation-and-adrs/
├── scripts/
│   ├── validate-skills.sh          ← YAML frontmatter + 结构检查
│   ├── install.sh                 ← 装到 .opencode/skills/(项目/global,高级)
│   └── inject-agents-md.sh        ← v0.2.1 新增:把 skill meta-info 追加到 AGENTS.md(opt-in,幂等)
├── bin/
│   └── meisijiya                  ← lite CLI:plugin list / plugin verify
└── evals/
    └── cases/                 ← 每个 skill 的 eval case(19 个)
```

## 安装

### 快速安装(推荐:`vercel-labs/skills` CLI)

`npx skills add <repo>` 自动装到 `~/.agents/skills/`(canonical skills 路径,OpenCode 作为 universal agent 直接读)。与 pwf / html-ppt-skill / ui-ux-pro-max 等其他 skills CLI 装的 skill 在同一位置,便于统一管理。

```bash
# 装必装集(6 个 core/)
npx skills add <this-repo> --from skills/core

# 装某个选装
npx skills add <this-repo> --skill pwf-enforcer

# 装多个选装
npx skills add <this-repo> --skill interview-me --skill security-and-hardening

# 看仓库有哪些 skill 可装
npx skills add <this-repo> --list

# 装到项目级(cwd 下的 .agents/skills/)
npx skills add <this-repo> --from skills/core

# 全局装(到 ~/.agents/skills/)
npx skills add <this-repo> -g
```

vercel-labs/skills CLI 自动处理 dedup / 多 agent harness 兼容 / 符号链接。

## Skills

按用途拆成两个子目录,每个有自己的 README 详细解释:

- **必装集**(9 个,所有项目都装):[`skills/core/README.md`](./skills/core/README.md) — 工作流骨架
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
scripts/install.sh --extra interview-me --extra security-and-hardening

# 装全部(必装 + 选装)
scripts/install.sh --all-extra

# 看可选的 extra/
scripts/install.sh --list

# 全局装(到 ~/.agents/skills/,跟 npx skills add 同位置 — 统一管理)
scripts/install.sh --global

# 预览但不复制
scripts/install.sh --dry-run
```

> 注意:`scripts/install.sh --global` 现在跟 `npx skills add` 装到**同一位置**(`~/.agents/skills/`)。OpenCode 从两个路径都发现 skill,所以即使你从不同来源装,也只会有同一份副本。**project-level 安装**仍走 `<project>/.opencode/skills/`(omo 原生,不被 skills CLI 影响)。

### Lite CLI:`bin/meisijiya`(OpenCode plugin 管理)

skill 安装用 `npx skills add`(已存在),**plugin 管理没有现成 CLI**,所以做了个 65 行 lite 工具,只覆盖痛的两件事:

```bash
# 列出已装 plugin(在 ~/.config/opencode/plugins/)
./bin/meisijiya plugin list

# 验证所有 plugin 的 TypeScript 语法(需要 bun)
./bin/meisijiya plugin verify

# 装到 PATH(任意一处)
ln -s "$(pwd)/bin/meisijiya" ~/.local/bin/meisijiya
```

**只做 `plugin list` + `plugin verify`,不做 plugin add/remove/inject/status/update**(那些是 YAGNI,等真痛了再加)。`plugin verify` 走 `bun check`,没有 bun 会报错提示安装。

### OpenCode Plugin(硬层 skill 注入)

`.opencode/plugins/meisijiya-skills.js` 是 hard-layer OpenCode 插件,跟 [`obra/superpowers` 的 `superpowers.js`](https://github.com/obra/superpowers/blob/main/.opencode/plugins/superpowers.js) 同款机制 — 在每个会话首条 user message 注入 `using-meisijiya-skills` 的 bootstrap,让 skill 真正高频触发(否则只在 `<available_skills>` 列表里软躺着,模型不会主动 invoke)。

**安装:**

```bash
mkdir -p ~/.config/opencode/plugins
cp .opencode/plugins/meisijiya-skills.js \
   ~/.config/opencode/plugins/meisijiya-skills.js
```

> 注:实测 `ln -sf` 软链接不被 OpenCode plugin loader 拾起,**用 `cp` 实复制**。

**禁用:** `rm ~/.config/opencode/plugins/meisijiya-skills.js`

**Reload:** OpenCode 不会自动重读 plugins 目录。改完插件或 bootstrap 内容后,点面板底部 **"重新加载 OpenCode"** 按钮,或在 settings 里触发 plugin rescan。

**诊断日志:** 插件内含 8 个 `log()` 调用,写到 `/tmp/meisijiya-skills.log`。可观察:
- `module loaded` — plugin 被 import
- `config hook fired` — `skills.paths` 注册成功
- `messages.transform fired` — bootstrap 注入 hook 触发
- `INJECTING bootstrap` — bootstrap 真的注入了首条 user message

不需要诊断时:`rm /tmp/meisijiya-skills.log` + 编辑插件去掉 `log()` 调用。

**Acceptance test:** 开新 session,发 `let's make X`(X 任意),期望模型先 announce `"Using brainstorming to ..."` 或其他 skill,再问需求。**不要直接 dive in 写代码**。

**已知限制**(per [superpowers issue #54](https://github.com/obra/superpowers/issues/54)):即使 hard-layer + superpowers-grade 强措辞,调用率仍 ~80-90%,不是 100%。模型有时仍能反 rationalization 绕过(尤其 Plan Mode — issue #1667)。需要 ~100% 时,加 `tool.execute.before` 拦截非 skill-issued 工具调用。

**SDK 验证**(2026-07):hook 名 + 签名匹配 OpenCode 官方 [`packages/plugin/src/index.ts`](https://raw.githubusercontent.com/anomalyco/opencode/dev/packages/plugin/src/index.ts)。用到的 hook:
- `config` — 注册 `~/.agents/skills` 到 OpenCode skill tool
- `experimental.chat.messages.transform` — 注入 bootstrap 到首条 user message

**关键设计:**
- 只注入首条,带 `EXTREMELY_IMPORTANT` guard 防重(session compaction 后仍幂等)
- 严格 in-place mutation([issue #25754](https://github.com/anomalyco/opencode/issues/25754):`output.messages = ...` 是静默 no-op)
- Bootstrap 来源:`~/.agents/skills/using-meisijiya-skills/SKILL.md`(strip frontmatter)
- 无外部依赖,纯 Node `fs/path`,Bun 跑原生 ESM

## 前置依赖

- **oh-my-openagent** 必须安装(`bunx oh-my-openagent install`)
- **planning-with-files** 必须安装(`/plugin marketplace add OthmanAdi/planning-with-files`)
- **可选**:`npm i -g ui-ux-pro-max-cli`(designer-handoff 需要)
- **可选**:`npx skills add https://github.com/lewislulu/html-ppt-skill`(build-gate-visual-review 需要,装到 `~/.agents/skills/`)

## 写作规范

参见 [skill-anatomy.md](./skill-anatomy.md)。

## 跟 pwf 的协作

参见 [pwf-integration.md](./pwf-integration.md)。

## License

MIT

---

## 当前状态

最近 tag: **v0.4.0**(19 个 SKILL.md / 19 个 eval case;9 `core/` + 10 `extra/`)

v0.4.0 内容:
- vendor 3 个 superpowers skill 到 `.core/`: `brainstorming`(HARD-GATE pre-design)、`verification-before-completion`(Iron Law)、`writing-skills`(TDD-for-docs + 提取重复工作流)
- `using-meisijiya-skills` 加 EXTREMELY-IMPORTANT 框架 + Skill Priority 链
- `AGENTS.md` Section A 加 Discipline layer + Skill chains 子段;Section C 加项目级 AGENTS.md skill 引用规范(含失败检测 grep)

详见 `CHANGELOG.md` 与 `git log --oneline`。