# Antumbra: roadmap

**Status: draft for review.** Written 2026-09-18. Sequences the work described in
[ARCHITECTURE.md](ARCHITECTURE.md). Naming follows [BRANDING.md](BRANDING.md).

Estimates are **full-time-equivalent weeks for one experienced developer**, and
they assume no prior Gecko experience, which adds a real learning curve to the
first two milestones. **Double every number for part-time work.** Browser
estimates are famously optimistic; treat these as the floor.

---

## How this roadmap is ordered

Three rules decide the sequence.

1. **Ship something real before building anything clever.** A browser that
   installs, browses, and blocks is worth more than a feature list. Milestone 1
   is deliberately small.
2. **Trust before revenue.** The VPN affiliate button (spec section 7) is a few
   days of work and could ship in milestone 1. It should not. A privacy browser
   whose first release includes affiliate links reads as an affiliate scheme with
   a browser attached. It lands after the project has a record.
3. **Cheap features before expensive ones.** Everything at the prefs and
   extension layers ships before anything that needs a chrome patch, because
   prefs cost nothing per release and patches cost forever. Split view, the most
   expensive feature per unit of value, is last.

---

## Milestone 0: decisions and groundwork

**2 to 4 weeks. No shippable output. Do not skip it.**

Every hour here saves days later. The deliverable is a repository that builds
unmodified Firefox on your own hardware, plus the decisions in ARCHITECTURE.md
section 13 actually made.

- [ ] Decide **ESR or Release** (ARCHITECTURE.md 3.2). Recommendation: ESR.
- [ ] Decide **First-Party Isolation** (5.2). Recommendation: drop it, Total
      Cookie Protection supersedes it.
- [ ] Decide **Remote Settings** and **Safe Browsing** posture (5.8).
- [ ] Decide **extension signing** posture (6.2), which determines whether
      Obfuscation mode can ever be bundled.
- [ ] Pin `upstream.conf` to a specific Firefox tag.
- [ ] Build unmodified Firefox from source, end to end, on the target machine.
      **Until this works, nothing else matters.** Expect this alone to take
      several days the first time.
- [ ] Stand up the self-hosted Linux builder (ARCHITECTURE.md 10.2) with
      persistent `sccache`.
- [ ] Create the repository skeleton from ARCHITECTURE.md section 9.2.
- [ ] Write `THIRD-PARTY.md`, `SECURITY.md`, `CONTRIBUTING.md` (including the
      standing no-crypto, no-rewards, no-sponsored-content rule from spec section
      9).
- [ ] Produce the icon set per BRANDING.md section 6, hand-tuned at 16, 32, and
      48px, all four mode variants.
- [ ] Verify against the pinned base whether native vertical tabs are available
      (ARCHITECTURE.md 6.8). This determines whether a headline design feature is
      free or deferred.

**Definition of done:** `scripts/build.sh` produces a working, unbranded Firefox
from a clean checkout on the builder, and CI runs the fast lane on every push.

---

## Milestone 1: the smallest shippable desktop build

**6 to 10 weeks. The first public release. Linux x86_64 only.**

This is the answer to "what is the smallest thing that is recognizably Antumbra
and worth installing?" Everything in it is at layer 1 to 3 except the first-run
flow. There is exactly one chrome patch of consequence, and it is onboarding,
because onboarding is the differentiator.

### In scope

**Identity**
- Full Antumbra branding: name, icon set, about dialog, window title. All Mozilla
  trademarks removed.
- Custom branding directory. Not `--enable-official-branding`.

**Privacy baseline, prefs and build flags only** (ARCHITECTURE.md section 5)
- Strict ETP, Total Cookie Protection, storage partitioning.
- Fingerprinting protection (FPP) on; RFP reserved for Blackout mode.
- WebRTC leak protection, HTTPS-First, tracking parameter stripping.
- Encrypted DNS, mode 2, with a resolver chosen at first run.
- Telemetry compiled out, plus the pref layer behind it.
- All sponsored surfaces, Pocket, and suggestions off. Mozilla search partner
  codes stripped.

**Bundled extensions**
- uBlock Origin, pinned version, unmodified, removable.
- Consent-O-Matic, plus Firefox's built-in banner rejection at mode 1 (reject
  only, never accept).
- Multi-Account Containers.

**Protection modes** (ARCHITECTURE.md section 4)
- Standard, Strict, Blackout mode. One setting driving the pref set, the uBlock
  Origin filter selection, the chrome accent color, and the icon variant.
- Per-site step-down: one click in the shield panel to relax protections on a
  site that is broken. **This is required in milestone 1, not later.** Without
  it, the first broken site turns protection off permanently.

**First run** (the one substantial patch)
- Protection mode picker, in plain language, with honest tradeoffs.
- DNS resolver picker, including "use my system resolver" as a real option.
- Vertical tabs or top tabs.
- Primary password offer for the built-in vault, explained in one sentence.
- How updates reach you, stated prominently, because milestone 1 has no built-in
  updater.

**Interface**
- Vertical tabs on the left by default, with a working toggle, **if the pinned
  base supports it natively.** If not, it moves to milestone 4 rather than being
  patched in. Decide in milestone 0.

**Release**
- Linux x86_64 tarball plus Flatpak, published on GitHub Releases with SHA-256
  sums.
- A privacy policy that is accurate, including the Remote Settings and Safe
  Browsing disclosures from ARCHITECTURE.md 5.8.

### Explicitly out of scope for milestone 1

Cookie clearing on tab close, the per-site consent panel, the privacy dashboard,
Obfuscation mode, the hardened HTTP profile, Proton Pass, the Totality window,
the VPN button, split view, web panels, Windows, macOS, Android, and the built-in
updater.

That list is long on purpose. Each item is a milestone-1 delay and none of them
is required for the release to be genuinely useful and genuinely private.

### Definition of done

- Installs and runs on a clean Ubuntu, Fedora, and Arch system.
- Automated smoke test confirms every pref in `antumbra.js` is actually set in
  the shipped binary.
- A network capture from first launch to five minutes idle contains **no
  connection we have not documented**. This is the test that makes the privacy
  claim falsifiable, and it should be published.
- The top 50 sites by traffic load and function in Standard mode.
- A non-technical person completes first run without assistance and can explain
  afterwards what mode they chose.

---

## Milestone 2: platforms, updates, and trust

**8 to 12 weeks. The milestone that turns a project into a product.**

Unglamorous and more important than any feature. Without it, Antumbra is a Linux
enthusiast tool, which is the audience it was specifically not built for.

- [ ] **Windows x86_64 build** in CI, plus code signing certificate, HSM key
      custody, and an installer. Unsigned Windows binaries trigger SmartScreen
      and will destroy install conversion.
- [ ] **macOS universal build**, Apple Developer Program membership,
      notarization, DMG packaging. Without notarization, Gatekeeper blocks it.
- [ ] **Built-in updater**: MAR signing keys generated and placed in documented
      custody, an update endpoint, and the build change. Losing this key ends the
      ability to update every installed copy.
- [ ] Package manager presence: Flatpak, AUR, Homebrew cask, winget.
- [ ] Publish the **security response commitment** in `SECURITY.md` with a
      specific day count, and demonstrate it by shipping the first upstream
      security release on schedule.
- [ ] Crash and bug reporting workflow that works without a crash reporter, since
      it is compiled out. This means good, structured issue templates and clear
      reproduction guidance.

**Definition of done:** a non-technical user on Windows or macOS can download,
install, and receive an automatic update, with no security warnings anywhere in
the flow.

---

## Milestone 3: cookie consent, fully realized

**6 to 9 weeks. The feature that most distinguishes Antumbra.**

Layers A and B shipped in milestone 1. This is layer C, enforcement, plus the
panel that makes all three legible (ARCHITECTURE.md 6.1).

- [ ] Cookie clearing on tab close, using the Open Cookie Database, in the
      first-party extension.
- [ ] Clear the rest of the storage surface too: `localStorage`,
      `sessionStorage`, IndexedDB, Cache API, service worker registrations.
      Cookies alone is theater.
- [ ] Last-tab-close tracking plus a grace period, so closing one of three tabs
      does not clear state.
- [ ] **The "keep me logged in" allowlist**, offered in context at the moment a
      session is about to be lost, one click to add, visible as a plain list in
      settings. This determines whether the whole feature is usable.
- [ ] Conservative defaults: clear Marketing and Analytics, keep Functional,
      Necessary, and unknown. Aggressive handling of unknown cookies is a Blackout
      mode option with a plain warning.
- [ ] **Per-site panel**: rejected, hidden, blocked, cleared. Chrome-level,
      reading Gecko's content blocking log for the blocked count rather than
      counting independently. Do not invent a number for uBlock Origin's cosmetic
      hides; label honestly what we can and cannot itemize.
- [ ] Proton Pass offer added to first run, clearly optional, with the built-in
      vault equally weighted.

**Definition of done:** a 200-site test corpus, run before and after, showing
what cleared, what broke, and what was correctly kept. Publish it. This is the
feature most likely to generate support load and the evidence is the defense.

---

## Milestone 4: the interface

**8 to 14 weeks, and the range is wide because split view dominates it.**

- [ ] **Privacy dashboard**: extend the existing protections page with consent,
      cookie clearing, and DNS data. Medium patch.
- [ ] **Sidebar web panels** via `sidebarAction` in the first-party extension.
      Cheap, visible, high value per hour.
- [ ] **Vertical tabs**, if deferred from milestone 1.
- [ ] Interface polish against BRANDING.md section 7: `--void` grounds, `--corona`
      accents, per-mode chrome color coding, monochrome in Blackout mode.
- [ ] **Split view.** Scheduled last within this milestone, deliberately, so that
      cutting it costs nothing already built. ARCHITECTURE.md 6.8 flags it as the
      highest permanent maintenance cost in the spec. It is worth building only
      if the first three milestones landed comfortably.

**Definition of done:** the browser is visually coherent, and every mode looks
like what it does.

---

## Milestone 5: hardening and opt-ins

**5 to 8 weeks.**

- [ ] **Hardened HTTP profile** (ARCHITECTURE.md 6.3): warning bar, autofill
      suppression, third-party requests blocked via `webRequest`, optional JS off.
- [ ] **One-tap "trust this site" per origin.** Mandatory alongside it. Router
      admin pages, local devices, and intranet hosts are plain HTTP and are
      exactly where the browser must not get in the way.
- [ ] **Obfuscation mode**, opt-in, off by default, with the full explainer:
      possible terms-of-service violation, increased fingerprintability,
      bandwidth and battery cost. Implementation depends on the milestone 0
      signing decision; if bundling is not possible, ship it as a documented
      link-out.
- [ ] Per-site fingerprinting exceptions UI, if not already folded into the
      milestone 1 step-down.

---

## Milestone 6: Totality window

**10 to 16 weeks. The single largest desktop item.**

Per BRANDING.md: "Totality window, powered by Tor", `--relay` violet chrome, the
ring with three violet dots.

- [ ] **Stage 1: Arti as a bundled child process** exposing SOCKS5, launched and
      supervised by the browser. Not in-process. ARCHITECTURE.md 6.5 explains
      why.
- [ ] Per-window proxying, attempted first through the `proxy` WebExtension API
      with a dedicated contextual identity, and only patched into the window's
      load context if that proves insufficient.
- [ ] **Leak prevention, which is the actual feature**: WebRTC off, DNS through
      the proxy, no cache shared with the normal profile, RFP on, no extensions
      in that window that phone home.
- [ ] Designed bootstrap UI. Ten to thirty seconds of connecting is normal and
      must not look like a hang.
- [ ] The honest disclaimer on first use: **not as anonymous as Tor Browser**,
      with a one-sentence explanation of why (anonymity comes from everyone
      looking identical, and an Antumbra window looks like Antumbra).
- [ ] Contact the Tor Project about trademark usage **before** launch, not after.
- [ ] Set expectations about blocked exit nodes and CAPTCHAs in the UI.

Stage 2, in-process Arti, is explicitly deferred until its embedding API is
stable and there is a concrete reason to pay for it.

---

## Milestone 7: VPN partner button

**1 to 2 weeks of work, placed here for sequencing reasons, not effort.**

Spec section 7. Everything in ARCHITECTURE.md 6.6 is a requirement, not a
suggestion:

- [ ] Four partners, links from `third_party/data/partners.json`, currently
      `[INSERT LINK]` placeholders.
- [ ] **Labeled as affiliate in the panel itself**, in visible text.
- [ ] **NordVPN and Surfshark shared ownership disclosed** next to both.
- [ ] Removable permanently with one right-click.
- [ ] No click telemetry, plus the honest caveat in the privacy policy: we record
      nothing, the destination records the click as it would any link.
- [ ] CI test enforcing that no partner ID can ever reach a user-initiated
      navigation (ARCHITECTURE.md 2.3). This is the rule Brave broke in 2020 and
      it is worth a permanent test.

Placing this after milestone 6 is a deliberate trade of revenue timing for
credibility. Move it earlier only with clear eyes about how the launch coverage
will read.

---

## Milestone 8 and beyond: Android

**20 to 30 weeks. Effectively a second project.**

Spec section 10. ARCHITECTURE.md section 7 covers the decision that determines
whether this is affordable.

- [ ] **Confirm the prebuilt GeckoView approach.** Building GeckoView from our
      patched Gecko means four ABIs of full Gecko build per release and doubles
      the maintenance burden permanently. Prebuilt GeckoView covers most of the
      Android spec and costs a fraction.
- [ ] Fenix fork with Antumbra branding.
- [ ] Bottom toolbar with a swipe-in tab drawer.
- [ ] uBlock Origin preinstalled. Verify Android extension support against the
      pinned GeckoView.
- [ ] The same pref set as desktop, from one shared source of truth.
- [ ] Tor as an in-app proxy. Simpler than desktop in one respect: no per-window
      concept to plumb.
- [ ] **Google Play**: read the policies on content blocking and on
      Tor-enabled apps carefully before building, not after rejection.
- [ ] **F-Droid**: F-Droid builds from source on their own infrastructure, which
      conflicts with prebuilt GeckoView. Expect to run our own F-Droid repository
      first and pursue inclusion in the main repository later, if at all.

Android is where Play and F-Droid requirements pull in opposite directions, which
is the main reason it is a separate phase rather than an extension of the desktop
work.

---

## Ongoing, from the first public build onward

This never stops and should be budgeted as real recurring time, not as slack.

| Cadence | Work |
|---|---|
| **Per upstream security release** | Rebase, build, smoke test, ship. Target measured in days, published in `SECURITY.md`. |
| **Every 4 weeks** | Pref audit review, bundled extension version bumps, filter list and Open Cookie Database refreshes. |
| **Annually (ESR)** | The major rebase. Budget one to two hard weeks. Every layer 5 patch is re-evaluated here, and this is the natural moment to drop one that has become too expensive. |
| **Continuously** | Site breakage reports. This is the dominant support cost for any browser with aggressive defaults, and it arrives forever. |

Rough steady-state estimate once everything in this roadmap has shipped: **one to
two days per week** of maintenance before any new feature work. If that is not
available, the roadmap should be cut, not compressed.

---

## Risk register

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| **Maintenance overtakes development** | High | Fatal | ESR base, layer discipline, drop patches at the annual rebase rather than nursing them. |
| **Security update lag** | Medium | Fatal to trust | Automated rebase and build on upstream tag, published SLA, ship before features. |
| **Cookie clearing logs users out** | High | Severe churn | Conservative defaults, in-context allowlist, the 200-site corpus in milestone 3. |
| **VPN affiliate links define the narrative** | Medium | Severe reputational | Milestone 7 placement, disclosure in the panel, the CI test, and never touching typed URLs. |
| **Signing costs or certificate issuance blocks release** | Medium | Delays milestone 2 | Start the certificate process during milestone 1, not at the end. Issuance takes weeks. |
| **Split view consumes the maintenance budget** | Medium | Severe | Scheduled last within milestone 4, explicitly droppable. |
| **Totality window leaks** | Medium | Fatal to trust | Treat leak testing, not routing, as the deliverable. Do not ship it until a capture proves it. |
| **Trademark objection to Antumbra** | Low to medium | Severe rework | The Class 9 and 42 clearance opinion in BRANDING.md, done before launch, not after. |
| **Solo-dev bus factor** | Certain over time | Fatal | Patch series over forked tree, everything documented, the repository buildable by a stranger from `README.md` alone. |
| **Google Play rejection on Android** | Medium | Delays milestone 8 | Read policy first, F-Droid and direct APK as the fallback distribution. |

---

## What would make this project fail

Stated plainly, because roadmaps usually do not.

1. **Shipping features faster than security updates.** The moment Antumbra is
   two weeks behind on a critical Firefox CVE, every privacy claim in
   BRANDING.md becomes a liability.
2. **Building split view and the Totality window before milestone 2.** Both are
   irresistible and both are enormous. Platform support and updates are neither,
   and they matter more.
3. **Letting the first broken site have no escape hatch.** Aggressive defaults
   without a one-click per-site relaxation train users to turn protection off
   globally. Then the browser is Firefox with a different icon.
4. **Leading with the affiliate button.** It is a few days of work and it can
   cost the entire positioning.
5. **Forking the tree instead of maintaining a patch series.** This is the one
   that has quietly killed the most browser forks, and it happens gradually
   enough that nobody notices until the next rebase is impossible.
