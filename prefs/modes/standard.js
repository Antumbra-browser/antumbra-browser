/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

/* Antumbra Standard mode pref delta (ARCHITECTURE.md section 4).
 * Applied by AntumbraMode.sys.mjs when antumbra.protection.mode = "standard".
 * These prefs extend the baseline in antumbra.js; they are NOT the full pref set.
 * Chrome accent: --ash (#8B95A3). Dark disc, thin ash ring (BRANDING.md section 6).
 */

// ETP strict (baseline also sets this; explicit here for mode clarity).
pref("browser.contentblocking.category", "strict");

// FPP on, RFP off in Standard (RFP reserved for Blackout/Totality per ARCHITECTURE.md 5.3).
pref("privacy.fingerprintingProtection", true);
pref("privacy.fingerprintingProtection.pbmode", true);
pref("privacy.resistFingerprinting", false);
pref("privacy.resistFingerprinting.letterboxing", false);

// WebRTC: block local address enumeration, keep WebRTC functional.
pref("media.peerconnection.ice.default_address_only", true);
pref("media.peerconnection.ice.proxy_only_if_behind_proxy", true);
pref("media.peerconnection.enabled", true);

// FPI off in Standard (D1: TCP covers this use case).
pref("privacy.firstparty.isolate", false);

// DNS: TRR mode 2, not mode 3 (captive portal compatibility per ARCHITECTURE.md 5.7).
pref("network.trr.mode", 2);

// Query stripping: baseline strip list.
pref("privacy.query_stripping.enabled", true);
pref("privacy.query_stripping.enabled.pbmode", true);
