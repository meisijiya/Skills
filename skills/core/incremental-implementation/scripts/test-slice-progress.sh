#!/usr/bin/env bash
# test-slice-progress.sh — Regression tests for slice-progress.sh arg parser.
#
# Covers Oracle-audited cases (13 happy + 4 error) that exercise the
# pre-scan --plan flag + subcommand positional handling. Exits non-zero
# on first failure; prints a summary on full pass.
#
# Usage:
#   bash test-slice-progress.sh [/path/to/slice-progress.sh]
#
# Default SCRIPT path: ../slice-progress.sh (relative to this test file)

set -uo pipefail   # NOTE: not -e — we want to count failures ourselves

TESTS_PASS=0
TESTS_FAIL=0
FAIL_NAMES=()

SCRIPT="${1:-$(cd "$(dirname "$0")" && pwd)/slice-progress.sh}"

# Pick a scratch dir for ledger artifacts; clean up between cases
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

mkdir -p "$WORK/.omo/plans"
mkdir -p "$WORK/.omo/sdd/demo"
cat > "$WORK/.omo/plans/demo.md" <<'EOF'
# demo
EOF

git_init_in_work() {
  ( cd "$WORK" && git init -q -b main && git config user.email t@e && git config user.name t && git commit -q --allow-empty -m init )
}

# ─────────────── helpers ───────────────

# Run: $1 = expected exit, $2 = expected stdout substring (''=don't care),
# $3 = expected stderr substring (''=don't care), $4 = case name, $5 = args...
expect() {
  local exp_rc="$1"; shift
  local exp_out="$1"; shift
  local exp_err="$1"; shift
  local name="$1"; shift
  local args=("$@")
  local rc=0
  local out err
  # Note: arrays expanded with "${args[@]}" — empty array → no args to bash
  out="$(cd "$WORK" && bash "$SCRIPT" "${args[@]}" 2>/tmp/err.$$)" || rc=$?
  err="$(cat /tmp/err.$$)"; rm -f /tmp/err.$$
  local ok=1
  [[ $rc == "$exp_rc" ]] || { ok=0; }
  if [[ -n "$exp_out" ]] && ! grep -qF -- "$exp_out" <<<"$out"; then ok=0; fi
  if [[ -n "$exp_err" ]] && ! grep -qF -- "$exp_err" <<<"$err"; then ok=0; fi
  if [[ $ok -eq 1 ]]; then ok "$name"; else bad "$name" "rc=$rc want=$exp_rc out='$out' err='$err'" ""; fi
}

ok()   { TESTS_PASS=$((TESTS_PASS+1)); echo "  PASS  $1"; }
bad()  { TESTS_FAIL=$((TESTS_FAIL+1)); FAIL_NAMES+=("$1"); echo "  FAIL  $1  ($2)"; [[ -n "$3" ]] && echo "        $3"; }

# ─────────────── happy path ───────────────

echo
echo "=== happy path ==="

git_init_in_work

# 1. mark-complete docs-style (plan last, with --review-verdict)
expect 0 ".omo/sdd/demo/progress.md" "" \
  "case 1: mark-complete plan-at-end review-verdict" \
  mark-complete T-x dummyBASE dummyHEAD --review-verdict ok --plan demo

# ledger should have 1 DONE row with 7-char SHAs
ROW="$(tail -n 1 "$WORK/.omo/sdd/demo/progress.md" 2>/dev/null || echo NONE)"
case "$ROW" in
  *"| T-x | DONE |"*".."|*" | ok |"*) ok "case 1.5: ledger row shape" ;;
  *) bad "case 1.5: ledger row shape" "got: $ROW" "" ;;
esac

# 2. mark-blocked with quoted reason containing spaces
expect 0 ".omo/sdd/demo/progress.md" "" \
  "case 2: mark-blocked quoted-spaces reason" \
  mark-blocked T-x "spec missing with spaces" --plan demo

ROW="$(tail -n 1 "$WORK/.omo/sdd/demo/progress.md")"
case "$ROW" in
  *"spec missing with spaces"*) ok "case 2.5: ledger keeps spaces" ;;
  *) bad "case 2.5: ledger keeps spaces" "got: $ROW" "" ;;
esac

# 3. --plan at front (any-position semantics)
expect 0 ".omo/sdd/demo/progress.md" "" \
  "case 3: --plan at front" \
  --plan demo mark-complete T-ya dummyBASE dummyHEAD

# 4. mark-complete without --plan, relies on auto-detect
expect 0 ".omo/sdd/demo/progress.md" "" \
  "case 4: mark-complete no --plan (auto-detect)" \
  mark-complete T-ad dummyBASE dummyHEAD --review-verdict needs-fixes

# 5. --help alone
expect 0 "Usage:" "" \
  "case 5: --help exit 0 with usage" \
  --help

# 6. mark-complete --help short-circuits
expect 0 "Usage:" "" \
  "case 6: --help inside subcommand short-circuits" \
  mark-complete T-x dummyBASE dummyHEAD --help

# ─────────────── error path ───────────────

echo
echo "=== error path ==="

# 7. --plan with no value (last arg)
expect 1 "" "--plan" \
  "case 7: --plan with no value" \
  --plan

# 8. --plan with no value (mid-arg)
expect 1 "" "--plan" \
  "case 8: --plan with no value mid-args" \
  mark-complete T-x dummyBASE dummyHEAD --plan

# 9. zero args (call bash with no positional — expect() can't do this cleanly)
{
  rc=0
  out="$(cd "$WORK" && bash "$SCRIPT" 2>/tmp/err.$$)" || rc=$?
  err="$(cat /tmp/err.$$)"; rm -f /tmp/err.$$
  if [[ $rc == 1 ]] && grep -qF "missing subcommand" <<<"$err"; then
    ok "case 9: zero args"
  else
    bad "case 9: zero args" "rc=$rc out='$out' err='$err'" ""
  fi
}

# 10. unknown subcommand
expect 1 "" "unknown subcommand" \
  "case 10: unknown subcommand" \
  frobnicate --plan demo

# 11. shell metachars in reason must NOT expand
expect 0 ".omo/sdd/demo/progress.md" "" \
  "case 11: metachars in reason, no expansion" \
  mark-blocked T-x 'reason with $VAR and `backticks`' --plan demo

ROW="$(tail -n 1 "$WORK/.omo/sdd/demo/progress.md")"
if [[ "$ROW" == *'$VAR'* && "$ROW" == *'`backticks`'* ]]; then
  ok "case 11.5: ledger preserves literal metachars"
else
  bad "case 11.5: ledger preserves literal metachars" "got: $ROW" ""
fi

# 12. glob chars in reason must NOT expand
expect 0 ".omo/sdd/demo/progress.md" "" \
  "case 12: glob chars in reason, no expansion" \
  mark-blocked T-x 'reason with * and ?' --plan demo

# 13. stdout is exactly one line (omo contract)
rm -rf "$WORK/.omo/sdd/demo"
git_init_in_work   # fresh repo to avoid ledger noise
OUT="$(cd "$WORK" && bash "$SCRIPT" mark-complete T-solo dummyBASE dummyHEAD --review-verdict ok --plan demo 2>/dev/null)"
LINE_COUNT="$(printf '%s' "$OUT" | grep -c '')"
if [[ "$LINE_COUNT" == "1" ]]; then
  ok "case 13: stdout is exactly one line (omo contract)"
else
  bad "case 13: stdout is exactly one line (omo contract)" "got $LINE_COUNT lines: $OUT" ""
fi

# 14. mark-complete too few positional args
expect 1 "" "requires <task-id> <base-sha> <head-sha>" \
  "case 14: mark-complete only 2 positional" \
  mark-complete T-x dummyBASE --plan demo

# 15. mark-blocked only 1 positional
expect 1 "" "requires <task-id> <reason>" \
  "case 15: mark-blocked only 1 positional" \
  mark-blocked T-x --plan demo

# 16. plan not found
expect 2 "" "plan file not found" \
  "case 16: plan not found" \
  mark-complete T-x dummyBASE dummyHEAD --plan nonexistent-slug

# ─────────────── summary ───────────────

echo
echo "────────────────────────────"
echo "PASS: $TESTS_PASS   FAIL: $TESTS_FAIL"
if [[ $TESTS_FAIL -gt 0 ]]; then
  echo "Failed cases:"
  for n in "${FAIL_NAMES[@]}"; do echo "  - $n"; done
  exit 1
fi
exit 0
