---
name: interview-me
description: "Backward-compat alias. The one-question-at-a-time discipline lives in `brainstorming` (core/). For new sessions, invoke `brainstorming` directly. This skill is preserved only so existing installs continue to find a routing target."
allowed-tools: "Read AskUserQuestion"
---

# interview-me

## Overview

**ALIAS**:这个 skill 的"一问一答 + 选项式提问 + 推荐答案 + 不对齐不实施"规则已经被 [`brainstorming`](~/.agents/skills/brainstorming/SKILL.md) 完整吸收。

**新会话请直接调用 `brainstorming`。** 本 skill 仅作为向后兼容入口保留(已装的仓库能找到路由目标,但实际内容已并入 brainstorming)。

## When to Use

**Use when:**
- 项目仍引用 `interview-me` 名称(旧配置 / 旧 docs / 第三方教程)
- 你需要快速确认"这套规则现在挂在哪个 skill 名下"——就是这个:`brainstorming`

**NOT for:**
- **新建流程**:直接 [`brainstorming`](~/.agents/skills/brainstorming/SKILL.md)。`brainstorming/SKILL.md` § Process.2 已含完整 one-question-at-a-time + 选项式 + 推荐答案协议。
- 旧调用方式:`/interview-me` 命令仍可执行(因本 skill 仍存在),但等同调 `brainstorming`。

## Process

1. **新流程请走 [`brainstorming`](~/.agents/skills/brainstorming/SKILL.md) § 2** — 那里有完整规则。
2. **若必须留在这里**:见下 "Legacy" 一问一答协议。

### Legacy 一问一答协议(仅作 reference,等效内容已并入 brainstorming)

- 每次只问一个问题,用 AskUserQuestion 工具,2-4 个互斥选项,带推荐答案。
- facts 自己查,decisions 让人答。
- 3-7 轮迭代到 95% 置信度,> 10 轮说明 scope 错,转 [`spec-driven-development`](~/.agents/skills/spec-driven-development/SKILL.md)。
- 2-3 句总结 + "我理解的对吗?" 确认,再交付。

## Common Rationalizations

| Excuse | Reality |
|---|---|
| "我装了 interview-me,直接用它" | `brainstorming` 已含此功能且更靠前(Phase 0 唯一设计闸门)。`interview-me` 仅是别名。 |
| "老项目还在用这个名字,改不动" | 本 skill 已声明为 alias;调用 `/interview-me` 会路由到 brainstorming 同一协议。无需改文档。 |
| "保留向后兼容有什么代价" | 在系统里多保留一行 frontmatter + 一段 alias 说明。当 brainstorming 演进,本 skill 不需要同步维护。 |

## Red Flags

- 新设计流程调用 `interview-me` 而不是 `brainstorming`(应迁移)
- 在 brainstorming 里发现重复的 question-quality 规则被发明两次(已合并到 brainstorming § 2;别再加重复)

## Verification

Before relying on this skill:
- [ ] 我已确认新流程可改用 [`brainstorming`](~/.agents/skills/brainstorming/SKILL.md)
- [ ] 我没有重新发明 question-quality 表(查 brainstorming § Process.2 即用)

## pwf Integration

被 [`brainstorming`](~/.agents/skills/brainstorming/SKILL.md) Phase 0 完整覆盖。Q&A 摘要写 `progress.md`,不写 `task_plan.md`(不归入 attestation 锁定内容)。

## Related Skills

- **Canonical**:[`brainstorming`](~/.agents/skills/brainstorming/SKILL.md) — 含完整一问一答协议 + Phase 0 Design
- Successor:[`spec-driven-development`](~/.agents/skills/spec-driven-development/SKILL.md) — Spec 写在 `task_plan.md`,此处不再独立