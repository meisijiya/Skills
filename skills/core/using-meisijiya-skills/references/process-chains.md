# Process Chains

The Priority table ([`priority-table.md`](priority-table.md)) is *cross-cutting routing* — it tells you which skill handles a single trigger. Most real work follows a multi-skill **chain**. Common chains (in order — don't skip stages):

```
design:           brainstorming OR wayfinder → research? → spec-driven-development → contract-strengthening?
                  (brainstorming 和 wayfinder 是同一 Phase 0 slot 的替代分支;research 在 wayfinder 给出 plan stub 后跑;contract-strengthening 在 spec attestation 后、impl 前的 Phase 1.25)

spec phase 1.2:   spec-driven-development §3.5 → /prototype (NEEDS_CONTEXT if <2 valid) → decisions.md [proto]

implementation:   api-and-interface-design? → brainstorming? → incremental-implementation → test-driven-development → verification-before-completion

ui front-end:     build-gate-visual-review? → designer-handoff (project-specific spec) → meisijiya-frontend-taste (anti-slop rules)
                  → [meisijiya-minimalist-ui if aesthetic named] → incremental-implementation
                  → meisijiya-redesign-ui (if existing UI) → verification-before-completion + visual-qa
                  (build-gate-visual-review? runs first when user explicitly wants design alignment
                   gate or HTML page output before handoff; not required for every UI task)

slice loop:       incremental-implementation (dispatch) → slice-review (per-slice)
                  → slice-progress.sh mark-complete → whole-branch review-work

fix:              debugging-and-error-recovery (5-step protocol) → diagnosing-bugs (when cause non-obvious)
                  → test-driven-development (red-green for the guard test) → verification-before-completion

maintenance:      improve-codebase-architecture? (scan) → verification-before-completion → ai-code-blindspots → security-and-hardening → review-work
                  (documentation-and-adrs? only if irreversible decision — 不默认走)

ci/cd security:   gha-security-review (workflow audit) → verification-before-completion (PR gate)

threat → hard:    security-threat-model (design) → security-and-hardening (impl) → pre-ship-gate (deploy)

ship:             gha-security-review (CI) → pre-ship-gate (deploy evidence) → observability-and-instrumentation (post telemetry) → verification-before-completion
                  (documentation-and-adrs? only if irreversible decision)

perf gate:        k6-load-testing (synthetic-load PASS/FAIL) → performance-optimization (post-fire diagnosis)

governance:       security-ownership-map (people↔file topology) before major refactor + post-incident

incident:         production-incident-playbook OR security-incident-response → observability-and-instrumentation? (data) → verification-before-completion (postmortem sign-off)
                  (production-incident-playbook 适用于非安全事故 in-flight runbook + blameless postmortem;
                   security-incident-response 适用于安全事故 NIST CSF detect/triage/contain/eradicate/recover/postmortem;
                   两者同一 Phase 0 slot 二选一 — 走错分支走错 skill)

closed loop:      verification-before-completion → pre-ship-gate (deploy evidence) → closed-loop-delivery (24h+ runtime)

dep safety:       supply-chain-risk-auditor (trustworthyness) → security-devsecops (CVE scan at install)

test quality:     test-driven-development → test-guard (post-hoc audit so tests actually test something)

teaching artifact: brainstorming? → teacher-skill (pedagogy data contract) → OMO `frontend` (single-file responsive HTML)
```

## Cross-cutting / context-dependent skills

The chain model above covers sequential multi-skill work. The skills below are deliberately **outside any single chain** — they fire on triggers, agent judgement, or dispatch-prompt loading rather than a fixed pipeline:

- [`loop-me`](~/.agents/skills/loop-me/SKILL.md) — `disable-model-invocation: true`; only fires on explicit `/loop-me` to avoid competing with `brainstorming`'s description match.
- [`writing-skills`](~/.agents/skills/writing-skills/SKILL.md) — TDD-for-docs meta; invoked when the user mentions creating or editing a skill. Not part of any standard work chain.
- [`source-driven-development`](~/.agents/skills/source-driven-development/SKILL.md) — fires on unfamiliar APIs, version-sensitive upgrades, or anomalous behavior. Agent self-checks against `context7` / `grep_app`; not anchored in any single chain.
- [`stack-security-coder`](~/.agents/skills/stack-security-coder/SKILL.md) — frontend / backend / mobile stack-specific checklist. Loaded via `task(load_skills=[...])` rather than appearing in an in-line chain.

The Priority table tells you *which* skill handles a single trigger. The chains tell you which skill comes *next*. The cross-cutting list tells you which skills are **deliberately outside the chain model** and why. All three matter.
