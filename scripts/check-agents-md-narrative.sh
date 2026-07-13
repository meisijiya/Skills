#!/usr/bin/env bash
# scripts/check-agents-md-narrative.sh
#
# Verify AGENTS.md inject block contains no version narrative / historical
# comparisons. AGENTS.md is read by the agent at startup, so history language
# ("v0.4.0 added X", "was 16 now 19") pollutes the agent's runtime context
# with stale info.
#
# Run pre-commit (via scripts/hooks/pre-commit) or manually:
#   scripts/check-agents-md-narrative.sh                    # repo + user-level AGENTS.md
#   scripts/check-agents-md-narrative.sh path/to/AGENTS.md  # specific file(s)
#
# Exit 0 = clean, 1 = dirty.
# See docs/agents-md-guide.md for the rationale.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

MARKER_BEGIN="<!-- meisijiya-skills:start -->"
MARKER_END="<!-- meisijiya-skills:end -->"

# Patterns to grep for (extended regex, one per line)
PATTERNS=(
  'v[0-9]+\.[0-9]+\.[0-9]+'
  '\bwas\b'
  '\bnow has\b'
  '\bnewly added\b'
  '\bnew in v[0-9]'
  '\bsince v[0-9]'
)
PATTERN_RE="$(IFS='|'; printf '%s' "${PATTERNS[*]}")"

# Collect files: args or default (repo AGENTS.md + user-level)
FILES=()
if [[ $# -gt 0 ]]; then
  for f in "$@"; do
    [[ -f "$f" ]] || { echo "FAIL: file not found: $f" >&2; exit 1; }
    FILES+=("$f")
  done
else
  [[ -f "$REPO_ROOT/AGENTS.md" ]] && FILES+=("$REPO_ROOT/AGENTS.md")
  [[ -f "$HOME/.config/opencode/AGENTS.md" ]] && FILES+=("$HOME/.config/opencode/AGENTS.md")
fi

[[ ${#FILES[@]} -gt 0 ]] || { echo "FAIL: no AGENTS.md files to check" >&2; exit 1; }

dirty=0
for f in "${FILES[@]}"; do
  # Extract block between markers (only if both present)
  block=$(awk -v b="$MARKER_BEGIN" -v e="$MARKER_END" '
    $0 == b { in_block = 1; next }
    $0 == e { in_block = 0 }
    in_block { print }
  ' "$f" 2>/dev/null || true)

  if [[ -z "$(printf '%s' "$block" | tr -d '[:space:]')" ]]; then
    # No inject block — nothing to check (fine for project-level files)
    echo "OK: $f (no inject block, skipping)"
    continue
  fi

  # Grep for narrative patterns (|| true suppresses exit-1-on-no-match)
  matches=$(printf '%s\n' "$block" | grep -nE "$PATTERN_RE" 2>/dev/null || true)
  if [[ -n "$matches" ]]; then
    echo "FAIL: $f contains version narrative in inject block:"
    printf '%s\n' "$matches" | sed 's/^/  /'
    dirty=1
  else
    echo "OK: $f (inject block clean)"
  fi
done

if [[ $dirty -ne 0 ]]; then
  echo
  echo "See docs/agents-md-guide.md for why this matters."
  exit 1
fi

echo
echo "All AGENTS.md inject blocks clean."
exit 0
