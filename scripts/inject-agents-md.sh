#!/usr/bin/env bash
# scripts/inject-agents-md.sh
#
# Append meisijiya-skills meta-info to the user's AGENTS.md.
# Opt-in, idempotent, non-destructive to omo routing.
#
# Why: omo loads AGENTS.md as agent context. Appending our skill catalog +
# conventions + omo-integration summary gives the agent persistent awareness
# of installed skills without forcing a hook into omo itself.
#
# Usage:
#   scripts/inject-agents-md.sh                       # inject to ~/.config/opencode/AGENTS.md (default)
#   scripts/inject-agents-md.sh --target PATH         # inject to specific AGENTS.md
#   scripts/inject-agents-md.sh --local               # inject to <pwd>/AGENTS.md (project-level)
#   scripts/inject-agents-md.sh --dry-run             # show what would be added, don't write
#   scripts/inject-agents-md.sh --remove              # remove previously injected block
#
# Behavior:
#   - Idempotent: re-running doesn't duplicate the block (uses sentinel markers)
#   - Non-destructive: only appends the meisijiya-skills block; preserves other content
#   - Opt-in: never auto-runs (no hook, no install.sh trigger)
#
# Multi-group catalog (2026-07+): marketplace.json's `plugins[]` array splits
# `skills/extra/` into multiple groups (security / cicd / observability / meta
# / domain). The Section A catalog header is auto-expanded per group. Source
# patterns in AGENTS.md use `** <group> (NN):**` and inject replaces `NN` with
# the live count parsed from .claude-plugin/marketplace.json.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
AGENTS_MD="$REPO_ROOT/AGENTS.md"

MARKER_BEGIN="<!-- meisijiya-skills:start -->"
MARKER_END="<!-- meisijiya-skills:end -->"

# Defaults
TARGET=""
LOCAL=false
DRY_RUN=false
REMOVE=false

# Known group suffixes — must match the suffixes used in AGENTS.md Section A
# catalog headers AND in marketplace.json plugin `name` values (`meisijiya-<suffix>`).
# Adding a new group = add here + add to marketplace.json + add a header in AGENTS.md.
GROUP_SUFFIXES=(core security cicd observability meta domain)

usage() {
  cat <<EOF
Usage: $0 [options]

Injects meisijiya-skills meta-info (skill catalog + omo integration summary
+ conventions) into your AGENTS.md. Idempotent (sentinel markers prevent
duplicates). Opt-in only — never auto-runs.

Options:
  --target PATH    inject into <PATH> (default: ~/.config/opencode/AGENTS.md)
  --local          inject into <pwd>/AGENTS.md (project-level)
  --dry-run        show what would be added, don't write
  --remove         remove previously injected block (instead of adding)
  -h, --help       show this help

Examples:
  $0                          # inject to user-level AGENTS.md
  $0 --target ~/notes/AGENTS.md
  $0 --local                  # inject to project AGENTS.md
  $0 --dry-run                # preview
  $0 --remove                 # remove the block
EOF
}

# Parse args
while [[ $# -gt 0 ]]; do
  case "$1" in
    --target) TARGET="$2"; shift 2 ;;
    --local) LOCAL=true; shift ;;
    --dry-run) DRY_RUN=true; shift ;;
    --remove) REMOVE=true; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage; exit 1 ;;
  esac
done

# Resolve target
if [[ -z "$TARGET" ]]; then
  if $LOCAL; then
    TARGET="$(pwd)/AGENTS.md"
  else
    TARGET="${HOME}/.config/opencode/AGENTS.md"
  fi
fi

if [[ ! -f "$AGENTS_MD" ]]; then
  echo "Error: AGENTS.md not found at $AGENTS_MD" >&2
  exit 1
fi

SNIPPET_CONTENT=$(awk -v begin="$MARKER_BEGIN" -v end="$MARKER_END" '
  $0 == begin { in_block = 1; next }
  $0 == end { in_block = 0; next }
  in_block { print }
' "$AGENTS_MD")

# Compute per-group skill counts by parsing .claude-plugin/marketplace.json.
#
# JSON is line-padded; this parser handles our specific manifest shape (plugin
# entries with `"name": "meisijiya-<suffix>"` then `./skills/...` paths).
# Pure awk — no jq dependency.
#
# Strategy: stream lines, track the current plugin entry, count paths in it,
# emit `<suffix> <count>` when the entry closes (closing `}`).
MARKETPLACE="$REPO_ROOT/.claude-plugin/marketplace.json"
if [[ ! -f "$MARKETPLACE" ]]; then
  echo "Error: $MARKETPLACE not found" >&2
  exit 1
fi

declare -A GROUP_COUNTS
for grp in "${GROUP_SUFFIXES[@]}"; do
  GROUP_COUNTS[$grp]="?"
done

current=""
count=0
while IFS= read -r line; do
  # Detect plugin entry name line — sets current suffix; emit any prior entry first.
  if [[ "$line" =~ \"name\"[[:space:]]*:[[:space:]]*\"meisijiya-([a-z-]+)\" ]]; then
    # Flush prior entry
    if [[ -n "$current" ]]; then
      GROUP_COUNTS[$current]="$count"
    fi
    current="${BASH_REMATCH[1]}"
    count=0
    continue
  fi
  # Glob match avoids bash regex escaping pitfalls with `=~` + `/`.
  if [[ -n "$current" && "$line" == *'"./skills/'* ]]; then
    count=$((count + 1))
    continue
  fi
  # Closing `}` of a plugin entry flushes its count
  if [[ -n "$current" && "$line" =~ ^[[:space:]]*\}[[:space:]]*,?[[:space:]]*$ ]]; then
    GROUP_COUNTS[$current]="$count"
    current=""
    count=0
    continue
  fi
done < "$MARKETPLACE"

# Flush the last entry (EOF without trailing `}`)
if [[ -n "$current" ]]; then
  GROUP_COUNTS[$current]="$count"
fi

# Two sed patterns: core keeps the `.core/` path visual cue; other groups use
# a uniform `<group> (N)` shape.
for grp in "${GROUP_SUFFIXES[@]}"; do
  resolved="${GROUP_COUNTS[$grp]}"
  if [[ "$grp" == "core" ]]; then
    SNIPPET_CONTENT=$(printf '%s\n' "$SNIPPET_CONTENT" | \
      sed -E "s/(\\*\\*\\.core\\/ — load always \\()([0-9]+|\\?)(\\)\\:\\*\\*)/\\1${resolved}\\3/")
  else
    sed_safe=$(printf '%s' "$grp" | sed 's/-/\\-/g')
    SNIPPET_CONTENT=$(printf '%s\n' "$SNIPPET_CONTENT" | \
      sed -E "s/(\\*\\*${sed_safe} \\()([0-9]+|\\?)(\\)\\:\\*\\*)/\\1${resolved}\\3/")
  fi
done

# Drop the pre-group `.extra/` line so it doesn't render a stale count.
SNIPPET_CONTENT=$(printf '%s\n' "$SNIPPET_CONTENT" | \
  sed -E "/^\\*\\*\\.extra\\/ — load on demand \\([0-9]+\\)\\:\\*\\*\$/d")

# Backward-compat: if AGENTS.md still has the old single `**\.extra\/` header,
# keep it functional — just rewrite to `meta (NN):**` so old source renders ok.
# This is a transitional shim; remove after one release.
if printf '%s' "$SNIPPET_CONTENT" | grep -qE '\*\*\\.extra\\\/'; then
  # Best-effort: don't change behavior, leave the legacy line alone.
  : # noop
fi

if [[ -z "$(printf '%s' "$SNIPPET_CONTENT" | tr -d '[:space:]')" ]]; then
  echo "Error: no content between $MARKER_BEGIN and $MARKER_END in $AGENTS_MD" >&2
  echo "  See Section A of AGENTS.md for the expected format" >&2
  exit 1
fi

SNIPPET_LINES=$(printf '%s\n' "$SNIPPET_CONTENT" | wc -l | tr -d ' ')

# Build the block with markers
build_block() {
  printf '%s\n%s\n%s\n' "$MARKER_BEGIN" "$SNIPPET_CONTENT" "$MARKER_END"
}

# Paired begin+end required — false-positive guard on files with stray marker substrings
has_block() {
  [[ -f "$1" ]] || return 1
  awk -v b="$MARKER_BEGIN" -v e="$MARKER_END" '
    $0 == b { seen_begin = 1; next }
    $0 == e { if (seen_begin) { found = 1; exit 0 } }
    END { if (!found) exit 1 }
  ' "$1"
}

# Remove existing block (between markers, inclusive)
remove_block() {
  if has_block "$1"; then
    if $DRY_RUN; then
      echo "DRY RUN: would remove meisijiya-skills block from $1"
      return
    fi
    # Use awk to extract everything outside the markers
    awk -v begin="$MARKER_BEGIN" -v end="$MARKER_END" '
      $0 == begin { in_block = 1; next }
      $0 == end { in_block = 0; next }
      !in_block { print }
    ' "$1" > "$1.tmp" && mv "$1.tmp" "$1"
    echo "Removed meisijiya-skills block from $1"
  else
    echo "No meisijiya-skills block found in $1"
  fi
}

# Main logic
if $REMOVE; then
  remove_block "$TARGET"
  exit 0
fi

if has_block "$TARGET"; then
  echo "Block already present in $TARGET (idempotent: no change)"
  echo "  Re-run with --remove first if you want to refresh"
  exit 0
fi

# Dry-run: show what would be added
if $DRY_RUN; then
  echo "DRY RUN: would append to $TARGET"
  echo "---"
  echo "  $MARKER_BEGIN"
  echo "  ($SNIPPET_LINES lines from $AGENTS_MD Section A)"
  echo "  $MARKER_END"
  exit 0
fi

# Ensure parent dir exists
TARGET_DIR="$(dirname "$TARGET")"
if [[ ! -d "$TARGET_DIR" ]]; then
  mkdir -p "$TARGET_DIR"
fi

# Append the block
{
  # If file exists, prepend a blank line separator (unless file is empty)
  if [[ -f "$TARGET" ]] && [[ -s "$TARGET" ]]; then
    printf '\n'
  fi
  build_block
} >> "$TARGET"

# Build human-readable count summary for the success message
counts_summary=""
for grp in "${GROUP_SUFFIXES[@]}"; do
  c="${GROUP_COUNTS[$grp]}"
  counts_summary+="${grp}=${c} "
done

echo "Injected meisijiya-skills block into $TARGET"
echo "  ($SNIPPET_LINES lines from $AGENTS_MD Section A; counts: $counts_summary)"
echo "  Idempotent: re-running is a no-op. Use --remove to delete."
