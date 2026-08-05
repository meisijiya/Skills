# meisijiya-dispatch-gate — Design Spec (DRAFT,待 user 批准)

> **状态**:Design + Spec 合并草案(本会话内一次性产出,非 Prometheus plan-scoped)。skill 本体 + plugin 尚未写。批准后 → 进 4-commit 原子提交(per §7 Command list)。
>
> **依赖**:本 spec 与 [phase-vocabulary.md](phase-vocabulary.md) / [state-file-governance.md](state-file-governance.md) / [skill-design-principles.md](skill-design-principles.md) / [omo-agent-skill-config.md](omo-agent-skill-config.md) 互补。dispatcher `using-meisijiya-skills/SKILL.md` §Category × Skill Matrix 是 matrix 推荐集的 SOT。
>
> **触发对话**:user 在 2026-08-05 多次 session 担心 Sisyphus controller 在 `task(load_skills=[...])` 派发时漏传/部分传 load_skills,导致 sub-agent 缺关键纪律技能。经过:
>
> 1. Phase 0 Design 探索(意图分类 → 按组加载 → 反思工程现实 → "dispatcher 训练 + plugin 兜底" 双层保险)
> 2. 4 个并行调研 pass(omo task() 真实 schema / OpenCode `tool.execute.before` 实际能力 / 现有 plugin 改 args 实例 / SKILL.md 主文修改是否真影响 LLM)
> 3. 5-lane design review(设计完整性 / SKILL.md 改写质量 / Plugin 实现风险 / 生态一致性 / Eval+测试覆盖)
> 4. 用户拍板关键决策:Plugin "保持现状 + warning 提示"(LLM 已传 list 时不动,只 console.warn 提示 matrix 推荐)
>
> 5-lane 复审 + 用户决策整合后产出本 spec。

---

## 1. 为什么需要这个 skill + plugin

### 1.1 Gap(纯 dispatcher 训练的局限)

`using-meisijiya-skills/SKILL.md` §Sisyphus Dispatch Protocol 当前已经教 LLM 在 `task()` 时传完整 `load_skills`(per §Category × Skill Matrix)。但 dispatcher 是 **soft layer** —— prompt 注入到 firstUser.parts(L11-15 + 整段 body),LLM 已知应当传完整,但**调用率 ~80-90%**(`meisijiya-skills.js:104-107` "Acceptance test" 段落已记录)。

实际 gap:
- LLM 偶尔忘记 `load_skills` 字段 → 派发到 sub-agent 没有任何 skill body
- LLM 偶尔只传部分(如 `[incremental-implementation]`,漏 `test-driven-development`)→ sub-agent 缺纪律技能
- LLM 偶尔传 `[]`(以为"skill overload 不好"或"这是 trivial task")→ 矩阵映射的非空 category 被强制空
- Plugin 是 hard layer:无论 LLM 决策如何,plugin 在 hook 层强制保证最低限度不空

### 1.2 双层保险方案

| 层 | 机制 | 触发 | 职责 |
|---|---|---|---|
| **训练层** | dispatcher SKILL.md §Hard Rule + §Category × Skill Matrix 重构 | LLM 读 SKILL.md 主文 | **教 LLM 主动传完整 load_skills**(主防线) |
| **兜底层** | new plugin `meisijiya-dispatch-gate.js` | OpenCode SDK `tool.execute.before` hook | **LLM 漏传/部分传时,console.warn 提醒或注入矩阵推荐集**(最后防线) |

**关键边界**:
- 训练层是软层(LLM 80-90% 命中率),兜底层是硬层(100% 触发)
- 兜底层**不替 LLM 决策**:LLM 已传 list 时不动(只 warn 提示),完全尊重 LLM
- 兜底层**只补"完全空"**:不 merge 到 LLM 已传 list(避免"我说 a,plugin 塞 b"的 LLM 困惑)
- 兜底层**不影响 omo 自身**:`tool.execute.before` 只 mutate LLM args 的 `load_skills` 字段,omo 自己 normalize + 派发路径不变

### 1.3 与"纯 dispatcher 训练" / "纯 plugin 注入" 方案的对比

| 维度 | 纯训练(现状) | 纯 plugin 注入 | **本方案(双层)** |
|---|---|---|---|
| LLM 主动率 | ~80-90% | 0%(无 LLM 训练) | ~80-90% + 100% 兜底 |
| 完全空覆盖 | ❌ 漏 | ✅ 注入 | ✅ 注入 |
| 部分空覆盖 | ❌ 漏 | ✅ merge | ⚠️ 不 merge,但 warn 提醒 |
| LLM 困惑 | 无 | 强("我说 a 被塞 b") | 弱("我有 list,但 console 提示可补") |
| 副作用风险 | 无 | LLM 可能困惑 | warn 显式,LLM 下次可补 |
| 实现复杂度 | 低(只需文档) | 中 | 中(文档 + plugin + 测试) |

**结论**:双层保险方案取"训练 + 兜底 + 显式 warn"的中道,在不破坏 LLM 自由度的前提下覆盖所有漏传场景。

---

## 2. Goals / Non-goals

### 2.1 Goals(本 spec 必须做到)

1. **SKILL.md 重构**:`§Sisyphus Dispatch Protocol` 段首加 §Hard Rule;`§Category × Skill Matrix` 主表 visual-engineering / deep 两行重构为 Main+Modifier;`§Common Dispatch Patterns` 改名 `§Common Dispatch Scenarios` 并加矩阵引用;修 L110 方向错误;补 Plugin layer 段首注入机制说明;Process step 8 改写为引用 Hard Rule
2. **新 plugin `meisijiya-dispatch-gate.js`**:`tool.execute.before` hook 拦截 `task()` 工具调用,在 `load_skills` 完全空时按 matrix 注入(经 installed 过滤 + cap 4),在 `load_skills` 非空时 `console.warn` 提示 matrix 推荐;**永不 throw 出 hook**(整体 try/catch)
3. **跨文件同步**:README 插件表 3→4 + 新表行;`docs/omo-agent-skill-config.md` L33/164/217 改名 + TL;DR 3→4 mechanisms;双 SKILL.md 拷贝同步(repo + 用户级);`bin/meisijiya plugin verify` 扩 `.js` 通道(`node --check` 零依赖)
4. **测试覆盖**:plugin 纯函数化(按 `omo-state-index.js:348-357` 模式导出测试表面)+ `tests/plugins/meisijiya-dispatch-gate.test.js`(`node --test` 零依赖,4 类用例);eval case +2 behavioral(§Hard Rule 完整性 + regression 非空 list 不被 mutate)
5. **MVP 范围**:plugin 只覆盖 **visual-engineering + deep** 两个无歧义 category;MVP 跑通 + 用户验收后再扩到 8 category(扩张表驱动数据,每行配正例测试)
6. **可观测**:plugin 注入时 `console.warn` 日志(对齐 `rtk.ts:13-14` 模式),硬层唯一观测点

### 2.2 Non-goals(本 spec **不做** 什么)

- ❌ **不 merge LLM 已传 list** —— 用户决策:保持现状 + warning。LLM 已传 list 时 plugin 只 console.warn 提示,不动 args。
- ❌ **不写 handoff doc** —— 那是 `meisijiya-handoff` 的事(per `disable-model-invocation: true`)
- ❌ **不修改 §Process 主体** —— 只改 step 8 改写为引用 Hard Rule + matrix + dispatch-gate warn;step 1-7 不动
- ❌ **不扩展到 8 category**(MVP 阶段)—— 仅 visual-engineering + deep;`ultrabrain` / `unspecified-high` 有歧义(pick 1 of 3 / bug-vs-skill-creation 二义性),MVP 后单独评估
- ❌ **不解决 SKILL.md 双拷贝同步机制** —— 仓库无 sync script,本次只在 commit 流程里要求双拷贝同改;长期同步机制是独立 YAGNI issue
- ❌ **不暴露 opt-out 哨兵** —— gate 对任何匹配 category + 空 load_skills 的 `task()` 无条件动作(omo 内部派发也包含);`null` 不能当哨兵(omo `prepareDelegateTaskArgs` 对 null 直接 throw)
- ❌ **不修改 omo schema** —— gate 是 orthogonal plugin,不依赖 `oh-my-openagent.json` 任何字段(per `docs/omo-agent-skill-config.md:5` "omo schema 没有 `load_skills` 字段")
- ❌ **不修改 marketplace.json** —— OpenCode plugin 不进 skills CLI marketplace(per `README.md:24-26` "不是 OpenCode Plugin Marketplace")

---

## 3. SKILL.md 重构细节

### 3.1 EXTREMELY_IMPORTANT 块(L11-15)

在 L12 之后插入 1 行:

```markdown
**IMPORTANT**: When dispatching sub-agents via `task()`, ALWAYS pass the COMPLETE `load_skills` set from the Category × Skill Matrix main table — never `[]` for matrix-mapped categories. The dispatch-gate plugin will console.warn if you pass an incomplete list.
```

(成本 ~30 tokens;最高可见性)

### 3.2 §Sisyphus Dispatch Protocol 段首加 §Hard Rule

在 L52 intro 之后、§Pattern 1 之前插入:

```markdown
### Hard Rule (mandatory)

Always pass the COMPLETE `load_skills` set from the Category × Skill Matrix main table below —
never an empty or partial list for a matrix-mapped category. Exceptions: categories the matrix
explicitly maps to `[]` (`quick`, `unspecified-low`, `artistry`). Never exceed 3 skills (Red Flags);
when a scenario needs more, expand via Common Dispatch Scenarios, not the matrix cell.
```

### 3.3 §Category × Skill Matrix 主表重构(L87-96)

主表前加 legend:

```markdown
Legend: `Main` = base bundle · `+X` = additive modifier · `→X` = substitute (mutually exclusive with Main)
```

`visual-engineering` 行改为:

```markdown
| `visual-engineering` | UI/UX code (React/Vue/Svelte/Tailwind) | Main: `["meisijiya-frontend-taste"]`; +`"meisijiya-minimalist-ui"` (Linear/Notion/editorial brief); →`"meisijiya-redesign-ui"` (existing UI audit-fix, see Scenarios §3) |
```

`deep` 行改为:

```markdown
| `deep` | Autonomous deep implementation | Main: `["incremental-implementation"]`; +`"test-driven-development"` (TDD-required) |
```

其余 6 行(`ultrabrain` / `quick` / `unspecified-low` / `unspecified-high` / `writing` / `artistry`)MVP 阶段保持原状,后续扩展时按相同模式重构。

### 3.4 §Common Dispatch Patterns → §Common Dispatch Scenarios

- 改名:标题改为 `## Common Dispatch Scenarios`(原 L122)
- 过渡标记:新标题下加 `(formerly Common Dispatch Patterns)`
- 每个 Pattern 内部加 `→ see matrix row: visual-engineering` 引用
- 顺序按主表 category 排序(visual-engineering → deep → ...)

### 3.5 §Process step 8 改写(L48)

```markdown
8. **When delegating to sub-agents, follow the Sisyphus Dispatch Protocol above** — always specify the COMPLETE `load_skills` set from the Category × Skill Matrix main table (Hard Rule). If the dispatch-gate plugin warns "matrix recommends X" while you have an existing list, evaluate whether X is missing and add it.
```

### 3.6 §Skill Priority Discipline 删除

原 §Skill Priority Discipline 整个段落(若已加)删除 —— 折入 §Process step 8,杀双路由表漂移风险(Lane 2 F4)。

### 3.7 L110 方向错误修复

```diff
- ... provide reviewer discipline anchoring (per the Sisyphus Dispatch Protocol below).
+ ... provide reviewer discipline anchoring (per the Sisyphus Dispatch Protocol above).
```

(协议在 L50-81,**在** Security 5-lane 表 L98-112 之上)

### 3.8 §Plugin layer 段首补一句

在 §Plugin layer (L199-204) 段首加:

```markdown
this SKILL.md is injected into firstUser.parts each session — see meisijiya-skills.js:113-132.
```

---

## 4. Plugin 设计(`meisijiya-dispatch-gate.js`)

### 4.1 文件位置

- 源:`/home/ubuntu/workSpace/Skills/.opencode/plugins/meisijiya-dispatch-gate.js`
- 安装:`cp .opencode/plugins/meisijiya-dispatch-gate.js ~/.config/opencode/plugins/`
- 测试:`/home/ubuntu/workSpace/Skills/tests/plugins/meisijiya-dispatch-gate.test.js`(`node --test`)

### 4.2 完整实现

```javascript
#!/usr/bin/env node
/**
 * meisijiya-dispatch-gate — OpenCode plugin
 *
 * Hard-layer fallback for `task(load_skills=[...])` dispatch. When the controller
 * (Sisyphus) forgets or omits the COMPLETE load_skills list per the Category × Skill
 * Matrix main table, this plugin:
 *
 *   1. Empty/undefined load_skills → inject matrix recommendation (filtered by installed)
 *   2. Non-empty load_skills → respect LLM (do NOT merge); console.warn with matrix hint
 *
 * Sync with: ~/.agents/skills/using-meisijiya-skills/SKILL.md §Category × Skill Matrix
 * (SOT — this file mirrors the matrix). When the matrix changes, update RECOMMENDED.
 */
import { existsSync } from 'node:fs'
import { join } from 'node:path'
import { homedir } from 'node:os'

const SKILLS_DIR = join(homedir(), '.agents', 'skills')

// SOT = SKILL.md §Category × Skill Matrix main table.
// MVP: visual-engineering + deep only. Expand when eval covers, matrix updated, unit test added.
const RECOMMENDED = Object.freeze({
  'visual-engineering': ['meisijiya-frontend-taste'],
  'deep':               ['incremental-implementation'],
})

function installed(name) {
  return existsSync(join(SKILLS_DIR, name, 'SKILL.md'))
}

/**
 * Pure: returns the recommended load_skills set (filtered by installed) for given args.
 * Returns null if no recommendation applies (plugin should no-op).
 * Exported for `node --test` unit testing (see tests/plugins/meisijiya-dispatch-gate.test.js).
 */
export function resolveDispatchLoadSkills(args) {
  const routing = (typeof args?.category === 'string' && args.category)
    || (typeof args?.subagent_type === 'string' && args.subagent_type)
  if (!routing) return null
  const rec = RECOMMENDED[routing]
  if (!rec) return null
  const filtered = rec.filter(installed)
  return filtered.length > 0 ? filtered : null
}

export const MeisijiyaDispatchGate = async () => ({
  'tool.execute.before': async (input, output) => {
    try {
      if (String(input?.tool ?? '').toLowerCase() !== 'task') return
      const args = output?.args
      if (!args || typeof args !== 'object') return

      const recommended = resolveDispatchLoadSkills(args)
      const existing = Array.isArray(args.load_skills) ? args.load_skills : null

      if (existing && existing.length > 0) {
        // Respect LLM: do NOT merge. console.warn so LLM can fix on next dispatch.
        if (recommended && recommended.length > 0) {
          console.warn(
            '[meisijiya-dispatch-gate] load_skills already set; matrix recommends',
            JSON.stringify(recommended),
          )
        }
        return
      }

      if (recommended && recommended.length > 0) {
        // Inject (user decision: only when fully empty/undefined).
        // cap(0, 4) — accommodates Security 5-lane 4-skill sets without silent drop.
        args.load_skills = recommended.slice(0, 4)
        console.warn('[meisijiya-dispatch-gate] injected', JSON.stringify(recommended))
      }
      // No recommendation / no axis → no-op (natural fallback)
    } catch (_e) {
      // Per omo-state-index.js discipline: never throw out of a tool hook.
    }
  },
})

// Test surface (per omo-state-index.js:348-357 pattern)
module.exports = { resolveDispatchLoadSkills, RECOMMENDED, installed }
```

### 4.3 行为表

| LLM 传的 `args.load_skills` | Plugin 动作 | 副作用 |
|---|---|---|
| 字段缺失(`undefined`) | 查 matrix → 注入(若该 category 在 matrix 且 installed) | `console.warn` 注入日志 |
| `null` | 不干预 → omo `prepareDelegateTaskArgs` 抛错 | (omo 行为不变) |
| `[]` | 查 matrix → 注入(同 undefined) | `console.warn` 注入日志 |
| `["foo"]`(任意非空) | **不动 args** + console.warn 提示 matrix 推荐 | `console.warn` 提示日志 |
| 非数组 / 字符串 / 其他 | 等价于"未传"(经 plugin 不动) → omo `prepareDelegateTaskArgs` 归一化处理 | (omo 行为不变) |

### 4.4 关键约束(已 5-lane 复审验证)

1. **mutate 字段,不 reassign 整个对象**(SDK 闭包 args 引用不变)
2. **永不 throw 出 hook**(整体 try/catch)
3. **只读 args,不动 category / subagent_type / command / prompt**(让 omo 自己处理这些)
4. **cap ≤ 4**(兼容 Security 5-lane 4-skill 集;Red Flag 是 >3,但 4 是已知 security lane 集,允许豁免)

### 4.5 Plugin 与 omo 的交互顺序(已 omo source 验证)

```
LLM 输出 task() call → JSON 校验(AI SDK 在 execute 前做,zod decode)
  ↓
OpenCode SDK: tool.execute.before hook chain(串行)
  ├─ plugin #1(我们)
  ├─ plugin #2(omo 自己的 tool.execute.before,mutate subagent_type via replaceToolArgs)
  └─ ... 后续 hooks
  ↓
delegateTask.execute(args, ctx)
  ├─ prepareDelegateTaskArgs 归一化(undefined→[], null→throw, filter string)
  ├─ resolveSkillContent(load_skills, ...)
  │   ├─ skills.length === 0 → short-circuit
  │   └─ else: 查 skill store,过滤 notFound,filter agent-restricted
  └─ buildSystemContent → client.session.prompt({ body: { system: input.systemContent, ... } })
```

我们 plugin 在 omo 之前或之后跑都不冲突:omo 只 mutate `subagent_type`(不影响 `load_skills`)。我们只 mutate `load_skills`(不影响 `subagent_type`)。

---

## 5. 跨文件同步清单

| 文件 | 改动 | 来源 |
|---|---|---|
| `~/.agents/skills/using-meisijiya-skills/SKILL.md` | 整 spec §3 全部改动 | runtime 用户级,plugin 读这里 |
| `skills/core/using-meisijiya-skills/SKILL.md` | 同上 | repo 源,需与用户级同步 |
| `README.md` L213/215/217 | "3 个" → "4 个" plugin | 计数 |
| `README.md` L221-223 | 加 `meisijiya-dispatch-gate.js` 行(`cp` install)+ `####` 子段 | 表格 |
| `docs/omo-agent-skill-config.md` L33/164/217 | "Common Dispatch Patterns" → "Common Dispatch Scenarios" | 命名同步 |
| `docs/omo-agent-skill-config.md` L5 TL;DR | 3 → 4 mechanisms(dispatch-gate 是新第 4) | 机制枚举 |
| `bin/meisijiya plugin verify` | 加 `.js` 通道:`node --check` 零依赖 | 语法门禁 |
| `evals/cases/using-meisijiya-skills.json` | +2 behavioral(§Hard Rule 完整性 + regression) | 行为覆盖 |
| `.opencode/plugins/meisijiya-dispatch-gate.js` | 新建 §4.2 完整实现 | plugin 源 |
| `tests/plugins/meisijiya-dispatch-gate.test.js` | 新建 `node --test` 4 类用例 | 单测 |

**同步义务**:仓库**无 SKILL.md 双拷贝自动同步机制**(scripts/ 无 cp script;inject-agents-md.sh 只注入 catalog 块,不动 dispatcher body)。本次 spec 要求双拷贝**在同一次 commit 中手动同改**(可在 commit message 里写明 `cp skills/core/using-meisijiya-skills/SKILL.md ~/.agents/skills/using-meisijiya-skills/SKILL.md`)。

---

## 6. Acceptance criteria(MVP 验收)

```
SKILL.md(双拷贝):
  [ ] §Hard Rule 出现在 §Sisyphus Dispatch Protocol 段首
  [ ] §Hard Rule 含 "never empty/partial for matrix-mapped" + 3 例外 + "never exceed 3"
  [ ] EXTREMELY_IMPORTANT 块加 1 行 dispatch 提示
  [ ] §Category × Skill Matrix 加 legend(3 个记号定义)
  [ ] visual-engineering 行重构为 Main + 2 个 modifier
  [ ] deep 行重构为 Main + 1 个 modifier
  [ ] §Common Dispatch Patterns → §Common Dispatch Scenarios + 过渡标记 + cross-refs
  [ ] §Process step 8 改写为引用 Hard Rule + matrix + dispatch-gate warn
  [ ] L110 "below" → "above"
  [ ] §Plugin layer 段首补注入机制说明
  [ ] 双拷贝同步(repo + ~/.agents/skills/)
  [ ] validate-skills.sh 通过

Plugin (meisijiya-dispatch-gate.js):
  [ ] 顶部注释声明 SOT 同步到 SKILL.md matrix
  [ ] installed() 过滤(防 notFound 硬失败)
  [ ] MVP RECOMMENDED 只有 visual-engineering + deep(冻结)
  [ ] resolveDispatchLoadSkills 纯函数导出(测试表面)
  [ ] hook 体整体 try/catch(永不 throw)
  [ ] console.warn 注入日志 + warn-only 日志(已有 list 时)
  [ ] cap ≤ 4(兼容 security 5-lane 集)
  [ ] mutate 字段,不复 reassign output.args
  [ ] node --check 通过
  [ ] node --test 通过(4 类用例 + 1 引用恒等断言)

跨文件:
  [ ] README.md L213/215/217 3→4
  [ ] README.md L221-223 表格 +1 行 + 新子段
  [ ] docs/omo-agent-skill-config.md L33/164/217 改名
  [ ] docs/omo-agent-skill-config.md L5 TL;DR 3→4 mechanisms
  [ ] bin/meisijiya plugin verify 扩 .js 通道

Eval:
  [ ] using-meisijiya-skills.json +2 behavioral
  [ ] 3+3+1 结构检查通过
  [ ] validate-skills.sh 全绿

E2E smoke:
  [ ] 真实 OpenCode session: task(category='visual-engineering', load_skills=[]) → sub-agent 收到 meisijiya-frontend-taste body
  [ ] 真实 OpenCode session: task(category='deep', load_skills=[]) → sub-agent 收到 incremental-implementation body
  [ ] 真实 OpenCode session: task(category='visual-engineering', load_skills=['meisijiya-frontend-taste']) → console.warn 显示 matrix hint
  [ ] 真实 OpenCode session: task(category='artistry', load_skills=[]) → no-op(artistry 不在 MVP RECOMMENDED)
```

---

## 7. Command list(实现期 4 原子 commit)

```bash
# 1. SKILL.md 双拷贝同步(只 spec §3 改动)
$EDITOR skills/core/using-meisijiya-skills/SKILL.md
$EDITOR ~/.agents/skills/using-meisijiya-skills/SKILL.md
# diff 验证一致
diff skills/core/using-meisijiya-skills/SKILL.md ~/.agents/skills/using-meisijiya-skills/SKILL.md
bash scripts/validate-skills.sh   # 期望:44+ OK(无新增 skill)
git add -u && git commit -m "docs(skill): restructure using-meisijiya-skills for load_skills completeness (Hard Rule + matrix Main/Modifier + Scenarios rename + Process step 8 rewrite)"

# 2. Plugin + 单测 + bin/meisijiya verify 扩
$EDITOR .opencode/plugins/meisijiya-dispatch-gate.js
$EDITOR tests/plugins/meisijiya-dispatch-gate.test.js
$EDITOR bin/meisijiya   # 扩 .js 通道
# 自检
node --check .opencode/plugins/meisijiya-dispatch-gate.js
node --test tests/plugins/meisijiya-dispatch-gate.test.js
./bin/meisijiya plugin verify   # 期望:4 OK
git add -A && git commit -m "feat(plugin): meisijiya-dispatch-gate hard-layer fallback for load_skills completeness (visual-engineering + deep MVP)"

# 3. Eval case +2 behavioral
$EDITOR evals/cases/using-meisijiya-skills.json
bash scripts/validate-skills.sh   # 期望:3+3+1 结构通过
git add -u && git commit -m "test(skill): add 2 behavioral evals for using-meisijiya-skills Hard Rule (completeness + regression)"

# 4. 跨文件同步(README + docs)
$EDITOR README.md
$EDITOR docs/omo-agent-skill-config.md
bash scripts/validate-skills.sh
bash scripts/check-marketplace.sh
bash scripts/check-doc-drift.sh   # 期望:无 drift
git add -u && git commit -m "docs(repo): README plugin table 3→4 + dispatch-gate row; docs/omo-agent-skill-config.md rename + TL;DR 3→4 mechanisms"
```

---

## 8. Test strategy

### 8.1 单元测试(`node --test`,零依赖)

**文件**:`tests/plugins/meisijiya-dispatch-gate.test.js`

**4 类用例**(每类至少 2 个 case):

1. **Positive**: `args.load_skills=[]` + `category='visual-engineering'` → `args.load_skills` mutate 为 `['meisijiya-frontend-taste']`(已 installed)
2. **Negative**: `args.load_skills=['foo']` + `category='visual-engineering'` → `args.load_skills` 不变(无 mutation);但 console.warn 被调(用 stub 验证)
3. **Defensive**: `output.args=null` / `output.args='string'` / `input.tool='write'` → hook 不抛、不 mutate
4. **Edge**: `category='artistry'`(不在 MVP RECOMMENDED) → no-op;`category=undefined` + `subagent_type=undefined` → no-op;未 installed 的 skill name → 过滤后空 → no-op

**1 个引用恒等断言**(防 reassign 整对象 bug 类回归):
- 调 hook 时传入 `{ args: original }`
- 断言 `output.args === original`(reference 不变)
- 断言 `original.load_skills` 被 mutate

### 8.2 Eval behavioral(`using-meisijiya-skills.json`)

加 2 个 behavioral_evals:

```json
{
  "scenario": "Sisyphus dispatches task(category='visual-engineering', load_skills=[]) for a greenfield landing page",
  "expected_behavior": [
    "Agent consults Category × Skill Matrix main table before dispatching (Hard Rule)",
    "Agent passes COMPLETE load_skills, never [] for matrix-mapped categories: [\"meisijiya-frontend-taste\"]",
    "Agent does NOT rely on dispatch-gate plugin to backfill — the gate is fallback, not primary discipline"
  ]
},
{
  "scenario": "Sisyphus dispatches task(category='deep', load_skills=['test-driven-development']) to an executor",
  "expected_behavior": [
    "Agent passes existing load_skills list through unchanged (regression: plugin never modifies non-empty)",
    "Agent does not merge, dedupe, or reorder the list"
  ]
}
```

### 8.3 静态门禁

- `node --check` plugin(扩 `bin/meisijiya plugin verify` 覆盖 `.js`)
- `validate-skills.sh` SKILL.md 结构 + eval 3+3+1
- `check-marketplace.sh` marketplace 同步
- `check-doc-drift.sh` README/AGENTS.md/extra-README 计数一致

### 8.4 E2E smoke(manual)

真实 OpenCode session,跑 4 个场景(per §6 E2E smoke checklist)。

---

## 9. Risks & mitigations

| Risk | 概率 | 影响 | Mitigation |
|---|---|---|---|
| Plugin hook throw → 整个 task() 派发失败(SDK 无 try/catch 包装) | 中 | **高**(派发静默崩) | (a) hook 体整体 try/catch §4.2 (b) node --check 语法门禁 §8.3 (c) 单测覆盖 4 类异常 §8.1 (d) console.warn 观测 §4.2 |
| Plugin 注入未 installed skill name → omo `resolveSkillContent` 返回 `notFound` error → task 失败 | 中 | **高** | installed() 过滤(防 notFound 硬失败) §4.2 |
| SKILL.md 矩阵与 plugin RECOMMENDED 表双 SOT 漂移 | 高 | 中 | plugin 头部注释声明 SOT §4.2;MVP 仅 2 行,易同步 |
| cap ≤ 4 与 Red Flag `>3 skills` 冲突 | 低 | 低 | 注释说明豁免(security 5-lane 4-skill 集);MVP 注入 ≤ 1,实际不触发 |
| 双 SKILL.md 拷贝同步漂移(repo 改用户级忘改) | 高 | 中 | 同 commit 双改 + commit message 含 `cp` 命令 |
| LLM 不读 §Hard Rule(80-90% 命中率) | 中 | 中 | §Hard Rule 移到段首 + EXTREMELY_IMPORTANT 块加 1 行(最高可见性) |
| Plugin "保持 + warning" 模式无法闭环"部分空"问题 | 中 | 低 | 决策:warn 提醒让 LLM 下次补;MVP 验证 80-90% 是否够 |
| Plugin 无 opt-out,omo 内部派发也被注入 | 低 | 低 | 无 sentinel 可用(null 抛错);文档化即可 |
| README/docs 跨文件同步漏掉 | 中 | 中 | commit 4 独立原子 commit;validate-skills.sh + check-doc-drift.sh 门禁 |
| `ultrabrain` / `unspecified-high` 行歧义 → 注入错误技能 | 中 | 中 | MVP 排除这两行;后续扩展需消歧 |
| Bin/meisijiya plugin verify 跳过 .js 修复后,误报 .ts 漏改 | 低 | 低 | node --check 仅做语法,不替代类型检查;注释清晰 |

---

## 10. 决策记录

| # | 决策 | 替代方案 | 选择理由 |
|---|---|---|---|
| D1 | 双层保险(dispatcher 训练 + plugin 兜底) | 纯 dispatcher / 纯 plugin | 取"训练 + 兜底 + 显式 warn"中道,不破坏 LLM 自由度 |
| D2 | Plugin "保持 + warning" 模式(已传 list 时不动 + console.warn) | merge / 不动且不提醒 | LLM 不被"我说 a 被塞 b"困惑;warn 让 LLM 下次主动补 |
| D3 | MVP 只覆盖 visual-engineering + deep | 8 categories 全上 | ultrabrain / unspecified-high 有歧义,注入错误比不注入更糟 |
| D4 | §Hard Rule 移到段首 + EXTREMELY_IMPORTANT 块加 1 行 | 仅段尾加 | LLM attention 在段首 / 文档开头最强(per meisijiya-skills.js:113-132 注入机制) |
| D5 | "协同集" → "skill set" / "recommended set" | 保留中文 | SKILL.md 正文全英文,中文术语破坏一致性 |
| D6 | §Skill Priority Discipline 删除,折入 §Process step 8 | 保留新段 | 60% 重复,杀双路由表漂移(Lane 2 F4) |
| D7 | Plugin 命名 `meisijiya-dispatch-gate.js` | 其他命名 | 匹配现有 `meisijiya-*.js` 命名风格 |
| D8 | cap ≤ 4(豁免 Red Flag `>3`) | cap ≤ 3 | Security 5-lane 集是 4-skill,3-cap 会静默截断 |
| D9 | installed() 过滤必须 | 不过滤 | notFound skills 让 omo 硬失败 task()(Lane 3 F1 关键发现) |
| D10 | bin/meisijiya plugin verify 扩 .js 通道(`node --check`) | 不扩 | .js plugin 零门禁(Lane 5 F3 关键发现) |
| D11 | Eval case +2 behavioral(必) | 不加 | dispatcher 行为变更无 eval 覆盖(Lane 5 F1 关键发现) |
| D12 | Plugin 纯函数化 + `node --test` 单测(应) | 不加 | plugin 行为无法进 eval JSON;必须单测 |
| D13 | `Common Dispatch Patterns` 改名 `Scenarios` + 过渡标记 | 保留原名 | 跟"场景展开"的语义更贴;过渡标记减迁移成本 |
| D14 | `docs/omo-agent-skill-config.md` L33/164/217 同步改名 | 不改 | 命名漂移会断 doc 引用(Lane 4 F7) |
| D15 | README 插件表 3→4 + 新表行(必) | 不改 | 计数与文档不一致(Lane 4 F3) |

---

## 11. 引用 + 关联文件

**Plugin / SKILL.md 引用**:
- `~/.config/opencode/plugins/rtk.ts` —— mutate args 模板(L19-37)
- `~/.config/opencode/plugins/meisijiya-review-router.js` —— `installed()` 检查模式(L106-112)
- `~/.config/opencode/plugins/omo-state-index.js` —— 测试表面导出模式(L33-37, 348-357) + 防御性 try/catch 模式
- `~/.agents/skills/using-meisijiya-skills/SKILL.md` —— dispatcher 主文件,plugin 读的 SOT

**omo 源码引用**(调研已验证):
- `packages/omo-opencode/src/tools/delegate-task/tools.ts:57-72` —— `load_skills` schema
- `packages/omo-opencode/src/tools/delegate-task/tools.ts:73-86` —— `createDelegateTask` 工厂
- `packages/omo-opencode/src/plugin/tool-registry-core-tools.ts:94` —— `tools.task = delegateTask`
- `packages/omo-opencode/src/tools/delegate-task/tool-argument-preparation.ts:50-77` —— `load_skills` 归一化
- `packages/omo-opencode/src/tools/delegate-task/skill-resolver.ts:80-85` —— 空数组 short-circuit
- `packages/omo-opencode/src/tools/delegate-task/skill-resolver.ts:116, 135-149` —— notFound 错误返回
- `packages/omo-opencode/src/tools/delegate-task/sync-prompt-sender.ts:82-86` —— 最终注入到 sub-agent
- `packages/omo-opencode/src/plugin/tool-execute-before.ts:142-149` —— omo 自己的 tool.execute.before

**OpenCode SDK 引用**(调研已验证):
- `packages/opencode/src/plugin/index.ts:282-295` —— `trigger` 顺序串行
- `packages/opencode/src/session/tools.ts:99-133` —— `execute` 包装:output = `{ args }` 同一引用
- `packages/plugin/src/index.ts:266-269` —— `tool.execute.before` 签名

**项目内引用**:
- `README.md` L213-258 —— OpenCode Plugins 表(需 3→4)
- `docs/omo-agent-skill-config.md` L5 TL;DR + L33/164/217 引用 —— 改名同步
- `bin/meisijiya` L39 —— plugin verify 当前只覆盖 `.ts`(需扩 `.js`)
- `evals/cases/using-meisijiya-skills.json` —— 当前 5+3+4,需 +2 behavioral
- `scripts/validate-skills.sh` —— 结构 + 3+3+1 校验
- `scripts/check-marketplace.sh` —— marketplace 同步校验(无变化)
- `scripts/check-doc-drift.sh` —— 文档计数一致性(无变化)

**调研 brief**:
- `/tmp/opencode/dispatch-gate-design-brief.md` —— 5-lane reviewer 用的统一 brief

---

**Spec 状态**:DRAFT,待 user 批准。批准后按 §7 Command list 4 原子 commit 实施。