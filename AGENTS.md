# meisijiya-skills — Agent Context

> **What this file is**: A self-contained agent context file for the `meisijiya-skills` repo.
>
> - **For users**: **Section A** is what `scripts/inject-agents-md.sh` injects into YOUR project's `AGENTS.md`. You can also manually copy Section A content.
> - **For contributors**: **Section B** documents how to add new skills to this repo.
> - **For agents reading this repo**: This whole file is context.

---

## Section A: Skill catalog

The block between the sentinel markers below is what `scripts/inject-agents-md.sh` extracts and appends (with its own markers) to your `~/.config/opencode/AGENTS.md`. To copy manually, copy everything between the markers.

<!-- meisijiya-skills:start -->

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

**.extra/ (opt-in, 10):**
`pwf-enforcer` · `build-gate-visual-review` · `designer-handoff` · `interview-me` · `code-simplification` · `api-and-interface-design` · `security-and-hardening` · `performance-optimization` · `observability-and-instrumentation` · `documentation-and-adrs`

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

Full omo → skills cross-reference map: in `~/.config/opencode/AGENTS.md` (consolidated from former `omo-integration` skill).

### Conventions

- pwf `task_plan.md` is the source of truth for in-flight work (legacy mode) or `.planning/<date>-<slug>/task_plan.md` (parallel mode)
- Don't ship code without spec + tests
- Verify APIs against official docs, not memory (use context7 MCP under omo)
- Multi-file changes → vertical slices (commit with `slice:` prefix)
- pwf phase boundaries defined in `pwf-integration.md`

### Install paths

- **This skill system (recommended)**: `npx skills add <repo>` → `~/.agents/skills/<name>/` (canonical)
- **This skill system (advanced)**: `scripts/install.sh --global` → `~/.agents/skills/<name>/` (same as skills CLI);`--target <path>` → `<path>/.opencode/skills/<name>/` (project-level, omo native)
- **Other skills** (pwf, html-ppt-skill, ui-ux-pro-max): `~/.agents/skills/<name>/` (canonical, all via skills CLI)

### Meta-info injection source

This block was injected by `meisijiya-skills/scripts/inject-agents-md.sh`.
Source: `AGENTS.md` (Section A) in the meisijiya-skills repo.
Re-run: `scripts/inject-agents-md.sh` (idempotent).
Remove: `scripts/inject-agents-md.sh --remove`.

<!-- meisijiya-skills:end -->

---

## Section B: Adding skills (contributor guide)

When adding a new skill to this repo, follow the conventions in [`skill-anatomy.md`](./skill-anatomy.md). Key requirements:

- **YAML frontmatter**: `name` (must match directory) + `description` (≤1024 chars, third-person, "what" + "Use when"). **Do not** include workflow summary in description (let the agent read the full file).
- **6 standard sections**: Overview / When to Use (with NOT for) / Process / Common Rationalizations (table) / Red Flags (list) / Verification (checkboxes with evidence requirements).
- **`## pwf Integration` section**: Map the skill to a pwf phase, OR note "no phase mapping" if it's a meta-doc.
- **≤ 500 lines**: Move reference material to supporting files.
- **`allowed-tools`**: Specify in frontmatter when the skill needs tool restrictions.
- **Eval case**: Add `evals/cases/<skill-name>.json` with 3 positive triggers + 3 negative triggers + ≥ 1 behavioral scenario.
- **omo integration** (if applicable): Reference relevant omo MCPs / agents / built-ins. See [`skills/.extra/omo-integration/SKILL.md`](./skills/.extra/omo-integration/SKILL.md) for the cross-reference map.

Existing skills are the reference. When in doubt, copy a similar skill's structure (e.g., `test-driven-development` for the canonical 6-section pattern).

For multi-harness compatibility, the skill should be readable even without omo or pwf installed. Reference them, but don't hard-depend on their presence.

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

Some skills (notably `pwf-enforcer`) enforce workflow discipline on OpenCode. They use **two layers**:

| Layer | Where it lives | Strength | Who reads it |
|---|---|---|---|
| **Hard** | OpenCode plugin at `~/.config/opencode/plugins/<skill>.ts` | Fires on real events (tool calls, compaction, system-prompt turn); always runs | The plugin runs every event; agent cannot skip it |
| **Soft** | A short reminder block in `~/.config/opencode/AGENTS.md` (user-level) or your project's `AGENTS.md` | Reminder only — agent reads and may or may not honor | The model reads AGENTS.md every turn |

**Hard layer ≠ routing.** Routing = which skill/agent handles a request (controlled by omo category/agent config). Enforcement = inject extra context at the right moments (plugin hooks). Don't conflate them. See `skills/.extra/pwf-enforcer/SKILL.md` for the canonical example.

Soft-layer content should be **concise** (5–10 lines). For full doc, read the skill.