---
name: pwf-enforcer
description: "Hard-enforces planning-with-files workflow via oh-my-openagent's hook system. Use when running omo + pwf together and want to upgrade pwf's soft compliance to hard compliance (e.g., prevent the agent from working on the wrong phase, force progress.md flushes, block stop on incomplete phases)."
allowed-tools: "Read Edit Bash Glob Grep Write"
---

# pwf-enforcer

## Overview

pwf 在 Claude Code 上有原生 hooks(`UserPromptSubmit` / `PreToolUse` / `PostToolUse` / `Stop` / `PreCompact`)—— 硬遵守。在 OpenCode 上 pwf 只是裸 SKILL.md,**软遵守**(agent 读了之后可以选择不遵守)。

`pwf-enforcer` 是桥梁:用 omo 的 hook 系统在 OpenCode 上**模拟 Claude Code 的 pwf hooks**,把软遵守升级为硬遵守。

## When to Use

**Use when:**
- 同时用 omo + pwf
- 想要 hard enforcement(block / inject / fail-stop)
- pwf 软遵守不够(agent 跑飞 phase、不更新 progress.md)
- 准备 on-call(需要 hard gate 防止事故)

**NOT for:**
- 只用 Claude Code(pwf 自带 hooks,不需要这个)
- 只用 pwf 不带 omo(没 hook 系统可用)
- 接受 soft compliance + 偶尔跑飞
- 没有 pwf 工作流的项目

## Process

### 1. Verify prerequisites

```bash
test -f ~/.config/opencode/oh-my-openagent.json && echo "omo installed" || echo "install omo first"
test -d ~/.agents/skills/planning-with-files/ && echo "pwf installed" || echo "install pwf first"
```

If either missing, prompt user to install before proceeding.

### 2. Understand the omo hook surface

omo maps Claude Code hooks to OpenCode events:

| pwf Claude Code hook | omo event |
|---|---|
| `UserPromptSubmit` | `session.created` + `tool.before.*` |
| `PreToolUse` | `tool.before.<tool_name>` |
| `PostToolUse` | `tool.after.<tool_name>` + `file.changed` |
| `Stop` | `session.idle`(Tier 3 — advisory only, can't hard-block) |
| `PreCompact` | `experimental.session.compacting` |

**Caveat:** omo's `session.idle` is Tier 3 — can **notify** but not hard-block. Use it as advisory, not enforcement. Hard phase enforcement belongs in `tool.before.*`.

### 3. Generate the omo hook config

Append to `~/.config/opencode/oh-my-openagent.json`:

```json
{
  "hooks": {
    "tool.before.write|edit": [
      {
        "command": "~/.agents/skills/planning-with-files/scripts/inject-plan.sh --context=pretool",
        "description": "Inject active plan head before any file edit (PreToolUse equivalent)"
      }
    ],
    "file.changed": [
      {
        "command": "echo '[pwf-enforcer] Update progress.md with what you just did. If a phase is now complete, update task_plan.md status.'",
        "description": "Prompt agent to update pwf files after mutations (PostToolUse equivalent)"
      }
    ],
    "experimental.session.compacting": [
      {
        "command": "~/.agents/skills/planning-with-files/scripts/inject-plan.sh --context=precompact",
        "description": "Flush pwf state before compaction (PreCompact equivalent)"
      }
    ],
    "session.idle": [
      {
        "command": "~/.agents/skills/planning-with-files/scripts/check-complete.sh || echo '[pwf-enforcer] incomplete phases remain'",
        "description": "Advisory check at session idle (Stop equivalent — Tier 3, notify only)"
      }
    ]
  }
}
```

### 4. Verify hooks loaded

Restart omo session. Run a test:

```bash
# Should trigger tool.before hook
echo "test"
# Should trigger file.changed hook
touch /tmp/pwf-enforcer-test.txt && rm /tmp/pwf-enforcer-test.txt
# Should trigger session.compacting hook (if compaction happens)
```

Check omo logs for hook invocations.

### 5. Test phase enforcement

Try to do something out of phase:

1. Create task_plan.md with Phase 3 in_progress
2. Try to write code without Phase 1 (Spec) complete
3. Hook should fire, agent should be reminded to complete Phase 1 first

### 6. Document in repo

Create `.opencode/oh-my-openagent.json` (project-level, committed) so the team shares the same hooks.

## Tier Reality

omo's host capability tiers (per `planning-with-files` SKILL.md):

| Tier | Behavior | What pwf-enforcer can do |
|---|---|---|
| 1 (Claude Code, Codex CLI) | Hard block | Full enforcement |
| 2 (Cursor, Pi, Kiro) | Follow-up inject | Soft enforcement + retry |
| 3 (OpenCode, Gemini CLI) | Notify only | **Advisory only** |

On OpenCode, pwf-enforcer **cannot hard-block**. Best achievable: advisory reminders + structured injection. For true hard enforcement, switch to Claude Code or Codex CLI.

This is an honest limitation. Document it.

## Common Rationalizations

| Excuse | Reality |
|---|---|
| "pwf 自带 hook,不需要这个" | 在 Claude Code 上自带。在 OpenCode 上没有。 |
| "soft compliance 也够用" | 你跑飞一次就够你怀念 hard gate。 |
| "omo hook 配置很复杂" | 一段 JSON,十分钟搞定。 |
| "OpenCode 不能 hard-block" | 对,但 advisory + structured injection 比裸 SKILL.md 强。 |
| "我手动 git commit progress.md 也行" | 手动 = 漏。Hook 自动 = 不漏。 |
| "skill 描述里写了 'check task_plan.md' 就够了" | 描述是软约束。Hook 是硬触发。 |

## Red Flags

- Hook 配置写错路径 / 写错 JSON 语法
- 没测就直接生产用
- 期望 hard-block 但跑在 OpenCode(Tier 3)
- 没装 pwf 就启用 pwf-enforcer(hook 调不到脚本)
- 多个 pwf-enforcer 配置互相覆盖
- Hook 跑了但 agent 还是跑飞 phase(说明 advisory 不够,需要 Phase 的 hard gate,但 OpenCode 做不到)

## Verification

Before declaring enforced, confirm:
- [ ] Prerequisites installed (omo + pwf)
- [ ] Hook config valid JSON
- [ ] Restarted omo session
- [ ] All 4 hook types tested (tool.before / file.changed / compacting / idle)
- [ ] Phase enforcement tested (try out-of-phase action)
- [ ] Documented Tier 3 limitation
- [ ] Project-level config committed for team sharing
- [ ] `progress.md` actually getting updates (not just advisory firing)

## pwf Integration

This skill exists to enforce pwf. Without pwf installed, this skill is useless. Verify pwf first.

See [pwf-integration.md](../../pwf-integration.md).