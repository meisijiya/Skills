#!/usr/bin/env bash
# scripts/wayfinder-close.sh
#
# Close a wayfinder session: validate tickets, generate .omo/plans/<slug>.md
# Phase 0 from ticket resolutions, move scaffold to .omo/wayfinder-archive/,
# append [wayfinder] entry to .omo/notepads/<slug>/decisions.md.
#
# Usage:
#   scripts/wayfinder-close.sh <slug> [--root DIR]
#
# Required: all tickets must have status in {resolved, skipped}; DAG must
# be acyclic (no cycles in blockedBy edges); ticket types must be in
# {prototype, research, decision}.
#
# Exit codes:
#   0  closed (or already closed — idempotent)
#   1  not initialized / no tickets / unresolved ticket / bad type / cycle
#   2  filesystem write failure
#
# Scope: writes only under <root>/.omo/{wayfinder,wayfinder-archive,plans,
# notepads}/. Does NOT touch OMO / OpenCode sources, marketplace, AGENTS,
# README, package.json, lockfile, skills/, evals/, or any path outside the
# selected root.

set -euo pipefail

ROOT=".omo"
SLUG=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --root) ROOT="${2:?--root requires DIR}"; shift 2 ;;
    -h|--help)
      sed -n '2,20p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    -*)
      echo "wayfinder-close.sh: unknown flag: $1" >&2; exit 1 ;;
    *)
      SLUG="$1"; shift ;;
  esac
done

if [[ -z "${SLUG}" ]]; then
  echo "wayfinder-close.sh: missing <slug>" >&2; exit 1
fi

if ! [[ "${SLUG}" =~ ^[a-z0-9][a-z0-9-]{0,39}$ ]]; then
  echo "wayfinder-close.sh: invalid slug '${SLUG}'" >&2; exit 1
fi

WF_DIR="${ROOT}/.omo/wayfinder/${SLUG}"
ARCHIVE_DIR="${ROOT}/.omo/wayfinder-archive/${SLUG}"
MAP="${WF_DIR}/map.json"

# Idempotent: if already archived, exit 0.
if [[ -d "${ARCHIVE_DIR}" ]]; then
  echo "wayfinder-close.sh: already closed (archive at ${ARCHIVE_DIR})"
  exit 0
fi

if [[ ! -d "${WF_DIR}" || ! -f "${MAP}" ]]; then
  echo "wayfinder-close.sh: not initialized at ${WF_DIR}" >&2
  exit 1
fi

# Validate tickets + compute plan + check DAG + check types — single Python pass.
PLAN_OUT="$(mktemp)"
RESULT="$(python3 - "${WF_DIR}" "${MAP}" "${PLAN_OUT}" <<'PYEOF'
import json, os, re, sys
from pathlib import Path
from collections import defaultdict

wf_dir, map_path, plan_out = sys.argv[1], sys.argv[2], sys.argv[3]
wf = Path(wf_dir)
tickets_dir = wf / "tickets"

def err(msg, code=1):
    print(msg, file=sys.stderr)
    sys.exit(code)

def parse_frontmatter(text):
    if not text.startswith("---"):
        return None
    end = text.find("\n---", 3)
    if end < 0:
        return None
    fm = {}
    body = text[end + 4:]
    for line in text[3:end].splitlines():
        line = line.rstrip()
        if not line or ":" not in line:
            continue
        k, _, v = line.partition(":")
        fm[k.strip()] = v.strip().strip('"').strip("'")
    return fm, body

# Load map.json
with open(map_path) as f:
    try:
        m = json.load(f)
    except json.JSONDecodeError as e:
        err(f"wayfinder-close.sh: map.json invalid JSON: {e}")

if m.get("status") == "closed":
    # Already closed at the data level (idempotent — handled by bash but be safe)
    sys.exit(0)

VALID_TYPES = {"prototype", "research", "decision"}
VALID_STATUSES = {"pending", "blocked", "in_progress", "resolved", "skipped"}
ALLOWED_CLOSE_STATUSES = {"resolved", "skipped"}

tickets = []
tickets_index = {}  # id -> dict for cycle detection
for path in sorted(tickets_dir.glob("*.md")):
    text = path.read_text(encoding="utf-8")
    parsed = parse_frontmatter(text)
    if parsed is None:
        err(f"wayfinder-close.sh: ticket '{path.name}' missing YAML frontmatter")
    fm, body = parsed
    tid = fm.get("id") or path.stem
    ttype = fm.get("type", "")
    tstatus = fm.get("status", "")
    if ttype not in VALID_TYPES:
        err(f"wayfinder-close.sh: ticket '{tid}' has invalid type '{ttype}' (must be one of {sorted(VALID_TYPES)})")
    if tstatus not in VALID_STATUSES:
        err(f"wayfinder-close.sh: ticket '{tid}' has invalid status '{tstatus}'")
    if tstatus not in ALLOWED_CLOSE_STATUSES:
        err(f"wayfinder-close.sh: ticket '{tid}' status='{tstatus}' (must be resolved or skipped)")
    blocked_raw = fm.get("blockedBy", "[]").strip()
    try:
        blocked = json.loads(blocked_raw) if blocked_raw.startswith("[") else []
    except json.JSONDecodeError:
        # tolerate bare CSV
        blocked = [b.strip().strip('"').strip("'") for b in blocked_raw.strip("[]").split(",") if b.strip()]
    tickets.append({
        "id": tid,
        "type": ttype,
        "status": tstatus,
        "blockedBy": blocked,
        "title": fm.get("title", ""),
        "path": f"tickets/{path.name}",
        "body": body,
    })
    tickets_index[tid] = tickets[-1]

# DAG cycle detection (DFS with color: 0=white, 1=gray, 2=black)
color = defaultdict(int)
def has_cycle(node):
    color[node] = 1
    for dep in tickets_index.get(node, {}).get("blockedBy", []):
        if dep not in tickets_index:
            err(f"wayfinder-close.sh: ticket '{node}' blockedBy unknown ticket '{dep}'")
        if color[dep] == 1:
            return True
        if color[dep] == 0 and has_cycle(dep):
            return True
    color[node] = 2
    return False

cycle_found = False
for tid in tickets_index:
    if color[tid] == 0 and has_cycle(tid):
        cycle_found = True
        break

if cycle_found:
    err("wayfinder-close.sh: ticket dependency graph has a cycle (blocking_cycles=true)")

# Update map.json with resolved state + per-status counts.
by_status = defaultdict(int)
for t in tickets:
    by_status[t["status"]] += 1
m["tickets"] = [{
    "id": t["id"], "type": t["type"], "status": t["status"],
    "path": t["path"], "blockedBy": t["blockedBy"],
} for t in tickets]
m["ticket_count"] = {
    "total": len(tickets),
    "by_status": {
        "resolved": by_status.get("resolved", 0),
        "in_progress": by_status.get("in_progress", 0),
        "pending": by_status.get("pending", 0),
        "blocked": by_status.get("blocked", 0),
        "skipped": by_status.get("skipped", 0),
    },
}
m["blocking_cycles"] = False
m["status"] = "closed"
from datetime import datetime, timezone
m["ts_closed"] = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")

# Write back updated map.json (atomic — bash will rename).
tmp_map = map_path + ".py.tmp"
with open(tmp_map, "w") as f:
    json.dump(m, f, indent=2)
    f.write("\n")
os.replace(tmp_map, map_path)

# Generate plan.md Phase 0
def extract_resolution(body):
    m = re.search(r"##\s*Resolution\s*\n(.*?)(?:\n##\s|\Z)", body, re.DOTALL)
    return m.group(1).strip() if m else ""

def extract_description(body):
    m = re.search(r"##\s*Description\s*\n(.*?)(?:\n##\s|\Z)", body, re.DOTALL)
    return m.group(1).strip() if m else ""

goal = m.get("goal", "") or "(no goal recorded)"
decision_resolutions = [extract_resolution(t["body"]) for t in tickets
                        if t["type"] == "decision" and t["status"] == "resolved"]
skipped = [t for t in tickets if t["status"] == "skipped"]
all_summaries = [f"- [{t['id']}/{t['type']}/{t['status']}] {t['title']}" for t in tickets]

plan_lines = [
    f"# {m['slug']} — Phase 0 (generated by wayfinder-close.sh)",
    "",
    f"**Slug:** `{m['slug']}`",
    f"**TS opened:** {m['ts_opened']}",
    f"**TS closed:** {m['ts_closed']}",
    f"**Ticket count:** {m['ticket_count']['total']}",
    "",
    "## Goal",
    "",
    goal,
    "",
    "## Approach",
    "",
]
if decision_resolutions:
    for i, r in enumerate(decision_resolutions, 1):
        plan_lines.append(f"### Decision {i}")
        plan_lines.append("")
        plan_lines.append(r or "(no resolution recorded)")
        plan_lines.append("")
else:
    plan_lines.append("(no resolved decision tickets)")
    plan_lines.append("")

plan_lines += ["## Architecture", "", "Ticket summary:"]
for line in all_summaries:
    plan_lines.append(line)
plan_lines += ["", "## Open Questions", ""]
if skipped:
    for t in skipped:
        plan_lines.append(f"- [{t['id']}] {t['title']} — skipped")
else:
    plan_lines.append("(no skipped tickets)")
plan_lines.append("")

with open(plan_out, "w") as f:
    f.write("\n".join(plan_lines))

print("OK")
PYEOF
)"

if [[ "${RESULT}" != "OK" ]]; then
  echo "${RESULT}" >&2
  exit 1
fi

# Move scaffold -> archive (atomic rename).
mkdir -p "${ROOT}/.omo/wayfinder-archive"
mv "${WF_DIR}" "${ARCHIVE_DIR}" \
  || { echo "wayfinder-close.sh: archive move failed" >&2; exit 2; }

# Write plan.md to <root>/.omo/plans/<slug>.md
PLAN_PATH="${ROOT}/.omo/plans/${SLUG}.md"
mkdir -p "${ROOT}/.omo/plans"
mv "${PLAN_OUT}" "${PLAN_PATH}" \
  || { echo "wayfinder-close.sh: plan write failed" >&2; exit 2; }

# Append [wayfinder] entry to notepad decisions.md (create if absent).
TS="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
DECISIONS="${ROOT}/.omo/notepads/${SLUG}/decisions.md"
mkdir -p "${ROOT}/.omo/notepads/${SLUG}"
if [[ ! -f "${DECISIONS}" ]]; then
  {
    echo "# Decisions — ${SLUG}"
    echo
  } > "${DECISIONS}"
fi
printf '[wayfinder] ts=%s close=1 plan_ref=.omo/plans/%s.md\n' "${TS}" "${SLUG}" >> "${DECISIONS}"

echo "wayfinder-close.sh: closed ${SLUG}"
echo "  plan: ${PLAN_PATH}"
echo "  archive: ${ARCHIVE_DIR}"