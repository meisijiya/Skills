# Controller vs Executor Identity Contract

When dispatching work via `task(subagent_type="...", ...)`, the **controller** (Sisyphus / Atlas / Sisyphus-Junior) and the **executor** (sisyphus-junior / hephaestus / general agent) have strictly different roles:

| Concern | Controller (session owner) | Executor (dispatched sub-agent) |
|---|---|---|
| Plan / spec / brief | Reads full plan, holds cross-task context | Reads only `brief` file (via `task-brief.sh`) — sees NOTHING else |
| Cross-slice state | Maintains Boulder + notepad | Reads notepad append-only, never edits |
| Review gates | Schedules `slice-review` (per slice) + `review-work` (whole-branch) | Receives review verdicts; re-dispatches fixers if BLOCKED |
| Decision authority | Owns design / scope / architectural calls | 4-status return only (DONE / DONE_WITH_CONCERNS / NEEDS_CONTEXT / BLOCKED) — never invents scope |
| Context pollution | Stays in session, accumulates | Fresh per dispatch (the whole point of subagent isolation) |

**Why this matters**: this skill is bound by `<SUBAGENT-STOP>` at the top of [`../SKILL.md`](../SKILL.md) — when invoked as a sub-agent, ignore it. The controller is the only entity that should ever invoke the meta dispatcher. Executors receive domain-specific skills (e.g. `incremental-implementation`, `slice-review`) in their dispatch prompt, NOT `using-meisijiya-skills`.