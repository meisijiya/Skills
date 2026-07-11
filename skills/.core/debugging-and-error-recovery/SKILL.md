---
name: debugging-and-error-recovery
description: "Five-step triage — reproduce / localize / reduce / fix / guard. Use when tests fail, builds break, or behavior is unexpected. Anti-pattern: guessing root cause and shotgun-changing files."
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

**NOT for:**
- 设计阶段的问题(架构选型——用 spec-driven-development)
- 已知 trivial typo
- 文档错误(直接改)
- 性能问题(用 performance-optimization)

## Process

### 1. Reproduce

写一个**能稳定复现的最小命令**(一行能跑):

```bash
# 例子:某个测试在 CI 上失败,本地通过
npm test -- --grep "specific failing test" 2>&1 | tail -20
```

Run it. **Confirm it reproduces** before doing anything else. If you can't reproduce, stop and gather more info — don't guess.

Document the reproduce command in `progress.md`:

```
[debug] reproduce: <command> → <output / exit code>
```

### 2. Localize

二分法找根因:

- **Binary search the timeline:** `git bisect` to find which commit introduced the bug
- **Binary search the codebase:** comment out half the code, see if it still fails
- **Add logging:** at module / function / branch boundaries, narrow down

Goal: identify **specific function + line** where behavior diverges from expectation.

Document:

```
[debug] localized: <file>:<line> | <expected> != <actual>
```

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
- [ ] `progress.md` has the `[debug]` log entries

## pwf Integration

Maps to `task_plan.md` **Phase 5: Fix**. The phase's Errors table gets an entry:

```markdown
## Errors Encountered
| Error | Attempt | Resolution |
|-------|---------|------------|
| Test "create-user" fails on empty name | 1 | Root cause: missing input validation in UserService.create() | Test: tests/test_user_service.py::test_create_user_empty_name | Fix: commit abc123 |
```

This builds debugging knowledge across the project — recurring errors are visible patterns, not surprises.

See [pwf-integration.md](../../pwf-integration.md).