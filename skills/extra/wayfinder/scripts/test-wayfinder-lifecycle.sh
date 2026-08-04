#!/usr/bin/env bash
# scripts/test-wayfinder-lifecycle.sh — failing-first contract test for wayfinder
# Probes: T1 init tree+schema / T2 invalid slug / T3 idempotent init /
#   T4 3 valid types accepted / T5 task type refused / T6 cycle refused /
#   T7 unresolved refused / T8 archive+plan / T9 close idempotent
# Exit 0 on all-pass; 1 on any-fail.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PASS=0; FAIL=0
PROBE(){ if [[ "$2" == "$3" ]]; then echo "PASS $1"; PASS=$((PASS+1)); else echo "FAIL $1 expected=$2 got=$3 :: $4"; FAIL=$((FAIL+1)); fi; }

# Helper: write a YAML-frontmatter ticket into TMP/.omo/wayfinder/<slug>/tickets/NN.md
wt(){ local i="$1" type="$2" status="$3" blocked="$4" resolved="$5"
  cat > "${TMP}/.omo/wayfinder/${slug}/tickets/${i}.md" <<EOF
---
id: "${i}"
type: ${type}
status: ${status}
ts_created: 2026-07-29T00:00:00Z
ts_resolved: ${resolved}
blockedBy: ${blocked}
title: t${i}
---
EOF
}

# T2 — invalid slug refused (no TMP needed)
set +e; bash "${ROOT}/scripts/wayfinder-init.sh" 'Bad_Slug!' >/dev/null 2>&1; RC=$?; set -e
PROBE T2 1 "${RC}" "init accepted invalid slug"

# T1/T3 — init creates tree + valid map.json; idempotent on re-run
TMP="$(mktemp -d)"; slug=qa-wayfinder
bash "${ROOT}/scripts/wayfinder-init.sh" "${slug}" --root "${TMP}" >/dev/null
[[ -d "${TMP}/.omo/wayfinder/${slug}/tickets" && -d "${TMP}/.omo/wayfinder/${slug}/sessions" ]] && PASS=$((PASS+1)) && echo "PASS T1a dirs" || { FAIL=$((FAIL+1)); echo "FAIL T1a dirs"; }
python3 -c "import json; m=json.load(open('${TMP}/.omo/wayfinder/${slug}/map.json')); assert m['slug']=='${slug}' and m['status']=='open' and m['blocking_cycles'] is False and isinstance(m['tickets'],list) and m['ticket_count']['total']==0" 2>/dev/null && PASS=$((PASS+1)) && echo "PASS T1b schema" || { FAIL=$((FAIL+1)); echo "FAIL T1b schema"; }
set +e; bash "${ROOT}/scripts/wayfinder-init.sh" "${slug}" --root "${TMP}" >/dev/null 2>&1; RC=$?; set -e
PROBE T3 0 "${RC}" "second init failed"

# T4 — exactly 3 valid ticket types (prototype/research/decision) accepted
wt 01 prototype resolved '[]' '2026-07-29T00:01:00Z'
wt 02 research resolved '[]' '2026-07-29T00:02:00Z'
wt 03 decision resolved '[]' '2026-07-29T00:03:00Z'
set +e; bash "${ROOT}/scripts/wayfinder-close.sh" "${slug}" --root "${TMP}" >/dev/null 2>&1; RC=$?; set -e
PROBE T4 0 "${RC}" "close refused valid types"

# After T4 close, archive exists. Restore fresh TMP for T5..T8.
rm -rf "${TMP}"; TMP="$(mktemp -d)"; bash "${ROOT}/scripts/wayfinder-init.sh" "${slug}" --root "${TMP}" >/dev/null

# T5 — `task` type refused (must be one of prototype/research/decision)
wt 01 decision resolved '[]' '2026-07-29T00:01:00Z'
wt 02 decision resolved '[]' '2026-07-29T00:02:00Z'
cat > "${TMP}/.omo/wayfinder/${slug}/tickets/03.md" <<'EOF'
---
id: "03"
type: task
status: resolved
ts_created: 2026-07-29T00:00:00Z
ts_resolved: 2026-07-29T00:03:00Z
blockedBy: []
title: bad
---
EOF
set +e; bash "${ROOT}/scripts/wayfinder-close.sh" "${slug}" --root "${TMP}" >/dev/null 2>&1; RC=$?; set -e
PROBE T5 'non-zero' "$([[ ${RC} -ne 0 ]] && echo non-zero || echo zero)" "task type accepted"

# T6 — cycle (01 blocks 02, 02 blocks 01) refused
wt 01 decision resolved '["02"]' '2026-07-29T00:01:00Z'
wt 02 decision resolved '["01"]' '2026-07-29T00:02:00Z'
wt 03 decision resolved '[]' '2026-07-29T00:03:00Z'
set +e; bash "${ROOT}/scripts/wayfinder-close.sh" "${slug}" --root "${TMP}" >/dev/null 2>&1; RC=$?; set -e
PROBE T6 'non-zero' "$([[ ${RC} -ne 0 ]] && echo non-zero || echo zero)" "cycle accepted"

# T7 — unresolved ticket refused (cycle not present here, but unresolved is)
wt 01 decision resolved '[]' '2026-07-29T00:01:00Z'
wt 02 decision pending   '[]' 'null'
wt 03 decision resolved '[]' '2026-07-29T00:03:00Z'
set +e; bash "${ROOT}/scripts/wayfinder-close.sh" "${slug}" --root "${TMP}" >/dev/null 2>&1; RC=$?; set -e
PROBE T7 'non-zero' "$([[ ${RC} -ne 0 ]] && echo non-zero || echo zero)" "unresolved accepted"

# T8 — happy path: all resolved, DAG acyclic -> archive + plan file
wt 01 decision resolved '[]' '2026-07-29T00:01:00Z'
wt 02 decision resolved '[]' '2026-07-29T00:02:00Z'
wt 03 decision resolved '[]' '2026-07-29T00:03:00Z'
set +e; bash "${ROOT}/scripts/wayfinder-close.sh" "${slug}" --root "${TMP}" >/dev/null 2>&1; RC=$?; set -e
PROBE T8a 0 "${RC}" "happy close failed"
[[ -d "${TMP}/.omo/wayfinder-archive/${slug}" ]] && PASS=$((PASS+1)) && echo "PASS T8b archive" || { FAIL=$((FAIL+1)); echo "FAIL T8b archive"; }
[[ -f "${TMP}/.omo/plans/${slug}.md" ]] && PASS=$((PASS+1)) && echo "PASS T8c plan" || { FAIL=$((FAIL+1)); echo "FAIL T8c plan"; }

# T9 — second close is idempotent
set +e; bash "${ROOT}/scripts/wayfinder-close.sh" "${slug}" --root "${TMP}" >/dev/null 2>&1; RC=$?; set -e
PROBE T9 0 "${RC}" "second close failed"

rm -rf "${TMP}"
echo "---"; echo "PASS=${PASS} FAIL=${FAIL}"; [[ ${FAIL} -eq 0 ]]