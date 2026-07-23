---
name: verification-before-completion
description: "Use when about to claim work is complete, fixed, or passing, before committing, creating PRs, or telling the user 'done'. Requires running verification commands and confirming output before making any success claims. Applies to ANY communication suggesting completion or correctness."
allowed-tools: "Read Bash Glob Grep"
---

# Verification Before Completion

## Overview

Claiming work is complete without verification is dishonesty, not efficiency.

**Core principle:** Evidence before claims, always. The verification must be fresh in the current turn — a previous run doesn't count.

**Violating the letter of this rule is violating the spirit of this rule.**

> **二段验证(必备)**:
> - **本会话证据**(test 命令 / lint / build)只是第一段
> - 真正宣布 "done" 前还必须有 **OMO `review-work` 的新上下文审计**(第二段)
> - UI 项目追加 **OMO `visual-qa` + 用户亲手运行** 的硬要求(把"人工品味 Taste"纳入完成门)

## When to Use

**Use when — ALWAYS:**
- About to claim any status or express satisfaction
- About to commit, push, or create a PR
- About to tell the user "done" / "finished" / "passing" / "fixed"
- Moving to the next task
- Delegating to subagents (verify their work, don't trust self-reports)

**NOT for:**
- Mid-task status updates (use plain prose, no completion claim)
- Honest uncertainty ("I think this might work but haven't verified yet" is fine)

## Process

### The Gate Function (two-stage)

- [ ] **If this turn produced new code via Write/Edit tool calls** (and not pure-docs / test-only / pure-style-only changes — i.e. the changes include executable logic), AND [`ai-code-blindspots`](~/.agents/skills/ai-code-blindspots/SKILL.md) is **installed** at `~/.agents/skills/ai-code-blindspots/SKILL.md` (it lives in `extra/`, so installation is opt-in), load it for a 7-class blindspot review on the diff before running the Gate Function below. AI tends to under-write: null/undefined boundaries, empty arrays, silent error catches, env incompat (Node-only API in browser), deprecated APIs, hardcoded secrets, invisible promise rejections. **If `ai-code-blindspots` is not installed OR the changes have no executable logic, skip this step and continue with the Gate Function below** — the core verification flow never blocks on a missing optional skill.
- [ ] **If the attested Spec or `.planning/<id>/contract-review.md` assigns any gap L2/L3**, require per-gap counterexample and discriminator evidence before completion: each counterexample has reproducible executable evidence (test, property test, or bounded model-check/solver counterexample as appropriate), and the discriminator run shows the intended violation is detected. Narrative-only evidence is insufficient. Ordinary L1 work keeps the existing gate and is never forced into formal tools.

```
BEFORE any completion claim:

  Stage 1 — in-session evidence:
    1. IDENTIFY: What command proves this claim?
    2. RUN: Execute the FULL command (fresh, complete)
    3. READ: Full output, check exit code, count failures
    4. VERIFY: Does the output actually confirm the claim?
       - If NO → state actual status with evidence ("X failed at step Y")
       - If YES → state first-stage PASS WITH evidence ("X: 34/34, exit 0")

  Stage 2 — fresh-context independent audit (mandatory before "done"):
    5. INVOKE OMO `review-work` skill (new-context, parallel sub-agents)
       - Pass: full OMO plan + branch diff (e.g. `git diff main...HEAD`)
       - Wait for 5 parallel sub-agent reports (goal / constraint / code quality / security / context mining)
    6. TRIAGE reports by severity (not all 🔴 are equal):
       - minor / smell                   → convert to new Blocking slice (Step 6a)
       - major / design issue            → convert to new Blocking slice (Step 6a)
       - critical / data-loss / security / correctness regression
                                          → **trigger [`incremental-implementation`](~/.agents/skills/incremental-implementation/SKILL.md) § 10 Rollback protocol**
                                            (NOT a new Blocking slice — the implementation is wrong, not missing)
    7. UI changes: ALSO invoke OMO `visual-qa` (Playwright screenshots + pixel diff)
       AND ask the human to actually run the app and bless the Taste ("yes it feels right" / "no, change X")
    8. ONLY THEN: Make the completion claim

  Skip stage 2 = "tests pass" without independent audit. Not done.
```

> **Why Stage 2 is mandatory (Matt Pocock)**: a sub-agent in the same session inherits your rationalizations. A fresh-context agent with empty `messages` doesn't. That's the whole point of `review-work`.

### Common Failures → Required Evidence

| Claim | Requires | NOT Sufficient |
|---|---|---|
| Tests pass | Test command output: 0 failures, exit 0 | Previous run, "should pass" |
| Linter clean | Linter output: 0 errors | Partial check, extrapolation |
| Build succeeds | Build command: exit 0 | Linter passing, logs look good |
| Bug fixed | Test original symptom: passes | Code changed, assumed fixed |
| Regression test works | Red-green cycle verified (write → fails → fix → passes) | Test passes once |
| Agent completed | VCS diff shows changes | Agent reports "success" |
| Requirements met | Line-by-line checklist against `OMO plan` Spec | Tests passing, "looks good" |
| L2/L3 strengthened gap closed | Reproducible executable counterexample + discriminator run that detects the intended violation | Narrative example, passing happy-path test, or level label alone |
| Skill loaded | `ls ~/.agents/skills/<name>/SKILL.md` exists | Description matches |
| **Code reviewed** | OMO `review-work` 5-并行子代理报告已收 + triage 完成 | 自我 declare "code looks good" |
| **UI passes taste** | OMO `visual-qa` 报告 + 用户亲手确认 OK | "I built the UI, looks fine" |

### Per-context Verification Commands

**Skills / scripts in this repo:**
```bash
# After ANY change to meisijiya-skills:
git clone https://github.com/meisijiya/Skills /tmp/mjs-check
bash /tmp/mjs-check/scripts/validate-skills.sh
bash /tmp/mjs-check/scripts/check-marketplace.sh
```

(Scripts aren't installed via `npx skills add` — they're repo-internal. Fetch the repo to verify.)

**Project under work:**
```bash
# Run the project's test command, lint, build — whatever proves the claim
```

**Skill invocation:**
```bash
# Confirm the skill exists where you think it does
ls ~/.agents/skills/<name>/SKILL.md
```

## Red Flags — STOP and Verify

- Using "should", "probably", "seems to", "looks correct"
- Expressing satisfaction before verification ("Great!", "Perfect!", "Done!", etc.)
- About to commit / push / PR without fresh verification output
- Trusting agent success reports without checking VCS diff
- Relying on partial verification ("the file looks right")
- Thinking "just this once"
- Tired and wanting to wrap up the work
- **Any wording implying success without having run fresh verification this turn**
- 完成声明但没跑 OMO `review-work`(Stage 2 缺失)
- UI 项目完成声明但没让用户亲手运行一次

## Common Rationalizations

| Excuse | Reality |
|---|---|
| "Should work now" | RUN the verification |
| "I'm confident" | Confidence ≠ evidence |
| "Just this once" | No exceptions |
| "Linter passed" | Linter ≠ compiler |
| "Agent said success" | Verify independently — check VCS diff |
| "I'm tired" | Exhaustion ≠ excuse |
| "Partial check is enough" | Partial proves nothing |
| "Different words so rule doesn't apply" | Spirit over letter |
| "The skill is too simple to need verification" | Simple things become complex. Run it. |
| "我本会话看到 diff 了,不必再独立审查" | 你在自己上下文里 — 这是反 rationalization 的盲区。OMO `review-work` 用新上下文跑。 |
| "UI 在我心里跑通了,不用 visual-qa" | 心里跑通的 UI ≠ 用户手感对的 UI。 |

## Anti-Patterns

- ❌ "I've made the changes. Let me know if you have questions." (no verification, just chatter)
- ❌ "Tests should pass now." (no output)
- ❌ "Looks good." (no evidence)
- ❌ "Done!" (no specific evidence attached)
- ❌ "All tests pass, ship it." (missing Stage 2 OMO `review-work`)
- ❌ "UI built, looks fine to me." (missing user Taste OK)
- ✅ "Tests pass: 34/34, exit 0. OMO review-work: 5 reports, 0 🔴. User confirmed Taste OK. Build clean: tsc + vite build exit 0."

## Why This Matters

From real failure memories:
- Human partner: "I don't believe you" — trust broken
- Undefined functions shipped — would crash
- Missing requirements shipped — incomplete features
- Time wasted on false completion → redirect → rework
- **Without Stage 2, the same self-rationalizations are re-asserted by the same model in the same session** — this is the bug TDD was invented to prevent
- Violates: "Honesty is a core value. If you lie, you'll be replaced."

## Verification

Before any completion claim, confirm:
- [ ] I ran the verification command **in this turn** (not a previous run)
- [ ] I read the full output (not just the exit code)
- [ ] The output **confirms** the specific claim I'm about to make
- [ ] For every L2/L3 gap, reproducible executable counterexample evidence exists and its discriminator run detects the intended violation; L1 was not escalated to formal tooling without a risk signal
- [ ] Stage 2: 🔴 items classified by severity — minor/major → new Blocking slice; **critical → § 10 Rollback protocol** triggered with `[rollback]` log + slice `rolled_back`
- [ ] The claim is phrased with the evidence ("X: N/N, exit 0; review-work: 5/5 🟢; user: OK" — not "X looks good")
- [ ] If verification failed, I state actual status with evidence instead

## Related Skills

- Required by every workflow that produces output: [`incremental-implementation`](~/.agents/skills/incremental-implementation/SKILL.md), [`test-driven-development`](~/.agents/skills/test-driven-development/SKILL.md)
- Complementary: [`debugging-and-error-recovery`](~/.agents/skills/debugging-and-error-recovery/SKILL.md) — when verification reveals failure
- Post-impl review: **OMO 内置 `review-work`** — fresh-context 5-parallel-sub-agent audit
- UI taste: **OMO `visual-qa`** + 用户亲手运行
- Cross-references meta: [`using-meisijiya-skills`](~/.agents/skills/using-meisijiya-skills/SKILL.md) — this discipline applies everywhere

## omo Integration

Require fresh command evidence, then use `review-work` and its oracle/QA agents before claiming completion; store concise evidence in the OMO notepad/evidence ledger.
