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

### The Gate Function

```
BEFORE any completion claim:

1. IDENTIFY: What command proves this claim?
2. RUN: Execute the FULL command (fresh, complete)
3. READ: Full output, check exit code, count failures
4. VERIFY: Does the output actually confirm the claim?
   - If NO → state actual status with evidence ("X failed at step Y")
   - If YES → state claim WITH evidence ("Tests pass: 34/34, exit 0")
5. ONLY THEN: Make the claim

Skip any step = lying, not verifying.
```

### Common Failures → Required Evidence

| Claim | Requires | NOT Sufficient |
|---|---|---|
| Tests pass | Test command output: 0 failures, exit 0 | Previous run, "should pass" |
| Linter clean | Linter output: 0 errors | Partial check, extrapolation |
| Build succeeds | Build command: exit 0 | Linter passing, logs look good |
| Bug fixed | Test original symptom: passes | Code changed, assumed fixed |
| Regression test works | Red-green cycle verified (write → fails → fix → passes) | Test passes once |
| Agent completed | VCS diff shows changes | Agent reports "success" |
| Requirements met | Line-by-line checklist against plan | Tests passing, "looks good" |
| Skill loaded | `ls ~/.agents/skills/<name>/SKILL.md` exists | Description matches |

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
- **ANY wording implying success without having run fresh verification this turn**

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

## Anti-Patterns

- ❌ "I've made the changes. Let me know if you have questions." (no verification, just chatter)
- ❌ "Tests should pass now." (no output)
- ❌ "Looks good." (no evidence)
- ❌ "Done!" (no specific evidence attached)
- ✅ "Tests pass: 34/34, exit 0. Build clean: tsc + vite build exit 0."

## Why This Matters

From real failure memories:
- Human partner: "I don't believe you" — trust broken
- Undefined functions shipped — would crash
- Missing requirements shipped — incomplete features
- Time wasted on false completion → redirect → rework
- Violates: "Honesty is a core value. If you lie, you'll be replaced."

## Verification

Before any completion claim, confirm:
- [ ] I ran the verification command **in this turn** (not a previous run)
- [ ] I read the full output (not just the exit code)
- [ ] The output **confirms** the specific claim I'm about to make
- [ ] The claim is phrased with the evidence ("X: N/N, exit 0" — not "X looks good")
- [ ] If verification failed, I state actual status with evidence instead

## Related Skills

- Required by every workflow that produces output: [`incremental-implementation`](~/.agents/skills/incremental-implementation/SKILL.md), [`test-driven-development`](~/.agents/skills/test-driven-development/SKILL.md)
- Complementary: [`debugging-and-error-recovery`](~/.agents/skills/debugging-and-error-recovery/SKILL.md) — when verification reveals failure
- Cross-references meta: [`using-meisijiya-skills`](~/.agents/skills/using-meisijiya-skills/SKILL.md) — this discipline applies everywhere