---
name: test-guard
description: "Prevents AI-assisted test code from passing-for-the-wrong-reasons — over-mocked, tautological, or premise-tested tests that pass without proving behavior. Use when reviewing AI-generated tests before merge, when a test suite is silently green but bugs are escaping to production, when TDD's red-green-refactor has been confused with 'ask the model to write tests that pass', or when establishing a per-PR test-quality gate. Pairs with test-driven-development (the methodology); this skill enforces that the resulting tests actually test something."
allowed-tools: "Read Bash Glob Grep"
---

# test-guard

## Overview

`test-driven-development` is the red-green-refactor discipline: write a failing test, write minimum code to pass, refactor. The discipline assumes the test, when red, captures a real behavior gap. When AI writes the test from the same instruction "write tests for X", the discipline breaks:

- The test never goes red (the model writes a test that already passes because the model wrote the implementation logic into the test)
- The test mocks away the very thing it's testing (the model writes a passing assertion against a no-op stub)
- The test tests the model, not the system (the test asserts behavior it would have implemented the same way)

Result: tests are green, the bug ships, "all tests passed" before merge.

`test-guard` is the post-`test-driven-development` quality audit. It doesn't replace TDD; it enforces that the tests TDD produced actually test what TDD claims they test.

This skill is the layer-specific complement to `ai-code-blindspots` (which catches cross-cutting AI blindspots). `test-guard` is exclusively about test code quality.

## When to Use

**Use when:**

- Reviewing AI-generated test code before merge
- Test suite is green but production bugs are escaping (silent-green failure mode)
- "We have 100% coverage" but the product is broken (coverage ≠ test quality)
- Audit a test file for premise correctness — does it assert against the right thing?
- Establish a per-PR test-quality gate (CI step that runs this skill on every PR)
- After a "passing test" incident: tests passed, code had a bug, postmortem reveals the test was tautological

**NOT for:** (scenario description — let description match decide)

- Writing the test first per TDD → [`test-driven-development`](~/.agents/skills/test-driven-development/SKILL.md)
- Per-PR diff blindspot review (cross-cutting, not test-specific) → [`ai-code-blindspots`](~/.agents/skills/ai-code-blindspots/SKILL.md)
- Production-bug root-cause hunt → [`debugging-and-error-recovery`](~/.agents/skills/debugging-and-error-recovery/SKILL.md)
- Per-line code audit (cross-cutting trust boundary) → [`security-and-hardening`](~/.agents/skills/security-and-hardening/SKILL.md)

## Process

### 1. Identify what the test is supposed to prove

For each test (each `it()` / `test()` / `def test_` / `func TestX`):

- What behavior is the test claiming? (1 sentence)
- What user-visible action does it cover? (API call / UI interaction / state change)
- What's the strongest assertion in the test? (the one most likely to catch a bug)

If you can't answer the first two, the test is in trouble from the start.

### 2. Run the 7 quality checks

#### Check G-1: Is the test actually green from running the system, or from skipping?

Indicators:

- Test calls `skip` / `xit` / `it.skip` / `test.skip` / `@unittest.skip` / `pytest.mark.skip`
- Test has `if (process.env.SKIP_FLAKY)`: passes by skipping
- Test expects an exception and the implementation catches internally; the test sees no exception either way

Audit:

```bash
# grep for skip patterns in test files
git grep -nE '\\b(skip|xit|xdescribe|test\\.skip|@unittest\\.skip|pytest\\.mark\\.skip)\\b' test/
```

**Severity if violated**: HIGH (test never runs → silent green). CRITICAL if the skip is unconditional and the test is the only coverage for a critical path.

#### Check G-2: Does the assertion actually execute the production code path?

Indicators of "mocks the system under test":

- The mock setup mimics the return value structure of the production code being tested
- The assertion is `expect(mockFoo).toHaveBeenCalledWith(...)` rather than `expect(result).toBe(...)`
- The mock returns `Promise.resolve({ data: expectedResult })` matching the production function's promise structure exactly
- The test file imports something the production code imports and re-implements it

Audit pattern:

```bash
# Find tests that mock the function they are supposed to test
git grep -nE 'jest\\.mock\\(['\"\\x27](.*)['\"\\x27]\\)' test/ | \
  xargs -I {} grep -l "<same import path>" src/
```

For each, manually verify the mock replaces something the test should be testing.

**Severity if violated**: HIGH (the test passes regardless of the production-code correctness).

#### Check G-3: Is the assertion tautological (proves only what the test sets up)?

Indicators:

- Test sets `const x = 5`; assertion is `expect(x).toBe(5)` — passing for the wrong reason
- Test calls production function and asserts the return is structurally equal to a literal the test wrote
- Test sets a mock return to `{ foo: 'bar' }` and asserts the function returns `{ foo: 'bar' }` (this is testing the mock, not the function)

Audit:

```bash
# Find tests where the assertion matches a literal in the test file
# (heuristic: grep for `<describe-block>.*it.*[` and look for duplicated literals)
```

For each suspect test, manually verify: would the assertion fail if the production function were removed entirely, and the function-under-test returned `undefined`?

**Severity if violated**: HIGH (test is structurally passing — does not exercise behavior)

#### Check G-4: Does the test cover the boundary / failure case, not just the happy path?

Indicators:

- Test only covers the "input A → expected output B" happy path
- No tests for `null` / `undefined` / empty array / overflow
- No tests for the error-path code (the catch handler / the 4xx / 5xx branch)
- No tests for concurrency or order-dependent behavior

Audit by category: for each function-under-test, count the case-coverage:

- Happy path: should have ≥ 1
- Boundary (empty / max / min): should have ≥ 1
- Failure (error / 4xx / 5xx): should have ≥ 1
- Adversarial (malformed input / injection / race): if security-critical, should have ≥ 1

For security-critical functions (auth, validation, parser), **zero adversarial tests** = HIGH finding.

**Severity if violated**: MEDIUM (gap in coverage) → HIGH for security-critical paths.

#### Check G-5: Does the test exercise a real (or faithful) dependency, or a stub that always succeeds?

Indicators:

- Mock returns the same response for any input (`mockReturnValue({ ok: true })`)
- Mock function does nothing: `jest.fn(() => undefined)`
- Database mock returns all rows as `[]` regardless of query
- Network mock returns 200 OK for any URL

**Severity if violated**: HIGH (test doesn't exercise the dependency's behavior; bug in real dep would slip through).

For databases / external services, the rule is: use a real (test) instance when possible — sqlite in-memory, testcontainers for postgres, mountebank / wiremock for HTTP. Reserve mocks for "I don't have a useful test instance for this".

#### Check G-6: Is the test assertion narrow (specific value) or vague (anything-non-error)?

Indicators of "vague pass":

- `expect(fn()).toBeDefined()` — passes if the function returns anything
- `expect(result).toBeTruthy()` — passes for `1`, `'foo'`, `{}`, etc.; misses correctness bugs
- `expect(result.length).toBeGreaterThan(0)` — passes with one item; doesn't verify the value
- `assertThrows(...)` without asserting the thrown message / type — passes for any throw

A test that uses these exclusively is checking "didn't crash", not "produced the right output".

**Severity if violated**: MEDIUM (per audit) — boundary between "weak test" and "useless test".

#### Check G-7: Does the test depend on order, global state, or timing?

Indicators:

- Test relies on a previous test having set up state (without explicit setup)
- Test uses `Date.now()` or sleep-based timing → flaky
- Test depends on filesystem order / network state
- Test modifies a global; another test depends on the global

These tests pass alone but fail in CI under parallelism or in different orders.

**Severity if violated**: HIGH (silent break, depends on order).

### 3. Aggregate per-file score

For each test file, count findings per check + severity. Output a file-level report:

```markdown
## test-guard report — <test file path>

- Tests in file: <N>
- Findings: <total>
  - HIGH: <count>
  - MEDIUM: <count>
  - LOW: <count>

| Severity | Check | Test name | Evidence | Remediation |
|---|---|---|---|---|
| HIGH | G-2 | "processes valid input" | mocks the parser being tested | unmock the parser; assert against parser output |

## Verdict
- <PASS / FAIL / NEEDS-FIX>
- Per-PR gate threshold: ≥ 1 HIGH = auto-FAIL
```

### 4. CI integration pattern

Per-PR CI step (pseudo-code):

```bash
# Run test-guard on all changed test files
git diff --name-only origin/main..HEAD | grep -E '(test|spec|_test)\\.(ts|js|py|go|java)$' | \
  xargs -I {} <test-guard runner> --file {}

# Aggregate HIGH findings
HIGH_COUNT=$(jq '[.[] | select(.severity == "HIGH")] | length' results.json)

if [ "$HIGH_COUNT" -gt 0 ]; then
  echo "::error::Test quality gate failed: $HIGH_COUNT HIGH-severity findings"
  exit 1
fi
```

This pairs with test-driven-development: TDD writes the test, test-guard verifies the test wasn't a tautology. The two are gates, not conflicts.

### 5. Anti-patterns

| Anti-pattern | Consequence |
|---|---|
| "Tests pass" without proof-of-meaning coverage | Coverage ≠ correctness |
| `toBeDefined()` as the only assertion | Doesn't catch wrong-but-truthy results |
| Mocking the function under test | Tests the mock, not the function |
| Skipping flaky tests to keep CI green | Silent green; bugs escape |
| Adding more assertions after a bug ships in production | Reactive noise; the structural issue is G-2 / G-3 |
| "We have 100% test coverage" defense | Coverage counts lines executed, not lines meaningfully tested |

## Common Rationalizations

| Excuse | Why it's wrong |
|---|---|
| "Tests are passing; what's the problem?" | Passing tautological tests gives false confidence; silent-green is the failure mode this skill catches. |
| "Coverage is 100%" | Line coverage ≠ assertion coverage ≠ behavior coverage. |
| "We mock external services so tests are fast" | Mocks should not replace the function-under-test. Reserve mocking for the dependency, not the system. |
| "Skipped test is fine, we don't run that code path in prod" | Production deploys code paths you didn't plan for; the skipped test indicates a coverage gap that wasn't surfaced. |
| "Lazy assertion (toBeDefined) is fine for happy path; edge cases are separate tests" | If happy-path is a toBeDefined and edges are also lazy, no real coverage. |
| "Test was written by AI; it must be fine" | That's exactly when to apply this skill. |

## Red Flags

The test-quality audit is going wrong if:

- Run against a test suite without seeing the production code being tested (test-only audit = missing G-2 / G-3 context)
- Reports zero findings on a test file with > 50 tests (heuristic: real test suites have at least some quality issues to surface)
- Skips G-5 (real dependencies) without justification (sqlite-in-memory is always available)
- Confuses "test failure" with "test quality" — a failing test isn't necessarily well-written
- Confuses coverage with quality — coverage is necessary but not sufficient
- Output aggregates per file but not per check — file-level "OK / not OK" loses which check failed

## omo Integration

| OMO capability | Used for |
|---|---|
| `oracle` agent | Verdict calibration: "Is this test really tautological, or just minimal-honest?" (oracle is read-only); "Should this `expect.assertions(0)` block count as G-7 lazy-assert?" |
| [`test-driven-development`](~/.agents/skills/test-driven-development/SKILL.md) | Methodology partner — test-guard audits existing tests; TDD enforces the discipline to write them right (red-green-refactor is the upstream cause; test-guard is the post-hoc audit) |
| `meisijiya-review-router` plugin | Auto-loads this skill on `Edit` of test files (matches `*test*.{ts,tsx,py,go,rs,swift,...}` per `matchPath` policy in `.opencode/plugins/meisijiya-review-router.js`) |
| `deep` agent category (omo) | Optional: for large test suites (>50 tests per file), fan out parallel sub-agents per file to scale the audit; without `deep`, fall back to per-file audits in the same agent context |

## Verification

Before claiming the audit is done, produce evidence:

- [ ] §1 Each test in scope has a 1-sentence behavior claim
- [ ] §2 All 7 checks run; skipped checks cited with reason
- [ ] §3 Per-file score + Findings table
- [ ] §4 Per-PR gate threshold defined and applied
- [ ] §5 Anti-patterns noted; remediations specified
- [ ] Output reviewed by the test's author OR a test-aware engineer (the author can usually defend tautological tests)

**Acceptance criterion**: A test-aware second reviewer re-runs the audit on the same files, reaches the same findings, and the team agrees which findings to fix this PR vs defer.
