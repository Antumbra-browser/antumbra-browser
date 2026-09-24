/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

/* Antumbra Blackout mode pref delta (ARCHITECTURE.md section 4).
 * Applied by AntumbraMode.sys.mjs when antumbra.protection.mode = "blackout".
 * Chrome accent: pure #000000, no accent color (BRANDING.md section 6).
 */

// ETP strict.
pref("browser.contentblocking.category", "strict");

// RFP on in Blackout (user has accepted breakage; this is the Tor Browser approach).
// Provides letterboxing, timezone spoofing, canvas noise. See ARCHITECTURE.md 5.3.
pref("privacy.resistFingerprinting", true);
pref("privacy.fingerprintingProtection", true);
pref("privacy.fingerprintingProtection.pbmode", true);

// WebRTC: restrict in Blackout. Disable host candidates; TURN-only via proxy if set.
pref("media.peerconnection.ice.default_address_only", true);
pref("media.peerconnection.ice.no_host", true);
pref("media.peerconnection.ice.proxy_only_if_behind_proxy", true);

// FPI off globally (D1); only Totality window enables it per-context.
pref("privacy.firstparty.isolate", false);

// DNS: mode 2 by default; mode 3 offered in UI with a warning (breaks captive portals).
pref("network.trr.mode", 2);

// Query stripping: enabled (same as Strict; maximum lists selected via uBO).
pref("privacy.query_stripping.enabled", true);
pref("privacy.query_stripping.enabled.pbmode", true);
