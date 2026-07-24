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

- **必填 install path** — 提到别的 skill 时,必须用 markdown link 给出 `~/.agents/skills/<name>/SKILL.md`:
  ```markdown
  Run [`test-driven-development`](~/.agents/skills/test-driven-development/SKILL.md) first.
  ```
  AI 知道 skill 名但不知道去哪读 — 必须在每个引用给路径。**这不只是规范,是运行时可读性**。
- 用反引号包住 skill 名:`test-driven-development`
- **不要重复内容**——直接引用即可
- 引用 hooks / 命令:`attest-plan.sh`、`/plan-goal`
- **失效检测** — 项目级 AGENTS.md 里的 skill 引用用 install path 后,grep 一下就能扫出 broken refs;上游改名 / 删 skill 时会立刻暴露

## 不要做的事

- 不要在 description 里写流程步骤
- 不要写"参考 Google 工程实践"这种空泛的引用(具体说引用哪本书哪一章)
- 不要用模糊的 verification("make sure it works" → "run `npm test` and verify exit 0")
- 不要超过 500 行不拆 supporting file
- 不要在 SKILL.md 里写 README 风格的介绍——那是 README 的事

## Marketplace 清单(.claude-plugin/marketplace.json)

`npx skills add <repo>` CLI 靠这个文件把 skill 分组显示。**新增 skill 时必须同步更新它**,否则 picker 里看不到新 skill。

### 文件结构

```json
{
  "plugins": [
    {
      "name": "meisijiya-core",          // 必装集(9 个)
      "skills": [
        "./skills/core/<skill-name>",
        ...
      ]
    },
    {
      "name": "meisijiya-security",      // 选装集(security group · 9 个)
      "skills": [
        "./skills/extra/<security-skill-name>",
        ...
      ]
    },
    {
      "name": "meisijiya-cicd",          // 选装集(cicd group · 2 个)
      "skills": [
        "./skills/extra/<cicd-skill-name>",
        ...
      ]
    },
    {
      "name": "meisijiya-observability",  // 选装集(observability group · 4 个)
      "skills": [
        "./skills/extra/<observability-skill-name>",
        ...
      ]
    },
    {
      "name": "meisijiya-meta",          // 选装集(meta group · 4 个)
      "skills": [
        "./skills/extra/<meta-skill-name>",
        ...
      ]
    },
    {
      "name": "meisijiya-domain",        // 选装集(domain group · 7 个)
      "skills": [
        "./skills/extra/<domain-skill-name>",
        ...
      ]
    }
  ]
}
```

### 规则

- `name` 是 picker 里显示的 group header(`npx skills add` 按 group 展示,可选整组团或单 skill)
- 每个路径必须以 `./` 起头
- 路径指向 skill 目录(包含 SKILL.md 的目录),**不是 SKILL.md 文件本身**
- 必装集(9 个)放 `meisijiya-core`(单 entry 保留必装视觉信号);选装集按 5 个 group(`security` / `cicd` / `observability` / `meta` / `domain`)分开放,共 26 个,5 个 entry
- 同一 skill 不能出现在多个 plugin 里(否则 pluginName 二义性)
- 新增 group(罕见):在 `marketplace.json` 加新 plugin entry、`scripts/inject-agents-md.sh:47` 的 `GROUP_SUFFIXES` 数组加对应后缀、`AGENTS.md` Section A 加 `**<group> (N):**` 块(N 自动从 manifest 派生)
- `core/` 保持单 entry 而**不**按学科拆,因为"必装"是定位信号(group 拆了反而稀释);如需拆 core,先确认会导致 picker UX 变化

### 添加新 skill 的步骤

1. 写 `skills/<dir>/<new-skill>/SKILL.md` 满足上方全部规则
2. 把 `"./skills/<dir>/<new-skill>"` 加到 `marketplace.json` 对应 plugin 的 `skills[]` 数组
3. 加 `evals/cases/<new-skill>.json`
4. 跑 `bash scripts/check-marketplace.sh` — 应输出 `OK`
5. 跑 `bash scripts/validate-skills.sh` — 应 `24/24`(或更新后的数字)

**CI 会自动跑 step 1-4**。任何漂移 → PR 失败。

## 安装完整性(Install Integrity)

`npx skills add <repo> --skill <name>` 把整个 skill 目录**递归**拷贝到目标位置(默认 `~/.agents/skills/<name>/`),**不只是 `SKILL.md`**。

### 关键事实

- **递归拷贝**:`src/installer.ts` 的 `copyDirectory()` 递归复制所有子目录与文件
- **硬排除集**(源码 `EXCLUDE_FILES` / `EXCLUDE_DIRS`):
  - 文件:`metadata.json`
  - 目录:`.git/`、`__pycache__/`、`__pypackages__/`
- **目标布局**:`<target>/<skill-name>/` 与源目录**结构完全一致**(子目录、文件名都保留)
- **全局 vs 项目**:`-g` 全局装到 `~/.agents/skills/`、项目级装到 `./.agents/skills/`,都走相同递归逻辑
- **current version**:v1.5.19(2026-07-16)非扁平 skill 结构完全支持

### 历史 bug(已修复)

| Issue / PR | 状态 |
|---|---|
| Issue #3 "npx skills add only installs SKILL.md, omitting prompts/" | 已修 |
| Issue #753 "CLI fails to download subdirectories within --skill filter" | 已修 |
| PR #1609 "fix: install full skill directory for root-level SKILL.md repos" | merged |

### 现有非扁平 skill 范例

- [`skills/extra/pwf-enforcer/templates/pwf-enforcer.ts`](skills/extra/pwf-enforcer/templates/pwf-enforcer.ts) —— SKILL.md 之外的支撑文件,正确由递归拷贝处理
- [`skills/extra/verify-chain/prompts/{critic,verifier,repairer}.md`](skills/extra/verify-chain/prompts/) —— 3 角色流水线 prompt,作为 subagent 注入内容

### 手验方法

```bash
# 全局安装
npx skills add <repo> --skill <name> -g -y -a opencode

# 验证目标目录含全部文件(应该看到 SKILL.md + 任何支撑文件/子目录)
ls -R ~/.agents/skills/<name>/

# 清理(测试后)
npx skills remove <name> -g -a opencode
```

### 命名约束

- YAML frontmatter `name: <kebab-case>` 必须跟 `--skill <name>` 精确匹配(CLI 同时支持匹配 frontmatter `name` 和目录 basename)
- **不要**在 skill 根目录放名为 `metadata.json` 的文件(会被硬排除)
- 不在硬排除集中的任意文件名都安全(包括 `prompts/`、`references/`、`scripts/`、`assets/`、`templates/` 等)

### 已知约束

- `npx skills add` CLI 用 `pluginName` 字段做 group header(`pluginName = name`)
- 单个 `name` 只能给所有列出的 skill 同一个 group → 必须用 `marketplace.json` 多 plugin entry 才有多个 group
- CLI 不按目录名分组(`.core/` vs `.extra/` 仅是组织约定,不影响显示)