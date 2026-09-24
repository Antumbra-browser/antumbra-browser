#!/usr/bin/env bash
# Copy vendored extension XPIs to the build output's distribution/extensions/ directory.
# Firefox auto-installs any <addon-id>.xpi found there on first startup.
# Called by scripts/package.sh after ./mach package.
#
# Usage: scripts/package-extensions.sh [objdir-name]
# Default objdir: obj-x86_64-pc-mingw32
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OBJDIR="${1:-obj-x86_64-pc-mingw32}"
FIREFOX_ROOT="/d/dev/antumbra/firefox"
DIST_DIR="${FIREFOX_ROOT}/${OBJDIR}/dist/bin/distribution/extensions"

declare -A EXT_IDS=(
  [ublock-origin]="uBlock0@raymondhill.net"
  [consent-o-matic]="gdpr@cavi.au.dk"
  [multi-account-containers]="@testpilot-containers"
)

mkdir -p "${DIST_DIR}"

for ext_dir in "${REPO_ROOT}/third_party/extensions"/*/; do
  ext_name="$(basename "${ext_dir}")"
  ext_id="${EXT_IDS[$ext_name]:-}"
  if [[ -z "${ext_id}" ]]; then
    echo "WARNING: no extension ID mapping for ${ext_name}; skipping." >&2
    continue
  fi
  xpi_found=0
  for xpi in "${ext_dir}"*.xpi; do
    if [ -f "${xpi}" ]; then
      cp "${xpi}" "${DIST_DIR}/${ext_id}.xpi"
      echo "  Copied ${ext_name} ($(basename "${xpi}")) -> ${ext_id}.xpi"
      xpi_found=1
      break
    fi
  done
  if [[ $xpi_found -eq 0 ]]; then
    echo "WARNING: no .xpi found in ${ext_dir}" >&2
  fi
done

echo "Extensions copied to ${DIST_DIR}"
