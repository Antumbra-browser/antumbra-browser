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

## Still open

Carried forward from ARCHITECTURE.md section 13. Not yet decided.

| # | Question | Needed by |
|---|---|---|
| 1 | **Split view.** Highest permanent maintenance cost in the spec. Confirm it is worth an annual re-patch against actively refactored front end code. | Milestone 4 |
| 3 | **Default DNS resolver.** An editorial choice with real privacy consequences. The reasoning must be published, not made quietly. | Milestone 1 |
| 4 | **Funding.** Signing, a domain, and a trademark clearance opinion are real year-one costs before anyone is paid for their time. | Milestone 0 |
