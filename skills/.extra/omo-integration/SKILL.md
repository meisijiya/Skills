---
name: omo-integration
description: "Cross-reference map of meisijiya-skills to oh-my-openagent (omo) features — MCPs (websearch, context7, grep_app, lsp), agents (sisyphus, prometheus, atlas, oracle, librarian, multimodal-looker, metis, momus), built-in skills (git-master, frontend-ui-ux, playwright, review-work, remove-ai-slops, init-deep, team-mode, ast-grep), and modes (ultrawork, search, analyze, team, hyperplan, security-research). Use when running the fork under omo and need to know which omo feature to leverage from which meisijiya-skills."
allowed-tools: "Read"
---

# omo Integration Map

## Overview

[oh-my-openagent](https://github.com/code-yeongyu/oh-my-openagent) (omo) provides MCPs, agents, built-in skills, and modes. **meisijiya-skills is designed to leverage these — not replace them.**

This skill is a cross-reference: for each omo feature, which meisijiya-skills should use it, and how.

## When to Use

**Use when:**
- Running meisijiya-skills under omo and want to know which omo feature helps with what
- Optimizing skill execution by leveraging omo's MCPs (instead of shelling out to web)
- Wanting to know which omo agent to delegate to for a given task type
- Deciding whether to invoke an omo built-in skill directly vs through a meisijiya-skills wrapper

**NOT for:**
- Running without omo (Claude Code / Codex CLI — these features don't exist there)
- Looking for omo basics (omo's own docs cover those)

## omo MCPs → meisijiya-skills

| MCP | Purpose | Used by |
|---|---|---|
| `context7` | Library docs lookup | `source-driven-development` (primary, replaces manual `WebFetch`) |
| `grep_app` | GitHub code search | `source-driven-development` (real-world examples), `security-and-hardening` (CVE patterns, dependency audit) |
| `websearch` (Exa AI) | Web search | `source-driven-development` (current info fallback when context7 doesn't have the lib) |
| `lsp` | Local language server | `debugging-and-error-recovery` (localization via goto_definition), `performance-optimization` (profiling context) |

## omo Agents → meisijiya-skills

| Agent | Purpose | Delegated from |
|---|---|---|
| `sisyphus` | Main orchestrator | (upstream of `using-meisijiya-skills`; falls through if omo absent) |
| `prometheus` | Interview-mode strategic planner | `interview-me` (deep planning when intent is ambiguous), `spec-driven-development` (open-ended specs) |
| `atlas` | Todo orchestration + execution | `incremental-implementation` (slice-level todo tracking) |
| `oracle` | Read-only architecture/debugging consultant | `debugging-and-error-recovery` (Step 2: Localize — when stuck), `api-and-interface-design` (architecture questions) |
| `explore` | Fast codebase grep | Used directly in any skill needing quick codebase pattern lookup |
| `librarian` | Docs/code/OSS search | `source-driven-development` (deep research) |
| `multimodal-looker` | Vision/screenshot analysis | `observability-and-instrumentation` (log/screenshot analysis), `build-gate-visual-review` (verify rendered deck) |
| `metis` | Gap analyzer | `spec-driven-development` (post-draft — check for gaps before commit) |
| `momus` | Ruthless plan reviewer | Ad-hoc plan review (no meisijiya-skill wrapper; use directly) |
| `hephaestus` | Deep autonomous executor | Use directly for complex end-to-end execution (don't need a skill) |

## omo Built-in Skills → meisijiya-skills

| omo Built-in | Purpose | Complementary to |
|---|---|---|
| `git-master` | Atomic commits, rebase surgery, history search | `incremental-implementation` (slice commits) — invoke via omo skill loader |
| `frontend-ui-ux` | Design-first UI generation | `designer-handoff` (frontend agent receives design spec from us, applies omo's frontend-ui-ux) |
| `playwright` / `agent-browser` / `dev-browser` | Browser automation | `build-gate-visual-review` (auto-screenshot the deck for verification) |
| `review-work` | 5-agent parallel post-implementation review | (we removed `code-review-and-quality`) — invoke `review-work` directly via omo |
| `remove-ai-slops` | AI-generated code pattern cleanup | `code-simplification` — different concern: `remove-ai-slops` = AI slop, `code-simplification` = complexity. Use both if applicable. |
| `init-deep` | Auto-generate hierarchical AGENTS.md | `agent-project-structure` (initial AGENTS.md auto-population across dirs) |
| `team-mode` | Parallel multi-agent coordination | `security-and-hardening` (full audit), `hyperplan` (complex plan review) |
| `ast-grep` | AST-aware search/rewrite | Used directly for structural code work (no meisijiya-skill wrapper needed) |

## omo Modes → meisijiya-skills

| Mode | Purpose | Trigger |
|---|---|---|
| `ultrawork` / `ulw` | All agents activated, doesn't stop until done | Long-running agentic work — say "ulw" to activate |
| `search` | Search-focused mode | Quick code/doc lookup |
| `analyze` | Analysis-focused mode | `performance-optimization`, `code-review-and-quality` |
| `team` | Team Mode enabled (lead + up to 8 parallel members) | For `/hyperplan` (5 hostile critics) or `/security-research` (3 hunters + 2 PoC engineers) |
| `hyperplan` | 5-agent adversarial plan review | After `spec-driven-development`, before commit |
| `security-research` | 3 hunters + 2 PoC engineer audit | For serious security audit on production code |

## omo Categories → meisijiya-skills

omo's category system routes work to optimal models:

| Category | Model (auto) | Use from |
|---|---|---|
| `visual-engineering` | Gemini 3.1 Pro | `designer-handoff` (frontend agent receives design spec, runs as visual-engineering category) |
| `ultrabrain` | GPT-5.5 xhigh | `debugging-and-error-recovery` (hard bugs), `api-and-interface-design` (architecture) |
| `deep` | GPT-5.5 | `incremental-implementation` (multi-step builds), `code-review-and-quality` style audits |
| `artistry` | Gemini 3.1 Pro | `designer-handoff` (creative design tasks) |
| `quick` | GPT-5.4 Mini | Trivial file edits (no skill needed) |
| `unspecified-low` | Cheapest available | Background helpers |
| `unspecified-high` | Claude Opus max | Use directly — doesn't need a meisijiya-skill wrapper |
| `writing` | Claude Opus high | Use directly for documentation tasks |

## How to invoke omo features from a meisijiya-skill

Inside any meisijiya-skill's Process section, when you want to use an omo feature:

1. **MCP**: invoke directly via tool name (e.g., `mcp__context7__get-library-docs`). MCPs are exposed as tools.
2. **Agent**: ask Sisyphus (or the parent) to delegate. Don't call agents directly — let Sisyphus route.
3. **Built-in skill**: load via omo's skill loader (e.g., "load git-master skill"). omo handles discovery.
4. **Mode**: trigger via Sisyphus with the mode name (e.g., "use hyperplan mode").
5. **Category**: Sisyphus picks based on task. Just describe the task; Sisyphus routes.

## Common Rationalizations

| Excuse | Reality |
|---|---|
| "omo 装起来太重,我不装" | fork 依赖 omo——omo 不在就 fork 不完整。装吧。 |
| "context7 不准,我去 WebFetch 抓官方文档" | WebFetch 经常拿不到结构化 API。context7 是为 AI 优化的。 |
| "oracle 是 read-only,改不了东西" | 对——它就是让你卡住时有个 AI 同伴问。Read-only 是 feature。 |
| "team-mode 太重,我手动想" | 是重。`/hyperplan` 5 个 agent 并行——只在复杂 plan 才用。手动想不是 substitute。 |
| "git-master 是 omo 自带的,我直接 git commit 就行" | omo 的 `git-master` 有 atomic commit + rebase surgery 纪律,你的 `git commit` 没这套。 |
| "frontend-ui-ux 是 omo 的,我的 designer-handoff 不需要" | omo 的 frontend-ui-ux 是 frontend agent 的执行 skill;designer-handoff 产生设计 spec,frontend-ui-ux 消费它。互补。 |
| "init-deep 是 omo 的,我手写 AGENTS.md" | init-deep 是自动生成的。手写会漏层级。手写只有极简项目才可行。 |

## Red Flags

- 不用 context7 而用 WebFetch 查 API(走弯路)
- 不用 oracle 而死磕调试 5 步(应该 escalate)
- 不用 git-master 而手动 commit(失掉纪律)
- 不用 init-deep 而手写 AGENTS.md(应该 auto-gen)
- 不用 visual-engineering category 而让 general agent 做 UI(质量低)
- 不用 `hyperplan` review 复杂 plan(应该 adversarial review)
- 不用 `security-research` 做生产代码 audit(应该 parallel hunter + PoC)

## Verification

- [ ] omo installed (`bunx oh-my-openagent install`)
- [ ] `~/.config/opencode/oh-my-openagent.json` exists
- [ ] Each skill that benefits from omo features is invoked WITH the relevant omo context (e.g., `source-driven-development` uses context7 first)
- [ ] When stuck, escalate to oracle agent (not guess)
- [ ] Heavy plans use `hyperplan` (not ad-hoc planning)
- [ ] Frontend work delegates to `visual-engineering` category

## pwf Integration

Meta-doc, not a phase. Read at session start if running under omo. Does not write to `task_plan.md`.

See [pwf-integration.md](../../pwf-integration.md) for the phase map.