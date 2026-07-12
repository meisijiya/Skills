# meisijiya-skills

Personal fork of [addyosmani/agent-skills](https://github.com/addyosmani/agent-skills), adapted for the [oh-my-openagent](https://github.com/code-yeongyu/oh-my-openagent) (omo) + [planning-with-files](https://github.com/OthmanAdi/planning-with-files) (pwf) stack.

## 与上游的差异

- **omo 之上补足**:omo 已内置的(frontend-ui-ux, git-master, playwright, review-work, remove-ai-slops, init-deep …)不重复。
- **omo 深度集成**(v0.2.0+):fork 的每个 skill 显式利用 omo 的 MCPs( context7 / grep_app / websearch / lsp)、agents( sisyphus / prometheus / atlas / oracle / librarian / multimodal-looker )、built-in skills( git-master / frontend-ui-ux / review-work / init-deep )和 modes( hyperplan / security-research / ultrawork )。详见 `skills/.extra/omo-integration/SKILL.md`。
- **pwf 硬遵守加强**:用 omo hook 把 pwf 的软遵守流程硬约束化。
- **教学化门控**:build 之前用 [html-ppt-skill](https://github.com/lewislulu/html-ppt-skill) 把项目状态生成 HTML slide deck,让用户可视化审视。
- **designer 协作**:用 [ui-ux-pro-max-skill](https://github.com/nextlevelbuilder/ui-ux-pro-max-skill) 为 designer 类 agent 生成 UI/UX design spec。
- **双目录结构**:`.core/` 必装集 + `.extra/` 选装集,适配 `vercel-labs/skills` CLI。

## 仓库结构

```
meisijiya-skills/
├── README.md                  ← 本文件
├── skill-anatomy.md           ← SKILL.md 写作规范
├── pwf-integration.md         ← 跟 pwf 协作的约定
├── docs/
│   ├── omo-agent-skill-config.md   ← 各 omo agent 的 skill 列表配置指南
│   └── p0-outline.md              ← 归档(已 ship)
├── templates/
│   └── AGENTS-snippet.md          ← 注入到用户级 AGENTS.md 的内容
├── skills/
│   ├── .core/                 ← 必装集(6 个)
│   │   ├── using-meisijiya-skills/
│   │   ├── spec-driven-development/
│   │   ├── incremental-implementation/
│   │   ├── test-driven-development/
│   │   ├── debugging-and-error-recovery/
│   │   └── source-driven-development/
│   └── .extra/                ← 选装集(12 个,按需)
│       ├── pwf-enforcer/
│       ├── build-gate-visual-review/
│       ├── designer-handoff/
│       ├── agent-project-structure/
│       ├── interview-me/
│       ├── code-simplification/
│       ├── api-and-interface-design/
│       ├── security-and-hardening/
│       ├── performance-optimization/
│       ├── observability-and-instrumentation/
│       ├── documentation-and-adrs/
│       └── omo-integration/         ← v0.2.0 新增:omo 特性跨参考图
├── scripts/
│   ├── validate-skills.sh          ← YAML frontmatter + 结构检查
│   ├── install.sh                 ← 装到 .opencode/skills/(项目/global)
│   └── inject-agents-md.sh        ← v0.2.1 新增:把 skill meta-info 追加到 AGENTS.md(opt-in,幂等)
└── evals/
    └── cases/                 ← 每个 skill 的 eval case(18 个)
```

## 安装

### 快速安装(推荐:`vercel-labs/skills` CLI)

`npx skills add <repo>` 自动装到 `~/.agents/skills/`(canonical skills 路径,OpenCode 作为 universal agent 直接读)。与 pwf / html-ppt-skill / ui-ux-pro-max 等其他 skills CLI 装的 skill 在同一位置,便于统一管理。

```bash
# 装必装集(6 个 .core/)
npx skills add <this-repo> --from skills/.core

# 装某个选装
npx skills add <this-repo> --skill pwf-enforcer

# 装多个选装
npx skills add <this-repo> --skill interview-me --skill security-and-hardening

# 看仓库有哪些 skill 可装
npx skills add <this-repo> --list

# 装到项目级(cwd 下的 .agents/skills/)
npx skills add <this-repo> --from skills/.core

# 全局装(到 ~/.agents/skills/)
npx skills add <this-repo> -g
```

vercel-labs/skills CLI 自动处理 dedup / 多 agent harness 兼容 / 符号链接。

### 高级:`scripts/install.sh`(项目级 install / 自定义路径)

仅当你**不能或不想**用 skills CLI、或者需要非标准路径时,才用这个脚本:

```bash
# 项目级 install: 装到 cwd 的 .opencode/skills/(omo 原生路径)
scripts/install.sh

# 装到指定项目
scripts/install.sh --target /path/to/your-project

# 装 .core/ + 指定的几个 .extra/
scripts/install.sh --extra interview-me --extra security-and-hardening

# 装全部(必装 + 选装)
scripts/install.sh --all-extra

# 看可选的 .extra/
scripts/install.sh --list

# 全局装(到 ~/.config/opencode/skills/,omo 原生路径)
scripts/install.sh --global

# 预览但不复制
scripts/install.sh --dry-run
```

> 注意:`scripts/install.sh` 装到 omo 原生路径(`~/.config/opencode/skills/`),不是 skills CLI 的 canonical 路径(`~/.agents/skills/`)。两者都被 OpenCode 发现,但**混用会装两份副本**。如果你已经在用 skills CLI 装其它 skill,优先用 CLI。

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

## 当前状态(v0.1.0)

- 17 个 SKILL.md(6 个 `.core/` + 11 个 `.extra/`)
- 17 个 eval case(全部 skill 都有)
- `scripts/validate-skills.sh` 验证脚本(YAML frontmatter + 结构检查)
- `docs/p0-outline.md` 归档(已 ship)

详见 `git log --oneline`。