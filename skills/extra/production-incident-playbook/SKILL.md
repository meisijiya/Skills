---
name: production-incident-playbook
description: "End-to-end incident handling — runbook templates for in-flight mitigation + blameless postmortem templates for after-action review. Use during an active production incident to follow the detect / triage / mitigate / resolve / communicate phases, or after an incident to write a postmortem that turns the outage into actionable follow-ups. Pairs with observability-and-instrumentation (the data sources — alerts, dashboards, traces) and security-incident-response (the security-specific variant). Read the runbook phases DURING the incident; write the postmortem within 5 business days after."
allowed-tools: "Read Bash Glob WebFetch"
---

# production-incident-playbook

## Overview

A production incident has two distinct lifecycles:

1. **In-flight** (minutes to hours): you're debugging live, the system is broken, users are affected. The work is operational — find the cause, mitigate, communicate.
2. **After-action** (days to weeks): you're writing the postmortem. The work is learning — what happened, why, how to prevent recurrence.

This skill ships **runbook templates for the in-flight phase** (what to do when the alert fires) and **postmortem templates for the after-action phase** (what to write 5 days later). Together they form the playbook that turns an outage into a system improvement.

Distinct from:

| Skill | Focus |
|---|---|
| `observability-and-instrumentation` | What to log / measure / trace BEFORE the incident |
| `security-incident-response` | Security-specific incidents (breach, CVE exploitation, leaked creds) — uses NIST CSF simplified framework |
| `pre-ship-gate` | Pre-deploy audit (catches the deploy-side silent failures BEFORE they hit users) |
| `closed-loop-delivery` | 24h+ post-deploy runtime evidence (the bridge between deploy and any incident) |

This skill is for **non-security** production incidents: latency spike, error rate spike, dependency outage, capacity exhaustion, deploy-caused regression. For security, see [`security-incident-response`](~/.agents/skills/security-incident-response/SKILL.md).

## When to Use

**Use when:**

- Active production incident: alert fired, you're the on-call or the named incident commander
- Writing a runbook template for a service / surface (proactive, before the incident)
- Postmortem time: it's been 1-5 days since the incident, you need to write up what happened
- Designing an incident-management process for the team (runbook library, postmortem template, review cadence)
- Periodic review of past postmortems — extracting patterns, ensuring follow-ups landed

**NOT for:** (scenario description — let description match decide)

- Security incidents (breach / leak / CVE / ransom) → [`security-incident-response`](~/.agents/skills/security-incident-response/SKILL.md)
- Pre-deploy catching of silent failures → [`pre-ship-gate`](~/.agents/skills/pre-ship-gate/SKILL.md)
- 24h+ post-deploy runtime monitoring (before the incident fires) → [`closed-loop-delivery`](~/.agents/skills/closed-loop-delivery/SKILL.md)
- Per-deploy evidence collection (PR-time) → [`verification-before-completion`](~/.agents/skills/verification-before-completion/SKILL.md)

## Process

### Part 1 — In-flight runbook (DURING the incident)

Use this when an alert fires and you're the first responder.

#### Phase 1 — Detect (already happened; confirm the alert)

- **Confirm the alert is real** (not a noisy alert, not a test, not a staging env)
- If false positive: silence the alert, file a follow-up to improve detection
- If real: open incident channel, declare incident commander (yourself if no-one else)

#### Phase 2 — Triage (first 5 min)

Fill in:

```markdown
## Incident header
- Started: <timestamp>
- Detected: <timestamp>
- Detected by: <alert name | user report | etc.>
- Severity: SEV1 (full outage, all users) | SEV2 (degraded, some users) | SEV3 (minor impact)
- Affected surface: <service / endpoint / feature / region>
- Customer-visible: yes | no
- Blameless assumption: the goal is to learn, not to assign fault
```

#### Phase 3 — Mitigate (first 30 min, goal: stop the bleeding)

The mitigation doesn't need to fix the root cause — it needs to stop the impact. Common mitigation moves:

- Roll back the most recent deploy (`kubectl rollout undo` / `helm rollback` / `vercel rollback --to <id>` / `fly releases rollback`)
- Feature-flag the affected path OFF (not "fix the bug", just "remove the offending code path from production")
- Throttle / rate-limit the affected endpoint (slowdown is better than 100% failure)
- Drain traffic from the bad pod / region / node
- Failover to the secondary region / cluster
- Scale up the healthy pool (if degradation is capacity-driven)

Document in the incident channel: "Mitigation applied: <action>, <timestamp>". Other responders can see what's been tried.

#### Phase 4 — Resolve (30 min to 4 hours, goal: find the cause)

Now that impact is contained, dig into root cause. Use [`debugging-and-error-recovery`](~/.agents/skills/debugging-and-error-recovery/SKILL.md) (5-step triage: reproduce / localize / reduce / fix / guard) and [`diagnosing-bugs`](~/.agents/skills/diagnosing-bugs/SKILL.md) (symptom-driven diagnosis loop for hard bugs).

Apply the fix:

- If the fix is a code change: PR + review + deploy. Note: **don't skip the deploy gate** because you're in incident mode. Use [`pre-ship-gate`](~/.agents/skills/pre-ship-gate/SKILL.md) Phase A + B as normal.
- If the fix is config / flag / capacity: deploy via normal path with monitoring increased.

#### Phase 5 — Communicate (ongoing, every 30-60 min during the incident)

Internal:

- Status update in incident channel every 30 min (even if "still investigating, no change")
- Update severity if it changes
- Hand off to a new incident commander if shift ends
- Page additional responders if needed (with specific ask: "we need someone who knows the auth service")

External (if customer-visible):

- Status page update (start within 30 min of customer-visible incidents)
- Customer support team: brief them with what's happening + what's safe to say
- For SEV1: leadership notification within 15 min; full situation report within 60 min

Template for status update:

```markdown
## Status update — <incident ID>
- Time: <timestamp>
- Status: investigating | identified | mitigated | resolved
- Customer impact: <what users are seeing>
- Mitigation in place: <what's been done>
- Next update: <timestamp>
```

#### Phase 6 — Close

- Confirm customer impact is gone (check error rate + user reports)
- Remove mitigation moves if appropriate (e.g. leave the feature flag OFF if a follow-up is needed to fix the underlying issue)
- Schedule the postmortem (within 5 business days for SEV1/2)
- Hand off the incident channel archive to the postmortem owner
- Send "all clear" in the channel; thank responders

### Part 2 — Postmortem (AFTER the incident)

Use this 1-5 days after the incident closed.

#### Template — blameless postmortem

```markdown
# Postmortem — <incident title>

> Date of incident: <YYYY-MM-DD>
> Authors: <names>
> Status: draft | under review | final

## Summary (1 paragraph)
What happened, in customer-impact terms. Read this first.

## Impact
- Customer-visible duration: <X hours Y minutes>
- Users affected: <N> or <X% of total>
- Severity: SEV<1|2|3>
- Revenue / SLA impact: <quantified or "not quantified">

## Timeline (UTC)
- HH:MM — what happened
- HH:MM — alert fired
- HH:MM — incident commander declared
- HH:MM — mitigation applied
- HH:MM — root cause identified
- HH:MM — fix deployed
- HH:MM — incident closed

Use precise UTC timestamps; avoid "around" / "approximately".

## Root cause (3 paragraphs)
What technically broke. Why. What the chain was.

The "5 whys" technique — keep asking "why" until you reach a structural cause, not a person:

1. Why did the error rate spike? Because the auth service returned 503.
2. Why did the auth service return 503? Because its connection pool was exhausted.
3. Why was the connection pool exhausted? Because each request held a connection for 30s.
4. Why did each request hold a connection for 30s? Because a new dependency added a 30s timeout.
5. Why did adding a 30s timeout slip through review? Because the review focused on functional correctness, not connection-pool budget.

The 5th why is the structural fix; the others are proximate causes.

## What went well
- Detection fired within <X> of impact (was the alert good?)
- Triage took <X> (was escalation clear?)
- Mitigation took <X> (was the rollback runbook available?)

## What went poorly
- Alert took <X> to fire (alert tuning needed?)
- Root cause took <X> to identify (debugging tooling needed?)
- Mitigation required manual action that should have been automated

## Where we got lucky
- The same chain could have been much worse (which mitigations prevented escalation?)

## Action items
| Item | Owner | Due | Type |
|---|---|---|---|
| Add timeout budget check to PR review template | alice | 2026-XX-XX | process |
| Implement connection-pool circuit breaker | bob | 2026-XX-XX | code |
| Add connection-pool saturation alert (P95 conn > 80%) | carol | 2026-XX-XX | observability |
| Runbook update: connection pool exhaustion response | dave | 2026-XX-XX | docs |

Each action item MUST have:
- Concrete owner (named person, not "team")
- Concrete due date
- Type (process / code / observability / docs)

## Follow-up review
- Action items reviewed at next monthly on-call rotation
- Action items older than 90 days with no progress → escalate

## Lessons
- <1-3 sentences for the org to learn from>
```

#### Reviewing a postmortem

When reviewing someone else's postmortem:

- [ ] Summary captures customer impact (not internal jargon)
- [ ] Timeline has precise UTC timestamps
- [ ] Root cause is structural (5+ whys), not personal
- [ ] Blameless tone throughout (no "X should have done Y differently")
- [ ] Action items are concrete (owner + date + type), not vague ("improve monitoring")
- [ ] "Where we got lucky" is honest (not just positive)
- [ ] Lessons are short and transferable (not just for this team)

If any of these fail: ask the author to revise before publishing.

### Common rationalizations (during incident)

| Excuse | Why it's wrong |
|---|---|
| "Skip the postmortem, we're shipping fast" | Postmortem IS the velocity investment. The next incident of the same shape is the cost. |
| "It was a one-off, won't happen again" | It will happen again if the structural cause isn't fixed. The 5-whys exists for this. |
| "Don't blame the runbook, blame the operator" | Operators follow runbooks. If the runbook was insufficient, fix it. |
| "The fix is obvious, just revert" | Reverting is a mitigation; the structural fix may be different. Document both. |
| "Customer impact was small" | Severity ≠ impact. Even SEV3 incidents get postmortems if they're symptomatic of a structural issue. |
| "We don't have time for a full postmortem" | A 30-min skeleton postmortem is better than no postmortem. The 5-day deadline is generous; don't waste it. |

## omo Integration

| OMO capability | Used for |
|---|---|
| `oracle` agent | Root-cause hypothesis calibration when the cause is non-obvious ("is this really the bug or just a symptom?") |
| `general` agent | Parallel investigation subagents for "is this also affected?" fan-out |
| OMO `review-work` skill | Stage-2 review of the postmortem before publishing (catches missing structural fixes) |
| `websearch` MCP | Similar-incident lookup ("did this happen elsewhere in our industry last quarter?") |
| `context7` MCP | Runbook tooling docs (k8s / helm / vendor-specific rollback commands) |

## Common Rationalizations

| Excuse | Why it's wrong |
|---|---|
| "We don't have runbooks for every service" | Start with the highest-traffic service; expand from there. Some runbook > zero. |
| "The postmortem takes a full day to write" | A 30-min skeleton is better than no postmortem. Schedule 1 hour. |
| "Action items never get done" | Track them; review at next rotation; escalate stale items. The system is broken, not the action item. |
| "We don't have time for the 5 whys" | The 5 whys is the part that prevents recurrence. Skipping it is the cost-saving that costs most. |
| "Customers already moved on; the postmortem is for us" | Correct — the postmortem IS for the team, not the customer. Don't skip it because no-one else will read it. |
| "We already know the cause, postmortem is busywork" | Documenting forces structural thinking; documenting the wrong cause is worse than not documenting. |

## Red Flags

The playbook is being applied wrong if:

- Phase 1 alert was silenced without a follow-up to improve detection (alert noise will compound)
- Phase 3 mitigation took > 1 hour (runbook gap; need a fast-path fix)
- Phase 4 fix was deployed without `pre-ship-gate` (incident-in-progress is not an excuse for skipping the deploy gate)
- Phase 5 status updates were not sent (stakeholders blind = trust erosion)
- Postmortem has no action items (a no-action-item postmortem is theatre)
- Postmortem has action items without owners (will be silently dropped)
- Postmortem blames a person ("Alice should have caught this in review") — not blameless
- Postmortem timeline has imprecise timestamps ("later that morning" instead of HH:MM UTC)

## Verification

For a well-applied playbook:

**In-flight**:
- [ ] Phase 1 alert acknowledged within 5 min
- [ ] Phase 2 triage header filed with severity + affected surface + timestamp
- [ ] Phase 3 mitigation applied within 30 min for SEV1/2
- [ ] Phase 4 root cause + fix path documented in incident channel
- [ ] Phase 5 status updates sent every 30-60 min
- [ ] Phase 6 incident closed with explicit "all clear" + postmortem scheduled

**Postmortem** (within 5 business days):
- [ ] Summary in customer-impact terms (1 paragraph)
- [ ] Timeline with precise UTC timestamps (no "around")
- [ ] Root cause via 5 whys; structural cause reached
- [ ] Action items with concrete owner + date + type
- [ ] Blameless tone throughout
- [ ] Honest "what went well / what went poorly / where we got lucky"
- [ ] Review-stage-2 (OMO review-work or equivalent) before publishing

**Quarterly review**:
- [ ] All postmortem action items < 90 days old reviewed; > 90 days escalated
- [ ] Pattern detection across postmortems (recurring themes; flag if same structural cause appears in 2+ postmortems)

**Acceptance criterion**: A new on-call engineer reading the runbook phase can resolve a similar incident without asking for help; a new team member reading a past postmortem understands what happened + why + what's changing as a result.
