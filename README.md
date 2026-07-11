# meisijiya-skills

Personal fork of [addyosmani/agent-skills](https://github.com/addyosmani/agent-skills), adapted for the [oh-my-openagent](https://github.com/code-yeongyu/oh-my-openagent) (omo) + [planning-with-files](https://github.com/OthmanAdi/planning-with-files) (pwf) stack.

## 与上游的差异

- **omo 之上补足**:omo 已内置的(frontend-ui-ux, git-master, playwright, review-work, remove-ai-slops, init-deep …)不重复。
- **pwf 硬遵守加强**:用 omo hook 把 pwf 的软遵守流程硬约束化。
- **教学化门控**:build 之前用 [HTML Anything](https://github.com/nexu-io/html-anything) 把项目状态渲染成 HTML,让用户可视化审视。
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
│   └── .extra/                ← 选装集(10 个,按需)
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

### 必装集(`.core/`)

通过 `vercel-labs/skills` CLI:

```bash
npx skills add <this-repo> --from skills/.core
```

或手动复制到 omo 项目级发现路径:

```bash
cp -r skills/.core/* <your-project>/.opencode/skills/
```

### 选装集(`.extra/`)

按需挑:

```bash
npx skills add <this-repo> --skill pwf-enforcer
npx skills add <this-repo> --skill build-gate-visual-review
# ...
```

## 前置依赖

- **oh-my-openagent** 必须安装(`bunx oh-my-openagent install`)
- **planning-with-files** 必须安装(`/plugin marketplace add OthmanAdi/planning-with-files`)
- **可选**:`pnpm add -g ui-ux-pro-max-cli`(designer-handoff 需要)
- **可选**:`pnpm dev` 启动 HTML Anything(build-gate-visual-review 需要)

## 写作规范

参见 [skill-anatomy.md](./skill-anatomy.md)。

## 跟 pwf 的协作

参见 [pwf-integration.md](./pwf-integration.md)。

## License

MIT