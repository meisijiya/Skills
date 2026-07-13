#!/usr/bin/env bash
# scripts/install-hooks.sh
#
# Install git hooks from scripts/hooks/ to .git/hooks/.
# Idempotent: re-running overwrites existing hooks.
#
# Usage:
#   scripts/install-hooks.sh
#
# The script copies all files in scripts/hooks/ to .git/hooks/ and
# chmods them +x. Files are not renamed (no .sample suffix convention).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
HOOKS_SRC="$REPO_ROOT/scripts/hooks"
HOOKS_DST="$(git -C "$REPO_ROOT" rev-parse --git-dir)/hooks"

[[ -d "$HOOKS_SRC" ]] || { echo "FAIL: $HOOKS_SRC not found" >&2; exit 1; }
[[ -d "$HOOKS_DST" ]] || { echo "FAIL: $HOOKS_DST not found (not a git repo?)" >&2; exit 1; }

count=0
for src in "$HOOKS_SRC"/*; do
  [[ -f "$src" ]] || continue
  name="$(basename "$src")"
  dst="$HOOKS_DST/$name"
  cp "$src" "$dst"
  chmod +x "$dst"
  echo "Installed: $dst"
  count=$((count + 1))
done

[[ $count -gt 0 ]] || { echo "No hooks to install (scripts/hooks/ is empty)" >&2; exit 1; }

echo
echo "Installed $count hook(s)."
echo "Bypass with: git commit --no-verify"
