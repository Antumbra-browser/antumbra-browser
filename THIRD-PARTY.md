# Third-party components

Every bundled third-party component is listed here with its version, license,
and corresponding source location. This file is a compliance artifact for the
GPLv3 and other license obligations described in ARCHITECTURE.md section 11.2.

See docs/extension-update-process.md for the XPI version refresh procedure
(every 4 weeks and at every Antumbra release).

## Bundled extensions

| Component | Version | License | Extension ID | Source URL | Notes |
|-----------|---------|---------|--------------|------------|-------|
| uBlock Origin | 1.75.0 | GPLv3 | uBlock0@raymondhill.net | https://github.com/gorhill/uBlock | Vendored unmodified. Do not patch. Ship unmodified, include license, provide corresponding source per ARCHITECTURE.md 6.2. |
| Consent-O-Matic | 1.1.5 | MIT | gdpr@cavi.au.dk | https://github.com/cavi-au/Consent-O-Matic | Aarhus University. Vendored unmodified. |
| Multi-Account Containers | 8.3.8 | MPL 2.0 | @testpilot-containers | https://github.com/mozilla/multi-account-containers | Mozilla project. Vendored unmodified. Displays "Firefox Multi-Account Containers" in its own UI -- see ROADMAP.md Milestone 4 (native container UI replacement). |

## SHA-256 hashes (at time of vendoring)

| Component | Version | SHA-256 |
|-----------|---------|---------|
| uBlock Origin | 1.75.0 | 5b74415860456370644bd80f16125e865b0e6c356bb5dfcfb84069967eaa5287 |
| Consent-O-Matic | 1.1.5 | a2119abc329638d6e7af1ab4e5548a348465e02eec11de08dee0af84919923dc |
| Multi-Account Containers | 8.3.8 | 306a294845363f15a7478e9620b43f91ea1761088727808e2327bfff16c14447 |

## License obligations summary

| Component | License | Obligations |
|-----------|---------|-------------|
| uBlock Origin | GPLv3 | Ship unmodified; include LICENSE; make corresponding source available for this exact version. Source: https://github.com/gorhill/uBlock/releases/tag/1.75.0 |
| Consent-O-Matic | MIT | Attribution. LICENSE file included. |
| Multi-Account Containers | MPL 2.0 | Keep MPL 2.0 headers. LICENSE file included. |

The GPLv3 extensions (uBlock Origin) are separate programs distributed alongside
Antumbra, not linked into its binary. This is mere aggregation. Our obligations
are: distribute unmodified, include the license, and make corresponding source
available for the exact version shipped. See ARCHITECTURE.md section 11.2.
