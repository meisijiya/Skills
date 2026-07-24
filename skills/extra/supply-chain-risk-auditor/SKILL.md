---
name: supply-chain-risk-auditor
description: "Audits the trustworthyness of dependencies — not the CVE database but the project's maintenance posture. Evaluates single-maintainer risk, abandoned-repo risk, low-popularity risk, maintainer-identity hygiene, and social-engineering resistance. Use when adding a dependency with a non-trivial maintenance footprint, when a dependency's maintenance signal has degraded (release cadence slipped, contributors dwindled, ownership changed), during dependency policy review, or before committing to a lockfile across releases. Distinct from security-devsecops: devsecops scans for known CVEs at install time; this skill audits the supply side that CVE scanning cannot reach."
allowed-tools: "Read Bash Glob WebFetch Grep"
---

# supply-chain-risk-auditor

## Overview

`security-devsecops` Step 1 (`npm audit`) catches **known CVEs** in your dependencies. It does not catch **whether the dependency itself is trustworthy**: a clean dependency that's maintained by one person who hasn't logged in for 8 months is a higher risk than a noisy dependency with a healthy maintainer pool. CVE scanners run on the package metadata; supply-chain risk audits the supply side — who maintains it, how, and whether continuing to depend on it is reasonable.

This skill evaluates the **trustworthyness** of dependencies against 5 axes:

1. **Single-maintainer risk**: is the package a bus-factor-1 project? (See also [`security-ownership-map`](~/.agents/skills/security-ownership-map/SKILL.md) — same methodology, applied to your dependencies.)
2. **Abandoned-repo risk**: last commit, last release, stale issue backlog, unmerged PRs.
3. **Low-popularity risk**: stars / downloads / dependents. Low numbers ≠ bad (some niche deps are gems), but worth questioning in security-sensitive paths.
4. **Maintainer-identity hygiene**: how is the maintainer account secured? Has it joined the project recently? Has it transferred ownership? Two-factor / GPG signing history?
5. **Social-engineering resistance**: how easy would it be to take over the package? (Maintainer accountability trail, code review on PRs, security policy, / SECURITY.md, PGP-signed releases.)

Distinct from: [`security-devsecops`](~/.agents/skills/security-devsecops/SKILL.md) (CVE scan, SBOM, IaC, pre-deploy) and [`security-incident-response`](~/.agents/skills/security-incident-response/SKILL.md) (post-breach). This skill is **before** the dep enters your lockfile or **at policy-review time** to decide whether to keep it.

## When to Use

**Use when:**

- Adding a new dependency (especially in security-sensitive paths: auth / crypto / secrets / network / DB drivers)
- Reviewing the lockfile quarterly — has any dependency's maintenance posture degraded since last review?
- About to upgrade across a major version (new maintainer, repo moved, ownership change)
- Sourcing-alternatives investigation (e.g. "should we replace `pkg-x` with `pkg-y`?")
- Compliance policy: SOC2 / ISO27001 review requires evidence of dependency risk assessment
- After a dependency incident in your ecosystem (e.g. a popular package was hijacked) — re-audit similar packages

**NOT for:** (scenario description — let description match decide)

- Per-install CVE scan (when adding a dep, run `npm audit` / `pip-audit` first) → [`security-devsecops`](~/.agents/skills/security-devsecops/SKILL.md)
- Code audit of code YOU wrote that depends on a library → [`security-and-hardening`](~/.agents/skills/security-and-hardening/SKILL.md)
- Production runtime incident (post-breach response) → [`security-incident-response`](~/.agents/skills/security-incident-response/SKILL.md)
- Audit of who knows what in your own codebase → [`security-ownership-map`](~/.agents/skills/security-ownership-map/SKILL.md)

## Process

### 1. Inventory the dependency surface

Two scopes:

- **Single dep**: target one package; tighter scope, deeper analysis
- **Lockfile-wide**: scan every direct + transitive dep; aggregate by risk score

For each dep, capture the metadata block:

```yaml
# dependency-risk-input.yaml
target:
  ecosystem: npm | pip | crates | go-modules | maven | rubygems
  package: <name>
  version_pinned: <current version in your lockfile>
  version_latest: <latest released>
  depth: 0=direct, 1=transitive-of-direct, 2+=deep
  used_in: <which of your code paths / services use it>
  security_critical: yes | no  # does it handle secrets? authn? network?
```

For lockfile-wide: emit one block per direct dep + ALL transitive deps (depth ≥ 1 optional; depth 0 mandatory).

### 2. For each dep, score the 5 axes

#### Axis 1 — Single-maintainer risk

- Count unique authors in last 90 days: `git log --since='90 days ago' --pretty=format:'%ae' | sort -u`
- Count unique authors in entire history: `git log --pretty=format:'%ae' | sort -u | wc -l`
- Risk: 1 author in last 90 days = HIGH; 0 = CRITICAL (drop or fork).
- Compare to historical: if a package historically had 5+ contributors and now has 1, that's a major maintainer consolidation (often pre-acquisition).

#### Axis 2 — Abandoned-repo risk

- Last commit date: `git log -1 --pretty=format:'%ai'` or GitHub API
- Last release date: GitHub API `published_at`
- Open issue count, open PR count, median-PR-age
- Risk: no release in 18+ months = HIGH; no commit in 24+ months = CRITICAL.
- Note: "no release" is less severe than "no commit" — releases are infrequent; commits indicate ongoing maintenance.

#### Axis 3 — Low-popularity risk

- Stars on GitHub (proxy for adoption breadth)
- Downloads / week (more reliable than stars for actual usage)
- Dependents count (GitHub "Used by" or npmjs dependents)
- Risk scoring is nuanced:
  - High stars (10k+) + low downloads (100/week) = suspicious (star-buying); flag for investigation
  - Low stars (<500) + high downloads (1M+/week) = healthy niche; low risk
  - Low stars (<100) + low downloads (<1k/week) = bus-factor + abandoned likely; high risk unless it's well-known elsewhere (e.g. stdlib, framework-bundled)

#### Axis 4 — Maintainer-identity hygiene

- Maintainer account creation date: GitHub API `created_at` (yesterday = suspicious for a maintainer)
- 2FA enabled: GitHub API `two_factor_authentication` (private; check via maintainer's public `requires_two_factor` flag on the repo / org)
- Past account rename: rare but a red flag
- PGP / Sigstore signed releases: signed tags + signatures in `git tag --verify`
- npm provenance attestations: npm publishes signed provenance
- Has the maintainer handle ever been transferred (e.g. ownership changed from person A to person B / org)?
- Risk: account created < 90 days ago for a dep with > 1000 users = HIGH; unsigned releases for a security-critical dep = MEDIUM.

#### Axis 5 — Social-engineering resistance

Read the package's repo for the following signals:

- **SECURITY.md**: exists in repo? Has a private disclosure channel?
- **Security policy mentions dependencies**: does it say who maintains and how?
- **Maintainer accountability trail**: are maintainers named on the project page, or anonymous?
- **PR review discipline**: are PRs reviewed before merge? Are there automated tests?
- **Issue triage**: are security-relevant issues addressed quickly?
- **Disclosure history**: has the maintainer handled a CVE before? Look for advisories under their name.
- **Commits signed**: `git log --pretty=format:'%H %GS' | grep -E '^[a-f0-9]+ (G|g)'` — signed commits indicate identity discipline.

Risk: no SECURITY.md = MEDIUM (acceptable for low-criticality deps, increasing risk for critical); maintainer anonymity + bus-factor-1 + no disclosure history = HIGH (consider replacing).

### 3. Aggregate to a risk score

Per dep:

```
risk_score = (
  axis1_score * 2 +   # single-maintainer: highest weight
  axis2_score * 1 +   # abandoned-repo
  axis3_score * 1 +   # popularity
  axis4_score * 2 +   # identity: same high weight as bus-factor
  axis5_score * 1     # social engineering
) / 7   # max possible = 14, divide by 14 to get 0-1
```

Each axis_score is 1-4 (LOW=1, MEDIUM=2, HIGH=3, CRITICAL=4).

Risk band:

- Score < 0.4 (and no axis ≥ 3): LOW — accept
- Score 0.4-0.6 OR any single axis = HIGH: REVIEW — note in dashboard, plan to mitigate
- Score > 0.6 OR any axis = CRITICAL: REJECT — find alternative or fork

For depth=0 (direct deps), the threshold is sharper:

- Any axis = CRITICAL: REJECT (especially for security-critical paths)
- Otherwise escalate the band one level

### 4. Output as `<repo>-supply-chain-risk.md`

```markdown
# Supply-chain risk assessment — <repo>

> Date: <today>
> Scanned: <N dependencies> (depth 0: <M>, depth 1: <K>, depth 2+: ...>)

## Direct dependencies (depth 0)
| Dep | Version | Used in | Axis 1-2-3-4-5 | Score | Band | Action |
|---|---|---|---|---|---|---|
| foo-auth | 1.2.3 | auth/login, auth/session | 2-2-1-3-2 | 0.50 | REVIEW | rotate signature |
| bar-crypto | 0.9.1 | secrets/kms | 4-3-2-3-3 | 0.86 | REJECT | replace with bar-crypto-fork |
| baz-fmt | 3.4.0 | util/format | 1-1-1-1-1 | 0.14 | accept | — |

## Transitive dependencies (depth 1): summary only
## Transitive dependencies (depth 2+): aggregate by ecosystem + report top-10 worst

## Recommendations
- REJECT list: <deps to remove>
- REVIEW list: <deps to mitigate, with timeline>
- Replacement / fork candidates: <deps and their replacements>

## Methodology
- All signals via public GitHub API / package-registry APIs (curl + jq)
- Per-dep git log walked (depth 0 only; transitive summary via registry API)
- Scoring matrix documented in <this-skill>/reference/scoring.md
```

### 5. Optional CSV / JSON artifacts

Same as security-ownership-map: emit `<repo>-supply-chain-risk.csv` / `.json` for downstream tooling (Renovate config gating, policy enforcement).

## omo Integration

| OMO capability | Used for |
|---|---|
| `oracle` agent | "Is this single-maintainer risk justified for the workload?" (e.g. stdlib modules often are; a 3rd-party auth library being bus-factor-1 is not) |
| `websearch` MCP | Lookup recent package-takeover incidents in the same ecosystem (npm hijacking class, PyPI typosquatting class) — measure whether the threat you face is current |
| OMO `general` agent | Parallel subagents to scan transitive deps at depth 1+ on big lockfiles |
| OMO `security-research` mode | For HIGH/CRITICAL findings, run `security-research` to verify exploitability OR fork viability |

## Common Rationalizations

| Excuse | Why it's wrong |
|---|---|
| "It's popular, must be safe" | Popular ≠ trustworthy — see the typosquat / takeover class. Popularity can be the attack target. |
| "CVE scan is clean, ship it" | CVE scan is necessary-but-not-sufficient; it doesn't catch unmaintained, bus-factor, identity-weak deps. |
| "We use it everywhere, can't switch" | "Can't switch" is a sunk-cost rationalization. Migration cost > incident cost if the dep is risky. Quantify both. |
| "It's pinned; npm install --frozen-lockfile prevents surprises" | Pinning prevents version drift; it doesn't prevent a pinned dep itself from being compromised. CVE + pin ≠ supply-chain safety. |
| "We're a small app, doesn't matter" | If you hold user data / process payments / run auth, the supply chain does matter — proportionally to the data sensitivity. |
| "Hard to verify; just trust npm's reputation system" | npm's reputation system is invisible to you; per-dep signals are how you verify. |
| "Sigstore / signed commits don't matter" | For security-critical deps, signed releases are a baseline; unsigned is HIGH risk because you can't verify the binary you consume matches the source. |
| "We'll re-audit when there's a CVE" | CVEs are lagging indicators; abandoned dep + social-engineering takeover ARE the threat vector. Audit before, not after. |

## Red Flags

Supply-chain risk audit is going wrong if:

- §1 skipped the version comparison (dep's pinned vs latest — if pinned-to-old-version, the question of "latest healthy?" is replaced by "ancient-support-only?" which is a different risk)
- §2 walked git log but didn't filter `git log --since='N months'` — without the time window you can't tell "still maintained" from "active historically, abandoned now"
- §3 uses stars as the sole adoption signal — stars are easily gamed; downloads / dependents are stronger signals
- §4 didn't check 2FA / signing — the maintainer-identity axis is the most often skipped; it's also where social-engineering attacks land
- §5 didn't read SECURITY.md / disclosure history — past behavior is the strongest predictor of future behavior
- Scoring matrix aggregates without considering depth — direct security-critical dep at axis 3 risk is much worse than transitive dep
- Output uses `risk_score` without per-axis breakdown — aggregates lose the diagnostic detail (which axis to fix?)
- Recommendations are vague ("replace risky deps") not specific ("replace `bar-crypto 0.9.1` with `bar-crypto-fork v1.0.2` — see SECURITY.md for fork maintainer's PGP signature")
- §5 mentions checking `npm audit` as input — that's [`security-devsecops`](~/.agents/skills/security-devsecops/SKILL.md)'s job, not this skill's; overlap blurs the score

## Verification

Before claiming the risk assessment is done, produce evidence:

- [ ] §1 Inventory complete; for lockfile-wide scan, transitive depth included with explicit policy
- [ ] §2 Per-dep 5-axis scoring with concrete evidence (commit dates, star counts, 2FA flags, signed-tag presence)
- [ ] §3 Aggregate risk score + band per dep + top-10 transitive aggregate
- [ ] §4 Markdown output saved at `<repo>-supply-chain-risk.md`
- [ ] §4 Recommendations include specific REJECT / REVIEW / replace-with lists
- [ ] §5 Methodology reproducible (commands in Methodology section)
- [ ] Optional CSV / JSON artifacts emitted
- [ ] Output reviewed by a second pair of eyes (a maintainer or stakeholder) — supply-chain risk is a security boundary decision and warrants human review before acting

**Acceptance criterion**: A second reviewer can re-run the same commands on each direct dep, see the same scores, and reach the same conclusion about which deps are at risk and why.
