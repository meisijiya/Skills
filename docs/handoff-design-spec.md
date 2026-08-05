# meisijiya-handoff — Design Spec (DRAFT,待 user 批准)

> **状态**:Design 草案。skill 本体尚未写。批准后 → 进 RED-GREEN-REFACTOR(`writing-skills` 路径)。
>
> **依赖**:本文档引用 [`phase-vocabulary.md`](phase-vocabulary.md) 的 phase 编号;handoff doc 的 `from_phase` / `to_phase` 字段必须与该表一致。
>
> **参考原型**:mattpocock/skills 的 `productivity/handoff`(仅 9 行 body,过薄)→ 改良路径见 §1。

---

## 1. 为什么需要这个 skill

### 1.1 gap(本 repo 当前状态)

| 机制 | 范围 | 跨 session? |
|---|---|---|
| `compaction-context-injector`(OMO `experimental.session.compacting`) | 同 session compaction 恢复 | ❌ |
| `.opencode/plugins/meisijiya-skills.js` firstUser.parts | 同 session 启动 + compaction 后 idempotent 注入 | ❌ |
| `wayfinder` | 多 session ticket DAG | ✅(但 scope = decision mapping,不是 session handoff) |
| `.omo/notepads/<plan>/{learnings,decisions,issues,problems}.md` | 跨 session 持久化决策 | ⚪ 隐式,无 skill 形式化 |
| `/handoff` builtin command | OpenCode 自带 | ⚪ 非 meisijiya skill |
| **`meisijiya-handoff`** | ❌ 不存在 | — |

**结论**:跨 session **没有显式的 handoff 协议**。用户在 Sisyphus-driven session 结束时,如果不靠人脑记忆 / notepad 自我提示 / wayfinder 重开,**新 session 不知道上一 session 走到了 Phase 几**。

### 1.2 mattpocock/skills 的版本为何不能直接用

```markdown
---
name: handoff
description: Compact the current conversation into a handoff document for another agent to pick up.
argument-hint: "What will the next session be used for?"
disable-model-invocation: true
---
Write a handoff document summarising the current conversation so a fresh
agent can continue the work. Save to the temporary directory of the user's
OS - not the current workspace.
Include a "suggested skills" section in the document, which suggests skills
that the agent should invoke.
Do not duplicate content already captured in other artifacts (specs, plans,
ADRs, issues, commits, diffs). Reference them by path or URL instead.
Redact any sensitive information, such as API keys, passwords, or personally
identifiable information.
If the user passed arguments, treat them as a description of what the next
session will focus on and tailor the doc accordingly.
```

5 条指令,5 个原则都正确:

- ✅ "save to temp dir, not workspace" — 但我们的 handoff 是 plan-scoped,**应该进 `.omo/handoff/<slug>-<date>.md`** 而非 `/tmp/`(项目内 git-tracked)
- ✅ "include suggested skills section" — 但没说怎么建议(基于什么信号、字段名是什么、跟 dispatcher 怎么挂钩)
- ✅ "don't duplicate, reference by path/URL" — 但没说 minimum reference 数量(我们要求 ≥ 1 个 plan/ADR/commit/diff)
- ✅ "redact sensitive info" — 我们已有 `Sensitive-Information-Handling` AGENTS.md rule,应**引用**而非重写
- ✅ "tailor by user argument" — 我们应要求 `argument-hint` = "下一个 session 的目标 phase"

**核心缺失**:没有任何 **phase 绑定** 与 **load_skills 契约**。新 session 接到 handoff 后,不知道该从 phase 几 继续、该 load 哪些 skill。

---

## 2. Goals / Non-goals

### 2.1 Goals(本 skill 必须做到)

1. **Phase 协议化**:handoff doc 必须含 `from_phase` / `to_phase` / `next_gate`,与 [`phase-vocabulary.md`](phase-vocabulary.md) 严格对齐
2. **load_skills 契约**:handoff doc 必须含 `load_skills: [...]` 字段(数组),新 session 的 dispatcher 据此自动注入(详见 §5)
3. **落点可控**:写到 `.omo/handoff/<slug>-<from-phase>-<to-phase>-<YYYY-MM-DD>.md`,不进 OS temp dir(项目内 git-tracked)
4. **Reference not duplicate**:handoff doc 内容 **必须** 引用至少 1 个 plan / ADR / commit / diff 路径;不允许把 plan 全文复制进 handoff
5. **Redact**:引用 `Sensitive-Information-Handling` AGENTS.md rule 的 3 类敏感信息(API key / token / secret)必须 redacted
6. **dispatcher 检测**:新 session 启动时,如果检测到未消费的 handoff doc,dispatcher 自动打印 `RESUME FROM PHASE N` + 注入 `load_skills`
7. **与 wayfinder 互补**:`meisijiya-handoff` 是 session-side 协议(一次会话结束 → 一次新会话接续);`wayfinder` 是 plan-side 决策映射(多 session 决策结构化)。两者 slot 不同,可串行(wayfinder close → 写 Phase 0 → handoff to next session)

### 2.2 Non-goals(本 skill **不做** 什么)

- ❌ **不做"自动 handoff"** — 必须用户显式 `/handoff` 或 `disable-model-invocation: true` + 显式调用
- ❌ **不做"自动消费"** — handoff doc 是 *advice*,不是 *command*;新 session 看到后可拒绝(给 reason)
- ❌ **不做 phase 编号定义** — phase 含义由 [`phase-vocabulary.md`](phase-vocabulary.md) 拥有,本 skill 只 reference
- ❌ **不做 cross-machine 同步** — `.omo/handoff/` 是 repo-local,git tracked;不做 IM / cloud sync
- ❌ **不做"继续式对话压缩"** — 同 session compaction 由 OMO `compaction-context-injector` hook 处理;本 skill 是 *cross-session* 协议

---

## 3. frontmatter 设计

```yaml
---
name: meisijiya-handoff
description: "Cross-session handoff protocol — writes a `.omo/handoff/<slug>-<date>.md` document with from_phase / to_phase / load_skills / references / redacted_secrets fields, so a fresh OMO session can resume work without re-reading full conversation. NOT for same-session compaction (use OMO `compaction-context-injector`), NOT for plan-side multi-session decision mapping (use `wayfinder`), NOT for code-only commit/PR continuation."
argument-hint: "下一个 session 要推进到的 phase / 目标 (e.g. 'Phase 3 切片 X → Phase 4 verification')"
allowed-tools: "Read Bash Glob Grep Write"
disable-model-invocation: true
disable-model-invocation-justification: "只在用户显式 `/handoff` 时触发;自动 handoff 会破坏 cross-session 协议(intent = user-driven checkpoint,非 runtime auto-state)。理由与 `loop-me` 同源(`disable-model-invocation-justification` 字段由 `skill-anatomy.md` 定义)。"
---
```

**关键决策**:

- `disable-model-invocation: true` — 与 mattpocock 一致,避免 agent 自作主张写 handoff
- `argument-hint` 显式引导用户填下一个 session 的目标 — 字段 `next_session_goal` 直接取自此处
- `allowed-tools` 只读 + Write — 不允许 Edit / apply_patch,因为 handoff doc 应**整文件写**,不做增量修改

---

## 4. body 设计(handoff doc 字段 schema)

### 4.1 文件路径

```
.omo/handoff/<slug>-<from-phase>-<to-phase>-<YYYY-MM-DD>.md
```

例:`.omo/handoff/auth-revamp-3-4-2026-08-05.md`(auth-revamp 计划从 Phase 3 推进到 Phase 4)。

如果 `<slug>` 不存在或不是 plan-scoped,fallback 到 `.omo/handoff/<slug>-<YYYY-MM-DD>.md` 并把 `from_phase` / `to_phase` 留空(null)。

### 4.2 必填字段

```yaml
---
# 元数据 frontmatter(machine-parseable)
slug: <plan-slug 或 "ad-hoc">
from_phase: <phase 编号或 null>(参考 phase-vocabulary.md)
to_phase: <phase 编号或 null>
written_at: <ISO-8601 timestamp>
written_by: <agent identity>(Sisyphus / Sisyphus-Junior / user)
next_session_goal: <一句话目标,直接取自 argument-hint>
load_skills: <skill 数组>[<skill-name>, ...]  # 新 session 自动注入
references: <artifact 数组,minimum 1>
  - <plan / ADR / commit / diff 路径>
redacted_secrets: <string 数组,redacted log>
consumed: false  # dispatcher 检测用
---
```

### 4.3 body(叙述段,h2 严格按顺序)

1. **## 当前状态**(≤ 200 字):该 phase 已完成什么、还差什么
2. **## Key decisions made**(≤ 300 字):本 session 内做了哪些决策,引用 reference
3. **## Open issues / unresolved questions**(≤ 200 字):未关闭的 issue / problem,引用 notepad 路径
4. **## Next session must do**(≤ 300 字):下一 session 必须做的步骤,带验收标准
5. **## Suggested skills**(≤ 100 字):与 frontmatter 的 `load_skills` 字段一致,人读可读版

每个 h2 末尾必须有 "**References:**" 列出该 section 引用的 artifact 路径(≤ 3 个),不允许内容重复。

### 4.4 字段长度上限

| 字段 | 上限 | 超出处理 |
|---|---|---|
| `next_session_goal` | 200 字 | 强制截断 + `[truncated]` 标记 |
| `## 当前状态` | 200 字 | 同上 |
| `## Key decisions made` | 300 字 | 同上 |
| `## Open issues / unresolved questions` | 200 字 | 同上 |
| `## Next session must do` | 300 字 | 同上 |
| `load_skills` 数组 | 7 项 | 与 dispatcher matrix 同步(`Category × Skill Matrix` 上限 3,留 4 buffer 给 user 自定义) |

**Why 长上限**:harness compaction 通常保留 8-12k token,handoff doc 不应超过该 budget 的 1/4。

---

## 5. dispatcher 集成(新 session 启动时)

### 5.1 检测逻辑

新 session 启动时(`.opencode/plugins/meisijiya-skills.js` firstUser.parts 注入 dispatcher 前),dispatcher 跑以下检查:

```bash
test -d .omo/handoff && \
  find .omo/handoff -name '*.md' -newer .omo/handoff/.last-consumed \
    -exec grep -l '^consumed: false' {} \;
```

如果有 unconsumed handoff:

1. 注入 `<RESUME>` block 到 firstUser.parts:

```
<RESUME FROM PHASE <to_phase>>
- slug: <slug>
- next_session_goal: <next_session_goal>
- load_skills: [<skill-1>, <skill-2>, ...]  (会注入到 sub-agent dispatch)
- references: [<path-1>, <path-2>, ...]  (Read 这些)
- handoff doc: <path-to-handoff-md>

Type `consumed` to acknowledge and proceed, or `consume --reject <reason>` to skip.
```

2. dispatcher 的 `load_skills` 在所有 sub-agent dispatch 时自动 append handoff 的 `load_skills`(per Sisyphus Dispatch Protocol §"Why load_skills matters")

### 5.2 消费确认

- 用户回 `consumed` → dispatcher 把 `consumed: false` 改为 `consumed: true`,追加 `consumed_at` + `consumed_by` 字段,接着 normal flow
- 用户回 `consume --reject <reason>` → 不改字段,加 `rejected_at` + `rejection_reason` 字段,接着 normal flow(用户决定从哪儿接)
- 静默 → dispatcher 不消费,只在每个 turn 的 `<system-reminder>` 提示 `<RESUME>` block 待消费(防失忆)

### 5.3 与现有 dispatcher 的兼容

- 不改 `using-meisijiya-skills/SKILL.md` 的 6-intent 表(已有 label 不需要新增)
- 不改 priority-table.md(只在 reading order 第 1 步加 `Check .omo/handoff/ for unconsumed documents`)
- 不改 process-chains.md(本 skill 是 cross-cutting / context-dependent,与 `loop-me` / `writing-skills` / `source-driven-development` 同 slot)

---

## 6. 与 wayfinder 的关系

| | `wayfinder` | `meisijiya-handoff` |
|---|---|---|
| slot | plan-side 决策映射 | session-side checkpoint |
| 触发 | 用户开 multi-session design | 用户 `/handoff` 结束当前 session |
| 产物 | `.omo/wayfinder/<slug>/map.json` + tickets + sessions | `.omo/handoff/<slug>-<date>.md` |
| 关闭 | wayfinder-close.sh → 生成 Phase 0 | 用户回 `consumed` → 字段更新 |
| 互补 | close 后 Phase 0 可被 handoff 引用 | handoff 可引用未关闭的 wayfinder 路径作为 `references` |

**串联用例**:用户开 `wayfinder` → 多 session 推进 ticket → 某个 session 结束 → 写 `meisijiya-handoff` 引用 `.omo/wayfinder/<slug>/map.json` + 未 resolved tickets → 新 session 启动 → dispatcher 检测 handoff → 注入 `load_skills: ["wayfinder", "brainstorming"]` → 用户 `consumed` → 继续推 tickets。

---

## 7. eval case 设计(RED-GREEN-REFACTOR 第一步)

per `writing-skills/SKILL.md`,必须先有 failing baseline test 才写 skill。

### 7.1 3 positive trigger

```json
[
  {
    "input": "We've finished Phase 3 slice 4 and need to stop here — write a handoff for the next session to do verification",
    "expected_skill": "meisijiya-handoff",
    "reason": "End-of-session checkpoint with explicit next-phase goal matches cross-session handoff protocol"
  },
  {
    "input": "Compaction ate 80% of context — write a handoff doc so I can resume tomorrow",
    "expected_skill": "meisijiya-handoff",
    "reason": "Compaction as handoff trigger; user explicitly invokes"
  },
  {
    "input": "/handoff Phase 4 verification — load skills verification-before-completion + slice-review",
    "expected_skill": "meisijiya-handoff",
    "reason": "Slash-command trigger with explicit phase + load_skills argument"
  }
]
```

### 7.2 3 negative trigger

```json
[
  {
    "input": "Just finished editing one file in this session, continue normally",
    "expected_skill": "(none)",
    "reason": "Same-session, no phase boundary — use normal flow, not handoff"
  },
  {
    "input": "Compress this conversation because context is huge",
    "expected_skill": "(none)",
    "reason": "Same-session compaction, not cross-session — OMO `compaction-context-injector` handles, NOT handoff"
  },
  {
    "input": "Plan a multi-session decision-mapping for the auth redesign",
    "expected_skill": "wayfinder",
    "reason": "Plan-side multi-session decision mapping — `wayfinder` owns this slot, NOT handoff"
  }
]
```

### 7.3 ≥ 1 behavioral scenario

```json
[
  {
    "scenario": "agent is told to write handoff after Phase 3 slice 4 completion, with reference to `.omo/plans/auth-revamp.md` Phase 3 table",
    "expected_behavior": [
      "agent writes `.omo/handoff/auth-revamp-3-4-<date>.md`",
      "frontmatter contains `from_phase: 3` and `to_phase: 4`",
      "load_skills = [\"verification-before-completion\", \"slice-review\"]",
      "references contains `.omo/plans/auth-revamp.md`",
      "no API key / token appears in body even if it was in conversation",
      "no duplication of plan content (only references + ≤ 300 char summaries)"
    ]
  }
]
```

---

## 8. anti-pattern / red flags

| 反模式 | 后果 | 检测方式 |
|---|---|---|
| handoff doc 包含 plan 全文复制 | 文档冗余 + git diff 噪音 | `wc -l` < plan 文件的 50% + `## References` ≥ 1 |
| handoff doc 含明文 API key | secret 泄漏 | `grep -E 'sk-[a-zA-Z0-9]{32,}\|[A-Za-z0-9]{32,}'` 应 0 命中 |
| handoff doc 写进 OS temp dir(`/tmp/`) | 跨 session 不可见 | `find /tmp -name 'handoff*' -newer .omo/.last-check` 应 0 命中 |
| 自动 handoff(无 user 显式触发) | session 边界被人为切碎,`disable-model-invocation` 被绕过 | 看 SKILL.md frontmatter |
| handoff doc 没有 `load_skills` | 新 session 不知道挂什么 skill,需 user 手动补 | 看 frontmatter 必填字段 |
| handoff doc 引用已删 plan 路径 | 链接悬空,新 session 失败 | dispatcher 检测 references 路径存在性 |

---

## 9. 不做的事(再次明确)

- ❌ 不创建 `.opencode/plugins/` 下新 plugin — `meisijiya-skills.js` 已存在,dispatcher 检测逻辑加在其 firstUser.parts 注入阶段即可,**不动 plugin 边界**
- ❌ 不创建新 chain 在 `process-chains.md` — handoff 是 cross-cutting skill,与 `loop-me` / `writing-skills` 同 slot
- ❌ 不创建新 OMO intent label — 已有 6 个 label 不需要新增;handoff 走"用户显式 `/handoff`"路径
- ❌ 不实现 remote sync(.omo/handoff/ 仅 git-tracked)
- ❌ 不实现 auto-archive(7 天前未消费的 handoff 自动归档)— YAGNI,以后真出现再加

---

## 10. 实现 checklist(批准后)

按顺序执行:

1. [ ] 跑 §7 的 eval case baseline(RED)— 用 deep agent 模拟 3+3+1 场景,看 agent **没** skill 时怎么乱写
2. [ ] 写 `skills/extra/meisijiya-handoff/SKILL.md`(GREEN)— frontmatter + body 严格按 §3 + §4
3. [ ] 写 `skills/extra/meisijiya-handoff/evals/cases/meisijiya-handoff.json`(3+3+1)— 跟 §7 一致
4. [ ] 改 `.claude-plugin/marketplace.json`(`meisijiya-domain` group +1)
5. [ ] 改 `skills/extra/README.md`(计数 11→12)+ `AGENTS.md`(同)+ `README.md`(同)
6. [x] 改 `skills/core/using-meisijiya-skills/references/priority-table.md` reading order 第 1 步
7. [x] 改 `skills/core/using-meisijiya-skills/SKILL.md` Process step 1(检测 handoff)
8. [ ] 改 `.opencode/plugins/meisijiya-skills.js` firstUser.parts 注入逻辑(可选,看 RED 是否暴露必要)
9. [ ] 跑 `validate-skills.sh` + `check-marketplace.sh` + `check-doc-drift.sh`(REFACTOR)— 三项全 PASS
10. [ ] 跑 §7 eval case(GREEN)— agent **有** skill 后,行为与 §7.3 expected_behavior 完全一致
11. [ ] 7-lane review(a-architecture / b-omo-compat / c-state / d-eval / e-migration / f-security / g-yagni)— 至少 5 lane APPROVE 才算 close

---

## 11. 一句话总结

> **`meisijiya-handoff` 是 plan-scoped、project-local、user-triggered 的 cross-session checkpoint 协议**;以 `.omo/handoff/<slug>-<from-phase>-<to-phase>-<date>.md` 为产物,含 7 个 frontmatter 必填字段 + 5 个 body h2 + ≥ 1 reference;新 session 的 dispatcher 检测 unconsumed handoff 自动注入 `load_skills`;与 `wayfinder` 互补不替代。批准本 spec 后进入 RED-GREEN-REFACTOR,预计 11 步落地。