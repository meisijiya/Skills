#!/usr/bin/env bash
# test-task-brief.sh — Regression tests for task-brief.sh rendering bugs.
#
# Covers Oracle-audited cases (3 visual bugs + happy/error paths).
# Pattern: each invocation uses `(cd $WORK && OMO_TASKS_DIR=$WORK/tasks bash $SCRIPT ...)`.
# The script resolves `.omo/plans/<slug>.md` relative to cwd, so cd is required.

set -uo pipefail

TESTS_PASS=0
TESTS_FAIL=0
FAIL_NAMES=()

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SCRIPT="${SCRIPT_DIR}/task-brief.sh"

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

ok()   { TESTS_PASS=$((TESTS_PASS+1)); echo "  PASS  $1"; }
bad()  { TESTS_FAIL=$((TESTS_FAIL+1)); FAIL_NAMES+=("$1"); echo "  FAIL  $1  ($2)"; }

setup() {
  local plan_slug="$1"
  local task_id="$2"
  local task_json="$3"
  mkdir -p "$WORK/.omo/plans" "$WORK/tasks"
  cat > "$WORK/.omo/plans/${plan_slug}.md" <<EOF
# $plan_slug
EOF
  printf '%s' "$task_json" > "$WORK/tasks/${task_id}.json"
}

run_brief() {
  local plan_slug="$1"; shift
  local task_id="$1"; shift
  local out_path="$1"; shift
  rc=0
  brief_body=""
  err_body=""
  brief_body="$(
    cd "$WORK" && \
    OMO_TASKS_DIR="$WORK/tasks" bash "$SCRIPT" "$task_id" --plan "$plan_slug" --output "$out_path" \
      "$@" 2>/tmp/err.$$
  )" || rc=$?
  err_body="$(cat /tmp/err.$$)"; rm -f /tmp/err.$$
  if [[ -f "$out_path" ]]; then
    file_body="$(cat "$out_path")"
  else
    file_body=""
  fi
}

run_brief_no_out() {
  local plan_slug="$1"; shift
  local task_id="$1"; shift
  rc=0
  brief_body=""
  err_body=""
  brief_body="$(
    cd "$WORK" && \
    OMO_TASKS_DIR="$WORK/tasks" bash "$SCRIPT" "$task_id" --plan "$plan_slug" "$@" 2>/tmp/err.$$
  )" || rc=$?
  err_body="$(cat /tmp/err.$$)"; rm -f /tmp/err.$$
  file_body=""
}

echo "=== bug B: report path substitution ==="

setup demo T-bug-b '{"id":"T-bug-b","subject":"B path","metadata":{"biteSizedSteps":[{"step":1,"action":"x"}],"noPlaceholders":true}}'
run_brief demo T-bug-b "$WORK/bug-b.md"
if grep -qE '\.mdreport\.md' <<<"$file_body"; then
  bad "bug B: no .mdreport.md artifact in brief body" "found broken path" ""
else
  ok "bug B: no .mdreport.md artifact in brief body"
fi
if grep -q 'Write a full report to' <<<"$file_body" && \
   ! grep -qE '\.mdreport\.md' <<<"$file_body"; then
  ok "bug B: report-path line references a real path"
else
  bad "bug B: report-path line references a real path" "broken or missing" ""
fi

echo
echo "=== bug C: Produces bold markup ==="

setup demo T-bug-c '{"id":"T-bug-c","subject":"C","metadata":{"noPlaceholders":true,"biteSizedSteps":[{"step":1,"action":"x"}],"interfaces":{"produces":[{"symbol":"healthRoute","signature":"(req: Request, res: Response) => void","file":"server.js"}]}}}'
run_brief demo T-bug-c "$WORK/bug-c.md"
if grep -qE '\*\*[^*]{1,40}\*\*\*\*' <<<"$file_body"; then
  bad "bug C: no **** artifact" "double-star pattern present" ""
else
  ok "bug C: no **** artifact"
fi
if grep -qF '**healthRoute** — ' <<<"$file_body"; then
  ok "bug C: Produces rendered as **symbol** — (followed by code)"
else
  bad "bug C: Produces rendered as **symbol** — ..." "expected form not found" "$file_body"
fi

echo
echo "=== bug D: biteSizedSteps empty fields ==="

setup demo T-bug-d '{"id":"T-bug-d","subject":"D","metadata":{"noPlaceholders":true,"biteSizedSteps":[{"step":1,"action":"Write failing test","code":"import test from node:test;"},{"step":2,"action":"Run test, expect FAIL"},{"step":3,"action":"Write minimal implementation"},{"step":4,"action":"Run test, expect PASS"},{"step":5,"action":"Commit"}]}}'
run_brief demo T-bug-d "$WORK/bug-d.md"

STEP1_CODE_LINE="$(printf '%s\n' "$file_body" | grep -n '^import test' | head -1 | cut -d: -f1)"
STEP2_LINE="$(printf '%s\n' "$file_body" | grep -n 'Step 2:' | head -1 | cut -d: -f1)"
STEP3_LINE="$(printf '%s\n' "$file_body" | grep -n 'Step 3:' | head -1 | cut -d: -f1)"

if [[ -n "$STEP1_CODE_LINE" && -n "$STEP2_LINE" ]]; then
  BLANK_LINES=$((STEP2_LINE - STEP1_CODE_LINE - 1))
  if [[ "$BLANK_LINES" -le 2 ]]; then
    ok "bug D: ≤ 2 blank lines between Step 1 code and Step 2 (got $BLANK_LINES)"
  else
    bad "bug D: ≤ 2 blank lines between Step 1 code and Step 2" "got $BLANK_LINES" ""
  fi
else
  bad "bug D: step markers not found" "1=$STEP1_CODE_LINE 2=$STEP2_LINE" "$file_body"
fi

if [[ -n "$STEP2_LINE" && -n "$STEP3_LINE" ]]; then
  BLANK_LINES=$((STEP3_LINE - STEP2_LINE - 1))
  if [[ "$BLANK_LINES" -le 3 ]]; then
    ok "bug D: ≤ 3 blank lines between empty-step headers (got $BLANK_LINES)"
  else
    bad "bug D: ≤ 3 blank lines between empty-step headers" "got $BLANK_LINES" ""
  fi
fi

echo
echo "=== happy path preserved ==="

setup demo T-happy '{"id":"T-happy","subject":"happy","description":"happy path","metadata":{"globalConstraints":["Node 20+"],"interfaces":{"consumes":[{"symbol":"express","file":"package.json:1"}],"produces":[{"symbol":"x","signature":"() => void","file":"x.js"}]},"biteSizedSteps":[{"step":1,"action":"x","code":"c","verify":"v","expected":"e"}],"noPlaceholders":true}}'
run_brief demo T-happy "$WORK/happy.md"
if [[ $rc -eq 0 ]] && [[ -n "$file_body" ]] && \
   grep -qF "Node 20+" <<<"$file_body" && \
   grep -qF "**express**" <<<"$file_body" && \
   grep -qF "Verify:" <<<"$file_body" && \
   grep -qF "Expected:" <<<"$file_body"; then
  ok "happy path: complete brief with all sections (rc=$rc)"
else
  bad "happy path: complete brief with all sections" "rc=$rc" "$err_body"
fi

echo
echo "=== error path preserved ==="

run_brief_no_out demo T-missing
if [[ $rc -eq 2 ]] && grep -qF "task file not found" <<<"$err_body"; then
  ok "error: missing task file → exit 2"
else
  bad "error: missing task file → exit 2" "rc=$rc" "$err_body"
fi

cat > "$WORK/tasks/T-x.json" <<'EOF'
{"id":"T-x","subject":"x","metadata":{"biteSizedSteps":[{"step":1,"action":"x"}],"noPlaceholders":true}}
EOF
run_brief_no_out nonexistent T-x
if [[ $rc -eq 3 ]] && grep -qF "plan file not found" <<<"$err_body"; then
  ok "error: plan not found → exit 3"
else
  bad "error: plan not found → exit 3" "rc=$rc" "$err_body"
fi

cat > "$WORK/tasks/T-y.json" <<'EOF'
{"id":"T-y","subject":"y","metadata":{}}
EOF
run_brief demo T-y "$WORK/y.md"
if [[ $rc -eq 4 ]] && [[ -f "$WORK/y.md" ]] && grep -qF "WARNING" "$WORK/y.md"; then
  ok "error: missing metadata → exit 4 + brief with WARN"
else
  bad "error: missing metadata → exit 4 + brief with WARN" "rc=$rc file=$([ -f "$WORK/y.md" ] && echo Y || echo N)" "$err_body"
fi

echo
echo "────────────────────────────"
echo "PASS: $TESTS_PASS   FAIL: $TESTS_FAIL"
if [[ $TESTS_FAIL -gt 0 ]]; then
  echo "Failed cases:"
  for n in "${FAIL_NAMES[@]}"; do echo "  - $n"; done
  exit 1
fi
exit 0
