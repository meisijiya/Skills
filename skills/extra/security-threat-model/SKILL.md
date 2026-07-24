---
name: security-threat-model
description: "Performs an AppSec-grade threat model before any non-trivial feature, integration, or design change. Identifies trust boundaries, attacker capability, abuse paths (STRIDE), and prioritized mitigations — all anchored to file:line in the actual codebase. Use when designing a new feature that crosses a trust boundary, integrating a third-party service, refactoring auth/secret handling, expanding blast radius (more tenants / more scope / more trust), or when security-and-hardening finds a control already inadequate. Output is a single `<repo>-threat-model.md` per session."
allowed-tools: "Read Grep Glob Bash WebFetch"
---

# security-threat-model

## Overview

`security-and-hardening` audits *existing* code line-by-line against OWASP rules — it answers "does this code follow the security playbook?". This skill operates **one level up**: it answers "**should this code exist, and where is the boundary it crosses?**". Threat modeling is the practice of naming the attacker, the assets, the trust boundaries, and the abuse paths *before* the code is written (and re-asserting them after significant changes).

This is the threat-side counterpart to:

| Phase | Skill | Question |
|---|---|---|
| Pre-design (this skill) | `security-threat-model` | What can go wrong? Where? Who? |
| Implementation | `security-and-hardening` | Does the code follow the controls? |
| Pre-deploy | `security-devsecops` / `gha-security-review` | Did we lock the supply chain / pipeline? |
| Post-deploy | `pre-ship-gate` | Is the deploy actually running safely? |
| Post-incident | `security-incident-response` | Contain / recover / postmortem |

Threat model output is a single Markdown file per session — `<repo>-threat-model.md` — with concrete file:line citations. **The model is only useful if the evidence can be checked in one read** — vague narratives get thrown away.

## When to Use

**Use when:**

- Designing a new feature that introduces or crosses a trust boundary (new external integration, new auth scope, new privileged action, new audit sink)
- Integrating a third-party service that handles user data, secrets, or privileged actions (auth provider, payments, file storage, AI provider)
- Refactoring authn / authz / session / secret-handling code (even if "small")
- Expanding blast radius — multi-tenant, broader scope, increased trust assignment, breaking out of a sandbox
- After a security review (pen-test, internal audit, security-and-hardening finding that a control was inadequate) to model the *system*, not just the finding
- Before any commitment of significant engineering effort on a path that crosses trust — much cheaper to correct the model than the code

**NOT for:** (scenario description — let description match decide)

- Per-line code review of *existing* code → [`security-and-hardening`](~/.agents/skills/security-and-hardening/SKILL.md)
- Supply chain / dep / IaC audit → [`security-devsecops`](~/.agents/skills/security-devsecops/SKILL.md)
- GHA workflow file audit → [`gha-security-review`](~/.agents/skills/gha-security-review/SKILL.md)
- Production monitoring / log analysis → [`observability-and-instrumentation`](~/.agents/skills/observability-and-instrumentation/SKILL.md)
- Post-incident (the threat materialised) → [`security-incident-response`](~/.agents/skills/security-incident-response/SKILL.md) — a postmortem retro-fits a model; this skill builds the model *first*

## Process

### 1. Scope extraction (anchor in the brief / spec / PRD)

- Read the feature brief / spec / proposal / PRD
- Identify the **sensitivity level**: does it handle user data, secrets, money, medical, regulated content? Mark `high | medium | low`
- Identify the **trust assignment**: who can call this? Pre-auth? Authenticated user? Specific role? Service-to-service? Specific tenant?
- Identify any **elevated capability**: writes DB, deploys, signs a payload, accesses files, reaches the network, runs code

Output for §1:

```markdown
## Scope

- Feature: <name + 1-line description>
- Source: <brief path> / <PR> / <spec>
- Trust assignment: <who can reach this>
- Asset sensitivity: <data type, classification>
- Elevated capability: <write-X | deploy-Y | net-out | code-exec | ...>
```

### 2. Trust boundaries, assets, entry points

List **each** trust boundary the feature crosses. A boundary is anywhere trust changes:

- Browser ↔ web server (auth boundary)
- Web server ↔ internal API service (internal boundary — assume broken)
- Internal ↔ third-party service (egress boundary)
- Service ↔ secret manager (creds boundary)
- User ↔ admin role (privilege boundary)
- Tenant-A ↔ Tenant-B (isolation boundary)

For **each** boundary, list:

```markdown
- **Boundary N: <name>** (e.g. "Browser ↔ Auth API")
  - **Assets protected**: <token | data | config | ...>
  - **Direction**: <ingress | egress | both>
  - **Auth model**: <none | session-cookie | mTLS | signed-token | ...>
  - **Entry points**: <endpoint paths / RPC names / message topics — with file:line>
```

### 3. Attacker capability calibration

For each boundary, name the attacker:

| Attacker profile | Capability | Examples |
|---|---|---|
| Network snooper (passive) | Observe encrypted traffic only | Coffee-shop Wi-Fi |
| Network attacker (active) | Observe + modify unencrypted traffic | Strip TLS, MITM |
| Unauthenticated user | Reach any unauthenticated endpoint | Pre-login flow abuse |
| Authenticated low-privilege user | Any auth-scoped endpoint | IDOR, session fixation |
| Authenticated high-privilege user | All endpoints accessible to their role | RBAC escalation |
| Compromised dependency | Reach the local process / data | Supply-chain RCE |
| Compromised developer machine | Reach local secrets, signed commits | Phish → creds → token theft |
| Malicious operator | Reach the production runtime / DB | Insider threat |

For this feature, identify which of these **actually apply** — a stateless CLI tool doesn't face browser-attacker profiles; an internal admin tool doesn't face "unauthenticated user".

### 4. Attack path enumeration (per STRIDE — concrete + file:line)

For each attacker profile × each boundary, enumerate attack paths. STRIDE categories:

| Category | Question |
|---|---|
| **Spoofing** | Can the attacker forge identity of another user / service? |
| **Tampering** | Can the attacker modify data in transit / at rest / during processing? |
| **Repudiation** | Can the attacker perform an action without audit log? |
| **Information disclosure** | Can the attacker read data they shouldn't? |
| **Denial of service** | Can the attacker take the feature down / starve resources? |
| **Elevation of privilege** | Can the attacker reach a higher-trust role from a lower-trust one? |

For **each** suspected path, capture:

```markdown
### STRIDE-<X>-N: <one-line summary>
- **Attacker**: <profile from §3>
- **Entry point**: `<file:line>` — `<brief code citation>`
- **Asset targeted**: <what they reach>
- **Pre-conditions**: <what must be true for this to work>
- **Severity**: CRITICAL | HIGH | MEDIUM | LOW (calibrate against blast radius)
  - CRITICAL = unauth RCE / secret theft / multi-tenant breach
  - HIGH = privilege escalation / cross-tenant data leak / sensitive data exposure
  - MEDIUM = info leak limited in scope / denial-of-resource isolated / audit gap recoverable
  - LOW = best-practice deviation / no realistic path in current architecture
- **Concrete scenario**: <2-3 sentence narrative with attacker actions>
- **Mitigation(s)**: <specific control(s) with file:line where they live OR need to be added>
```

Severity rules:
- Unauthenticated → CRITICAL by default unless the feature is public-read
- Multi-tenant cross-talk → CRITICAL
- Auth-bypass or session-fixation → CRITICAL
- Single-tenant info leak of low-sensitivity data → MEDIUM
- Audit-log gap on a privileged action → MEDIUM

### 5. Prioritization + user validation

After enumerating paths:

1. **Drop severity=n/a** — paths that have no realistic attacker (e.g. "compromised kernel" for a SaaS web app)
2. **Group findings by mitigation owner** — many paths share a mitigation (e.g. one auth-fix covers 5 paths)
3. **Validate assumptions with the user** — the model is a hypothesis; ask 2-3 questions to confirm attacker profile, deployment model (managed vs self-hosted), and threat priorities
4. **Decide: model done; ship to implementation; or model needs more**

### 6. Output: `<repo>-threat-model.md`

Write the model to `<repo>-threat-model.md` at workspace root. Structure:

```markdown
# Threat model — <feature name>

> Date: <date>
> Author: <agent name + version>
> Brief: <link to scope / spec>

## 1. Scope & sensitivity
[output of §1]

## 2. Trust boundaries
[output of §2]

## 3. Attacker profiles
[output of §3]

## 4. Attack paths
[output of §4 — sorted by severity, each finding with file:line + concrete scenario + mitigation]

## 5. Mitigations to implement (or already present)

| Mitigation | Already implemented? | Related findings | Owner |
|---|---|---|---|
| <control> | yes/no/partial — file:line | STRIDE-X-N, STRIDE-X-M | <team> |

## 6. Open assumptions (need user validation)
- [assumption 1 — what we assumed + what would change the model if wrong]
- [assumption 2]

## 7. Out of scope
- <explicit non-coverage; one line each>

## 8. Change log
- <date> — initial
```

Commit the file (or save as a PR review artifact) so the team can reference it during implementation. Threat models decay — re-run on significant architecture changes.

## omo Integration

| OMO capability | Used for |
|---|---|
| `oracle` agent | Calibration calls when severity assignment is judgment-laden (e.g. "is cross-tenant data leak via this API actually CRITICAL or just HIGH?") |
| `security-research` mode | Post-modeling: 3 hunters + 2 PoC engineers to verify the highest-severity findings reproduce |
| `context7` MCP | Lookup latest OWASP / NIST references when ranking severity or naming controls |
| `websearch` MCP | CVEs for dependencies mentioned in §2 trust boundaries (newsworthy attack patterns in past 90 days) |
| OMO `review-work` skill | Stage-2 review for the threat-model.md before sharing with the user |

## Common Rationalizations

| Excuse | Why it's wrong |
|---|---|
| "It's a small feature, threat model is overkill" | Threat model cost is roughly proportional to *boundaries crossed*, not to lines of code. A 20-line auth helper can introduce 5 boundaries. |
| "We don't have time for a model" | A 1-page model is cheaper than the postmortem + rollback + customer-trust repair after a boundary cross. |
| "STRIDE is too academic" | STRIDE is just a checklist; the discipline is *naming the boundary* then asking "who can reach it from where". The acronyms are bookkeeping, not ceremony. |
| "We trust all internal users" | The threat model says which internal users can reach which boundary; RBAC and "all dev staff have prod SSH" are real boundary decisions. |
| "We'll figure out security during hardening" | Hardening applies existing controls; threat modeling decides *which controls are needed*. Different questions. |
| "This is internal-only" | "Internal" still has boundaries: laptop ↔ corp-VPN, dev box ↔ prod creds, on-call ↔ prod DB. A model is cheap even for internal tools. |
| "Output goes in a wiki nobody reads" | Output should be a Markdown file in the repo, reviewed alongside the implementation PR. Wikis rot. |
| "We can ship and model later" | Once the implementation is done, sunk-cost bias dominates — the model either re-shapes the code (expensive) or stays a paper exercise. |

## Red Flags

The threat model is going wrong if:

- §1 Scope says "the feature" without naming the trust assignment — vague scope = useless model
- §2 lists only 1-2 boundaries and the feature touches 5 (boundary-coverage failure)
- §3 attacker profiles repeat — the model isn't enumerating real attackers
- §4 paths are listed as "STRIDE-X: <control is missing>" instead of attacker-driven narratives
- File:line absent on at least one entry point or mitigation anchor — model is decoupled from code
- Severity rating has no narrative: "HIGH because I said so" is not a rating
- §5 Mitigations table says "TBD owner" for >half the rows — model is undeliverable
- §6 Open assumptions is empty — every model has assumptions; absent ⇒ unspoken, unverified
- §7 Out of scope is missing — scope-creep risk
- §6 assumptions aren't validated with the user before finalizing — model is unverified
- Threat model written but never committed to repo — model has no audit trail

## Verification

Before claiming the threat model is done, produce evidence:

- [ ] §1 Scope completed with sensitivity + trust assignment + elevated capability
- [ ] §2 every boundary the feature crosses, named, with assets + entry points (`file:line`)
- [ ] §3 attacker profiles explicitly enumerated (no template-row repeat)
- [ ] §4 each finding has attacker profile + entry point + asset + pre-conditions + severity + concrete scenario + mitigation(s)
- [ ] §4 severity ratings justified (one-line rationale per finding, not just a label)
- [ ] §4 file:line citations present for entry points AND mitigations
- [ ] §5 mitigations table with owner column; gaps explicitly `no` or `partial`
- [ ] §6 Open assumptions — at least 2-3 listed, validated with user
- [ ] §7 Out-of-scope explicitly listed (one line each)
- [ ] File saved at `<repo>-threat-model.md`
- [ ] If stage-2 review applies (production-critical), `review-work` has run

**Acceptance criterion**: A second reviewer can read only the file and reach the same severity ranking, OR can pinpoint which §3 / §4 / §6 assumption they disagree with and why. The model is a contract; the team can call it on it later.
