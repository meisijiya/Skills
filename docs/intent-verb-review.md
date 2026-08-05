# Intent Verb → Skill 表的诚实审视

> **目的**:对 [`skills/core/using-meisijiya-skills/references/priority-table.md`](../skills/core/using-meisijiya-skills/references/priority-table.md) 的 "Intent Verb → Skill" 6 行表做 per-label 诚实判定,确认 4 个 `(none — OMO handles)` 是否真的 OMO 全消化了。

---

## 1. 现状回顾(priority-table.md 当前内容)

| OMO intent label | User signal | Default meisijiya skill |
|---|---|---|
| `research` | "explain" / "how does" / "what is" | **(none — OMO handles)** |
| `investigation` | "look into" / "check" / "investigate" | **(none — OMO handles)** |
| `implementation` | "implement" / "add" / "build" | (no intent-wide default — use the Priority table after OMO dispatch) |
| `fix` | "broken" / "error" / "wrong" | `debugging-and-error-recovery` |
| `evaluation` | "review" / "is this right?" | **(none — OMO handles)** |
| `open-ended` | "refactor" / "improve" / "clean up" | **(none — assess/clarify, then use the Priority table)** |

**前提**:`intent-diff.md I3` 已记录 "No runtime semantic classifier was found in inspected sources"(omo `v4.19.4` @ commit `b072d279`),6-intent 标签是 **prompt-only 自报**,不是 durable intent state。OMO 先选 agent(`librarian` / `explore` / `oracle` / Sisyphus 系列),再由本表决定是否有 meisijiya skill 介入。

---

## 2. Per-label 判定

### 2.1 `research` → OMO handles ✅ **判定:正确**

OMO 把 `research` 路由到 `librarian` specialist agent。`librarian` 的工具集(`gh repo view` / `gh release list` / `gh api` / `Context7` / Web Search)本身就是 "explain / how does / what is" 的标准答案机制,**无需 meisijiya skill 介入**。

**特例**:`research` skill([`skills/extra/research/SKILL.md`](../skills/extra/research/SKILL.md))不是 `research` label 的默认入口 — 它的 description 明确写 "plan context — refuses plan-less. NOT for casual questions"。它是 **planning-phase high-trust research**,由 `brainstorming` / `wayfinder` / `spec-driven-development` 阶段触发,不是用户直接说 "explain X" 的入口。

**结论**:Intent Verb 表对 `research` 的判定正确。但 Priority table 的 27 行 trigger 表里 "research" 行应注明"只在 plan context 内,且 priority 在 `brainstorming`/`spec-driven-development` 之后"。

---

### 2.2 `investigation` → OMO handles ✅ **判定:正确**

OMO 把 `investigation` 路由到 `explore` specialist agent。`explore` 的工具集(`grep` / `Read` / `Glob` / LSP)是 codebase grep 的标准答案,**无需 meisijiya skill 介入**。

**特例**:`diagnosing-bugs` 不是 `investigation` label 的默认入口 — 它的 description 是 "5-step triage is in progress and cause is non-obvious; when obvious causes are exhausted"。它是 fix 链路上根因非显然时的升级路径,**不应在 `investigation` label 下触发**。

**结论**:Intent Verb 表对 `investigation` 的判定正确。

---

### 2.3 `implementation` → no intent-wide default ⚪ **判定:正确(显式 defer 到 Priority table)**

Priority table 是 *single-trigger 路由器*;6-intent 表是 *intent-label 路由器*。两者正交。`implementation` label 涵盖的触发词 ("implement / add / build") 太宽,无法用 1 个 skill 覆盖 — 必须落到 Priority table 的具体行。

**结论**:Intent Verb 表对 `implementation` 的判定正确,但需要 Priority table 的 27 行覆盖度足够。当前覆盖度足够(我数过:ulw / scope-known / design / fix / review-slice / claim-done / GHA / trust-boundary / release / perf / production-alert / declared-done / new-dep / AI-wrote / tests-green-but-bug / spec-done / unfamiliar-API / write-skill / health-scan / contract-strengthening / record-ADR / teacher / grill-me / landing / PROTO-RESOLVE / wayfinder / research / agent-loop / verify-article = 29 行)。

---

### 2.4 `fix` → `debugging-and-error-recovery` ✅ **判定:正确**

`debugging-and-error-recovery` 的 description 第一句就是 "Five-step triage — reproduce / localize / reduce / fix / guard";正是 fix label 的方法论入口。

**结论**:Intent Verb 表对 `fix` 的判定正确,且 Priority table 的 fix 行也明确到 `diagnosing-bugs` 的升级路径。

---

### 2.5 `evaluation` → OMO handles ⚠️ **判定:gap — 隐藏了 evaluation → 具体 skill 的路由**

OMO 把 `evaluation` 路由到 `oracle`(read-only consultant)。但 **Priority table 里有 4+ 个 evaluation-type trigger 实际由 meisijiya skill 接管**:

| Priority table 行 | 触发词 | 实际 skill |
|---|---|---|
| "Review this slice" / "diff against brief" | evaluation | `slice-review` |
| "About to claim done" / "ready to commit/PR" | evaluation | `verification-before-completion` |
| "Codebase health scan" / weekly architecture review | evaluation | `improve-codebase-architecture` |
| "About to record an irreversible architectural decision" | evaluation | `documentation-and-adrs` |
| "Underspecified request" / "interview me" / "grill me" | evaluation | `brainstorming`(也是 evaluation!) |

**问题**:当前 Intent Verb 表对 `evaluation` 标 `(none — OMO handles)` 隐藏了上述路由;新会话看到 `evaluation` label 会去 OMO `oracle`,**错过 meisijiya skill 的 evaluation 入口**。

**建议**:`evaluation` 改为 `(oracle default; defer to Priority table when trigger matches a specific evaluation skill)`。不要直接把 `brainstorming` 或 `verification-before-completion` 写成 default — 它们各自 trigger 不同。

---

### 2.6 `open-ended` → assess/clarify, then use Priority table ⚠️ **判定:partial — `brainstorming` 应是 first-line**

`open-ended` label 涵盖 "refactor / improve / clean up"。`brainstorming` 的 trigger 之一正是 "I want to do X but I'm not sure how" — **这是 open-ended 的典型问法**。

当前 Intent Verb 表说 "assess/clarify, then use the Priority table",这是 **隐式两步**;但 Priority table 的 "Underspecified request / 'interview me' / 'grill me'" 行已直接映射到 `brainstorming`,**没必要让 agent 走 "assess" 这一步**。

**建议**:`open-ended` 改为 `brainstorming`(默认入口)→ Priority table(具体 trigger 行)。即:

```
| `open-ended` | "refactor" / "improve" / "clean up" | `brainstorming`(scope ambiguous)→ Priority table |
```

---

## 3. 总结判定

| Label | 当前判定 | 诚实判定 | 建议修改 |
|---|---|---|---|
| `research` | (none — OMO handles) | ✅ 正确 | 无 |
| `investigation` | (none — OMO handles) | ✅ 正确 | 无 |
| `implementation` | (no intent-wide default — Priority table) | ✅ 正确 | 无 |
| `fix` | `debugging-and-error-recovery` | ✅ 正确 | 无 |
| `evaluation` | (none — OMO handles) | ⚠️ **gap** | 改为 "(oracle default; defer to Priority table when trigger matches)" |
| `open-ended` | (assess/clarify, then Priority table) | ⚠️ **partial** | 改为 "`brainstorming`(scope ambiguous) → Priority table" |

**2 个 label 需改**,都是文字调整而非机制变更;预计 impact 在 priority-table.md 的 2 行。

---

## 4. 改动建议(给下次 dispatcher review)

### 4.1 priority-table.md:33 (research 行)

**当前**:

```
| `research` | "explain" / "how does" / "what is" | (none — OMO handles) |
```

**建议**:保持不变。但应在 `research` skill 的 description 或 Priority table 的 research 行加注释:`research skill is plan-scoped, not the same as this label`。

### 4.2 priority-table.md:37 (evaluation 行)

**当前**:

```
| `evaluation` | "review" / "is this right?" | (none — OMO handles) |
```

**建议改为**:

```
| `evaluation` | "review" / "is this right?" | (OMO oracle default; defer to Priority table when trigger matches — `brainstorming` for "interview me", `verification-before-completion` for "claim done", `slice-review` for "diff vs brief", `improve-codebase-architecture` for codebase scan, `documentation-and-adrs` for irreversible decision) |
```

### 4.3 priority-table.md:38 (open-ended 行)

**当前**:

```
| `open-ended` | "refactor" / "improve" / "clean up" | (none — assess/clarify, then use the Priority table) |
```

**建议改为**:

```
| `open-ended` | "refactor" / "improve" / "clean up" | `brainstorming` (if scope ambiguous) → Priority table |
```

---

## 5. 与 `meisijiya-handoff` skill 的关联

这份审视本身是一种典型 handoff 场景:reviewer 写了发现 + 建议,等新 session 接收并 commit。`meisijiya-handoff` skill 设计时应当把 "**priority-table 之类的细改动建议**" 也作为 handoff doc 的常见 payload 类型之一(参考 [`docs/phase-vocabulary.md`](phase-vocabulary.md) 的字段设计)。

---

## 6. 一句话总结

> 6 个 label 中 **4 个判定正确**、**2 个有 gap**:`evaluation` 应显式说 "OMO oracle + Priority table 兜底",`open-ended` 应直接 default 到 `brainstorming`。改动在 priority-table.md 的 2 行,**不动机制**;建议走下次 dispatcher 7-lane review 的 `b-omo-compat` lane。