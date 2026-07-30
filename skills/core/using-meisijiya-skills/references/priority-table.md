# Skill Priority Table

Cross-cutting routing hints — not rules. The `description` field of each
skill is the source of truth; this table is an accelerator for the most
common trigger patterns. When multiple skills could apply, **process
skills come first** (the discipline layer; the rest are tools).

Under omo, Sisyphus's Intent Gate classifies intent (research /
implementation / investigation / fix / evaluation) before any skill
routing happens. This table covers the `implementation` branch where
skill routing still matters; other branches are handled by omo's built-in
dispatch (librarian / explore / oracle for `research`;
`debugging-and-error-recovery` for `fix`).

| Trigger (user request pattern) | Consider first | Possible next |
|---|---|---|
| `ulw` / `ultrawork` / "just build it" / "do it" | (no skill — Sisyphus ultrawork mode handles) | [`brainstorming`](~/.agents/skills/brainstorming/SKILL.md) only if mid-flight scope emerges |
| "Let's build X" / "implement Y" / new feature (scope known) | [`incremental-implementation`](~/.agents/skills/incremental-implementation/SKILL.md) | [`brainstorming`](~/.agents/skills/brainstorming/SKILL.md) only if Sisyphus detects hidden ambiguity |
| "I want to do X but I'm not sure how" / "design X" / "what's the right way" | [`brainstorming`](~/.agents/skills/brainstorming/SKILL.md) | [`spec-driven-development`](~/.agents/skills/spec-driven-development/SKILL.md) → [`incremental-implementation`](~/.agents/skills/incremental-implementation/SKILL.md) |
| "Fix this bug" / "X is broken" / "X is wrong" | [`debugging-and-error-recovery`](~/.agents/skills/debugging-and-error-recovery/SKILL.md) | If the cause is non-obvious after 1-2 hypotheses, switch to [`diagnosing-bugs`](~/.agents/skills/diagnosing-bugs/SKILL.md); final fix then returns to [`verification-before-completion`](~/.agents/skills/verification-before-completion/SKILL.md) |
| "Review this slice" / "diff against brief" / per-slice review before next slice | If installed, [`slice-review`](~/.agents/skills/slice-review/SKILL.md) (extra/) | [`verification-before-completion`](~/.agents/skills/verification-before-completion/SKILL.md) |
| "About to claim done" / "ready to commit/PR" | [`verification-before-completion`](~/.agents/skills/verification-before-completion/SKILL.md) | (invoke OMO `review-work` per Stage 2) |
| "Modify GHA workflow" / "audit .github/workflows" / "review a PR with CI changes" / "design CI step order" | If installed, [`gha-security-review`](~/.agents/skills/gha-security-review/SKILL.md) (extra/) | [`security-devsecops`](~/.agents/skills/security-devsecops/SKILL.md) if the workflow change touches supply chain |
| "About to design / refactor / integrate X" with a trust-boundary crossing | If installed, [`security-threat-model`](~/.agents/skills/security-threat-model/SKILL.md) (extra/) | [`security-and-hardening`](~/.agents/skills/security-and-hardening/SKILL.md) once the design lands |
| "About to roll out a release" / "canary stuck at 0%" / "deploy exit 0 but suspect silent failure" | If installed, [`pre-ship-gate`](~/.agents/skills/pre-ship-gate/SKILL.md) (extra/) | [`security-incident-response`](~/.agents/skills/security-incident-response/SKILL.md) only if the failure already reached users |
| "Need perf gate before merging" / "is X endpoint fast enough at 1k RPS" | If installed, [`k6-load-testing`](~/.agents/skills/k6-load-testing/SKILL.md) (extra/) | [`performance-optimization`](~/.agents/skills/performance-optimization/SKILL.md) once the gate fires |
| "Production alert fired" / "need the in-flight runbook" / "writing postmortem" | If installed, [`production-incident-playbook`](~/.agents/skills/production-incident-playbook/SKILL.md) (extra/) | [`security-incident-response`](~/.agents/skills/security-incident-response/SKILL.md) only if the incident is security-class |
| "About to declare this done" / "diff is large, must be done" / "bug came back despite green CI" | If installed, [`closed-loop-delivery`](~/.agents/skills/closed-loop-delivery/SKILL.md) (extra/) | [`pre-ship-gate`](~/.agents/skills/pre-ship-gate/SKILL.md) + [`observability-and-instrumentation`](~/.agents/skills/observability-and-instrumentation/SKILL.md) |
| "Adding a new dep" / "lockfile quarterly review" | If installed, [`supply-chain-risk-auditor`](~/.agents/skills/supply-chain-risk-auditor/SKILL.md) (extra/) | [`security-devsecops`](~/.agents/skills/security-devsecops/SKILL.md) for CVE scan at install time |
| "AI wrote our React/Express/Mobile code" / "XSS-prone frontend code" / "WebView hard to reason about" | If installed, [`stack-security-coder`](~/.agents/skills/stack-security-coder/SKILL.md) (extra/) | [`security-and-hardening`](~/.agents/skills/security-and-hardening/SKILL.md) for the cross-cutting audit + [`ai-code-blindspots`](~/.agents/skills/ai-code-blindspots/SKILL.md) for AI-coded diff blindspots |
| "Tests are 100% green but prod bug slipped" | If installed, [`test-guard`](~/.agents/skills/test-guard/SKILL.md) (extra/) | [`test-driven-development`](~/.agents/skills/test-driven-development/SKILL.md) for the methodology |
| AI just generated/edited code, in `verification-before-completion` stage | [`verification-before-completion`](~/.agents/skills/verification-before-completion/SKILL.md) | [`ai-code-blindspots`](~/.agents/skills/ai-code-blindspots/SKILL.md) (extra/) |
| "Write code that touches K+/v X / unfamiliar API" | [`source-driven-development`](~/.agents/skills/source-driven-development/SKILL.md) | [`test-driven-development`](~/.agents/skills/test-driven-development/SKILL.md) |
| "Write a skill" / "edit a skill" / "extract this workflow" | [`writing-skills`](~/.agents/skills/writing-skills/SKILL.md) | (test-first, red-green-refactor) |
| Codebase health scan / on-boarding unfamiliar codebase / weekly architecture review | [`improve-codebase-architecture`](~/.agents/skills/improve-codebase-architecture/SKILL.md) | (proposal-only output; defer to `incremental-implementation` for action) |
| Post-attested-Spec work with observed open-world contract/state/timing/concurrency/boundary signals | If installed, [`contract-strengthening`](~/.agents/skills/contract-strengthening/SKILL.md) | Missing optional extra never blocks the core flow |
| `@teacher` / "教我" / "teaching-style HTML" | If installed, [`teacher-skill`](~/.agents/skills/teacher-skill/SKILL.md) (extra/) | Emits pedagogy data contract → OMO `frontend` |
| Underspecified request / "interview me" / "grill me" | [`brainstorming`](~/.agents/skills/brainstorming/SKILL.md) | (one question at a time, see Process § 2) |
| "Build a landing / portfolio / marketing page" / "redesign our existing site to premium quality" | If installed, [`meisijiya-frontend-taste`](~/.agents/skills/meisijiya-frontend-taste/SKILL.md) (extra/) — anti-slop rules + three dials | [`designer-handoff`](~/.agents/skills/designer-handoff/SKILL.md) for the project-specific spec contract. If the brief names a specific aesthetic, stack [`meisijiya-minimalist-ui`](~/.agents/skills/meisijiya-minimalist-ui/SKILL.md). If upgrading existing UI, load [`meisijiya-redesign-ui`](~/.agents/skills/meisijiya-redesign-ui/SKILL.md) first. |
| Use when a Phase 1.2 spec contains `[PROTO-RESOLVE]` markers | If installed, [`prototype`](~/.agents/skills/prototype/SKILL.md) (extra/) | Return to [`spec-driven-development`](~/.agents/skills/spec-driven-development/SKILL.md) §3.5 |
| Use when scope exceeds a single brainstorming session | If installed, [`wayfinder`](~/.agents/skills/wayfinder/SKILL.md) (extra/) — DAG ticket graph | Close → Phase 0 of `.omo/plans/<slug>.md` |
| Use when a planning/design decision requires authoritative information from official docs / RFCs | If installed, [`research`](~/.agents/skills/research/SKILL.md) (extra/) — plan-required, 4-type citation whitelist | Uses the OMO `librarian` under the hood |

**Project-level AGENTS.md and direct user instructions override this table** — only skip Skills when the human partner has explicitly told you to.

## Reading order

1. Check the trigger column against the current request.
2. If the "Consider first" cell is empty, this is omo's territory (no skill needed).
3. If you have an "If installed" cell, the skill is in `extra/` — only loaded if the user opted in via `npx skills add`.
4. Read [`references/process-chains.md`](process-chains.md) when work spans multiple stages — the table tells you *which* skill handles a single trigger; chains tell you what comes *next*.