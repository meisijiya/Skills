---
name: ai-code-blindspots
description: "Reviews AI-generated or AI-modified code for blindspots that AI commonly omits — missing boundary checks (null/array), invisible error handling (empty catch / silent Promise rejection), environment compatibility (Node-only APIs in browser code / ES2022+ browser support), deprecated API usage (substr / UNSAFE_* / componentWillMount), and hardcoded configuration (URLs / tokens / secrets). Use when AI just generated or modified code and is in the verification stage, or when the agent itself suspects its own freshly-written code may have boundary / environment / error-handling omissions. NOT for manual review of hand-written code, pure style or text-only changes, code that has already been fully scanned by remove-ai-slops, or layer-specific landmines (frontend XSS / backend SQL injection / mobile WebView) → load `stack-security-coder` for per-stack coding checks. Load after verification-before-completion (core/, always installed). (token cost: medium — sub-agent scan + grep fallback)"
---

# ai-code-blindspots

## Overview

Catches the **omissions** AI is most likely to leave out when writing code — the things that compile, look correct in a quick read, and silently break at runtime or in production. Complements OMO's built-in [`remove-ai-slops`](https://github.com/code-yeongyu/oh-my-openagent) skill, which hunts **bloat / over-engineering / dead flexibility** (code that *should not exist*); this skill hunts **missing checks** (code that *should exist but doesn't*).

| Skill | Hunts | Example finding |
|---|---|---|
| `remove-ai-slops` | over-engineering, smells, bloat | "this abstraction has one implementation — delete it" |
| **`ai-code-blindspots`** (this) | missing checks, silent failures, deprecated calls | "this `.map()` is called on a possibly-undefined field — add a guard" |

The two skills do not overlap; running both back-to-back is the intended workflow. Each finds bugs the other structurally cannot.

**Output:** `ai-blindspots-report.md` in the caller workspace root, listing every finding with file:line + a one-line fix. Findings cite the checklist class (1-7 below) so the reader can audit coverage.

## When to Use

**Use when:**
- AI just generated or modified code (one or more `Write` / `Edit` tool calls this session), AND
- You are at the `verification-before-completion` gate and about to claim work complete, OR
- The agent itself suspects its freshly-written code may have boundary / environment / error-handling omissions, OR
- Reviewing a PR / diff where the commit history suggests AI assistance (`Co-authored-by: Cursor` / `Generated with Claude` / similar).

**NOT for:**
- Manual review of purely hand-written code (no AI involvement). The 7-class checklist is tuned for AI failure modes; human-written code has different omissions.
- Pure style / formatting / text-only changes (no executable logic touched).
- Code that has **already** been fully scanned by `remove-ai-slops` *and* the agent has re-verified boundary/error/deprecated items. Running both skills fully is fine — running this skill a second time after a clean pass is not.
- Bug *debugging* of an existing failure. Use [`debugging-and-error-recovery`](~/.agents/skills/debugging-and-error-recovery/SKILL.md) for that; this skill is **preventive review**, not incident response.

**Token note:** `(token cost: medium — sub-agent scan + grep fallback)`. Do not invoke speculatively. The sub-agent scan is the heavy part; the grep fallback is cheap. If the diff is empty, skip this skill entirely.

## Process

The skill runs in 5 steps. Steps 2 and 3 are the **two-layer scan** (LLM semantic + grep static); both must run. Step 4 is the report.

### 1. Determine scope

Pick the smaller of:
1. `git diff` from the last commit (or last N commits since the AI touched files) — preferred when in a git repo.
2. Caller-passed file list — fallback when no git or no commit exists.
3. All `.ts` / `.js` / `.py` / `.go` / `.rs` files touched by `Write` / `Edit` tool calls in this session — fallback when no caller list.

If all three fail, write `"scope: undetermined — no git diff, no caller list, no recent tool calls"` to the report header and stop. Do not guess.

### 2. Sub-agent scan (LLM semantic layer)

Dispatch a sub-agent (under omo: `task(category="deep", load_skills=["ai-code-blindspots"])`) over the scoped files with the 7-class checklist below. The sub-agent reads each file in full and flags suspicious patterns that grep cannot see (intent, missing-not-wrong, control flow across functions).

For each class, the sub-agent must report:
- file:line
- which AI omission pattern it matches
- a one-line concrete fix (not "consider checking" — show the guard)

### 3. Grep fallback (static layer)

After the sub-agent scan, run the grep patterns below against the same scope. These catch **mechanical** omissions the LLM may skip (regex-blind items: a single `process.env` in client code, an empty `catch {}`, an `UNSAFE_*` call). The grep layer is the safety net.

Run each pattern with `grep -rnE '<pattern>' <scope>` and filter out:
- Lines inside block comments (`/*... */`) and line comments (`//...` / `#...`).
- Lines inside test files matching `*.test.*` / `*.spec.*` / `__tests__/` / `*_test.*` — those are expected to probe error paths.
- Lines inside `node_modules/` / `.git/` / `dist/` / `build/` / `vendor/`.

For each grep hit, write a finding with the same file:line + fix format.

### 4. The 7-class checklist

This is the canonical list. Both sub-agent (Step 2) and grep (Step 3) must cover all 7.

#### Class 1 — Null / undefined boundaries

**What AI omits:** accessing fields that may be null/undefined, missing optional chaining, calling methods on values not validated to exist.

**LLM scan guidance (2-4 items):**
- Each `.<method>()` chain on a field — is every link null-safe?
- Destructured object fields used without default — e.g. `const { name } = user` where `user` may be undefined.
- Function parameters used without null check when caller is external (entry points).
- Return values used immediately without checking.

**Grep fallback patterns:**
- `(\.map\(|\.filter\(|\.forEach\(|\.find\(|\.reduce\()` — array methods on fields not visibly null-checked in the same expression.
- Look for `^[^/]*\?\.\w+` patterns that *bypass* guards — flag if used without context.

#### Class 2 — Array boundaries

**What AI omits:** indexing `[0]` without length check, calling `.first()` / `.head()` without emptiness check, assuming non-empty arrays.

**LLM scan guidance:**
- `[0]` / `[N]` index access on values not visibly length-checked.
- `.first()` / `.head()` / `.last()` calls without preceding emptiness check.
- `.pop()` / `.shift()` used without checking return value (returns `undefined` on empty).
- Loops over arrays assuming `i < arr.length` — fine if literal, suspicious if `arr[i].field` accessed before length check.

**Grep fallback patterns:**
- `(\[\s*0\s*\]|\.first\(\)|\.head\(\))` — first-element access without explicit length check.
- `(\.pop\(\)|\.shift\(\))` — returns undefined on empty.

#### Class 3 — Error visibility

**What AI omits:** empty `catch {}` blocks, `catch` that only `console.error`s, async functions throwing without try/catch upstream, swallowed rejections.

**LLM scan guidance:**
- `try {... } catch (e) {}` — empty body; the failure is invisible to caller.
- `catch (e) { console.error(e) }` — logged but not rethrown / not notified; caller has no signal.
- `async function` that may throw, called without `await` inside `try`.
- `Promise.then(success)` without `.catch()` — rejection unhandled.

**Grep fallback patterns** (best-effort static layer; LLM scan in Step 2 catches what these miss — see Process § 3 for the full safety-net story):
- `catch\s*(\([^)]*\))?\s*\{\s*\}` — empty catch body, including ES2019 optional-binding `catch {}` (the `(\(...\))?` makes the error-binding parens optional).
- `catch\s*(\([^)]*\))?\s*\{[\s\S]*?console\.(error|warn|log)[\s\S]*?\}` — catch that only logs (multi-line safe via `[\s\S]*?` lazy match; **run with `grep -Pz`** so the pattern can span newlines). Does NOT confirm whether error is rethrown downstream.
- `console\.(error|warn|log)\(` within 3 lines after `catch` keyword (heuristic fallback for multi-line matches).

#### Class 4 — Environment compatibility

**What AI omits:** Node-only APIs in browser code, ES2022+ syntax without target browser support, missing browserslist config.

**LLM scan guidance:**
- `fs.*` / `process.env` / `Buffer` / `__dirname` in files under `src/` / `client/` / `public/` / `browser/` paths.
- Top-level `await` / `??=` / private class fields (`#field`) without confirming target supports them.
- Importing `node:*` modules in non-Node code (frontend bundles, edge runtime, browser extensions).
- `crypto.randomUUID()` used in code targeting browsers < Chrome 92 / Safari 15.4.

**Grep fallback patterns:**
- `(^|[^a-zA-Z])(fs\.|process\.env|Buffer\.|__dirname|__filename)` — Node-only globals/APIs (covers inline usage).
- `require\(\s*['"](fs|node:fs|node:path|node:os|node:crypto)['"]\s*\)` — CJS `require('fs')` / `require('node:fs')` style.
- `import\s+.*\s+from\s+['"](fs|node:fs)['"]` — ESM `import {x} from 'fs'` style.
- `(\.at\(\)|\?\.|\?\?=|#\w+\s*=)` — modern syntax; verify target support.

**browserslist fallback:** if the project has no `browserslist` config (`.browserslistrc` / `package.json#browserslist`), the LLM scan's environment-compat sub-item is marked `unverified - no browserslist config` in the report. Grep patterns still run.

#### Class 5 — Deprecated API

**What AI omits:** calls to APIs marked deprecated, removed, or unsafe by the platform / framework.

**LLM scan guidance:**
- `substr()` (deprecated; use `substring()` / `slice()`).
- `escape()` / `unescape()` (deprecated for string escaping; use `encodeURIComponent`).
- `componentWillMount` / `componentWillReceiveProps` / `componentWillUpdate` (React legacy lifecycle).
- `UNSAFE_*` prefixed methods (React `UNSAFE_componentWillMount`, etc.).
- `new Buffer()` (use `Buffer.from()` / `Buffer.alloc()`).

**Grep fallback patterns:**
- `(\.substr\(|escape\(|unescape\()` — standard library deprecations.
- `(UNSAFE_|componentWillMount|componentWillReceiveProps|componentWillUpdate)` — React legacy.

#### Class 6 — Hardcoded configuration

**What AI omits:** URLs, API endpoints, secrets, tokens, credentials hardcoded as string literals.

**LLM scan guidance:**
- `https?://` URLs in non-config files (`*.config.*`, `.env*`, `src/config/`, `constants.*`).
- `sk-...` / `pk-...` style API keys (OpenAI, Stripe, etc.).
- `Bearer <token>` literals.
- DB connection strings with embedded passwords.
- URL hits in code are often false positives — examples, docs, comments. LLM scan must validate intent before flagging.

**Grep fallback patterns:**
- `https?://[a-zA-Z0-9./_-]+` — non-config-file URLs (filter out: comments via `grep -vE '^\s*(#|//|/\*|\*)'`; test fixtures via file-name glob `*.test.* / *.spec.* / __tests__ / __fixtures__`; localhost / 127.0.0.1 / 0.0.0.0). All hits reported as `[candidate]` (URLs in code are common false positives — examples, docs, comments).
- `sk-[a-zA-Z0-9]{20,}|pk-[a-zA-Z0-9]{20,}` — API key shapes. Reported as `[confirmed]` (rarely a false positive).
- `Bearer\s+[a-zA-Z0-9._-]{16,}` — bearer tokens in code (not env-var expansion). Reported as `[confirmed]`.

#### Class 7 — Invisible failures

**What AI omits:** `Promise.all([...])` without `allSettled` when any rejection aborts the whole batch silently, fire-and-forget promises, async IIFEs whose rejection is unhandled.

**LLM scan guidance:**
- `Promise.all([...])` where one rejection rejects all; consider `.allSettled` when partial success is acceptable.
- `async` IIFE (`(async () => {... })()`) called without `.catch()`.
- `setTimeout` / `setInterval` callback that throws synchronously inside an async body.
- `EventTarget.addEventListener('error',...)` without a matching `'unhandledrejection'` listener.

**Grep fallback patterns:**
- `Promise\.all\(` — flag when not paired with `.allSettled` consideration; LLM scan evaluates intent.
- `(\.catch\(\s*\(\s*\)\s*=>\s*\{\s*\}\s*\))` — empty arrow catch.

### 5. Write report

Output path: caller workspace root, file name `ai-blindspots-report.md`.

Report template:

```markdown
# AI Code Blindspots Report

- **Scope:** <git diff range | caller list | "undetermined">
- **Sub-agent:** <agent name + duration | "unavailable — grep-only mode">
- **Grep patterns run:** <count> / 7 classes covered
- **Findings:** <N> (<N_confirmed> confirmed + <N_candidate> candidate)

## Class 1 — Null / undefined boundaries
- `path/to/file.ts:42` [confirmed] — `<field>.map(...)` called on possibly-undefined `field`. Fix: `<field>?.map(...) ?? []`.
- `path/to/file.ts:51` [candidate] — `<field>` access without explicit guard; needs LLM review to confirm if surrounding context guarantees non-null.

## Class 2 — Array boundaries
-...

## Class N — <name>
-...

## Unverified
- `<browserslist missing | sub-agent timed out | git diff unavailable>` — class <X> coverage partial.
```

**Confidence tiers** (each finding carries one):
- `[confirmed]` — LLM semantic scan validated the grep hit as a real omission. Carries a concrete one-line fix.
- `[candidate]` — grep-only hit; needs LLM review to confirm. Listed separately so reviewers know what's still unvalidated. **In grep-only mode (sub-agent unavailable), every finding is `[candidate]` by default.**

Reporters must NEVER label a hit `[confirmed]` when running grep-only; reviewers must treat `[candidate]` findings as "possibly real" not "definitely real".

If the report cannot be written to disk (permissions / full disk), print the same template to stdout. Findings must not be lost.

## Common Rationalizations

| Excuse | Reality |
|---|---|
| "AI code looked clean in my read; no need to scan" | AI omissions are invisible to quick reads — that's the failure mode. `git diff` + the 7-class checklist catches what eyes miss. |
| "Sub-agent scan is too expensive; grep alone is fine" | Grep catches mechanical patterns; LLM catches intent (e.g. "this `await` is in a fire-and-forget"). Run both. |
| "The diff is tiny (5 lines), skip the skill" | 5-line diffs often have null guards / catch blocks omitted. Skill runs in seconds for small diffs. |
| "Already ran `remove-ai-slops`; double-scanning is wasteful" | `remove-ai-slops` hunts *bloat* (over-engineering). This skill hunts *omissions* (under-engineering). They cover different halves of the AI failure surface. |
| "Class 6 (hardcoded config) is a security job, not this skill" | Security tools (gitleaks / detect-secrets) only catch known-shape secrets in committed history. This skill catches them at write time, before commit. |
| "No browserslist means the project is Node-only; skip Class 4" | No `browserslist` field can also mean "we never configured it" — the report marks `unverified` and the reviewer decides. Don't silently skip. |
| "Empty catch is fine here because we intentionally swallow" | Maybe. Then add a comment that the skill grep will see and skip. Bare empty catch is indistinguishable from a bug — that's the problem. |
| "Will run this skill next time, this PR is already merged" | Next time = never. Run it now, on this diff, before declaring done. |
| "I'm reviewing my own AI output, I already know what I wrote" | You wrote what you intended; the skill hunts what you *didn't intend* — the omissions. Different lens. |

## Red Flags

- Report file is missing after the skill ran — findings were lost; retry.
- Sub-agent layer skipped with "time pressure" — fall back to grep-only and note it explicitly; don't claim full coverage.
- Class 4 (environment compat) marked "covered" when `browserslist` is absent — must be marked `unverified`.
- A `catch {}` empty body appears in the diff and is **not** flagged — the grep pattern was skipped or commented-out detection failed.
- Class 6 (hardcoded config) is skipped because "no security tooling installed" — this skill IS the tooling for the write-time case.
- The report lists 0 findings on a non-trivial diff (>50 lines) — re-run; either the scope was wrong or one of the layers failed silently.
- Findings lack file:line — they're not actionable; reject the report and re-run.
- The skill was invoked but no `git diff` / caller list / tool-call list was collected — scope is `undetermined`; that's a process failure, not a clean pass.
- Findings cite "consider adding" / "you might want to" — that's not a fix; reject and ask for the concrete change (e.g. "add `?.` after `<expr>`").

## Verification

- [ ] Scope determined from one of: `git diff`, caller-passed list, recent `Write`/`Edit` tool calls (or report marks `undetermined`).
- [ ] Sub-agent scan dispatched and completed (or grep-only fallback with explicit note).
- [ ] All 7 checklist classes covered (LLM + grep combined); Class 4 may be `unverified` if no browserslist.
- [ ] Each finding has `file:line` + one-line concrete fix (not "consider").
- [ ] `ai-blindspots-report.md` written to caller workspace root, OR printed to stdout if write failed.
- [ ] `bash scripts/validate-skills.sh` reports OK for `skills/extra/ai-code-blindspots/SKILL.md`.
- [ ] `bash scripts/check-marketplace.sh` reports OK (entry present in `.claude-plugin/marketplace.json`).
- [ ] Description length ≤ 1024 chars; SKILL.md ≤ 500 lines.

Run:

```bash
# Description budget
DESCRIPTION=$(grep -E '^description:' skills/extra/ai-code-blindspots/SKILL.md | head -1 | sed 's/^description:[[:space:]]*//' | tr -d '"')
echo "description length: ${#DESCRIPTION}"  # ≤ 1024

# File size budget
wc -l skills/extra/ai-code-blindspots/SKILL.md  # ≤ 500

# 7-class coverage in Process
for pat in 'Null / undefined' 'Array boundaries' 'Error visibility' 'Environment compat' 'Deprecated API' 'Hardcoded configuration' 'Invisible failures'; do
  grep -q "$pat" skills/extra/ai-code-blindspots/SKILL.md && echo "✓ $pat" || echo "✗ MISSING: $pat"
done

# Manifest sync
bash scripts/check-marketplace.sh  # OK
```

## omo Integration

Run the scan during the OMO verification handoff; attach findings to the evidence ledger and route unresolved risk to oracle or `review-work`.
## Related Skills

- **Upstream gate (always runs first):** [`verification-before-completion`](~/.agents/skills/verification-before-completion/SKILL.md) — two-stage verification; `ai-code-blindspots` is invoked **inside** its Process step (with install + executable-code guards) when AI touched executable code in the session.
- **Complementary coverage:** [`remove-ai-slops`](https://github.com/code-yeongyu/oh-my-openagent) (OMO built-in skill) — hunts bloat / over-engineering / dead flexibility. Run **independently** (in any order) on the same diff. The two together cover both halves of AI's failure surface; running both is the intended workflow, not running them in a strict sequence.
- **Dispatcher context:** [`using-meisijiya-skills`](~/.agents/skills/using-meisijiya-skills/SKILL.md) — Priority table points to this skill for AI-touched-code verification (Layer 2 soft-routing).
- **When a finding reveals an actual bug:** [`debugging-and-error-recovery`](~/.agents/skills/debugging-and-error-recovery/SKILL.md) — 5-step triage. If a Class 3 (error visibility) or Class 7 (invisible failures) finding surfaces a real runtime issue, escalate.
- **Pre-write prevention (orthogonal):** [`spec-driven-development`](~/.agents/skills/spec-driven-development/SKILL.md) — locking the spec upfront is the *preventive* counterpart to this skill's *detective* role. A complete spec catches omissions at design time; this skill catches what slips through at code-review time.
- **Security-class findings (Class 6):** [`security-and-hardening`](~/.agents/skills/security-and-hardening/SKILL.md) — application-layer trust-boundary hardening. If a Class 6 finding expands into a broader pattern (e.g. "we don't have any secret management"), route to security-and-hardening for a project-wide audit.
