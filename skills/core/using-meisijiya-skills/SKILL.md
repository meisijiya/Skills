---
name: using-meisijiya-skills
description: "Dispatcher meta-skill for the meisijiya-skills collection. Forces the agent to check applicable skills before every response, coordinate with oh-my-openagent's Sisyphus + IntentGate, and initialize OMO. Use when starting any session in a project where meisijiya-skills are installed, or when about to take any action on the user's behalf."
allowed-tools: "Read Bash Glob Grep"
---

<SUBAGENT-STOP>
If you were dispatched as a subagent to execute a specific task, ignore this skill.
</SUBAGENT-STOP>

<EXTREMELY-IMPORTANT>
If a Skill's description matches what you are about to do, you MUST invoke it before acting. If you are not sure whether a Skill applies, **stop and check the Skill catalog first**; do not default to skipping.

**IMPORTANT**: When dispatching sub-agents via `task()`, ALWAYS pass the COMPLETE `load_skills` set from the Category × Skill Matrix main table — never `[]` for matrix-mapped categories. The dispatch-gate plugin will console.warn if you pass an incomplete list.

This is not optional. Skills encode team-validated discipline; bypassing them because "this is simple" is exactly when they matter.
</EXTREMELY-IMPORTANT>

## Overview

Meta dispatcher. Hard-injected every session by the OpenCode plugin (`~/.config/opencode/plugins/meisijiya-skills.js`) so the model actively invokes skills instead of letting them sit in `<available_skills>`. Coordinates with omo Sisyphus + IntentGate; this skill does NOT do work — it routes.

## Relationship to OMO IntentGate (prompt-only)

- **OMO Intent Gate:** prompt text asks Sisyphus to self-report one of six labels and select an agent; no durable semantic intent record exists (`sisyphus/default.ts:200-213`; `intent-diff.md` I3, status `partial`; *"No runtime semantic classifier was found in inspected sources."*).
- **meisijiya dispatcher:** after that selection, this `SKILL.md` and `priority-table.md` decide whether a meisijiya skill applies; `(no skill)` never overrides OMO.
- **Bootstrap plugin:** `meisijiya-skills.js:113-132` injects this dispatcher into `firstUser.parts`; the `EXTREMELY_IMPORTANT` marker guard makes re-injection idempotent after compaction. It is a meisijiya-owned OpenCode plugin, not an OMO agent, hook, or classifier.

These are existing prompt/injection layers, not a new lifecycle stage, phase, or intent-state object. Keyword-mode detection remains a separate mechanism.

## When to Use

**Use when:**
- Starting any session in a project where meisijiya-skills are installed (you're in one right now)
- About to take any action on the user's behalf — every turn, before responding

**NOT for:**
- Sub-agents (you were dispatched to execute a specific task; ignore this skill — the controller should not have forwarded it)
- Executors — receive domain-specific skills in the dispatch prompt, NOT this dispatcher

## Process

1. **Check `.omo/handoff/` for unconsumed documents** (cross-session resumption). If any `.md` file has `consumed: false` in frontmatter, this takes precedence over trigger matching — user expects `RESUME FROM PHASE <to_phase>`, not fresh routing. Inject a `<RESUME FROM PHASE <to_phase>>` block to firstUser.parts and auto-append the doc's `load_skills` to sub-agent dispatch per Sisyphus Dispatch Protocol. Wait for user to type `consumed` (mark `consumed: true`) or `consume --reject <reason>` (skip) before proceeding. See [`meisijiya-handoff`](~/.agents/skills/meisijiya-handoff/SKILL.md) for the cross-session protocol.
2. Consult `<available_skills>` (injected by the harness) for the current session's skill roster + each skill's `description`.
3. Match the incoming request against each skill's `description` field. The `description` is the source of truth for routing.
4. For cross-skill trigger hints (one row per common request pattern), read [`references/priority-table.md`](references/priority-table.md).
5. For multi-stage work sequences (design → spec → impl → test → review; fix; ship; perf gate; etc.), read [`references/process-chains.md`](references/process-chains.md).
6. For the sub-agent controller/executor split, read [`references/controller-executor.md`](references/controller-executor.md). For agent / category selection by task type, read [`references/model-selection.md`](references/model-selection.md).
7. Announce **"Using [skill] to [purpose]"** when invoking, and follow the invoked skill's checklist exactly.
8. **When delegating to sub-agents, follow the Sisyphus Dispatch Protocol below** — always specify the COMPLETE `load_skills` set from the Category × Skill Matrix main table (Hard Rule). If the dispatch-gate plugin warns "matrix recommends X" while you have an existing list, evaluate whether X is missing and add it.

## Sisyphus Dispatch Protocol

When delegating to sub-agents, ALWAYS specify both the routing axis (`category` OR `subagent_type`) AND `load_skills=[...]`. The sub-agent will see the skill in `<available_skills>`, but explicit loading forces it to read SKILL.md body and follow the discipline — without it, sub-agents often miss narrow-trigger skills.

### Hard Rule (mandatory)

Always pass the COMPLETE `load_skills` set from the Category × Skill Matrix main table below —
never an empty or partial list for a matrix-mapped category. Exceptions: categories the matrix
explicitly maps to `[]` (`quick`, `unspecified-low`, `artistry`). Never exceed 3 skills (Red Flags);
when a scenario needs more, expand via Common Dispatch Scenarios, not the matrix cell.

### Pattern 1 — `category`-based dispatch (most common)

```typescript
task(
  category: "<category>",
  load_skills: ["<skill-name>", ...],
  prompt: "..."
)
```

### Pattern 2 — `subagent_type` dispatch (specialist agents)

```typescript
task(
  subagent_type: "<oracle|librarian|explore>",
  load_skills: ["<skill-name>", ...],
  prompt: "..."
)
```

### Why `load_skills` matters

Without it, the sub-agent may:
- Skip reading SKILL.md body (only sees the description in `<available_skills>`)
- Drift toward generic output (no discipline anchor)
- Miss narrow-trigger skills entirely (e.g., `meisijiya-frontend-taste` triggers only on UI code, easy to miss)

With it, the sub-agent's instructions explicitly include the skill body, and routing is unambiguous.

## Category × Skill Matrix

Use this matrix to choose `load_skills=[...]` based on the task's category. (Categories from omo orchestration schema.) The default model for each category is selected by OMO at runtime — do NOT hardcode a model name here; the matrix is about category → skill routing, not model selection.

Legend: `Main` = base bundle · `+X` = additive modifier · `→X` = substitute (mutually exclusive with Main)

| Category | When to use | Recommended `load_skills` |
|---|---|---|
| `visual-engineering` | UI/UX code (React/Vue/Svelte/Tailwind) | Main: `["meisijiya-frontend-taste"]`; +`"meisijiya-minimalist-ui"` (Linear/Notion/editorial brief); →`"meisijiya-redesign-ui"` (existing UI audit-fix, see Scenarios §3) |
| `ultrabrain` | Hard logic, architecture, complex debugging | `["api-and-interface-design"]` / `["security-threat-model"]` / `["performance-optimization"]` (pick 1) |
| `deep` | Autonomous deep implementation | Main: `["incremental-implementation"]`; +`"test-driven-development"` (TDD-required) |
| `quick` | Trivial single-file changes (typo / rename) | `[]` (don't load skills — overhead > benefit) |
| `unspecified-low` | General standard work | `[]` (default is fine); add `["prototype"]` only if task has `[PROTO-RESOLVE]` markers |
| `unspecified-high` | Complex general work | `["debugging-and-error-recovery"]` for bug hunts, `["writing-skills"]` for skill creation |
| `writing` | Documentation, prose, articles | `["verify-chain"]` if fact-checking claims |
| `artistry` | Creative / unconventional approaches | (rarely needed) |

### Security 5-lane review fan-out (validated 2026-07-31)

When Sisyphus / orchestrator dispatches the OMO `review-work` 5-lane scheme (or a custom 5-lane security audit), the `load_skills` for each lane has been validated against the 9 meisijiya security skills:

| Lane (OMO 5-lane name) | `subagent_type` / `category` | Validated `load_skills` | Trigger condition |
|---|---|---|---|
| Security Oracle | `subagent_type="oracle"` | `["security-threat-model", "security-and-hardening", "security-incident-response", "ai-code-blindspots"]` | Trust-boundary-crossing code; multi-tenant / auth / secrets change; pre-merge of security-critical diff |
| Code Quality Oracle | `subagent_type="oracle"` | `["ai-code-blindspots", "stack-security-coder", "security-and-hardening"]` | AI-generated or AI-touched diff; frontend/backend/mobile layer change; `meisijiya-review-router` matchPath on `.tsx`/`.vue`/`.svelte`/`.swift`/`.dart` |
| QA Execution | `category="unspecified-high"` | `["gha-security-review", "security-devsecops", "security-threat-model"]` | `.github/workflows/*` change; Dockerfile / terraform / k8s manifest change; lockfile / dependency-tree change; pre-deploy gate |
| Context Mining | `category="unspecified-high"` | `["security-ownership-map", "supply-chain-risk-auditor", "ai-code-blindspots"]` | New dependency added; lockfile quarterly review; bus-factor / sensitive-code ownership question; post-incident ownership re-mapping |
| Slice Review (per-slice) | `subagent_type="oracle"` | `["verification-before-completion", "security-and-hardening", "ai-code-blindspots"]` (security variant — see `slice-review` skill § 2a) | Per-slice dispatch via `slice-review` skill; default `load_skills=[]` only for non-trust-boundary slices |

Each `load_skills` set was validated by 5 parallel sub-agents in a 2026-07-31 review pass; the load_skills combinations cover all 5 lifecycle phases (design → code → pre-merge → pre-deploy → prod) and provide reviewer discipline anchoring (per the Sisyphus Dispatch Protocol above).

**Pairing rule**: `meisijiya-frontend-taste` + `meisijiya-minimalist-ui` is intentional; `meisijiya-frontend-taste` + `meisijiya-redesign-ui` is NOT (one is greenfield, the other audit-fix). For security: `security-and-hardening` + `ai-code-blindspots` is the canonical "AI wrote this code" pair. `gha-security-review` + `security-devsecops` is the canonical "CI/CD touched" pair (gha = file-level, devsecops = pipeline-level).

### Specialist agents (`subagent_type`)

| subagent_type | Purpose | Recommended `load_skills` |
|---|---|---|
| `oracle` | Read-only consultation (architecture / debug / threat-model) | `["api-and-interface-design"]` / `["security-threat-model"]` / `["debugging-and-error-recovery"]` / `["diagnosing-bugs"]` (pick 1 matching the question) |
| `librarian` | Doc / OSS search | `["source-driven-development"]` (always — it enforces API verification) |
| `explore` | Codebase grep | `[]` (already fast, skill overhead wasted) |

## Common Dispatch Scenarios

(formerly Common Dispatch Patterns — kept for grep-compatibility during migration)

### Marketing frontend / UI code

→ see matrix row: `visual-engineering`

```typescript
task(
  category: "visual-engineering",
  load_skills: ["meisijiya-frontend-taste"],
  prompt: "Build the landing page for [brief]"
)
```

### Linear/Notion aesthetic

→ see matrix row: `visual-engineering` (+modifier)

```typescript
task(
  category: "visual-engineering",
  load_skills: ["meisijiya-frontend-taste", "meisijiya-minimalist-ui"],
  prompt: "Build a Linear-style settings page for [brief]"
)
```

### Existing UI audit-then-fix

→ see matrix row: `visual-engineering` (→modifier; mutually exclusive with Main)

```typescript
task(
  category: "visual-engineering",
  load_skills: ["meisijiya-redesign-ui"],
  prompt: "Audit and fix the React checkout UI in [path]"
)
```

### Spec-level visual decision (Phase 1.2)

→ see matrix row: `unspecified-low` (PROTO-RESOLVE marker)

```typescript
task(
  category: "unspecified-low",
  load_skills: ["prototype"],
  prompt: "Generate 3 layout variants for [PROTO-RESOLVE: button placement]"
)
```

### Multi-session scope (wayfinder)

→ see Specialist agents table (`subagent_type="general"`)

```typescript
// wayfinder triggers automatically via description; explicit load only for spec-level clarity
task(load_skills: ["wayfinder"], prompt: "Plan a 3-day refactor across [modules]")
```

### Plan-phase high-trust research

→ see Specialist agents table (`subagent_type="general"`)

```typescript
// research triggers automatically via description; explicit load only for spec-level clarity
task(load_skills: ["research"], prompt: "Investigate the OpenCode skill loading mechanism")
```

## Common Rationalizations

| Thought | Reality |
|---|---|
| "This is just a simple question" / "Let me explore first" / "I can check files quickly" | Questions are tasks. Skills tell you HOW to explore. Files lack conversation context. |
| "This doesn't need a formal skill" / "I remember this skill" / "The skill is overkill" | If a Skill exists, use it. Skills evolve — read current version. Simple things become complex. |
| "I'll just do this one thing first" / "This feels productive" | Check BEFORE doing anything. Undisciplined action wastes time. |
| "1% chance applies, must load" | Only invoke when description matches; "not sure" still requires checking the catalog, but not loading every adjacent Skill. |
| "The sub-agent will figure it out from `<available_skills>`" | It won't. Description triggers are too weak for narrow skills. Explicit `load_skills=[...]` is the contract. |
| "I'll just dispatch without `load_skills`, simpler" | Sub-agent drifts toward generic output without the discipline anchor. Your dispatch is wasted. |

## Red Flags

- Invoking `using-meisijiya-skills` from a sub-agent (means the controller forgot to filter — see `<SUBAGENT-STOP>`).
- Reading skill SKILL.md files when the description alone would suffice (wastes tokens — read on demand after description match).
- Treating the Priority table as authoritative (it's a hint accelerator; the `description` field wins).
- Skipping the announce step — without "Using [skill] to [purpose]" the user can't see the routing.
- **Dispatching without `load_skills=[...]`** — sub-agent may miss the skill's discipline or skip its constraints.
- **Overloading `load_skills` (>3 skills per dispatch)** — context bloat kills quality; load only what's strictly needed.
- **Loading conflicting skills** — `meisijiya-frontend-taste` + `meisijiya-minimalist-ui` together is intentional pairing (minimalist-ui narrows frontend-taste); `meisijiya-frontend-taste` + `meisijiya-redesign-ui` is NOT (frontend-taste = greenfield; redesign-ui = existing UI audit-fix).

## Plugin layer (where this bootstrap comes from)

This SKILL.md is injected into firstUser.parts each session — see `meisijiya-skills.js:113-132` (Editing rules below).

- `~/.config/opencode/plugins/meisijiya-skills.js` reads this `SKILL.md` on session start, strips frontmatter, wraps in `<EXTREMELY-IMPORTANT>`, and `unshift`s into `firstUser.parts` once per session (idempotent against compaction re-fires).
- `~/.config/opencode/plugins/meisijiya-review-router.js` injects per-Edit reminders for `ai-code-blindspots` + `security-and-hardening` + `verification-before-completion` after `write` / `edit` / `apply_patch` (deduped per turn).

**Editing rules** — Changes to `SKILL.md` do **not** auto-reload; OpenCode plugins load once at process start. Restart OpenCode after editing. If `<EXTREMELY-IMPORTANT>` is missing, the bootstrap plugin is not installed — fix the install before assuming this skill is active.

## User Instructions

User instructions (AGENTS.md, direct requests) take precedence over skills, which override default behavior. Only skip skill workflows when your human partner has explicitly told you to.

## Verification

Before responding, confirm:
- [ ] You have either invoked a matching skill OR explicitly stated no skill matches
- [ ] You announced "Using [skill] to [purpose]" when invoking
- [ ] The invoked skill's `allowed-tools` covers the tools you need (otherwise escalate)
- [ ] For sub-agent dispatches: `load_skills=[...]` is specified (consult Category × Skill Matrix)