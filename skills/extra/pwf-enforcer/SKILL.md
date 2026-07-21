---
name: pwf-enforcer
description: "Hard-enforces planning-with-files (PWF) workflow on OpenCode via a TypeScript plugin (hard layer) plus a concise AGENTS.md reminder (soft layer). Use when running omo + pwf together and need planning discipline preserved across context compression, tool calls, and sessions."
allowed-tools: "Read Write Edit Bash Glob Grep"
---

# pwf-enforcer

## What this skill does

Two-layer enforcement of the planning-with-files (PWF) workflow on OpenCode:

| Layer | Mechanism | Strength | Auto-loaded? |
|---|---|---|---|
| **Hard** | OpenCode plugin at `~/.config/opencode/plugins/pwf-enforcer.ts` | Fires on real OpenCode events; injects plan head via `experimental.chat.system.transform` and `experimental.session.compacting` | Yes — opencode scans `~/.config/opencode/plugins/` at startup |
| **Soft** | User-level AGENTS.md reminder block | Read by agent on every turn; reminder is opt-in | Yes — opencode reads `~/.config/opencode/AGENTS.md` per session |

**This is not routing.** Routing = "which skill/agent handles a request" (controlled by omo category/agent system). PWF enforcement = "force planning files to be visible to the model at the right moments" (event-driven prompt injection).

Different mechanisms, different layers. If the user wants routing tweaks, that's the `omo-integration` skill. This skill is only about PWF discipline.

## When to Use

Use when:
- Run omo + pwf together
- PWF compliance is critical (long-running tasks, on-call, multi-session work)
- Want auto-enforcement instead of relying on agent remembering

NOT for:
- Pure Claude Code (PWF has native hooks there — Claude Code plugin route at `~/.claude/plugins/marketplaces/`)
- Don't use PWF at all
- One-shot quick tasks without a `task_plan.md`

## Process

### 1. Verify prerequisites

```bash
test -d ~/.agents/skills/planning-with-files/ && echo "pwf installed" || echo "install pwf first"
test -d ~/.config/opencode/plugins/ && echo "plugin dir exists" || mkdir -p ~/.config/opencode/plugins
```

If pwf is missing, prompt user to install before continuing. Plugin without pwf is a no-op (warns at load).

### 2. Install the hard layer (plugin file)

Copy `templates/pwf-enforcer.ts` (this skill's bundled template) to the OpenCode plugin directory:

```bash
SKILL_DIR="${CLAUDE_SKILL_DIR:-$HOME/.agents/skills/pwf-enforcer}"
# When installed via npx skills add, files land at ~/.agents/skills/pwf-enforcer/
# When copied manually, point to wherever you put this repo
cp "$SKILL_DIR/templates/pwf-enforcer.ts" ~/.config/opencode/plugins/pwf-enforcer.ts
```

The plugin uses 6 OpenCode hook points (verified against `@opencode-ai/plugin@1.17.18` d.ts + https://opencode.ai/docs/plugins/):

| OpenCode hook (d.ts-verified) | PWF Claude Code hook it replaces | What plugin does | Strength |
|---|---|---|---|
| `experimental.chat.system.transform` | `UserPromptSubmit` (partly) | Append PWF reminder to system prompt on every chat turn | Real — model sees it every turn |
| `tool.execute.before` (modify `output.args`) | `PreToolUse` (partly) | For `bash`: prepend `echo "<plan head>"` so plan appears in tool output | Fragile — bash-only |
| `tool.definition` (modify description) | n/a | Rewrite `write`/`edit` tool descriptions to remind "also update progress.md" | Soft — agent reads description |
| `tool.execute.after` (modify `output.output`) | `PostToolUse` | After `write`/`edit`: append `[pwf-enforcer] Update progress.md` to tool output | Real — agent sees it as tool result |
| `experimental.session.compacting` (push `output.context`) | `PreCompact` | Push plan head into the compaction prompt | **Real hard inject — the killer feature** |
| `event` handler (`event.type === "session.idle"`) | `Stop` | Run `check-complete.sh`, log advisory only | OpenCode Tier 3 — notify only, can't hard-block |

**Note on `session.idle`**: this is NOT a dedicated hook in `@opencode-ai/plugin`. The d.ts Hooks interface lists it as an Event that fires the generic `event` handler with `{ event: { type: "session.idle", ... } }`. Plugin must switch on `event.type`.

**Note on `tui.prompt.append`**: same situation — not a hook, an event. Plugin can intercept via `event` handler but cannot programmatically inject into a running prompt the way Claude Code's `additionalContext` does.

### 3. Install the soft layer (AGENTS.md reminder)

Append to `~/.config/opencode/AGENTS.md` (user-level, applies across projects):

```markdown
## PWF enforcement (soft layer)

If a `task_plan.md` exists (project root or `.planning/<id>/`):
- The `pwf-enforcer` plugin auto-injects plan context on every system prompt turn (via `experimental.chat.system.transform`).
- After every Write/Edit: update `progress.md` with what you just did. If a phase completes, flip its status in `task_plan.md`.
- Before `/compact` or autoCompact: the plugin pushes plan head into the compaction context via `output.context.push()`.
- Stop is advisory only on OpenCode (Tier 3). If phases incomplete, the plugin notifies but you decide.

If `task_plan.md` does NOT exist: this is a quick task, no PWF required.
```

The user can also drop this block into a project-level `AGENTS.md` if they want it scoped per-project instead of globally.

### 4. Verify opencode loads the plugin

#### 4a. TypeScript syntax check (offline)

OpenCode ships with Bun which has `bun check`. If unavailable, install types globally and use `tsc`:

```bash
# Option A: bun
bun check ~/.config/opencode/plugins/pwf-enforcer.ts

# Option B: tsc with @opencode-ai/plugin types
mkdir -p /tmp/pwf-enforcer-check && cd /tmp/pwf-enforcer-check
npm init -y >/dev/null 2>&1
npm i --save-dev @opencode-ai/plugin typescript 2>&1 | tail -3
npx tsc --noEmit --strict --module nodenext --moduleResolution nodenext \
  --target es2022 ~/.config/opencode/plugins/pwf-enforcer.ts
```

Both should exit 0 with no errors. The plugin file's `import type { Plugin } from "@opencode-ai/plugin"` must resolve.

#### 4b. Opencode actually loads it (runtime)

OpenCode scans the plugin directory at session start. To verify:

```bash
# Start a new opencode session, then trigger a tool call
echo "test"
```

The plugin's `experimental.chat.system.transform` should append a PWF reminder to the system prompt on every turn. To confirm, look at opencode logs for:
- Plugin load messages at startup (should appear once)
- Tool output containing `[pwf-enforcer]` after any Write/Edit (when `task_plan.md` exists)

If the plugin does not fire:
- Check file is at exact path `~/.config/opencode/plugins/pwf-enforcer.ts` (case-sensitive)
- Run step 4a — TypeScript syntax error breaks plugin load silently
- Verify pwf is installed (`ls ~/.agents/skills/planning-with-files/scripts/inject-plan.sh`)
- Check opencode logs for plugin error messages

## Tier Reality (Honest Limitations)

OpenCode is Tier 3 per PWF's own classification (https://github.com/anomalyco/opencode — opencode plugin docs):

| What pwf-enforcer achieves | Verdict |
|---|---|
| Plan head injected every turn via `experimental.chat.system.transform` | ✅ Real |
| Plan head injected before bash via `echo` prepend | ⚠️ Fragile (escapes, multi-line) |
| Plan head injected before non-bash tools | ❌ `output.args` mutation can't add context; fallback to `tool.definition` description rewrite (soft) |
| Plan flush before `/compact` via `output.context.push()` | ✅ Real hard injection — most valuable hook |
| PostToolUse reminder after write/edit via `output.output` mutation | ✅ Real |
| Stop hard-block on incomplete phases | ❌ OpenCode Tier 3 — notify only |
| Tool description rewrite for write/edit | ✅ Real (model sees updated description) |

For **real hard enforcement on Stop**, switch to Claude Code or Codex CLI (Tier 1). On OpenCode, plan-survives-compaction is guaranteed, but stop-gate is advisory.

## omo boulder.json Bridge (Future Enhancement, Not Implemented)

omo's boulder system persists active work across sessions (`boulder.json` written by Sisyphus / Atlas). pwf-enforcer currently writes its state to `task_plan.md` + `progress.md` only. A future enhancement:

- On `tool.execute.after` (Write to task_plan.md or progress.md), mirror phase status into omo's `boulder.json` location
- This lets omo resume a PWF-style plan mid-session without losing pwf discipline

**Not implemented** — requires omo boulder.json schema (`code-yeongyu/oh-my-openagent` repo). Tracked as a future plugin enhancement, not a current behavior.

## Why this is not routing (a note for the user)

Sometimes users confuse "make the model do X at every step" with "route this message to skill/agent Y." They are different:

- **Routing** = "this user message → call skill X" (omo category/agent config decides)
- **Prompt injection / context augmentation** = "on every turn / event Y, append instruction Z" (plugin hook decides)

PWF enforcement is the second. The plugin never decides "send this message to skill P." It only decides "on system prompt transform, prepend PWF reminder." Routing lives in `oh-my-openagent.json` `agents`/`categories` config; enforcement lives in the plugin.

If a user complains "pwf-enforcer routes my requests wrong," they're confused about which layer they're touching.

## Common Rationalizations

| Excuse | Reality |
|---|---|
| "omo 自带 hook" | omo has `disabled_hooks` deny list (in `oh-my-openagent.json` schema) but NO `hooks` config field. User-written plugins required. |
| "OpenCode hook 跟 Claude Code 一样" | 不一样。OpenCode plugin API: `tool.execute.before` 不是 `PreToolUse`; `output.args` 不能注入 prompt 上下文; `session.idle` 是 event 不是 hook. |
| "软约束够了" | 软约束 = agent 读完 SKILL.md 后选择不遵守。压 context 时 plan 必定丢失(除非 hard inject via compaction hook)。 |
| "Plugin 复杂" | 6 hook × 5-15 行 = 一个文件 ~120 行。OpenCode 类型完整,IDE 自动补全。 |
| "我手动 git commit progress.md 也行" | 手动 = 漏。Plugin 自动 = 不漏(尤其 `output.output` 改写让 model 在 tool result 里看到提醒)。 |

## Red Flags

- Plugin 路径错(不是 `~/.config/opencode/plugins/pwf-enforcer.ts`)
- 没 `bun check` / `tsc` 验证就 ship(TypeScript 错误会让 plugin 静默不加载)
- 期望 hard-block Stop 但跑在 OpenCode(Tier 3)
- 装了 pwf-enforcer 但没装 pwf(plugin 调不到 inject-plan.sh,变成 no-op)
- 多个 pwf-enforcer 互相覆盖(注意 opencode plugin load order: global plugins 在 project plugins 之前加载,但同 name plugin 会被去重)
- `task_plan.md` 不存在却看到 PostToolUse 提醒(plugin 应该有 plan-exists check)

## Verification

Before declaring enforced:
- [ ] pwf installed at `~/.agents/skills/planning-with-files/`
- [ ] `pwf-enforcer.ts` copied to `~/.config/opencode/plugins/`
- [ ] `bun check` 或 `tsc --noEmit` 通过(plugin 文件 TypeScript 合法)
- [ ] AGENTS.md snippet 已追加到 `~/.config/opencode/AGENTS.md`
- [ ] 测试:重启 opencode,运行 `echo hello` → 触发 `tool.execute.before`
- [ ] 测试:在有 `task_plan.md` 的项目里 Write 文件 → tool output 末尾出现 `[pwf-enforcer] Update progress.md`
- [ ] 测试:在有 `task_plan.md` 的项目里,长 session 触发 `/compact` → 验证 plan head 进了 compaction prompt(可以通过查看 compaction 后的 system prompt 验证)
- [ ] Tier 3 限制已书面记录

## pwf Integration

This skill enforces PWF. Without PWF installed, the plugin is a no-op (warns at load). Verify PWF first.

See [pwf-integration.md](../../pwf-integration.md).

## Plugin Source Reference

The plugin file at `templates/pwf-enforcer.ts` is verified against:
- `@opencode-ai/plugin@1.17.18` d.ts (https://unpkg.com/@opencode-ai/plugin@1.17.18/dist/index.d.ts)
- https://opencode.ai/docs/plugins/ (OpenCode plugin docs)

If `@opencode-ai/plugin` ships a new version with breaking API changes, regenerate the template.
