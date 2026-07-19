---
name: build-gate-visual-review
description: "Design-alignment gate: runs BEFORE any code is written. Compiles spec/plan/design/research into an HTML slide deck via html-ppt-skill for the user to visually approve. Use when the project has UI, when the user wants to verify understanding before implementation, or when teaching/learning mode is active."
allowed-tools: "Read Bash Glob Grep Write"
---

# build-gate-visual-review

## Overview

在 build 之前把项目的当前状态(spec / plan / design spec / research findings / progress)生成为**HTML slide deck**,让用户在浏览器里**可视化审视设计**。

目的:build 写代码之前,用户和 agent **对项目状态有共同的、可视化的理解**。Slide deck 比纯 markdown 更易 review(每页一个主题、视觉层次清晰)。

> **职责边界**:
> - 这是**设计对齐闸门**,只检查"还没写代码前的 spec/plan/design 是否一致"
> - **不是**人工 QA / 走查 / 视觉验收。代码写完后的 QA 走 [`incremental-implementation`](~/.agents/skills/incremental-implementation/SKILL.md) § 8:用户亲手运行关键路径 + OMO `visual-qa` 跑像素 diff
> - **不是**完成声明。完成声明走 [`verification-before-completion`](~/.agents/skills/verification-before-completion/SKILL.md)
> - 在 pwf 时序上属于**Phase 3.5**(spec/plan/design 完成、Phase 3 slice 之前)

[html-ppt-skill](https://github.com/lewislulu/html-ppt-skill) 提供 36 themes × 31 layouts × 47 animations,输出纯静态 HTML/CSS/JS,无需构建步骤。

## When to Use

**Use when:**
- 项目准备进入 build phase(spec/plan/design 都已写完)
- 用户说"我想先看看" / "show me what we're building"
- 教学 / 学习模式(用户在学习项目结构)
- 跨团队 review(把状态发给非技术人员)
- 复杂项目需要 sanity check

**NOT for:**
- 纯后端 / CLI / 无 UI 项目(无视觉内容,deck 没意义)
- Trivial 改动(< 1 个 slice)
- 紧急 hotfix
- **代码写完后的 QA** → 那是 [`incremental-implementation`](~/.agents/skills/incremental-implementation/SKILL.md) § 8(OMO `visual-qa` + 亲手运行)
- **完成声明** → 那是 [`verification-before-completion`](~/.agents/skills/verification-before-completion/SKILL.md)

## Process

### 1. Verify prerequisites

`html-ppt-skill` 必须装在全局 skills 目录(由用户预装):

```bash
test -d ~/.agents/skills/html-ppt-skill && echo "html-ppt-skill installed" || echo "install html-ppt-skill first"
```

If missing, prompt user with one of:

```bash
# Option A: via vercel-labs/skills CLI
npx skills add https://github.com/lewislulu/html-ppt-skill

# Option B: manual clone into global omo skills dir
git clone https://github.com/lewislulu/html-ppt-skill \
  ~/.agents/skills/html-ppt-skill
```

### 2. Gather project state — read from `task_plan.md`

Spec / design / research 都写在 `task_plan.md` 各类别里。**不要 cat 独立 `spec.md`**。

```bash
# Primary source — everything lives here
cat task_plan.md             # or .planning/<plan-id>/task_plan.md
cat findings.md              # Phase 2: Research
tail -50 progress.md         # recent activity

# Sub-phase artifacts (if produced)
cat .planning/<plan-id>/design-spec.md       # designer-handoff
cat .planning/<plan-id>/contract.{yaml,…}    # api-and-interface-design
cat .planning/<plan-id>/security-review.md   # security-and-hardening
cat .planning/<plan-id>/perf-baseline.md     # performance-optimization
```

Compile a single markdown: `.planning/<plan-id>/build-context.md`。

### 3. Activate html-ppt-skill

通过 Skill tool 加载 `html-ppt-skill`,让 agent 使用其 36 themes / 31 layouts / 47 animations 创建 deck。

### 4. Author the deck

让 html-ppt-skill 把 `build-context.md` 转换成 slide deck。建议结构:

- Slide 1: 项目名 + 目标(cover layout)
- Slide 2: 目录 / 路线图(toc / roadmap layout)
- Slide 3+: spec 关键决策(spec 摘要 / 验收标准 / 风险)
- Slide N-1: 设计 spec 摘要(if UI 项目,chart-grid / arch-diagram layout)
- Slide N: 当前 phase 状态 / 下一步(cta / thanks layout)

### 5. Output deck file

- 标准:`.planning/<plan-id>/build-gate-deck/index.html`(html-ppt-skill 多文件 deck 结构)
- 简单单文件:`.planning/<plan-id>/build-gate.html`

### 6. Present to user + record decision

告诉用户文件路径 + 打开方式,然后追加 `progress.md`:

```
[build-gate] review: <path-to-html> | user: <approve | modify | reject>
```

如果 reject → 回到 spec 阶段,把新 phase 加进 task_plan.md(例如 `Phase 3.6: Spec revision`),重新跑 build-gate。
如果 approve → 进入 Phase 3: Slice(走 [`incremental-implementation`](~/.agents/skills/incremental-implementation/SKILL.md))

## Common Rationalizations

| Excuse | Reality |
|---|---|
| "用户已经看了 spec,不需要再 review" | Spec 是文字,deck 是可视化。两种认知负担不同。 |
| "Deck 渲染浪费时间" | 5 分钟渲染 vs 50 分钟改错代码。前者更快。 |
| "build-gate 之后还要再 QA 一遍" | 这个 skill 是设计对齐闸门,**不是** QA。代码写完后的 QA 由 OMO `visual-qa` + 用户亲手运行负责,见 [`incremental-implementation`](~/.agents/skills/incremental-implementation/SKILL.md) § 8。 |
| "build-gate 通过 = 完成" | Build-gate 在 slice 之前。完成 = [`verification-before-completion`](~/.agents/skills/verification-before-completion/SKILL.md) + OMO `review-work` 5 子代理。 |
| "纯后端项目不需要这个" | 对,后端跳过 build-gate(写明 NOT for)。 |
| "用户太忙,跳过 review" | 忙 ≠ 不要 review。Build-gate 是异步的,用户有空再看。 |
| "直接动手,出问题再调" | 出问题再调 = 返工 = 更慢。 |
| "html-ppt-skill 装起来麻烦" | `npx skills add <url>` 一行命令。 |

## Red Flags

- html-ppt-skill 没装就用 skill
- 跳到 build 之前没等用户确认
- Build context 拼凑不全(漏 spec / 漏 design)
- cat 独立 `spec.md` / `docs/specs/*.md` — 已被 `task_plan.md` 替代,违反唯一落点
- Deck 内容跟 build-context.md 不一致(凭空捏造)
- 用户没看到 deck 就进入 build phase
- Deck 路径写错 / 权限不够
- 生成失败但不报告

## Verification

Before declaring build-gate ready, confirm:
- [ ] html-ppt-skill installed at `~/.agents/skills/html-ppt-skill/`
- [ ] build-context.md compiled entirely from `task_plan.md` + sub-phase artifacts(no独立 `spec.md`)
- [ ] html-ppt-skill loaded via Skill tool
- [ ] Deck generated successfully (non-empty file)
- [ ] User presented with file path + how to open
- [ ] User explicitly approved (verbal / progress.md entry)
- [ ] Any modifications from review applied
- [ ] Deck re-generated if spec changed

## pwf Integration

Maps to `task_plan.md` **Phase 3.5: Build Gate Visual Review** — runs **between Phase 1 (Spec) approval and Phase 3 (Slice) start**, NOT after slices.

The deck goes in `.planning/<plan-id>/build-gate-deck/` (artifact directory, not in task_plan.md).

The gate decision is recorded in `progress.md`:

```
[build-gate] review → user: approve | modify | reject
```

If reject, add a new phase to task_plan.md (e.g., Phase 3.6: Spec revision) and restart from there.

See [pwf-integration.md](../../pwf-integration.md).

## Related Skills

- Predecessor: [`brainstorming`](~/.agents/skills/brainstorming/SKILL.md) → [`spec-driven-development`](~/.agents/skills/spec-driven-development/SKILL.md)
- Successor (after deck approve): [`incremental-implementation`](~/.agents/skills/incremental-implementation/SKILL.md) → 包含 Phase 3 § 8 的 OMO `visual-qa` + 用户亲手运行
- Completion gate: [`verification-before-completion`](~/.agents/skills/verification-before-completion/SKILL.md)
