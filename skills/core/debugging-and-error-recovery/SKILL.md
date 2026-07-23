---
name: debugging-and-error-recovery
description: "Five-step triage — reproduce / localize / reduce / fix / guard. Under omo, escalate to oracle agent when stuck at Step 2 (Localize) and use lsp MCP for code intelligence. Use when tests fail, builds break, or behavior is unexpected. Anti-pattern: guessing root cause and shotgun-changing files."
allowed-tools: "Read Edit Bash Glob Grep"
---

# debugging-and-error-recovery

## Overview

五步排错 —— reproduce / localize / reduce / fix / guard。**禁止猜根因,改改看**。

猜是修的最常见反模式:你改了 3 处,test 通过了,但**不知道为什么通过** —— 下次同症状复发,你再猜 3 处。猜的 fix 不是 fix,是赌博。

五步法的核心是**reproduce first**:没 reproduce 命令的 fix,reviewer 无法验证,你也无法在 3 个月后复现。

## When to Use

**Use when:**
- 测试失败(包括之前通过的测试)
- 构建失败(`make` / `npm run build` / `cargo build` 退出非 0)
- 运行时异常 / panic / 段错误
- 行为异常(测试通过但运行错)
- 用户报"X 不工作了"

**NOT for:**(场景描述 —— 具体用哪个 skill 由 description 匹配决定,不硬指)
- 设计阶段的纯架构选型问题(未触发 bug)
- 已知 trivial typo
- 文档错误
- 性能问题(非 bug 范畴)

## Process

### 1. Reproduce

写一个**能稳定复现的最小命令**(一行能跑):

```bash
# 例子:某个测试在 CI 上失败,本地通过
npm test -- --grep "specific failing test" 2>&1 | tail -20
```

Run it. **Confirm it reproduces** before doing anything else. If you can't reproduce, stop and gather more info — don't guess.

Document the reproduce command in `.omo/notepads/<plan>/problems.md` (append-only via `notepad-write-guard` hook):

```
[debug] reproduce: <command> → <output / exit code>
```

### 2. Localize

二分法找根因:

- **Binary search the timeline:** `git bisect` to find which commit introduced the bug
- **Binary search the codebase:** comment out half the code, see if it still fails
- **Add logging:** at module / function / branch boundaries, narrow down
- **omo LSP MCP** (when running under omo): `mcp__lsp__goto_definition` / `find_references` to trace code flow without grepping

Goal: identify **specific function + line** where behavior diverges from expectation.

Document:

```
[debug] localized: <file>:<line> | <expected> != <actual>
```

### 2.5 Escalate to oracle (omo, optional but recommended for hard bugs)

If after Step 2 you're still stuck — especially for architecture-level bugs, multi-service interactions, or "why does this happen in production but not in tests" — escalate to omo's oracle agent:

```
Ask Sisyphus: "Stuck debugging <symptom>. Tried: <your attempts>.
Hypotheses: <list>. Please consult oracle for fresh-context reasoning."
```

Oracle is **read-only** — won't change code, but provides a fresh-context reasoning pass. Use after your own 3+ failed attempts, not as the first move (you should still localize first).

### 3. Reduce

Minimize the failing case:
- Strip input data to smallest failing subset
- Remove unrelated code paths
- Isolate the failing component

Goal: a **5-10 line reproducer** that anyone can run and see the bug.

### 4. Fix

Fix the **root cause**, not the symptom:

- ❌ Adding `try/catch` around the failing line
- ❌ Adding `if (x) return null` to avoid the path
- ❌ Casting to `any` to silence type errors
- ✅ Fixing the actual logic that produces wrong values
- ✅ Adding input validation at the trust boundary
- ✅ Correcting the type signature so wrong usage fails at compile time

After fix, run the reproduce command. **Confirm it now passes.**

### 5. Guard

Add a **regression test** that fails without the fix:

- The test must be a real behavior test (not a type/mocking test)
- The test must have failed **before** your fix
- The test must pass **after** your fix

Commit:

```
fix: <one-line summary>

Root cause: <what was actually wrong>
Test: <test name that guards against regression>
```

## Common Rationalizations

| Excuse | Reality |
|---|---|
| "我猜是 X,改改看" | 猜不是修。没 reproduce 的 fix 是赌博,3 个月内会咬回来。 |
| "时间紧,先 fix 再说" | 没找到根因的 fix 会回来 —— 通常以最糟的方式(生产事故)。 |
| "reproduce 太麻烦" | 没 reproduce 的 fix,reviewer 无法验证,你无法 3 个月后回查。 |
| "二分法太慢" | 二分法 5 分钟,猜 + 改 + 测循环 30 分钟。二分法更快。 |
| "这个 bug 是 flaky,不用修" | Flaky 必有原因。没找到原因 = 5 步没走完。 |
| "加个 try/catch 就好了" | 那叫吞错,不叫 fix。Bug 还在,只是被藏起来。 |

## Red Flags

- 不写复现命令就开始改
- 一次改多个地方(无法定位哪个 fix 起作用)
- 跳过 regression test(下次同类 bug 再现)
- 修完不留 root cause 笔记
- 用 `// FIXME` / `// TODO` 标记代替 fix
- 用 `as any` / `@ts-ignore` 压制类型错误
- 改完没跑 reproduce 命令验证

## Verification

Before declaring debug complete, confirm:
- [ ] Reproduce command written down and runnable by anyone
- [ ] Reproduce command **failed** before fix
- [ ] Reproduce command **passes** after fix
- [ ] Localized to specific file:line
- [ ] Reduced to minimal failing case (≤ 10 lines)
- [ ] Root cause explained (not just "X was wrong")
- [ ] Regression test added to test suite
- [ ] Regression test fails without the fix
- [ ] Other tests still pass (no regression introduced)
- [ ] `.omo/notepads/<plan-name>/problems.md` has the `[debug]` log entries

## omo Integration

Use an OMO task (`task_create` / `task_update` for the bug as a task DAG entry) for reproduce/localize/reduce/fix/guard, hand complex localization to the `oracle` agent (read-only high-IQ, gpt-5.6-sol xhigh — escalate to it after 2+ failed fix attempts, not before), and record evidence in `.omo/notepads/<plan-name>/problems.md` (append-only via `notepad-write-guard` hook) before `review-work`.

**State-survival across compaction**: debugging is the most likely workflow to hit `experimental.session.compacting` mid-investigation — long file reads + multiple reproduce attempts easily exceed 1M-token context windows. OMO's `compaction-context-injector` hook handles this in 3 stages:

1. **Capture** (pre-compaction): saves `{agent, model, tools}` checkpoint per session
2. **Inject** (during compaction): pushes an 8-section `COMPACTION_CONTEXT_PROMPT` into the surviving context — sections include "Active Working Context (For Seamless Continuation)", "Agent Verification State (Critical for Reviewers)", and "Delegated Agent Sessions" with the explicit directive **"RESUME, DON'T RESTART"**
3. **Restore** (post-compaction, on `session.compacted` event): tail monitor (threshold 5 consecutive no-text events + 60s cooldown) detects stuck sessions and re-dispatches the agent's prior config

**Implication for debugging**: if you launched an `oracle` or `librarian` subagent for localization and compaction fires while it's running, the resuming Sisyphus will see the in-flight task ID and the "RESUME, DON'T RESTART" directive — call `background_output(task_id="bg_...")` to collect its result, do not re-spawn it. Same applies if compaction hits between reproduce/localize/reduce/fix/guard — the surviving context already carries the reproduce command + localized file:line; resume from Step 4 (fix), don't restart at Step 1.
## Errors Encountered
| Error | Attempt | Resolution |
|-------|---------|------------|
| Test "create-user" fails on empty name | 1 | Root cause: missing input validation in UserService.create() | Test: tests/test_user_service.py::test_create_user_empty_name | Fix: commit abc123 |
```

This builds debugging knowledge across the project — recurring errors are visible patterns, not surprises.