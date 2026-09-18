# Antumbra: architecture

**Status: draft for review.** Written 2026-09-18 against the feature spec.
Naming throughout follows [BRANDING.md](BRANDING.md).

This document describes how Antumbra is built: the fork strategy, how each
feature in the spec is implemented, what it costs a solo developer to build and
to keep alive across Firefox releases, and where it will break sites. It is a
plan, not a description of existing code. Nothing here has been built yet.

Companion documents: [ROADMAP.md](ROADMAP.md) sequences this work into
milestones, and [DECISIONS.md](DECISIONS.md) records the decisions behind it with
their reasoning. Where this document says "decided", DECISIONS.md says why.

---

## 1. What Antumbra is

A minimal-patch fork of Firefox (Gecko), licensed MPL 2.0, targeting three
things at once:

- **LibreWolf-level privacy.** Hardened defaults, no telemetry, no sponsored
  content, no phone-home that the user did not ask for.
- **Zen-level design.** Vertical tabs, split view, web panels, a browser that
  looks deliberate rather than defaulted.
- **Onboarding simple enough for a non-technical user.** This is the hard one.
  LibreWolf assumes you can read `about:config`. Antumbra must not.

The third goal is the constraint that shapes every decision below. A privacy
browser that only works for people who already understand trackers is a
configuration file with a logo on it.

### 1.1 Non-goals

Stated here so they do not get relitigated. From the spec, section 9:

- No crypto wallet, no token, no rewards program.
- No sponsored tiles, no ad network of our own.
- No new tab news feed, no content recommendations.

And some of our own:

- **Not a Tor Browser replacement.** The Totality window improves your position;
  it does not make you anonymous. This is stated in the UI, not buried in docs.
- **Not a Chromium fork.** Gecko keeps blocking `webRequest`, which is what
  makes real content blocking possible. That is the whole reason to be here.
- **Not a full rewrite of Firefox's interface.** Every line of chrome we patch
  is a line we re-patch forever.

---

## 2. Principles

### 2.1 Use the lowest layer that works

Five layers, cheapest first. A feature goes at the highest-numbered layer only
when every layer below it genuinely cannot do the job.

| Layer | Mechanism | Per-release cost | Notes |
|---|---|---|---|
| 1 | **Default prefs** baked into the source pref file | Very low: audit that the pref still exists | Users can still change them. Preferred. |
| 2 | **Enterprise policy** (`policies.json`) | Very low | For things prefs cannot do: bundling extensions, disabling the updater in distro builds. |
| 3 | **Bundled third-party extension** | Low: version bumps, license review | No Gecko knowledge needed. Isolated blast radius. |
| 4 | **First-party in-tree extension** (ours, MPL 2.0) | Low to medium | WebExtension APIs are stable across releases. Much cheaper than chrome JS. |
| 5a | **Chrome patch** (`browser/`, front end JS and XHTML) | Medium to high | Breaks when upstream restructures the interface. |
| 5b | **Gecko patch** (`dom/`, `netwerk/`, `toolkit/`, C++) | High | Breaks on refactors. Needs real Gecko knowledge to fix. |

Layers 1 and 2 are the difference between a project a solo developer can sustain
and one that dies at the third rebase. **Roughly 70 percent of the spec is
achievable at layers 1 to 4.** The remainder is where the maintenance budget
goes, so it is spent deliberately.

### 2.2 Prefs are not free

A common mistake in hardened-Firefox projects is treating prefs as
zero-maintenance. They are not. Upstream removes and renames prefs regularly
(`network.cookie.lifetimePolicy` was removed; First-Party Isolation is being
retired). A pref that no longer exists is silently ignored, so the protection
quietly disappears and nothing warns you.

**Mitigation: an automated pref audit in CI.** See section 10.3. Every pref we
set is checked against the upstream tree on every build. An unknown pref fails
the build.

### 2.3 Never rewrite what the user typed

A hard rule, stated here because section 7 of the spec introduces affiliate
links and this is exactly how that goes wrong. Brave appended affiliate codes to
user-typed URLs in 2020 and spent years paying for it.

**Antumbra never modifies a URL the user entered, autocompleted, clicked, or
bookmarked, for any commercial reason, ever.** Affiliate links exist only as the
destination of a button the user deliberately presses, in a panel that says it
is affiliate marketing. There is no code path from the address bar to a partner
ID. This rule is enforceable in CI as a test.

### 2.4 Privacy claims must be falsifiable

Every protection gets a way for a skeptical user to verify it. The privacy
dashboard (section 6.8) is not decoration: it is the evidence. If we cannot show
what a feature did, we should think harder about whether it did anything.

---

## 3. Fork strategy

### 3.1 A patch series, not a forked tree

**Decided (D6): maintain a patch series applied to a pinned upstream tag, not a
long-lived fork of mozilla-central.**

This is the single most important structural decision in the project. The
alternative, a permanent branch of the Firefox tree that you merge upstream into
periodically, is how solo browser forks die. Conflict resolution in a 20-million
line tree with an opaque history is unbounded work.

With a patch series:

- Every change we make is an explicit, reviewable, individually named patch.
- A rebase failure is scoped to one patch, and you can see exactly what upstream
  changed underneath it.
- A patch that becomes too expensive can be dropped, and the feature degrades
  visibly instead of the tree silently rotting.
- The cost of each feature is legible: it is the size and fragility of its
  patch. That makes section 2.1 enforceable rather than aspirational.

LibreWolf works this way and is maintained by a small volunteer team. That is
the existence proof.

### 3.2 Upstream base: ESR or Release

| | **Firefox ESR** | **Firefox Release** |
|---|---|---|
| Major rebase | Once a year | Every 4 weeks |
| Security updates | Every 4 weeks, plus out-of-band | Every 4 weeks, plus out-of-band |
| Patch conflict risk | Concentrated into one painful annual window | Spread thin, constant |
| Feature lag | Up to 12 months behind | None |
| Realistic solo-dev load | 1 hard week per year plus light monthly work | 1 to 3 days every 4 weeks, forever |

**Decided (D6): base on ESR.** The annual rebase is a scheduled, bounded event
that can be planned around. The 4-week treadmill is not, and it is the thing most
likely to end the project in year one.

The cost is real and should be understood: privacy improvements that land in
Release (new fingerprinting protection targets, cookie banner rule updates,
sandbox hardening) reach Antumbra up to a year late. Two mitigations:

1. Security fixes are **not** delayed. ESR receives the same security patches on
   the same day. The lag is features, not safety.
2. Where a specific upstream privacy feature matters and has not reached ESR,
   backport it as its own patch. That is a deliberate, costed decision per
   feature rather than a standing commitment to the release train.

Revisit this decision if the project gains a second full-time maintainer.

### 3.3 Upstream source

Mozilla now publishes the canonical Firefox tree on Git. Track a specific
release tag, pinned in a single file (`upstream.conf`), and bump it as an
explicit commit. Never track a moving branch: the build must be reproducible
from the repository state alone.

---

## 4. Protection modes

BRANDING.md defines four visual modes. They are not four independent settings:
**one "protection mode" setting drives everything.** This is the core of making
the browser comprehensible to a non-technical user.

| Mode | ETP / prefs | uBlock Origin filter set | Chrome accent | Icon variant |
|---|---|---|---|---|
| **Standard** | Strict ETP, TCP on, RFP off | Default lists plus privacy and annoyance lists | `--ash` neutral | Dark disc, thin `--ash` ring |
| **Strict** | Plus fingerprinting protection, query stripping aggressive | Default plus regional plus extra privacy | `--corona` amber | Dark disc, full `--corona` ring with glow |
| **Blackout mode** | Everything, RFP on, third-party frames restricted | Maximum, all annoyance and hardening lists | Pure `#000000`, no accent | Pure black disc, `--penumbra` hairline, no ring |
| **Totality window** | Blackout plus Tor routing, per-window | As Blackout | `--relay` violet | Ring with three `--relay` dots |

The user picks one thing at first run and sees one visual language reflect it
everywhere: the icon, the toolbar color, the shield. Removing color in Blackout
mode is the signal that everything else was removed too, exactly as BRANDING.md
specifies.

Standard and Strict are per-profile. Totality is per-window. Blackout mode is
per-profile with a per-site step-down, because a mode you cannot escape from is
a mode users turn off permanently after the first broken site.

**Implementation:** a single pref `antumbra.protection.mode` (`standard`,
`strict`, `blackout`), read by a chrome patch that applies the pref set and the
accent, and by the first-party extension that swaps uBlock Origin's filter
selection. Complexity: medium. This is the one place where centralizing is worth
a patch.

---

## 5. Spec section 1: tracker isolation

### 5.1 Enhanced Tracking Protection, strict

**Layer 1, prefs only.**

```
browser.contentblocking.category = "strict"
privacy.trackingprotection.enabled = true
privacy.trackingprotection.socialtracking.enabled = true
privacy.trackingprotection.cryptomining.enabled = true
privacy.trackingprotection.fingerprinting.enabled = true
privacy.trackingprotection.emailtracking.enabled = true
```

Setting `browser.contentblocking.category` to `strict` is what makes the
Settings UI show "Strict" rather than "Custom". Setting the individual prefs
without it produces a browser that claims to be in a custom configuration, which
is confusing for the audience we are targeting. Set both.

Complexity: **trivial.** Maintenance: **very low.** Breakage: **low to medium**,
and it is upstream's breakage, shared with every Firefox user on Strict, which
means site operators already test against it.

### 5.2 Total Cookie Protection and First-Party Isolation

**Layer 1, prefs. Decided (D1).**

The original spec asked for Total Cookie Protection **and** First-Party
Isolation. These are two generations of the same idea and they should not both be
on.

- **First-Party Isolation** (`privacy.firstparty.isolate`) is the older, blunter
  mechanism, inherited from Tor Browser's work. It is effectively deprecated
  upstream, is not well tested in combination with modern code paths, and breaks
  federated login broadly.
- **Total Cookie Protection** (dynamic First-Party Isolation,
  `network.cookie.cookieBehavior = 5`) is its supported successor. It gives
  substantially the same partitioning with heuristics that keep common login
  flows working, and it is what Firefox ships on Strict. Tor Browser itself
  migrated from FPI to dFPI.

**Decided: ship Total Cookie Protection everywhere. First-Party Isolation is
off in Standard, Strict, and Blackout mode, and enabled only inside the Totality
window.** Enabling both globally produces unpredictable interactions and a worse
user experience for no measurable privacy gain.

```
network.cookie.cookieBehavior = 5
privacy.partition.network_state = true
privacy.partition.serviceWorkers = true
privacy.partition.always_partition_third_party_non_cookie_storage = true
privacy.firstparty.isolate = false
```

The Totality window sets `privacy.firstparty.isolate = true` on top of the
above. That is the one context where the user has already accepted that things
will break, and where breakage is expected for unrelated reasons anyway (blocked
exit nodes, CAPTCHAs). It is a one-line addition to the Totality window profile,
not a global default. If upstream removes the pref entirely, the Totality window
loses that single extra guarantee and nothing else changes.

Complexity: **trivial.** Maintenance: **low**, watch for the eventual removal of
the FPI pref entirely. Breakage: **medium**, mostly single-sign-on and embedded
payment flows. The per-site exception UI (section 5.4) is the release valve.

### 5.3 Fingerprinting resistance

**Layer 1 for the engine, layer 5a for the per-site UI.**

Two mechanisms exist upstream and they are different:

- **RFP** (`privacy.resistFingerprinting`): the Tor Browser approach. Lies about
  timezone, screen size, language, fonts, and more. Strong, and visibly breaks
  things: letterboxed windows, wrong timezone in calendar apps, broken canvas
  rendering.
- **FPP** (`privacy.fingerprintingProtection`, with granular per-target
  overrides): the newer, targeted system Firefox ships in Strict ETP and private
  windows. Weaker, far less breakage.

**Mapping to modes:** Standard and Strict use FPP. Blackout mode and Totality
window turn on RFP.

```
privacy.fingerprintingProtection = true
privacy.fingerprintingProtection.pbmode = true
privacy.resistFingerprinting = false        # true in Blackout and Totality
privacy.resistFingerprinting.letterboxing = false
```

**Per-site exceptions** are the hard part. Upstream exposes
`privacy.resistFingerprinting.exemptedDomains` (a comma-separated pref) and
per-domain FPP overrides (a JSON pref). Neither has user-facing UI. Writing a
comma-separated domain list in `about:config` is precisely the experience
Antumbra exists to avoid.

Implementation: a toggle in the shield panel, "This site is broken, relax
protections here", that writes the exemption pref and reloads. Layer 5a, a
small, self-contained chrome patch.

Complexity: **low** for the prefs, **medium** for the panel UI. Maintenance:
**medium**, the panel patch touches front end code upstream reorganizes.
Breakage with RFP: **high**, which is why RFP is not on in Standard.

### 5.4 WebRTC leak protection

**Layer 1, prefs.**

```
media.peerconnection.ice.default_address_only = true
media.peerconnection.ice.proxy_only_if_behind_proxy = true
media.peerconnection.enabled = true
```

`default_address_only` stops the local network address enumeration that leaks
your LAN and real IP behind a VPN, while leaving WebRTC functional. The stronger
options (`ice.no_host = true`, or disabling WebRTC entirely) break video calling
on local networks and are wrong as a default for a browser aimed at
non-technical users. Reserve them for Blackout mode and Totality.

Complexity: **trivial.** Maintenance: **very low.** Breakage: **low** in
Standard, **high** if WebRTC is disabled outright, which is why it is not.

### 5.5 Tracking parameter stripping

**Layer 1 plus layer 3.**

Firefox has built-in query stripping, but its list is deliberately short:

```
privacy.query_stripping.enabled = true
privacy.query_stripping.enabled.pbmode = true
privacy.query_stripping.strip_list = <extended list>
```

For real coverage, add the **AdGuard URL Tracking Protection** filter list to the
bundled uBlock Origin rather than shipping a second extension such as ClearURLs.
uBlock Origin's `removeparam` syntax handles this well, the list is maintained
by someone else, and it costs us one checkbox instead of another dependency,
another update channel, and another license to track.

Complexity: **trivial.** Maintenance: **very low.** Breakage: **low to medium.**
Stripping is occasionally wrong: some sites genuinely use `fbclid`-adjacent
parameters for routing, and stripped parameters can break "click this email link
to confirm" flows. Per-site disable lives in the same panel as 5.3.

### 5.6 Redirect and AMP bypass

**Layer 4, first-party extension.**

Two related behaviors:

- **Redirect bypass:** skip interstitial trackers (`out.reddit.com`,
  `l.facebook.com`, link shims) and go straight to the destination.
- **AMP bypass:** when a link points to a Google AMP wrapper, rewrite it to the
  publisher's canonical URL before navigating.

There are existing extensions for both, but they are GPL-licensed, separately
maintained, and add two more things to audit. This is small, well-understood
logic, so **write it in-tree as part of the Antumbra extension** (section 9.3),
MPL 2.0, sharing the panel and the mode plumbing with everything else.

Design notes that matter:

- Rewrite **before** the request leaves, using `webRequest.onBeforeRequest`, not
  after the page loads. Rewriting after load means the tracker already saw you.
- AMP canonical extraction must not require loading the AMP page. Use the URL
  pattern where possible (`google.com/amp/s/<canonical>`), and fall back to
  leaving it alone rather than guessing.
- Never rewrite inside a page's own navigation logic (SPA route changes), only
  top-level document requests.

Complexity: **medium**, maybe a week including tests. Maintenance: **low**,
WebExtension APIs are stable. Breakage: **medium**. Redirect shims sometimes
carry authentication state, and a stripped shim produces a login loop. Ship an
exclusion list and make it per-site overridable.

### 5.7 Encrypted DNS with a first-run resolver picker

**Layer 1 for the engine, layer 5a for the picker.**

```
network.trr.mode = 2
network.trr.uri = <user's choice>
network.trr.custom_uri = <same>
network.trr.disable-ECS = true
network.dns.echconfig.enabled = true
```

**Use mode 2 (TRR-first with fallback), not mode 3 (TRR-only).** Mode 3 breaks
captive portals, which means the browser stops working on hotel and airport
wifi, which for a non-technical user means the browser is broken. Offer mode 3
in Blackout mode with a clear warning.

The picker is the interesting part. Firefox's built-in provider list comes from
Mozilla's Remote Settings and reflects Mozilla's TRR partner program, which is
Mozilla's business relationship, not ours. Ship our **own static list** instead,
in-tree, with an honest one-line description of each resolver's jurisdiction and
logging policy, plus:

- **"Use my system resolver"** as a real, non-scary option, correctly explained.
  For a user on a trusted network with Pi-hole or an ISP they do not distrust,
  this is a legitimate choice and hiding it is dishonest.
- **A custom URL field** for people who run their own.

Selecting a default for the user is a genuine editorial decision with privacy
consequences and it should be documented in the repository, not made quietly.

Complexity: **low** for prefs, **medium** for the first-run picker UI (shared
with the rest of onboarding). Maintenance: **low**, plus periodically rechecking
that the resolvers we recommend still deserve it. Breakage: **low** on mode 2.

### 5.8 Zero telemetry

**Layer 1 plus build flags. Build flags matter more.**

Prefs can be flipped back by a bug, a profile migration, or an upstream default
change. Compiling the code out cannot.

Build flags in the mozconfig:

```
ac_add_options --disable-crashreporter
ac_add_options --disable-parental-controls
ac_add_options --disable-default-browser-agent
export MOZ_TELEMETRY_REPORTING=0
export MOZ_DATA_REPORTING=0
export MOZ_SERVICES_HEALTHREPORT=0
export MOZ_NORMANDY=0
export MOZ_CRASHREPORTER=0
export MOZ_TELEMETRY_ON_BY_DEFAULT=0
```

Prefs as a second layer (belt and braces):

```
toolkit.telemetry.enabled = false
toolkit.telemetry.unified = false
toolkit.telemetry.archive.enabled = false
toolkit.telemetry.server = "data:,"
datareporting.healthreport.uploadEnabled = false
datareporting.policy.dataSubmissionEnabled = false
app.shield.optoutstudies.enabled = false
app.normandy.enabled = false
app.normandy.api_url = ""
browser.ping-centre.telemetry = false
browser.discovery.enabled = false
browser.newtabpage.activity-stream.telemetry = false
browser.newtabpage.activity-stream.feeds.telemetry = false
toolkit.coverage.opt-out = true
toolkit.coverage.endpoint.base = ""
```

Also removed: sponsored content, Pocket integration (which upstream is retiring
anyway), and Mozilla's search partner codes, which must be stripped from the
bundled search plugins or we are quietly monetizing users through a third party
while claiming not to.

**The decision this raises: what about Remote Settings?**

Firefox's Remote Settings (`services.settings`) is a periodic fetch from Mozilla
infrastructure. It is not telemetry: it is a download, not an upload. But it is a
regular connection to Mozilla that a user on a zero-telemetry browser may not
expect. It carries:

- Cookie banner rules (required for spec section 2, layer 1)
- Certificate revocation data (CRLite) and intermediate certificate preloading
- Tracking protection list updates
- The public suffix list and HSTS preload updates
- Also, the things we do not want: Normandy recipes, study definitions

**Decided (D5): keep Remote Settings on, disable Normandy and studies
specifically, and document the connection prominently in the onboarding and the
dashboard.** Turning it off costs real security (stale revocation data is a
genuine risk) to buy a purity claim. Self-hosting a Remote Settings mirror is the
correct long-term answer and belongs in a later milestone, not milestone 1.

Same reasoning for **Safe Browsing**, and decided the same way (D5): keep the
local list-based malware and phishing checks on, because our audience is exactly the audience that gets
phished, but turn off the per-download remote lookup that sends URLs to Google:

```
browser.safebrowsing.malware.enabled = true
browser.safebrowsing.phishing.enabled = true
browser.safebrowsing.downloads.remote.enabled = false
browser.safebrowsing.downloads.remote.block_potentially_unwanted = false
```

This is a defensible, explainable position and it should be explained, not
hidden. A privacy browser that silently removes phishing protection from
non-technical users has made them less safe overall.

Complexity: **low.** Maintenance: **low**, with the pref audit catching renames.
Breakage: **none**, except that the crash reporter being compiled out means we
have no crash data at all, ever. That is the price of the claim, and it makes
reproducible user bug reports much more important.

---

## 6. Spec sections 2 to 9: desktop features

### 6.1 Cookie consent, three layers

The most valuable feature in the spec and the most likely to generate support
load. Three independent mechanisms, each with a different failure mode.

#### Layer A: auto-reject

**Layer 1 plus layer 3.**

Firefox has built-in cookie banner handling:

```
cookiebanners.service.mode = 1                  # reject only, never accept
cookiebanners.service.mode.privateBrowsing = 1
cookiebanners.bannerClicking.enabled = true
cookiebanners.cookieInjection.enabled = true
```

**Mode 1, never mode 2.** Mode 2 permits auto-accepting when rejection is not
available, which is the opposite of what a privacy browser should do on the
user's behalf. The spec is right to forbid it and the pref makes it a one-line
guarantee.

Bundle **Consent-O-Matic** (MIT, Aarhus University) alongside it. The two have
different rule sets and different coverage; running both catches more banners
than either alone. Consent-O-Matic's rules are declarative JSON, updated
independently of the extension.

Conflict risk: both trying to click the same banner. In practice they settle,
but this needs real testing on a corpus of sites, and if it turns out to be
messy, Consent-O-Matic should run and Firefox's service should drop to
`detectOnly`.

Complexity: **low.** Maintenance: **low**, version bumps and a rules pin.
Breakage: **low to medium**, occasional double-click on a banner or a rejection
that a site handles badly.

#### Layer B: hide what layer A missed

**Layer 3, uBlock Origin annoyance filter lists.**

Enable the cookie notice lists in the bundled uBlock Origin. Critical
distinction to communicate honestly in the UI:

> **Hiding a banner is not rejecting it.** The banner is gone from your screen.
> The site may still treat you as having not decided, or in some jurisdictions
> and implementations, as having accepted by continuing.

This is why layer C exists. A browser that hides banners and calls it consent
management is lying to its users, and the per-site panel must distinguish
"rejected" from "hidden" for exactly this reason.

Complexity: **trivial.** Maintenance: **very low.** Breakage: **medium.**
Cosmetic filters hide elements by selector and sometimes catch page furniture, or
leave `overflow: hidden` on the body so the page cannot scroll. uBlock Origin's
lists handle most of this, but it is the most common cosmetic-filter complaint.

#### Layer C: enforce by clearing

**Layer 4, first-party extension. The hard one.**

On tab close, clear non-essential first-party cookies for that site, using the
**Open Cookie Database** to decide what is essential.

Design constraints that are not optional:

1. **Cookies are not the whole story.** Clear `localStorage`, `sessionStorage`,
   IndexedDB, Cache API, and service worker registrations for the origin too, or
   the site rebuilds its identifier on the next visit and the feature is
   theater.
2. **Classification is heuristic and will be wrong.** The Open Cookie Database
   keys on cookie names and known patterns. It does not and cannot know what an
   arbitrary site's `sid` cookie does. Unknown cookies must default to a
   documented, conservative choice.
3. **"Tab close" is ambiguous.** A site open in three tabs must not be cleared
   when one closes. Track open origins and clear on last-tab-close, with a grace
   period (60 seconds is a reasonable default) so that closing and reopening does
   not log you out.
4. **The "keep me logged in" allowlist is the actual product.** This is the
   escape hatch that determines whether the feature is usable. It must be:
   offered in-context at the moment a user is about to lose a session, one click
   to add, and visible as a plain list in settings. Do not make people hunt for
   it after they have already been logged out of their bank.

**The default matters enormously.** Recommended default: clear cookies
classified Marketing and Analytics, keep Functional and Necessary, keep anything
unknown, and offer the aggressive "clear unknown too" setting in Blackout mode
with a plain-language warning. Clearing unknown cookies by default will log
people out of small sites constantly and is the fastest way to lose a
non-technical user.

Complexity: **high.** This is the largest single piece of original code in the
desktop spec: two to four weeks including the site testing needed to trust the
defaults. Maintenance: **low** once built, WebExtension APIs are stable, plus
periodic Open Cookie Database refreshes. Breakage: **high**, and it is breakage
users blame on us, not on the site. Budget more testing here than anywhere else.

#### The per-site panel

The panel that shows what was **rejected** (layer A), **hidden** (layer B),
**blocked** (tracking protection and uBlock Origin), and **cleared** (layer C).

Data sources differ and this shapes the implementation:

- "Rejected" and "cleared" come from our own code. Easy.
- "Hidden" comes from uBlock Origin's cosmetic filtering, which does not expose
  a counting API to other extensions.
- "Blocked" is best taken from Gecko's own content blocking log, available to
  chrome code, rather than counted a second time in an extension.

**Therefore the panel is chrome-level (layer 5a), reading the content blocking
log directly, with the extension feeding it consent and cookie events over a
small message channel.** Counting blocked requests independently in a
WebExtension would produce numbers that disagree with the shield, which is worse
than showing fewer numbers.

For the "hidden" count, either accept that uBlock Origin's contribution is not
itemized, or count our own cosmetic rules only and label it honestly. Do not
invent a number.

Complexity: **medium to high.** Maintenance: **medium**, it is a chrome patch.
Breakage: **none**, it is read-only.

### 6.2 Adblocking

**Layer 2 plus layer 3.**

**uBlock Origin preinstalled**, with the mode picker at first run selecting the
filter set per section 4. Bundled via `policies.json` (`ExtensionSettings` with
`installation_mode: normal_installed`) so it is present on first launch and the
user can still remove it.

Non-negotiable constraints:

- **Ship uBlock Origin unmodified.** Do not patch it and keep the name. The
  author's position on forks carrying the name is clear and reasonable, and the
  trust the name carries is exactly what we are borrowing.
- **The user can disable or remove it.** A bundled extension that cannot be
  removed is adware architecture with the polarity flipped.
- Pin a specific version, review the diff on every bump, and record the version
  in the release notes.

License: uBlock Origin is **GPLv3**. Antumbra is MPL 2.0. This is fine: the
extension is a separate work, sandboxed, not linked, distributed alongside us.
That is mere aggregation. Our obligations are to ship it unmodified, include its
license, and make its corresponding source available. See section 11.

**Obfuscation mode (AdNauseam), off by default.** The spec is right to make this
opt-in with an explainer, and there are three specific things the explainer must
say:

1. **It may violate ad network terms of service** and, depending on
   jurisdiction, has been characterized as click fraud. The user is choosing
   this.
2. **It makes you more fingerprintable, not less.** A browser generating
   distinctive click patterns is a browser with a distinctive signature. This
   directly conflicts with section 1 of the spec, and a user who turns it on
   should know they are making a trade, not stacking a benefit.
3. **It costs bandwidth and battery**, which matters especially on Android and
   on metered connections.

**Distribution, decided (D3): install the signed build from addons.mozilla.org,
and leave extension signature enforcement on.**

An earlier draft of this document assumed AdNauseam was still self-distributed
following its 2017 removal from AMO, and on that basis floated building with
`MOZ_REQUIRE_SIGNING=0`. That assumption was wrong. AdNauseam is listed on AMO and
is signed and installable (verified 2026-09-18). That removes any reason to weaken
signing, so:

- **Antumbra ships with `xpinstall.signatures.required` enforced**, and does not
  set `MOZ_REQUIRE_SIGNING=0`. Disabling enforcement would have loosened security
  for every extension a user ever installs, in order to enable one optional
  feature.
- Enabling Obfuscation mode installs the AMO build through the normal install
  flow, pinned to a reviewed version like every other bundled component.

AdNauseam is **GPLv3** and is a uBlock Origin fork, so it cannot run
alongside uBlock Origin: enabling Obfuscation mode swaps one for the other, which
means filter list settings must be migrated between them. Add that to the
complexity.

Complexity: **low** for uBlock Origin, **medium** for the Obfuscation swap plus
migration plus explainer. Maintenance: **low**, version bumps. Breakage:
**medium** at Blackout filter levels, which is inherent to aggressive blocking
and is why per-site disable must be one click from the toolbar.

### 6.3 HTTPS-First with a hardened HTTP profile

**Layer 1 for HTTPS-First, layer 4 plus 5a for the hardened profile.**

```
dom.security.https_first = true
dom.security.https_first_pbm = true
dom.security.https_only_mode = false
```

HTTPS-First upgrades and silently falls back, which is correct for our audience.
HTTPS-Only shows an interstitial and requires a decision, which non-technical
users answer by clicking whatever makes it go away.

The interesting part is what happens **after** fallback. The spec asks for a
hardened profile on plain HTTP pages:

| Sub-feature | Mechanism | Notes |
|---|---|---|
| Warning bar | Layer 5a, chrome patch | A persistent, non-dismissable-per-page notification bar. Small patch. |
| No autofill | Layer 5a, chrome patch | Suppress form autofill and password autofill for insecure documents. Firefox already warns on insecure login forms; this extends it to suppression. |
| Third-party requests blocked | Layer 4, extension | `webRequest` blocking: on a top-level HTTP document, block subresources from other origins. Straightforward with blocking `webRequest`, which Gecko retains. |
| Optional JS off, one-tap override | Layer 5a plus permissions | Per-origin JavaScript permission already exists in Gecko's permission manager; the work is the UI and tying it to the document's scheme. |

This is the most Gecko-flavored feature in the spec, and doing the third-party
blocking in the extension rather than in C++ is what keeps it affordable. The
warning bar and autofill suppression are small, local chrome patches.

Complexity: **medium.** Maintenance: **medium**, the chrome parts follow
upstream's notification and autofill code. Breakage: **medium to high** on the
HTTP pages it applies to: old sites, local devices, router admin pages, and
intranet hosts. Router configuration pages in particular are plain HTTP, heavily
JavaScript-driven, and exactly where a user needs the browser to work. **A
prominent, one-tap "trust this site" that persists per origin is mandatory**, not
a nice-to-have.

### 6.4 Passwords

**Layer 1 plus onboarding.**

Default: Firefox's built-in vault with a **primary password**. This matters and
is usually skipped: without a primary password, the built-in store is encrypted
with a key sitting next to it on disk, so any local process can read it. A
privacy browser that ships the vault as default and does not prompt for a
primary password is shipping a weaker story than it implies.

So: at first run, offer the primary password as part of the flow, with a plain
explanation of what it protects against (someone with access to your computer or
your backups) and what it does not (a compromised browser process).

**Proton Pass is offered, never forced**, per the spec. One card in the first-run
flow, clearly optional, with "keep using the built-in one" as an equally weighted
choice rather than a greyed-out escape. If a Proton affiliate relationship exists,
it is disclosed on that card under the same rules as section 6.6.

Complexity: **low.** Maintenance: **very low.** Breakage: **none.**

### 6.5 Totality window

**Layer 5a plus a bundled process. The largest engineering item in the spec.**

Per BRANDING.md: labeled "Totality window, powered by Tor", violet `--relay`
chrome, three violet dots on the ring, and it must carry the honest disclaimer
the spec requires: **not as anonymous as Tor Browser.**

That disclaimer is not legal boilerplate, it is technically true and the reason
matters. Tor Browser's anonymity comes from every user presenting an identical
fingerprint, not from the routing. An Antumbra window routed over Tor has
Antumbra's fingerprint, our window dimensions, our font set, and our user's
preferences. It defeats network-level observation and IP-based tracking. It does
not put you in Tor Browser's anonymity set. The UI should say roughly that, in
plain words, on first use.

**Staging the implementation, which the spec does not address:**

The spec asks for embedded Arti. Arti (Tor's Rust implementation, MIT or Apache
2.0) is the right destination, but embedding it in-process inside Gecko is a
major undertaking: its embedding API is still evolving, and linking a large
async Rust stack into the Firefox build introduces build complexity and a new
class of crash.

**Decided (D2): two stages.**

1. **Stage 1: Arti as a supervised child process exposing SOCKS5.** Antumbra
   launches it, waits for bootstrap, and points the Totality window's proxy
   settings at it. This is how Brave ships Tor windows (with C tor), it is well
   understood, and the failure modes are contained: if the process dies, the
   window shows an error instead of crashing the browser.
2. **Stage 2: in-process Arti**, once its embedding story is stable and there is
   a reason to pay for it (faster startup, no separate binary to ship and sign).

Either way, the per-window plumbing is the same work and is not small:

- **Per-window proxy** is not something Firefox does natively. Proxy settings are
  global. This needs either a container-based approach (give the Totality window
  its own contextual identity and proxy that identity, which the `proxy`
  WebExtension API can do per-request) or a chrome patch threading a proxy
  through the window's load context. The extension route is cheaper and should be
  tried first.
- **Leak prevention is the whole feature.** WebRTC off, DNS through the proxy
  (`network.proxy.socks_remote_dns = true`), no disk cache shared with the normal
  profile, RFP on, no extensions running in that window that phone home. A
  Totality window that leaks is worse than no Totality window, because the user
  believed it.
- **Bootstrap takes time.** Ten to thirty seconds of "connecting" needs designed
  UI, not a hung window.

Complexity: **very high.** Six to ten weeks, realistically, and it is the item
most likely to be underestimated. Maintenance: **medium to high**, tracking Arti
releases plus the per-window plumbing. Breakage: **high by nature**, Tor exit
nodes are widely blocked and CAPTCHAs are constant. Set expectations in the UI.

License: Arti is MIT or Apache 2.0, both compatible. C tor, if used as an interim
backend, is BSD 3-clause, also compatible. The **Tor trademark** is the real
constraint: read the Tor Project's trademark FAQ, always use "powered by Tor"
rather than anything implying endorsement, never adopt the onion logo as our
mark, and contact the Tor Project before launch rather than after.

### 6.6 VPN toolbar button

**Layer 5a, small chrome patch plus a static config file.**

Four partners with affiliate links: NordVPN, Surfshark, AdGuard VPN, Proton VPN.

This is the feature with the worst risk-to-effort ratio in the spec. It is a few
days of work and it is the thing most likely to be the top comment on every
launch post. That does not mean do not ship it. It means ship it in a way that
survives a hostile reading.

**The disclosure requirements, all mandatory:**

| Requirement | Implementation |
|---|---|
| Labeled as affiliate | Visible text in the panel itself, not a footnote, not a tooltip, not a link to a policy page. |
| Shared ownership disclosed | NordVPN and Surfshark are both Nord Security brands. Stated in the panel, next to both. |
| Removable | Right-click, "Remove from toolbar", gone permanently. A pref, respected on upgrade. |
| No click telemetry | We record nothing. See the honesty note below. |
| Never applied to typed URLs | Section 2.3. Enforced by test. |

**The honesty note, which must be in our privacy policy:** we collect nothing,
but an affiliate link works by identifying the referrer to the partner. When the
user clicks, the partner and their affiliate network learn that a click came from
Antumbra's referral ID, along with the user's IP and user agent as with any
navigation. We cannot make that not happen, and claiming "no tracking" without
this caveat would be false. The correct claim is: **Antumbra records nothing
about your click; the destination does, as it would for any link you follow.**

Implementation: a `partners.json` in-tree with the links, so changing a partner
is a data change with a visible diff rather than a code change. Affiliate URLs
are placeholders until supplied:

| Partner | Affiliate URL | Ownership note shown |
|---|---|---|
| NordVPN | `[INSERT LINK]` | Owned by Nord Security, same company as Surfshark |
| Surfshark | `[INSERT LINK]` | Owned by Nord Security, same company as NordVPN |
| AdGuard VPN | `[INSERT LINK]` | Independent |
| Proton VPN | `[INSERT LINK]` | Independent, Swiss, open source clients |

Complexity: **low**, three to five days. Maintenance: **very low.** Breakage:
**none technical, high reputational.** Decided (D4): **milestone 7, after the
Totality window.** It ships once the browser has an established privacy record,
so that it reads as a funding model rather than as the point of the project. The
CI rule above is permanent and does not depend on that sequencing.

### 6.7 Container tabs

**Layer 2 plus layer 3.**

Contextual identities are already in Gecko. What users think of as "container
tabs" is Mozilla's **Multi-Account Containers** extension (MPL 2.0, same license
as us), which provides the interface. Bundle it.

There is meaningful overlap with Total Cookie Protection: once state is
partitioned per top-level site, the main remaining use of containers is running
multiple accounts on one site. Present it that way in onboarding ("stay logged
into two accounts at once") rather than as a privacy feature, or users will
reasonably ask why they need both.

Complexity: **trivial.** Maintenance: **very low.** Breakage: **none.**

### 6.8 Interface: vertical tabs, split view, web panels, dashboard

| Feature | Layer | Complexity | Per-release maintenance | Notes |
|---|---|---|---|---|
| **Vertical tabs, left, default** | 1 | Low | Low | Recent Firefox ships native vertical tabs in the revamped sidebar (`sidebar.revamp`, `sidebar.verticalTabs`). If the pinned ESR base has them, this is a default change plus a toggle. If not, it waits for the next ESR rather than being patched in. **Verify against the pinned base before committing to this.** |
| **Top-tabs toggle** | 1 plus 5a | Low | Low | The pref exists; the work is putting the toggle somewhere a non-technical user finds it, which means first-run and Settings, not `about:config`. |
| **Sidebar web panels** | 4 | Medium | Low | `sidebarAction` is a stable WebExtension API. A first-party extension can host arbitrary sites in the sidebar without touching chrome code. Far cheaper than patching the sidebar. |
| **Split view** | 5a | High | **High** | No upstream equivalent. Requires patching `tabbrowser` and the browser window layout, which is among the most actively refactored code in the tree. This is the most expensive interface feature per unit of user value and should be scheduled last. |
| **Privacy dashboard** | 5a | Medium | Medium | Extend the existing protections page rather than building a new surface. It already aggregates the content blocking log. Add our consent, cookie clearing, and DNS data to it. |

**Split view deserves an explicit warning.** Zen's split view is excellent and it
is also a substantial, continuously maintained patch against front end code that
upstream reorganizes without warning. For a solo developer, this single feature
could plausibly cost more per year than every prefs-level protection in section 5
combined. Schedule it accordingly, and be willing to drop it.

### 6.9 Exclusions

Spec section 9. Enforcing these is mostly a matter of turning off what upstream
ships:

```
browser.newtabpage.activity-stream.showSponsored = false
browser.newtabpage.activity-stream.showSponsoredTopSites = false
browser.newtabpage.activity-stream.feeds.section.topstories = false
browser.newtabpage.activity-stream.feeds.topsites = false
browser.topsites.contile.enabled = false
extensions.pocket.enabled = false
browser.urlbar.suggest.quicksuggest.sponsored = false
browser.urlbar.suggest.quicksuggest.nonsponsored = false
browser.urlbar.quicksuggest.enabled = false
```

Crypto wallets and rewards are simply never added, which needs no code, only a
written policy so it stays true after the project gains contributors. Put it in
`CONTRIBUTING.md` as a standing rule.

Complexity: **trivial.** Maintenance: **low**, new sponsored surfaces appear
upstream and the pref audit should flag new `sponsored` prefs for review.

---

## 7. Spec section 10: Android

Deliberately later. The important architectural decision is made early because it
determines whether Android is a moderate project or a second full-time job.

### 7.1 The decision that matters: prebuilt GeckoView or build it ourselves

| | **Prebuilt GeckoView from Maven** | **GeckoView built from our patched Gecko** |
|---|---|---|
| Build | Gradle only. Hours of setup, minutes per build. | Full Gecko build for four Android ABIs. Very large. |
| CI | Runs on hosted runners | Needs the self-hosted builder, several hours per release |
| Gecko patches | **None available.** Prefs, policies, and extensions only. | All desktop patches carry over |
| F-Droid | Feasible | Very heavy, but proven by other projects |
| Solo-dev cost | Moderate | High and permanent |

**Recommendation: start with prebuilt GeckoView.** Most of the spec's Android
scope (uBlock Origin preinstalled, hardened prefs, bottom toolbar, tab drawer)
needs no Gecko patches at all. Accept that the HTTP hardened profile's chrome
parts and the desktop chrome patches do not exist on Android in the first
Android release, and say so.

### 7.2 Components

| Item | Mechanism | Complexity | Notes |
|---|---|---|---|
| Fenix fork | Kotlin, Android Components | High | Fenix is MPL 2.0. Prior art: Mull and its successor Ironfox show this is achievable by a small team, and also show how much work it is. |
| Bottom toolbar, swipe-in tab drawer | Fenix UI work | Medium | Fenix already supports a bottom toolbar; the drawer is custom. |
| uBlock Origin preinstalled | Extension, Fenix supports WebExtensions | Low | Android extension support is narrower than desktop. Verify per release. |
| Hardened prefs | Same pref set, shared source of truth with desktop | Low | Keep one pref file for both targets. |
| Tor as in-app proxy | Arti as a bundled library or service | Very high | Simpler than desktop in one way, no per-window concept: it is per-app or per-tab. |
| Google Play release | Play Console, $25 one-time | Low process, medium policy risk | Play policy on ad blocking and on Tor-enabled apps requires reading carefully before building. |
| F-Droid release | Reproducible build from source | High | F-Droid must build from source on their infrastructure. Any prebuilt GeckoView binary is a blocker for inclusion in the main repository; expect to run our own F-Droid repository first. |

The Play and F-Droid requirements pull in opposite directions (Play accepts
prebuilt dependencies happily, F-Droid does not), which is the main reason
Android is a distinct project phase and not an extension of the desktop work.

---

## 8. Summary: everything, costed

Complexity is solo-developer effort to first working version. Maintenance is
recurring cost per upstream release.

| # | Feature | Layer | Complexity | Maintenance | Breakage risk | License |
|---|---|---|---|---|---|---|
| 1.1 | Strict ETP | Prefs | Trivial | Very low | Low | MPL 2.0 |
| 1.2 | Total Cookie Protection | Prefs | Trivial | Low | Medium | MPL 2.0 |
| 1.2b | First-Party Isolation | Prefs | Trivial | Low | High | **Totality window only (D1)**, superseded by TCP elsewhere |
| 1.3 | Fingerprinting resistance | Prefs | Low | Low | Medium (FPP) / High (RFP) | MPL 2.0 |
| 1.3b | Per-site FP exceptions UI | Chrome patch | Medium | Medium | None | MPL 2.0 |
| 1.4 | WebRTC leak protection | Prefs | Trivial | Very low | Low | MPL 2.0 |
| 1.5 | Parameter stripping | Prefs + uBO list | Trivial | Very low | Low to medium | GPLv3 list, aggregated |
| 1.6 | Redirect / AMP bypass | Own extension | Medium | Low | Medium | MPL 2.0 |
| 1.7 | Encrypted DNS | Prefs | Low | Low | Low | MPL 2.0 |
| 1.7b | First-run resolver picker | Chrome patch | Medium | Low | None | MPL 2.0 |
| 1.8 | Zero telemetry | Build flags + prefs | Low | Low | None | MPL 2.0 |
| 2.A | Auto-reject consent | Prefs + Consent-O-Matic | Low | Low | Low to medium | MIT, aggregated |
| 2.B | Hide banners | uBO annoyance lists | Trivial | Very low | Medium | GPLv3, aggregated |
| 2.C | Clear on tab close | Own extension | **High** | Low | **High** | MPL 2.0; Open Cookie Database separately licensed |
| 2.D | Per-site consent panel | Chrome patch + extension | Medium to high | Medium | None | MPL 2.0 |
| 3 | uBlock Origin preinstalled | Policy + bundle | Low | Low | Medium | GPLv3, aggregated |
| 3b | Obfuscation mode (AdNauseam) | Signed AMO install | Medium | Low | Medium | GPLv3; signing enforcement stays on (D3); **legal and ethical caveats** |
| 4 | HTTPS-First | Prefs | Trivial | Very low | Low | MPL 2.0 |
| 4b | Hardened HTTP profile | Extension + chrome patch | Medium | Medium | Medium to high | MPL 2.0 |
| 5 | Passwords, primary password default | Prefs + onboarding | Low | Very low | None | MPL 2.0 |
| 5b | Proton Pass offer | Onboarding card | Trivial | Very low | None | Link only |
| 6 | Totality window | Bundled Arti + chrome patch | **Very high** | Medium to high | High by nature | MIT/Apache 2.0; **Tor trademark care** |
| 7 | VPN button | Chrome patch + config | Low | Very low | Reputational | MPL 2.0 |
| 8a | Container tabs | Bundled extension | Trivial | Very low | None | MPL 2.0 |
| 8b | Vertical tabs default | Prefs | Low | Low | None | MPL 2.0 |
| 8c | Sidebar web panels | Own extension | Medium | Low | Low | MPL 2.0 |
| 8d | **Split view** | Chrome patch | High | **High** | Medium | MPL 2.0 |
| 8e | Privacy dashboard | Chrome patch | Medium | Medium | None | MPL 2.0 |
| 9 | Exclusions | Prefs + policy | Trivial | Low | None | MPL 2.0 |
| 10 | Android | Separate project | **Very high** | High | n/a | MPL 2.0 |

**Where the maintenance budget actually goes:** split view, the Totality window,
the per-site panel, the hardened HTTP profile, and the dashboard. Five features,
all layer 5. Everything else is close to free per release. If the project ever
feels like it is drowning, the answer is in that list.

---

## 9. Repository structure

### 9.1 One repository or several

LibreWolf splits into several repositories (settings, source, build scripts).
That suits a team with separate maintainers per area. **For a solo developer, one
repository is better**: one issue tracker, one CI configuration, one place where
a change and its build result live together, and atomic commits across patches
and prefs.

Revisit if and when the Android work starts, which is the natural point to split
(different toolchain, different release cadence, different CI).

### 9.2 Layout

```
antumbra-browser/
  README.md
  ARCHITECTURE.md
  ROADMAP.md
  BRANDING.md
  CONTRIBUTING.md
  SECURITY.md
  LICENSE                       MPL 2.0
  THIRD-PARTY.md                every bundled component, version, license, source URL

  upstream.conf                 pinned Firefox tag and commit hash. The single
                                source of truth for what we are forking.

  patches/                      applied in numeric order
    0000-branding/              name, icons, about dialog, remove Mozilla marks
    0100-prefs/                 pref file injection
    0200-modes/                 protection mode plumbing and chrome accent
    0300-onboarding/            first-run flow
    0400-fp-exceptions/         per-site fingerprinting exceptions UI
    0500-http-hardening/        warning bar, autofill suppression
    0600-dashboard/             privacy dashboard extensions
    0700-consent-panel/         per-site consent panel
    0800-totality/              Totality window
    0900-vpn-button/            VPN toolbar button
    1000-split-view/            split view (scheduled last, dropped first)

  prefs/
    antumbra.js                 default prefs, shared desktop and Android
    modes/standard.js
    modes/strict.js
    modes/blackout.js
    policies.json               extension bundling, updater policy

  branding/antumbra/            icons at every required size, brand strings,
                                per-mode variants per BRANDING.md section 6

  extensions/                   our code, MPL 2.0
    antumbra-core/              modes, redirect and AMP bypass, cookie clearing,
                                consent event reporting, web panels
  third_party/extensions/       vendored, unmodified, with source and license
    ublock-origin/
    consent-o-matic/
    multi-account-containers/
  third_party/data/
    open-cookie-database/
    dns-resolvers.json          our resolver list, not Mozilla's
    partners.json               VPN affiliate links, section 6.6

  mozconfigs/
    linux-x86_64
    windows-x86_64
    macos-universal
  scripts/
    bootstrap.sh                toolchain setup
    fetch-upstream.sh           clone and check out upstream.conf
    apply-patches.sh
    build.sh
    package.sh
    audit-prefs.py              section 10.3
  .github/workflows/
  docs/
```

**`THIRD-PARTY.md` is load-bearing, not bureaucracy.** We ship GPLv3 code inside
an MPL 2.0 product. The file that records what, which version, under which
license, and where the corresponding source lives is the compliance artifact. Its
absence is the licensing problem.

---

## 10. Build and CI

### 10.1 Build requirements

Firefox is one of the largest open source codebases in existence. The numbers are
not negotiable:

| Resource | Minimum | Comfortable |
|---|---|---|
| Disk | 60 GB free | 200 GB plus, NVMe |
| RAM | 16 GB | 32 to 64 GB |
| Cores | 8 | 16 to 32 |
| Clean build | 2 to 5 hours on 8 cores | 30 to 60 minutes on 32 cores |
| Incremental build | Minutes | Minutes |

Toolchain: `mach bootstrap` handles most of it (clang, Rust, cbindgen, nasm,
Node). **Artifact builds are not available to us**: they only work when you make
no compiled-code changes, and we do.

Cross-platform realities:

- **Windows: the first target (D7).** Built natively on the maintainer's own
  desktop, which is also the machine Antumbra is daily-driven on. Cross-compiling
  from Linux is possible but the SDK licensing makes it awkward to distribute
  from CI, and building on Windows removes that problem entirely. Code signing is
  a milestone 2 blocker: unsigned Windows binaries trigger SmartScreen warnings
  that will destroy install conversion for exactly the non-technical audience
  Antumbra targets. Options and costs are in BRANDING.md's launch checklist.
- **Linux**: the cheapest target technically (no signing, no notarization,
  simplest toolchain), which is why it was originally proposed first. It moves to
  milestone 2 and is built in CI. See D7 for why daily-driving beat cheapness.
- **macOS**: requires Apple's SDK, which cannot be redistributed, so either build
  on a Mac or supply the SDK yourself. Distribution requires an Apple Developer
  Program membership (99 USD per year) and notarization. Without notarization,
  Gatekeeper blocks the app for ordinary users.

**Signing is a hard prerequisite for the non-technical audience, not an
optimization.** A browser that shows a scary warning on install has failed before
it launches.

**GPUs do not build browsers.** Worth stating because it is a common assumption:
Firefox compilation is CPU-bound and IO-bound. Cores, RAM, and NVMe throughput
determine build times. A discrete GPU sits idle throughout. It is genuinely
useful for *testing* Antumbra's graphics paths (WebRender, hardware video decode,
compositor behavior), which is a real benefit of building on a workstation, but
it will not shorten a single build.

### 10.2 Does this need a self-hosted runner

**Eventually yes, and it is the maintainer's own Windows desktop (D7). Not
yet.**

**Milestones 0 and 1 have no CI builder at all.** Builds run locally on the
Windows machine, driven by Claude Code installed on that machine. Cloud sessions
handle documentation, planning, patch review, and pref auditing, and **must not
attempt builds**: they have neither the disk nor the job time limit for a Firefox
build. That separation of duties is deliberate, not a limitation to work around.

From milestone 2, when Linux and macOS builds are needed, the question becomes
real, and the answer is below.

GitHub-hosted standard runners give roughly 4 vCPUs, 16 GB RAM, and on the order
of 14 GB of usable free disk, against a 6 hour job limit. A Firefox checkout plus
object directory exceeds the disk on its own, and a 4-core build would not finish
inside the time limit. This is not a tuning problem.

Three options:

| Option | Cost | Verdict |
|---|---|---|
| GitHub-hosted standard | Free | **Not viable** for full builds. Disk and time both fail. |
| GitHub larger runners | Per-minute, adds up fast at multi-hour builds | Viable, no hardware to own. Good for occasional macOS and Windows builds. |
| **Self-hosted** | One machine | **Recommended for the Linux builder.** A 16-core, 64 GB, 1 TB NVMe box, with a persistent `sccache` directory, turns a nightly into something that finishes while you sleep. |

Recommended shape from milestone 2: **the maintainer's Windows desktop registered
as a self-hosted runner** for Windows builds, plus GitHub larger runners called on
demand for Linux and macOS. That inverts the usual arrangement, and it follows
from D7: the machine that already builds Windows locally is the machine that
should keep building it, and Linux is now the target that needs borrowed
hardware.

**Security rule, non-negotiable if the repository is public:** never run
self-hosted runner jobs on pull requests from forks. A self-hosted runner
executing untrusted pull request code is arbitrary code execution on your
hardware, with your signing secrets nearby. Gate fork pull requests behind a
manual approval and keep release signing on a separate, isolated runner that
pull requests can never reach.

### 10.3 CI jobs

Fast lane, on free hosted runners, on every push:

| Job | What it catches |
|---|---|
| **Pref audit** (`audit-prefs.py`) | Every pref we set is checked to exist in the upstream tree at the pinned tag. A removed or renamed pref fails the build instead of silently disabling a protection. **The highest-value job in this list.** |
| **Patch apply check** | All patches apply cleanly to the pinned upstream tag. Catches rebase rot the moment `upstream.conf` moves. |
| **Extension build and lint** | Our extension compiles and passes `web-ext lint`. |
| **License check** | Every entry in `third_party/` has a license file and a `THIRD-PARTY.md` row. |
| **No-affiliate-rewrite test** | Static check that no code path writes a partner ID into a navigation the user initiated. Enforces section 2.3. |
| **Branding check** | No Mozilla trademarks in strings or assets. |
| **Docs check** | Internal links resolve. No em dashes, per house style. |

Heavy lane, on the self-hosted runner:

| Job | Trigger |
|---|---|
| Full Linux build | Nightly, plus on `upstream.conf` change |
| Packaging and smoke test | After a successful build: launch headless, load a page, confirm prefs applied |
| Release build, sign, publish | On tag, on the isolated release runner only |

Smoke testing deserves more than a mention: **automatically verify that the
shipped build actually has the prefs set.** Launch it, read the prefs back, fail
if any differ from `antumbra.js`. It is the difference between claiming privacy
defaults and having them.

---

## 11. Licensing and trademark

### 11.1 Our license

**MPL 2.0**, matching upstream. MPL 2.0 is file-level copyleft: our modifications
to Mozilla files stay MPL, our new files could technically be anything, and
keeping everything MPL 2.0 avoids the question entirely. MPL 2.0 is also
GPL-compatible as a secondary license, which keeps future options open.

### 11.2 Bundled components

| Component | License | Compatibility | Obligation |
|---|---|---|---|
| Firefox / Gecko | MPL 2.0 | Same license | Keep headers, publish modified source |
| uBlock Origin | GPLv3 | Aggregation, not linking | Ship unmodified, include license, provide corresponding source |
| AdNauseam | GPLv3 | Aggregation, not linking | Installed from AMO as the signed build (D3); include license, provide corresponding source; caveats in section 6.2 |
| Consent-O-Matic | MIT | Permissive | Attribution |
| Multi-Account Containers | MPL 2.0 | Same license | Keep headers |
| Proton Pass | GPLv3 | **Not bundled**, offered as a link | None |
| Open Cookie Database | Apache 2.0 (verify at vendoring time) | Compatible with MPL 2.0 | Attribution, NOTICE file |
| Arti | MIT or Apache 2.0 | Compatible | Attribution |
| C tor (if used as interim backend) | BSD 3-clause | Compatible | Attribution |
| Filter lists (EasyList and others) | Mostly CC BY-SA 3.0 | Data, not code | Attribution, share-alike on modifications |

**The GPLv3 question, answered plainly:** bundling GPLv3 WebExtensions with an
MPL 2.0 browser is mere aggregation. The extensions are separate programs running
in a sandbox with a defined API boundary; they are not linked into our binary and
do not form a combined work. This is the same posture every Linux distribution
takes when shipping GPL and non-GPL software on one medium. Our obligations are
narrow and concrete: distribute the GPL components unmodified, include their
licenses, and make the corresponding source available for the exact versions we
ship. `THIRD-PARTY.md` plus a source mirror satisfies this.

The one thing that would change the analysis is **modifying** a GPLv3 extension
and shipping the result. Do not do that. If uBlock Origin needs to behave
differently, do it through its own settings and filter lists, not by patching it.

### 11.3 Trademarks, which the license does not cover

MPL 2.0 grants no trademark rights, explicitly. Three separate obligations:

1. **Mozilla.** Do not use "Firefox", the Firefox logo, or Mozilla branding in
   the product name, icon, domain, or taglines. BRANDING.md already forbids this.
   Build with our own branding directory, not `--enable-official-branding`.
   "Based on Firefox" in technical documentation is acceptable descriptive use.
2. **Tor.** Per section 6.5 and BRANDING.md: always "powered by Tor", never the
   onion logo as our mark, never any implication of endorsement or maintenance by
   the Tor Project. Contact them before launch.
3. **uBlock Origin.** Do not modify it and keep the name. Do not imply the author
   endorses Antumbra.

And one for us: BRANDING.md's checklist already flags that a Class 9 and Class 42
clearance opinion is required before launch. Nothing in this document substitutes
for it.

---

## 12. Updates and security response

The obligation that outlasts every feature: **when Firefox ships a security
release, Antumbra ships one within days.** A fork that lags on security is
actively harmful to the people who trusted it, and that is a permanent, recurring
commitment starting the day of the first public build.

ESR helps here. Its security releases are predictable, roughly every 4 weeks plus
out-of-band fixes for anything critical, and they rarely disturb patches.

**Update delivery** has two phases:

1. **Milestone 1 and 2: package managers.** Flatpak, AUR, Homebrew, winget.
   Users get updates through machinery that already exists and is already
   trusted. Zero infrastructure for us.
2. **Later: the built-in updater.** Firefox's updater needs an update server
   speaking its protocol and MAR update files signed with a key compiled into the
   build. This is well-trodden (LibreWolf does it) but it is real work: key
   generation and custody, a static update endpoint, and a build change. It also
   means that losing the signing key ends the ability to update every installed
   copy, so key custody is a serious, documented procedure, not a file on a
   laptop.

Until the built-in updater exists, **the browser must tell users how it gets
updated**, prominently, at first run. A browser that silently stops receiving
security updates is the worst possible outcome for this project.

`SECURITY.md` should state the response target plainly: a public commitment to
ship within N days of upstream, where N is a number that can actually be met.

---

## 13. Open questions

Seven of the original ten are now decided. See [DECISIONS.md](DECISIONS.md) for
the reasoning behind each.

### Decided

| Was | Decision | Reference |
|---|---|---|
| First-Party Isolation | Total Cookie Protection only, FPI confined to the Totality window | D1 |
| Arti embedding | Supervised child process first, in-process later | D2 |
| Extension signing | Signing enforcement stays on; AdNauseam installs from AMO as the signed build | D3 |
| VPN button timing | Milestone 7, after the privacy work | D4 |
| Remote Settings | On, with Normandy and studies off, disclosed | D5 |
| Safe Browsing | Local list checks on, per-download remote lookup off, disclosed | D5 |
| ESR or Release | ESR, with a patch series over a pinned tag | D6 |
| Build platform | Windows first, built locally; Linux and macOS at milestone 2 via CI | D7 |

### Still open

1. **Split view.** Section 6.8 flags it as the worst maintenance-to-value ratio
   in the spec. Confirm it is worth a permanent annual cost. Needed by milestone
   4.
2. **Search default.** Not in the original spec, but every browser must answer
   it, and it is the most obvious non-affiliate revenue source. Decide whether
   taking search revenue is compatible with the positioning. Needed by milestone
   1.
3. **Default DNS resolver.** Section 5.7 requires an editorial choice with real
   privacy consequences. Document the reasoning publicly. Needed by milestone 1.
4. **Funding.** A signing arrangement, a domain, and a trademark clearance
   opinion are real year-one costs before anyone is paid for their time. Windows
   signing in particular has a free path for open source projects and several
   low-cost ones; see BRANDING.md's launch checklist. Needed by milestone 0.
