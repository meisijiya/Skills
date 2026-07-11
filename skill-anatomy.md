# Skill Anatomy

每个 SKILL.md 必须满足的规范。

## Frontmatter(必填)

```yaml
---
name: kebab-case-name
description: 第三人称描述(≤1024 字符)。包含 "what" + "Use when"。
# 以下可选,按需加:
allowed-tools: "Read Edit Bash Glob Grep"
---
```

### `description` 规则

- **第三人称**:"Guides agents through X" / "做 X。Use when Y。"
- **包含触发条件**:"Use when Y"
- **禁止包含流程摘要**——否则 agent 会按摘要跳过读全文
- **必须能让 agent 判断"现在该不该加载这个 skill"**

### `name` 规则

- kebab-case(小写 + 连字符)
- 必须跟 SKILL.md 所在的目录名一致

## 6 个标准段(推荐结构)

按顺序:

| 段 | 作用 |
|---|---|
| **Overview** | 一两句话说明 skill 做什么、为什么重要 |
| **When to Use** | 触发条件 + NOT for(反向排除) |
| **Process** | 步骤化工作流(可编号、可分支) |
| **Common Rationalizations** | agent 跳步骤的借口 + 反驳(表格) |
| **Red Flags** | skill 被错误应用的迹象(列表) |
| **Verification** | 退出条件 + 证据要求(checkbox) |

不是死模板——等价标题如 `How It Works` / `Workflow` / `Core Process` 可接受。

## 上下文效率

- **推荐 ≤500 行**
- 超过 100 行的参考材料拆到 supporting file
- 一层引用:`SKILL.md` → `supporting.md`,不要链式 `a → b → c`

## 双 frontmatter 兼容

| 平台 | 必需字段 | 可选字段 |
|---|---|---|
| **pwf** | `name` + `description` | (无) |
| **omo** | `name` + `description` | `allowed-tools`, `hooks`, `mcpConfig` |

**本 fork 默认只写 pwf 必需字段**。omo 字段按需添加(详见各 skill 顶部注释)。

## 命名

| 元素 | 命名风格 | 示例 |
|---|---|---|
| skill 目录 | kebab-case | `test-driven-development/` |
| skill 文件 | 大写 | `SKILL.md` |
| supporting 文件 | kebab-case | `phase-templates.md` |
| frontmatter `name` | kebab-case,跟目录名一致 | `name: test-driven-development` |

## 引用其他 skill

- 用反引号包住 skill 名:`test-driven-development`
- **不要重复内容**——直接引用即可
- 引用 hooks / 命令:`attest-plan.sh`、`/plan-goal`

## 不要做的事

- 不要在 description 里写流程步骤
- 不要写"参考 Google 工程实践"这种空泛的引用(具体说引用哪本书哪一章)
- 不要用模糊的 verification("make sure it works" → "run `npm test` and verify exit 0")
- 不要超过 500 行不拆 supporting file
- 不要在 SKILL.md 里写 README 风格的介绍——那是 README 的事