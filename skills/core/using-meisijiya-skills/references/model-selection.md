# Agent / Category Selection by Task Type

OpenCode does not support per-call dynamic `model` fields — OMO routes through **agent / category selection** instead. The underlying model for each agent/category is configured in OMO and is out of scope for this skill system. This reference exists to recommend WHICH agent or category to dispatch to, not WHICH model to use.

| Task type | Recommended agent / category | Rationale |
|---|---|---|
| Mechanical implementation (1-2 files, complete spec in brief) | `sisyphus-junior` or category `quick` | Transcription + testing; cheap executor suffices |
| Integration / coordination (multi-file, dependency awareness) | `sisyphus-junior` | Cross-file judgment needed; cheap executor is risky here |
| Architectural / design decisions | `oracle` (read-only consultant) | High judgment; cheapest executors tend to approve DRY violations as YAGNI per Superpowers cost experiments |
| Final whole-branch review | OMO built-in `review-work` (5 parallel lanes) | Multi-lane = broader coverage than any single reviewer |

**Cheapest ≠ always-better**: Superpowers' cost experiments showed cheap reviewers approve DRY violations as YAGNI and pass tests with no assertions. Mid-tier is the floor for reviewers; cheap only works for implementers with **complete code in brief** (i.e. transcription, not judgment).