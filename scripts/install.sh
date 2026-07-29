#!/usr/bin/env bash
# scripts/install.sh
#
# Atomic, idempotent installer for the omo-state-index OpenCode plugin.
#
# Copies only `.opencode/plugins/omo-state-index.js` from the repository
# root to `~/.config/opencode/plugins/`, and refuses to overwrite if the
# destination's SHA-256 has drifted from the source (i.e. the user has
# a hand-edited copy they want to keep, or a different version pinned).
#
# Idempotent: re-running with the same source SHA exits 0 without writes.
#
# Flags:
#   --force   overwrite destination even if SHA differs (with a warning)
#   --dry-run print intended actions without writing
#
# Exit codes:
#   0  — installed (or already up to date)
#   1  — source missing / SHA drift without --force
#   2  — mkdir / cp failed
#
# This script does NOT touch OMO / OpenCode sources, the marketplace,
# AGENTS.md, README, package.json, lockfile, skills/, or evals/.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="${REPO_ROOT}/.opencode/plugins/omo-state-index.js"
DEST_DIR="${HOME}/.config/opencode/plugins"
DEST="${DEST_DIR}/omo-state-index.js"

FORCE=0
DRY_RUN=0
for arg in "$@"; do
  case "${arg}" in
    --force) FORCE=1 ;;
    --dry-run) DRY_RUN=1 ;;
    -h|--help)
      sed -n '2,30p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *)
      echo "install.sh: unknown flag: ${arg}" >&2
      exit 1
      ;;
  esac
done

if [[ ! -f "${SRC}" ]]; then
  echo "install.sh: source not found: ${SRC}" >&2
  exit 1
fi

SRC_SHA="$(sha256sum "${SRC}" | awk '{print $1}')"

# Ensure destination directory exists.
if [[ ! -d "${DEST_DIR}" ]]; then
  if [[ ${DRY_RUN} -eq 1 ]]; then
    echo "DRY: mkdir -p ${DEST_DIR}"
  else
    mkdir -p "${DEST_DIR}" || { echo "install.sh: mkdir failed: ${DEST_DIR}" >&2; exit 2; }
  fi
fi

# Existing destination handling.
if [[ -f "${DEST}" ]]; then
  DEST_SHA="$(sha256sum "${DEST}" | awk '{print $1}')"
  if [[ "${DEST_SHA}" == "${SRC_SHA}" ]]; then
    echo "install.sh: ${DEST} already up to date (sha256=${SRC_SHA:0:12}…)"
    exit 0
  fi
  if [[ ${FORCE} -ne 1 ]]; then
    echo "install.sh: SHA drift at ${DEST}" >&2
    echo "           source sha256: ${SRC_SHA}" >&2
    echo "           dest   sha256: ${DEST_SHA}" >&2
    echo "           re-run with --force to overwrite." >&2
    exit 1
  fi
  echo "install.sh: --force: overwriting ${DEST} (sha256 ${DEST_SHA:0:12}… → ${SRC_SHA:0:12}…)"
fi

# Atomic copy: write to temp, then rename into place. This matches the
# plugin's own atomic-write discipline for .omo/.index.json.
TMP="${DEST}.tmp.$$"
if [[ ${DRY_RUN} -eq 1 ]]; then
  echo "DRY: cp ${SRC} ${TMP}"
  echo "DRY: mv ${TMP} ${DEST}"
else
  cp "${SRC}" "${TMP}" || { echo "install.sh: cp failed" >&2; rm -f "${TMP}"; exit 2; }
  mv "${TMP}" "${DEST}" || { echo "install.sh: mv failed" >&2; rm -f "${TMP}"; exit 2; }
fi

# Sanity check: destination must be byte-identical to source.
if [[ ${DRY_RUN} -ne 1 ]]; then
  POST_SHA="$(sha256sum "${DEST}" | awk '{print $1}')"
  if [[ "${POST_SHA}" != "${SRC_SHA}" ]]; then
    echo "install.sh: post-install SHA mismatch (${POST_SHA} != ${SRC_SHA})" >&2
    exit 2
  fi
  echo "install.sh: installed ${DEST} (sha256=${POST_SHA:0:12}…)"
else
  echo "DRY: would install ${DEST} (sha256=${SRC_SHA:0:12}…)"
fi
