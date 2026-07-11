#!/usr/bin/env bash
# scripts/install.sh
#
# Install meisijiya-skills to an OpenCode project.
#
# Usage:
#   scripts/install.sh                          # install .core/ to ./.opencode/skills/
#   scripts/install.sh --target /path/to/proj   # install to specific project
#   scripts/install.sh --extra <name>           # also install a specific .extra/ skill
#   scripts/install.sh --all-extra              # install all .extra/ skills
#   scripts/install.sh --list                   # list available .extra/ skills
#   scripts/install.sh --dry-run                # show what would be installed, don't copy
#   scripts/install.sh --global                 # install to ~/.agents/skills/
#
# Defaults: install all .core/ to <target>/.opencode/skills/
#
# Notes:
#   - .core/ is always installed by default (required set)
#   - .extra/ is opt-in (you pick which ones)
#   - Existing skills in target dir are not overwritten (rm manually if needed)
#   - Uses cp -r, so no symlinks (clean copy)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CORE_DIR="$REPO_ROOT/skills/.core"

# Defaults
TARGET="$(pwd)"
GLOBAL=false
DRY_RUN=false
EXTRAS=()
ALL_EXTRA=false
LIST_ONLY=false

usage() {
  cat <<EOF
Usage: $0 [options]

Options:
  --target PATH        install to <PATH>/.opencode/skills/ (default: cwd)
  --global             install to ~/.agents/skills/
  --extra NAME         also install .extra/NAME (repeatable)
  --all-extra          install all .extra/ skills
  --list               list available .extra/ skills and exit
  --dry-run            show what would be installed, don't copy
  -h, --help           show this help

Examples:
  $0                                          # install .core/ to cwd
  $0 --target ~/projects/myapp                # install to myapp/.opencode/skills/
  $0 --extra interview-me --extra security-and-hardening
  $0 --all-extra --dry-run                    # preview all-extra install
EOF
}

# Parse args
while [[ $# -gt 0 ]]; do
  case "$1" in
    --target) TARGET="$2"; shift 2 ;;
    --global) GLOBAL=true; shift ;;
    --extra) EXTRAS+=("$2"); shift 2 ;;
    --all-extra) ALL_EXTRA=true; shift ;;
    --list) LIST_ONLY=true; shift ;;
    --dry-run) DRY_RUN=true; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage; exit 1 ;;
  esac
done

# List mode
if $LIST_ONLY; then
  echo "Available .extra/ skills:"
  for d in "$REPO_ROOT/skills/.extra"/*/; do
    [[ -f "$d/SKILL.md" ]] || continue
    name=$(basename "$d")
    desc=$(awk -F': *' '/^description:/{sub(/^description: */,""); print; exit}' "$d/SKILL.md")
    printf "  %-32s %s\n" "$name" "$desc"
  done
  exit 0
fi

# Resolve target dir
if $GLOBAL; then
  INSTALL_ROOT="${HOME}/.agents/skills"
else
  INSTALL_ROOT="$TARGET/.opencode/skills"
fi

# Build the list of (source, dest) pairs to install
PAIRS=()

# Always install all .core/
if [[ ! -d "$CORE_DIR" ]]; then
  echo "Error: $CORE_DIR not found. Run from meisijiya-skills repo root." >&2
  exit 1
fi
for d in "$CORE_DIR"/*/; do
  [[ -f "$d/SKILL.md" ]] || continue
  name=$(basename "$d")
  PAIRS+=("$d|$INSTALL_ROOT/$name")
done

# Optional extras
if $ALL_EXTRA; then
  for d in "$REPO_ROOT/skills/.extra"/*/; do
    [[ -f "$d/SKILL.md" ]] || continue
    name=$(basename "$d")
    PAIRS+=("$d|$INSTALL_ROOT/$name")
  done
else
  for extra in "${EXTRAS[@]}"; do
    src="$REPO_ROOT/skills/.extra/$extra"
    if [[ ! -d "$src" ]]; then
      echo "Error: .extra/$extra not found. Use --list to see available skills." >&2
      exit 1
    fi
    PAIRS+=("$src|$INSTALL_ROOT/$extra")
  done
fi

# Display plan
echo "Install plan:"
echo "  Target: $INSTALL_ROOT"
echo "  Skills: ${#PAIRS[@]}"
echo

# Execute (or dry-run)
if ! $DRY_RUN; then
  mkdir -p "$INSTALL_ROOT"
fi
for pair in "${PAIRS[@]}"; do
  src="${pair%|*}"
  dest="${pair#*|}"
  name=$(basename "$dest")
  if [[ -d "$dest" ]]; then
    echo "  SKIP   $name (already exists at $dest)"
  elif $DRY_RUN; then
    echo "  COPY   $src -> $dest"
  else
    cp -r "$src" "$dest"
    echo "  COPIED $name -> $dest"
  fi
done

echo
if $DRY_RUN; then
  echo "(dry run — no files copied)"
else
  echo "Done. $INSTALL_ROOT now contains $(ls -1 "$INSTALL_ROOT" 2>/dev/null | wc -l) skill(s)."
fi