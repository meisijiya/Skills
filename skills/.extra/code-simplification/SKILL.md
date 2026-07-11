---
name: code-simplification
description: "Reduces code complexity while preserving exact behavior. Use when code works but is harder to read or maintain than it should be, when adding a feature requires touching too many places, or when the diff to understand a module exceeds ~100 lines."
allowed-tools: "Read Edit Bash Glob Grep"
---

# code-simplification

## Overview

行为不变的前提下削减复杂度。不是优化性能,不是清理 AI 痕迹(那是 `remove-ai-slops`,omo 内置),不是加测试覆盖。

Complexity 的两种形态:
- **Essential**:业务规则本身的复杂度(无法削减,只能命名)
- **Accidental**:实现选择引入的复杂度(可以削减)

这个 skill 只削减 accidental complexity。Chesterton's Fence 保护 essential complexity。

## When to Use

**Use when:**
- 改一处需要 touch 5+ 个文件
- 理解一个函数需要读 100+ 行
- 同一个概念有 3+ 种命名
- 重构时发现"A → B"中间有 5 个不必要的间接层
- Code review 反复出现 "为什么这样写?"

**NOT for:**
- Performance 优化(用 performance-optimization)
- AI slop 清理(omo 的 remove-ai-slills skill)
- 重写整个模块(spec-driven-development 流程)
- 改动 behavior 的"简化"(那是新功能)

## Process

### 1. Identify the target

What's the specific module/function/class to simplify? Don't try to simplify everything at once.

### 2. Verify Chesterton's Fence

Before removing anything, ask: **"Why was this added?"** If you can't answer, don't remove it. Use git blame, PR history, or ask the original author.

Removing code you don't understand is the #1 simplification anti-pattern.

### 3. Establish behavior baseline

Run the existing test suite. **All tests must pass** before simplifying. If they don't, fix that first.

```bash
npm test  # exit 0 baseline
```

### 4. Apply simplification techniques (in order)

1. **Rename**: best names > good comments. If you need a comment to explain a name, the name is wrong.
2. **Extract**: pull repeated logic into a named function. Don't extract single-use code.
3. **Inline**: remove trivial wrappers that obscure the actual logic.
4. **Remove dead code**: unused exports, unreachable branches, commented-out blocks.
5. **Flatten nesting**: early returns > nested if/else.
6. **Co-locate**: related code lives together, not in "utils" dumping ground.

Stop after each change. Re-run tests.

### 5. Verify behavior unchanged

```bash
npm test  # exit 0 — same tests, same pass
```

If tests still pass, behavior is preserved. If not, you changed behavior — revert.

### 6. Diff review

```bash
git diff --stat
```

**Net lines should be negative or near-zero.** If you added more lines than you removed, you didn't simplify — you rewrote.

## Common Rationalizations

| Excuse | Reality |
|---|---|
| "这层抽象以后会用到" | YAGNI。删,以后再加比留着的成本低。 |
| "原作者可能有意为之" | 那就 git blame 问清楚,不要猜。 |
| "简化会破坏现有功能" | 简化 ≠ 改 behavior。测试过就是没破。 |
| "代码可以工作就别动" | "工作"是最低标准。"读得懂"才是合格的。 |
| "这一行太巧妙了" | 巧妙 ≠ 简洁。Clever 是要 decode 的,simple 是直接读的。 |
| "我只删了一行" | 一行能藏 5 层逻辑。每次简化只看 diff 大小,不看影响深度。 |

## Red Flags

- 删了 Chesterton's Fence(没搞清楚为啥加的就删)
- 测试没跑过就 commit
- 简化后 net diff 为正(加了更多)
- 改了 behavior 但没加测试
- 简化了别人刚写的代码(< 1 周)—— 等沉淀再动
- 在 master / main 分支直接简化(应该 PR)
- 删了看起来"没用"的代码但没 git blame

## Verification

Before declaring done, confirm:
- [ ] Chesterton's Fence verified for every removed line (blame / history checked)
- [ ] Test suite passes before AND after
- [ ] Net diff ≤ 0 (removed ≥ added)
- [ ] No behavior change visible to test suite
- [ ] No unrelated formatting changes in diff
- [ ] Diff reviewed and is "obviously correct" (no clever bits)

## pwf Integration

Maps to `task_plan.md` **Phase 6: Cleanup**. Each simplification is its own row:

```markdown
### Phase 6: Simplify
| Target | Diff | Tests | Behavior | Status |
|--------|------|-------|----------|--------|
| UserService.create | -15/+3 | ✓ | unchanged | complete |
| (next target) | | | | pending |
```

See [pwf-integration.md](../../pwf-integration.md).