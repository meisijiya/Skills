#!/usr/bin/env bash
# scripts/inject-agents-md.sh
#
# DEPRECATED: Section A of AGENTS.md is now provided by the plugin runtime via
# <available_skills>. This script no longer injects content; it only removes a
# legacy injected block (opt-in, idempotent, non-destructive).
#
# Usage:
#   scripts/inject-agents-md.sh                          # deprecation notice, exit 0
#   scripts/inject-agents-md.sh --remove [--target PATH] # remove legacy block
#   scripts/inject-agents-md.sh --dry-run [--remove]     # print, don't write

set -euo pipefail

MARKER_BEGIN="<!-- meisijiya-skills:start -->"
MARKER_END="<!-- meisijiya-skills:end -->"

TARGET="${HOME}/.config/opencode/AGENTS.md"
DRY_RUN=false
REMOVE=false

usage() {
  cat <<EOF
Usage: $0 [options]

Section A is now provided by the plugin runtime (<available_skills>). This
script only removes the legacy injected block.

Options:
  --target PATH    operate on <PATH> (default: ~/.config/opencode/AGENTS.md)
  --dry-run        print what would be done, don't write
  --remove         remove the legacy injected block
  -h, --help       show this help
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target) TARGET="$2"; shift 2 ;;
    --dry-run) DRY_RUN=true; shift ;;
    --remove) REMOVE=true; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage; exit 1 ;;
  esac
done

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
      echo "DRY RUN: would remove the legacy injected block from $1"
      return
    fi
    awk -v begin="$MARKER_BEGIN" -v end="$MARKER_END" '
      $0 == begin { in_block = 1; next }
      $0 == end { in_block = 0; next }
      !in_block { print }
    ' "$1" > "$1.tmp" && mv "$1.tmp" "$1"
    echo "Removed the legacy injected block from $1"
  else
    echo "No legacy injected block found in $1"
  fi
}

if $REMOVE; then
  remove_block "$TARGET"
  exit 0
fi

if $DRY_RUN; then
  echo "DRY RUN: no injection would happen (Section A now comes from the plugin runtime)."
  echo "  Add --remove to preview block removal instead."
  exit 0
fi

echo "DEPRECATED: scripts/inject-agents-md.sh no longer injects AGENTS.md content."
echo "  Section A is now provided by the plugin runtime via <available_skills>."
echo "  No changes made. Use --remove to delete a legacy injected block."
exit 0
