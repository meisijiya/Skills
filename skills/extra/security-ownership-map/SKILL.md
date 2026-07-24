---
name: security-ownership-map
description: "Builds a people↔file security-ownership topology from git history to surface orphan sensitive code, hidden owners, and bus-factor hotspots. Default queries: orphan sensitive files (no recent contributor), hidden owners (single-author modules nobody else has touched), bus-factor hotspots (files with only N contributors where N=1), maintainer concentration (top-K authors by sensitive LOC). Output is a single `<repo>-ownership-map.md` per session plus optional CSV/JSON artifacts for further analysis. Use before any refactor that risks orphaning sensitive code, after a security incident to map the blast-radius-of-departure, when hiring and need to identify coverage gaps, or when designing a rotation / on-call scheme that requires understanding who actually knows what."
allowed-tools: "Read Bash Glob Grep"
---

# security-ownership-map

## Overview

Static security audits catch *what* is wrong with the code. They don't tell you *who* would notice if it broke — and crucially, *who would notice if it broke and the original author left*. The bus-factor problem in security terms: a sensitive file with one contributor is a single-point-of-failure. When that contributor leaves, the file becomes "abandoned code" — no active review, no security vigilance, no migration path when frameworks upgrade.

This skill turns git history into a people↔file topology and surfaces the security-relevant patterns:

- **Orphan sensitive files**: high-risk files (auth, crypto, secrets, payment) with no contributor in 12+ months
- **Hidden owners**: a module whose commit history shows only one author; not officially documented as owner
- **Bus-factor hotspots**: critical-path files where N=1 contributor holds 100% of expertise
- **Maintainer concentration**: top-K authors' share of sensitive LOC; if one team owns 80% of sensitive code, the team's departure is a single point of failure

This is **security governance** — not security code review. Pairs with [`security-and-hardening`](~/.agents/skills/security-and-hardening/SKILL.md) (the per-line code audit) and [`security-devsecops`](~/.agents/skills/security-devsecops/SKILL.md) (the supply-chain layer).

Source material adapted from openai's `.curated/security-ownership-map`; the YAML/Neo4j/Gephi outputs were dropped in favor of CSV/JSON + a Markdown summary, which covers the same questions without the dependency.

## When to Use

**Use when:**

- Before a major refactor (e.g. extracting a module, splitting a monolith) that risks orphaning sensitive code
- After a security incident: map "if the author of the vulnerable code left tomorrow, who would catch the next one?"
- During hiring or team-formation: identify sensitive-code coverage gaps
- Designing on-call or rotation schemes that need real coverage understanding (not just org-chart claim)
- Quarterly security governance review: re-run to catch drift
- Compliance audit asking "who has expertise in the auth code?" (SOC2 / ISO27001-style)
- About to deprecate a feature: "does anyone else still own this?"

**NOT for:** (scenario description — let description match decide)

- Per-line code audit of *existing* code → [`security-and-hardening`](~/.agents/skills/security-and-hardening/SKILL.md)
- Code-contract risk review (state / timing / concurrency / boundary) → [`contract-strengthening`](~/.agents/skills/contract-strengthening/SKILL.md)
- Per-PR review of changes → [`verification-before-completion`](~/.agents/skills/verification-before-completion/SKILL.md) + [`slice-review`](~/.agents/skills/slice-review/SKILL.md) if multi-slice
- Threat modeling (who could attack, what could they reach) → [`security-threat-model`](~/.agents/skills/security-threat-model/SKILL.md)
- People / org-chart mapping without git-history grounding → use HR / team data; this skill only uses git

## Process

### 1. Classify the repo into sensitive vs non-sensitive paths

Sensitive paths are where security bugs have outsized blast radius. Pick a heuristic that fits the repo; common categories:

| Category | Examples |
|---|---|
| Authn / authz | `auth/`, `login/`, `session/`, `rbac/`, `permissions/`, `oauth/`, `sso/` |
| Secrets / crypto | `crypto/`, `keys/`, `secrets/`, `vault/`, `kms/` |
| Payment / billing | `billing/`, `payment/`, `invoice/`, `stripe/`, `ledger/` |
| PII / regulated | `gdpr/`, `pii/`, `phi/`, `consent/`, `dsar/` |
| Privileged operations | `admin/`, `iam/`, `sudo/`, `dangerous/`, `unsafe/` |
| External integrations | `integrations/`, `webhooks/`, `third-party/`, `vendors/` |

Define these as glob patterns at the top of the run (so the user can adjust before generation):

```yaml
# <repo>-ownership-map.yaml
sensitive_paths:
  - "auth/**"
  - "**/crypto/**"
  - "billing/**"
  - "secrets/**"
  - "**/admin/**"

low_risk_paths:
  - "**/*.md"
  - "docs/**"
  - "tests/**"
  - "fixtures/**"

default_sensitive_window_months: 12  # "no contributor in N months" = orphan
```

### 2. Walk git history for the people↔file graph

Use `git log` to enumerate authors per file, weighted by recency:

```bash
# Per-file: list all contributors + their last-commit date + commit count
for f in $(find . -type f -name '*.ts' -o -name '*.go' -o -name '*.py' -o -name '*.rs' -o -name '*.java' | grep -v -E '\.(test|spec)\.' ); do
  git log --follow --format='%ae|%aI' -- "$f" | sort -u
done
```

Map email → canonical author (git allows same person with multiple emails; reconcile via `.mailmap` if present, otherwise treat emails as distinct identities and warn).

Compute per file:

- **Contributor count** (unique authors)
- **Top author** (by commit count in window)
- **Last contribution date** (most recent commit)
- **Days since last contribution** (vs today)
- **Sensitive-LOC share** by top author

### 3. Surface the 4 default queries

#### Query A: Orphan sensitive files

Sensitive file with `days_since_last_contribution > sensitive_window_months × 30` AND `contributor_count <= 2`.

These files had contributors in the past but no recent activity. Risk: stale code, no active review, framework upgrades may silently break them, security patches may not get applied.

```markdown
## Query A — Orphan sensitive files

| File | Last touched | Last contributor | Bus factor | Risk |
|---|---|---|---|---|
| src/auth/legacy-saml.ts | 2024-03-15 | alice@oldcorp.com | 1 | HIGH |
```

#### Query B: Hidden owners

Sensitive file where **one author holds ≥ 80% of commits** AND **no author listed in the project's CODEOWNERS or team rosters**. Risk: institutional knowledge concentrated in one person who is not officially accountable.

```markdown
## Query B — Hidden owners (single-author + no CODEOWNERS coverage)

| File | Single-author | Single-author's commit share | CODEOWNERS coverage |
|---|---|---|---|
| src/billing/tax-engine.go | bob | 100% (47/47) | none |
```

#### Query C: Bus-factor hotspots

Critical-path files where `contributor_count == 1` regardless of recency. These are single points of failure for expertise. The bus-factor-1 owner leaving means no one knows the file.

```markdown
## Query C — Bus-factor-1 hotspots (sensitive paths only)

| File | Owner | Last touched | Status |
|---|---|---|---|
| src/crypto/legacy-rsa.ts | carol | 2026-06-01 | active — but solo |
```

#### Query D: Maintainer concentration

Per author, total sensitive-LOC under their ownership (using "most-recent-touch-author" as the proxy). Top-K by share.

```markdown
## Query D — Top maintainers by sensitive-LOC share

| Author | Sensitive files | Sensitive LOC | Share |
|---|---|---|---|
| alice@corp.com | 47 | 12,400 | 38% |
| bob@corp.com | 31 | 9,800 | 30% |
| carol@corp.com | 22 | 7,200 | 22% |
| others | — | 3,200 | 10% |
```

If top-1 > 40% OR top-3 > 85%, flag concentration risk.

### 4. Optional deeper queries

- **Cross-team coupling**: which teams' code touches the same file? `git log --pretty=format:'%ae' -- file` clustered by email-domain.
- **Tenure vs recency**: contributors active > 1 year ago but NOT in last 3 months — the people who may have moved teams.
- **Off-hours velocity**: commits outside 9-17 by author — signal of bus-factor pressure.
- **Sensitive-vs-public exposure gap**: sensitive files without test coverage from non-author contributors — no peer review evidence.

### 5. Output as `<repo>-ownership-map.md`

```markdown
# Security ownership map — <repo>

> Date: <today>
> Window: <sensitive_paths> definition, default window 12 months
> Source: git history (sha <HEAD>)

## Summary
- Total sensitive files: <N>
- Orphan sensitive: <N> (<X>%)
- Hidden owner: <N> files
- Bus-factor-1: <N> files
- Top-1 maintainer share: <X>%

## Query A — Orphan sensitive files
[table]

## Query B — Hidden owners
[table]

## Query C — Bus-factor hotspots
[table]

## Query D — Maintainer concentration
[table]

## Optional: deeper queries (if requested)
[…]

## Recommendations
- Bus-factor-1 files: pair-program a current contributor onto each; document the result in a runbook
- Hidden owners: cross-reference CODEOWNERS or team rosters; either add to CODEOWNERS or assign an official owner
- Orphan files: deprecate (if unused), or assign a current owner with a "first pass" review
- Maintainer concentration: spread sensitive-LOC knowledge through rotation / pair-programming

## Methodology
- All numbers derived from `git log --follow` per file (commands in process §2)
- Sensitive paths defined by `<repo>-ownership-map.yaml` (top of run); adjust per repo
- Email canonicalization via `.mailmap` if present
- Recency window: 12 months (configurable)
```

### 6. Optional CSV / JSON artifacts

For machine-readable downstream analysis, also write:

- `<repo>-ownership-map.csv` with one row per file: path, sensitive_yes, contributor_count, top_author, top_author_share, last_touched, days_since_touch, bus_factor, hidden_owner
- `<repo>-ownership-map.json` with the same data nested: `{repo, sensitive_paths, files: [...], queries: {A, B, C, D}, recommendations: [...]}`

Do NOT include Neo4j / Gephi / Graphviz outputs unless explicitly requested — CSV/JSON is enough for downstream tooling.

## omo Integration

| OMO capability | Used for |
|---|---|
| `oracle` agent | Calibration: "is this contributor count really a bus-factor hotspot, given tenure and the team's documented rotation scheme?" |
| `websearch` MCP | Lookup org-chart or team-rotation data when reasoning about hidden owners |
| OMO `general` agent | Parallel subagents to compute per-team summaries if the repo is large (>5k files) |
| OMO `review-work` skill | Stage-2 review of the ownership map before sharing with leadership |

## Common Rationalizations

| Excuse | Why it's wrong |
|---|---|
| "Our CODEOWNERS covers everything" | CODEOWNERS lists *required reviewers*, not *who knows the code*. Hidden owners often pre-date CODEOWNERS or are missing entries. |
| "Bus-factor is an org problem, not security" | A bus-factor-1 sensitive file is exactly the security risk: if that person is coerced, compromised, or simply leaves without handover, no one reviews the next change. |
| "We have 10 years of git history; this is too big to compute" | The compute is `git log --follow` per file; even 100k commits takes <5 minutes. The output is one Markdown file. |
| "We don't know who's on which team anymore" | Git email domain (`@corp.com` / `@subsidiary.com`) is a reasonable proxy; pair with HR data if you have it. |
| "The output will be political" | That's a feature, not a bug. Bus-factor concentration IS a leadership question. Run the report quarterly; don't make it a one-shot. |
| "Let me run this once a year" | Bus-factor changes fast in fast-moving teams. Quarterly cadence catches drift; monthly is overkill for most teams. |
| "Sensitive paths depend on context; we can't auto-classify" | Heuristics (auth/crypto/billing/admin) cover ~80% of cases; tune the YAML per repo for the rest. Perfect classification isn't the goal — flag concentration risk. |
| "All our sensitive code is owned by senior staff anyway" | That's the concentration risk: if seniors leave or are unavailable, the file becomes orphan. |

## Red Flags

The ownership map is going wrong if:

- §1 sensitive_paths is empty or only contains `*.md` — the user hasn't classified the repo; stop and ask
- §2 walks `git log --follow` for binary files (locks, fixtures, generated code) — exclude these
- §2 reconciles emails by ignoring `.mailmap` — multiple emails for the same person will inflate "contributor count"
- §3 Query A returns 0 results on a 5-year-old repo — the recency window is too short, or the heuristic is wrong
- §3 Query D top-1 share > 60% — concentration risk, must be flagged
- §5 Output has no Recommendations section — the map is a description; the value is the action items
- §5 Methodology is missing — second reviewer can't reproduce
- §6 CSV/JSON missing `sensitive_yes` column — downstream can't filter without it
- Recommendations are vague ("improve documentation") not specific ("assign alice + bob as co-owners of src/crypto/; pair on first change")

## Verification

Before claiming the ownership map is done, produce evidence:

- [ ] §1 sensitive_paths YAML at top of run (or in `<repo>-ownership-map.yaml`); reviewed by user before generation
- [ ] §2 walked git log per file; excluded binary / generated / fixture files
- [ ] §2 reconciled authors via `.mailmap` if present
- [ ] §3 Query A: orphan sensitive files listed with `last_touched` + `days_since`
- [ ] §3 Query B: hidden owners listed; cross-referenced against CODEOWNERS (or absence noted)
- [ ] §3 Query C: bus-factor-1 hotspots listed (sensitive paths only)
- [ ] §3 Query D: top-K maintainers share calculated; concentration risk flagged if thresholds breached
- [ ] §5 Markdown output saved at `<repo>-ownership-map.md`
- [ ] §5 Recommendations are concrete actions (specific file + specific remediation)
- [ ] §5 Methodology section: reproducible commands listed
- [ ] §6 CSV/JSON artifacts with `sensitive_yes` column for downstream filtering

**Acceptance criterion**: A second reviewer can rerun the same commands (listed in Methodology), see the same numbers, and reach the same conclusion about which files are at risk and why.
