# meisijiya-skills — Agent Context

> **What this file is**: A self-contained agent context file for the `meisijiya-skills` repo.
>
> - **For users**: **Section A** is what `scripts/inject-agents-md.sh` injects into YOUR project's `AGENTS.md`. You can also manually copy Section A content.
> - **For contributors**: **Section B** documents how to add new skills to this repo.
> - **For AGENTS.md writers**: Writing rules (no version narrative, no historical comparisons, etc.) are in [`docs/agents-md-guide.md`](./docs/agents-md-guide.md). Apply to user-level, project-level, and Section A.
> - **For agents reading this repo**: This whole file is context.

---

## Section A: Skill catalog

The block between the sentinel markers below is what `scripts/inject-agents-md.sh` extracts and appends (with its own markers) to your `~/.config/opencode/AGENTS.md`. To copy manually, copy everything between the markers.

<!-- meisijiya-skills:start -->

## meisijiya-skills

Use this skill system for the omo stack. Invoke skills by matching their `description` field against the user's request; do not invoke skills that don't match.

These conventions apply globally unless a project-level AGENTS.md overrides them.

### Discipline layer

Before any completion claim (commit, PR, "done", "fixed"), invoke [`verification-before-completion`](~/.agents/skills/verification-before-completion/SKILL.md). Evidence before claims, always.

### Catalog

**.core/ — load always (8):**
- [`using-meisijiya-skills`](~/.agents/skills/using-meisijiya-skills/SKILL.md) — meta dispatcher; check before every response
- [`brainstorming`](~/.agents/skills/brainstorming/SKILL.md) — pre-design exploration (HARD-GATE: no implementation before user-approved design)
- [`spec-driven-development`](~/.agents/skills/spec-driven-development/SKILL.md) — spec before non-trivial code
- [`incremental-implementation`](~/.agents/skills/incremental-implementation/SKILL.md) — vertical slices (≤ 100 lines each) with dependency/HITL-AFK metadata
- [`test-driven-development`](~/.agents/skills/test-driven-development/SKILL.md) — red-green-refactor
- [`verification-before-completion`](~/.agents/skills/verification-before-completion/SKILL.md) — no completion claims without fresh evidence; two-stage gate (in-session + OMO `review-work`)
- [`debugging-and-error-recovery`](~/.agents/skills/debugging-and-error-recovery/SKILL.md) — 5-step triage (reproduce / localize / reduce / fix / guard)
- [`diagnosing-bugs`](~/.agents/skills/diagnosing-bugs/SKILL.md) — symptom-driven diagnosis loop (≥3 hypotheses + distinguishing observation per hypothesis + cheapest observation first); pairs with `debugging-and-error-recovery` as protocol ↔ discipline
- [`source-driven-development`](~/.agents/skills/source-driven-development/SKILL.md) — verify API against official docs

**security (6):**
- [`security-and-hardening`](~/.agents/skills/security-and-hardening/SKILL.md) — application-layer trust-boundary hardening; depth audit via OMO `security-research`
- [`security-devsecops`](~/.agents/skills/security-devsecops/SKILL.md) — supply chain + deploy pipeline (deps / SBOM / secrets rotation / CI/CD / IaC / pre-deploy); OMO `security-research` + `oracle` + `websearch` + `context7`
- [`security-incident-response`](~/.agents/skills/security-incident-response/SKILL.md) — post-incident (NIST CSF simplified: detect / triage / contain / eradicate / recover / postmortem); OMO `security-research` post-PoC + `oracle` decision + `websearch` IOC
- [`ai-code-blindspots`](~/.agents/skills/ai-code-blindspots/SKILL.md) — AI-generated code blindspots (boundary checks / silent error handling / env compatibility / deprecated API / hardcoded config / invisible failures); complements OMO `remove-ai-slops`
- [`gha-security-review`](~/.agents/skills/gha-security-review/SKILL.md) — GitHub Actions workflow security audit (action permission / expression injection / unpinned actions / workflow_run / artifact poisoning); each finding ships with concrete exploit scenario
- [`security-threat-model`](~/.agents/skills/security-threat-model/SKILL.md) — AppSec-grade threat model (trust boundaries + STRIDE + attacker profile + file:line citations + prioritized mitigations); precedes `security-and-hardening` on design / 3rd-party-integration / blast-radius expansion
- [`security-ownership-map`](~/.agents/skills/security-ownership-map/SKILL.md) — git-history people↔file topology surfacing orphan sensitive code / hidden owners / bus-factor hotspots / maintainer concentration; precedes major refactors + post-incident governance
- [`supply-chain-risk-auditor`](~/.agents/skills/supply-chain-risk-auditor/SKILL.md) — dependency trustworthyness audit (single-maintainer / abandoned-repo / low-popularity / identity hygiene / social-engineering); precedes `security-devsecops` for security-critical paths + quarterly governance
- [`stack-security-coder`](~/.agents/skills/stack-security-coder/SKILL.md) — layer-specific coding checklists (frontend XSS-CSP-cross-origin / backend SQL-NoSQL-authz-SSRF-webhook / mobile WebView-certs-storage-biometric); complements OMO `remove-ai-slops` + `ai-code-blindspots` for per-stack landmines

**ci-cd (2):**
- [`pre-ship-gate`](~/.agents/skills/pre-ship-gate/SKILL.md) — pre-deploy read-only audit + post-deploy smoke verification that catches 'deploy exit 0 ≠ actually running' (migrations / feature flags / CDN / canary / env / shadow traffic); allowed-tools read-only
- [`closed-loop-delivery`](~/.agents/skills/closed-loop-delivery/SKILL.md) — 5-gate evidence chain (implemented / reviewed / deployed / healthy-at-runtime / reachable-by-users) so 'done' means running safely in production, not just merged

**observability (4):**
- [`observability-and-instrumentation`](~/.agents/skills/observability-and-instrumentation/SKILL.md) — log/metrics/tracing for production visibility
- [`performance-optimization`](~/.agents/skills/performance-optimization/SKILL.md) — measure-first backend profile + optimization; frontend CWV routed to OMO `frontend`
- [`k6-load-testing`](~/.agents/skills/k6-load-testing/SKILL.md) — pre-deploy performance acceptance gate (smoke / load / stress / spike / soak) with explicit latency-percentile + error-budget thresholds; pairs with `performance-optimization` as front-back
- [`production-incident-playbook`](~/.agents/skills/production-incident-playbook/SKILL.md) — end-to-end incident handling (in-flight runbook phases + blameless postmortem templates with 5-whys root-cause + structural action items); pairs with `pre-ship-gate` as front-back

**meta (3):**
- [`writing-skills`](~/.agents/skills/writing-skills/SKILL.md) — TDD-for-docs for skills; meta-only, lives here not in `core/`
- [`contract-strengthening`](~/.agents/skills/contract-strengthening/SKILL.md) — open-world / non-exhaustive contract review (Phase 1.25 optional extra; complements `spec-driven-development` + `verification-before-completion`)
- [`slice-review`](~/.agents/skills/slice-review/SKILL.md) — per-slice lightweight reviewer (spec compliance + code quality, 2 verdicts); complements OMO `review-work` (whole-branch 5-lane)
- [`test-guard`](~/.agents/skills/test-guard/SKILL.md) — 7-check AI-test quality audit (skip-detection / over-mocking / tautology / boundary / fake-deps / lazy-assert / flakiness); pairs with `test-driven-development` to enforce tests actually test something

**domain (7):**
- [`build-gate-visual-review`](~/.agents/skills/build-gate-visual-review/SKILL.md) — pre-build design alignment; default Markdown, HTML deck only on explicit visual/teaching request
- [`designer-handoff`](~/.agents/skills/designer-handoff/SKILL.md) — designer → eng UI/UX spec handoff via `ui-ux-pro-max`
- [`api-and-interface-design`](~/.agents/skills/api-and-interface-design/SKILL.md) — contract-first REST / GraphQL / RPC design
- [`documentation-and-adrs`](~/.agents/skills/documentation-and-adrs/SKILL.md) — architectural ADRs only (data model / API contracts / dependency upgrades / deprecations)
- [`improve-codebase-architecture`](~/.agents/skills/improve-codebase-architecture/SKILL.md) — codebase-wide health scan via Ousterhout deep/shallow scoring; proposal-only
- [`verify-chain`](~/.agents/skills/verify-chain/SKILL.md) — 3-role article fact-check pipeline (Critic → Verifier × N → Repairer); OMO `general` agent for parallel Verifier subagents
- [`loop-me`](~/.agents/skills/loop-me/SKILL.md) — extract a repeated workflow into an executable spec; output feeds OMO `/goal` or `incremental-implementation`

(Group counts auto-derive from `.claude-plugin/marketplace.json` on each `scripts/inject-agents-md.sh` run; manifest ↔ files bidirectional check via `scripts/check-marketplace.sh`.)

### Skill chains (process order)

Most work follows a process chain. Invoke skills in order:

1. [`brainstorming`](~/.agents/skills/brainstorming/SKILL.md) — design before implementation (HARD-GATE)
2. [`spec-driven-development`](~/.agents/skills/spec-driven-development/SKILL.md) — formalize design
3. [`incremental-implementation`](~/.agents/skills/incremental-implementation/SKILL.md) — vertical slices
4. [`test-driven-development`](~/.agents/skills/test-driven-development/SKILL.md) — red-green-refactor (per slice)
5. [`verification-before-completion`](~/.agents/skills/verification-before-completion/SKILL.md) — before any completion claim

[`writing-skills`](~/.agents/skills/writing-skills/SKILL.md) is invoked separately when adding/editing skills OR extracting a repeated workflow into a reusable skill.

### omo integration

For the reverse map (omo feature → skills that use it), see the `meisijiya-extras` block above. Skills use:

- [`source-driven-development`](~/.agents/skills/source-driven-development/SKILL.md) — context7 MCP (primary), grep_app MCP
- [`debugging-and-error-recovery`](~/.agents/skills/debugging-and-error-recovery/SKILL.md) — oracle agent (escalation), lsp MCP
- [`incremental-implementation`](~/.agents/skills/incremental-implementation/SKILL.md) — git-master skill, atlas agent, `/start-work` trigger, OMO `review-work` post-impl
- [`designer-handoff`](~/.agents/skills/designer-handoff/SKILL.md) — visual-engineering category, frontend-ui-ux skill
- [`build-gate-visual-review`](~/.agents/skills/build-gate-visual-review/SKILL.md) — visual-engineering runtime child + frontend-ui-ux + html-ppt for explicit visual/teaching decks
- [`security-and-hardening`](~/.agents/skills/security-and-hardening/SKILL.md) + [`security-devsecops`](~/.agents/skills/security-devsecops/SKILL.md) + [`security-incident-response`](~/.agents/skills/security-incident-response/SKILL.md) — security-research mode (3 hunters + 2 PoC engineers)
- [`gha-security-review`](~/.agents/skills/gha-security-review/SKILL.md) — `oracle` agent for "is this permissions: block actually minimal?" judgment calls + `grep_app` MCP for known-bad action patterns across GitHub
- [`verification-before-completion`](~/.agents/skills/verification-before-completion/SKILL.md) — OMO `review-work` (Stage 2) + `visual-qa` (UI Taste gate)
- [`verify-chain`](~/.agents/skills/verify-chain/SKILL.md) — `general` agent for parallel Verifier subagents (web research + independent context)
- [`performance-optimization`](~/.agents/skills/performance-optimization/SKILL.md) — `analyze` mode, lsp MCP for large-codebase bottleneck tracing
- [`using-meisijiya-skills`](~/.agents/skills/using-meisijiya-skills/SKILL.md) — Sisyphus (executing delegation), atlas (todo orchestration), IntentGate routing
- [`brainstorming`](~/.agents/skills/brainstorming/SKILL.md) — in-context counterpart of Prometheus Mode (Tab / `@plan`); omo users may prefer Prometheus for multi-day projects
- [`spec-driven-development`](~/.agents/skills/spec-driven-development/SKILL.md) — Spec/PRD pre-Prometheus-plan; Momus reviews the plan, not the Spec
- [`contract-strengthening`](~/.agents/skills/contract-strengthening/SKILL.md) — optional extra for open-world contract/state/timing/concurrency/boundary/reversibility risk review (Phase 1.25 between attested Spec and implementation); complements core `spec-driven-development` + `verification-before-completion`; resource/isolation-first with consent-gated global-install exception; external verifiers never auto-installed; makes no correctness guarantee
- [`loop-me`](~/.agents/skills/loop-me/SKILL.md) — output spec handed to OMO `/goal <objective>` for continuous execution
- [`improve-codebase-architecture`](~/.agents/skills/improve-codebase-architecture/SKILL.md) — codebase-wide counterpart of per-diff OMO `refactor` / `ponytail-review` / `remove-ai-slops`
- [`ai-code-blindspots`](~/.agents/skills/ai-code-blindspots/SKILL.md) — catches AI-generated code blindspots (boundary checks / silent error handling / env compatibility / deprecated API / hardcoded config / invisible failures); complements OMO `remove-ai-slops` (which hunts over-engineering); soft-routes via `verification-before-completion` Process step + 4-layer dispatcher Priority chain

**No direct omo bridge** (yet):
- [`observability-and-instrumentation`](~/.agents/skills/observability-and-instrumentation/SKILL.md) — `oracle` agent could design SLI/SLO targets; tracked as future enhancement

### Conventions

- Don't ship code without spec + tests
- Verify before claiming completion (use [`verification-before-completion`](~/.agents/skills/verification-before-completion/SKILL.md))
- When you notice a repeated workflow, capture it as a skill (use [`writing-skills`](~/.agents/skills/writing-skills/SKILL.md))

<!-- meisijiya-skills:end -->

---

## Section B: Adding skills (contributor guide)

When adding a new skill to this repo, follow the conventions in [`skill-anatomy.md`](./skill-anatomy.md). Key requirements:

- **YAML frontmatter**: `name` (must match directory) + `description` (≤1024 chars, third-person, "what" + "Use when"). **Do not** include workflow summary in description (let the agent read the full file).
- **6 standard sections**: Overview / When to Use (with NOT for) / Process / Common Rationalizations (table) / Red Flags (list) / Verification (checkboxes with evidence requirements).
- **`## omo Integration` section**: Map the skill to an OMO capability (Prometheus plan, Boulder, task, notepad, evidence ledger, start-work, review-work, compaction-context-injector, or omo agent/category).
- **≤ 500 lines**: Move reference material to supporting files.
- **`allowed-tools`**: Specify in frontmatter when the skill needs tool restrictions.
- **Eval case**: Add `evals/cases/<skill-name>.json` with 3 positive triggers + 3 negative triggers + ≥ 1 behavioral scenario.
- **Marketplace manifest** (`.claude-plugin/marketplace.json`): Every new skill must add its path to the corresponding plugin entry's `skills[]` array. `npx skills add` groups by `pluginName`, not by directory. The 5 non-core plugin entries map to logical groups: `meisijiya-security` / `meisijiya-cicd` / `meisijiya-observability` / `meisijiya-meta` / `meisijiya-domain`. Pick the group whose existing members share the same audience and stage in the dev lifecycle. See `skill-anatomy.md` for the full convention. CI `scripts/check-marketplace.sh` enforces this.
- **Adding a new group** (rare; only when a category is genuinely missing): add the plugin entry in `.claude-plugin/marketplace.json`, append the suffix to `GROUP_SUFFIXES` in `scripts/inject-agents-md.sh`, and add a `**<group> (N):**` header block in Section A. The count auto-derives on each inject.
- **omo integration** (if applicable): Reference relevant omo MCPs / agents / built-ins. See any existing skill's Process section for the format.
- **Section A counts auto-derive**: The `(N)` numbers in Section A (`load always` / `<group>`) are auto-replaced by `scripts/inject-agents-md.sh` from `.claude-plugin/marketplace.json` on each inject. Source numbers may drift; the rendered block always reflects the current manifest.

Existing skills are the reference. When in doubt, copy a similar skill's structure (e.g., [`test-driven-development`](~/.agents/skills/test-driven-development/SKILL.md) for the canonical 6-section pattern).

For multi-harness compatibility, the skill should be readable even without omo installed. Reference them, but don't hard-depend on their presence.

---

## Section C: AGENTS.md supplement conventions (user guide)

When `scripts/inject-agents-md.sh` injects into your project's `AGENTS.md`, it appends a block between `<!-- meisijiya-skills:start -->` and `<!-- meisijiya-skills:end -->` markers. These sentinel markers make the script idempotent (re-running won't duplicate).

**Recommended project layout for YOUR `AGENTS.md`:**

```markdown
# <Your Project Name>

<Project-specific context — what is this project, what's the agent's role here>

## Tech stack
...

## Conventions
...

<!-- meisijiya-skills:start -->
[Injected by meisijiya-skills/scripts/inject-agents-md.sh — do not edit]
<!-- meisijiya-skills:end -->

## Project-specific skills

<Your project's domain-specific skills, conventions, etc.>
```

Three sections, top-to-bottom:
1. **Project context** (top) — agent reads first, knows the project
2. **meisijiya-skills block** (middle, injected) — agent knows what skills are installed
3. **Project-specific** (bottom) — your domain knowledge, custom conventions

### Skill reference convention (project-level)

When your project's `AGENTS.md` (or any project doc) references a skill by name, **include the install path as a markdown link**:

```markdown
- [`spec-driven-development`](~/.agents/skills/spec-driven-development/SKILL.md) — spec before code
```

**Why**: AI can find the skill at runtime after `npx skills add`. Without the path, AI guesses or fails to load.

**Failure detection** — when a skill breaks (renamed, deleted, upstream drift), broken refs surface at runtime:
```bash
# Check that all skill references in your AGENTS.md resolve to installed paths
grep -oE '~\/\.agents\/skills\/[a-z0-9-]+\/SKILL\.md' .opencode/AGENTS.md | \
  while read path; do
    [ -f "$path" ] || echo "BROKEN REF: $path"
  done
```

**Periodic check** — re-run `validate-skills.sh` + `check-marketplace.sh` from the meisijiya-skills repo to catch upstream drift:
```bash
git clone https://github.com/meisijiya/Skills /tmp/mjs-check
bash /tmp/mjs-check/scripts/validate-skills.sh
bash /tmp/mjs-check/scripts/check-marketplace.sh
```

**Convention is enforced by AI behavior, not tooling** — the agent reads your AGENTS.md and looks up paths. Without paths, the agent has no way to know where the skill actually lives on disk.

### Common operations

| Operation | Command |
|---|---|
| Inject block (first time or after remove) | `scripts/inject-agents-md.sh` |
| Inject into a specific path | `scripts/inject-agents-md.sh --target <path>` |
| Inject into project-level AGENTS.md | `scripts/inject-agents-md.sh --local` |
| Preview what would be added | `scripts/inject-agents-md.sh --dry-run` |
| Remove the block (cleanly) | `scripts/inject-agents-md.sh --remove` |
| Refresh block content after skill updates | `--remove` then re-run (no arg) |

**Notes:**
- The script NEVER auto-runs. You must invoke it explicitly.
- The script does NOT touch omo's routing or hooks — only appends to AGENTS.md.
- If you hand-edit the area around markers, re-running the script is still safe (won't duplicate).
- Removing the block via `--remove` preserves everything outside the markers, including any content you've added directly above/below.

### Behavior enforcement: two layers

Some skills (notably OMO's `review-work` skill) enforce workflow discipline on OpenCode. They use **two layers**:

| Layer | Where it lives | Strength | Who reads it |
|---|---|---|---|
| **Hard** | OpenCode plugin at `~/.config/opencode/plugins/<skill>.ts` | Fires on real events (tool calls, compaction, system-prompt turn); always runs | The plugin runs every event; agent cannot skip it |
| **Soft** | A short reminder block in `~/.config/opencode/AGENTS.md` (user-level) or your project's `AGENTS.md` | Reminder only — agent reads and may or may not honor | The model reads AGENTS.md every turn |

**Hard layer ≠ routing.** Routing = which skill/agent handles a request (controlled by omo category/agent config). Enforcement = inject extra context at the right moments (plugin hooks). Don't conflate them. See OMO's `review-work` skill for the canonical example.

Soft-layer content should be **concise** (5–10 lines). For full doc, read the skill.