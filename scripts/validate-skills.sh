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

# eval_check_eval <eval_json_path>: print OK|WAIVER|FAIL|<reason>
# OK when positive_triggers≥3, negative_triggers≥3, behavioral_evals≥1.
# WAIVER when any count below threshold but top-level `waiver` field has future `expires` date.
# FAIL otherwise (also when waiver is missing fields, has invalid expires, or expired).
eval_check_eval() {
  python3 - "$1" <<'PYEOF'
import json, sys, datetime
path = sys.argv[1]
try:
    d = json.load(open(path))
except Exception as e:
    print(f"FAIL|invalid JSON: {e}")
    sys.exit(0)
pos = len(d.get("positive_triggers") or [])
neg = len(d.get("negative_triggers") or [])
beh = len(d.get("behavioral_evals") or [])
waiver = d.get("waiver")
if pos >= 3 and neg >= 3 and beh >= 1:
    print(f"OK|pos={pos} neg={neg} beh={beh}")
    sys.exit(0)
if waiver:
    reason = waiver.get("reason", "")
    expires = waiver.get("expires", "")
    if not reason or not expires:
        print(f"FAIL|waiver present but missing 'reason' or 'expires' (pos={pos} neg={neg} beh={beh})")
        sys.exit(0)
    try:
        exp_dt = datetime.date.fromisoformat(expires)
    except Exception:
        print(f"FAIL|waiver 'expires' not ISO date '{expires}' (pos={pos} neg={neg} beh={beh})")
        sys.exit(0)
    today = datetime.date.today()
    if exp_dt < today:
        print(f"FAIL|waiver EXPIRED on {expires} (today {today}) (pos={pos} neg={neg} beh={beh})")
        sys.exit(0)
    print(f"WAIVER|expires={expires} pos={pos} neg={neg} beh={beh}")
    sys.exit(0)
print(f"FAIL|pos={pos}(need≥3) neg={neg}(need≥3) beh={beh}(need≥1); no waiver or waiver expired")
PYEOF
}

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

  # 9. disable-model-invocation controlled-field policy (per skill-anatomy.md)
  # Allowlist of skills allowed to use this controlled extension field.
  # TODO: extract to a config file (e.g. scripts/allowlist/disable-model-invocation.txt) when more skills qualify.
  dmi_allowlist="loop-me
meisijiya-handoff"
  has_dmi=$(grep -E '^disable-model-invocation:[[:space:]]*true' <<<"$fm" || true)
  if [[ -n "$has_dmi" ]]; then
    if ! grep -qxF "$skill_name" <<<"$dmi_allowlist"; then
      fails+=("disable-model-invocation: true on '$skill_name' but only allowlisted skills may use it (current allowlist: $dmi_allowlist). See skill-anatomy.md § Controlled extension fields.")
    else
      fm_line_index=$(awk -v p="$fm" 'BEGIN{ n=0 } { n++ } { if($0 == p || (length(p)>0 && index($0,p)==1)) print n; exit }' <<<"$fm" || true)
      dmi_line=$(awk 'BEGIN{n=0} /^disable-model-invocation:[[:space:]]*true/{print NR; exit}' <<<"$fm")
      if [[ -z "$dmi_line" ]]; then
        fails+=("disable-model-invocation: true on '$skill_name' (allowlisted) but could not locate line index in frontmatter.")
      else
        next_line=$((dmi_line + 1))
        next_field=$(awk -v n="$next_line" 'NR==n' <<<"$fm")
        if ! [[ "$next_field" =~ ^disable-model-invocation-justification:[[:space:]]* ]]; then
          fails+=("disable-model-invocation: true on '$skill_name' (allowlisted) but the line immediately below the flag is not 'disable-model-invocation-justification:'. See skill-anatomy.md § Controlled extension fields.")
        fi
      fi
      eval_file="evals/cases/${skill_name}.json"
      if [[ -f "$eval_file" ]]; then
        beh_count=$(python3 -c "import json; d=json.load(open('$eval_file')); print(len(d.get('behavioral_evals',[])))" 2>/dev/null || echo "0")
        if [[ "${beh_count:-0}" -lt 1 ]]; then
          fails+=("disable-model-invocation: true on '$skill_name' (allowlisted) but eval case '$eval_file' has 0 behavioral_evals. Must have ≥1 demonstrating the user-trigger pattern.")
        else
          eval_check=$(python3 - "$eval_file" <<'PYEOF'
import json, re, sys
path = sys.argv[1]
data = json.load(open(path))
invocation_keywords = re.compile(r"user-triggered|user explicitly|manual invocation|disable-model-invocation|user-only|stateful|user must|user invokes|user-invocation|requireUserInvocation|user must explicitly|manually invoked", re.I)
no_auto_keywords = re.compile(r"does not auto-invoke|does NOT invoke|agent will not auto-load|not auto-invoked|will not auto-load|must not auto-invoke|not auto[- ]load|never invoke|never auto-invoke|NEVER invoke", re.I)
for entry in data.get("behavioral_evals", []):
    if not isinstance(entry, dict):
        continue
    fields = []
    for key in ("scenario", "expected_behavior", "scenario_text", "expected", "input", "output"):
        if key in entry:
            value = entry[key]
            if isinstance(value, str):
                fields.append(value)
            elif isinstance(value, list):
                fields.extend(item for item in value if isinstance(item, str))
    if not fields:
        for key, value in entry.items():
            if isinstance(value, str):
                fields.append(value)
            elif isinstance(value, list):
                fields.extend(item for item in value if isinstance(item, str))
    text = "\n".join(fields)
    if invocation_keywords.search(text) and no_auto_keywords.search(text):
        print("MATCH")
        sys.exit(0)
print("MISS")
PYEOF
          )
          if [[ "$eval_check" != "MATCH" ]]; then
            fails+=("disable-model-invocation: true on '$skill_name' (allowlisted) but no behavioral_evals entry contains BOTH a user-invocation phrase (user-triggered / user explicitly / manual invocation / disable-model-invocation / user-only / stateful / user must / user invokes / user-invocation) AND a non-auto-invocation phrase (does not auto-invoke / agent will not auto-load / not auto-invoked / will not auto-load / must not auto-invoke / not auto-load).")
          fi
        fi
      else
        fails+=("disable-model-invocation: true on '$skill_name' (allowlisted) but eval case '$eval_file' not found.")
      fi
    fi
  fi

  # 10. eval case 3+3+1 structural check (per skill-anatomy.md § Marketplace / Add new skill step)
  # Each evals/cases/<skill>.json MUST have ≥3 positive_triggers, ≥3 negative_triggers,
  # ≥1 behavioral_evals scenario UNLESS it carries a top-level `waiver` with future
  # `expires` date. Expired waivers also fail.
  eval_file="evals/cases/${skill_name}.json"
  if [[ -f "$eval_file" ]]; then
    eval_check=$(eval_check_eval "$eval_file" 2>/dev/null || echo "FAIL|PYTHON_ERROR")
    case "${eval_check%%|*}" in
      OK) ;;
      WAIVER) ;;
      FAIL)
        fails+=("eval case '$eval_file' structural check: ${eval_check#FAIL|}")
        ;;
      *)
        fails+=("eval case '$eval_file' check error: ${eval_check#*|}")
        ;;
    esac
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