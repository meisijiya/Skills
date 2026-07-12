---
name: test-driven-development
description: "Enforces red-green-refactor discipline — write a failing test first, write minimum code to pass, then refactor. Use when implementing any new logic, fixing any bug, or changing any behavior. Anti-pattern: writing code first and 'adding tests later'."
allowed-tools: "Read Edit Bash Glob Grep"
---

# test-driven-development

## Overview

红绿重构 —— 先写失败的测试,再写最小代码让它通过,再重构。**禁止先写实现再补测试**。

"测试覆盖实现" ≠ TDD。TDD 的关键是:**测试先于实现存在,且一开始是红的**。这保证测试真的在测行为(因为它失败过),而不是事后给实现"站台"。

测试金字塔 80/15/5(unit / integration / e2e)—— 多数是快的单元测试,少量是端到端。

## When to Use

**Use when:**
- 实现任何新逻辑(函数、类、模块)
- 修复任何 bug(先写 regression test)
- 改任何行为(API 签名、返回值、错误处理)
- 添加新分支 / 边界情况

**NOT for:**
- 单行 typo / 重命名
- 纯文档 / 注释 / 类型注解
- 生成代码 / 配置 / 模板
- 探索性 spike(用 throwaway 脚本)

## Process

### 1. Write the failing test (RED)

Before touching implementation, write a test that:
- Calls the function/API you're about to write
- Asserts the expected behavior (return value, side effect, error case)
- **Fails** when run (because the function doesn't exist or doesn't behave correctly)

```python
# tests/test_user_service.py
def test_create_user_assigns_unique_id():
    service = UserService()
    user = service.create(name="alice")
    assert user.id is not None
    assert isinstance(user.id, UUID)
```

Run it. **Confirm it fails for the right reason** (not a typo, not a missing import).

### 2. Write minimum code to pass (GREEN)

Write the **smallest possible** implementation that makes the test pass. Resist the urge to:
- Add features the test doesn't ask for
- Handle edge cases the test doesn't cover
- Optimize prematurely

```python
class UserService:
    def create(self, name: str) -> User:
        return User(id=uuid4(), name=name)
```

Run the test. **Confirm it passes.**

### 3. Refactor (REFACTOR)

Now improve the code **without changing behavior**:
- Remove duplication
- Improve naming
- Extract helpers
- Apply patterns

Run the test after each refactor. **Behavior must not change.**

### 4. Commit

Two commits per TDD cycle (or one squashed — your team's call):
- `test: add <test-name>` — just the failing test + scaffolding
- `feat: implement <feature>` — minimum implementation

Or with test+impl together for trivial cases:
- `feat: implement <feature> with test`

### 5. Boundary tests

For any public API, add these boundary tests (one per case):
- Zero value (empty list, 0, "")
- Null / None / undefined
- Max value (overflow, very large input)
- Concurrent access (if applicable)
- Invalid input (wrong type, malformed)

## Common Rationalizations

| Excuse | Reality |
|---|---|
| "我先写代码再补测试" | 那叫"测试覆盖实现",不是 TDD。事后写的测试不会失败,所以它们不可信。 |
| "这个逻辑太简单,不需要测试" | 简单的逻辑最容易藏 bug —— 因为 reviewer 也不会多想。 |
| "测试太多,跑得慢" | 100 个单元测试 < 1s。如果慢,测试设计有问题,不是测试多。 |
| "mock 太多,测试不真实" | 那是测试设计问题,不是 TDD 问题。Mock 外部 IO,不要 mock 自己写的逻辑。 |
| "我已经手动测过了" | 手动测不防回归。下次有人改这函数,谁来手动测? |
| "TDD 太慢,影响交付速度" | 短期看慢,长期看快 10x(没 regression bug)。 |

## Red Flags

- 跳过"红"(直接写实现,看不到测试先失败)
- 测试和实现在同一个 commit 里,看不到先红
- 测试只验证类型/存在(`assert x is not None`),不验证行为
- mock 多于真实代码
- 测试覆盖率 100% 但都是 trivial 的(覆盖率是手段,不是目标)
- 修复 bug 时没先写 failing regression test
- 测试用 `time.sleep` / 网络请求(慢 + flaky)

## Verification

Before committing a TDD cycle, confirm:
- [ ] Saw the test fail (RED) — captured in transcript or commit history
- [ ] Wrote minimum implementation, no extra features
- [ ] Test now passes (GREEN)
- [ ] Refactored without behavior change (test still passes)
- [ ] Boundary tests added for public APIs
- [ ] Test runs in < 1s (unit), < 10s (integration), < 60s (e2e)

Per slice, confirm:
- [ ] Test pyramid 80/15/5 maintained
- [ ] No test without corresponding production code (or vice versa)
- [ ] `npm test` / `pytest` / equivalent exits 0
- [ ] Coverage didn't decrease

## pwf Integration

Maps to `task_plan.md` **Phase 4: Verify per slice**. Each slice's TDD completion updates the phase progress:

```markdown
### Phase 4: TDD per slice
| Slice | Red | Green | Refactor | Boundary | Status |
|-------|-----|-------|----------|----------|--------|
| create-user | ✓ | ✓ | ✓ | ✓ | complete |
| read-user | ✓ | ✓ | in_progress | - | in_progress |
```

See [pwf-integration.md](../../pwf-integration.md).