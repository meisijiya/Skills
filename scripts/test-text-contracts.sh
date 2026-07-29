#!/usr/bin/env bash
set -euo pipefail

ROOT="${TEXT_CONTRACT_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
failures=0

check() {
  local file="$1" literal="$2" label="$3"
  if grep -Fq -- "$literal" "$ROOT/$file"; then
    printf 'PASS %s\n' "$label"
  else
    printf 'FAIL %s — missing literal: %s\n' "$label" "$literal"
    failures=$((failures + 1))
  fi
}

contracts() {
  check skills/core/brainstorming/SKILL.md '^[a-z0-9][a-z0-9-]{0,39}$' slug-regex
  check skills/core/brainstorming/SKILL.md 'REFUSE: slug must match ^[a-z0-9][a-z0-9-]{0,39}$; offer transliterate fallback.' slug-refusal
  check skills/core/incremental-implementation/SKILL.md 'ls -d .omo/{drafts,sdd,build-gate,prototypes,throwaway,wayfinder,wayfinder-archive,research,architecture-review,incidents}/* 2>/dev/null' startup-sweep
  check skills/core/incremental-implementation/SKILL.md 'Cross-check every result against `.omo/.index.json` field `stale_artifacts`.' sweep-index-crosscheck
  check skills/core/incremental-implementation/SKILL.md 'Prompt exactly `Delete stale artifacts? y/n`; never auto-delete.' sweep-confirmation
  check skills/core/debugging-and-error-recovery/SKILL.md '<!-- WARNING: notepad exceeded 500 lines at <iso8601> -->' notepad-banner
  check skills/core/debugging-and-error-recovery/SKILL.md 'Never auto-truncate the notepad.' no-auto-truncate
  check skills/core/spec-driven-development/SKILL.md '### 3.5 Visual/Interaction Decisions' proto-section
  check skills/core/spec-driven-development/SKILL.md '`spec_approved` requires zero remaining `[PROTO-RESOLVE: <question>]` markers.' proto-zero-marker
  check skills/core/spec-driven-development/SKILL.md 'mkdir -p .omo/sdd/<slug>/drafts/ && mv .omo/drafts/<slug>.md .omo/sdd/<slug>/drafts/' draft-archive
  check skills/core/spec-driven-development/SKILL.md '[cleanup] ts=<iso8601> source=.omo/drafts/<slug>.md destination=.omo/sdd/<slug>/drafts/<slug>.md action=moved' cleanup-row
  check skills/extra/build-gate-visual-review/SKILL.md "find .omo -type f \\( -name '*.html' -o -name '*.htm' \\) -mtime +30 -print" stale-html
  check skills/extra/build-gate-visual-review/SKILL.md 'Prompt exactly `Archive stale HTML? y/n`; never auto-delete.' stale-html-confirmation
  check skills/extra/security-incident-response/SKILL.md '[incident:closed] ts=<iso8601> incident=<slug> closed=.omo/incidents/<slug>/closed.json' incident-row
  check skills/extra/security-incident-response/SKILL.md "printf '%s\\n' '{\"status\":\"closed\",\"closed_at\":\"<iso8601>\"}' > .omo/incidents/<slug>/closed.json" incident-closed-json
  (( failures == 0 )) || return 1
}

slug_qa() {
  local slug="${1:-}"
  if [[ "$slug" =~ ^[a-z0-9][a-z0-9-]{0,39}$ ]]; then printf 'ACCEPT %s\n' "$slug"
  else printf 'REFUSE: slug must match ^[a-z0-9][a-z0-9-]{0,39}$; offer transliterate fallback.\n'; fi
}

notepad_qa() {
  local file="${1:-}" lines stamp iso_re='^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$'
  [[ "$file" != /* && ( "$file" == .omo/notepads/* || "$file" == */.omo/notepads/* ) && "$file" != *"/../"* && ! -L "$file" && -f "$file" ]] || { printf 'ERROR: notepad path/format invalid: %s\n' "$file" >&2; return 1; }
  lines=$(wc -l < "$file")
  if (( lines >= 500 )); then
    [[ -z "${QA_ISO8601:-}" || "$QA_ISO8601" =~ $iso_re ]] || { printf 'ERROR: QA_ISO8601 must match ISO 8601 Z format\n' >&2; return 1; }
    stamp="${QA_ISO8601:-$(date -u +%Y-%m-%dT%H:%M:%SZ)}"
    printf '<!-- WARNING: notepad exceeded 500 lines at %s -->\n' "$stamp" >> "$file" || { printf 'ERROR: failed to append to %s\n' "$file" >&2; return 1; }
  fi
}

sweep_qa() {
  local root="${1:-}" answer
  [[ -d "$root" ]] || { printf 'ERROR: not a directory: %s\n' "$root" >&2; return 1; }
  (cd "$root" && ls -d .omo/{drafts,sdd,build-gate,prototypes,throwaway,wayfinder,wayfinder-archive,research,architecture-review,incidents}/* 2>/dev/null || true)
  printf 'Delete stale artifacts? y/n: '
  IFS= read -r answer || { printf 'ERROR: read failed (EOF?)\n' >&2; return 1; }
  printf 'selection=%s; no files deleted by test helper\n' "$answer"
}

html_qa() {
  local root="${1:-}" answer
  [[ -d "$root" ]] || { printf 'ERROR: not a directory: %s\n' "$root" >&2; return 1; }
  (cd "$root" && find .omo -type f \( -name '*.html' -o -name '*.htm' \) -mtime +30 -print)
  printf 'Archive stale HTML? y/n: '
  IFS= read -r answer || { printf 'ERROR: read failed (EOF?)\n' >&2; return 1; }
  printf 'selection=%s; no files deleted by test helper\n' "$answer"
}

case "${1:-contracts}" in
  contracts) contracts ;;
  slug) slug_qa "${2:-}" ;;
  notepad) notepad_qa "${2:?notepad path required}" ;;
  sweep) sweep_qa "${2:?fixture root required}" ;;
  html) html_qa "${2:?fixture root required}" ;;
  *) printf 'usage: %s [contracts|slug VALUE|notepad FILE|sweep ROOT|html ROOT]\n' "$0" >&2; exit 2 ;;
esac
