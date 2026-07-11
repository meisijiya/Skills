---
name: incremental-implementation
description: "Decomposes a task into vertical slices — each slice is independently committable, testable, and rollback-safe. Under omo, delegates slice todo tracking to atlas agent and uses git-master skill for atomic commits. Use when any change touches more than one file, when the task has 3+ steps, or when refactoring/migrating existing code."
allowed-tools: "Read Edit Bash Glob Grep"
---

# incremental-implementation

## Overview

纵向切片 —— 每个 slice 独立可交付、可回滚、可单独 ship。横向分层(一口气全写完)是大忌,因为 debug 时找不到边界,rollback 时丢一片,review 时读 1000 行 diff。

Slice 的大小不是越小越好 —— 太碎浪费 commit overhead,太大失去切片价值。经验值:**30~100 行净 diff** 是甜区。

## When to Use

**Use when:**
- 任何改动超过 1 个文件
- 任务含 3+ 个步骤
- 重构 / 迁移
- 需要保留 rollback 能力
- 多人协作同一代码库

**NOT for:**
- 单文件改动
- 纯文档 / 配置修改
- 用户明确说"一次性写完"
- 已知 trivial 重命名(用 IDE rename)

## Process

### 1. Decompose into slices

Read `task_plan.md` Phase 3. Slice by **vertical capability**, not by technical layer:

❌ **Wrong (horizontal):**
- Slice 1: Add database schema
- Slice 2: Add API endpoint
- Slice 3: Add UI

Each slice breaks the system end-to-end. After slice 1 the app doesn't work.

✅ **Right (vertical):**
- Slice 1: Add minimal "create user" feature end-to-end (schema + endpoint + minimal UI)
- Slice 2: Add "read user" feature
- Slice 3: Add "update user" feature

Each slice ships a working capability. After slice 1 users can create accounts.

### 2. Size each slice

| Indicator | Target |
|---|---|
| Net diff (added + modified, minus deleted) | 30~100 lines |
| New files per slice | ≤ 3 |
| Touched existing files per slice | ≤ 5 |
| Test files per slice | ≥ 1 |
| Slice commit count | 1 (squash if multi-commit during slice work) |

If a slice exceeds these, decompose further.

### 3. Isolate each slice

For slices > 50 lines, use a feature branch or git worktree:

```bash
git worktree add ../project-slice-2 -b feat/slice-2-name
```

This lets you switch context, run tests in isolation, and rollback cleanly.

### 4. Implement + verify per slice

For each slice, follow the loop:
1. **omo**: load `git-master` skill (atomic commits, branch hygiene, rebase surgery)
2. **omo**: delegate slice todo tracking to `atlas` agent (Sisyphus routes)
3. Implement the slice
4. Run `test-driven-development` skill (red-green-refactor)
5. Verify the slice ships end-to-end (not just unit tests)
6. Commit with `slice: <slice-name>` prefix in message (git-master enforces atomicity)
7. Append to `progress.md`:
   ```
   [slice] <name> → <commit-sha> | <LOC> | tests pass
   ```

### 5. Rollback drill

Before merging slices, mentally rehearse: "If slice 3 breaks production, can I revert just slice 3?" If no, the slice isn't actually independent — re-decompose.

## Common Rationalizations

| Excuse | Reality |
|---|---|
| "一次写完更快" | 一次写完更快地制造 bug,而且 debug 时找不到边界。 |
| "slice 太小没必要" | 30 行的 slice 也有价值 —— 它把"已 working"边界画清楚。 |
| "git worktree 太麻烦" | 主分支污染更麻烦 —— 一次事故就够你怀念 worktree。 |
| "没有合适的 slice 边界" | 强制找。每个能力必有可独立交付的最小版本。 |
| "横着切更快看到进度" | 横着切给你"快"的错觉。系统依然不可运行到 slice 1 完成。 |
| "review 一次看完就行" | 1000 行 diff 的 review 几乎一定漏问题。多个 50 行 diff 的 review 抓得全。 |

## Red Flags

- 单个 slice > 100 行 net diff
- slice 之间互相依赖(必须先 A 才能 B)
- 没 commit 就跳到下一个 slice
- 在 main 分支直接改
- slice 完成后没跑全链路 smoke test
- slice 没有对应的 `slice:` 前缀 commit
- 多个 slice 在同一个 commit 里

## Verification

Before moving to the next slice, confirm:
- [ ] Slice net diff ≤ 100 lines
- [ ] Slice has ≥ 1 test file
- [ ] Slice commit message starts with `slice: <name>`
- [ ] `progress.md` has the `[slice]` log line
- [ ] End-to-end smoke test passes (not just unit tests)
- [ ] Previous slices still work (no regression)

Before declaring task complete:
- [ ] All slices independent (rollback drill succeeds)
- [ ] Total commits ≥ number of slices
- [ ] No slice contains code from a future slice

## pwf Integration

Maps to `task_plan.md` **Phase 3: Slice**. Each slice gets a row in the phase's progress table:

```markdown
### Phase 3: Slice
| Slice | Commit | LOC | Tests | Status |
|-------|--------|-----|-------|--------|
| create-user | abc123 | 67 | ✓ | complete |
| read-user | def456 | 45 | ✓ | complete |
| update-user | (in_progress) | | | in_progress |
```

See [pwf-integration.md](../../pwf-integration.md).