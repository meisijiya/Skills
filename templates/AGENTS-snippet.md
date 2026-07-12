## meisijiya-skills (installed)

This project uses [meisijiya-skills](https://github.com/meisijiya/meisijiya-skills) — a personal fork of [addyosmani/agent-skills](https://github.com/addyosmani/agent-skills) for the [oh-my-openagent](https://github.com/code-yeongyu/oh-my-openagent) (omo) + [planning-with-files](https://github.com/OthmanAdi/planning-with-files) (pwf) stack.

### Skill catalog

**.core/ (always-loaded, 6):**
- `using-meisijiya-skills` — meta dispatcher; check before every response
- `spec-driven-development` — spec before non-trivial code
- `incremental-implementation` — vertical slices (≤ 100 lines each)
- `test-driven-development` — red-green-refactor
- `debugging-and-error-recovery` — 5-step triage (reproduce / localize / reduce / fix / guard)
- `source-driven-development` — verify API against official docs

**.extra/ (opt-in, 12):**
`pwf-enforcer` · `build-gate-visual-review` · `designer-handoff` · `agent-project-structure` · `interview-me` · `code-simplification` · `api-and-interface-design` · `security-and-hardening` · `performance-optimization` · `observability-and-instrumentation` · `documentation-and-adrs` · `omo-integration`

### omo integration (v0.2.0+)

Skills explicitly leverage omo features:

| Skill | omo feature used |
|---|---|
| `source-driven-development` | context7 MCP (primary), grep_app MCP, websearch MCP |
| `debugging-and-error-recovery` | oracle agent (escalation), lsp MCP (localization) |
| `incremental-implementation` | git-master skill, atlas agent |
| `designer-handoff` | visual-engineering category, frontend-ui-ux skill |
| `security-and-hardening` | security-research mode (v0.2.1+) |
| `using-meisijiya-skills` | Sisyphus + IntentGate handoff, atlas agent |

Full map: load `omo-integration` skill (already in `.extra/`).

### Conventions

- pwf `task_plan.md` is the source of truth for in-flight work (legacy mode) or `.planning/<date>-<slug>/task_plan.md` (parallel mode)
- Don't ship code without spec + tests
- Verify APIs against official docs, not memory (use context7 MCP under omo)
- Multi-file changes → vertical slices (commit with `slice:` prefix)
- pwf phase boundaries defined in `pwf-integration.md`

### Install paths

- **This skill system (recommended)**: `npx skills add <repo>` → `~/.agents/skills/<name>/` (canonical)
- **This skill system (advanced)**: `scripts/install.sh` → `~/.config/opencode/skills/<name>/` (omo native) or `<project>/.opencode/skills/<name>/`
- **Other skills** (pwf, html-ppt-skill, ui-ux-pro-max): `~/.agents/skills/<name>/` (canonical, all via skills CLI)

### Meta-info injection source

This block was injected by `meisijiya-skills/scripts/inject-agents-md.sh`.
Source: `templates/AGENTS-snippet.md` in the meisijiya-skills repo.
Re-run: `scripts/inject-agents-md.sh` (idempotent).
Remove: `scripts/inject-agents-md.sh --remove`.