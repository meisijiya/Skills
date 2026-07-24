---
name: diagnosing-bugs
description: "Symptom-driven diagnosis loop for hard bugs and performance regressions. Form ≥3 candidate hypothesis statements before observing; for each hypothesis, predict the distinguishing observation that would falsify the others; eliminate one. Use when debugging-and-error-recovery's 5-step triage (reproduce / localize / reduce / fix / guard) is in progress and the cause is non-obvious; when you've tried the obvious causes and the bug persists; or when the symptom is a performance regression that doesn't match a known failure mode. Pairs with debugging-and-error-recovery (the protocol) by adding the diagnostic discipline underneath — debugging owns the sequence, this skill owns the 'which observation next' question; together they let you diagnose hard bugs systematically."
allowed-tools: "Read Bash Glob Grep"
---

# diagnosing-bugs

## Overview

`debugging-and-error-recovery` is the **protocol**: reproduce / localize / reduce / fix / guard. This skill is the **discipline inside the localize-and-reduce phases** — when the cause isn't obvious, what observation do you make next?

Most debugging wastes time on the wrong hypothesis. The fix isn't more brainstorming; it's a tighter observation. Symptom-driven diagnosis:

- Form ≥3 hypotheses about the cause BEFORE making an observation
- For each hypothesis, predict what observation would distinguish it from the others
- Make the smallest observation that distinguishes
- Eliminate one or more hypotheses
- Repeat until one hypothesis remains

This is `debugging-and-error-recovery` Step 2 (Localize) made concrete — and Step 3 (Reduce) as well. The two skills together form the full debugging cycle:

| Phase | Owner | Skill |
|---|---|---|
| Reproduce | `debugging-and-error-recovery` (Step 1) | protocol — build a minimal repro |
| Localize | **`diagnosing-bugs`** | symptom-driven observation |
| Reduce | **`diagnosing-bugs`** | minimize repro until 1 variable differs |
| Fix | `debugging-and-error-recovery` (Step 4) | protocol — write minimum code to fix |
| Guard | `debugging-and-error-recovery` (Step 5) | protocol — write test that would have caught this |

This skill is `core/` because hard bugs are a guaranteed part of every project; the discipline is more universal than the specifics.

## When to Use

**Use when:**

- debugging-and-error-recovery's Step 2 (Localize) is in progress and the bug's cause is non-obvious
- You've tried 1-2 hypotheses and they didn't pan out (random debugging wastes time)
- The bug is a performance regression that doesn't match a known failure mode (latency spike without error spike, error spike without latency spike, etc.)
- The bug is intermittent — first reproduce it, then this skill for the local
- You're asked "why is X slow" / "why does X return wrong values" / "why does Y sometimes fail" — observation-driven investigation, not guess-driven

**NOT for:** (scenario description — let description match decide)

- Bug with obvious cause (syntax error / type error / missing import / typo in config) → fix directly
- Production incident in-flight (you need the runbook, not the diagnostic loop) → [`production-incident-playbook`](~/.agents/skills/production-incident-playbook/SKILL.md) for the incident protocol; come back here when the runbook's Phase 4 (Resolve) needs deeper investigation
- Security investigation (the threat model / attack pattern is different) → [`security-incident-response`](~/.agents/skills/security-incident-response/SKILL.md)
- Performance regression hunting post-deploy (no clear repro) → [`performance-optimization`](~/.agents/skills/performance-optimization/SKILL.md) post-hoc optimization
- Per-PR / per-deploy evidence (not a bug) → [`verification-before-completion`](~/.agents/skills/verification-before-completion/SKILL.md)

## Process

### 1. Build a hypothesis set BEFORE observing

Write down at least 3 hypotheses about the cause. Don't observe until you have ≥3 distinct hypotheses.

For each hypothesis, predict:

- **What observation would distinguish this from the others?**
- **What's the cheapest way to make that observation?**

A "hypothesis" is testable + specific. Compare:

| Bad (vague) | Good (testable + specific) |
|---|---|
| "Something is wrong with the database" | "The slow query is `SELECT * FROM users WHERE ...` because it does a full table scan when there's no index on `email`" |
| "The cache is broken" | "The cache returns stale data because the TTL is set in seconds but the test asserts minutes" |
| "Race condition in handler X" | "Two concurrent requests to handler X both pass the existence check before either inserts; second insert fails with a unique-violation that bubbles up as 500" |

Vague hypotheses produce vague observations. Specific hypotheses have a specific observation that distinguishes them.

### 2. For each hypothesis, predict the distinguishing observation

Examples:

| Hypothesis | Distinguishing observation |
|---|---|
| "Slow query is the full-table scan" | Run `EXPLAIN ANALYZE` on the suspect query; check if it shows "Seq Scan on users" |
| "Cache TTL is in seconds not minutes" | Read the cache config; observe the cache hit rate over 70 seconds (longer than 60s TTL but shorter than 1-minute expected TTL) |
| "Concurrent-insert race" | Run 10 concurrent requests; observe if ≥2 return success (no unique-violation) but only 1 record exists |

The cheapest distinguishing observation wins. **Don't start by running every test**; start by running the one that falsifies the most-likely hypothesis.

### 3. Make the smallest distinguishing observation

Don't refactor anything yet. Don't "fix" anything yet. **Observe**.

An observation is:

- A specific command run + the result (with timestamp + git SHA of the code-under-test)
- A specific log line read + the value seen
- A specific metric pulled + the comparison vs baseline
- A specific hypothesis test (e.g. write a 3-line script that asserts the suspected condition)

If the observation doesn't falsify your top hypothesis: **you've eliminated one possibility**. Update the hypothesis set. Don't keep the same hypothesis alive across multiple observations — if the observation matched the prediction, that's data; if it didn't, that's data too.

### 4. Update the hypothesis set

After each observation:

- **Falsified hypothesis**: cross it out (with the observation that killed it)
- **Surviving hypothesis**: keep it; design the next distinguishing observation
- **New hypothesis surfaced by the observation**: add it; design a distinguishing observation for it

Loop until one hypothesis survives with high confidence. **Three observations minimum** is typical; for hard bugs, 5-7 is normal.

### 5. Once one hypothesis survives — localize + reduce

Now you're back in `debugging-and-error-recovery`:

- **Localize**: which module / function / line is the cause? (Reduce search space)
- **Reduce**: minimum-repro the cause to one variable / one input / one config

At this point, the fix is usually obvious. If it's not: you've localized to the wrong level; go back to step 1.

### 6. Document the diagnosis

When the bug is fixed, write a 1-paragraph diagnosis for the postmortem / commit message:

```markdown
## Diagnosis
- Symptom: <what users saw>
- Root cause: <specific technical cause with file:line>
- Distinguishing observations: <1-3 observations that localized the cause>
- Why obvious causes didn't pan out: <what was tried that didn't work>
- Fix: <the code change>
- Guard: <the test that would catch this in future>
```

### 7. Anti-patterns

| Anti-pattern | Consequence |
|---|---|
| "Let me just run more tests" | Random debugging wastes time |
| "I bet it's the cache" | Single-hypothesis debugging |
| "Let me refactor this code" | Premature change before diagnosis |
| "Maybe it's X, let me check X then Y then Z" | Sequential debugging without hypothesis ranking |
| "I observed the bug; let me try a fix" | Observation ≠ diagnosis |
| "I'll add logging everywhere" | Logging is not observation; it's noise |
| "Let me search Stack Overflow" | Symptom-driven diagnosis must run against YOUR code, not generic patterns |
| "Let me try the same fix again" | If it didn't work the first time, the cause is different from your hypothesis |

### 8. Worked example — "checkout endpoint slow for some users"

Symptom: 1% of checkout requests take 5s; the rest take 200ms.

Hypothesis set (write down 3):

1. **Stripe API is slow for some payment methods** (e.g. 3DS-required transactions have 4s bank round-trip)
2. **Inventory check queries the primary DB synchronously** with no caching; contention from other requests causes the spike
3. **A specific user cohort's payment method triggers a fraud check** that has its own 5s timeout

Distinguishing observations:

- **For H1**: pull Stripe response time by payment_method; check if 5s cases correlate with 3DS-required payment methods
- **For H2**: trace a 5s checkout; observe DB query time; check if it's near 5s
- **For H3**: pull 5s cases' user cohort; check if fraud-check service latency correlates

Cheapest observation: pull Stripe response times (1 SQL query). Result: H1 doesn't correlate — slow checkouts have Stripe responses <500ms.

Next observation: trace a 5s checkout end-to-end. Result: 4.8s of the 5s is in the inventory check (H2 confirmed).

Localize: which inventory check? Inventory service has 3 endpoints; trace shows the "limited stock" check (added 2 weeks ago) is the slow one. Reduce: minimum input is "user wants item with stock_count = 1"; the call to /inventory/limited takes 4.8s for stock_count=1 but <100ms for stock_count>=2. Root cause: new code path added `FOR UPDATE` on a heavily-contended row, blocking concurrent transactions.

Fix: replace FOR UPDATE with a non-blocking check; add a test that asserts limited-stock checkout latency < 1s under load.

Diagnosis (1 paragraph):

> Symptom: 1% of checkout requests took 5s. Root cause: the new limited-stock check (added 2 weeks ago) used `FOR UPDATE` on a hot row, causing lock contention. Distinguishing observations: Stripe response times ruled out payment-side latency; end-to-end trace localized to inventory; trace within inventory localized to /limited endpoint. Fix: replace `FOR UPDATE` with non-blocking read.

This is the discipline: 3 hypotheses, 3 observations, one survives, fix follows.

## Common Rationalizations

| Excuse | Why it's wrong |
|---|---|
| "I have one strong hypothesis, I'll test that first" | Strongest first is fine, but you need ≥3 to design a distinguishing observation. One hypothesis = no observation that distinguishes it from anything. |
| "I've been debugging this for hours, I'm too tired to write down hypotheses" | Writing the hypothesis set is what makes the next observation efficient. Skipping it makes the next hour worse. |
| "I can ask the LLM to fix it without knowing the cause" | An LLM (or a human) can guess a fix, but a guess-fix for an unknown cause is a coin flip. Symptom-driven diagnosis is faster than guess-fix-loop. |
| "Just add logging and read the logs" | Logs confirm what happened, not why. Logging is for verifying a hypothesis, not generating one. |
| "It's intermittent, I can't make a hypothesis" | Intermittent means "depends on state I haven't observed yet" — that IS a hypothesis. State the state variables; predict which one differs. |
| "It's obvious, I'll just fix it" | If it were obvious, debugging-and-error-recovery's Step 1 (Reproduce) would have led you straight to it. If you're past Step 1, it's not obvious. |

## Red Flags

The diagnosis loop is going wrong if:

- More than 7 observations made without converging on a cause (you're guessing, not diagnosing)
- Each observation is "let me try another thing" (no hypothesis being falsified)
- Same hypothesis still alive after 3+ observations that should have falsified it (you didn't actually falsify — you confirmed your existing belief)
- "Fix" attempted before diagnosis converged (you're guessing fixes)
- Hypothesis set has < 3 candidates (you've already anchored on one; symptom-driven diagnosis requires alternatives)
- Diagnosis takes longer than 2 hours without convergence (use the oracle agent or a colleague; you may be too close)

## Verification

Before claiming the diagnosis is done, produce evidence:

- [ ] ≥ 3 hypotheses written down (not just "in your head")
- [ ] Each hypothesis has a distinguishing observation predicted
- [ ] Each observation documented (command + result + timestamp + git SHA)
- [ ] Falsified hypotheses crossed out with the killing observation
- [ ] Surviving hypothesis survives ≥ 2 distinguishing observations
- [ ] Localized to a specific module / function / line
- [ ] Minimum-repro the cause
- [ ] Diagnosis paragraph written (symptom / cause / distinguishing observations / why obvious didn't pan out / fix / guard)
- [ ] Fix applied + test added that would have caught this in the future

**Acceptance criterion**: A second engineer reading the diagnosis paragraph can confirm the cause is localized + the fix is appropriate + the guard would catch recurrence — without re-running the diagnosis.

## omo Integration

| OMO capability | Used for |
|---|---|
| `oracle` agent | When 2 hypotheses survive after multiple observations, get a second opinion on which to prioritize next |
| `lsp` MCP | Jump to definition; locate the suspected function for the localized cause |
| `general` agent | Parallel subagents to run independent observations when the hypothesis set is large |
| OMO `debugging` mode (built-in) | For very hard bugs (multi-system, race-condition, environmental) — escalation tier |

## Anti-patterns in debugging (call out and fix)

| Anti-pattern | Fix |
|---|---|
| "Let me add a print statement and see" | Form 3 hypotheses first; predict distinguishing observations |
| "Let me run all the tests" | Pick the one test that falsifies the most-likely hypothesis |
| "I bet it's the third-party service" | State which third-party service, which call, which timing — vague guesses waste time |
| "Let me revert my last change" | Diagnose first; reverting is mitigation, not diagnosis |
| "Maybe the user is wrong" | Reproduce first; if you can't reproduce, the symptom IS data — adjust hypothesis |
| "I've checked everything, it must be magic" | List the hypotheses you DIDN'T test; the bug is usually in the untested one |
