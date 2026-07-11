# Changelog

All notable changes to meisijiya-skills.

## [0.1.3] - 2026-07-11

### Fixed

- **Over-broad fix in v0.1.2 reverted for this repo's own paths.** v0.1.2 changed all `~/.config/opencode/skills/` refs to `~/.agents/skills/` — too broad. Correct rule:
  - **Skills installed via `vercel-labs/skills` CLI** (pwf, html-ppt-skill, ui-ux-pro-max) → `~/.agents/skills/`
  - **This repo's own install paths** (`scripts/install.sh --global`) → `~/.config/opencode/skills/` (omo's native)
  - **omo runtime config** (`oh-my-openagent.json`) → `~/.config/opencode/oh-my-openagent.json` (unchanged)

Reverted:
- `scripts/install.sh` — `--global` default target + 2 comments back to `~/.config/opencode/skills/`
- `README.md` — `--global` comment back to `~/.config/opencode/skills/`

Kept (v0.1.2 fix was correct for these):
- `pwf-enforcer/SKILL.md` — pwf at `~/.agents/skills/`
- `build-gate-visual-review/SKILL.md` — html-ppt-skill at `~/.agents/skills/`
- `designer-handoff/SKILL.md` — ui-ux-pro-max at `~/.agents/skills/`
- `evals/cases/build-gate-visual-review.json` — html-ppt-skill refs

## [0.1.2] - 2026-07-11

### Fixed

- **Skills-CLI-managed skill paths corrected** from `~/.config/opencode/skills/` → `~/.agents/skills/`. The canonical location for `vercel-labs/skills` CLI global installs is `~/.agents/skills/`, not omo's local config dir. Applies to skills that users install via `npx skills add` (pwf, html-ppt-skill, ui-ux-pro-max). Does NOT apply to meisijiya-skills' own install paths (those use omo's native locations — see v0.1.3 for the correction). Fixes:
  - `pwf-enforcer/SKILL.md` — 4 path refs (verify + 3 hook commands)
  - `build-gate-visual-review/SKILL.md` — 3 path refs (verify + install options + verification)
  - `designer-handoff/SKILL.md` — 1 path ref (ui-ux-pro-max verify)
  - `README.md` — html-ppt-skill prerequisites line
  - `evals/cases/build-gate-visual-review.json` — behavioral eval + notes

omo config path (`~/.config/opencode/oh-my-openagent.json`) is unchanged — it's not a skill install location, it's omo's runtime config.

## [0.1.1] - 2026-07-11

### Changed

- `build-gate-visual-review` (skill + eval): replaced HTML Anything with [html-ppt-skill](https://github.com/lewislulu/html-ppt-skill). Reason: HTML Anything was a self-hosted web service (`pnpm dev`, `localhost:3000`, POST API) — heavy for the use case. html-ppt-skill is an installed AgentSkill (SKILL.md + themes + layouts + animations) that the agent loads directly and produces a static HTML slide deck. Simpler install, more focused output.
- README prerequisites: HTML Anything → `npx skills add <html-ppt-skill-url>` (installs to `~/.agents/skills/`).

### Required user action

After upgrading to v0.1.1:

```bash
npx skills add https://github.com/lewislulu/html-ppt-skill
```

(html-ppt-skill must be pre-installed in `~/.agents/skills/` before using `build-gate-visual-review`; agent does not auto-install.)

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
- `build-gate-visual-review` — html-ppt-skill orchestration for pre-build visual review (HTML slide deck)
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