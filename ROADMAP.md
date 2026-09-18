# Antumbra: roadmap

**Status: draft for review.** Written 2026-09-18. Sequences the work described in
[ARCHITECTURE.md](ARCHITECTURE.md), under the decisions recorded in
[DECISIONS.md](DECISIONS.md). Naming follows [BRANDING.md](BRANDING.md).

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

## Milestone 0: groundwork

**2 to 4 weeks. No shippable output. Do not skip it.**

Every hour here saves days later. The deliverable is a Windows machine that
builds unmodified Firefox end to end, plus a repository skeleton ready to take
patches.

The decisions that used to live in this milestone are made. See
[DECISIONS.md](DECISIONS.md): ESR with a patch series (D6), Total Cookie
Protection only (D1), Arti as a child process (D2), signing enforcement on (D3),
VPN button at milestone 7 (D4), Remote Settings and Safe Browsing on and
disclosed (D5), Windows first (D7). Four questions remain open and are listed at
the end of that file.

### Build machine setup (Windows)

Antumbra is built on Windows first (D7), natively, on the maintainer's own
desktop. Claude Code runs on that machine for build work. **Cloud sessions handle
documentation, planning, patch review, and pref auditing, and must not attempt
builds:** they have neither the disk nor the job time limit for a Firefox build.

Mozilla's authoritative page is
[Building Firefox On Windows](https://firefox-source-docs.mozilla.org/setup/windows_build.html).
Follow it if anything below has drifted. These steps are that page plus the
things worth knowing before you start.

#### Before you begin: what actually determines build speed

| Matters a lot | Matters a little | Does not matter |
|---|---|---|
| CPU core count | Windows 11 Dev Drive (5 to 10 percent) | **The GPU** |
| RAM (link steps are memory-hungry) | | |
| NVMe throughput | | |

**The RTX 3080 will not shorten a single build.** Firefox compilation is
CPU-bound and IO-bound and the GPU sits idle throughout. It earns its place on
this project a different way: it is genuinely useful for testing Antumbra's
graphics paths (WebRender, hardware video decode, compositor behavior), which is
a real advantage of developing on a workstation rather than a build server.

**RAM.** Mozilla's stated floor is 4 GB, with 8 GB or more recommended. Treat
that as the absolute minimum to complete a build, not a target. For comfortable
work: **16 GB minimum, 32 GB recommended.** Parallelism is what eats memory, and
the link step is the peak. If a build dies during linking, reduce the job count
before assuming something is broken.

**Disk.** At least 40 GB free, and that is tight once you have an object
directory, a `.mozbuild` toolchain cache, and `sccache`. Budget 150 to 200 GB.

#### Step 1: folder locations

Path choice causes more first-time Windows build failures than anything else.

- **No spaces and no special characters** anywhere in the path. This is a hard
  build failure, not a warning.
- Keep paths short. Windows path length limits bite deep in the object
  directory. Enable long path support if you hit file-not-found errors partway
  through a build.
- **Do not put the source tree inside OneDrive, Dropbox, or any synced folder.**
  A sync client trying to upload a million intermediate object files will ruin
  the machine's day and corrupt builds.

Use the defaults, which are chosen to avoid all of this:

```
C:\mozilla-build      MozillaBuild itself
C:\mozilla-source     the Firefox source tree
%USERPROFILE%\.mozbuild   toolchains fetched by bootstrap
```

**Windows 11 Dev Drive:** if you have the spare capacity, create one and put
`C:\mozilla-source` on it. Mozilla measures 5 to 10 percent faster builds. It is
free performance on a machine that already has the SSD space.

#### Step 2: Visual Studio Build Tools

Firefox needs the MSVC toolchain. Recent versions of `bootstrap.py` can provision
much of this for you, so run step 4 first and come back here only if it asks for
a compiler.

To install it explicitly, **Visual Studio Build Tools 2022** is sufficient; the
full Visual Studio IDE is not required.

```powershell
winget install --id Microsoft.VisualStudio.2022.BuildTools --override ^
  "--quiet --wait --add Microsoft.VisualStudio.Workload.VCTools --includeRecommended"
```

Or install interactively and select:

- Workload: **Desktop development with C++**
- Individual components: **MSVC v143 x64/x86 build tools**, the **Windows 11
  SDK**, and **C++ ATL for latest v143 build tools (x86 and x64)**

Reboot afterwards if the installer asks. Do not skip the ATL component: it is
easy to miss and the failure it causes appears much later in the build.

#### Step 3: MozillaBuild

MozillaBuild is the MSYS2-based shell environment that carries the bash, Python,
git, and assorted Unix tools the build system expects.

1. Download `MozillaBuildSetup-Latest.exe` from
   [ftp.mozilla.org/pub/mozilla/libraries/win32/](https://ftp.mozilla.org/pub/mozilla/libraries/win32/).
2. **Accept the default install directory** (`C:\mozilla-build`).
3. Make a shortcut to `C:\mozilla-build\start-shell.bat`. That shell, not
   PowerShell or cmd, is where every build command runs.

Two environment gotchas from Mozilla's docs, both of which produce confusing
failures:

- **Do not have a `PYTHON` environment variable set.**
- If Cygwin is installed, **MozillaBuild's paths must come first in `PATH`.**

#### Step 4: bootstrap and first checkout

In the MozillaBuild shell:

```bash
cd /c/
mkdir mozilla-source
cd mozilla-source
wget https://raw.githubusercontent.com/mozilla-firefox/firefox/refs/heads/main/python/mozboot/bin/bootstrap.py
python3 bootstrap.py
```

Bootstrap clones the tree and fetches the toolchains (clang, Rust, cbindgen,
nasm, Node). It will raise a **UAC prompt for PowerShell: answer Yes.** That step
adds the Microsoft Defender exclusions described below automatically, and
skipping it costs a large amount of build time for no benefit.

Then pin to ESR per D6, rather than tracking `main`:

```bash
cd firefox
git fetch --tags
git checkout <FIREFOX_ESR_TAG>     # recorded in upstream.conf
```

#### Step 5: Windows Defender exclusions

The single highest-leverage speed change on Windows. Real-time scanning inspects
every one of the hundreds of thousands of files a build touches, and the cost is
large.

Bootstrap adds these for you if you accepted the UAC prompt. Verify them, and add
them by hand if not, under Windows Security, Virus and threat protection,
Manage settings, Exclusions:

```
C:\mozilla-build
C:\mozilla-source
%USERPROFILE%\.mozbuild
```

PowerShell, run as Administrator:

```powershell
Add-MpPreference -ExclusionPath "C:\mozilla-build"
Add-MpPreference -ExclusionPath "C:\mozilla-source"
Add-MpPreference -ExclusionPath "$env:USERPROFILE\.mozbuild"
```

If third-party antivirus is installed, exclude the same paths there too. It is
usually the larger offender.

#### Step 6: first build

```bash
cd /c/mozilla-source/firefox
./mach build
./mach run
```

**Until `./mach run` launches a working browser, nothing else in this roadmap
matters.** Budget a day or two for this the first time, most of it spent on
toolchain problems rather than on the build itself.

#### Realistic build times

Highly dependent on core count. Wide ranges because they are honest ones.

| Build type | Time | When you use it |
|---|---|---|
| **Clean full build**, 8 cores | 60 to 120 minutes | First build, after a rebase, after a mozconfig change |
| **Clean full build**, 16 cores | 30 to 60 minutes | Same |
| **Incremental**, C++ change | 2 to 15 minutes | Editing Gecko. A widely included header touches everything and approaches a full rebuild. |
| **`./mach build faster`** | Seconds to ~2 minutes | **Frontend only**: JS, CSS, XHTML, prefs, branding assets. This is most of Antumbra's milestone 1 work. |
| **Artifact build** | 1 to 5 minutes | Frontend iteration only. See the warning below. |

Two things that will save more time than any hardware upgrade:

- **`./mach build faster` is the command you will live in.** Milestone 1 is
  almost entirely branding, prefs, and one frontend onboarding patch, all of
  which it rebuilds in seconds.
- **Artifact builds** (`ac_add_options --enable-artifact-builds`) download
  Mozilla's prebuilt binaries and build only the frontend, turning a 30-plus
  minute build into 1 to 5 minutes. **They are for iteration only and can never
  produce a release.** The downloaded binaries are Mozilla's official builds,
  which means Mozilla branding and the telemetry we compile out are both present.
  Keep a separate mozconfig for artifact builds so this can never be confused
  with a release build.

Set up **sccache** (bootstrap can configure it) so that rebuilds after a rebase
reuse work instead of starting from zero. On a patch-series project that is a
recurring, meaningful saving.

#### Step 7: Claude Code on the build machine

```powershell
winget install OpenJS.NodeJS.LTS
npm install -g @anthropic-ai/claude-code
claude
```

A native Windows installer also exists; see the Claude Code docs at
[code.claude.com/docs](https://code.claude.com/docs) for the current options.

**The one integration detail that matters:** `mach` must run inside the
MozillaBuild shell, not in PowerShell. Rather than rely on remembering that, add
a wrapper to the repository so a single command works from anywhere:

```bat
:: scripts\mach.cmd
@echo off
C:\mozilla-build\start-shell.bat -c "cd /c/mozilla-source/firefox && ./mach %*"
```

Then `scripts\mach.cmd build faster` works from a normal terminal, and Claude
Code can drive builds without a shell-environment detour every time.

### Remaining milestone 0 checklist

- [ ] Working `./mach run` on the Windows machine, per the steps above.
- [ ] Defender exclusions verified, `sccache` configured, artifact-build mozconfig
      kept separate from the release mozconfig.
- [ ] Claude Code installed on the build machine, `scripts\mach.cmd` wrapper
      working.
- [ ] Pin `upstream.conf` to a specific Firefox ESR tag.
- [ ] Create the repository skeleton from ARCHITECTURE.md section 9.2.
- [ ] Write `THIRD-PARTY.md`, `SECURITY.md`, `CONTRIBUTING.md` (including the
      standing no-crypto, no-rewards, no-sponsored-content rule from spec section
      9).
- [ ] Produce the icon set per BRANDING.md section 6, hand-tuned at 16, 32, and
      48px, all four mode variants.
- [ ] Verify against the pinned ESR base whether native vertical tabs are
      available (ARCHITECTURE.md 6.8). This determines whether a headline design
      feature is free or deferred.
- [ ] **Start the Windows code signing process now, not at milestone 2.**
      Identity validation takes days and SignPath Foundation review takes longer.
      See BRANDING.md's launch checklist.
- [ ] Answer the four open questions in DECISIONS.md, or at least the funding one.

**Definition of done:** a clean checkout on the Windows machine produces a
working, unbranded Firefox via one documented command, and CI runs the fast lane
(pref audit, patch apply, lint) on every push.

---

## Milestone 1: the smallest shippable desktop build

**6 to 10 weeks. The first public release. Windows x86_64 only (D7).**

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
- Windows x86_64 installer plus a portable ZIP, published on GitHub Releases with
  SHA-256 sums.
- **Signed if signing is in place, and honest about it if not.** If the
  certificate has not landed by release, the download page must say plainly that
  Windows will show a SmartScreen warning and what the user should expect. Do not
  let a non-technical user meet that dialog unprepared.
- A privacy policy that is accurate, including the Remote Settings and Safe
  Browsing disclosures from ARCHITECTURE.md 5.8.

### Explicitly out of scope for milestone 1

Cookie clearing on tab close, the per-site consent panel, the privacy dashboard,
Obfuscation mode, the hardened HTTP profile, Proton Pass, the Totality window,
the VPN button, split view, web panels, Linux, macOS, Android, and the built-in
updater.

That list is long on purpose. Each item is a milestone-1 delay and none of them
is required for the release to be genuinely useful and genuinely private.

### Definition of done

- Installs and runs on a clean Windows 10 and Windows 11 install, not just the
  build machine.
- **Daily-driven by the maintainer for at least two weeks before release.** This
  is the point of building Windows first (D7), and it is a release gate, not a
  suggestion.
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

Unglamorous and more important than any feature. Without it, Antumbra is one
person's Windows build, which is not a product.

- [ ] **Windows code signing in place**, if it did not land during milestone 1.
      Unsigned binaries trigger SmartScreen warnings that will destroy install
      conversion. Options, costs, and the free open source route are in
      BRANDING.md's launch checklist.
- [ ] **Register the Windows desktop as a self-hosted GitHub Actions runner**
      (D7), so Windows release builds stop depending on someone being at the
      keyboard. Never run self-hosted jobs on pull requests from forks.
- [ ] **Linux x86_64 build** in CI, on GitHub larger runners, plus a tarball and
      Flatpak. Cheapest platform technically; it waited only because nobody was
      daily-driving it.
- [ ] **macOS universal build**, Apple Developer Program membership,
      notarization, DMG packaging. Without notarization, Gatekeeper blocks it.
- [ ] **Built-in updater**: MAR signing keys generated and placed in documented
      custody, an update endpoint, and the build change. Losing this key ends the
      ability to update every installed copy.
- [ ] Package manager presence: winget first (it is the Windows audience's
      update path before the built-in updater exists), then Flatpak, AUR, and a
      Homebrew cask.
- [ ] Publish the **security response commitment** in `SECURITY.md` with a
      specific day count, and demonstrate it by shipping the first upstream
      security release on schedule.
- [ ] Crash and bug reporting workflow that works without a crash reporter, since
      it is compiled out. This means good, structured issue templates and clear
      reproduction guidance.

**Definition of done:** a non-technical user on Windows, Linux, or macOS can
download, install, and receive an automatic update, with no security warnings
anywhere in the flow.

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
| **Signing or certificate issuance blocks release** | Medium | Delays milestone 1 | Start the process in milestone 0, not milestone 2. Identity validation takes days and SignPath Foundation review takes longer. A free or 10 USD per month route exists; see BRANDING.md. |
| **SmartScreen warnings on early releases** | **High, expect it** | Severe conversion loss | Reputation accrues per signing identity over downloads, and since 2024 not even EV bypasses it. Sign consistently from the first release so reputation starts accumulating, and warn users on the download page until it clears. |
| **Split view consumes the maintenance budget** | Medium | Severe | Scheduled last within milestone 4, explicitly droppable. |
| **Totality window leaks** | Medium | Fatal to trust | Treat leak testing, not routing, as the deliverable. Do not ship it until a capture proves it. |
| **Trademark objection to Antumbra** | Low to medium | Severe rework | The Class 9 and 42 clearance opinion in BRANDING.md, done before launch, not after. |
| **Solo-dev bus factor** | Certain over time | Fatal | Patch series over forked tree, everything documented, the repository buildable by a stranger from `README.md` alone. |
| **Single build machine is a single point of failure** | Medium | Weeks lost | Everything needed to rebuild the environment is in milestone 0's setup steps. Move to the self-hosted runner in milestone 2 so builds are reproducible off one keyboard. |
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
