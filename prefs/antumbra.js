/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

/* Antumbra privacy baseline prefs -- Milestone 1
 * Applied via JS_PREFERENCE_FILES in browser/app/profile/moz.build,
 * after firefox.js. Verified against FIREFOX_153_3_0esr_RELEASE by
 * scripts/audit-prefs.py. antumbra.* prefs are allowlisted in that script. */

/* --- Tracking and content blocking --- */
pref("browser.contentblocking.category", "strict");
pref("network.cookie.cookieBehavior", 5);
pref("privacy.firstparty.isolate", false); // D1: TCP only; FPI reserved for Totality window
pref("privacy.fingerprintingProtection", true);
pref("privacy.resistFingerprinting", false); // true only in Blackout mode (set by AntumbraMode)
pref("privacy.query_stripping.enabled", true);
pref("privacy.query_stripping.enabled.pbmode", true);

/* --- WebRTC leak protection --- */
pref("media.peerconnection.ice.default_address_only", true);
pref("media.peerconnection.ice.no_host", false); // true in Blackout

/* --- HTTPS --- */
pref("dom.security.https_first", true);
pref("dom.security.https_only_mode", false); // user opt-in

/* --- DNS over HTTPS (mode 2 = TRR-first with fallback) --- */
pref("network.trr.mode", 2);
pref("network.trr.uri", "https://dns.quad9.net/dns-query"); // overwritten by first-run wizard

/* --- Telemetry and data collection --- */
pref("toolkit.telemetry.enabled", false);
pref("toolkit.telemetry.unified", false);
pref("toolkit.telemetry.server", "");
pref("datareporting.healthreport.uploadEnabled", false);
pref("datareporting.policy.dataSubmissionEnabled", false);
pref("browser.ping-centre.telemetry", false);

/* --- Normandy / studies / experiments (D5) --- */
pref("app.normandy.enabled", false);
pref("app.normandy.api_url", "");
pref("app.shield.optoutstudies.enabled", false);

/* --- Safe Browsing: local checks on, remote lookup off (D5) --- */
pref("browser.safebrowsing.downloads.remote.enabled", false);
pref("browser.safebrowsing.provider.google4.updateURL", "");
pref("browser.safebrowsing.provider.google4.gethashURL", "");

/* --- Cookie banner rejection (mode 1 = reject only, never accept) --- */
pref("cookiebanners.service.mode", 1);
pref("cookiebanners.service.mode.privateBrowsing", 1);

/* --- Sponsored content and suggestions off --- */
pref("browser.newtabpage.activity-stream.showSponsored", false);
pref("browser.newtabpage.activity-stream.showSponsoredTopSites", false);
pref("browser.newtabpage.activity-stream.feeds.section.topstories", false);

/* --- Pocket off --- */
pref("extensions.pocket.enabled", false);

/* --- Content recommendations (discovery stream) off --- */
pref("browser.newtabpage.activity-stream.discoverystream.enabled", false);

/* --- Private browsing page: Mozilla promotional content off --- */
pref("browser.vpn_promo.enabled", false);
pref("browser.promo.focus.enabled", false);
pref("browser.promo.pin.enabled", false);
pref("browser.promo.cookiebanners.enabled", false);
pref("browser.search.separatePrivateDefault.ui.enabled", false);

/* --- First run / welcome --- */
pref("browser.aboutwelcome.enabled", false);

/* --- Vertical tabs (confirmed present in ESR 153) --- */
pref("sidebar.verticalTabs", true);
pref("sidebar.revamp", true);

/* --- Antumbra protection mode (new pref; antumbra.* allowlisted in audit-prefs.py) --- */
pref("antumbra.protection.mode", "standard");
