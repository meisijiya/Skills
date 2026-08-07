# `/research` — high-trust-source research with cited Markdown output

Cited research findings on planning / design questions, written to `docs/research/<plan-slug>/<topic>.md` (git tracked, project-level audit log). Thin contract layer over the OMO `librarian` agent — this skill enforces the source whitelist, citation format, plan-required gate, async dispatch, and the audit entry; librarian does the actual retrieval.

## When to use

- A planning or design decision needs an authoritative answer that should outlive the current session as a citable record.
- Candidate sources are official vendor docs, IETF / W3C / IEEE RFCs, source-repo code with `path:line` anchors, or project ADRs / current plan Phase 1 spec — the four whitelisted `[ref]` types.
- A wayfinder `research` ticket needs dispatch (async by default).
- `brainstorming` / `spec-driven-development` / `prototype` surfaces a question the local codebase cannot answer.

**Not for:** casual knowledge questions (use agent default tools), non-authoritative sources like Stack Overflow or blogs (link in `See Also` only — never cite as `[ref]`), or plan-less invocations (refuse with `Plan context required. Open a plan first with /brainstorming or /ulw-plan.`).

## How it works

```
[plan-scoped question]
  ↓
/research skill
  ├─ plan-required gate (refuse if no plan slug)
  ├─ topic dedupe (docs/research/<plan-slug>/<topic>.md exists? → reuse, no re-dispatch)
  ├─ mode: sync (short fact-check) | async (≥ 3 sub-questions, wayfinder dispatch)
  ├─ dispatch librarian (background: true|false) with whitelist + format contract
  ↓
librarian output (4-type whitelist only, inline [`ref:<type>,<id>`](url))
  ↓
/research closeout:
  ├─ write docs/research/<plan-slug>/<topic>.md (frontmatter + 5 sections)
  ├─ append [research] ts=... topic=... findings=... mode=... to .omo/notepads/<plan>/decisions.md
  └─ return:
       sync  → "findings: <path> (N findings, M sources)"
       async → {"status": "running", "task_id": "..."}
```

## Source whitelist (4 types — exact)

| Type | Example |
|---|---|
| `ref:official-docs` | `` [`ref:official-docs,vue-3.5-rfc`](https://github.com/vuejs/rfcs/discussion/502) `` |
| `ref:rfc` | `` [`ref:rfc-9457`](https://datatracker.ietf.org/doc/html/rfc9457) `` |
| `ref:source-repo` | `` [`ref:source-repo,src/auth.ts:L42`](https://github.com/.../blob/main/src/auth.ts#L42) `` |
| `ref:spec` | `` [`ref:spec,ADR-0007`](https://.../docs/adr/0007-cite-discipline.md) `` |

Anything else (Stack Overflow, blogs, Medium, Reddit, AI-generated answers) goes in `See Also` as a plain markdown link `[label](url)`. The regression test `scripts/test-citation-discipline.sh` rejects non-whitelist citations and missing plan slugs.

## Output file

`docs/research/<plan-slug>/<topic>.md` — required YAML frontmatter (`topic, plan, ts, mode, status, sources_used`) + five body sections in order: `Question` / `Findings` / `Recommendation` / `See Also` / `Sources Cited`. Each `Findings` subsection carries at least one `[ref:*]` inline citation; `See Also` is plain links only.

## Audit entry

```
[research] ts=<iso8601> topic=<slug> findings=docs/research/<plan-slug>/<topic>.md mode=sync|async
```

Appended to `.omo/notepads/<plan>/decisions.md` (parallel to existing `[proto]` / `[amend]` / `[wayfinder]` formats). The `ts` is ISO 8601 in UTC; the path is repo-relative; the line is the only accepted shape (case-greped by the test suite).

## Hard rules

- Refuse without a plan slug — verbatim `Plan context required. Open a plan first with /brainstorming or /ulw-plan.`
- Only `ref:official-docs`, `ref:rfc`, `ref:source-repo`, `ref:spec` may appear as `[ref:*]`. Stack Overflow / blogs / Medium → `See Also` only.
- `See Also` is plain markdown links; never wrap in `[ref:*]`.
- Every `Findings` subsection has at least one `[ref:*]` inline citation.
- Async dispatch returns the exact `{"status": "running", "task_id": "<id>"}` shape — no synchronous result, no fallback path.
- Idempotency: a re-invocation with the same `(plan, topic)` reuses the existing output and does not re-dispatch librarian.
- Librarian agent is the execution body; **do not modify librarian** to make this skill work.

## Related skills

- Wayfinder dispatch: [`wayfinder`](~/.agents/skills/wayfinder/SKILL.md) (P1) — `research` ticket type, async by default
- Spec authoring context: [`spec-driven-development`](~/.agents/skills/spec-driven-development/SKILL.md) — research fills gaps Phase 1 cannot resolve from local code
- Verifier: `scripts/test-citation-discipline.sh` — 7 sub-tests (Stack Overflow refusal, official-docs accept, plan-less refusal, 4-type whitelist exact match, See Also non-ref accept, async dispatch shape, idempotent `(plan, topic)` completion)
