/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

/* Antumbra Strict mode pref delta (ARCHITECTURE.md section 4).
 * Applied by AntumbraMode.sys.mjs when antumbra.protection.mode = "strict".
 * Chrome accent: --corona (#FFB020). Dark disc, full corona ring with glow (BRANDING.md section 6).
 */

// ETP strict (same as Standard).
pref("browser.contentblocking.category", "strict");

// FPP on, RFP still off (site breakage too high for default; user-togglable per ARCHITECTURE.md 5.3).
pref("privacy.fingerprintingProtection", true);
pref("privacy.fingerprintingProtection.pbmode", true);
pref("privacy.resistFingerprinting", false);

// WebRTC: same as Standard (no_host breaks local video calls; wrong default for non-technical users).
pref("media.peerconnection.ice.default_address_only", true);
pref("media.peerconnection.ice.proxy_only_if_behind_proxy", true);
pref("media.peerconnection.enabled", true);

// FPI off in Strict (D1: TCP covers this; FPI causes SSO breakage).
pref("privacy.firstparty.isolate", false);

// DNS: TRR mode 2 (same as Standard).
pref("network.trr.mode", 2);

// Query stripping: aggressive (Strict adds regional and extra privacy lists via uBO).
pref("privacy.query_stripping.enabled", true);
pref("privacy.query_stripping.enabled.pbmode", true);
