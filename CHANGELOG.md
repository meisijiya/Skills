# Changelog

All notable changes to meisijiya-skills.

## Unreleased

### Added (v0.5.2 — rollback protocol + review-work critical-severity routing)

Closes the audit gap on "what do we record when code must be rolled back?" — v0.5.1 had requirement-change routing but no symmetric rollback routing. v0.5.2 adds it without inventing a new skill.

**Files modified (2):**

- `skills/core/incremental-implementation/SKILL.md` — new **§ 10 Rollback protocol**:
  - **§ 10.1 触发条件**(5 路:review-work critical / 用户主动 / fix-the-fix / spec-retro / pre-merge cherry-pick 错位)
  - **§ 10.2 协议**(7 步:halt → 选恢复方式 → 标 slice → log → critical 写 postmortem → amend spec → 验证)
  - **§ 10.3 slice 状态机扩展**:新增 6 态 `rolled_back`,必填 `rolled_back_at` / `rolled_back_reason`
  - **§ 10.4 `[rollback]` 日志模板**(7 字段:trigger / severity / recovered / reason / affected / action + optional `[postmortem]` `[test-gap]`)
  - **§ 10.5 Common Rationalizations** + **§ 10.6 Red Flags**
- `skills/core/verification-before-completion/SKILL.md` — Stage 2 step 6 added severity triage: minor/major → new Blocking slice; **critical → trigger § 10 Rollback protocol** (NOT a new slice — implementation is wrong, not missing). Verification checklist updated.

**No historical narrative in skill content:** patch as-written uses pure "when X, do Y" prescription. The v0.5.2 version tag appears only as a section ID; the body never compares against a previous state. Aligns with `docs/agents-md-guide.md` rule #2 ("现状描述,不做历史对比").

**Verified:**
- `validate-skills.sh`: 19 / 19 OK
- `check-marketplace.sh`: OK marketplace.json in sync (19 skills)
- No deletion, no new file. SKILL.md content added: ~80 lines (incremental-implementation § 10) + ~10 lines (verification-before-completion severity triage). Net "skill内容" 增量集中在 § 10。

### Added (v0.5.1 — mid-build requirement change routing)

Closes the gap from the v0.5.0 audit: when users change requirements mid-build (after Slice work has started), the system previously had no protocol — agents either pretended the change didn't happen (Spec/code drift) or started a fresh spec cycle. v0.5.1 introduces a 5-tier change classifier + amend + re-attest + slice status state machine.

**Files modified (2):**
- `skills/core/incremental-implementation/SKILL.md` — slice metadata table gains `status` enum (`pending` / `in_progress` / `complete` / **`deprecated`** / **`superseded`**) + `superseded_by` field; new **§ 9 Mid-build requirement changes** (5-row classification table + 8-step Process + § 9.3 status state machine + Red Flags + Verification additions)
- `skills/core/spec-driven-development/SKILL.md` — new **Step 5.5 Amend Spec mid-build** (when to call, 5-step Process, re-attest, log amendment, "no shortcuts" list) + Step 6 note on re-approval scope + Verification checklist addition

**Why this matters (Matt Pocock-aligned):** the previous design assumed the Spec is locked after Phase 1 approval. Real engineering never works that way — requirements change mid-build, every project knows it. Without an explicit change protocol, agents ship Spec/code drift and lose the audit trail. v0.5.1 makes the change-classifier explicit (5 rows map to 5 routes) so the model has a decision tree instead of improvising.

**No new skill**: the amend workflow lives in `spec-driven-development` (the contract) + `incremental-implementation` (the executor). OMO `atlas` / `team_task` already consume slice metadata; the `status` enum extension + `superseded_by` field are zero-cost additions from their perspective.

**Verified:**
- `validate-skills.sh`: 19 / 19 OK
- `check-marketplace.sh`: OK marketplace.json in sync (19 skills)

### Changed (v0.5.0 — skill system refactor + OMO bridge overhaul)

The v0.4.x skill system had drifted from actual OMO capabilities in three measurable ways: (1) duplicate approval gates, (2) duplicate cleanup pathways now offered by OMO built-ins, and (3) post-implementation review never invoked despite OMO shipping the right primitive. v0.5.0 closes these.

**Architecture changes (per Wave):**

| Wave | Scope | Why |
|---|---|---|
| 1 — Doc drift | `pwf-integration.md` count 16/17 → 19, removed dead `agent-project-structure`, fixed `build-gate-visual-review` timing conflict; `docs/omo-agent-skill-config.md` "18 → 19" + removed dead skill; `README.md` "6 core → 8 core" + Skills section numeric alignment | Inventory must match filesystem before any architectural claim |
| 2 — Core workflow dedup | `brainstorming` absorbs the one-question-at-a-time rule (formerly in `interview-me`), single design artifact → `task_plan.md` Phase 0 (no separate commit); `spec-driven-development` locks PRD/Spec single landing page = `task_plan.md` Phase 1, honest Tier 3 disclosure; `incremental-implementation` slice metadata + slice metadata = `blockedBy / parallel / HITL\|AFK / owner / verify` + post-slice hand-off to **OMO `review-work`** + per-slice human visual QA + `verification-before-completion` **two-stage gate** (Stage 1 in-session + Stage 2 OMO new-context audit + UI then OMO `visual-qa` + user hand-bless) | Stop duplicating what OMO already does; bind end-to-end to OMO primitives |
| 3 — Narrow / thin extras | `interview-me` → thin alias (canonical = `brainstorming`); `code-simplification` → thin alias (canonical = OMO `refactor` / `ponytail-review` / `remove-ai-slops`) + retains only Chesterton's Fence reminder; `documentation-and-adrs` narrowed to "irreversible + cross-time + cross-person" architectural decisions (not daily docs); `build-gate-visual-review` clarified as **design-alignment gate** (not human QA), reads from `task_plan.md` (not separate `spec.md`); `security-and-hardening` Step 6.5 explicitly routes to OMO `security-research` (v0.4.0 falsely claimed OMO had no security skill); `performance-optimization` drops frontend CWV (routed to OMO `frontend`) | Shrink + route, not duplicate |
| 4 — Repo layout | `writing-skills` moved from `.core/` (9 → 8) to `.extra/` (10 → 11); `.claude-plugin/marketplace.json` synced; `AGENTS.md` Section A catalog auto-derived counts; in-README install example updated | Catalog consistency |
| 5 — Independent review | Oracle sub-agent in a fresh session verified 17 audit items; 16 PASS, 3 PARTIAL (README numeric typo + omo-config stale refs + pwf-integration arithmetic) → all fixed before declaring done | Matt Pocock-style "isolated fresh-context review" prevents self-rationalization |

**Files modified (20) / net lines (-779 / +662, -117 lines)**
- 5 docs / configs (`README.md`, `AGENTS.md`, `pwf-integration.md`, `docs/omo-agent-skill-config.md`, `.claude-plugin/marketplace.json`)
- 5 core SKILL.md (`brainstorming` +92 / `incremental-implementation` +118 / `source-driven-development` +39 / `spec-driven-development` +73 / `using-meisijiya-skills` +41 / `verification-before-completion` +69)
- 1 core/README.md + 1 extra/README.md (catalog counts)
- 6 extra SKILL.md (`build-gate-visual-review` +107 / `code-simplification` +120 narrowed / `documentation-and-adrs` +186 narrowed / `interview-me` +98 narrowed / `performance-optimization` +98 narrowed / `security-and-hardening` +48)
- 1 file delete + 1 dir migrate (`writing-skills` core → extra)

**No new skill added.** Net TODO reduction: 3 skills dropped to alias form, 2 sub-routines moved out to OMO built-ins, 1 phase shifted.

**Verified:**
- `validate-skills.sh`: 19 / 19 OK (2 warnings = intentional superpowers-style dispatcher thinness on `using-meisijiya-skills` + `pwf-enforcer`)
- `check-marketplace.sh`: OK marketplace.json in sync (19 skills)
- Independent fresh-context Oracle review: 17 / 17 PASS after 3 follow-up fixes

### Added (v0.4.0 — superpowers integration + AGENTS.md enhancement)

**3 superpowers skills vendored to `.core/`:**
- `brainstorming` — HARD-GATE pre-design exploration; "no implementation before user-approved design"
- `verification-before-completion` — discipline layer: NO COMPLETION CLAIMS WITHOUT FRESH VERIFICATION EVIDENCE (Iron Law)
- `writing-skills` — meta: TDD for process documentation; extract repeated workflows into reusable skills

**Why these 3 in core (not extra):** Cross-cutting discipline / process skills that ALL work should use, not opt-in utilities.

**Inspired by superpowers' skill-integration patterns:**
- `using-meisijiya-skills` enhanced with EXTREMELY-IMPORTANT framing + Skill Priority section (process skills first, then implementation, then discipline, then meta) + Skill capture process step (writing-skills invoked when patterns repeat)
- Description field rules (per superpowers' writing-skills): "Use when..." + triggering conditions only, NO workflow summary (which causes agents to skip reading the skill)

**AGENTS.md Section A enhanced:**
- Added "Discipline layer" subsection: invoke `verification-before-completion` before any completion claim
- Added "Skill chains (process order)" subsection: brainstorming → spec → incremental → TDD → verification
- Catalog now: 9 core (was 6) + 10 extra = 19 total
- All skill mentions carry `~/.agents/skills/<name>/SKILL.md` install paths
- New convention bullets: "Verify before claiming completion" + "Capture repeated workflows as skills"

**AGENTS.md Section C enhanced (project-level AGENTS.md):**
- New "Skill reference convention" subsection: when project-level AGENTS.md references a skill, **must include install path as markdown link**
- Failure detection: grep-based check that all `~/.agents/skills/<name>/SKILL.md` paths resolve to installed files
- Periodic check: re-run `validate-skills.sh` + `check-marketplace.sh` from meisijiya-skills repo
- Addresses: "项目级AGETNS.md的skill引用使得后续生成的项目级skill出现问题可以及时修复"

**Files modified (7):**
- `AGENTS.md` — Section A + Section C (~25 new path refs in injected block)
- `.claude-plugin/marketplace.json` — meisijiya-core plugin entries 6 → 9
- `skills/core/using-meisijiya-skills/SKILL.md` — rewrite (181 lines, was ~150)
- `skills/core/brainstorming/SKILL.md` — new (139 lines)
- `skills/core/verification-before-completion/SKILL.md` — new (139 lines)
- `skills/core/writing-skills/SKILL.md` — new (178 lines)
- `skill-anatomy.md` — "引用其他 skill" section: now requires install path

**Eval cases (3 new):**
- `brainstorming.json` — 3 positive + 3 negative + 2 behavioral
- `verification-before-completion.json` — 4 positive + 3 negative + 3 behavioral
- `writing-skills.json` — 3 positive + 3 negative + 3 behavioral

**Verified:**
- `validate-skills.sh`: 19/19 OK (was 16)
- `check-marketplace.sh`: OK marketplace.json in sync (19 skills)
- All 19 SKILL.md files have frontmatter
- `inject-agents-md.sh` round-trip: extracts 57 lines, 25 path references preserved
- Path-sweep audit: 0 missing paths across AGENTS.md + 16 SKILL.md

**Tag:** v0.4.0 (was v0.3.0)

### Added (skill cross-reference path convention)

Every meisijiya skill mention in agent-facing docs now carries its install path (`~/.agents/skills/<name>/SKILL.md`) so the agent can find the file when invoked.

**Why:** AI matches a skill by name (e.g., "use interview-me") but doesn't know where to read it from — only the agent's installed skill tree at `~/.agents/skills/<name>/` is guaranteed to exist after `npx skills add`. Without explicit paths, AI guesses or fails to load.

**Scope:** 17 agent-facing files updated (1 AGENTS.md + 16 SKILL.md files).

**Convention:**
- AGENTS.md Section A (injected block) and each SKILL.md: install path `~/.agents/skills/<name>/SKILL.md` as markdown link
- Repo-source docs (README, skill-anatomy.md): repo paths `skills/<dir>/<name>/SKILL.md` (for human browsing on GitHub)
- Self-references (e.g., `using-meisijiya-skills` mentioning itself): exempt — the file IS the path

**Files modified:**
- `AGENTS.md` Section A catalog tables (6 core + 10 extra skills, plus 6 omo-integration entries)
- `AGENTS.md` Section B + C (contributor + user guide references)
- `skills/core/using-meisijiya-skills/SKILL.md` (catalog tables, rationalizations, red flags)
- `skills/core/spec-driven-development/SKILL.md` (1 ref to interview-me)
- `skills/core/incremental-implementation/SKILL.md` (1 ref to test-driven-development)
- `skills/extra/designer-handoff/SKILL.md` (3 refs)
- `skills/extra/interview-me/SKILL.md` (1 ref to spec-driven-development)
- `skills/extra/documentation-and-adrs/SKILL.md` (1 ref to interview-me; removed stale `agent-project-structure` reference)

**Cleanup:** removed stale `agent-project-structure` skill reference in `documentation-and-adrs/SKILL.md` (skill was deleted in commit dfff240; convention lives on in user-level AGENTS.md `meisijiya-extras` block).

**Verified:**
- Audit script: 17 files, 0 missing paths (excluding intentional self-references)
- `validate-skills.sh`: 16/16 OK
- `check-marketplace.sh`: OK marketplace.json in sync
- `inject-agents-md.sh` round-trip: extracts 36 lines from Section A, 13 path references preserved

### Fixed (CI bijection false-positive on README.md)

CI run #29180590851 failed at step "Verify skill↔eval bijection":
```
skills without eval: {'README.md'}
```

**Root cause:** inline Python used `os.listdir(root)` to enumerate skills, which returned `README.md` alongside actual skill directories. The script then treated `README.md` as a skill missing its eval case.

The Node 20 deprecation warning in the same run was unrelated (a yellow notice, not the failure).

**Fix:** filter `os.listdir()` results to directories that contain a `SKILL.md`. README.md / docs / scripts / etc. are now correctly skipped.

**Verified locally:**
- New logic: `Bijection OK: 16 skills ↔ 16 evals`
- Old logic: `missing={'README.md'}` (confirmed the bug)
- validate-skills.sh: 16/16 OK
- check-marketplace.sh: OK marketplace.json in sync

### Added

- **`.github/workflows/validate-skills.yml`** — added `actions/setup-node@v4` pinning `node-version: '24'`. The workflow itself doesn't run Node, but `actions/checkout@v4` internally targets Node 20 which GitHub deprecated (Sept 2025). Pinning silences the deprecation warning.

### Added

- **`skills/core/README.md`** — human-readable catalog of the 6 must-install skills:
  - One-line description per skill (what it does, when to use)
  - "Why must-install" table (consequence of skipping each one)
  - Install command

- **`skills/extra/README.md`** — human-readable catalog of the 10 opt-in skills + decision support:
  - "How to choose" table: pick skills based on project type (UI / production / multi-engineer / using pwf / etc.)
  - One-line description per skill
  - Dependency table (which skill needs which other tool installed first)
  - Install command

- **`README.md`** updates:
  - New "Skills" section with explicit jump links to both subdirectory READMEs
  - Repo structure tree updated to show README.md in each skills/ subdirectory
  - "当前状态" block refreshed (v0.2.2 → v0.3.0, recent Unreleased commits listed)

### Added

- **`scripts/check-marketplace.sh`** — automated bidirectional drift check between `.claude-plugin/marketplace.json` and `skills/` filesystem:
  - Verifies every skill under `skills/<dir>/<name>/SKILL.md` is listed in some plugin entry's `skills[]` array
  - Verifies every manifest path exists on disk
  - Verifies all paths start with `./` (CLI requirement)
  - Exits 1 with diff on drift, 0 with count on match
  
  Wired into `.github/workflows/validate-skills.yml` as a CI step. New skill additions that forget to update marketplace.json will fail CI.

### Documentation

- **`skill-anatomy.md`** — added a new "Marketplace 清单" section documenting:
  - File structure (`plugins[].name` + `plugins[].skills[]`)
  - Rules (path must start with `./`, paths to skill dirs not files, single group per plugin)
  - 5-step checklist for adding a new skill (write SKILL.md → update manifest → add eval → run checks)
  - Known constraints (CLI groups by pluginName not by directory)
- **`AGENTS.md` Section B** — added bullet linking to skill-anatomy.md for the marketplace convention

### Added

- **`.claude-plugin/marketplace.json`** — declares the plugin as TWO named units (`meisijiya-core` + `meisijiya-extra`) so the vercel-labs/skills CLI picker shows skills under two distinct group headers matching the source directory layout.

  Initial attempt was `.claude-plugin/plugin.json` with a single `name="meisijiya-skills"` — produced one merged group "Meisijiya Skills" containing all 16 skills. Reading `vercel-labs/skills` src/add.ts confirmed: `pluginName` (assigned per skill from `getPluginGroupings`) drives the group header. Multiple groups require multiple plugin entries — only `marketplace.json` supports that schema.

  Schema (from vercel-labs/skills src/plugin-manifest.ts):
  ```json
  {
    "plugins": [
      { "name": "meisijiya-core",  "skills": ["./skills/core/..."] },
      { "name": "meisijiya-extra", "skills": ["./skills/extra/..."] }
    ]
  }
  ```

  After this, `npx skills add https://github.com/meisijiya/Skills` displays:
  ```
  ◆ meisijiya-core (6)
    □ debugging-and-error-recovery
    □ incremental-implementation
    □ source-driven-development
    □ spec-driven-development
    □ test-driven-development
    □ using-meisijiya-skills

  ◆ meisijiya-extra (10)
    □ api-and-interface-design
    □ ...
  ```

  **Maintenance:** each `skills[]` array must be kept in sync with the filesystem. Drift = un-installable via picker (still installable via direct path). Add CI check in follow-up if drift becomes a problem.

### Added (v0.4.2 — AGENTS.md hygiene tooling)

**`docs/agents-md-guide.md`** (116 lines) — Records the rules for writing `AGENTS.md` content: no version narrative / historical comparisons / change announcements in inject block; 4 core rules + 4 error-fix examples (E1-E4); 3 ways to handle stale-prone counts (delete / manual sync / script sync); where history narrative belongs (`CHANGELOG.md` / `git log` / `git tag` / `README.md` release section). Referenced from user-level `~/.config/opencode/AGENTS.md` `meisijiya-extras` segment.

**`scripts/inject-agents-md.sh` auto-derive** — Section A's `(9)` / `(10)` skill counts now auto-derived from `.claude-plugin/marketplace.json` via `grep -c` (no `jq` needed). Idempotent: source numbers may drift, rendered block always matches current manifest. Falls back to source values with `(?)` in the output line if marketplace.json is missing or has zero counts. `AGENTS.md` Section B documents this.

**`scripts/check-agents-md-narrative.sh`** — Validates that the meisijiya-skills inject block in any `AGENTS.md` contains no version narrative. Patterns: `v0.0.0`, `\bwas\b`, `\bnow has\b`, `\bnewly added\b`, `\bnew in v[0-9]`, `\bsince v[0-9]`. Exit 0 = clean, 1 = dirty. Default args: check repo `AGENTS.md` + user-level `~/.config/opencode/AGENTS.md`.

**`scripts/hooks/pre-commit` + `scripts/install-hooks.sh`** — Pre-commit hook template auto-checks staged `AGENTS.md` files via `git diff --cached --diff-filter=ACMR`. Installer copies template to `.git/hooks/pre-commit` and `chmod +x`. Idempotent install. Bypass: `git commit --no-verify`.

**Triggered by user feedback (v0.4.0 → v0.4.1):** adding 3 superpowers skills exposed that the inject block can carry version narrative ("v0.4.0 status" written into the user-level `meisijiya-extras` segment polluted agent startup context). v0.4.2 establishes rules + tooling to prevent recurrence: rules in the guide, runtime gate via the pre-commit hook, source-of-truth via auto-derived counts.

### Fixed (v0.4.3 — Oracle review nits)

Oracle review of v0.4.2 returned PASS-WITH-NITS. Patches:

- **`docs/agents-md-guide.md`** (3 stale refs):
  - L82 + L84 — table row 3 + label updated from "用 `check-marketplace.sh` 在 CI 验证 `wc -l`" (CI-validation approach) to "注入时脚本自动派生" (v0.4.2 method); the "当前用做法 2" sentence below the table replaced with description of the actual v0.4.2 auto-derive
  - L103 — manual grep example regex now has all 6 patterns matching the check script (was missing `\bnew in v[0-9]` and `\bsince v[0-9]`)
  - L108 — "(可选)做 pre-commit hook...脚本占位...留待真痛了再加(YAGNI)" replaced with pointer to real `scripts/check-agents-md-narrative.sh` + `scripts/hooks/pre-commit` + `scripts/install-hooks.sh`
- **`scripts/check-agents-md-narrative.sh`** — awk block extractor now has `next` after `$0 == e` (defensive parity with `scripts/inject-agents-md.sh`'s awk). HTML comment markers don't carry version narratives, so this never fired; consistency fix.
- **`~/.config/opencode/AGENTS.md` meisijiya-extras segment** — cross-ref to `docs/agents-md-guide.md` self-referenced "v0.4.0" in the trail "(移走 v0.4.0 status 段)的依据", violating the rule the guide itself articulates. Replaced with a one-line version-free pointer. (User-level file, not in repo.)

### Added (v0.5.0 — OpenCode plugin for high-frequency skill invocation)

- **`.opencode/plugins/meisijiya-skills.js`** (NEW, 137 lines): Hard-layer OpenCode plugin that auto-injects the `using-meisijiya-skills` bootstrap content into the first user message of every session, and registers `~/.agents/skills` with OpenCode's skill tool. Pattern adapted from [obra/superpowers' `superpowers.js`](https://github.com/obra/superpowers/blob/main/.opencode/plugins/superpowers.js).
  - Hooks used: `config` (register skills dir) + `experimental.chat.messages.transform` (inject bootstrap)
  - Idempotent: guarded by `EXTREMELY_IMPORTANT` marker; survives session compaction (OpenCode issue #17820 — hook re-fires after compact)
  - Bootstrap source: `~/.agents/skills/using-meisijiya-skills/SKILL.md` (frontmatter stripped, body wrapped in `<EXTREMELY_IMPORTANT>` tags)
  - No external deps (pure Node `fs/path`; Bun runtime, native ESM)

**SDK verification** (2026-07): hook names + signatures matched against official OpenCode [`packages/plugin/src/index.ts`](https://raw.githubusercontent.com/anomalyco/opencode/dev/packages/plugin/src/index.ts). `Config.skills.paths` schema confirmed at [`packages/core/src/v1/config/skills.ts`](https://raw.githubusercontent.com/anomalyco/opencode/dev/packages/core/src/v1/config/skills.ts#L5). Critical gotcha: in-place mutation required ([issue #25754](https://github.com/anomalyco/opencode/issues/25754)) — `output.messages = newArr` is a silent no-op. Plugin uses `unshift` on `parts[]`, which is safe.

**Install:**

```bash
mkdir -p ~/.config/opencode/plugins
ln -sf "$(pwd)/.opencode/plugins/meisijiya-skills.js" \
       ~/.config/opencode/plugins/meisijiya-skills.js
```

**Verified:**
- Node syntax check (forced ESM): OK
- Functional test (import + invoke hook with synthetic user message): bootstrap injected, marker present
- Symlink live at `~/.config/opencode/plugins/meisijiya-skills.js`

**Triggered by:** user observed that `using-meisijiya-skills` was listed in `<available_skills>` but never auto-invoked in their sessions (~0% invocation rate). The hard-layer plugin mirrors the superpowers pattern that achieves ~80-90% invocation rate.

### Added (v0.5.1 — bootstrap content upgrade + plugin diagnostics)

Two atomic commits on top of v0.5.0, in response to the v0.5.0 acceptance test failure:

- **`skills/core/using-meisijiya-skills/SKILL.md`** (181 → 198 lines): Upgraded body to superpowers-grade strong imperatives.
  - Added `<SUBAGENT-STOP>` block (subagent exemption pattern from `obra/superpowers`)
  - Added `## The Rule` section: "Invoke skills BEFORE any response or action — including clarifying questions, exploring the codebase, or checking files"
  - Added explicit `announce "Using [skill] to [purpose]"` pattern
  - Strengthened `## Red Flags` table to superpowers' 12-row "STOP, you're rationalizing" format
  - Pattern source: [`obra/superpowers` `using-superpowers/SKILL.md`](https://github.com/obra/superpowers/blob/main/skills/using-superpowers/SKILL.md)
  - Runtime copy at `~/.agents/skills/using-meisijiya-skills/SKILL.md` (byte-identical with repo source)

- **`.opencode/plugins/meisijiya-skills.js`** (137 → 165 lines): Kept diagnostic logging (8 `log()` calls writing to `/tmp/meisijiya-skills.log`).
  - Confirms plugin loaded, hooks fired, bootstrap injected — used to verify v0.5.0 acceptance test
  - Useful for future debugging of similar load/inject issues
  - Disable by deleting `/tmp/meisijiya-skills.log` and removing the log calls

**Triggered by**: v0.5.0 acceptance test (`let's make agent`) showed plugin loaded + bootstrap injected correctly, but model still skipped skill invocation. Root cause was bootstrap content (too soft), not plugin load. New content matches `obra/superpowers` patterns.

**Known limitations** (from [superpowers issue #54](https://github.com/obra/superpowers/issues/54)): even with hard-layer plugin + superpowers-grade imperatives, invocation rate is ~80-90%, not 100%. Model can still rationalize its way out (especially in Plan Mode — issue #1667, #439). Path to higher rates: add `tool.execute.before` hook to block non-skill-issued tool calls.

## v0.3.0 (2026-07-12)

### Changed (skill directory rename for `npx skills add` grouping)

`skills/.core/` → `skills/core/`, `skills/.extra/` → `skills/extra/` (removed leading dots).

**Why:** `vercel-labs/skills` CLI treats directories starting with `.` as hidden and does NOT display them as groups in the install picker. Without grouping, all 16 skills show as a flat list. Renaming to non-hidden directories makes them appear as 2 groups: `core` (6 skills, must-install) and `extra` (10 skills, opt-in). Reference image: mattpocock/skills uses this pattern (`Mattpocock Skills` + `Other` groups).

**Migration for users on the old paths:** none — `npx skills add <repo> --from skills/.core` no longer works; use `--from skills/core` instead. The skill NAMES didn't change, so installed skills at `~/.agents/skills/<name>/` are unaffected.

**Files touched:** 7 (README.md, AGENTS.md, pwf-integration.md, docs/p0-outline.md, .github/workflows/validate-skills.yml, scripts/install.sh, skills/core/using-meisijiya-skills/SKILL.md). Historical CHANGELOG entries preserved as-is (they reference the old paths in past tense, which is correct historical record).

### Changed (AGENTS.md rewrite per Oracle review)

Oracle audit verdict: 4 of 6 axes NEEDS-FIX. Section A reduced from 51 → 36 lines; dropped repo-internal noise and duplicates with existing user-level content.

**Removed** (was repo-maintenance noise or duplicate content in user-level AGENTS.md):
- "Re-sync" section (commands the user can't run — they don't have the script)
- "Install paths" section (user already installed to receive the injection)
- `task_plan.md` global convention (pwf-specific, not applicable to all projects)
- `context7 MCP` reminder (duplicates existing Grilling "Look it up first")
- `slice:` commit prefix (meisijiya-skills repo convention, not global)

**Changed**:
- Opening line: declarative "Skill system for..." → imperative "Use this skill system for the omo + pwf stack."
- "omo integration" table → compact bullet list with cross-link to existing `meisijiya-extras` block (no more duplicate MCP/agent listings)
- `using-meisijiya-skills` row: "Sisyphus + IntentGate handoff, atlas agent" → "Sisyphus (executing delegation), atlas (todo orchestration)" (dropped jargon)
- Added scope disclaimer: "These conventions apply globally unless a project-level AGENTS.md overrides them."

### Fixed (inject script edge case)

`scripts/inject-agents-md.sh` `has_block()` was checking for the begin marker substring anywhere in the file. If a user's notes happened to contain the marker string (e.g., as a section placeholder), the script would silently skip — reporting "Block already present ... idempotent: no change" without injecting anything. **Silent failure**.

Replaced with stateful awk: tracks seen_begin flag, only returns true when a paired end is found. Verified with three fixtures:
- paired block → returns 0 (true)
- stray begin only → returns 1 (false, proceeds to inject)
- no markers → returns 1 (false)

### Changed (install path unification — BREAKING for `--global` users)

**`scripts/install.sh --global`** target: `~/.config/opencode/skills/` → `~/.agents/skills/`.

**Why:** `npx skills add <repo>` (canonical, vercel-labs CLI) installs to `~/.agents/skills/`. `scripts/install.sh --global` previously went to `~/.config/opencode/skills/` (omo native), causing two problems:
1. Two different global paths for the same skill system — confusing mental model
2. Cross-CLI dedup didn't work — `npx skills add` could see `~/.config/opencode/skills/<name>` and refuse to install to `~/.agents/skills/<name>` (or vice versa)

Now both methods converge on `~/.agents/skills/`. OpenCode discovers skills from there.

**Project-level path unchanged:** `scripts/install.sh --target <path>` still installs to `<path>/.opencode/skills/` (omo's per-project convention; not used by skills CLI).

**Migration for users on the old `--global` path:**
```bash
# If you previously ran --global and have skills at ~/.config/opencode/skills/meisijiya-*:
ls ~/.config/opencode/skills/ | grep ^meisijiya-  # check what's there
rm -rf ~/.config/opencode/skills/meisijiya-*      # safe to delete — they're at ~/.agents/skills/ now (or will be after re-running --global)
```

Verified via `scripts/install.sh --global --dry-run`:
```
Target: /home/ljh2923/.agents/skills
Skills: 6
```

### Fixed (audit cleanups from path/coherence review)

User requested a full audit before using the system. Findings → fixes:

- **`pwf-integration.md` line 36** — fixed stale reference to "configure omo hooks" + `oh-my-openagent.json`. omo has NO user-writable hooks field (only `disabled_hooks` deny list). The actual approach is an OpenCode TypeScript plugin at `~/.config/opencode/plugins/pwf-enforcer.ts`. This was a remnant from before the pwf-enforcer rewrite (`e1330d2`). Also fixed the count "17 个 skill (11 主流程 + 4 sub-phase + 2 一次性 = 17)" → "16 个 skill (10 + 4 + 2 = 16)" since `agent-project-structure` was consolidated in `dfff240`.
- **`README.md` line 8** — fixed section reference: "`~/.config/opencode/AGENTS.md`(`omo-integration` 段)" → "(`meisijiya-extras` 段)". The actual injected block uses `<!-- meisijiya-extras_START -->` markers, not "omo-integration".
- **`README.md` status block (lines 149–156)** — replaced stale v0.1.0 / "17 SKILL.md / 17 eval" with current state: last tag v0.2.2 (16 / 16), unreleased commits listed with hashes.
- **`pwf-enforcer.ts`** — added `PWF_DIR` env var override for `PWF_DIR` (consistency with `bin/meisijiya`'s `OPENCODE_PLUGINS_DIR` override). Falls back to `${HOME}/.agents/skills/planning-with-files/`.

### Added

- **`bin/meisijiya` — lite CLI for OpenCode plugin management (65 lines, bash)**
  Two commands only:
  - `plugin list` — list installed plugins in `~/.config/opencode/plugins/` with status (looks for `import type { Plugin` to confirm it's actually a plugin)
  - `plugin verify` — run `bun check` on all installed `.ts` plugins
  Requires `bun` for verify. Override plugin directory via `OPENCODE_PLUGINS_DIR` env var.

  **Scope: intentional lite per maintainer recommendation. Does NOT do:** `plugin add`, `plugin remove`, `inject`, `status`, `doctor`, `update` — those are YAGNI until they hurt. `git revert` this commit if a fuller CLI was wanted.

  **Why a CLI at all:** skill install is covered by `npx skills add`. Plugin install currently requires manual `cp templates/x.ts ~/.config/opencode/plugins/` + `bun check`. Closing that small gap doesn't justify a 150-line monorepo CLI; 65 lines of bash does.

### Changed (skill consolidation)

Dropped 2 skills that were pure documentation (no executable workflow). Content moved to user-level `~/.config/opencode/AGENTS.md` as condensed reference blocks.

- **Removed `skills/.extra/agent-project-structure/`** + eval case. The 10-folder agent-project layout is now a 10-line section in `~/.config/opencode/AGENTS.md` under `<!-- meisijiya-extras_START -->`.
- **Removed `skills/.extra/omo-integration/`** + eval case. The omo features cross-reference map is now a 7-line section in the same place.

**Why:** Skills without workflow are redundant — agents read user-level AGENTS.md every turn, no skill-matching needed. Removing them shrinks the injected catalog (12 → 10 in `.extra/`).

### Changed (pwf-enforcer rewrite)

**Previously:** `skills/.extra/pwf-enforcer/SKILL.md` documented a fake mapping table of "omo hook events" (`session.created`, `tool.before.*`, `file.changed`, `session.idle`, `experimental.session.compacting`) and instructed users to add a `hooks:` field to `~/.config/opencode/oh-my-openagent.json`. **None of this was real.** omo's actual schema has only `disabled_hooks` (a deny list), not a user-writable `hooks` config. Several event names were fabricated or wrong.

**Now:** pwf-enforcer documents the real OpenCode plugin API (`@opencode-ai/plugin@1.17.18` d.ts-verified) and ships a verified plugin template:

- **`templates/pwf-enforcer.ts`** — 6-hook TypeScript plugin, type-checks clean with `tsc --noEmit --strict` against `@opencode-ai/plugin` + `@types/node`. Hooks used: `experimental.chat.system.transform` (system-prompt reminder), `tool.definition` (rewrite write/edit descriptions), `tool.execute.before` (bash echo prepend), `tool.execute.after` (append reminder to tool output), `experimental.session.compacting` (push plan head to compaction prompt), `event` handler (catch `session.idle`).
- **Two-layer enforcement** — hard layer (the plugin, fires automatically) + soft layer (concise AGENTS.md reminder block, opt-in reading). Both installable from the skill.
- **Routing clarification** — explicit note: pwf-enforcer is prompt injection at events, NOT routing. Routing = which skill/agent handles a request (omo category/agent config). Different mechanisms, different layers.

### Added

- **`AGENTS.md` at repo root** — canonical agent context file with 3 sections:
  - **Section A**: The injectable block (between `<!-- meisijiya-skills:start -->` markers)
  - **Section B**: Contributor guide for adding new skills (refers to `skill-anatomy.md`)
  - **Section C**: User guide for `AGENTS.md` supplement conventions (project layout, operations)

### Changed

- **`scripts/inject-agents-md.sh`** now reads from `AGENTS.md` Section A (extracting content between sentinel markers via awk), instead of a separate `templates/AGENTS-snippet.md` file. **Single source of truth** for the injectable content.
- **`README.md`** repo structure updated to reference `AGENTS.md` (not `templates/AGENTS-snippet.md`).

### Removed

- **`templates/AGENTS-snippet.md`** — content moved to `AGENTS.md` Section A. Templates directory is now empty (git doesn't track, so effectively gone).

### Rationale

User feedback: AGENTS.md (the canonical agent context) should serve dual purpose:
1. Source of truth for `inject-agents-md.sh` (script reads Section A)
2. Self-contained doc users can browse on GitHub and copy manually

Having the snippet in a separate `templates/AGENTS-snippet.md` was unneeded indirection — Section A of AGENTS.md IS the template.

### Earlier unreleased (still relevant)

- **README + install.sh**: promoted `npx skills add <repo>` as the recommended install method. `scripts/install.sh` demoted to advanced.

No tag bump (docs-only structural change). Next tag will be the next functional release.

### Rationale

Both methods work (OpenCode discovers skills from both `~/.config/opencode/skills/` and `~/.agents/skills/`), but skills CLI is now the de-facto canonical install method for the broader agent skill ecosystem (pwf, html-ppt-skill, ui-ux-pro-max are all installed there). Mixing install locations causes duplicate copies. Users using skills CLI for other skills should use it for this one too.

No tag bump (docs-only change). Next tag will be the next functional release.

## [0.2.2] - 2026-07-11

### Changed

- **`security-and-hardening`** — added Step 6.5: omo `security-research` mode (3 vulnerability hunters + 2 PoC engineers in parallel) for production-critical code + `grep_app` MCP for known CVE pattern search. Updated description and Pre-deployment gate (Step 7) to cross-reference the omo audit.
- **`performance-optimization`** — added omo `lsp` MCP to Step 3 (Profile) for bottleneck localization in large codebases + `analyze` mode reference in Step 6 (Add a guard). Updated description.
- **`omo-integration/SKILL.md`** — updated MCP table (lsp → performance) and Modes table (`analyze` and `security-research` rows).
- Both eval cases updated with new behavioral scenarios for the omo integrations.

### Design rationale

Per Oracle's advice from the v0.2.0 review: these are the two highest-value remaining omo integrations. `security-and-hardening` gains genuinely new capability (parallel hunter audit is qualitatively different from a sequential checklist). `performance-optimization` gains speed (lsp tracing is faster than grep in large codebases). All other potential integrations were assessed as low-impact and deferred.

## [0.2.1] - 2026-07-11

### Added (infrastructure for omo ecosystem)

- **`scripts/inject-agents-md.sh`** — opt-in, idempotent script that appends meisijiya-skills meta-info (skill catalog + omo integration summary + conventions) to user-level `AGENTS.md`. Uses sentinel markers for idempotency. Supports `--target`, `--local`, `--dry-run`, `--remove`. **Does NOT modify omo's routing or hooks.**
- **`templates/AGENTS-snippet.md`** — the meta-info block that gets injected. Concise (53 lines) — full skill details stay in `omo-integration/SKILL.md`.
- **`docs/omo-agent-skill-config.md`** — guidance for constraining per-agent skill lists in `oh-my-openagent.json`. Recommends which of the 18 meisijiya-skills each omo agent should have (Sisyphus gets all, others get curated subset). **User-applied, not auto-applied.**

### Updated

- `omo-integration/SKILL.md` — added "Distributing meta-info to user-level AGENTS.md" and "Per-agent skill list config" sections that reference the new artifacts.

### Design rationale

The user asked: can meisijiya-skills do what superpowers does (append skill meta-info at startup)? Answer: superpowers uses an OpenCode plugin registration (not a hook); we use a simpler opt-in script that writes to `AGENTS.md`. Both achieve "agent knows what skills are available at session start" without forcing modifications to omo's routing.

> **Parked for future**: Oracle advised v0.2.1 should also integrate `security-and-hardening` (security-research mode + grep_app) and `performance-optimization` (lsp MCP). Not done in this release — separate scope.

### Added

- **`omo-integration/SKILL.md` + eval case** — cross-reference map of meisijiya-skills to omo features (MCPs, agents, built-in skills, modes, categories). Read at session start when running under omo.

### Changed

- **5 priority skills now explicitly invoke omo features:**
  - `source-driven-development` — context7 MCP (primary, replaces WebFetch), grep_app MCP (real-world examples), websearch MCP (fallback)
  - `debugging-and-error-recovery` — added Step 2.5 "Escalate to oracle" (omo read-only consultation when stuck); lsp MCP for goto_definition/find_references in localization
  - `incremental-implementation` — delegates slice todo tracking to omo's atlas agent; uses omo's git-master skill for atomic commits + branch hygiene
  - `designer-handoff` — frontend agent now runs under omo's `visual-engineering` category (Gemini 3.1 Pro) + loads omo's `frontend-ui-ux` skill
  - `using-meisijiya-skills` — strengthened Sisyphus + IntentGate handoff documentation; added omo atlas agent reference for todo orchestration

### Design rationale

omo is the orchestration layer; meisijiya-skills is the workflow discipline. v0.1.x focused on the discipline (skills, evals, scripts). v0.2.0 deepens the integration: each skill now knows which omo feature to leverage, avoiding redundant WebFetch calls, manual commits, general-agent UI work, etc.

## [0.1.3] - 2026-07-11

### Fixed

- **Over-broad fix in v0.1.2 reverted for this repo's own paths.** v0.1.2 changed all `~/.config/opencode/skills/` refs to `~/.agents/skills/` — too broad. Correct rule:
  - **Skills installed via `vercel-labs/skills` CLI** (pwf, html-ppt-skill, ui-ux-pro-max) → `~/.agents/skills/`
  - **This repo's own install paths** (`scripts/install.sh --global`) → `~/.config/opencode/skills/` (omo's native)
  - **omo runtime config** (`oh-my-openagent.json`) → `~/.config/opencode/oh-my-openagent.json` (unchanged)

Reverted:
- `scripts/install.sh` — `--global` default target + 2 comments back to `~/.config/opencode/skills/`
- `README.md` — `--global` comment back to `~/.config/opencode/skills/`

Kept (v0.1.2 fix was correct for these):
- `pwf-enforcer/SKILL.md` — pwf at `~/.agents/skills/`
- `build-gate-visual-review/SKILL.md` — html-ppt-skill at `~/.agents/skills/`
- `designer-handoff/SKILL.md` — ui-ux-pro-max at `~/.agents/skills/`
- `evals/cases/build-gate-visual-review.json` — html-ppt-skill refs

## [0.1.2] - 2026-07-11

### Fixed

- **Skills-CLI-managed skill paths corrected** from `~/.config/opencode/skills/` → `~/.agents/skills/`. The canonical location for `vercel-labs/skills` CLI global installs is `~/.agents/skills/`, not omo's local config dir. Applies to skills that users install via `npx skills add` (pwf, html-ppt-skill, ui-ux-pro-max). Does NOT apply to meisijiya-skills' own install paths (those use omo's native locations — see v0.1.3 for the correction). Fixes:
  - `pwf-enforcer/SKILL.md` — 4 path refs (verify + 3 hook commands)
  - `build-gate-visual-review/SKILL.md` — 3 path refs (verify + install options + verification)
  - `designer-handoff/SKILL.md` — 1 path ref (ui-ux-pro-max verify)
  - `README.md` — html-ppt-skill prerequisites line
  - `evals/cases/build-gate-visual-review.json` — behavioral eval + notes

omo config path (`~/.config/opencode/oh-my-openagent.json`) is unchanged — it's not a skill install location, it's omo's runtime config.

## [0.1.1] - 2026-07-11

### Changed

- `build-gate-visual-review` (skill + eval): replaced HTML Anything with [html-ppt-skill](https://github.com/lewislulu/html-ppt-skill). Reason: HTML Anything was a self-hosted web service (`pnpm dev`, `localhost:3000`, POST API) — heavy for the use case. html-ppt-skill is an installed AgentSkill (SKILL.md + themes + layouts + animations) that the agent loads directly and produces a static HTML slide deck. Simpler install, more focused output.
- README prerequisites: HTML Anything → `npx skills add <html-ppt-skill-url>` (installs to `~/.agents/skills/`).

### Required user action

After upgrading to v0.1.1:

```bash
npx skills add https://github.com/lewislulu/html-ppt-skill
```

(html-ppt-skill must be pre-installed in `~/.agents/skills/` before using `build-gate-visual-review`; agent does not auto-install.)

## [0.1.0] - 2026-07-11

Initial fork from [addyosmani/agent-skills](https://github.com/addyosmani/agent-skills), adapted for the oh-my-openagent (omo) + planning-with-files (pwf) stack.

### Added

**Meta & docs**
- `README.md` — fork intro, install paths, v0.1.0 status
- `skill-anatomy.md` — SKILL.md writing conventions (≤500 lines rule, 6-section structure)
- `pwf-integration.md` — phase mapping + file write boundaries
- `LICENSE` (MIT)
- `.gitignore`

**.core/ — 6 required skills**
- `using-meisijiya-skills` — meta dispatcher (force skill check + pwf init before every response)
- `spec-driven-development` — write spec before any non-trivial code
- `incremental-implementation` — vertical-slice decomposition
- `test-driven-development` — red-green-refactor discipline
- `debugging-and-error-recovery` — 5-step triage (reproduce / localize / reduce / fix / guard)
- `source-driven-development` — verify API against official docs

**.extra/ — 11 optional skills**
- `pwf-enforcer` — bridges pwf's Claude Code hooks to omo's OpenCode hook system (Tier 3 honest: advisory only)
- `build-gate-visual-review` — html-ppt-skill orchestration for pre-build visual review (HTML slide deck)
- `designer-handoff` — ui-ux-pro-max-skill orchestration for frontend-agent design contract
- `agent-project-structure` — 10-folder canonical agent-project/ template (planner / memory / tools / knowledge / agent_core / evaluation / observability / deployment / examples / docs)
- `interview-me` — one-question-at-a-time requirement extraction
- `code-simplification` — Chesterton's Fence + behavior-preserving complexity reduction
- `api-and-interface-design` — Hyrum's Law + One-Version Rule + typed errors
- `security-and-hardening` — OWASP Top 10 + three trust boundaries (input / auth / integration)
- `performance-optimization` — Core Web Vitals + measure-first + profiling workflows
- `observability-and-instrumentation` — structured logging + RED metrics + OpenTelemetry + symptom-based alerts
- `documentation-and-adrs` — ADR template + "document the why"

**Eval cases (17)**
- One JSON per skill at `evals/cases/<skill-name>.json`
- Format: 3 positive triggers + 3 negative triggers + 2 behavioral evals
- All parse-validated, all match their SKILL.md (perfect bijection)

**Scripts**
- `scripts/validate-skills.sh` — YAML frontmatter + structure check (required name, name==directory, description ≤1024 chars, recommended 6 sections)
- `scripts/install.sh` — install .core/ (always) + selected .extra/ to `<project>/.opencode/skills/` or `~/.config/opencode/skills/` (global)

**Design documents**
- `docs/p0-outline.md` — archived (was draft → shipped)

### Design decisions

1. **omo + pwf stack targeted** — fills gaps omo doesn't cover, hardens pwf's soft compliance
2. **Double-directory structure** (`.core/` + `.extra/`) — matches `vercel-labs/skills` CLI conventions
3. **pwf Tier 3 documented honestly** — OpenCode cannot hard-block; `pwf-enforcer` is advisory only there
4. **6-section SKILL.md anatomy** — Overview / When to Use (with NOT for) / Process / Common Rationalizations / Red Flags / Verification / pwf Integration
5. **All SKILL.md < 500 lines** — within `skill-anatomy.md` spec
6. **All eval cases warning-level** — per upstream `addyosmani/agent-skills#352` convention

### Omitted (vs. upstream)

These are covered by omo built-ins or pwf itself, so not duplicated:
- `using-agent-skills` (omo Sisyphus + IntentGate substitute)
- `planning-and-task-breakdown` (pwf task_plan.md IS the plan)
- `git-workflow-and-versioning` (omo git-master)
- `frontend-ui-engineering` (omo frontend-ui-ux)
- `browser-testing-with-devtools` (omo playwright)
- `code-review-and-quality` (omo review-work)