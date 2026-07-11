# Changelog

All notable changes to meisijiya-skills.

## [0.1.0] - 2026-07-11

Initial fork from [addyosmani/agent-skills](https://github.com/addyosmani/agent-skills), adapted for the oh-my-openagent (omo) + planning-with-files (pwf) stack.

### Added

**Meta & docs**
- `README.md` — fork intro, install paths, v0.1.0 status
- `skill-anatomy.md` — SKILL.md writing conventions (≤500 lines rule, 6-section structure)
- `pwf-integration.md` — phase mapping + file write boundaries
- `LICENSE` (MIT)
- `.gitignore`

**.core/ — 6 required skills**
- `using-meisijiya-skills` — meta dispatcher (force skill check + pwf init before every response)
- `spec-driven-development` — write spec before any non-trivial code
- `incremental-implementation` — vertical-slice decomposition
- `test-driven-development` — red-green-refactor discipline
- `debugging-and-error-recovery` — 5-step triage (reproduce / localize / reduce / fix / guard)
- `source-driven-development` — verify API against official docs

**.extra/ — 11 optional skills**
- `pwf-enforcer` — bridges pwf's Claude Code hooks to omo's OpenCode hook system (Tier 3 honest: advisory only)
- `build-gate-visual-review` — HTML Anything orchestration for pre-build visual review
- `designer-handoff` — ui-ux-pro-max-skill orchestration for frontend-agent design contract
- `agent-project-structure` — 10-folder canonical agent-project/ template (planner / memory / tools / knowledge / agent_core / evaluation / observability / deployment / examples / docs)
- `interview-me` — one-question-at-a-time requirement extraction
- `code-simplification` — Chesterton's Fence + behavior-preserving complexity reduction
- `api-and-interface-design` — Hyrum's Law + One-Version Rule + typed errors
- `security-and-hardening` — OWASP Top 10 + three trust boundaries (input / auth / integration)
- `performance-optimization` — Core Web Vitals + measure-first + profiling workflows
- `observability-and-instrumentation` — structured logging + RED metrics + OpenTelemetry + symptom-based alerts
- `documentation-and-adrs` — ADR template + "document the why"

**Eval cases (17)**
- One JSON per skill at `evals/cases/<skill-name>.json`
- Format: 3 positive triggers + 3 negative triggers + 2 behavioral evals
- All parse-validated, all match their SKILL.md (perfect bijection)

**Scripts**
- `scripts/validate-skills.sh` — YAML frontmatter + structure check (required name, name==directory, description ≤1024 chars, recommended 6 sections)
- `scripts/install.sh` — install .core/ (always) + selected .extra/ to `<project>/.opencode/skills/` or `~/.config/opencode/skills/` (global)

**Design documents**
- `docs/p0-outline.md` — archived (was draft → shipped)

### Design decisions

1. **omo + pwf stack targeted** — fills gaps omo doesn't cover, hardens pwf's soft compliance
2. **Double-directory structure** (`.core/` + `.extra/`) — matches `vercel-labs/skills` CLI conventions
3. **pwf Tier 3 documented honestly** — OpenCode cannot hard-block; `pwf-enforcer` is advisory only there
4. **6-section SKILL.md anatomy** — Overview / When to Use (with NOT for) / Process / Common Rationalizations / Red Flags / Verification / pwf Integration
5. **All SKILL.md < 500 lines** — within `skill-anatomy.md` spec
6. **All eval cases warning-level** — per upstream `addyosmani/agent-skills#352` convention

### Omitted (vs. upstream)

These are covered by omo built-ins or pwf itself, so not duplicated:
- `using-agent-skills` (omo Sisyphus + IntentGate substitute)
- `planning-and-task-breakdown` (pwf task_plan.md IS the plan)
- `git-workflow-and-versioning` (omo git-master)
- `frontend-ui-engineering` (omo frontend-ui-ux)
- `browser-testing-with-devtools` (omo playwright)
- `code-review-and-quality` (omo review-work)