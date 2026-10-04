#!/usr/bin/env bash
# check-tree-sync.sh -- Verify that the state of a Firefox tree matches the state
# that the committed patch series would produce from a clean checkout of the
# pinned ESR tag.
#
# Why this exists:
# Several times during Milestone 0 and Milestone 1 a developer fixed something
# in the local Firefox tree during a build session, built successfully, and
# never regenerated the fix back into the committed patch. Cold builds then
# failed on fresh checkouts because the patch series was incomplete. See
# D16 in DECISIONS.md.
#
# What this script catches:
#   1. Modifications to any file created or modified by the patch series that
#      differ from what the patches would produce from a clean checkout.
#   2. Files that no patch produces but that exist in the Firefox tree under an
#      owned prefix (orphan additions).
#   3. Files that the patch series produces but that are missing in the Firefox
#      tree (patched file was deleted locally).
#
# What this script does NOT catch:
#   - Edits to upstream files that no patch touches and that live outside the
#     owned-prefix list. Broaden OWNED_PREFIXES as new patch areas are added.
#   - Patch content that is syntactically valid but semantically wrong (a pref
#     typo that passes audit but produces no behavior). Those are caught by the
#     pref audit CI job and by on-screen verification, not by this script.
#   - Changes applied via symlinks, hardlinks, or outside git's view.
#
# Usage:
#   scripts/check-tree-sync.sh [--firefox-src PATH]
#
# Exit codes:
#   0 - No drift detected.
#   1 - Drift detected; a non-empty diff is printed.
#   2 - Script setup error (missing files, bad tag, apply failure).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
PATCHES_DIR="${REPO_ROOT}/patches"
FIREFOX_SRC="${REPO_ROOT}/../firefox"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --firefox-src) FIREFOX_SRC="$2"; shift 2 ;;
        -h|--help)
            awk '/^set -euo/{exit} NR>1' "$0" | sed 's/^# \{0,1\}//'
            exit 0
            ;;
        *) echo "ERROR: unknown flag: $1" >&2; exit 2 ;;
    esac
done

if [[ ! -d "${FIREFOX_SRC}/.git" ]]; then
    echo "ERROR: Firefox source not found at ${FIREFOX_SRC}" >&2
    exit 2
fi

PINNED_TAG="$(grep '^FIREFOX_ESR_TAG=' "${REPO_ROOT}/upstream.conf" | cut -d= -f2)"
if [[ -z "${PINNED_TAG}" ]]; then
    echo "ERROR: FIREFOX_ESR_TAG missing from upstream.conf" >&2
    exit 2
fi

# Owned prefixes: the parts of the Firefox tree that the patch series is the
# sole source of truth for. Anything under these paths that is not produced by
# a patch is treated as drift. Keep this list in sync with new patch areas.
OWNED_PREFIXES=(
    "browser/branding/antumbra"
    "browser/components/antumbra"
    "browser/distribution/policies.json"
    "browser/app/profile/antumbra.js"
)

# Shared files: files that patches modify but that upstream owns. For these,
# we only check that the file content matches what applying the patches to
# the pinned tag would produce. Added/removed is not meaningful here.
SHARED_FILES=(
    "browser/moz.build"
    "browser/components/moz.build"
    "browser/themes/shared/customizableui/panelUI-shared.css"
)

echo "Pinned tag: ${PINNED_TAG}"
echo "Firefox src: ${FIREFOX_SRC}"

# Build the expected state in a stub directory. We only need the shared files
# from the pinned tag as a base; every patch after the first creates new files,
# which git apply does not need existing content for. This is orders of
# magnitude cheaper than cloning the full Firefox tree.
STUB="$(mktemp -d -t antumbra-sync-stub-XXXXXX)"
cleanup() {
    rm -rf "${STUB}" 2>/dev/null || true
}
trap cleanup EXIT

echo "Preparing stub at ${STUB}..."

# Materialize each shared file at the pinned tag using git-cat-file into the stub.
for f in "${SHARED_FILES[@]}"; do
    mkdir -p "${STUB}/$(dirname "$f")"
    git -C "${FIREFOX_SRC}" show "${PINNED_TAG}:${f}" > "${STUB}/${f}"
done

# Make the stub a git repo so apply --3way can resolve base content.
(
    cd "${STUB}"
    git init -q
    git -c user.email=sync@antumbra -c user.name=sync add . >/dev/null
    git -c user.email=sync@antumbra -c user.name=sync commit -q -m "stub at ${PINNED_TAG}"
)

echo "Applying patches to stub..."
APPLIED=0
while IFS= read -r -d '' patch; do
    if ! (cd "${STUB}" && git apply --3way "${patch}" 2>&1 | sed 's/^/  /'); then
        echo "ERROR: patch failed to apply to clean stub: ${patch}" >&2
        exit 2
    fi
    APPLIED=$((APPLIED + 1))
done < <(find "${PATCHES_DIR}" -name "*.patch" -print0 | sort -z)
echo "  applied ${APPLIED} patch(es)"

DRIFT=0
report_drift() {
    DRIFT=$((DRIFT + 1))
    echo "DRIFT: $*"
}

check_file() {
    local path="$1"
    local expected="${STUB}/${path}"
    local actual="${FIREFOX_SRC}/${path}"
    if [[ -f "${expected}" ]] && [[ -f "${actual}" ]]; then
        if ! diff -q --strip-trailing-cr "${expected}" "${actual}" >/dev/null 2>&1; then
            report_drift "${path}"
            diff -u --strip-trailing-cr "${expected}" "${actual}" | head -40 | sed 's/^/  /'
        fi
    elif [[ -f "${expected}" ]] && [[ ! -e "${actual}" ]]; then
        report_drift "${path} (patches create it, tree is missing it)"
    elif [[ -f "${actual}" ]] && [[ ! -e "${expected}" ]]; then
        report_drift "${path} (tree has it, no patch produces it)"
    fi
}

check_prefix() {
    local prefix="$1"
    # Forward: everything the patches put under <prefix> must exist and match.
    if [[ -d "${STUB}/${prefix}" ]]; then
        while IFS= read -r -d '' f; do
            local rel="${f#${STUB}/}"
            check_file "${rel}"
        done < <(find "${STUB}/${prefix}" -type f -print0)
    elif [[ -f "${STUB}/${prefix}" ]]; then
        check_file "${prefix}"
    fi
    # Reverse: anything in the Firefox tree under <prefix> that is not in the
    # stub is drift.
    if [[ -d "${FIREFOX_SRC}/${prefix}" ]]; then
        while IFS= read -r -d '' f; do
            local rel="${f#${FIREFOX_SRC}/}"
            if [[ ! -e "${STUB}/${rel}" ]]; then
                report_drift "${rel} (tree has it, no patch produces it)"
            fi
        done < <(find "${FIREFOX_SRC}/${prefix}" -type f -print0)
    fi
}

for p in "${OWNED_PREFIXES[@]}"; do check_prefix "$p"; done
for p in "${SHARED_FILES[@]}";   do check_file   "$p"; done

if [[ "${DRIFT}" -gt 0 ]]; then
    echo
    echo "FAIL: ${DRIFT} drift(s) detected between Firefox tree and patch series."
    echo "Likely cause: a fix was applied in the Firefox tree without regenerating"
    echo "the owning patch (DECISIONS.md D16). Regenerate with:"
    echo "  git -C ${FIREFOX_SRC} add <changed-paths>"
    echo "  git -C ${FIREFOX_SRC} diff --binary --cached ${PINNED_TAG} -- <paths> > <patch>"
    exit 1
fi

echo "PASS: Firefox tree matches patch series."
