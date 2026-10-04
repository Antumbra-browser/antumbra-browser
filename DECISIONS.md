# Antumbra: decision log

Decisions that shape the project, with the reasoning behind them, in the order
they were made. Newest section at the bottom.

This file is the record of **why**. [ARCHITECTURE.md](ARCHITECTURE.md) and
[ROADMAP.md](ROADMAP.md) describe **what** and **when**, and are kept in sync
with whatever is decided here. When the two disagree, this file is the source of
truth and the others are stale.

A decision here can be revisited. Reversing one means adding a new entry that
supersedes the old one, not editing history.

---

## 2026-09-18

Seven decisions, resolving the open questions raised in ARCHITECTURE.md section
13 plus one change of direction on build platform.

---

### D1. First-Party Isolation: ship Total Cookie Protection only

**Decision.** Total Cookie Protection (dynamic First-Party Isolation,
`network.cookie.cookieBehavior = 5`) is the default everywhere. Legacy
First-Party Isolation (`privacy.firstparty.isolate`) is **off in Standard,
Strict, and Blackout mode**, and enabled **only inside the Totality window**.

**Reasoning.**

First-Party Isolation and Total Cookie Protection are two generations of the same
idea, and running both produces unpredictable interactions for no measurable
gain. FPI is the older and blunter of the two: it is effectively deprecated
upstream, is not well tested against modern code paths, and breaks federated
login broadly. Total Cookie Protection is its supported successor, gives
substantially the same partitioning, and carries heuristics that keep common
login flows working. Tor Browser itself migrated from FPI to dFPI, which is the
strongest available signal about which one to build on.

Confining FPI to the Totality window keeps the stricter guarantee available in
the one context where the user has already accepted that things will break, and
where breakage is expected for other reasons anyway (blocked exit nodes,
CAPTCHAs). It costs one line in the Totality window's profile.

**Consequence.** The original feature spec asked for both. This narrows it. If
the FPI pref is removed upstream entirely, the Totality window loses that one
extra guarantee and nothing else changes, which is the right blast radius.

**Affects:** ARCHITECTURE.md 5.2, 6.5, summary table row 1.2b.

---

### D2. Arti: supervised child process first, embedding later

**Decision.** The Totality window ships Tor as **Arti running as a supervised
child process exposing SOCKS5**, launched and monitored by the browser. Linking
Arti in-process is deferred to a later stage with no committed date.

**Reasoning.**

Arti is the right destination: it is Tor's own Rust implementation, MIT or
Apache 2.0 licensed, and actively developed. But embedding it in-process inside
Gecko means linking a large async Rust stack into the Firefox build against an
API that is still evolving, which buys build complexity and an entirely new
class of crash before a single user benefits.

A supervised child process contains the failure modes. If Arti dies, the Totality
window shows an error rather than taking the browser down with it. It is also how
Brave ships Tor windows, so the approach has been proven at scale by someone
else.

The per-window plumbing, which is the genuinely hard part of this feature, is
identical either way. Nothing is wasted by starting with the process model.

**Consequence.** One extra binary to ship, sign, and notarize per platform.
Accepted.

**Affects:** ARCHITECTURE.md 6.5, ROADMAP.md milestone 6.

---

### D3. AdNauseam: install the signed AMO build, signing enforcement stays on

**Decision.** Obfuscation mode installs **AdNauseam from
addons.mozilla.org**, as the Mozilla-signed build. Antumbra ships with **extension
signature enforcement left on**. No `MOZ_REQUIRE_SIGNING=0`, and no relaxation of
`xpinstall.signatures.required`.

Obfuscation mode remains **opt-in and off by default**, with the full explainer
intact.

**Reasoning.**

The earlier architecture draft assumed AdNauseam was still self-distributed
following its 2017 removal from AMO, and on that basis recommended either
disabling signature enforcement or dropping the feature to a link-out. That
assumption was wrong. AdNauseam is listed on AMO and is signed and installable
(version 3.28.8, last updated 2026-07-20, GPLv3, verified 2026-09-18).

That removes the entire reason to weaken signing. Disabling signature enforcement
would have loosened security for **every** extension the user ever installs, in
order to enable one optional feature. Keeping enforcement on is strictly better
and costs nothing now.

The reasons Obfuscation mode stays off by default are unchanged and are not about
signing:

1. It may violate ad network terms of service, and has been characterized as
   click fraud in some jurisdictions.
2. It makes the user **more** fingerprintable, not less. A browser generating
   distinctive click patterns has a distinctive signature, which works against
   spec section 1.
3. It costs bandwidth and battery, which matters on metered connections and on
   Android.

A user turning it on is making a trade, not stacking a benefit, and the explainer
must say so.

**Consequence.** AdNauseam and uBlock Origin are both uBlock Origin lineage and
cannot run together, so enabling Obfuscation mode still swaps one for the other
and still needs filter settings migrated between them. That complexity is
unchanged.

**Affects:** ARCHITECTURE.md 6.2, 11.2, summary table row 3b, section 13 open
question 5 (closed).

---

### D4. VPN partner button: sequenced after the privacy work

**Decision.** The VPN toolbar button ships in **milestone 7**, after the Totality
window, not at launch. All disclosure requirements stand, and the CI rule that
**no partner ID can reach a user-initiated navigation** is permanent.

**Reasoning.**

The button is one to two weeks of work and could ship in milestone 1. Sequencing
it late is a deliberate trade of revenue timing for credibility. A privacy
browser whose first release contains affiliate links reads as an affiliate scheme
with a browser attached, and that framing is very hard to undo once it is the
top comment on the launch post.

The CI rule is not about sequencing and does not expire. Brave appended affiliate
codes to user-typed URLs in 2020 and paid for it for years. Antumbra never
modifies a URL the user entered, autocompleted, clicked, or bookmarked for any
commercial reason. Affiliate links exist only as the destination of a button the
user deliberately presses, in a panel that says it is affiliate marketing. A
static test enforces that there is no code path from the address bar to a partner
ID.

**Consequence.** Revenue arrives later than it could. Accepted.

**Affects:** ARCHITECTURE.md 2.3, 6.6, ROADMAP.md milestone 7.

---

### D5. Safe Browsing and Remote Settings: on and disclosed

**Decision.** Keep **Remote Settings** on. Keep **Safe Browsing** local list
checks on. Keep the **per-download remote lookup off**. Disclose all three
prominently in onboarding, the privacy dashboard, and the privacy policy.

**Reasoning.**

Both are network connections a user on a zero-telemetry browser might not expect,
and the honest answer is disclosure rather than removal.

Remote Settings is a download, not an upload. It carries cookie banner rules
(which spec section 2 layer A depends on), certificate revocation data, tracking
protection list updates, the public suffix list, and HSTS preload updates.
Turning it off would trade real security, stale certificate revocation most
seriously, for a purity claim. Normandy and studies, which are the parts we
genuinely do not want, are disabled separately and specifically.

Safe Browsing's local list checks are what protect users from phishing, and
Antumbra's stated audience is precisely the audience that gets phished. Removing
it silently would make those users less safe overall while the marketing says the
opposite. The part that actually sends URLs to Google is the per-download remote
lookup, and that stays off.

This is a defensible position **only if it is explained**. Hiding it would be
worse than not doing it.

**Consequence.** Antumbra cannot claim "contacts no third party ever". It claims
something more precise and more honest, and the documented network capture in
milestone 1 proves it.

Self-hosting a Remote Settings mirror remains the correct long-term answer and
stays on the roadmap as a later item, not a launch blocker.

**Affects:** ARCHITECTURE.md 5.8, section 13 open questions 3 and 4 (closed).

---

### D6. ESR base with a patch series over a pinned upstream tag

**Decision.** Track **Firefox ESR**, pinned to a specific tag in
`upstream.conf`, and maintain all changes as an ordered **patch series** applied
to it. No long-lived fork of mozilla-central.

**Reasoning.**

Two separate choices that reinforce each other.

The patch series is the more important one. A permanent branch of the Firefox
tree that you merge upstream into is how solo browser forks die: conflict
resolution in a 20-million line tree with an opaque history is unbounded work,
and it degrades gradually enough that nobody notices until the next rebase is
impossible. With a patch series, every change is explicit and named, a rebase
failure is scoped to one patch, and the cost of each feature stays legible as the
size and fragility of its patch. A patch that becomes too expensive gets dropped
and the feature degrades visibly instead of the tree rotting silently.

ESR turns the major rebase into a scheduled, bounded, once-a-year event instead
of a 4-week treadmill that runs forever. For a solo developer the treadmill is
the single most likely cause of project death in year one.

The cost is real: privacy improvements that land in Release reach Antumbra up to
a year late. Security fixes are **not** delayed, because ESR receives them on the
same day. Where a specific upstream privacy feature matters before it reaches
ESR, it gets backported as its own patch, which is a costed per-feature decision
rather than a standing commitment.

**Consequence.** Revisit if the project ever gains a second full-time maintainer.

**Affects:** ARCHITECTURE.md 3.1, 3.2, section 13 open questions 1 and 2
(closed).

---

### D7. Windows first, Linux later via CI

**Decision.** Milestone 0 and milestone 1 target **Windows x86_64**. Linux and
macOS move to milestone 2 and are built in CI.

Builds run **locally on a Windows desktop** (modern CPU, NVIDIA RTX 3080, ample
SSD), with Claude Code installed on that machine for build work. **Cloud sessions
are for documentation and planning only.** That same Windows machine later
becomes a self-hosted GitHub Actions runner.

**Reasoning.**

This reverses the earlier recommendation to start on Linux, and the reason is
better than the reason for the original ordering.

The original case for Linux first was that it is the cheapest target: no
signing, no notarization, simplest toolchain. That is true and it is not the
point. **The first platform should be the one the maintainer daily-drives.** A
browser gets debugged by being used, and the fastest feedback loop available is
the maintainer noticing something broken during their own ordinary browsing. A
Linux-first build that the maintainer never runs would be tested by intention
rather than by use.

Windows is also the largest desktop user base by a wide margin, so the
non-technical audience Antumbra is built for is disproportionately there. Getting
that platform right first aligns the hardest audience with the most attention.

The build machine argument reinforces it: the hardware exists, it has the cores,
RAM, and NVMe that matter, and using it directly removes the cloud builder from
the critical path entirely.

**One correction worth recording:** the **RTX 3080 contributes nothing to build
speed.** Firefox compilation is CPU-bound and IO-bound. Cores, RAM, and NVMe
throughput determine build times; the GPU is idle throughout. It is useful for
testing Antumbra's own graphics paths (WebRender, hardware video decode,
compositor behavior), which is a real benefit, but not for building.

**Consequence.** Windows code signing becomes a milestone 2 blocker rather than a
later concern, because unsigned Windows binaries trigger SmartScreen warnings
that would destroy install conversion for exactly the audience being targeted.
See the Windows code signing item in BRANDING.md's launch checklist.

The separation of duties is explicit: **cloud sessions must not attempt builds.**
They have neither the disk nor the time limit for a Firefox build, and pretending
otherwise wastes hours. Documentation, planning, patch review, and pref auditing
work fine in the cloud. Compilation happens on the Windows machine.

**Affects:** ARCHITECTURE.md 10.1, 10.2, ROADMAP.md milestones 0, 1, and 2.

---

## 2026-09-22 (milestone 0 hardware run)

---

### D8. Pin to Firefox ESR 153, tag FIREFOX_153_3_0esr_RELEASE

**Decision.** The initial upstream pin is `FIREFOX_153_3_0esr_RELEASE`
(Firefox 153.3.0esr), recorded in `upstream.conf`.

**Reasoning.**

Three ESR generations were available at bootstrap time: ESR 128, ESR 140,
and ESR 153. ESR 128 is end-of-life. ESR 140 is ending in approximately
October 2026, which would force an immediate major rebase. ESR 153 is the
current active generation, released mid-2026, with a support window running
through approximately late 2027. Pinning to it gives the longest runway before
the next annual rebase and uses the most recent privacy and security work
from upstream.

The specific point release (153.3.0) is the latest available RELEASE tag as
of 2026-09-22. The tag is chosen from the repo at bootstrap time per D6.

**Affects:** `upstream.conf`, ROADMAP.md milestone 0 checklist.

---

## 2026-09-23

---

### D9. GSD as the task workflow; DECISIONS.md remains the single decision record

**Decision.** The project uses **GSD (get-shit-done-cc)** as its task-planning and execution
workflow, scaffolded under `.planning/`. GSD plans break milestone checklist items into
executable tasks and track execution state.

DECISIONS.md remains the single authoritative decision record. GSD-generated files under
`.planning/` are task management artifacts and do not override it. When a `.planning/` file
and any of DECISIONS.md, ARCHITECTURE.md, or ROADMAP.md disagree, the root-level document
is correct and the `.planning/` file is stale.

**Operational rules:**

1. Record decisions here (DECISIONS.md), not in `.planning/STATE.md` or plan summaries.
   If a decision surfaces during phase execution, add it to this file.
2. GSD plans under `.planning/phases/` scope tasks to what the authoritative ROADMAP.md
   already specifies. They do not add or remove milestone scope.
3. `.planning/STATE.md`, `.planning/todos/`, `.planning/debug/`, `.planning/spikes/`,
   `.planning/sketches/`, and `.planning/quick/` are gitignored. They are working
   state, not project record.
4. `.planning/config.json`, `.planning/PROJECT.md`, `.planning/ROADMAP.md`, phase
   PLAN.md files, and SUMMARY.md files are committed. They are part of the project
   history.

**Reasoning.**

The project has detailed authoritative documentation already. Running `/gsd-new-project`
would regenerate that documentation from scratch via questioning, producing competing
copies. Bootstrapping `.planning/` manually with thin pointer files and going directly
to `/gsd-plan-phase` preserves the existing docs as source of truth while gaining GSD's
task-breakdown and execution tracking.

The build machine constraint from D7 does not apply to local VS Code sessions, which have
full access to `D:\dev\antumbra\firefox`. GSD phase plans must still state which build
type verification requires (`./mach build faster` for frontend, full build for C++ or
Rust), because build times differ by two orders of magnitude.

**Affects:** `.planning/` directory (new), `.gitignore`.

---

## 2026-09-23 (Milestone 1 planning)

---

### D10. Bundled extensions auto-update from AMO; Antumbra never blocks extension security updates

**Decision.** Bundled extensions (uBlock Origin, Consent-O-Matic, Multi-Account
Containers) **auto-update from AMO**. The XPI files vendored in
`distribution/extensions/` serve as the initial install baseline only. After first
launch, Firefox's addon update service picks up newer versions from each extension's
AMO update manifest. `updates_disabled` is NOT set in `policies.json`.

**Reasoning.**

uBlock Origin and Consent-O-Matic are effective only when current. Their core value
is delivered through frequently updated filter lists, consent rules, and bug fixes.
A stale uBlock Origin ships outdated block lists that miss new trackers and ads. A
stale Consent-O-Matic misses new consent banner patterns. Pinning these extensions
would mean Antumbra's primary privacy layers degrade silently with every passing week.
An old blocker is a broken blocker.

Extension security updates are in the same category as browser security updates.
Blocking them to achieve version control is trading user security for operational
convenience. Antumbra does not make that trade.

The vendored XPI baseline exists so new installs start at a reviewed, working version
rather than at an AMO version that may be weeks ahead of any testing. The baseline
refresh process (`docs/extension-update-process.md`) keeps this starting point current
so the gap between shipped and current stays small.

**Consequence.** The vendored XPIs in `third_party/extensions/` are not a version pin.
They are a snapshot reviewed at release time. Users will run newer extension versions
than what was vendored, which is intentional. The refresh process (every 4 weeks and
at each Antumbra release) keeps the baseline close to AMO current.

**Affects:** `.planning/phases/01-milestone-1/01-03-PLAN.md` Task 2 and Task 3,
`prefs/policies.json`.

---

---

## 2026-09-26

---

### D11. Default search engine: DuckDuckGo in both normal and private windows

**Decision.** DuckDuckGo is the default search engine for all windows -- normal
and private -- set via `policies.json` SearchEngines. No search revenue
partnership is accepted at this stage.

**Reasoning.**

The open question asked whether taking search revenue is compatible with the
privacy positioning. The answer is: not yet, and not with the wrong partner.

A default search deal with Google would be incompatible with the stated
positioning regardless of revenue. Google is the largest surveillance advertising
business on the internet. Shipping Google as the default while describing
Antumbra as a privacy browser would be incoherent.

DuckDuckGo is the least-bad option among broadly available engines: no IP
logging by policy, no user profiling by policy, and a documented privacy
commitment that aligns closely enough with Antumbra's positioning to be
defensible in onboarding copy. It is also the engine most users expect to see
in a privacy browser, which reduces friction.

Revenue from a DuckDuckGo default is possible via their search attribution
program but is not a condition of this decision and is not being pursued in
milestone 1. This decision does not preclude revisiting a revenue arrangement
with DuckDuckGo or another privacy-aligned engine in a later milestone, provided
full disclosure is maintained.

The private window default is set to DuckDuckGo explicitly to prevent the
"separate private default" search banner from appearing and to keep behavior
consistent for users.

**Consequence.** No search revenue in milestone 1. Revisit at milestone 5 or
later alongside the VPN button decision (D4).

**Affects:** `prefs/policies.json`, open question 2 (closed).

---

## 2026-09-27

---

### D12. Disable weather widget: showWeather = false

**Decision.** `browser.newtabpage.activity-stream.showWeather` is set to `false` in `antumbra.js`.

**Reasoning.**

The weather widget on the new tab page makes an outbound request to Mozilla's Merino service on every tab open to determine the user's location. The request carries the user's IP address. This is a phone-home that the user did not ask for, that reveals location on a per-tab basis, and that has no privacy disclosure in Firefox's onboarding. It is incompatible with Antumbra's zero-unrequested-network-contact baseline and is disabled at the pref layer.

**Consequence.** No weather widget. No loss of privacy-relevant functionality.

**Affects:** `prefs/antumbra.js`.

---

### D13. Disable topsites/shortcuts section: feeds.topsites = false

**Decision.** `browser.newtabpage.activity-stream.feeds.topsites` is set to `false` in `antumbra.js`.

**Reasoning.**

The topsites section displays a "Drag important tabs here" placeholder populated with default vendor shortcuts (Firefox, Slack, Gmail logos). These are Mozilla-chosen brand relationships bundled into the new tab page with no user opt-in. The placeholder with vendor icons is incompatible with the no-sponsored-content, no-content-recommendations baseline in spec section 9 and ARCHITECTURE.md 6.9. This pref was listed in ARCHITECTURE.md 6.9's exclusion table but was accidentally omitted from the initial `antumbra.js`. This decision corrects that omission.

**Consequence.** No topsites row on the new tab page.

**Affects:** `prefs/antumbra.js`.

---

### D14. Build policy: cold builds required for branding, prefs, and packaged file changes

**Decision.** Any build that is meant to verify a change to branding assets, pref files, or chrome-packaged files (JS, CSS, HTML, JSON under the branding or components directories) must be a cold build from a wiped object directory. Incremental builds on these file types are not acceptable for verification purposes.

**Reasoning.**

Three builds were wasted between 2026-09-24 and 2026-09-27 because incremental builds silently reused stale object directory state. Pref file changes (`antumbra.js`) did not reach the binary. Chrome-packaged file changes (welcome page, policies.json) did not land because their jar was not repacked. Only a file with a timestamp change that forced the packager to re-run (an SVG) reached the binary. The incremental build gave no error or warning. The developer assumed the build was correct and proceeded to on-screen verification, which then failed.

The root cause is that Firefox's incremental build system tracks source timestamps, and a file that is identical to the indexed version is not repacked even if the output jar is missing or stale. A cold build starts from scratch and eliminates this class of silent failure.

**Rule:**
1. Wipe the object directory (`rm -rf obj-*`) before any build that verifies a pref, branding, policy, or packaged file change.
2. Confirm the built artifacts are present in the build output before requesting on-screen verification. Check for the specific files (antumbra.js in the JAR, policies.json in the distribution directory, welcome files in the chrome directory) by path before launching.
3. Never ask the user to verify what they see on screen if you have not independently confirmed the artifact is present in the build output.

**Affects:** `ROADMAP.md` build policy section, all future milestone execution.

---

## 2026-09-30

---

### D15. BLOCKING BUG: 0000-branding patch is not reproducible from a clean checkout

**Status.** This is a Milestone 1 blocker. The patch series is not reproducible from a clean Firefox tree.

**Problem.**

The `0000-branding` patch was generated with `git diff` without the `--binary` flag. Binary files (PNG, ICO, BMP, .car, and others) appear in the patch as lines of the form:

```
Binary files /dev/null and b/browser/branding/antumbra/... differ
```

`git apply` and `git apply --3way` cannot process this format. There is no binary content in the patch -- only the hash of the object that was staged. Running `scripts/apply-patches.sh` or `git apply` on a genuinely clean checkout will fail immediately on `Assets.car` (line 4).

All builds since the branding work began have succeeded only because the branding files were never fully removed from the Firefox tree between sessions. `git clean -fd` removed the staged index entries but left the directory structure in place (the files had already been copied manually or survived prior clean attempts). The build appeared to work from a clean state; it did not.

This means the patch series violates its own stated goal from D6 and ARCHITECTURE.md 3.1: that every change is an explicit, named patch and the build is reproducible from the repository state alone.

**Consequence.**

1. A developer following the documented bootstrap procedure (reset tree, run `scripts/apply-patches.sh`, build) cannot reproduce the build.
2. The CI patch-apply check in ARCHITECTURE.md 10.3 cannot be meaningfully implemented until this is fixed.
3. Any future developer who hard-resets the Firefox tree will have a broken build with no clear error message pointing at the patch.

**Fix required before Milestone 1 ships.**

Regenerate the `0000-branding` patch using `git format-patch --binary` or `git diff --binary` so the patch contains actual binary content in GIT binary patch format (`literal` or `delta` sections). Then prove reproducibility by:

1. Hard-resetting the Firefox tree to the pinned ESR tag (`git checkout FIREFOX_153_3_0esr_RELEASE`).
2. Removing all untracked files (`git clean -fdx`).
3. Running `scripts/apply-patches.sh` with all four patches applied in order.
4. Confirming the tree compiles to a working binary with a full cold build.

Until that is done, the branding source files in `antumbra-browser/branding/antumbra/` also need to be kept in sync with the final patch content, because they are the only reliable way to reconstruct the Firefox tree. Two files in the branding source directory are currently stale and must be updated as part of this fix:

- `branding/antumbra/content/jar.mn`: has `antumbra.jar:` format; correct format is `browser.jar:` with both the branding and the antumbra content sections.
- `branding/antumbra/content/antumbra-content/welcome.js`: imports `chrome://antumbra/content/AntumbraMode.sys.mjs`; correct import is `resource://antumbra/AntumbraMode.sys.mjs`.

**Affects:** `patches/0000-branding/`, `scripts/apply-patches.sh`, `branding/antumbra/`, all CI plans in ARCHITECTURE.md 10.3.

---

## 2026-10-03

---

### D16. RECURRING FAILURE PATTERN: fixes applied in the Firefox tree without regenerating the owning patch

**Status.** Structural guard added as a Milestone 1 blocker fix.

**Problem.**

Across Milestone 0 and Milestone 1 the same failure mode has blocked cold builds several times:

1. A developer applies the patch series to the Firefox source tree.
2. During a build session the developer discovers a problem (unsorted `FINAL_TARGET_FILES`, `DIRS` referencing a non-existent `moz.build`, a missing jar.mn, a chrome asset not registered in jar.mn).
3. The developer edits the file in place in the Firefox tree, the next build succeeds.
4. The regenerated patch is never written back to `patches/`, and the `branding/antumbra/` source copies are never updated.
5. The commit lands with a patch series that is incomplete relative to what actually produced the working binary.
6. The next cold build on any machine fails with an error that no longer appears anywhere in the committed artifacts.

Known evidence:

- `aboutDialog.css` was present in the Firefox tree and the shipped build for multiple sessions before it was discovered that no patch and no `branding/antumbra/` source copy produced it. The file existed only because an earlier session had copied it in manually.
- `browser/branding/antumbra/content/moz.build` had `FINAL_TARGET_FILES.browser.chrome.branding` in unsorted order in the committed `0000-01-branding-dir.patch` long after a session had locally sorted it to pass configure (`UnsortedError`). Rediscovered in 2026-10-03.
- `browser/branding/antumbra/locales/moz.build` shipped as `DIRS += ["en-US"]` in the committed patch despite the fix being documented in project memory. Rediscovered in 2026-10-03.
- `browser/branding/antumbra/locales/jar.mn` was created in the Firefox tree during a Milestone 0 session but never added to any patch. Rediscovered in 2026-10-03.

The common cause is that `git apply` to the Firefox tree does not stage the result in the antumbra-browser repo. The two trees are siblings, not linked, and a tree-side edit is invisible to anything that only inspects `antumbra-browser/`.

**Decision.**

Two structural guards, both automatic.

1. **`scripts/check-tree-sync.sh`** on the maintainer's machine. Creates a scratch worktree at the pinned ESR tag, applies the full patch series to it, and compares every owned path and every shared file against the current Firefox tree. Any difference is drift and exits non-zero. Intended to be run before every commit that touches `patches/` and before every `/gsd-ship` or push to main.

2. **`patch-source-sync-check` CI job** in `.github/workflows/fast-lane.yml`. Applies the patch series to a stub Firefox tree in CI and compares the result for `browser/branding/antumbra/` against the committed `branding/antumbra/` source copies. Fails on any mismatch in either direction (patch produces a file the source copy doesn't have; source copy exists for a file no patch produces; content differs). This runs on every push and PR and does not depend on a Firefox checkout.

**What the guard catches:**

- Patch output and `branding/antumbra/` source copy diverge in content.
- Patch creates a file not represented in `branding/antumbra/` (orphan patch output).
- `branding/antumbra/` has a file not produced by any patch (orphan source copy).
- Local-only drift on the maintainer's Firefox tree (local script only).

**What the guard does not catch:**

- Edits to upstream files that no patch currently touches and that live outside the owned prefix list in `check-tree-sync.sh`. If a developer modifies a file that no patch references and does not create a patch, neither guard flags it. Broaden the owned prefix list as new patch areas are added.
- Patches whose content is syntactically valid but semantically wrong (a pref typo that lands in `antumbra.js` and passes audit, for example). Caught by the pref audit CI job and by on-screen verification, not by this guard.
- Changes applied via symlinks, hard links, or anything outside git's view.

**Reasoning.**

The symptom in every past incident is "cold build fails on something that was fixed weeks ago". The root cause is that the Firefox tree is not a committed artifact and the patch series is, and a human step bridges the two. Any human step that is both (a) required for correctness and (b) easy to skip will be skipped. The response is to make the bridge detectable rather than require perfect discipline.

The two-guard shape is deliberate: the CI job catches patch/source-copy drift on every push, which stops bad commits from reaching main; the local script catches tree/patch drift before commit, which stops bad commits from being authored. Either alone leaves a hole.

**Consequence.**

Milestone 1 ships only after both guards are green and the drift-detector run on the maintainer's Firefox tree is clean.

**Affects:** `scripts/check-tree-sync.sh` (new), `.github/workflows/fast-lane.yml` (new `patch-source-sync-check` job), `branding/antumbra/` (now authoritative source copies, synced on every patch regeneration).

---

### D17. Milestone 1 verification findings: Mozilla-service entry points, promo card, add-on pane, native containers, error page

**Status.** Visual verification of the 2026-10-03 cold build surfaced five
items that go beyond brand-string removal. Four are decided or in-progress
here. One (Mozilla-service entry points) is **open** and listed below in
the still-open table.

**Fixed in this entry, pref-only, no decision needed:**

- `sidebar.verticalTabs.dragToPinPromo.dismissed = true`. The vertical-tabs
  sidebar renders a "Drag important tabs here to keep them within reach"
  card with Firefox, Slack, foxy, and Gmail icons until this pref is set.
  The card lives in `browser/components/sidebar/sidebar-pins-promo.mjs`
  and is pre-dismissable via the pref it already uses to track user
  dismissal. Pre-dismissing is cleaner than hiding the card via CSS,
  because the control already exists upstream and we are using it as
  intended. Added to `prefs/antumbra.js`.
- `extensions.getAddons.showPane = false` and
  `extensions.htmlaboutaddons.recommendations.enabled = false`. The first
  hides the "Recommendations" tab in about:addons. The second hides the
  Recommended Extensions cards in the list view. Together they remove
  every AMO-driven card from about:addons. The user-initiated "search for
  more add-ons" input in the sidebar is unaffected and continues to work;
  this is a separate question (see below) about whether Antumbra should
  keep AMO as the add-on source at all.

**Open sub-decisions deferred to the user, not resolved here:**

- Whether Antumbra should keep AMO as the add-on source. Keeping AMO is
  cheap (works out of the box, security review handled by Mozilla,
  no infrastructure needed) and consistent with the current signed-only
  posture (D3). Replacing it with a self-hosted mirror or allowlist means
  running the mirror and running the signing. Not a Milestone 1 decision
  unless the maintainer wants it to be.
- Multi-Account Containers: revisit cost estimates for the native UI
  replacement under revised constraints below.

**Container UI replacement: revised cost estimate.**

The 2026-09-18 plan assumed the native container UI was a Milestone 4
item and that bundling MAC unmodified for Milestone 1 was the cheap
path. The 2026-10-03 verification confirmed MAC does display
"Firefox Multi-Account Containers" in the toolbar tooltip and about:addons,
which is the branding inconsistency the Option-C note already captured.

What was missed: **forking MAC is more expensive than it looks because
of D3.** A fork requires either (a) submitting to AMO as a separately
named extension, which has unpredictable review cycles and risks a
near-duplicate rejection, or (b) signing it ourselves and relaxing
`xpinstall.signatures.required`, which D3 explicitly rules out. The
GPLv3 constraint from ARCHITECTURE.md 11.3 does not block a fork of
MPL 2.0 MAC, but it does block modifications to uBlock Origin, so the
pattern of "modify and reship" would set a precedent we would then
have to argue against for every other bundled extension.

Native container UI at **minimum viable** scope is a smaller job than
either plan assumed. The pieces needed:

1. Toolbar button that opens a picker panel. Chrome patch to
   `browser/base/content/navigator-toolbox.inc.xhtml` and new
   `antumbra-containers-panel.{xhtml,js,css}` under
   `browser/components/antumbra/`. Roughly a week.
2. Container picker and new-container dialog, both backed by the
   existing `contextualIdentity` WebExtension API that Gecko already
   exposes. No Gecko changes. Roughly a week including the two dialogs
   and the per-container color/icon list.
3. The "Open in container" context menu entry already exists upstream
   behind `privacy.userContext.enabled`. One pref flip in
   `antumbra.js` and nothing else.
4. Tab coloring to reflect the container colour. Small CSS patch to
   `browser/themes/shared/tabbrowser/tabs.css`, driven by the existing
   `useContextColors` attribute. A day.

Call it two to three weeks of chrome-patch work to replace MAC for the
primary use case of "two accounts on one site at once". MAC's
auto-containment rules (open domain X in container Y automatically) are
not in minimum-viable scope and can land later or stay out of scope.

Forking MAC is roughly one to two weeks of initial work plus 4 hours of
maintenance per MAC release times about 6 releases per year, i.e. 24
hours per year of ongoing cost, plus the signing problem above.

**Recommendation (not a decision until the user confirms).** Native
minimum-viable container UI, scheduled into Milestone 4 as currently
planned, is the cleaner path. For Milestone 1, ship MAC unmodified and
note the branding inconsistency in release notes, as the original
Option-C plan said.

**Error page illustration (Firefox fox).** Not currently tracked in
ROADMAP.md or ARCHITECTURE.md. It belongs in Milestone 4 under
"interface polish against BRANDING.md section 7" alongside the other
chrome-patch visual items. The error page itself lives in
`toolkit/content/aboutNetError.mjs` and `toolkit/content/net-error-card.mjs`,
not under `browser/`, which means the patch touches toolkit code and
should be scheduled with other toolkit-visual-polish items (not a huge
patch but it will rebase annually along with upstream's periodic
redesigns of the error page). Adding to Milestone 4 scope in this entry.

**Affects:** `prefs/antumbra.js`, `ROADMAP.md` Milestone 1 release
notes and Milestone 4 interface section, Milestone 4 scope list in
ARCHITECTURE.md 6.8.

---

### D18. Milestone 1 Mozilla-independence decisions: Q3, Q5, Q6, Q7 closed

**Status.** Four open questions from D17 and the original ARCHITECTURE.md
list are closed with the following decisions. Q4 (funding) remains open
but is owned by the maintainer directly, not by code; it stays in the
before-launch table.

**Q5. Firefox Accounts, Sync, and other Mozilla-service entry points: Option A, disable entirely.**

- `identity.fxaccounts.enabled = false` in `prefs/antumbra.js`.
- `services.sync.enabled = false` in `prefs/antumbra.js`.
- `DisableFirefoxAccounts: true` added to `prefs/policies.json`
  as belt-and-braces.
- The pref alone does not hide the toolbar button on ESR 153. The
  CSS at `browser/themes/shared/customizableui/panelUI-shared.css:732-734`
  only hides `#appMenu-fxa-status2` and `#appMenu-fxa-separator` when
  `:root[fxadisabled="true"]`. The `fxa-toolbar-menu-button` element has
  no `.sync-ui-item` class and is not covered by `onFxaDisabled()` in
  `browser/base/content/browser-sync.js:2903-2910`. Therefore a chrome
  patch is required to hide it: `patches/0400-fxa-ui-removal/0400-01-hide-toolbar-button.patch`
  extends the existing selector to include `#fxa-toolbar-menu-button`.
  Minimal patch; follows upstream's own disable mechanism; does not
  introduce a new attribute or require JS changes.
- Pref one-liners also set in `prefs/antumbra.js`:
  - `extensions.pocket.enabled = false` (DisablePocket policy
    is schema-only on ESR 153 and does not take effect).
  - `browser.contentblocking.report.monitor.enabled = false`.
  - `signon.firefoxRelay.feature = "disabled"`.
- SUMO and support URLs rewritten to `https://antumbrabrowser.org/help/*`.
  Receiving pages do not exist yet; recorded as a before-launch content
  item in ROADMAP.md. Rewrites avoid dead links; a `about:blank` target
  would be worse user experience than a 404 on the eventual help site.

Reasoning. Shipping Milestone 1 with live mozilla.com account entry
points would make MONETIZATION.md's Antumbra Sync plan read as
aspirational while the browser's first click leads the user to a
Mozilla account. Option A is cheap and reversible once Antumbra Sync
exists. The toolbar-button chrome patch is small, isolated to a
single CSS file, and uses an attribute upstream already defines; its
rebase cost is near zero.

Consequence. No cross-device bookmark/password/history sync in
Milestone 1. No "send tab to device" context menu entries. The
feature returns when Antumbra Sync ships, per MONETIZATION.md.

**Q6. Add-on source: keep AMO.**

Running a self-hosted mirror or allowlist is real infrastructure work
and buys no privacy improvement for user-initiated installs. The
Recommended cards and the Discovery pane in about:addons are the real
problem, and D17 already hid those via
`extensions.getAddons.showPane = false` and
`extensions.htmlaboutaddons.recommendations.enabled = false`. Keeping
AMO is consistent with D3 (signing enforcement stays on).

Consequence. Antumbra uses AMO for extension discovery and signed
distribution. Does not revisit until there is a specific reason.

**Q7. Multi-Account Containers: confirm Milestone 4 as planned.**

Ship MAC unmodified for Milestone 1, with the release-notes line
noting the "Firefox Multi-Account Containers" branding. Milestone 4
replaces MAC with the native minimum-viable container UI described
in D17 (toolbar button + picker panel + context menu + tab coloring,
roughly 2 to 3 weeks of chrome-patch work).

**Q3. Default DNS resolver: Quad9 pre-selected.**

`branding/antumbra/content/antumbra-content/dns-resolvers.json`
already has Quad9 marked `"default": true`. Reasoning published here:

- Swiss non-profit.
- Documented no-log policy for source IPs.
- Blocks known malware domains at the resolver level, which aligns
  with D5 (keep local Safe Browsing lists on for the audience most
  likely to get phished).
- No commercial advertising or data-brokerage relationships.

The first-run picker still shows Mullvad, AdGuard, Cloudflare, the
system resolver, and a custom URL field. Quad9 is a default, not a
lock. The reasoning is recorded here so changing the pre-selected
default requires a new DECISIONS.md entry.

**Q4. Funding items: user-owned, remain in before-launch table.**

Maintainer handles the `antumbrabrowser.org` domain purchase and
starts the SignPath application directly. These stay on the
Milestone 1 before-launch blocker list in ROADMAP.md.

**Affects:** `prefs/antumbra.js`, `prefs/policies.json`,
`patches/0400-fxa-ui-removal/0400-01-hide-toolbar-button.patch` (new),
`ROADMAP.md` Milestone 1 before-launch and still-open list.

---

## Still open

Carried forward from ARCHITECTURE.md section 13 and D17.

| # | Question | Needed by |
|---|---|---|
| 1 | **Split view.** Highest permanent maintenance cost in the spec. Confirm it is worth an annual re-patch against actively refactored front end code. | Milestone 4 |
| 4 | **Funding.** Maintainer handles domain purchase and SignPath application directly. Remains an item in the Milestone 1 before-launch table but is not a code decision. | Milestone 0 (in flight with maintainer) |
