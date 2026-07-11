# omo Per-Agent Skill List Configuration

## Overview

[meisijiya-skills] installs 18 SKILL.md files. By default, omo loads all installed skills for **every** agent. This bloats context for agents that only need a few (e.g., `explore` doesn't need `spec-driven-development`).

This guide recommends which skills each omo agent should have in its `skills` list, for users who want to constrain per-agent context.

> **Constraint**: we do **NOT** modify `oh-my-openagent.json` for you. Apply this manually. This is **enhancement/guidance**, not routing modification.

## Why per-agent skill lists?

- **Smaller context per agent** — agents only see relevant skills
- **Faster responses** — less context to process
- **Less noise** — fewer "which skill applies?" decisions
- **Clearer intent** — agent's role + skill set align

Sisyphus (main orchestrator) gets **all 18** (it routes everything). All other agents get a subset.

## Recommended per-agent config

| omo Agent | Recommended skills | Why |
|---|---|---|
| **sisyphus** | (all 18) | Main orchestrator — full visibility needed |
| **hephaestus** | spec-driven-development, incremental-implementation, test-driven-development, debugging-and-error-recovery, source-driven-development | Deep autonomous executor — full discipline stack |
| **prometheus** | interview-me, spec-driven-development | Strategic planner — question-quality + spec discipline |
| **atlas** | using-meisijiya-skills, incremental-implementation | Todo orchestrator — meta + slice guidance |
| **oracle** | source-driven-development, debugging-and-error-recovery, api-and-interface-design | Read-only consultant — verification + interface design |
| **librarian** | source-driven-development | Docs/OSS search — needs verification |
| **explore** | (none) | Codebase grep — already fast, no skill needed |
| **multimodal-looker** | (none) | Vision — no meisijiya-skill wrapper needed |
| **metis** | spec-driven-development, agent-project-structure | Gap analyzer — spec + structure context |
| **momus** | (none) | Plan reviewer — direct-use agent |
| **sisyphus-junior** | incremental-implementation, test-driven-development | Focused executor — slice + TDD |

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
      "skills": ["interview-me", "spec-driven-development"]
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
      "skills": ["spec-driven-development", "agent-project-structure"]
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
2. Run `use skill tool to list skills` (or equivalent) inside Sisyphus's context — should see all 18.
3. Dispatch a task to `hephaestus` and list its skills — should see only the 5 recommended.
4. Spot-check 2-3 other agents.

## Caveat: skill discoverability

If a non-Sisyphus agent needs a skill not in its list, omo should still let it load the skill on demand (or fall back to Sisyphus for routing). Per-agent lists are an **optimization**, not a hard restriction.

If you want strict enforcement, use omo's hook system (`tool.before.*` matching on skill load) to block unauthorized skill loading.

## Don't confuse with omo built-ins

These meisijiya-skills are **additive** to omo's built-in skills (git-master, frontend-ui-ux, playwright, review-work, remove-ai-slops, init-deep, team-mode, ast-grep, etc.). Per-agent config above is for **our** skills only — don't remove omo built-ins.

If you want to control omo built-in skills per agent, that's omo's territory (see omo docs for `omo.builtin_skills` or similar config).