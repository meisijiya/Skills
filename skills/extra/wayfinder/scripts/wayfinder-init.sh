#!/usr/bin/env bash
# scripts/wayfinder-init.sh
#
# Scaffold a new wayfinder session: create .omo/wayfinder/<slug>/{map.json,
# tickets/, sessions/} with a schema-valid empty map.json. Idempotent.
#
# Usage:
#   scripts/wayfinder-init.sh <slug> [--root DIR]
#
# Slug format (binding, matches brainstorming): ^[a-z0-9][a-z0-9-]{0,39}$
#
# Exit codes:
#   0  created or already initialized
#   1  invalid slug
#   2  mkdir / write failure
#
# Scope: writes only under <root>/.omo/wayfinder/<slug>/. Does NOT touch
# OMO / OpenCode sources, marketplace, AGENTS, README, package.json,
# lockfile, skills/, evals/, or any path outside the selected root.

set -euo pipefail

ROOT=".omo"
SLUG=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --root) ROOT="${2:?--root requires DIR}"; shift 2 ;;
    -h|--help)
      sed -n '2,16p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    -*)
      echo "wayfinder-init.sh: unknown flag: $1" >&2; exit 1 ;;
    *)
      SLUG="$1"; shift ;;
  esac
done

if [[ -z "${SLUG}" ]]; then
  echo "wayfinder-init.sh: missing <slug>" >&2; exit 1
fi

if ! [[ "${SLUG}" =~ ^[a-z0-9][a-z0-9-]{0,39}$ ]]; then
  echo "wayfinder-init.sh: invalid slug '${SLUG}' (must match ^[a-z0-9][a-z0-9-]{0,39}$)" >&2
  exit 1
fi

WF_DIR="${ROOT}/.omo/wayfinder/${SLUG}"
MAP="${WF_DIR}/map.json"

# Idempotent: if scaffold already exists, exit 0 without rewriting map.json.
if [[ -f "${MAP}" ]]; then
  echo "wayfinder-init.sh: already initialized at ${WF_DIR}"
  exit 0
fi

mkdir -p "${WF_DIR}/tickets" "${WF_DIR}/sessions" \
  || { echo "wayfinder-init.sh: mkdir failed: ${WF_DIR}" >&2; exit 2; }

TS="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
TMP="${MAP}.tmp.$$"
cat > "${TMP}" <<EOF
{
  "slug": "${SLUG}",
  "goal": "",
  "ts_opened": "${TS}",
  "ts_closed": null,
  "status": "open",
  "tickets": [],
  "ticket_count": {
    "total": 0,
    "by_status": {"resolved": 0, "in_progress": 0, "pending": 0, "blocked": 0, "skipped": 0}
  },
  "blocking_cycles": false,
  "destination": ".omo/plans/${SLUG}.md"
}
EOF

# Atomic write: rename into place; integrity-check after.
mv "${TMP}" "${MAP}" || { echo "wayfinder-init.sh: write failed: ${MAP}" >&2; rm -f "${TMP}"; exit 2; }

# Post-write validation: map.json must be parseable JSON with required keys.
if ! python3 -c "
import json, sys
m = json.load(open('${MAP}'))
required = ['slug','goal','ts_opened','ts_closed','status','tickets','ticket_count','blocking_cycles','destination']
missing = [k for k in required if k not in m]
assert not missing, f'missing keys: {missing}'
assert m['slug'] == '${SLUG}', f\"slug mismatch: {m['slug']!r} != '${SLUG}'\"
assert m['status'] in ('open','closed'), f'bad status: {m[\"status\"]}'
assert m['blocking_cycles'] is False
assert isinstance(m['tickets'], list)
" >/dev/null 2>&1; then
  echo "wayfinder-init.sh: post-write validation failed: ${MAP}" >&2
  rm -rf "${WF_DIR}"
  exit 2
fi

echo "wayfinder-init.sh: initialized ${WF_DIR}"