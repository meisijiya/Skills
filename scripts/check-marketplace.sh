#!/usr/bin/env bash
# scripts/check-marketplace.sh
#
# Verify .claude-plugin/marketplace.json is in sync with the skills/
# filesystem. Bidirectional:
#   - Every skill under skills/<dir>/<name>/SKILL.md is listed in some
#     plugin entry's skills[] array
#   - Every path declared in the manifest exists on disk
#   - All manifest paths start with "./" (vercel-labs/skills CLI requirement)
#
# Run in CI; exit 0 = OK, 1 = drift detected.

set -euo pipefail

MANIFEST=".claude-plugin/marketplace.json"

die() {
  echo "FAIL: $*" >&2
  exit 1
}

[[ -f "$MANIFEST" ]] || die "$MANIFEST not found"

mapfile -t manifest_paths < <(
  grep -oE '"\./skills/[^"]+"' "$MANIFEST" | tr -d '"' | sort -u
)

[[ ${#manifest_paths[@]} -gt 0 ]] || die "$MANIFEST contains no './skills/' paths"

for p in "${manifest_paths[@]}"; do
  [[ "$p" == ./* ]] || die "manifest path '$p' must start with './' (vercel-labs/skills CLI requirement)"
done

mapfile -t fs_paths < <(
  find skills -mindepth 2 -maxdepth 2 -type d -exec test -f "{}/SKILL.md" \; -print \
    | sed 's|^|./|' | sort -u
)

if diff -q <(printf '%s\n' "${fs_paths[@]}") <(printf '%s\n' "${manifest_paths[@]}") > /dev/null; then
  echo "OK marketplace.json in sync with skills/ ($(printf '%s\n' "${fs_paths[@]}" | wc -l) skills)"
  exit 0
fi

echo "FAIL $MANIFEST is out of sync with skills/"
echo
echo "Diff (left = filesystem, right = manifest):"
diff <(printf '%s\n' "${fs_paths[@]}") <(printf '%s\n' "${manifest_paths[@]}") | sed 's/^/  /'
echo
echo "Fix: edit $MANIFEST to add/remove paths to match filesystem"
exit 1