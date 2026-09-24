# Contributing to Antumbra

Antumbra is MPL 2.0. By contributing, you agree that your changes will be
licensed under the same terms.

## Standing rules (non-negotiable)

These rules apply to all contributors, all maintainers, and all future versions
of the project. They are recorded here rather than in comments or changelogs so
they survive personnel changes and cannot be quietly revised.

### No cryptocurrency, no rewards, no sponsored content

Antumbra will never include:

- A cryptocurrency wallet, token, or rewards program of any kind.
- Sponsored tiles, curated top sites, or a new-tab news feed.
- Content recommendations, a discovery panel, or anything that serves
  suggestions to a user who did not ask for them.
- An ad network of our own.

These are non-goals of the project (ARCHITECTURE.md section 1.1). Removing any
of them would require a new decision recorded in DECISIONS.md and a public
explanation, not a code change alone.

The VPN affiliate button described in ARCHITECTURE.md section 6.6 is the only
planned affiliate feature in the roadmap. It ships in milestone 7 -- after the
browser has an established privacy record -- with mandatory disclosure in the
panel itself. Its implementation is subject to CI enforcement that no partner
ID can reach a user-initiated navigation (ARCHITECTURE.md section 2.3). That
test is permanent and does not depend on milestone sequencing.

### Do not modify bundled GPLv3 extensions

uBlock Origin (GPLv3) is bundled unmodified. Modifying it and keeping the name
would change the licensing analysis (ARCHITECTURE.md section 11.2). If uBlock
Origin needs different behavior, configure it through its own settings and
filter lists. Never patch it.

The same rule applies to Consent-O-Matic (MIT) and Multi-Account Containers
(MPL 2.0). Bundled extensions are distributed as-is from their upstream sources.

### Firefox builds on the local Windows machine only

GitHub-hosted CI runners must not attempt a Firefox build. They have neither the
disk space nor the time limit (ARCHITECTURE.md section 10.2, decision D7). The
fast-lane CI jobs run without a Firefox build. Full builds happen on the
maintainer's Windows machine or on the self-hosted runner registered from
milestone 2 onward.

Patches to the Firefox tree are submitted as unified diff files under
`patches/`. The CI patch-apply-check job verifies they apply cleanly to the
pinned ESR tag without running the build.

## How to contribute

1. Open an issue describing the change and which ROADMAP.md milestone it
   addresses.
2. Fork the repository and create a branch named
   `milestone-N-short-description`.
3. Changes to the Firefox source tree must be submitted as patch files under
   `patches/`. Never include modifications to the Firefox tree directly in a
   pull request -- provide the patch file, not the modified source.
4. All new prefs in `prefs/antumbra.js` must exist in the upstream ESR tree at
   the pinned tag. The pref audit CI job enforces this on every push.
   Prefs with the `antumbra.` prefix are allowlisted -- they are Antumbra-specific
   and are not expected in the upstream tree.
5. Add rows to THIRD-PARTY.md for any new bundled component, including its
   version, license, and source URL.
6. Decisions that affect the project's direction belong in DECISIONS.md, not
   in code comments or PR descriptions. If your change requires a decision,
   add it there before writing the code.
7. Open a pull request. The fast-lane CI must pass before review.

## Decisions and DECISIONS.md

DECISIONS.md is the authoritative record of why the project is built the way it
is. When DECISIONS.md and any other file (ARCHITECTURE.md, ROADMAP.md, a GSD
plan file) disagree, DECISIONS.md is correct and the other file is stale.

If a contribution reverses an existing decision, it must add a new entry to
DECISIONS.md explaining the reasoning. Editing history is not acceptable --
add a superseding entry.

## Security vulnerabilities

Report security issues per SECURITY.md. Do not open a public issue for
a vulnerability until a fix is ready.

## Style

- No em dashes. Use a hyphen or rephrase the sentence.
- Patch commit messages: `patches: short description (patch-file-name)`.
- Keep patches small and single-purpose. A 20-line patch is easy to rebase;
  a 500-line patch is a rebase hazard.
