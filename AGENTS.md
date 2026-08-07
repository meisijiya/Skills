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

完整 skill catalog 由 plugin runtime 的 `<available_skills>` 提供。

→ `references/priority-table.md` 用于路由触发关键词
→ `references/process-chains.md` 用于多 Skill 工作链
→ `references/category-matrix.md` 用于 Category × Skill 矩阵与 dispatch 场景

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
- **Marketplace manifest** (`.claude-plugin/marketplace.json`): Every new skill must add its path to the corresponding plugin entry's `skills[]` array. `npx skills add` groups by `pluginName`, not by directory. The 6 non-core plugin entries map to logical groups: `meisijiya-security` / `meisijiya-cicd` / `meisijiya-observability` / `meisijiya-meta` / `meisijiya-domain` / `meisijiya-frontend`. Pick the group whose existing members share the same audience and stage in the dev lifecycle. See `skill-anatomy.md` for the full convention. CI `scripts/check-marketplace.sh` enforces this.
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