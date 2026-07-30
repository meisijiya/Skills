# Process Chains

The Priority table ([`priority-table.md`](priority-table.md)) is *cross-cutting routing* — it tells you which skill handles a single trigger. Most real work follows a multi-skill **chain**. Common chains (in order — don't skip stages):

```
design:           brainstorming → wayfinder → spec-driven-development
                  (wayfinder is the alternative Phase 0 for multi-session scope)

spec phase 1.2:   spec-driven-development §3.5 → /prototype (NEEDS_CONTEXT if <2 valid) → decisions.md [proto]

implementation:   brainstorming? → incremental-implementation → test-driven-development → verification-before-completion

ui front-end:     designer-handoff (project-specific spec) → meisijiya-frontend-taste (anti-slop rules)
                  → [meisijiya-minimalist-ui if aesthetic named] → incremental-implementation
                  → meisijiya-redesign-ui (if existing UI) → verification-before-completion + visual-qa

slice loop:       incremental-implementation (dispatch) → slice-review (per-slice)
                  → slice-progress.sh mark-complete → whole-branch review-work

fix:              debugging-and-error-recovery (5-step protocol) → diagnosing-bugs (when cause non-obvious)
                  → test-driven-development (red-green for the guard test) → verification-before-completion

maintenance:      verification-before-completion → ai-code-blindspots → security-and-hardening → review-work

ci/cd security:   gha-security-review (workflow audit) → verification-before-completion (PR gate)

threat → hard:    security-threat-model (design) → security-and-hardening (impl) → pre-ship-gate (deploy)

ship:             gha-security-review (CI) → pre-ship-gate (deploy evidence) → observability-and-instrumentation (post)

perf gate:        k6-load-testing (synthetic-load PASS/FAIL) → performance-optimization (post-fire diagnosis)

governance:       security-ownership-map (people↔file topology) before major refactor + post-incident

closed loop:      verification-before-completion → pre-ship-gate (deploy evidence) → closed-loop-delivery (24h+ runtime)

dep safety:       supply-chain-risk-auditor (trustworthyness) → security-devsecops (CVE scan at install)

test quality:     test-driven-development → test-guard (post-hoc audit so tests actually test something)

teaching artifact: brainstorming? → teacher-skill (pedagogy data contract) → OMO `frontend` (single-file responsive HTML)
```

The Priority table tells you *which* skill handles a single trigger. The chains tell you which skill comes *next*. Both matter.