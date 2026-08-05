---
name: meisijiya-handoff
description: "Use when ending a session that the next session needs to resume — writes `.omo/handoff/<slug>-<from>-<to>-<date>.md` with from_phase / to_phase / load_skills / references / redacted_secrets fields so a fresh OMO session picks up without re-reading the full conversation. NOT for same-session compaction (use OMO `compaction-context-injector`), NOT for plan-side multi-session decision mapping (use `wayfinder`), NOT for commit/PR-only continuation."
argument-hint: "下一个 session 要推进到的 phase / 目标 (e.g. 'Phase 3 切片 X → Phase 4 verification')"
allowed-tools: "Read Bash Glob Grep Write"
disable-model-invocation: true
disable-model-invocation-justification: "Cross-session checkpoint 协议:handoff 是 user-driven checkpoint(用户显式决定"我要停了,新 session 接"),agent 不应自动写 handoff 切碎会话边界;与 `loop-me` 同 slot 的 user-only invocation 模式。"
---

# meisijiya-handoff

## Overview

写一个 `.omo/handoff/<slug>-<from-phase>-<to-phase>-<date>.md` 把当前 session 的状态编码成新 session 可消费的 checkpoint。**不是对话压缩**(那是 OMO `compaction-context-injector` hook 的事),**不是 plan 决策**(那是 `wayfinder` 的事),**不是 commit 续接**——是 plan-scoped、project-local、user-triggered 的 cross-session 协议。

`disable-model-invocation: true` 强制 checkpoint 由用户显式决定边界;agent 不自动切碎 session。

## When to Use

**Use when:**

- 当前 session 即将结束(用户说"今天先到这" / compaction 即将 / 上下文已用 80%+)
- 明确要切到新 session 继续(明天 / 下周 / 跨人交接)
- 已有 plan-scoped 工作(`.omo/plans/<slug>.md` 存在)需要跨 session 接续
- 当前 phase 有明确 `from_phase` 和下一 phase 有明确 `to_phase`(参考 [`phase-vocabulary`](../../../docs/phase-vocabulary.md))
- 用户显式 `/handoff` 或 `disable-model-invocation`-compatible 触发词

**NOT for:**

- 同 session context compaction → OMO `compaction-context-injector` hook(`experimental.session.compacting` event)
- 多 session 决策结构化(>1 session 不能装下 scope)→ [`wayfinder`](~/.agents/skills/wayfinder/SKILL.md)
- 单次 commit/PR 续接 → 直接 `git log` + `git diff` 即可,不写 doc
- 短 session(上下文 < 50%,phase 无变化)→ 不要写 handoff,YAGNI
- Plan 不存在的 ad-hoc 工作 → 走 notepad 而非 handoff

## Process

### 0. 校验前置条件

```bash
# plan slug 必须存在
test -f .omo/plans/<slug>.md || echo "WARN: plan missing — handoff is plan-scoped"
```

如果 plan 不存在:`ask user to confirm fallback to .omo/handoff/<slug>-<date>.md with from_phase/to_phase=null`;不静默降级。

### 1. 解析 argument-hint 为结构化字段

`argument-hint` 字符串拆为:

- `next_session_goal`:直接复制 argument-hint 全文
- `from_phase` / `to_phase`:从 argument-hint 提取 phase 编号,无 → null(参考 [`phase-vocabulary`](../../../docs/phase-vocabulary.md))

### 2. 提取本 session 关键 facts

agent 必须读(不复制内容):

- `.omo/plans/<slug>.md` — 提取 current phase + acceptance criteria
- `.omo/notepads/<slug>/{learnings,decisions,issues,problems}.md` — 提取未关闭项
- 本 session 的 tool call history — 提取已 commit 的 commit SHA(如有)
- `.git/log` — 提取最近 5 个 commit SHA

**禁止**复制 plan 全文或 notepad 全文到 handoff doc。

### 3. 检查 secret 泄漏

扫描本 session 出现的所有 string,匹配 `Sensitive-Information-Handling` AGENTS.md rule 的 3 类:

- API key:`sk-[a-zA-Z0-9]{16,}` / `[A-Za-z0-9]{32,}` 类
- Token: Bearer token / GitHub PAT / OAI token
- Password / PII

任何命中 → 加入 `redacted_secrets` 数组(只列字段名,不列值)。

### 4. 计算 handoff doc 文件路径

```
.omo/handoff/<slug>-<from-phase>-<to-phase>-<YYYY-MM-DD>.md
```

`from-phase` 或 `to-phase` 为 null → 省略对应段:`.omo/handoff/<slug>-<from>-<date>.md` 或 `.omo/handoff/<slug>-<date>.md`。

如果文件已存在 → 拒绝并 ask user 是否 overwrite(append-only with timestamp suffix 是默认)。

### 5. 写 handoff doc

frontmatter 必填字段(共 7 个):

```yaml
---
slug: <plan-slug>
from_phase: <phase 编号 or null>
to_phase: <phase 编号 or null>
written_at: <ISO-8601 timestamp>
written_by: <agent identity>
next_session_goal: <一句话,来自 argument-hint>
load_skills: [<skill-name-1>, <skill-name-2>, ...]  # 新 session 自动注入
references:
  - <plan / ADR / commit / diff 路径,minimum 1>
redacted_secrets: [<字段名-1>, <字段名-2>, ...]
consumed: false
---
```

body 5 段严格按顺序,每段末尾必须 "**References:**" 列引用:

1. **## 当前状态**(≤ 200 字)
2. **## Key decisions made**(≤ 300 字)
3. **## Open issues / unresolved questions**(≤ 200 字)
4. **## Next session must do**(≤ 300 字)
5. **## Suggested skills**(≤ 100 字,与 frontmatter `load_skills` 一致)

长度上限详见 [`handoff-design-spec` §4.4](../../../docs/handoff-design-spec.md);超出 → 强制截断 + `[truncated]` 标记。

### 6. 告知 user

输出三行:

```
Wrote: .omo/handoff/<path>.md
New session can resume with: load_skills=[<skill-1>, <skill-2>, ...] from_phase=<from> to_phase=<to>
To consume: open new session, type `consumed` (mark `consumed: true`) or `consume --reject <reason>` (skip)
```

## Common Rationalizations

| 借口 | 反驳 |
|---|---|
| "新 session 不需要 load_skills,会自己发现 skill" | dispatcher 不读 handoff doc 就不会 inject `load_skills`;新 session 从 0 路由等于从 0 试错 |
| "写到 /tmp/ 就行,git 不污染" | handoff 是 plan-scoped artifact,跨 session 必须在仓库内(`.omo/handoff/`);写到 /tmp 等同丢 |
| "让我把整个 plan 复制进 handoff" | handoff doc 严禁 duplicate artifacts(§1);只能 reference;复制会让 doc 体积超 LLM context budget |
| "secret 在本 session 提过,handoff 也带上原值" | 违反 `Sensitive-Information-Handling`;必须 redacted_secrets 字段名 + 不带值 |
| "我没显式 `/handoff`,用户说 'resume tomorrow' 我就写了" | 违反 `disable-model-invocation`;必须等用户显式触发词(`/handoff` / "handoff 一下" / "写个 handoff doc") |
| "from_phase 和 to_phase 我不知道" | 读 `.omo/plans/<slug>.md` Phase 段;无 → null + plan-scoped fallback |

## Red Flags

- handoff doc 含 plan / notepad 全文复制 — `wc -l handoff.md` < `wc -l plan.md` 的 50% 是必要条件
- handoff doc 含明文 API key / token — `grep -E 'sk-[a-zA-Z0-9]{32,}\|[A-Za-z0-9]{32,}|Bearer ' .omo/handoff/*.md` 应 0 命中
- handoff doc 写到 OS temp dir(`/tmp/` / `~/.cache/`)— `find /tmp -name 'handoff*'` 应 0 命中
- `load_skills` 字段为空数组 — 新 session 不知道 load 什么,等于用户必须手动补
- `references` 字段少于 1 项 — 不算 valid handoff,等于 0 evidence
- 同一 slug 24h 内有 2+ 个未消费 handoff doc — 上一 session 没 close 就写,流程混乱

## Verification

- [ ] `.omo/handoff/<path>.md` 文件已写,frontmatter 7 个必填字段全填
- [ ] body 5 段严格按顺序,每段长度 ≤ 上限
- [ ] `references` 数组 ≥ 1 项,`redacted_secrets` 数组(可空)列了字段名不列值
- [ ] `from_phase` / `to_phase` 与 `.omo/plans/<slug>.md` 的实际进度对齐
- [ ] `load_skills` 数组与 Priority table 中下一 phase 的推荐 skill 一致
- [ ] 文件未进 `/tmp/`、未含明文 secret、未复制 plan 全文
- [ ] User 已收到 6 步末尾的 3 行告知

## omo Integration

**Dispatcher 集成**:`skills/core/using-meisijiya-skills/SKILL.md` Process step 0(检测阶段)新增 "Check `.omo/handoff/` for unconsumed documents"。检测到 `consumed: false` 的 doc 时:

1. 注入 `<RESUME FROM PHASE <to_phase>>` block 到 firstUser.parts
2. dispatcher 自动把 `load_skills` 注入 sub-agent dispatch(per Sisyphus Dispatch Protocol)
3. 等用户回 `consumed` 或 `consume --reject <reason>` 才推进

**OMO `compaction-context-injector` hook 不冲突**:compaction 是同 session,本 skill 是跨 session;两者通过不同时机区分(plan-compacting event vs user `/handoff` 触发)。

**与 `wayfinder` 互补**:`wayfinder` 是 plan-side 多 session 决策映射(产物:`.omo/wayfinder/<slug>/`);本 skill 是 session-side checkpoint(产物:`.omo/handoff/<slug>-<date>.md`)。可串联:wayfinder close → 写 Phase 0 → handoff to next session → 新 session consume → 继续推 ticket。

**`disable-model-invocation: true` 政策**:与 `loop-me` 同源(2026-08-01 allowlist 加入)。agent 必须 NOT 自动 invoke 本 skill,只 user `/handoff` 或 explicit trigger。Validator §9 检查:frontmatter 必含 `disable-model-invocation-justification`(紧跟下一行);eval 必须有 ≥1 behavioral scenario 证明 user-only invocation pattern。

**Phase 词汇表**:`from_phase` / `to_phase` 字段必须与 [`docs/phase-vocabulary.md`](../../../docs/phase-vocabulary.md) 一致;Phase 7 已撤出主流程,新 handoff 不应默认含 Phase 7 行。

**Phase 1 ask #7 待 OMO 上游**:`requireUserInvocation: true` 在 OMO runtime 级别强制 `disable-model-invocation` 才能 100% 生效;当前 doc-level 措辞 ~80-90% per project docs(per 2026-07-31 security 5-lane 报告);full L1 enforcement 仍 deferred to OMO upstream。