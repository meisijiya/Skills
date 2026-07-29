#!/usr/bin/env bash
# scripts/test-prototype.sh — contract verifier for /prototype skill package
# Failing-first: exits 1 before the skill package exists; exits 0 after.
# Verifies: C1 eval JSON | C2 trigger counts (3+3+>=1) | C3 positive_keywords
# ⊂ description | C4 SKILL.md structure (6 sections + omo Integration) | C5 status
# machine literals | C6 decisions.md formats | C7 bypass reason requirement | C8
# MIN 2 variants + render:failed | C9 brownfield+greenfield+?variant=A/B/C | C10
# taste enforcement + [taste:exempt] | C11 docs/prototype.md exists.
set -euo pipefail
cd "$(dirname "$0")/.."
SKILL="skills/extra/prototype/SKILL.md"; DOCS="docs/prototype.md"; EVAL="evals/cases/prototype.json"
fails=(); pass(){ echo "  PASS: $1"; }; chk(){ if eval "$2" >/dev/null 2>&1; then pass "$1"; else fails+=("$1"); echo "  FAIL: $1"; fi; }
echo "=== test-prototype.sh — $(date -u +%Y-%m-%dT%H:%M:%SZ) ==="
echo "--- C1: eval JSON parse ---"
if [[ -f "$EVAL" ]] && jq -e . "$EVAL" >/dev/null 2>&1; then pass "C1: $EVAL parses as JSON"; else fails+=("C1: $EVAL missing or invalid JSON"); echo "  FAIL: C1"; echo "=== FAIL — 1 contract violated ==="; echo "  - C1: $EVAL missing or invalid JSON"; exit 1; fi
echo "--- C2: trigger counts (3 pos / 3 neg / >=1 beh) ---"
PT=$(jq -r '.positive_triggers | length' "$EVAL"); NT=$(jq -r '.negative_triggers | length' "$EVAL"); BE=$(jq -r '.behavioral_evals | length' "$EVAL")
chk "C2a: positive_triggers == 3 (got $PT)" "[[ $PT -eq 3 ]]"; chk "C2b: negative_triggers == 3 (got $NT)" "[[ $NT -eq 3 ]]"; chk "C2c: behavioral_evals >= 1 (got $BE)" "[[ $BE -ge 1 ]]"
echo "--- C3: positive_keywords ⊂ description ---"
if [[ -f "$SKILL" ]]; then
  DESC=$(awk 'BEGIN{n=0} /^---[[:space:]]*$/{n++; if(n==2){exit}; next} n==1{print}' "$SKILL" | sed -n '/^description:/p' | sed 's/^description:[[:space:]]*//')
  PKW=$(jq -r '.positive_keywords | length' "$EVAL")
  chk "C3a: positive_keywords non-empty ($PKW entries)" "[[ $PKW -gt 0 ]]"
  miss=(); while IFS= read -r kw; do [[ -z "$kw" ]] && continue; grep -qiF "$kw" <<<"$DESC" || miss+=("$kw"); done < <(jq -r '.positive_keywords[]' "$EVAL")
  chk "C3b: every positive_keyword in description (missing: ${miss[*]:-none})" "[[ ${#miss[@]} -eq 0 ]]"
else chk "C3: $SKILL exists" "false"; fi
echo "--- C4: SKILL.md structure ---"
if [[ -f "$SKILL" ]]; then
  chk "C4a: frontmatter starts with ---" "head -1 '$SKILL' | grep -q '^---[[:space:]]*$'"
  FM=$(awk 'BEGIN{n=0} /^---[[:space:]]*$/{n++; if(n==2){exit}; next} n==1{print}' "$SKILL")
  chk "C4b: name == prototype" "grep -q '^name:[[:space:]]*prototype' <<<\"\$FM\""
  DL=$(awk 'BEGIN{n=0} /^---[[:space:]]*$/{n++; if(n==2){exit}; next} n==1{print}' "$SKILL" | awk -F: '/^description:/{$1=""; print substr($0,2)}' | wc -c)
  chk "C4c: description <= 1024 chars (got $DL)" "[[ $DL -le 1025 ]]"
  chk "C4d: allowed-tools set" "grep -q '^allowed-tools:' <<<\"\$FM\""
  for s in "## Overview" "## When to Use" "## Process" "## Common Rationalizations" "## Red Flags" "## Verification" "## omo Integration"; do chk "C4e: section: $s" "grep -qF '$s' '$SKILL'"; done
else chk "C4: $SKILL exists" "false"; fi
echo "--- C5: status machine literals ---"
[[ -f "$SKILL" ]] && for l in triggered generating awaiting_selection resolved need_context bypassed; do chk "C5: literal: $l" "grep -qF '$l' '$SKILL'"; done || chk "C5: $SKILL exists" "false"
echo "--- C6: decisions.md formats ---"
[[ -f "$SKILL" ]] && for f in '\[proto\]' '\[proto:superseded\]' '\[proto:cleanup\]' '\[proto:bypass\]' '\[proto:exempt\]'; do chk "C6: format: $f" "grep -qE '$f' '$SKILL'"; done || chk "C6: $SKILL exists" "false"
echo "--- C7: bypass policy + reason ---"
[[ -f "$SKILL" ]] && { chk "C7a: bypass default TRIGGER" "grep -qiE '(bypass.*default.*trigger|bypass.*TRIGGER)' '$SKILL'"; chk "C7b: reason required" "grep -qiE 'reason' '$SKILL'"; } || chk "C7: $SKILL exists" "false"
echo "--- C8: MIN 2 variants + render:failed ---"
[[ -f "$SKILL" ]] && { chk "C8a: MIN 2 variants" "grep -qE '(MIN 2|minimum 2|at least 2|>= 2)' '$SKILL'"; chk "C8b: render:failed" "grep -qF 'render:failed' '$SKILL'"; } || chk "C8: $SKILL exists" "false"
echo "--- C9: brownfield + greenfield + switcher ---"
[[ -f "$SKILL" ]] && { chk "C9a: brownfield" "grep -qiE 'brownfield' '$SKILL'"; chk "C9b: greenfield" "grep -qiE 'greenfield' '$SKILL'"; chk "C9c: ?variant=A/B/C" "grep -qE 'variant=[ABC]' '$SKILL'"; } || chk "C9: $SKILL exists" "false"
echo "--- C10: taste + exempt ---"
[[ -f "$SKILL" ]] && { chk "C10a: meisijiya-frontend-taste" "grep -qF 'meisijiya-frontend-taste' '$SKILL'"; chk "C10b: [taste:exempt]" "grep -qF 'taste:exempt' '$SKILL'"; } || chk "C10: $SKILL exists" "false"
echo "--- C11: docs/prototype.md ---"; chk "C11: $DOCS exists" "[[ -f '$DOCS' ]]"
echo
if [[ ${#fails[@]} -eq 0 ]]; then echo "=== OK — all contracts pass ==="; exit 0; else echo "=== FAIL — ${#fails[@]} contract(s) violated ==="; printf '  - %s\n' "${fails[@]}"; exit 1; fi
