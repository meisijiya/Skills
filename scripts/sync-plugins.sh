#!/usr/bin/env bash
# scripts/sync-plugins.sh
#
# Sync meisijiya OpenCode plugins from repo → user-level plugin dir.
#
# Why: per-session commit `cp .opencode/plugins/*.js ~/.config/opencode/plugins/`
# is the documented install path (see README "OpenCode Plugins" table). Three
# pain points it doesn't solve:
#   1. root-owned 老 plugin mtime 不可刷(Permission denied on `cp -p`)
#   2. no chown step → root-owned files persist across reinstalls
#   3. no dry-run → no preview before mutating user-level state
#
# This script adds: explicit chown + sudo fallback + dry-run preview.
#
# Usage:
#   scripts/sync-plugins.sh                  # sync all repo plugins → user-level
#   scripts/sync-plugins.sh --dry-run        # show what would be copied/chowned
#   scripts/sync-plugins.sh --force          # overwrite root-owned files via sudo
#   scripts/sync-plugins.sh --dest PATH      # sync to a non-default dest dir
#
# Behavior:
#   - Idempotent: re-running is safe (cp overwrites + chmod normalizes)
#   - Non-destructive to user edits: only `.js` from this repo are touched
#   - Resolves `REPO` from `git rev-parse --show-toplevel` if not set
#   - Defaults DEST to `$HOME/.config/opencode/plugins/`
#   - `chmod 644` on every synced file; `chown ubuntu:ubuntu` only when current
#     owner ≠ ubuntu (avoids touching files already owned correctly)
#   - With --force, falls back to `sudo chown` if direct chown fails

set -euo pipefail

# --- args ---
DRY_RUN=false
FORCE=false
DEST="${OPENCODE_PLUGINS_DIR:-$HOME/.config/opencode/plugins}"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=true; shift ;;
    --force)   FORCE=true; shift ;;
    --dest)    DEST="$2"; shift 2 ;;
    -h|--help)
      sed -n '2,30p' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *) echo "Unknown arg: $1" >&2; exit 2 ;;
  esac
done

# --- resolve REPO ---
if [[ -z "${REPO:-}" ]]; then
  if command -v git >/dev/null 2>&1; then
    REPO="$(git rev-parse --show-toplevel 2>/dev/null || true)"
  fi
fi
if [[ -z "${REPO}" || ! -d "$REPO/.opencode/plugins" ]]; then
  echo "error: cannot locate .opencode/plugins/ — set REPO or run from repo root" >&2
  exit 1
fi

SRC_DIR="$REPO/.opencode/plugins"
mkdir -p "$DEST"

echo "src: $SRC_DIR"
echo "dst: $DEST"
echo "dry-run: $DRY_RUN  force: $FORCE"
echo

synced=0
for src in "$SRC_DIR"/*.js; do
  [[ -f "$src" ]] || continue
  base="$(basename "$src")"
  dst="$DEST/$base"

  echo "→ $base"
  if $DRY_RUN; then
    echo "  cp $src $dst"
    echo "  chmod 644 $dst"
    [[ "$(stat -c %U "$dst" 2>/dev/null || echo unknown)" != "ubuntu" ]] && \
      echo "  chown ubuntu:ubuntu $dst  (current owner differs)"
    continue
  fi

  # chown before cp: root-owned dst would otherwise make cp fail under set -e
  # before the sudo chown fallback (--force) could run. Preserve this order.
  current_owner="$(stat -c %U "$dst" 2>/dev/null || echo unknown)"
  if [[ "$current_owner" != "ubuntu" ]]; then
    if chown ubuntu:ubuntu "$dst" 2>/dev/null; then
      echo "  chown ubuntu:ubuntu ✓"
    elif $FORCE; then
      sudo chown ubuntu:ubuntu "$dst"
      echo "  sudo chown ubuntu:ubuntu ✓"
    else
      echo "  WARN: chown failed (current owner: $current_owner); rerun with --force" >&2
    fi
  fi

  cp "$src" "$dst"
  chmod 644 "$dst" 2>/dev/null || true
  synced=$((synced + 1))
done

echo
echo "synced $synced plugin(s) → $DEST"