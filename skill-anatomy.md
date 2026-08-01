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
- **必须以 "Use when ..." 开头** — 优先描述**触发条件**,而非 skill 的工作流摘要(Superpowers 实证测试:描述含流程摘要会导致 agent 跳过读全文,直接按 description 执行)
- **触发句式**:`Use when [具体触发条件/症状/上下文]`(可接同义表达 `Use before/after/during/in/for`、`Apply when`、`Load when`、`Triggers:`)
- **可含 what 摘要,但只放在触发句之后** — 现有 skill 的 "what + Use when" 双段式格式可接受;新 skill 推荐"Use when ..." 开头(分阶段迁移,不强制重写)
- **必须能让 agent 判断"现在该不该加载这个 skill"**
- **≤ 1024 字符**(硬上限),推荐 ≤ 500 字符(更易在 group picker 中完整展示)
- **不要写流程步骤**("1. xxx 2. xxx");流程属于 SKILL.md body,不属于 description

### `name` 规则

- kebab-case(小写 + 连字符)
- **必须满足正则 `^[a-z0-9]+(-[a-z0-9]+)*$`** — 禁止连续 `--`、首尾连字符、保留字(`anthropic-` / `claude-`)
- **推荐 gerund 形式**(Anthropic best-practices):`-ing` 结尾(`brainstorming` / `debugging` / `testing`) — 不强制,但与 Anthropic 标准对齐
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
      "name": "meisijiya-domain",        // 选装集(domain group · 11 个)
      "skills": [
        "./skills/extra/<domain-skill-name>",
        ...
      ]
    },
    {
      "name": "meisijiya-frontend",      // 选装集(frontend group · 3 个)
      "skills": [
        "./skills/extra/<frontend-skill-name>",
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
- 必装集(9 个)放 `meisijiya-core`(单 entry 保留必装视觉信号);选装集按 6 个 group(`security` / `cicd` / `observability` / `meta` / `domain` / `frontend`)分开放,共 33 个,7 个 entry
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

## 安全(Safety)

**只从可信源安装 skill**。本仓库的 skill 经 omo 生态审计,符合 OpenCode + OMO 插件适配;第三方 skill 可能包含未审计的指令或脚本,在加载前必须人工 review:

- **仓库视角**:本 fork 继承自 [addyosmani/agent-skills](https://github.com/addyosmani/agent-skills) + [obra/superpowers](https://github.com/obra/superpowers) + 社区贡献;每个 SKILL.md 的 `omo Integration` 段明示其调用的 OMO 资源(`task()` / `oracle` / `librarian` 等)。装到 `.agents/skills/` 后,skill 在 OpenCode 加载时会进入 `<available_skills>`,模型可能根据 description 自动 invoke。
- **用户视角**:通过 `npx skills add meisijiya/Skills` 装本仓库的 skill 是受信任路径;通过 `npx skills add <unknown-source>/<repo>` 装第三方 skill 前,先 review `SKILL.md` 的 description 是否合理、`Process` 段是否会触发不可逆动作(`git push --force` / `rm -rf` / 网络请求外部 URL 等)。
- **审计线索**:每个 skill 的 `verification-before-completion` 段是反向测试 — 如果 skill 让你跳过 verification,这就是一个 red flag。
- **威胁模型**:恶意 skill 可能让 model 执行 description 之外的工具调用(如 `Bash` 跑外部脚本、`WebFetch` 抓取钓鱼 URL);`allowed-tools` 字段是显式声明的工具白名单,frontmatter 缺 `allowed-tools` 时 model 默认有全部工具权限。

**对齐**:Anthropic / OpenCode / Superpowers 三方权威都强调 "install only from trusted sources";本段是该共识在 meisijiya-skills 的本地化表达。

**仅 OpenCode + OMO 插件适配**:本仓库的 skill **仅**针对 OpenCode + oh-my-openagent (omo) 生态设计,引用 `~/.config/opencode/plugins/`、`~/.agents/skills/`、OMO 内置 MCPs (`context7` / `grep_app` / `websearch` / `lsp`)、内置 agents (`sisyphus` / `prometheus` / `atlas` / `oracle` / `librarian`)、内置 skills (`git-master` / `review-work` / `visual-qa` / `remove-ai-slops` / `init-deep` / `frontend` / `playwright`)、内置 modes (`hyperplan` / `security-research` / `ultrawork`)。其他 harness (Claude Code / Codex / Cursor / 等) 的扩展字段(`when_to_use` / `user-invocable` / `context: fork` / hooks) **不在本仓库支持范围内**,刻意不引入以避免 YAGNI 兼容成本。

### Controlled extension fields

少数来自其他 harness 的字段虽然被刻意排除,但有 1 个例外因真实需要被列为**受控扩展字段**(controlled extension field)— 允许使用,但使用门槛被 validator 强制。

| 字段 | 状态 | 原因 |
|---|---|---|
| `disable-model-invocation` | **CONTROLLED**(allowlist only) | 强制 agent 不自动 invoke,只能用户手动触发(stateful 交互会话场景)。其他 skill 不得使用 |
| `when_to_use` / `user-invocable` / `context: fork` / hooks | 禁用(YAGNI) | 无本仓库真实需求 |

#### `disable-model-invocation` 政策

**Allowlist(2026-08-01)**:仅 `loop-me`(stateful `/grilling` 交互会话;避免与 `brainstorming` 自动 description 匹配产生路由竞争)。

**Frontmatter pairing**:任何 skill 标 `disable-model-invocation: true` **必须**紧随其后(下一行)声明:

```yaml
disable-model-invocation: true
disable-model-invocation-justification: "<one-sentence reason — why this skill needs user-only invocation>"
```

**Eval pairing**:该 skill 的 `evals/cases/<name>.json` **必须**有 ≥1 `behavioral_evals` 场景,显式说明用户触发模式(user-triggered / manual invocation / explicit user invocation / disable-model-invocation 关键字之一),并显式证明 agent **不会**自动 invoke 该 skill(例如:用户在没有显式 `/skill-name` 调用时,agent 不会加载该 skill)。

**Validator 强制**:`scripts/validate-skills.sh` 加 §9 检查 — skill 在 allowlist 中但 frontmatter 缺 `disable-model-invocation-justification` 或 eval 缺 behavioral scenario,**FAIL**;skill 不在 allowlist 但 frontmatter 含 `disable-model-invocation: true`,**FAIL**。

**加新 skill 到 allowlist 的流程**:(1) 提 PR 描述真实需求场景;(2) 在 frontmatter 加 justification;(3) eval 加 ≥1 behavioral scenario 证明 user-only invocation;(4) `skill-anatomy.md` allowlist 表格更新该 skill 名;(5) `scripts/validate-skills.sh` allowlist 同步更新;(6) `scripts/validate-skills.sh` 跑通。