#!/usr/bin/env bash
# scripts/validate-skills.sh
#
# Validate every SKILL.md under skills/ has correct YAML frontmatter
# and the recommended section structure defined in skill-anatomy.md.
#
# Usage:
#   scripts/validate-skills.sh                # default: skills/
#   scripts/validate-skills.sh skills/core
#   NO_COLOR=1 scripts/validate-skills.sh     # no ANSI in CI logs
#
# Exit codes:
#   0  all skills valid (warnings OK)
#   1  at least one skill failed required checks
#   2  usage / setup error (no SKILL.md found, missing dep)

set -euo pipefail

SKILLS_DIR="${1:-skills}"

# Color setup (suppressed in non-tty or when NO_COLOR is set)
if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
  RED=$'\033[0;31m'
  GREEN=$'\033[0;32m'
  YELLOW=$'\033[1;33m'
  NC=$'\033[0m'
else
  RED='' GREEN='' YELLOW='' NC=''
fi

usage() {
  cat <<EOF
Usage: $0 [skills-dir]

Validates SKILL.md files under the given directory (default: skills/).

Required checks (FAIL on miss):
  - File starts with YAML frontmatter delimited by ---
  - frontmatter has 'name' field
  - 'name' matches the directory name
  - frontmatter has 'description' field
  - 'description' is <= 1024 characters

Recommended checks (WARN on miss):
  - Has '## Overview' section
  - Has '## When to Use' section
  - Has '## Process' section
  - 'name' matches strict kebab-case regex (no '--', no leading/trailing '-')
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

if [[ ! -d "$SKILLS_DIR" ]]; then
  echo "Error: '$SKILLS_DIR' is not a directory" >&2
  usage >&2
  exit 2
fi

mapfile -t skill_files < <(find "$SKILLS_DIR" -name SKILL.md -type f | sort)

if [[ ${#skill_files[@]} -eq 0 ]]; then
  echo "Error: no SKILL.md files found under '$SKILLS_DIR/'" >&2
  exit 2
fi

checked=0
failed=0
warned=0

for skill_md in "${skill_files[@]}"; do
  checked=$((checked + 1))
  skill_dir=$(dirname "$skill_md")
  skill_name=$(basename "$skill_dir")
  rel="${skill_md#./}"

  fails=()
  warns=()

  # 1. YAML frontmatter exists
  if ! head -1 "$skill_md" | grep -q '^---[[:space:]]*$'; then
    fails+=("missing YAML frontmatter (file must start with '---' on line 1)")
    echo "${RED}FAIL${NC} $rel"
    printf '  - %s\n' "${fails[@]}"
    failed=$((failed + 1))
    continue
  fi

  # 2. Extract frontmatter body (between first two ---)
  fm=$(awk 'BEGIN{n=0} /^---[[:space:]]*$/{n++; if(n==2){exit}; next} n==1{print}' "$skill_md")

  # 3. Parse name
  name=$(grep -E '^name:' <<<"$fm" | head -1 | sed 's/^name:[[:space:]]*//')

  # 4. Parse description
  desc=$(grep -E '^description:' <<<"$fm" | head -1 | sed 's/^description:[[:space:]]*//')

  # 5. Validate name
  if [[ -z "$name" ]]; then
    fails+=("frontmatter missing 'name'")
  elif [[ "$name" != "$skill_name" ]]; then
    fails+=("name '$name' does not match directory '$skill_name'")
  fi

  # 5b. Strict kebab-case regex check
  if [[ -n "$name" && ! "$name" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]]; then
    warns+=("name '$name' should match ^[a-z0-9]+(-[a-z0-9]+)*\$ (no '--' / no leading or trailing '-')")
  fi

  # 6. Validate description
  if [[ -z "$desc" ]]; then
    fails+=("frontmatter missing 'description'")
  elif [[ ${#desc} -gt 1024 ]]; then
    fails+=("description is ${#desc} chars (max 1024)")
  fi

  # 7. Recommended sections
  if ! grep -qiE '^##[[:space:]]+Overview' "$skill_md"; then
    warns+=("missing recommended section '## Overview'")
  fi
  if ! grep -qiE '^##[[:space:]]+(When to Use|When To Use|Usage|Triggering Conditions)' "$skill_md"; then
    warns+=("missing recommended section '## When to Use' (or equivalent)")
  fi
  if ! grep -qiE '^##[[:space:]]+(Process|Core Process|Workflow|How It Works|Steps)' "$skill_md"; then
    warns+=("missing recommended Process section (## Process / ## Core Process / ## Workflow / ## How It Works)")
  fi

  # 8. allowed-tools consistency: body must not reference tools not declared
  body_after_fm=$(awk 'BEGIN{out=0} /^---$/{n++; if(n==2) out=1; next} out' "$skill_md")
  if [[ -n "$fm" && -n "$body_after_fm" ]]; then
    declared_tools=$(echo "$fm" | grep '^allowed-tools:' | head -1 | sed 's/^allowed-tools:[[:space:]]*"//;s/"[[:space:]]*$//' | tr ' ' '\n' | sort -u)
    for tool in Read Write Edit Bash Glob Grep WebFetch WebSearch; do
      echo "$body_after_fm" | grep -qE "\b$tool\b" || continue
      echo "$declared_tools" | grep -qxF "$tool" && continue
      echo "$body_after_fm" | grep -qiE "(No|not|cannot|should not|禁用|不要|不需要|only[[:space:]]+Read|not[[:space:]]+use|without).{0,30}\b$tool\b" && continue
      if [[ "$tool" == "Write" ]] && echo "$body_after_fm" | grep -qiE "\b(writes?|writing|written)\b"; then continue; fi
      if [[ "$tool" == "Edit" ]] && echo "$body_after_fm" | grep -qiE "\b(edits?|editing|edited)\b"; then continue; fi
      warns+=("body references '$tool' but frontmatter allowed-tools does not declare it")
      break
    done
  fi

  # Report
  if [[ ${#fails[@]} -gt 0 ]]; then
    echo "${RED}FAIL${NC} $rel"
    for f in "${fails[@]}"; do echo "  - $f"; done
    for w in "${warns[@]}"; do echo "  ~ $w"; done
    failed=$((failed + 1))
  elif [[ ${#warns[@]} -gt 0 ]]; then
    echo "${YELLOW}WARN${NC} $rel"
    for w in "${warns[@]}"; do echo "  ~ $w"; done
    warned=$((warned + 1))
  else
    echo "${GREEN}OK  ${NC} $rel"
  fi
done

echo
echo "Checked: $checked  Failed: $failed  Warnings: $warned"

if [[ $failed -gt 0 ]]; then
  exit 1
fi
echo "All required checks passed."