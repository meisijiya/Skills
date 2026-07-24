# omo Per-Agent Skill List Configuration

## Overview

[meisijiya-skills] installs **36 SKILL.md** files(9 `core/` + 27 `extra/` = `9 security` + `2 cicd` + `4 observability` + `4 meta` + `8 domain`,见 `.claude-plugin/marketplace.json`)。默认 omo 会把所有已装 skill 加载到**每个** agent 的上下文中。这会让只需要的 agent(例如 `explore` 不需要 `spec-driven-development`)的 context 膨胀。

本指南为每个 omo agent 推荐应装载的 skill 子集,供希望按 agent 收敛 context 的用户参考。

> **约束**:我们**不会**替你修改 `oh-my-openagent.json`。请手工应用。本文档是**增强/指南**,不是路由变更。

## Why per-agent skill lists?

- **Smaller context per agent** — agents only see relevant skills
- **Faster responses** — less context to process
- **Less noise** — fewer "which skill applies?" decisions
- **Clearer intent** — agent's role + skill set align

Sisyphus (main orchestrator) gets **all 36** (it routes everything). All other agents get a subset.

## Recommended per-agent config

| omo Agent | Recommended skills | Why |
|---|---|---|
| **sisyphus** | (all 36) | Main orchestrator — full visibility needed |
| **hephaestus** | brainstorming, spec-driven-development, incremental-implementation, test-driven-development, debugging-and-error-recovery, source-driven-development, diagnosing-bugs, **security-devsecops**, **supply-chain-risk-auditor**, **closed-loop-delivery** | Deep autonomous executor — full discipline stack + supply-chain/deployment + runtime-closure |
| **prometheus** | brainstorming, spec-driven-development, **contract-strengthening** (optional) | Strategic planner — question-quality + spec discipline + Phase 1.25 contract review |
| **atlas** | using-meisijiya-skills, incremental-implementation, **slice-review**, **verify-chain** | Todo orchestrator — meta + slice guidance + per-slice review + parallel Verifier via `general` agent |
| **oracle** | source-driven-development, debugging-and-error-recovery, diagnosing-bugs, api-and-interface-design, **security-incident-response**, **security-threat-model**, **gha-security-review**, **contract-strengthening** | Read-only consultant — verification + interface design + post-incident + threat modeling + GHA audit + Phase 1.25 contract review |
| **librarian** | source-driven-development | Docs/OSS search — needs verification |
| **explore** | (none) | Codebase grep — already fast, no skill needed |
| **multimodal-looker** | (none) | Vision — no meisijiya-skill wrapper needed |
| **metis** | spec-driven-development, **contract-strengthening** | Gap analyzer — spec context + open-world / non-exhaustive contract review |
| **momus** | (none) | Plan reviewer — direct-use agent |
| **sisyphus-junior** | incremental-implementation, test-driven-development, **test-guard**, **improve-codebase-architecture** | Focused executor — slice + TDD + test-quality audit + single-task architecture review |
| **build** | verification-before-completion, **ai-code-blindspots**, **stack-security-coder** | Default build agent — must-invoke verification layer; layer-coding + AI-blindspots picked up via review-router plugin (no manual config needed) |

## Configuration example

Add to `~/.config/opencode/oh-my-openagent.json` (user-level) or `.opencode/oh-my-openagent.json` (project-level override):

```json
{
  "agents": {
    "sisyphus": {
      "model": "anthropic/claude-opus-4-7",
      "skills": ["*"]
    },
    "hephaestus": {
      "model": "openai/gpt-5.5",
      "variant": "xhigh",
      "skills": [
        "spec-driven-development",
        "incremental-implementation",
        "test-driven-development",
        "debugging-and-error-recovery",
        "source-driven-development"
      ]
    },
    "prometheus": {
      "model": "kimi-for-coding/k2p5",
      "skills": ["brainstorming", "spec-driven-development"]
    },
    "atlas": {
      "model": "google/gemini-3-flash",
      "skills": ["using-meisijiya-skills", "incremental-implementation"]
    },
    "oracle": {
      "model": "openai/gpt-5.5",
      "variant": "high",
      "skills": [
        "source-driven-development",
        "debugging-and-error-recovery",
        "api-and-interface-design"
      ]
    },
    "librarian": {
      "model": "google/gemini-3-flash",
      "skills": ["source-driven-development"]
    },
    "explore": {
      "model": "github-copilot/grok-code-fast-1",
      "skills": []
    },
    "multimodal-looker": {
      "model": "google/gemini-3-flash",
      "skills": []
    },
    "metis": {
      "skills": ["spec-driven-development"]
    },
    "momus": {
      "skills": []
    },
    "sisyphus-junior": {
      "skills": ["incremental-implementation", "test-driven-development"]
    }
  }
}
```

> **Field-name note**: Verify the exact field name for per-agent skill lists against your version of omo. Recent versions use `skills: [...]` (list) or `skills: ["*"]` (all). Older versions may use different syntax. Check [omo docs](https://github.com/code-yeongyu/oh-my-openagent) for current schema.

## How to apply

1. Open `~/.config/opencode/oh-my-openagent.json` (or your project-level override).
2. For each agent listed above, add the `skills` array under its config.
3. For Sisyphus, use `["*"]` to get all.
4. Restart omo for changes to take effect.

## Verification

After applying:

1. Restart omo session.
2. Run `use skill tool to list skills` (or equivalent) inside Sisyphus's context — should see all 36.
3. Dispatch a task to `hephaestus` and list its skills — should see only the ~10 recommended (including 11-skill-series additions).
4. Spot-check 2-3 other agents.

## Caveat: skill discoverability

If a non-Sisyphus agent needs a skill not in its list, omo should still let it load the skill on demand (or fall back to Sisyphus for routing). Per-agent lists are an **optimization**, not a hard restriction.

If you want strict enforcement, use omo's hook system (`tool.before.*` matching on skill load) to block unauthorized skill loading.

## Don't confuse with omo built-ins

These meisijiya-skills are **additive** to omo's built-in skills (git-master, frontend-ui-ux, playwright, review-work, remove-ai-slops, init-deep, team-mode, ast-grep, etc.). Per-agent config above is for **our** skills only — don't remove omo built-ins.

If you want to control omo built-in skills per agent, that's omo's territory (see omo docs for `omo.builtin_skills` or similar config).