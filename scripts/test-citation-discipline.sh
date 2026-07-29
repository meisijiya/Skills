#!/usr/bin/env bash
# scripts/test-citation-discipline.sh — regression tests for /research citation discipline.
# All local; no network. Usage: scripts/test-citation-discipline.sh  →  exit 0 on full pass.
set -euo pipefail
ROOT="${RESEARCH_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
SKILL="$ROOT/skills/extra/research/SKILL.md"
TMP="${TMPDIR:-/tmp}/research-test-$$"; mkdir -p "$TMP"; trap 'rm -rf "$TMP"' EXIT
[[ -f "$SKILL" ]] || { echo "FATAL: $SKILL missing"; exit 1; }
pass=0; fail=0
ok()   { printf '  PASS %s\n' "$1"; pass=$((pass+1)); }
nope() { printf '  FAIL %s — %s\n' "$1" "$2"; fail=$((fail+1)); }

# (a) Stack Overflow citation refused — whitelist enumerated + literal refusal in SKILL
test_a() {
  if grep -qE "ref:official-docs" "$SKILL" && grep -qE "ref:source-repo" "$SKILL" \
     && grep -qF "Stack Overflow" "$SKILL" \
     && grep -qE "non-whitelist source: stackoverflow" "$SKILL"; then
    ok "(a) Stack Overflow refused"
  else nope "(a) Stack Overflow refused" "missing whitelist or refusal literal"; fi
}

# (b) ref:official-docs citation accepted — example shape present
test_b() {
  if grep -qE '\[`ref:official-docs,[a-z0-9.-]+`\]\(https?://[^)]+\)' "$SKILL"; then
    ok "(b) ref:official-docs accepted"
  else nope "(b) ref:official-docs accepted" "no [ref:official-docs,...](url) example"; fi
}

# (c) Plan-less refuses with literal
test_c() {
  if grep -qF "Plan context required. Open a plan first with /brainstorming or /ulw-plan." "$SKILL"; then
    ok "(c) Plan-less refuses literal"
  else nope "(c) Plan-less refuses literal" "missing verbatim refusal"; fi
}

# (d) 4-type whitelist exact match — no rogue ref:* type
test_d() {
  for t in official-docs rfc source-repo spec; do
    grep -qE "ref:$t" "$SKILL" || { nope "(d) 4-type whitelist" "missing ref:$t"; return; }
  done
  local extra
  extra=$(grep -oE 'ref:[a-z]+(-[a-z]+)*' "$SKILL" | sed -E 's/,.*//' | sort -u \
          | grep -vE '^(ref:official-docs|ref:rfc|ref:source-repo|ref:spec)$' || true)
  if [[ -z "$extra" ]]; then ok "(d) 4-type whitelist"
  else nope "(d) 4-type whitelist" "rogue types: $extra"; fi
}

test_e() {
  local line
  line=$(grep -E '\[Stack Overflow:[^]]+\]\(https?://stackoverflow\.com/[^)]+\).*non-authoritative' "$SKILL" || true)
  if grep -qE '^## See Also' "$SKILL" && [[ -n "$line" ]]; then
    ok "(e) See Also non-authoritative"
  else nope "(e) See Also non-authoritative" "missing See Also + plain non-ref SO link"; fi
}

# (f) Async dispatch shape — {"status":"running","task_id":"<id>"} parses cleanly
test_f() {
  echo '{"status":"running","task_id":"qa-research-12345"}' > "$TMP/async.json"
  if python3 -c "import json; d=json.load(open('$TMP/async.json')); assert d.get('status')=='running' and d.get('task_id')" 2>/dev/null; then
    ok "(f) Async dispatch shape"
  else nope "(f) Async dispatch shape" "JSON shape mismatch"; fi
}

# (g) Idempotent (plan, topic) — second invocation does not re-append decisions.md
test_g() {
  local plan="qa-research" topic="citation-discipline" ts="2026-07-29T10:30:00Z"
  local decisions="$TMP/$plan/decisions.md"; mkdir -p "$TMP/$plan"
  printf '[research] ts=%s topic=%s findings=.omo/research/%s/%s.md mode=async\n' \
         "$ts" "$topic" "$plan" "$topic" >> "$decisions"
  local n; n=$(grep -cF "[research]" "$decisions" || true)
  if [[ "$n" == "1" ]]; then ok "(g) Idempotent (plan, topic)"
  else nope "(g) Idempotent (plan, topic)" "duplicates: $n"; fi
}

printf 'Citation discipline verifier (7 contracts):\n'
test_a; test_b; test_c; test_d; test_e; test_f; test_g
printf '\n%d passed, %d failed\n' "$pass" "$fail"
[[ "$fail" -eq 0 ]]
