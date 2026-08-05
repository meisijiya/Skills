# omo Skill 配置参考

> **本文档的姊妹文档**：[`using-meisijiya-skills`](../../skills/core/using-meisijiya-skills/SKILL.md) — **Sisyphus dispatcher skill**（运行时读）。本文档是**用户配置参考**（手工应用 `omo.jsonc`）。
>
> **TL;DR**：omo 没有 `agents.<name>.skills` 字段。Skill 管理 = **4 个机制**：(1) `<available_skills>` 全可见（OpenCode 原生），(2) `task(load_skills=[...])` 由 Sisyphus 在 dispatch 时显式加载（**核心决策点**），(3) per-edit reminder plugin（review-router，已实现 8 个 reminder），(4) `task()` dispatch-gate plugin（**hard 层**兜底 Sisyphus 漏传 `load_skills`；MVP 覆盖 `visual-engineering` + `deep`）。

---

## 一、omo Skill 加载的 4 个机制

omo 通过 **4 层机制** 加载 skill，**没有 per-agent skill 白名单配置字段**。

### L1：`<available_skills>` 自动可见

OpenCode 扫描 `~/.agents/skills/` 路径下的所有 SKILL.md，把它们的 `name` + `description` 注入每个 agent 的 `<available_skills>` system prompt 列表。

**所有 agent 默认能看到所有 skill description**。这意味着 agent 会**知道**每个 skill 的存在，但**不一定会主动 invoke**（description 触发是弱信号，特别是窄触发 skill）。

### L2：`task(load_skills=[...])` 由 Sisyphus 显式加载（核心）

Sisyphus 在 dispatch sub-agent 时，可以指定要加载哪些 skill：

```typescript
task(
  category: "visual-engineering",
  load_skills: ["meisijiya-frontend-taste"],  // ← 关键
  prompt: "..."
)
```

**没有 `load_skills=[...]`，sub-agent 经常漏触发窄 skill**（如 `meisijiya-frontend-taste` 的 trigger 是 "agent writes marketing-grade UI code"，容易被忽略）。

**SOT（single source of truth）**：[`using-meisijiya-skills`](../../skills/core/using-meisijiya-skills/SKILL.md) 的 **Category × Skill Matrix** + **Common Dispatch Scenarios** 段。这是 Sisyphus 应该读的协议。

### L3：per-edit reminder plugin

`~/.config/opencode/plugins/meisijiya-review-router.js` 在 Write/Edit/apply_patch 后追加 reminder，引导 invoke：

| File path pattern | Reminder skill |
|---|---|
| `*.ts` / `*.js` / `*.py` / `*.go` / `*.rs` (AI-generated code) | `ai-code-blindspots` |
| 任何文件 | `security-and-hardening` |
| `.github/workflows/*.yml` | `gha-security-review` |
| `*test*.ts` / `*.test.js` 等 | `test-guard` |
| `.tsx` / `.jsx` / `.vue` / `.svelte` | `meisijiya-frontend-taste` + `stack-security-coder` |
| `.tsx` / `.jsx` / `.vue` / `.svelte` / `.css` / `.scss` / `.less` | `meisijiya-redesign-ui` |
| `.swift` / `.dart` | `stack-security-coder` |
| Write/Edit tool calls | `verification-before-completion` |

这是**文件路径触发的硬规则**，**不是 skill 配置**。

### L4：`task()` dispatch-gate plugin（load_skills 兜底，新加）

L2 是 soft 层（Sisyphus 主动传 `load_skills`），但 LLM 调用率 ~80-90%（per `meisijiya-skills.js` acceptance test 段落）。

`~/.config/opencode/plugins/meisijiya-dispatch-gate.js`（**hard 层**，可选安装）作为 L2 的兜底：

| 情况 | plugin 动作 |
|---|---|
| `load_skills=[]` / undefined + matrix-mapped category（visual-engineering / deep MVP） | 注入 RECOMMENDED（按 `installed()` 过滤掉未装的 skill）|
| `load_skills=[...]`（任意非空）| **不动 args** + `console.warn` 提示 matrix 推荐 |
| category 不在 MVP | no-op |
| tool != task | no-op |
| 全局 | mutate 字段,**永不 throw**,**永不 reassign args** |

安装（可选，独立 install）：

```bash
cp .opencode/plugins/meisijiya-dispatch-gate.js ~/.config/opencode/plugins/
```

**SOT sync**：plugin 头部注释声明 SOT → `~/.agents/skills/using-meisijiya-skills/SKILL.md` §Category × Skill Matrix；matrix 变更时同步更新 plugin `RECOMMENDED` 常量。MVP 仅 `visual-engineering` + `deep`，扩展其他 category 需 (a) matrix 同步 (b) RECOMMENDED 加行 (c) 单测加正例 (d) eval case 评估是否加 behavioral。

---

## 二、omo 的实际 schema（没有 per-agent skill 字段）

来源：[omo `docs/reference/configuration.md`](https://github.com/code-yeongyu/oh-my-openagent/blob/dev/docs/reference/configuration.md) + [`docs/reference/omo-json.md`](https://github.com/code-yeongyu/oh-my-openagent/blob/dev/docs/reference/omo-json.md)

### `agents.<name>` 支持的字段

```jsonc
{
  "agents": {
    "<name>": {
      "model": "<provider>/<model-name>",       // ← 实际能配的,具体 provider 由 OMO 运行时决定
      "fallback_models": ["<provider>/<model-name>"],  // ← 实际能配的
      "prompt": "..." | "file://...",
      "prompt_append": "...",
      "tools": { "edit": "allow" | "deny" },
      "temperature": 0.1,
      "disable": true,
      "permission": { "edit": "ask" | "allow" | "deny", "bash": "..." }
    }
  }
}
```

**没有 `skills` 字段**。`variant` / `reasoningEffort` / `fallback_models` 等老 key 已被迁移到 `reasoning` + `models`。

### `categories.<name>` 支持的字段

```jsonc
{
  "categories": {
    "visual-engineering": {
      "model": "<provider>/<model-name>",
      "fallback_models": ["<provider>/<model-name>"],
      "prompt_append": "...",
      "tools": { "bash": false },
      "disable": false,
      "warn_unavailable": false
    }
  }
}
```

**没有 `skill` 字段**。

### `skills.<name>` 全局 per-skill 配置

```jsonc
{
  "skills": {
    "sources": [{ "path": "~/.agents/skills", "recursive": true }],
    "enable": ["my-skill"],
    "disable": ["other-skill"],
    "my-skill": {
      "description": "...",
      "allowed-tools": ["read", "bash"],
      "model": "<provider>/<model-name>",
      "agent": "custom-agent",
      "subtask": true
    }
  }
}
```

这是**唯一 per-skill 配置入口**。但它是**全局**的，不是 per-agent。

---

## 三、6 个新 skill 的全局配置示例（v0.8.0+）

基于 [`using-meisijiya-skills`](../../skills/core/using-meisijiya-skills/SKILL.md) 的 Category × Skill Matrix，6 个新 skill 的推荐配置：

```jsonc
{
  "skills": {
    "meisijiya-frontend-taste": {
      "allowed-tools": ["read"],
      "model": "<provider>/<model-name>"
    },
    "meisijiya-minimalist-ui": {
      "allowed-tools": ["read"],
      "model": "<provider>/<model-name>"
    },
    "meisijiya-redesign-ui": {
      "allowed-tools": ["read"],
      "model": "<provider>/<model-name>"
    },
    "prototype": {
      "allowed-tools": ["read", "edit", "bash", "glob", "grep"]
    },
    "wayfinder": {
      "allowed-tools": ["read", "edit", "bash", "glob", "grep"]
    },
    "research": {
      "allowed-tools": ["read", "edit", "bash", "glob", "grep"]
    }
  }
}
```

**为什么 `allowed-tools` 是关键？**

| Skill | `allowed-tools` | 含义 |
|---|---|---|
| 3 个 frontend triad | `["read"]` | 这些 skill 是 reference-only（约束规则集），不应有 Edit/Write 权限；UI 输出由 frontend agent 自己负责 |
| `prototype` / `wayfinder` / `research` | `["read", "edit", "bash", "glob", "grep"]` | 这些 skill 需要写文件（prototype 变体、wayfinder plan、research report）|

---

## 四、Sisyphus Dispatch Patterns（完整决策树）

完整版见 [`using-meisijiya-skills` § Common Dispatch Scenarios](../../skills/core/using-meisijiya-skills/SKILL.md)。这里给 6 个新 skill 的精简版：

| 任务 | `task(category=..., load_skills=[...])` |
|---|---|
| 写 React/Vue UI | `task(category="visual-engineering", load_skills=["meisijiya-frontend-taste"])` |
| Linear/Notion 风格 UI | `task(category="visual-engineering", load_skills=["meisijiya-frontend-taste", "meisijiya-minimalist-ui"])` |
| 改造现存 UI | `task(category="visual-engineering", load_skills=["meisijiya-redesign-ui"])` |
| Spec 阶段视觉决策 | `task(category="unspecified-low", load_skills=["prototype"])` |
| 多 session 规划 | `task(load_skills=["wayfinder"])` |
| Plan 阶段权威研究 | `task(load_skills=["research"])` |

---

## 五、常见误解澄清

### ❌ "我可以在 `omo.jsonc` 给特定 agent 限定 skill 列表"

**不能**。omo schema 没有 `agents.<name>.skills` 字段。任何 agent 默认能看到所有 skill description。

如果你想"屏蔽"某个 skill，只能用全局 `skills.disable: ["my-skill"]`——这是**全局**禁用，不是 per-agent。

### ❌ "我可以指定 `sisyphus` 用 `["*"]` 兜底"

**没意义**。`<available_skills>` 已经默认全部可见。`["*"]` 在 schema 中也不存在。

### ❌ "文件路径触发的 review-router 是 skill 配置"

**不是**。review-router plugin 是 `~/.config/opencode/plugins/` 下的 `.js` 文件，由 OpenCode plugin hook 触发。它与 `omo.jsonc` 的 skill 配置是**正交**的两层。

### ❌ "我应该把 meisijiya-frontend-taste 给 build agent 加 allowed-tools"

**build agent 默认就能 invoke meisijiya-frontend-taste**（通过 `<available_skills>` + review-router 触发）。allowed-tools 控制的是 skill 加载时的工具权限（"这个 skill 能用什么工具"），不是"哪些 agent 能用它"。

---

## 六、Apply 此配置

```bash
# 用户级
~/.omo/omo.jsonc

# 项目级
<project>/.omo/omo.jsonc
```

修改后**重启 OpenCode** 才能生效（omo 启动时一次性读取配置）。

> **Field-name note**：早期版本用 `oh-my-openagent.json[c]` / `oh-my-opencode.json[c]`，已迁移到统一 `omo.jsonc`。详细迁移说明见 [omo migration docs](https://github.com/code-yeongyu/oh-my-openagent/blob/dev/docs/reference/configuration.md#migration)。

---

## 七、相关文档

- [`using-meisijiya-skills`](../../skills/core/using-meisijiya-skills/SKILL.md) — **SOT**：dispatch 协议 + Category × Skill Matrix + Common Dispatch Scenarios
- [omo `docs/reference/configuration.md`](https://github.com/code-yeongyu/oh-my-openagent/blob/dev/docs/reference/configuration.md) — 完整 schema
- [omo `docs/reference/omo-json.md`](https://github.com/code-yeongyu/oh-my-openagent/blob/dev/docs/reference/omo-json.md) — 字段定义
- [omo `docs/reference/orchestration.md`](https://github.com/code-yeongyu/oh-my-openagent/blob/dev/docs/guide/orchestration.md) — task(category=, load_skills=) 协议

## Verification

After applying:
1. Restart OpenCode session.
2. Run `using-meisijiya-skills` — should see the new "Sisyphus Dispatch Protocol" + "Category × Skill Matrix" + "Common Dispatch Scenarios" sections.
3. Dispatch a sub-agent task with `load_skills=["meisijiya-frontend-taste"]` — sub-agent's instructions should explicitly include meisijiya-frontend-taste's SKILL.md body.
4. Edit a `.tsx` file — review-router should fire `meisijiya-frontend-taste` reminder (per-edit reminder, not skill config).
</content>
</invoke>