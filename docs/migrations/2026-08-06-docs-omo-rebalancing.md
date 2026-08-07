# docs/ vs .omo/ Two-Axis Rebalancing — Migration Guide

> **Date**: 2026-08-06
> **Scope**: 6-step migration (Steps 1-6) shipped; this document is the user-facing runbook
> **Audience**: existing meisijiya-skills users with prior `.omo/` reports to migrate
> **Status**: shipped — all 6 steps complete + Stage 2 dual audit PASS

## 1. Why this migration

Two-axis principle (decided 2026-07-30):

```
write 文档前先问 2 个问题:
  1. 项目产物(被未来引用 / 被 ADR / spec / 后续 commit 引用)? → docs/(git tracked)
  2. 开发中间态(per-session / append-only journal / 抛掷 worktree)? → .omo/(gitignored)
```

Each Step 1-5a skill updated its `SKILL.md` to write to `docs/<noun>/...`. Step 6 establishes the directories and provides this runbook.

## 2. Pre-flight checklist

Before running any migration:

- [ ] **Close OpenCode session** — plugins only load at process start
- [ ] **Restart OpenCode** — load-bearing: new `omo-state-index.js@v1.1.0` plugin adds `throwaway_protos` array; existing `.omo/.index.json` files with `schema_version: "1.0.0"` will be flagged `fromCorrupt=true` and rebuilt on next `.omo/**` write (self-healing)
- [ ] **No in-flight `/start-work`** — check `.omo/plans/` for active phase-3 slices
- [ ] **git status clean** — `git status` shows no unrelated uncommitted changes
- [ ] **Backup existing `.omo/` state** — `cp -R .omo/ .omo.backup-$(date +%Y%m%d)` before any migration

## 3. Migration scripts (5 categories)

### 3.1 Category 1: verify-chain → `docs/verification/`

```bash
# old: .omo/verification/<article-slug>/article-verified.md
# new: docs/verification/<article-slug>/{article-verified.md, verification-report.md}

if [ -d .omo/verification ]; then
  mkdir -p docs/verification
  rsync -av .omo/verification/ docs/verification/
fi
```

### 3.2 Category 2: 3 security reports → `docs/{ownership-map, threat-model, supply-chain-risk}/`

```bash
# old: .omo/<noun>/<repo-hash>-<date>/...
# new: docs/<noun>/<repo-hash>-<date>/...

for dir in ownership-map threat-model supply-chain-risk; do
  if [ -d ".omo/$dir" ]; then
    mkdir -p "docs/$dir"
    rsync -av ".omo/$dir/" "docs/$dir/"
  fi
done
```

### 3.3 Category 3: research → `docs/research/`

```bash
# old: .omo/research/<plan-slug>/<topic>.md
# new: docs/research/<plan-slug>/<topic>.md

if [ -d .omo/research ]; then
  mkdir -p docs/research
  rsync -av .omo/research/ docs/research/
fi
```

### 3.4 Category 4: 3 docs/ migrations → `docs/{architecture-review, incidents, design-spec}/`

```bash
for dir in architecture-review incidents design-spec; do
  if [ -d ".omo/$dir" ]; then
    mkdir -p "docs/$dir"
    rsync -av ".omo/$dir/" "docs/$dir/"
  fi
done
```

### 3.5 Category 5: ai-blindspots + 5b/5c impacts

```bash
# ai-blindspots reports: process-grade, ephemeral
# old: caller-workspace-root/ai-blindspots-report.md (legacy)
# new: .omo/blindspots-reports/<diff-hash>/ai-blindspots-report.md
# No migration needed — process-grade, gitignored (.gitignore:.omo/ covers)
#
# 5b throwaway split: no migration; new code creates .omo/throwaway-worktree/ + .omo/throwaway-proto/
# 5c SCHEMA_VERSION bump: user must restart OpenCode (load-bearing)
echo "Category 5: no script migration; restart OpenCode to load new plugin"
```

## 4. Collision handling

Three options inherited from Step 1/2 semantics:

1. **Overwrite** (default) — `rsync -av` copies new docs/ on top; old `.omo/` preserved.
2. **Rename** — `mv .omo/<noun> .omo/<noun>.archive-<date>` first; then copy.
3. **Skip** — no migration; old reports remain in `.omo/` for archival reference.

The `<repo-hash>` semantic (8-char git short SHA at report generation) and `<plan-slug>` regex `^[a-z0-9][a-z0-9-]{0,39}$` make collisions rare. For true collisions (same repo-hash on same date), append `-HHMMSS` suffix.

## 5. Post-migration validation

```bash
# 6 Iron Law gates
bash scripts/validate-skills.sh         # 44/44 OK
bash scripts/check-doc-drift.sh         # in sync
bash scripts/check-marketplace.sh       # 44 skills
bash scripts/test-text-contracts.sh     # 15/15 PASS
node --test scripts/test-omo-state-index.js  # 4/4 cases
bash scripts/test-citation-discipline.sh    # 7/7 passed

# Plugin version check
node -e "console.log('SCHEMA_VERSION=' + require('.opencode/plugins/omo-state-index.js').SCHEMA_VERSION)"
# Expected: SCHEMA_VERSION=1.1.0
```

## 6. Rollback

If migration went wrong:

```bash
# Restore .omo/ from backup
rm -rf .omo
mv .omo.backup-$(date +%Y%m%d) .omo

# Selectively remove new docs/<noun>/ directories
rm -rf docs/<noun>

# Revert plugin to old version (rebuilds 1.0.0 schema)
git checkout HEAD~1 -- .opencode/plugins/omo-state-index.js
# Then restart OpenCode
```

## 7. Add new skill — follow the same pattern

When adding a new skill that produces reports:

1. Decide: project product (git tracked, ADR-cited) → `docs/<noun>/`; or per-session (gitignored) → `.omo/<noun>/`.
2. Update `SKILL.md` Process / `## omo Integration` to specify the output path.
3. Create `docs/<noun>/README.md` (or `.omo/<noun>/README.md` if applicable) with: heading, 1-2 sentence description, output path convention, link to skill.
4. If `docs/<noun>/` is new, add it to this migration guide's category list.
5. Validate via `scripts/check-doc-drift.sh` and the 6 Iron Law gates.

---

## See also

- Step 5b: `skills/extra/prototype/SKILL.md` 6 throwaway refs + plugin dual arrays (`docs/`)
- Step 5c: `SCHEMA_VERSION` `1.0.0` → `1.1.0` + `docs/state-file-governance.md` (this repo)
- PWF → OMO migration: `docs/migrations/pwf-to-omo-native.md` (earlier 6-step rebalancing)
- Two-axis decision D-001: available in the original handoff `.omo/handoff/ad-hoc-2026-08-06.md`
