#!/usr/bin/env bash
# apply-patches.sh -- Apply the Antumbra patch series to a Firefox source tree.
#
# Usage:
#   apply-patches.sh [--check] [--firefox-src PATH]
#
#   --check          Dry run only (git apply --check). No changes are made.
#   --firefox-src    Path to the Firefox source tree.
#                    Defaults to ../firefox relative to the repository root.
#
# Patches are applied in numeric filename order (0000, 0100, 0200, ...).
# All patches must apply cleanly; the script exits on the first failure.
#
# In CI: call with --check. On the build machine: call without --check.
# See ARCHITECTURE.md section 10.3 and CONTRIBUTING.md.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
PATCHES_DIR="${REPO_ROOT}/patches"
FIREFOX_SRC="${REPO_ROOT}/../firefox"
DRY_RUN=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        --check)
            DRY_RUN=1
            shift
            ;;
        --firefox-src)
            FIREFOX_SRC="$2"
            shift 2
            ;;
        *)
            echo "ERROR: unknown flag: $1" >&2
            echo "Usage: $0 [--check] [--firefox-src PATH]" >&2
            exit 1
            ;;
    esac
done

if [[ ! -d "${FIREFOX_SRC}/.git" ]]; then
    echo "ERROR: Firefox source not found at ${FIREFOX_SRC}" >&2
    echo "Set --firefox-src or ensure ../firefox is a git repository." >&2
    exit 1
fi

PATCH_COUNT="$(find "${PATCHES_DIR}" -name "*.patch" | wc -l)"
if [[ "${PATCH_COUNT}" -eq 0 ]]; then
    echo "WARNING: no .patch files found under ${PATCHES_DIR}"
    exit 0
fi

if [[ $DRY_RUN -eq 1 ]]; then
    APPLY_FLAGS="--check"
    echo "DRY RUN: checking ${PATCH_COUNT} patch(es) apply cleanly to ${FIREFOX_SRC}"
else
    APPLY_FLAGS="--3way"
    echo "Applying ${PATCH_COUNT} patch(es) to ${FIREFOX_SRC}"
fi

APPLIED=0
while IFS= read -r -d '' patch; do
    rel="${patch#${REPO_ROOT}/}"
    echo "  Applying: ${rel}"
    if ! git -C "${FIREFOX_SRC}" apply ${APPLY_FLAGS} "${patch}"; then
        echo "FAILED: ${rel}" >&2
        exit 1
    fi
    APPLIED=$((APPLIED + 1))
done < <(find "${PATCHES_DIR}" -name "*.patch" -print0 | sort -z)

if [[ $DRY_RUN -eq 1 ]]; then
    echo "Patch check passed: ${APPLIED} patch(es) apply cleanly."
else
    echo "Done: ${APPLIED} patch(es) applied."
fi
