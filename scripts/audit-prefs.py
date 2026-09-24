#!/usr/bin/env python3
"""audit-prefs.py -- Verify every pref in antumbra.js exists in the upstream Firefox tree.

Usage:
    python audit-prefs.py --prefs prefs/antumbra.js --firefox-src PATH

    --prefs         Path to prefs/antumbra.js (required).
    --firefox-src   Path to the Firefox source tree. Defaults to ../firefox
                    relative to the antumbra-browser repository root.

Exit 0: all prefs found or allowlisted.
Exit 1: one or more prefs not found in the upstream tree.

Prefs with the "antumbra." prefix are allowlisted -- they are Antumbra-specific
and do not exist in the upstream tree. All other prefs are checked.

Per ARCHITECTURE.md section 2.2: a pref that no longer exists upstream is
silently ignored by Firefox, so the protection it was meant to set quietly
disappears. This script is the difference between a claimed protection and
a real one. It is the highest-value CI job in the project.
"""

import argparse
import re
import sys
from pathlib import Path

# Prefs with these prefixes are Antumbra-specific. They do not exist upstream
# and are intentionally absent from the upstream pref files.
ALLOWLISTED_PREFIXES = ["antumbra."]

# Upstream pref files to search, relative to the Firefox source root.
UPSTREAM_PREF_FILES = [
    "browser/app/profile/firefox.js",
    "modules/libpref/init/all.js",
    "modules/libpref/init/StaticPrefList.yaml",
    "browser/app/profile/channel-prefs.js",
]


def extract_pref_names(prefs_file: Path) -> list[str]:
    """Extract pref names from a .js pref file (pref("name", value) pattern)."""
    text = prefs_file.read_text(encoding="utf-8")
    pattern = re.compile(r'\bpref\s*\(\s*["\']([^"\']+)["\']')
    return pattern.findall(text)


def is_allowlisted(pref_name: str) -> bool:
    return any(pref_name.startswith(prefix) for prefix in ALLOWLISTED_PREFIXES)


def search_pref_in_files(pref_name: str, search_paths: list[Path]) -> bool:
    """Return True if pref_name appears as a quoted string in any of the paths."""
    escaped = re.escape(pref_name)
    pattern = re.compile(r'["\']' + escaped + r'["\']')
    for path in search_paths:
        if not path.exists():
            continue
        try:
            text = path.read_text(encoding="utf-8", errors="ignore")
        except OSError:
            continue
        if pattern.search(text):
            return True
    return False


def main() -> None:
    parser = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument(
        "--prefs",
        required=True,
        type=Path,
        help="Path to prefs/antumbra.js",
    )
    parser.add_argument(
        "--firefox-src",
        type=Path,
        default=None,
        help="Path to the Firefox source tree",
    )
    args = parser.parse_args()

    if not args.prefs.exists():
        print(f"ERROR: prefs file not found: {args.prefs}", file=sys.stderr)
        sys.exit(1)

    if args.firefox_src is None:
        script_dir = Path(__file__).parent
        args.firefox_src = script_dir.parent.parent / "firefox"

    firefox_src = args.firefox_src
    search_paths = [firefox_src / rel for rel in UPSTREAM_PREF_FILES]
    available = [p for p in search_paths if p.exists()]

    if not available:
        print(
            f"ERROR: no upstream pref files found under {firefox_src}",
            file=sys.stderr,
        )
        print(
            "  Expected at least one of:",
            file=sys.stderr,
        )
        for p in search_paths:
            print(f"    {p}", file=sys.stderr)
        sys.exit(1)

    pref_names = extract_pref_names(args.prefs)
    print(f"Auditing {len(pref_names)} pref(s) from {args.prefs}")
    print(f"Searching {len(available)} upstream pref file(s) under {firefox_src}")

    found: list[str] = []
    allowlisted: list[str] = []
    missing: list[str] = []

    for name in pref_names:
        if is_allowlisted(name):
            allowlisted.append(name)
        elif search_pref_in_files(name, available):
            found.append(name)
        else:
            missing.append(name)

    print(f"  Found:       {len(found)}")
    print(f"  Allowlisted: {len(allowlisted)}  (antumbra.* -- not expected upstream)")
    print(f"  Missing:     {len(missing)}")

    if allowlisted:
        print("Allowlisted prefs (Antumbra-specific):")
        for name in allowlisted:
            print(f"  {name}")

    if missing:
        print("\nMISSING PREFS -- not found in upstream ESR 153 tree:", file=sys.stderr)
        for name in missing:
            print(f"  MISSING: {name}", file=sys.stderr)
        print(
            "\nThese prefs no longer exist upstream and will be silently ignored.",
            file=sys.stderr,
        )
        print(
            "Remove them from prefs/antumbra.js or add them to ALLOWLISTED_PREFIXES.",
            file=sys.stderr,
        )
        sys.exit(1)

    print("Pref audit PASSED.")
    sys.exit(0)


if __name__ == "__main__":
    main()
