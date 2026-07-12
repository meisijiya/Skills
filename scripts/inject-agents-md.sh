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

echo "Injected meisijiya-skills block into $TARGET"
echo "  ($SNIPPET_LINES lines from $AGENTS_MD Section A)"
echo "  Idempotent: re-running is a no-op. Use --remove to delete."