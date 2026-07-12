---
name: build-gate-visual-review
description: "Before build phase, generates an HTML slide deck via html-ppt-skill from current project state (spec / plan / design spec / progress), so the user can visually review and approve before any code is written. Use when the project has UI, when the user wants to verify understanding before implementation, or when teaching/learning mode is active."
allowed-tools: "Read Bash Glob Grep Write"
---

# build-gate-visual-review

## Overview

在 build 之前,把项目的当前状态(spec / plan / design spec / research findings / progress)生成为**HTML slide deck**,让用户在浏览器里可视化审视。

目的:build 阶段写代码之前,用户和 agent **对项目状态有共同的、可视化的理解**。Slide deck 比纯 markdown 更易 review(每页一个主题、视觉层次清晰)。

[html-ppt-skill](https://github.com/lewislulu/html-ppt-skill) 提供 36 themes × 31 layouts × 47 animations,输出纯静态 HTML/CSS/JS,无需构建步骤。

## When to Use

**Use when:**
- 项目准备进入 build phase
- 用户说"我想先看看" / "show me what we're building"
- 教学 / 学习模式(用户在学习项目结构)
- 跨团队 review(把状态发给非技术人员)
- 复杂项目需要 sanity check

**NOT for:**
- 纯后端 / CLI / 无 UI 项目
- Trivial 改动(< 1 个 slice)
- 紧急 hotfix
- 用户已经明确知道要建什么、不需要 review

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

### 2. Gather project state

Read all relevant pwf + project files:

```bash
# pwf files
cat task_plan.md          # or .planning/*/task_plan.md
cat findings.md           # research
tail -50 progress.md      # recent activity

# Design spec if UI project
cat .planning/*/design-spec.md   # from designer-handoff

# Spec
cat spec.md               # from spec-driven-development

# Contract if API project
cat contract.{yaml,json,graphql,proto}  # from api-and-interface-design
```

Compile a single markdown document: `build-context.md` at `.planning/<plan-id>/build-context.md`.

### 3. Activate html-ppt-skill

通过 Skill tool 加载 `html-ppt-skill`,让 agent 使用其 36 themes / 31 layouts / 47 animations 创建 deck。

### 4. Author the deck

让 html-ppt-skill 把 `build-context.md` 转换成 slide deck。建议的 slide 结构:

- Slide 1: 项目名 + 目标(cover layout)
- Slide 2: 目录 / 路线图(toc / roadmap layout)
- Slide 3+: spec 关键决策(spec 摘要 / 验收标准)
- Slide N-1: 设计 spec 摘要(if UI 项目,chart-grid / arch-diagram layout)
- Slide N: 当前 phase 状态 / 下一步(cta / thanks layout)

Theme 选择:可让用户从 html-ppt-skill 的 36 themes 中选(`minimal-white` / `editorial-serif` / `cyberpunk-neon` / `xiaohongshu-white` 等),或 agent 根据项目类型自动选。

### 5. Output deck file

Output 位置:`.planning/<plan-id>/build-gate-deck/index.html`(html-ppt-skill 标准的多文件 deck 结构)

或简单的单文件:`.planning/<plan-id>/build-gate.html`

### 6. Present to user

告诉用户文件路径 + 打开方式:

```
Build-gate review ready:
  File: /abs/path/to/build-gate.html (or build-gate-deck/index.html)
  Open: file:// URL in browser

Content includes:
  - Project goal & scope
  - Phases & current status
  - Design spec (if UI project)
  - Open questions / risks

Please review and confirm or request changes before build begins.
```

### 7. Record gate decision

Wait for user confirmation. Append to `progress.md`:

```
[build-gate] review: <path-to-html> | user: <approve | modify | reject>
```

If approve → proceed to build phase
If modify → update spec / plan, regenerate deck
If reject → go back to spec phase

## Common Rationalizations

| Excuse | Reality |
|---|---|
| "用户已经看了 spec,不需要再 review" | Spec 是文字,deck 是可视化。两种认知负担不同。 |
| "Deck 渲染浪费时间" | 5 分钟渲染 vs 50 分钟改错代码。前者更快。 |
| "纯后端项目不需要这个" | 对,后端跳过 build-gate(写明 NOT for)。 |
| "用户太忙,跳过 review" | 忙 ≠ 不要 review。Build-gate 是异步的,用户有空再看。 |
| "直接动手,出问题再调" | 出问题再调 = 返工 = 更慢。 |
| "html-ppt-skill 装起来麻烦" | `npx skills add <url>` 一行命令。 |

## Red Flags

- html-ppt-skill 没装就用 skill(agent 不会自动安装)
- 跳到 build 之前没等用户确认
- Build context 拼凑不全(漏 spec / 漏 design)
- Deck 内容跟 build-context.md 不一致(凭空捏造)
- 用户没看到 deck 就进入 build phase
- Deck 路径写错 / 权限不够
- 生成失败但不报告

## Verification

Before declaring build-gate ready, confirm:
- [ ] html-ppt-skill installed at `~/.agents/skills/html-ppt-skill/`
- [ ] build-context.md compiled with all relevant sections
- [ ] html-ppt-skill loaded via Skill tool
- [ ] Deck generated successfully (non-empty file)
- [ ] User presented with file path + how to open
- [ ] User explicitly approved (verbal / progress.md entry)
- [ ] Any modifications from review applied
- [ ] Deck re-generated if spec changed

## pwf Integration

Maps to `task_plan.md` **Phase 3.5: Build Gate Visual Review**. The deck goes in `.planning/<plan-id>/build-gate-deck/` (artifact directory, not in task_plan.md).

The gate decision is recorded in `progress.md`:

```
[build-gate] review → user: approve | modify | reject
```

If reject, add a new phase to task_plan.md (e.g., Phase 3.6: Spec revision) and restart from there.

See [pwf-integration.md](../../pwf-integration.md).