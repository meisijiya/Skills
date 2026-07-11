---
name: build-gate-visual-review
description: "Before build phase, renders current project state (spec / plan / design spec / progress) as a single HTML file using HTML Anything, so the user can visually review and approve before any code is written. Use when the project has UI, when the user wants to verify understanding before implementation, or when teaching/learning mode is active."
allowed-tools: "Read Bash Glob Grep Write WebFetch"
---

# build-gate-visual-review

## Overview

在 build 之前,把项目的当前状态(spec / plan / design spec / research findings / progress)渲染成**单文件 HTML**,让用户在浏览器里可视化审视。

目的:build 阶段写代码之前,用户和 agent **对项目状态有共同的、可视化的理解**。纯 markdown 描述容易各理解各的;可视化 HTML 消除歧义。

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

```bash
# HTML Anything CLI installed?
test -d ~/html-anything || which html-anything 2>/dev/null
# Or: bun/pnpm based on user's install
```

If not installed, prompt user:

```bash
git clone https://github.com/nexu-io/html-anything ~/html-anything
cd ~/html-anything && pnpm install && pnpm dev  # starts on localhost:3000
```

HTML Anything reuses your existing AI CLI session — no API key needed.

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

Compile a single markdown document: `BUILD_CONTEXT.md` at `.planning/<plan-id>/build-context.md`.

### 3. Choose HTML Anything template

HTML Anything has 9 surfaces × 75 templates. For build-gate review:

| Surface | Best for |
|---|---|
| **magazine** | Long-form spec narrative |
| **deck** | Slides for stakeholder review |
| **data report** | API contracts, schema diagrams |
| **prototype** | UI mockup preview (if design spec exists) |

Default: **magazine** for spec narrative, **deck** for stakeholder review.

### 4. Generate HTML

Invoke HTML Anything with the chosen template + build-context.md content:

```bash
# Assuming HTML Anything runs on localhost:3000
# API call (or use the web UI):
curl -X POST http://localhost:3000/api/generate \
  -H "Content-Type: application/json" \
  -d '{
    "template": "magazine",
    "surface": "article",
    "input": "'"$(cat .planning/<plan-id>/build-context.md | base64 -w0)"'",
    "output": ".planning/<plan-id>/build-gate.html"
  }'
```

Or use the HTML Anything web UI directly: paste content, pick template, download.

### 5. Verify HTML generated

```bash
test -s .planning/<plan-id>/build-gate.html && echo "OK" || echo "Generation failed"
wc -l .planning/<plan-id>/build-gate.html
```

### 6. Present to user

Tell the user the file path + how to view:

```
Build-gate review ready:
  File: /abs/path/to/build-gate.html
  Open: file:// URL in browser, or run:
        pnpm --dir ~/html-anything dev  # then visit localhost:3000

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
If modify → update spec / plan, regenerate HTML
If reject → go back to spec phase

## Common Rationalizations

| Excuse | Reality |
|---|---|
| "用户已经看了 spec,不需要再 review" | Spec 是文字,build-gate 是可视化。两种认知负担不同。 |
| "HTML 渲染浪费时间" | 5 分钟渲染 vs 50 分钟改错代码。前者更快。 |
| "纯后端项目不需要这个" | 对,后端跳过 build-gate(写明 NOT for)。 |
| "用户太忙,跳过 review" | 忙 ≠ 不要 review。Build-gate 是异步的,用户有空再看。 |
| "直接动手,出问题再调" | 出问题再调 = 返工 = 更慢。 |
| "HTML Anything 装起来麻烦" | `git clone && pnpm install && pnpm dev` 30 秒。 |

## Red Flags

- HTML Anything 没装就用 skill(脚本会失败)
- 跳到 build 之前没等用户确认
- Build context 拼凑不全(漏 spec / 漏 design)
- HTML 模板选错(prototype 模板渲 spec 文档会很怪)
- 用户没看到 build-gate.html 就进入 build phase
- build-gate.html 路径写错 / 权限不够
- 生成 HTML 失败但不报告

## Verification

Before declaring build-gate ready, confirm:
- [ ] HTML Anything installed and running
- [ ] build-context.md compiled with all relevant sections
- [ ] HTML generated successfully (non-empty file)
- [ ] User presented with file path + how to open
- [ ] User explicitly approved (verbal / progress.md entry)
- [ ] Any modifications from review applied
- [ ] HTML re-generated if spec changed

## pwf Integration

Maps to `task_plan.md` **Phase 3.5: Build Gate Visual Review**. The HTML goes in `.planning/<plan-id>/build-gate.html` (not in task_plan.md — it's an artifact, not a plan element).

The gate decision is recorded in `progress.md`:

```
[build-gate] review → user: approve | modify | reject
```

If reject, add a new phase to task_plan.md (e.g., Phase 3.6: Spec revision) and restart from there.

See [pwf-integration.md](../../pwf-integration.md).