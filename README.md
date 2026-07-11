# meisijiya-skills

Personal fork of [addyosmani/agent-skills](https://github.com/addyosmani/agent-skills), adapted for the [oh-my-openagent](https://github.com/code-yeongyu/oh-my-openagent) (omo) + [planning-with-files](https://github.com/OthmanAdi/planning-with-files) (pwf) stack.

## 与上游的差异

- **omo 之上补足**:omo 已内置的(frontend-ui-ux, git-master, playwright, review-work, remove-ai-slops, init-deep …)不重复。
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
├── skills/
│   ├── .core/                 ← 必装集(6 个)
│   │   ├── using-meisijiya-skills/
│   │   ├── spec-driven-development/
│   │   ├── incremental-implementation/
│   │   ├── test-driven-development/
│   │   ├── debugging-and-error-recovery/
│   │   └── source-driven-development/
│   └── .extra/                ← 选装集(11 个,按需)
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
│       └── documentation-and-adrs/
└── evals/
    └── cases/                 ← 每个 skill 的 eval case(.core 必填)
```

## 安装

### 快速安装(推荐)

`scripts/install.sh` 处理全部安装逻辑 —— 必装 + 按需选装 + dry-run + 跳过已存在。

```bash
# 装 .core/ 6 个到当前目录的 .opencode/skills/
scripts/install.sh

# 装到指定项目
scripts/install.sh --target /path/to/your-project

# 装 .core/ + 指定的几个 .extra/
scripts/install.sh --extra interview-me --extra security-and-hardening

# 装所有
scripts/install.sh --all-extra

# 看可选的 .extra/
scripts/install.sh --list

# 全局安装(到 ~/.agents/skills/)
scripts/install.sh --global

# 预览但不复制
scripts/install.sh --dry-run
```

### 手动安装

如果不想用脚本,把 `skills/.core/` 复制到 omo 项目级发现路径即可:

```bash
cp -r skills/.core/* <your-project>/.opencode/skills/
```

### 通过 `vercel-labs/skills` CLI

```bash
npx skills add <this-repo> --from skills/.core    # 必装集
npx skills add <this-repo> --skill pwf-enforcer   # 单个选装
```

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