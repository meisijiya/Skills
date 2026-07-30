# Model Selection by Task Type

OpenCode does not support per-call dynamic `model` fields ([issue #1776](https://github.com/code-yeongyu/oh-my-openagent/issues/1776) is still open). Instead, OMO routes through **agent / category selection** — each agent has a fixed model chain, so picking the agent indirectly picks the model.

| Task type | Recommended agent / category | Rationale |
|---|---|---|
| Mechanical implementation (1-2 files, complete spec in brief) | `sisyphus-junior` (sonnet-4-6) — or category `quick` (gpt-5.4-mini) | Transcription + testing; cheap model suffices |
| Integration / coordination (multi-file, dependency awareness) | `sisyphus-junior` (sonnet-4-6) | Mid-tier; can't be cheap because cross-file judgment needed |
| Architectural / design decisions | `oracle` (gpt-5.6-sol xhigh) — read-only consultant | High judgment; cheapest models recommend DRY as YAGNI per Superpowers cost experiments |
| Final whole-branch review | OMO built-in `review-work` (5 parallel lanes) | Multi-lane = broader coverage than any single reviewer |

**Cheapest ≠ always-better**: Superpowers' cost experiments showed cheap reviewers approve DRY violations as YAGNI and pass tests with no assertions. Mid-tier is the floor for reviewers; cheap only works for implementers with **complete code in brief** (i.e. transcription, not judgment).