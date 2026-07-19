---
name: code-simplification
description: "Backward-compat alias. For cleanup passes, prefer OMO built-in `refactor` (auto-routes to /simplify), `ponytail-review` (over-engineering hunt), and `remove-ai-slops` (AI-generated smell cleanup). This skill is preserved only so existing installs find a routing target with a Chesterton's Fence reminder."
allowed-tools: "Read Edit Bash Glob Grep"
---

# code-simplification

## Overview

**ALIAS**:行为不变前提下削减复杂度的"6 techniques + Chesterton's Fence"方法论,已经被 OMO 内置 skill 覆盖:

| 任务 | 改用 OMO 内置 | 触发方式 |
|---|---|---|
| 一般重构(repeated logic / 抽象 / 命名) | `refactor` | `/refactor` 或 `code-simplification` 的 description match 时改调用此 skill |
| 过度工程化狩猎(YAGNI / 不必要的接口 / 工厂) | `ponytail-review` | `/ponytail-review` |
| AI 生成代码味(structural duplication / 长 if-elif / 占位) | `remove-ai-slops` | `/remove-ai-slops` |
| 只有 Chesterton's Fence 一句话提醒 | **本 skill 保留此条** | 见 Process § 1 |

**新流程请直接调用 OMO 内置 skill。** 本 skill 仅作向后兼容入口(其唯一独立价值是 Chesterton's Fence 一句提醒)。

## When to Use

**Use when:**
- 项目仍引用 `code-simplification` 名称(旧配置 / 旧 docs)
- 你需要 Chesterton's Fence 提醒:**改代码前先搞明白它为什么存在** — 没搞清楚前别删

**NOT for:**
- 真做 simplification:用 OMO `refactor` / `ponytail-review` / `remove-ai-slops`
- AI slop 清扫:OMO `remove-ai-slops`(不要在本 skill 里手撸 grep 占位)

## Process

### 1. Chesterton's Fence (本 skill 唯一保留的硬规则)

> **删任何代码前,先回答:它为什么存在?**

回答不出来(没 blame、没 PR history、找不到原作者)→ **不要删**。

```bash
git blame -L <start>,<end> path/to/file.ts
git log --all --oneline -- path/to/file.ts
```

如果这俩都不够,去问原作者(在 PR / chat / 公司 Slack)。**删一行能藏 5 层逻辑**,第 1 个被合并的 PR 不会感谢你。

### 2. 其余步骤(高阶流程)— 改用 OMO 内置 skill

| 你想做 | skill |
|---|---|
| 一般重构 | `refactor` |
| 找过度工程 | `ponytail-review` |
| 清理 AI slop | `remove-ai-slops` |
| 缩窄本 Skill 重复内容 | (无 — 别再加) |

不要在本 skill 里复制 6 techniques 完整流程 — OMO 已有。

## Common Rationalizations

| Excuse | Reality |
|---|---|
| "装了 code-simplification,直接用它就行" | 优先 OMO `refactor` / `ponytail-review` / `remove-ai-slops`,本 skill 只剩 Chesterton's Fence 一条 |
| "把 OMO 的能力再写一遍保险一点" | 重复实现 = 双份维护负担,且你会得到 OMO 已经拒绝的错误版本 |
| "Chesterton's Fence 太保守了" | 数据:删一行无 git blame 引发的回归 bug 数 >> 因为"谨慎过度"延后的 PR 数 |

## Red Flags

- 在本 skill 里跑 `grep -E "TODO|FIXME"` 当 cleanup(那是 AI-slop 识别,走 `remove-ai-slops`)
- "我看一眼就知道这行没用" → 走 Chesterton's Fence:**用 git blame 印证**
- 改完没跑全测就 commit
- 一次删超过 50 行却没 blame 查询记录(见 Chesterton's Fence)

## Verification

Before relying on this skill:
- [ ] 我已确认本次 cleanup 改用 OMO `refactor` / `ponytail-review` / `remove-ai-slops` 之一
- [ ] 唯一保留:Chesterton's Fence 已查 blame / history

## pwf Integration

被 OMO 内置 `refactor` / `ponytail-review` / `remove-ai-slops` 取代。Phase 6 Cleanup 仍可在 `task_plan.md` 留行,但实现细节交给 OMO。

## Related Skills

- **OMO canonical**:`refactor` / `ponytail-review` / `remove-ai-slops`
- 对应 `task_plan.md` Phase 6: Cleanup