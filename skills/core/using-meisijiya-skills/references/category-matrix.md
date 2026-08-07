# Category × Skill Matrix & Dispatch Reference

Dispatch reference for the `using-meisijiya-skills` dispatcher (loaded from
SKILL.md §Process / §Category × Skill Matrix cross-ref). SOT for the
`meisijiya-dispatch-gate` plugin's `RECOMMENDED` constant — when this matrix
changes, update `.opencode/plugins/meisijiya-dispatch-gate.js` to match.

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

## Security 5-lane review fan-out (validated 2026-07-31)

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

## Specialist agents (`subagent_type`)

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
