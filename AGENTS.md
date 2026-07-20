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

Use this skill system for the omo + pwf stack. Invoke skills by matching their `description` field against the user's request; do not invoke skills that don't match.

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
- [`source-driven-development`](~/.agents/skills/source-driven-development/SKILL.md) — verify API against official docs

**.extra/ — load on demand (10):**
[`writing-skills`](~/.agents/skills/writing-skills/SKILL.md) · [`pwf-enforcer`](~/.agents/skills/pwf-enforcer/SKILL.md) · [`build-gate-visual-review`](~/.agents/skills/build-gate-visual-review/SKILL.md) · [`designer-handoff`](~/.agents/skills/designer-handoff/SKILL.md) · [`api-and-interface-design`](~/.agents/skills/api-and-interface-design/SKILL.md) · [`security-and-hardening`](~/.agents/skills/security-and-hardening/SKILL.md) · [`performance-optimization`](~/.agents/skills/performance-optimization/SKILL.md) · [`observability-and-instrumentation`](~/.agents/skills/observability-and-instrumentation/SKILL.md) · [`documentation-and-adrs`](~/.agents/skills/documentation-and-adrs/SKILL.md) · [`improve-codebase-architecture`](~/.agents/skills/improve-codebase-architecture/SKILL.md)

Canonical write-side note: `writing-skills` is meta-only and lives in `extra/`.

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
- [`incremental-implementation`](~/.agents/skills/incremental-implementation/SKILL.md) — git-master skill, atlas agent
- [`designer-handoff`](~/.agents/skills/designer-handoff/SKILL.md) — visual-engineering category, frontend-ui-ux skill
- [`security-and-hardening`](~/.agents/skills/security-and-hardening/SKILL.md) — security-research mode
- [`using-meisijiya-skills`](~/.agents/skills/using-meisijiya-skills/SKILL.md) — Sisyphus (executing delegation), atlas (todo orchestration)

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
- **`## pwf Integration` section**: Map the skill to a pwf phase, OR note "no phase mapping" if it's a meta-doc.
- **≤ 500 lines**: Move reference material to supporting files.
- **`allowed-tools`**: Specify in frontmatter when the skill needs tool restrictions.
- **Eval case**: Add `evals/cases/<skill-name>.json` with 3 positive triggers + 3 negative triggers + ≥ 1 behavioral scenario.
- **Marketplace manifest** (`.claude-plugin/marketplace.json`): Every new skill must add its path to the corresponding plugin entry's `skills[]` array. `npx skills add` groups by `pluginName`, not by directory. See `skill-anatomy.md` for the full convention. CI `scripts/check-marketplace.sh` enforces this.
- **omo integration** (if applicable): Reference relevant omo MCPs / agents / built-ins. See any existing skill's Process section for the format.
- **Section A counts auto-derive**: The `(N)` numbers in Section A (`load always` / `load on demand`) are auto-replaced by `scripts/inject-agents-md.sh` from `.claude-plugin/marketplace.json` on each inject. Source numbers may drift; the rendered block always reflects the current manifest.

Existing skills are the reference. When in doubt, copy a similar skill's structure (e.g., [`test-driven-development`](~/.agents/skills/test-driven-development/SKILL.md) for the canonical 6-section pattern).

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

Some skills (notably [`pwf-enforcer`](~/.agents/skills/pwf-enforcer/SKILL.md)) enforce workflow discipline on OpenCode. They use **two layers**:

| Layer | Where it lives | Strength | Who reads it |
|---|---|---|---|
| **Hard** | OpenCode plugin at `~/.config/opencode/plugins/<skill>.ts` | Fires on real events (tool calls, compaction, system-prompt turn); always runs | The plugin runs every event; agent cannot skip it |
| **Soft** | A short reminder block in `~/.config/opencode/AGENTS.md` (user-level) or your project's `AGENTS.md` | Reminder only — agent reads and may or may not honor | The model reads AGENTS.md every turn |

**Hard layer ≠ routing.** Routing = which skill/agent handles a request (controlled by omo category/agent config). Enforcement = inject extra context at the right moments (plugin hooks). Don't conflate them. See `skills/extra/pwf-enforcer/SKILL.md` for the canonical example.

Soft-layer content should be **concise** (5–10 lines). For full doc, read the skill.