---
name: research
description: "Investigates planning/design questions against high-trust primary sources (official docs, RFCs, source-repo, project ADRs / spec); writes cited Markdown findings to `docs/research/<plan-slug>/<topic>.md`. Use when a decision requires authoritative information as a citable record. Requires plan context — refuses plan-less with `Plan context required.` NOT for casual questions or Stack Overflow / blogs."
allowed-tools: "Read Edit Bash Glob Grep"
---
version: 0.1.0

# research

## Overview

High-trust-source research with cited Markdown output to `docs/research/<plan-slug>/<topic>.md`. The skill is a thin **contract layer** over the OMO `librarian` agent: librarian does the actual retrieval, `/research` enforces the 4-type source whitelist, the inline citation format, the plan-required invocation gate, async dispatch, and the `.omo/notepads/<plan>/decisions.md` audit entry.

The whole point is to make a cited record that outlives the session: a future reader (human or agent) must be able to point at a finding and say "this came from `ref:rfc-9457`, here's the URL, here is the page that resolves it" — not "trust me, I checked Stack Overflow".

## When to Use

**Use when:**
- A planning or design decision needs an authoritative answer and the answer should be saved as a citable Markdown record (not just a chat reply).
- The candidate sources are official vendor docs, IETF / W3C / IEEE RFCs, source-repo code with `path:line` anchors, or project ADRs / current plan Phase 1 spec — the four whitelisted `[ref]` types.
- The user wants the work to keep running while they plan further (async mode), or wants a sync answer for a short fact-check.
- A wayfinder ticket of type `research` needs dispatch.
- `brainstorming` / `spec-driven-development` / `prototype` surfaces a question that the local codebase cannot answer (e.g. "what does the latest Vue RFC say about prop inheritance?" or "what is the IANA reservation rule for header `Foo-Bar`?").

**NOT for:**
- Casual knowledge questions ("what is Next.js?", "is React faster than Vue?") — answer directly with agent default tools, no `research` invocation.
- Non-authoritative sources: Stack Overflow, blog posts, Medium articles, Reddit threads, AI-generated answers. These may appear in `See Also` as plain links, **never** as `[ref:*]` citations.
- Plan-less research: refuse with the literal `Plan context required. Open a plan first with /brainstorming or /ulw-plan.` and stop. There is no way to land a research output without a plan slug.
- Pure code review / debugging / hotfixes — those are `debugging-and-error-recovery` / `diagnosing-bugs` / `incremental-implementation` territory.
- Anything the user has already answered in the current conversation — do not re-research.

**Skip conditions summary:** the bar is "needs an authoritative, citable record AND candidate sources are in the whitelist AND a plan is open". If any of those three is false, do not invoke this skill.

## Process

### 1. Gate on plan context

Before anything else, check for a plan slug:

- If the caller is inside an active `.omo/plans/<slug>.md` (plan_approved or later), or the user has explicitly named a slug in this turn, **accept the slug**.
- If there is no plan and no slug, **refuse immediately** with the exact literal:

  ```
  Plan context required. Open a plan first with /brainstorming or /ulw-plan.
  ```

  This is the verbatim refusal string the regression test (`scripts/test-citation-discipline.sh` case (c)) greps for. Do not paraphrase it. The skill is not the place to bootstrap a plan — that is [`brainstorming`](~/.agents/skills/brainstorming/SKILL.md) or [`ulw-plan`](~/.agents/skills/ulw-plan/SKILL.md).

The slug feeds two downstream slots: the output file path (`docs/research/<plan-slug>/<topic>.md`) and the `decisions.md` audit entry (`.omo/notepads/<slug>/decisions.md`).

### 2. Resolve the topic and dedupe

Topic is a kebab-case slug (≤ 60 chars, matches `^[a-z0-9][a-z0-9-]{0,59}$`). Prefer a phrase the user already wrote; if they wrote a sentence, extract the first ≤ 8 words and slugify.

Before opening anything, check for an existing record:

- `docs/research/<plan-slug>/<topic>.md` already exists → report the existing path, do **not** re-run librarian, and append a `[research]` entry to `decisions.md` with `mode=sync` and the existing `findings=<path>`. This is the idempotency contract tested in case (g). If the file was last modified within the last 60 seconds, treat it as in-flight and warn the user before re-dispatching (rare duplicate-dispatch window).

### 3. Pick the mode

Default mode is `sync` for short fact-checks, `async` for multi-source investigations. Heuristics:

| Signal | Mode |
|---|---|
| wayfinder ticket of type `research` dispatches `/research` | `async` |
| user said "后台" / "background" / "in the background" | `async` |
| topic spans ≥ 3 sub-questions or ≥ 4 distinct citations expected | `async` |
| everything else (default) | `sync` |

The chosen mode is recorded verbatim in the `decisions.md` entry as `mode=async|sync`.

### 4. Dispatch librarian

Delegate retrieval to the OMO `librarian` agent. **Do not modify librarian**; the contract is one prompt with the following mandatory clauses:

- **Source whitelist (whitelist, not preference):** only these four may be cited as `[ref:*]`:
  - `ref:official-docs` — vendor docs (e.g. Vue / React / Anthropic / Stripe / IANA registry)
  - `ref:rfc` — IETF / W3C / IEEE RFCs
  - `ref:source-repo` — repo source with `path:line` anchor
  - `ref:spec` — `docs/adr/*.md` or current `.omo/plans/<slug>.md` Phase 1 spec
- **Citation format:** inline markdown anchor: `` [`ref:<type>,<id>`](url) ``. The `<id>` is the canonical identifier (e.g. `2026-07-15` for a dated doc, `rfc-9457` for an RFC, `src/auth.ts:L42` for a source-repo line, `ADR-0007` for an ADR).
- **Section contract:** the output **must** contain `Question` / `Findings` (one subsection per finding, each with at least one `[ref:*]`) / `Recommendation` / `See Also` (plain links, no `[ref]`) / `Sources Cited` (deduplicated list of all `[ref:*]` used).
- **Refusal rule:** if a needed source is not in the whitelist, the librarian must surface it in `See Also` (plain link, no `[ref]`) and continue, never invent a `[ref:*]` for it.

The full prompt template is below in § "Dispatch prompt template" so it is copy-pasteable.

### 5. Capture the output

Write the librarian output verbatim to `docs/research/<plan-slug>/<topic>.md`. Required YAML frontmatter:

```yaml
---
topic: <topic-slug>
plan: <slug>
ts: <iso8601>
mode: sync|async
status: complete
sources_used: <comma-separated list of ref:<type>,<id>>
---
```

Required body sections, in order: `Question`, `Findings`, `Recommendation`, `See Also`, `Sources Cited`. Missing any of these is a `BLOCKED` return, not `DONE`.

### 6. Append the audit entry

Append one line to `.omo/notepads/<slug>/decisions.md` (create the directory if absent). Use this exact shape — `scripts/test-citation-discipline.sh` case (g) greps for it:

```
[research] ts=<iso8601> topic=<topic-slug> findings=docs/research/<plan-slug>/<topic>.md mode=sync|async
```

The `ts` must be ISO 8601 in UTC (`YYYY-MM-DDTHH:MM:SSZ`). The path must be repo-relative. No additional keys, no prose on the same line.

### 7. Return

- **Sync mode:** return a one-line summary plus the absolute path. Format: `findings: docs/research/<plan-slug>/<topic>.md (N findings, M sources)`.
- **Async mode:** return immediately with the exact JSON shape the regression test asserts (case (f)):

  ```json
  {"status": "running", "task_id": "<id>"}
  ```

  Caller polls via `/research status <task_id>` or by checking filesystem existence of the output file. The async return **must not** block on librarian completion — it returns the moment the dispatch is acknowledged.

## Source Whitelist (4 types — exact)

| Type | Pattern | Example |
|---|---|---|
| `ref:official-docs` | `[\`ref:official-docs,<id>\`](https://...)` | `` [`ref:official-docs,vue-3.5-rfc`](https://github.com/vuejs/rfcs/discussion/502) `` |
| `ref:rfc` | `[\`ref:rfc-<number>\`](https://datatracker.ietf.org/doc/html/rfc<number>)` | `` [`ref:rfc-9457`](https://datatracker.ietf.org/doc/html/rfc9457) `` |
| `ref:source-repo` | `[\`ref:source-repo,<path:line>\`](https://...#L<line>)` | `` [`ref:source-repo,src/auth.ts:L42`](https://github.com/.../blob/main/src/auth.ts#L42) `` |
| `ref:spec` | `[\`ref:spec,<id>\`](https://.../adr/<id>.md)` | `` [`ref:spec,ADR-0007`](https://.../docs/adr/0007-cite-discipline.md) `` |

Anything outside these four patterns is non-authoritative for citation purposes. Stack Overflow, blog posts, Medium, Reddit, AI-generated answers, vendor forum posts — all of these go in `See Also` as plain markdown links `[label](url)`, never wrapped in `[ref:*]`.

When a candidate source is not in the whitelist, the librarian dispatch refuses it with the literal string `non-whitelist source: stackoverflow` (or the equivalent `non-whitelist source: <hostname>` for other non-whitelisted hosts), and surfaces the link in `See Also` instead.

## Output File Schema

```markdown
---
topic: vue-prop-inheritance
plan: skills-extension-v1
ts: 2026-07-29T10:30:00Z
mode: sync
status: complete
sources_used: ref:rfc-9457, ref:source-repo,src/runtime-core/apiInject.ts:L42
---

# Question
<one paragraph: what was asked and why>

## Findings

### Finding 1: <subject>
<one paragraph>
[`ref:official-docs,vue-3.5-rfc`](https://...) · [`ref:source-repo,src/runtime-core/apiInject.ts:L42`](https://...#L42)

### Finding 2: <subject>
<one paragraph>
[`ref:rfc-9457`](https://datatracker.ietf.org/doc/html/rfc9457)

## Recommendation
<one paragraph: what the planner should do, given the findings>

## See Also
- [Stack Overflow: similar Q&A](https://stackoverflow.com/...) — non-authoritative
- [Medium post on related topic](https://...) — non-authoritative

## Sources Cited
- [`ref:official-docs,vue-3.5-rfc`](https://github.com/vuejs/rfcs/discussion/502)
- [`ref:rfc-9457`](https://datatracker.ietf.org/doc/html/rfc9457)
- [`ref:source-repo,src/runtime-core/apiInject.ts:L42`](https://github.com/.../blob/main/src/runtime-core/apiInject.ts#L42)
```

## Dispatch Prompt Template

Copy verbatim into the librarian dispatch prompt. Fill the `<...>` slots from the caller; do not paraphrase the contract clauses — the test suite greps for the literal strings.

```
You are retrieving research on: <topic-slug>
Plan: <plan-slug>
Mode: sync|async

Source whitelist (only these four may appear as [ref:*]):
  ref:official-docs   vendor docs (Vue / React / Stripe / IANA / etc.)
  ref:rfc             IETF / W3C / IEEE RFCs
  ref:source-repo     repo source with path:line anchor
  ref:spec            docs/adr/*.md or current plan Phase 1 spec

Citation format (inline markdown anchor):
  [`ref:<type>,<id>`](url)
  e.g. [`ref:rfc-9457`](https://datatracker.ietf.org/doc/html/rfc9457)

Output contract (file docs/research/<plan-slug>/<topic-slug>.md):
  Required sections in order: Question / Findings / Recommendation / See Also / Sources Cited
  Each finding must carry at least one [ref:*] inline citation.
  See Also contains plain markdown links only — no [ref:*] tag.
  Sources Cited deduplicates every [ref:*] used.

Refusal rule:
  If a needed source is not in the whitelist, surface it in See Also as a plain link.
  Never invent a [ref:*] for a non-whitelisted source.

Frontmatter (required):
  topic, plan, ts (ISO 8601 Z), mode, status: complete, sources_used (comma list)
```

## Common Rationalizations

| Excuse | Reality |
|---|---|
| "Stack Overflow has the answer, just cite it" | Stack Overflow is non-authoritative. Link in `See Also`; do not wrap in `[ref:*]`. The test suite rejects this in case (a). |
| "Plan-less research is fine, I'll just save to /tmp" | The whole skill is plan-scoped (output path, decisions.md entry). A plan-less invocation has no place to land. Refuse with the literal `Plan context required.` |
| "I'll just answer the user directly, no need to write a file" | Then `/research` was not the right skill. Either use the agent's default tools for casual questions, or pick a different skill. `/research` always writes a cited record. |
| "I can see the answer in the local code, no need for librarian" | If the answer is already in the local code, no research is needed — just answer. `/research` is for questions that need external or higher-trust sources. |
| "Async dispatch means I should wait until librarian finishes" | Async means **return immediately** with `{"status": "running", "task_id": "..."}`. The caller polls separately. Returning a synchronous result for an async dispatch is a contract violation tested in case (f). |
| "Mode=sync is the default, no need to ask the user" | Mode is heuristic-driven (see § 3). For multi-source investigations, async is safer; the cost of an extra click is much lower than the cost of blocking a planning session. |
| "I'll skip the `decisions.md` entry, the file itself is enough" | The `decisions.md` line is the audit hook — without it, downstream tools cannot reconstruct when / by which plan / in which mode a research output was created. Idempotency depends on it (case (g)). |
| "See Also doesn't need to be exhaustive" | `See Also` is the safety valve for non-authoritative-but-relevant links. Skipping it is what makes an LLM silently "upgrade" a blog post to `[ref:official-docs]`. The section's existence is the discipline. |
| "The user wants the answer now, skip the file write" | The user wanted `/research`, not "tell me the answer". The file is the deliverable. Sync mode still writes the file; only the caller's experience is "fast". |
| "I'll let the librarian pick which source types to cite" | The whitelist is enforced by this skill, not by librarian. The dispatch prompt above tells librarian "only these four may appear as [ref:*]". If the librarian proposes a Stack Overflow citation, the caller rejects and asks for an authoritative alternative. |
| "I'll write the file to `.omo/research/` first, then distill to `docs/research/`" | Single-path: the canonical output goes directly to `docs/research/<plan-slug>/<topic>.md` (git tracked). No two-stage write; the cited record IS the deliverable from the start. |

## Red Flags

- Output file is missing the YAML frontmatter or any of the 5 required body sections.
- A `[ref:*]` link points to Stack Overflow, a blog, Medium, Reddit, or an AI-generated page.
- A `See Also` entry is wrapped in `[\`ref:...\`](...)` instead of plain `[label](url)`.
- `decisions.md` entry is missing, mistyped (e.g. `[Research]` capitalised), or has the wrong shape (`[research] ts=... topic=...` is the **only** accepted format).
- Sync mode returns `{"status": "running", "task_id": "..."}` (that's async's shape, not sync's).
- Async mode returns a synchronous result without a `task_id`.
- Plan-less invocation is accepted with a fallback path like `/tmp/research-<topic>.md` (refuse; do not improvise).
- The same `(plan, topic)` is dispatched twice without an idempotency check on the existing output file (filesystem existence) and `decisions.md` audit entry.
- Librarian is modified, patched, or "improved" — it is the execution body and **must not be touched** by this skill.
- The output cites a URL that does not resolve to one of the four whitelisted source types, even if the URL "looks official".

## Verification

Before returning to the caller, confirm:

- [ ] Plan slug is set; refusal literal is the exact string the test greps for.
- [ ] Output file `docs/research/<plan-slug>/<topic>.md` exists with YAML frontmatter (`topic, plan, ts, mode, status, sources_used`).
- [ ] All five body sections present in order: `Question` / `Findings` / `Recommendation` / `See Also` / `Sources Cited`.
- [ ] Every `Findings` subsection has at least one `[ref:*]` inline citation.
- [ ] `See Also` contains plain markdown links only — no `[ref:*]` wrapping.
- [ ] `Sources Cited` deduplicates every `[ref:*]` used.
- [ ] `decisions.md` entry is exactly: `[research] ts=<iso8601> topic=<slug> findings=docs/research/<plan-slug>/<topic>.md mode=sync|async`.
- [ ] Sync mode returned a one-line summary; async mode returned `{"status": "running", "task_id": "<id>"}` within 100ms of dispatch.
- [ ] Idempotency: a re-invocation with the same `(plan, topic)` reuses the existing output and does not re-dispatch librarian.
- [ ] `scripts/test-citation-discipline.sh` exit 0 with all 7 sub-tests passing (run after every change to this skill).

## omo Integration

Librarian agent is the execution body — this skill **does not modify librarian**; the dispatch prompt above is the entire contract surface. The `decisions.md` audit entry is consumed by OMO `atlas` for progress tracking and by the `compaction-context-injector` hook to surface recent research in surviving context. Async dispatch returns a `task_id`; the caller polls it via `/research status <task_id>` or by checking filesystem existence of `docs/research/<plan-slug>/<topic>.md`.
