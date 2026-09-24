# Security policy

## Response commitment

When Firefox ESR ships a security release, Antumbra aims to ship a corresponding
release within **7 days**. For vulnerabilities rated CVSS 9.0 or higher, the
target is **3 days**.

This commitment starts with the first public build. A fork that lags on security
patches actively harms the people who trusted it, and it starts from day one.

ESR security releases follow a predictable cadence (roughly every 4 weeks, plus
out-of-band fixes for critical issues). That schedule is published by Mozilla and
can be monitored at https://www.mozilla.org/en-US/security/known-vulnerabilities/

## How updates reach you

**Milestone 1 and 2:** Updates are delivered through package managers. Install
Antumbra from one of these sources and it updates through the same channel:

- Windows: winget
- Linux: Flatpak, AUR
- macOS: Homebrew

The browser itself does not update automatically in milestone 1 builds. The
first-run screen says this explicitly. If you installed without a package
manager, check the releases page for new versions.

**From milestone 3 onward:** Antumbra's built-in updater will be available. It
uses Mozilla's MAR signing protocol with a key held by the Antumbra project.
Until it exists, the above package manager paths are the update mechanism.

**What this means in practice:** if you are not using a package manager, you
need to check for updates yourself. A browser that silently stops receiving
security updates is the worst outcome for a privacy-focused project. We will
never let that happen quietly -- release notes will always say what upstream
security issues were fixed.

## Reporting a vulnerability

Do not open a public GitHub issue for a security vulnerability until a fix is
ready and coordinated.

**Preferred path:** GitHub Security Advisories:
https://github.com/antumbra-browser/antumbra-browser/security/advisories/new

This lets you report privately and gives us a space to coordinate disclosure.

**Alternative:** email security@antumbrabrowser.org if that address is active.
If it bounces, use the GitHub advisory flow above.

When reporting, include:

- The Firefox ESR version and Antumbra version affected
- Whether the issue is specific to Antumbra's patches or inherited from upstream
  Firefox (issues inherited from upstream should also be reported to Mozilla at
  https://www.mozilla.org/en-US/security/bug-bounty/)
- Steps to reproduce
- Your assessment of the impact if known

## Scope

This policy covers:

- Antumbra's patch series under `patches/`
- Antumbra's bundled prefs (`prefs/antumbra.js`, `prefs/policies.json`)
- The Antumbra first-party extension (when present)
- The build and release process

It does not cover vulnerabilities in Firefox itself that are not specific to our
changes. Report those to Mozilla directly.

## Known limitations

Antumbra does not have a crash reporter -- it is compiled out. If you encounter
a crash that is reproducible on Antumbra but not on unmodified Firefox ESR, a
detailed manual reproduction report with the exact steps and the version number
is the only way we can investigate it.

Code signing is a milestone 2 deliverable. Milestone 1 builds may trigger
Windows SmartScreen warnings on install. This is expected and documented on the
download page. It does not indicate a problem with the binary.
