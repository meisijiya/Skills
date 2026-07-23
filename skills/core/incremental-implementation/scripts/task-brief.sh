#!/usr/bin/env bash
# task-brief.sh — Extract a single task's structured metadata into an
# executor-readable brief file. Part of meisijiya-skills' SDD (Subagent-Driven
# Development) layer, adapted from Superpowers subagent-driven-development's
# `scripts/task-brief`.
#
# Why this exists:
#   - OMO `task_create` stores tasks as JSON in
#     `$OPENCODE_CONFIG_DIR/tasks/<list-id>/T-<uuid>.json`.
#   - Executor (sisyphus-junior / hephaestus) is dispatched in a fresh
#     context — it MUST NOT inherit the orchestrator's session history.
#   - The brief is the executor's single source of requirements. It
#     contains: Global Constraints, Interfaces (Consumes / Produces),
#     bite-sized steps with exact code, and the 4-status contract.
#
# Usage:
#   task-brief.sh <task-id>
#   task-brief.sh <task-id> --output <path>
#
# Output: stdout prints the path of the brief file (one line, no trailing
# whitespace). The orchestrator (Atlas / Sisyphus) embeds this path in
# the dispatch prompt so the executor does a single Read of its brief.
#
# Required env / files:
#   - .omo/plans/<slug>.md        plan file (Phase 3 Prometheus task rows)
#   - $OMO_TASKS_DIR/<task-id>.json  OMO task object with `metadata` field
#
# Exit codes:
#   0 = brief written, path printed
#   1 = usage / args error
#   2 = task not found in OMO tasks dir
#   3 = plan file not found
#   4 = task metadata missing required SDD fields (warns but still writes)

set -euo pipefail

PROG="$(basename "$0")"
usage() {
  cat <<USAGE
Usage: $PROG <task-id> [--output <path>] [--plan <slug>] [--tasks-dir <dir>]

Extracts one OMO task's SDD metadata (globalConstraints / interfaces /
biteSizedSteps / statusContract) into a brief file an executor can
read in a single Read.

Options:
  --output <path>    Override the brief output path (default:
                     .omo/sdd/<plan-slug>/task-<id>-brief.md)
  --plan <slug>      Plan slug to scope under .omo/sdd/ (default: derive
                     from the most recent .omo/plans/*.md or the .active_plan
                     pointer)
  --tasks-dir <dir>  Override the OMO tasks directory
                     (default: \$OMO_TASKS_DIR or
                     \$OPENCODE_CONFIG_DIR/tasks/<list-id>)

Exit codes: 0 ok, 1 usage, 2 task not found, 3 plan not found, 4 metadata incomplete
USAGE
}

# ---------- arg parse ----------
TASK_ID=""
OUT_PATH=""
PLAN_SLUG=""
TASKS_DIR_OVERRIDE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --output) OUT_PATH="$2"; shift 2 ;;
    --plan)   PLAN_SLUG="$2"; shift 2 ;;
    --tasks-dir) TASKS_DIR_OVERRIDE="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    -*) echo "$PROG: unknown flag $1" >&2; usage; exit 1 ;;
    *)
      if [[ -z "$TASK_ID" ]]; then TASK_ID="$1"; shift
      else echo "$PROG: unexpected positional arg $1" >&2; usage; exit 1
      fi
      ;;
  esac
done

if [[ -z "$TASK_ID" ]]; then
  echo "$PROG: missing task-id" >&2
  usage; exit 1
fi

# ---------- locate OMO task ----------
# Precedence: --tasks-dir flag > $OMO_TASKS_DIR env > $OPENCODE_CONFIG_DIR fallback.
# Note: $TASKS_DIR is NOT consulted; the env name is OMO_TASKS_DIR, the flag is --tasks-dir.
if [[ -n "$TASKS_DIR_OVERRIDE" ]]; then
  TASKS_DIR="$TASKS_DIR_OVERRIDE"
elif [[ -n "${OMO_TASKS_DIR:-}" ]]; then
  TASKS_DIR="$OMO_TASKS_DIR"
else
  CONFIG_DIR="${OPENCODE_CONFIG_DIR:-$HOME/.config/opencode}"
  LIST_ID="${ULTRAWORK_TASK_LIST_ID:-${CLAUDE_CODE_TASK_LIST_ID:-$(basename "$PWD")}}"
  LIST_ID_SAFE="$(printf '%s' "$LIST_ID" | tr -c '[:alnum:]._-' '-')"
  TASKS_DIR="$CONFIG_DIR/tasks/$LIST_ID_SAFE"
fi

TASK_JSON="$TASKS_DIR/${TASK_ID}.json"
if [[ ! -f "$TASK_JSON" ]]; then
  echo "$PROG: task file not found: $TASK_JSON" >&2
  exit 2
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "$PROG: jq is required to parse OMO task JSON" >&2
  exit 1
fi

# ---------- locate plan file ----------
if [[ -z "$PLAN_SLUG" ]]; then
  if [[ -f .omo/plans/.active_plan ]]; then
    PLAN_SLUG="$(cat .omo/plans/.active_plan | tr -d '[:space:]')"
  elif [[ -f .active_plan ]]; then
    PLAN_SLUG="$(cat .active_plan | tr -d '[:space:]')"
  else
    # Pick the most recently modified plan
    PLAN_FILE="$(ls -1t .omo/plans/*.md 2>/dev/null | head -1 || true)"
    if [[ -z "$PLAN_FILE" ]]; then
      echo "$PROG: no plan file in .omo/plans/ and no --plan given" >&2
      exit 3
    fi
    PLAN_SLUG="$(basename "$PLAN_FILE" .md)"
  fi
fi

PLAN_FILE=".omo/plans/${PLAN_SLUG}.md"
if [[ ! -f "$PLAN_FILE" ]]; then
  echo "$PROG: plan file not found: $PLAN_FILE" >&2
  exit 3
fi

# ---------- derive default output path ----------
if [[ -z "$OUT_PATH" ]]; then
  OUT_PATH=".omo/sdd/${PLAN_SLUG}/task-${TASK_ID}-brief.md"
fi

mkdir -p "$(dirname "$OUT_PATH")"

# ---------- extract task fields ----------
SUBJECT="$(jq -r '.subject // "(no subject)"' "$TASK_JSON")"
DESCRIPTION="$(jq -r '.description // ""' "$TASK_JSON")"
GLOBAL_CONSTRAINTS="$(jq -r '.metadata.globalConstraints // [] | if type=="array" then .[] else . end' "$TASK_JSON" | sed 's/^/- /')"
INTERFACES_CONSUMES="$(jq -r '.metadata.interfaces.consumes // [] | .[] | "- **\(.symbol)** — `\(.file)`"' "$TASK_JSON")"
INTERFACES_PRODUCES="$(jq -r '.metadata.interfaces.produces // [] | .[] | "- **\(.symbol)**\(if .signature then " — `\(.signature)`" else "" end)\(if .file then " — new export in `\(.file)`" else "" end)"' "$TASK_JSON")"
BITE_SIZED_STEPS="$(jq -r '.metadata.biteSizedSteps // [] | .[] |
  ("- [ ] **Step \(.step): \(.action)**"),
  (if .code then "\(.code)" else empty end),
  (if .verify then "**Verify:** \(.verify)" else empty end),
  (if .expected then "**Expected:** \(.expected)" else empty end),
  ""' "$TASK_JSON")"
STATUS_CONTRACT="$(jq -r '.metadata.statusContract // "DONE | DONE_WITH_CONCERNS | NEEDS_CONTEXT | BLOCKED"' "$TASK_JSON")"
NO_PLACEHOLDERS="$(jq -r '.metadata.noPlaceholders // true' "$TASK_JSON")"

# ---------- validate required fields ----------
MISSING=()
if [[ -z "$BITE_SIZED_STEPS" ]]; then MISSING+=("biteSizedSteps (executor needs step-by-step exact code)"); fi
if [[ "$NO_PLACEHOLDERS" != "true" ]]; then MISSING+=("metadata.noPlaceholders must be true"); fi

# ---------- write brief ----------
BRIEF_TMP="${OUT_PATH}.tmp.$$"
{
  echo "# Task Brief: ${TASK_ID} — ${SUBJECT}"
  echo
  echo "_Auto-generated by task-brief.sh — DO NOT EDIT. Edit the plan at ${PLAN_FILE} and re-run._"
  echo
  echo "**Plan:** \`${PLAN_FILE}\`"
  echo "**Task ID:** \`${TASK_ID}\`"
  echo "**Brief generated:** $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo
  echo "## Description"
  echo
  if [[ -n "$DESCRIPTION" ]]; then
    echo "$DESCRIPTION"
  else
    echo "_(no description provided in task_create)_"
  fi
  echo
  echo "## Global Constraints (verbatim from plan)"
  echo
  if [[ -n "$GLOBAL_CONSTRAINTS" ]]; then
    echo "$GLOBAL_CONSTRAINTS"
  else
    echo "_⚠️ WARNING: no globalConstraints in task metadata — executor is operating without plan-wide constraints_"
  fi
  echo
  echo "## Interfaces"
  echo
  echo "### Consumes (from earlier slices — already exists in repo)"
  echo
  if [[ -n "$INTERFACES_CONSUMES" ]]; then
    echo "$INTERFACES_CONSUMES"
  else
    echo "_(none — this slice does not depend on prior slice artifacts)_"
  fi
  echo
  echo "### Produces (for later slices — declare the contract)"
  echo
  if [[ -n "$INTERFACES_PRODUCES" ]]; then
    echo "$INTERFACES_PRODUCES"
  else
    echo "_(none — this slice does not export symbols for later slices)_"
  fi
  echo
  echo "## Bite-sized steps (TDD 5-step, exact code required)"
  echo
  if [[ -n "$BITE_SIZED_STEPS" ]]; then
    echo "$BITE_SIZED_STEPS"
  else
    echo "_⚠️ WARNING: no biteSizedSteps in task metadata — executor has no step-by-step guide_"
  fi
  echo
  echo "## Executor contract"
  echo
  echo "After completing the steps above, return EXACTLY ONE of these 4 statuses (no free text):"
  echo
  echo -e "$STATUS_CONTRACT"
  echo
  echo "Write a full report to \`${OUT_PATH%-brief.md}-report.md\` including:"
  echo "- RED command + expected failure + observed failure"
  echo "- GREEN command + observed pass"
  echo "- Commit SHA(s) (or 'no-commit' if project policy does not auto-commit)"
  echo "- Concerns (if DONE_WITH_CONCERNS): edge cases noticed, design doubts, code smells"
  echo "- Context needed (if NEEDS_CONTEXT): what was missing from this brief"
  echo "- Blocker (if BLOCKED): what blocked you, what you tried, your hypothesis"
  echo
  echo "## No placeholders (binding contract)"
  echo
  echo "Your brief does NOT contain (and you MUST NOT introduce):"
  echo "- \"TBD\" / \"TODO\" / \"implement later\" / \"fill in details\""
  echo "- \"Add appropriate error handling\" / \"add validation\" / \"handle edge cases\""
  echo "- \"Similar to Task N\" (code MUST be repeated verbatim in each step)"
  echo "- \"Write tests for the above\" without actual test code"
  echo "- References to types/functions not defined in this brief or the codebase"
  echo
  echo "If your brief is missing information needed to execute, return NEEDS_CONTEXT, do NOT invent."
} > "$BRIEF_TMP"
mv "$BRIEF_TMP" "$OUT_PATH"

# Print the path so the caller can embed it in dispatch prompt
printf '%s\n' "$OUT_PATH"

if [[ ${#MISSING[@]} -gt 0 ]]; then
  echo "$PROG: WARNING — task metadata missing required SDD fields:" >&2
  printf '  - %s\n' "${MISSING[@]}" >&2
  echo "$PROG: brief written anyway; fix the plan and re-run before dispatching executor" >&2
  exit 4
fi
