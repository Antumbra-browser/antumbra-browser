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

**These steps must run in a Claude Code session on the build machine itself.**
A cloud session has neither the disk nor the job time limit for a Firefox build,
which is what D7 means by cloud sessions handling documentation and planning
only. Run `scripts/setup-windows.ps1 -DryRun` first; it validates the drive and
prints everything it would change before touching anything.

#### The build machine

| | |
|---|---|
| CPU | Intel i7-11700, 8 physical cores, 16 threads |
| RAM | 64 GB |
| GPU | NVIDIA RTX 3080 (irrelevant to build speed; see below) |
| OS | Windows 11 Home 25H2 |
| Build drive | `D:`, an SSD shared with games |

**64 GB removes the memory constraint entirely.** The warning elsewhere in this
document about reducing the job count when a build dies while linking does not
apply to this machine. Run `mach` at its default, which will use all 16 threads.
Core count, not memory, is the limit here.

**The drive is shared with games, so Defender exclusions are scoped to three
specific paths and never to `D:` as a whole.** See step 5.

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
work: **16 GB minimum, 32 GB recommended.** Parallelism is what eats memory and
the link step is the peak, so on a constrained machine, reduce the job count
before assuming a build that died while linking is broken.

**This machine has 64 GB, so none of that applies to it.** Run at the default job
count. Memory guidance is kept here for anyone reproducing the build elsewhere.

**Disk.** At least 40 GB free, and that is tight once you have an object
directory, a toolchain cache, and `sccache`. Budget 150 to 200 GB. On a drive
shared with games this is the constraint most likely to bite, so check it first:
`scripts/setup-windows.ps1 -DryRun` reports free space and warns below 150 GB.

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

The layout, all on the build drive:

```
D:\dev\antumbra\                    build root
D:\dev\antumbra\antumbra-browser\   this git repository
D:\dev\antumbra\firefox\            Firefox ESR source and object directories
D:\dev\antumbra\.mozbuild\          MOZBUILD_STATE_PATH, toolchain cache
C:\mozilla-build\                   MozillaBuild itself (keep the default)
```

`D:\dev\antumbra` has no spaces and is not inside OneDrive.
`scripts/setup-windows.ps1` verifies both, plus free space, before it changes
anything.

**The repository and the source tree are siblings, not nested.** That is
deliberate: it makes committing the Firefox tree or an object directory
structurally impossible rather than merely forbidden. The repository's
`.gitignore` also covers `firefox/`, `.mozbuild/`, and `obj-*/` as a second
layer, in case a checkout ever ends up nested.

**MozillaBuild stays at `C:\mozilla-build`.** Mozilla's docs say to accept the
default, it is small, and it is a toolchain rather than source or build output.
Only the things that grow to tens of gigabytes need to be on `D:`.

**`MOZBUILD_STATE_PATH` is the one that is easy to miss.** Mozilla's toolchain
cache defaults to `%USERPROFILE%\.mozbuild` on `C:` and reaches several
gigabytes. Point it at the build drive:

```powershell
[Environment]::SetEnvironmentVariable(
  'MOZBUILD_STATE_PATH', 'D:\dev\antumbra\.mozbuild', 'User')
```

Set this **before** running bootstrap, or the toolchains land on `C:` and have to
be re-fetched. `scripts/setup-windows.ps1` sets it for you. Open a new shell
afterwards so the variable is picked up.

**Windows 11 Dev Drive:** if you have the spare capacity, create one and put
`D:\dev\antumbra` on it. Mozilla measures 5 to 10 percent faster builds. It is
free performance on a drive that already has the space.

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

First confirm `MOZBUILD_STATE_PATH` is set from step 1, or the toolchains land on
`C:`. In the MozillaBuild shell:

```bash
echo $MOZBUILD_STATE_PATH      # expect D:\dev\antumbra\.mozbuild

cd /d/dev/antumbra
wget https://raw.githubusercontent.com/mozilla-firefox/firefox/refs/heads/main/python/mozboot/bin/bootstrap.py
python3 bootstrap.py
```

MozillaBuild is an MSYS2 environment, so `D:\dev\antumbra` is `/d/dev/antumbra`
inside that shell. The `scripts\mach.cmd` wrapper handles this translation for
you afterwards.

Bootstrap clones the tree and fetches the toolchains (clang, Rust, cbindgen,
nasm, Node). It will raise a **UAC prompt for PowerShell: answer Yes.** That step
adds the Microsoft Defender exclusions described below automatically, and
skipping it costs a large amount of build time for no benefit.

**Real-hardware note (2026-09-22).** Running `bootstrap.py` directly as written
above crashed after a successful clone on this machine. Two issues were found:

1. **MOZBUILD_STATE_PATH not visible in the MozillaBuild shell.** Even though the
   variable was set as a user environment variable by `setup-windows.ps1`, the
   MozillaBuild shell did not inherit it. Bootstrap fell back to
   `C:\Users\Travis\.mozbuild`. Fix: `export MOZBUILD_STATE_PATH=/d/dev/antumbra/.mozbuild`
   at the top of every MozillaBuild session, or add it to
   `C:\mozilla-build\start-shell.bat`. The `scripts\mach.cmd` wrapper already
   sets it as a fallback.

2. **git safe.directory ownership error.** After the clone, subsequent `git`
   operations fail with `detected dubious ownership` because the clone ran in an
   elevated context (bootstrap raised a UAC prompt) which caused the repository
   directory to be owned by `BUILTIN/Administrators` rather than the current user.
   Fix (run once in the MozillaBuild shell):
   ```bash
   git config --global --add safe.directory D:/dev/antumbra/firefox
   ```

**Revised procedure.** If `bootstrap.py` fails after cloning, do not re-run it.
Instead, fix the ownership issue above, then install toolchains directly:

```bash
export MOZBUILD_STATE_PATH=/d/dev/antumbra/.mozbuild
cd /d/dev/antumbra/firefox
git config --global --add safe.directory D:/dev/antumbra/firefox
git checkout main
./mach bootstrap --application-choice browser
```

`mach bootstrap` skips the clone and goes straight to toolchain installation,
which is all that remains after the clone succeeds.

Then pin to ESR per D6, rather than tracking `main`:

```bash
cd firefox
git fetch --tags
git checkout <FIREFOX_ESR_TAG>     # recorded in upstream.conf
```

**Real-hardware note (2026-09-23).** Two additional issues hit when re-running
`./mach bootstrap --application-choice browser` from the pinned ESR tree after
checking it out:

3. **`check_agentic_tools()` fails in MozillaBuild.** The bootstrap tries to
   install `cargo-binstall` via system cargo, which fails because the Windows SDK
   `LIB` path is not set in the MozillaBuild shell environment (LNK1181:
   cannot open `kernel32.lib`). This step only installs AI developer tooling and
   is not needed for building. Fix: comment out the call at line 461 of
   `python/mozboot/mozboot/bootstrap.py`:
   ```python
   # self.check_agentic_tools()
   ```
   This is a one-time patch to the ESR 153 source tree.

4. **VS toolchain version mismatch after re-bootstrap.** If bootstrap is run more
   than once (e.g., once from `main` to clone, then again from the ESR tree), the
   bundled VS toolchain in `.mozbuild/vs` may be replaced with a different MSVC
   version. The `config.status` file in the build object directory then references
   the old version, causing `INCLUDE` to point to a non-existent path. Cargo
   builds of C++ crates (notably `swgl`, which compiles `gl.cc`) fail with
   `fatal error: 'stdlib.h' file not found`. Fix: re-run configure after any
   bootstrap that changes the VS toolchain version:
   ```bash
   ./mach configure
   ```
   Then resume `./mach build` as normal. The configure step detects the installed
   VS version and regenerates `config.status` with the correct paths.

**The toolchain used is clang 21.1.8**, not clang 22 as originally assumed. Both
the main-branch and ESR 153 bootstrap resolve to the same cached clang artifact
(`lib/clang/21/`). The `-Wno-error=incompatible-pointer-types` flag in `mozconfig`
is required because clang 21.1.8 treats the pointer type mismatches in ESR 153's
bundled NSPR as hard errors in C mode.

#### Step 5: Windows Defender exclusions

The single highest-leverage speed change on Windows. Real-time scanning inspects
every one of the hundreds of thousands of files a build touches, and the cost is
large.

**Scope the exclusions to these three paths. Never exclude a whole drive.** `D:`
also holds games and general files; excluding all of it would turn a build
optimization into a standing security hole on the largest volume in the machine.

```
D:\dev\antumbra\firefox       source tree and object directories
D:\dev\antumbra\.mozbuild     toolchain cache
C:\mozilla-build              MozillaBuild
```

`scripts/setup-windows.ps1` adds exactly these and nothing else. To do it by
hand, in an **Administrator** PowerShell:

```powershell
Add-MpPreference -ExclusionPath "D:\dev\antumbra\firefox"
Add-MpPreference -ExclusionPath "D:\dev\antumbra\.mozbuild"
Add-MpPreference -ExclusionPath "C:\mozilla-build"
```

Verify what is actually excluded, which is worth doing since a typo silently
buys nothing:

```powershell
(Get-MpPreference).ExclusionPath
```

Bootstrap offers to add exclusions itself via a UAC prompt. Accepting that is
fine, but check afterwards that it did not add anything broader than the three
paths above, and that it did not exclude a `C:` source location you are not
using.

If third-party antivirus is installed, exclude the same three paths there too.
It is usually the larger offender.

**If `Add-MpPreference` fails with error 0x800106ba**, a third-party antivirus
product is the active provider and has taken over the Windows Security service.
`Add-MpPreference` is not available in that state. Add the three paths as
exclusions in the third-party product's own settings instead. On this machine the
active provider is Surfshark Antivirus. Exclusions are a build-speed optimization,
not a build requirement, and this error does not block the build.

#### Step 6: first build

```bash
cd /d/dev/antumbra/firefox
./mach build
./mach run
```

**Until `./mach run` launches a working browser, nothing else in this roadmap
matters.** Budget a day or two for this the first time, most of it spent on
toolchain problems rather than on the build itself.

Capture the numbers while you have them, because they set every estimate that
follows. `mach` prints its own elapsed time and the job count it chose:

```bash
./mach build 2>&1 | tee /d/dev/antumbra/build-log-first.txt
grep -iE "real|elapsed|jobs|Your build was successful" /d/dev/antumbra/build-log-first.txt
```

Record the result in the build times table below, replacing the expected values.

#### Build times

| Build type | Expected | Measured | Job count | When you use it |
|---|---|---|---|---|
| **Clean full build** | 60 to 90 min | 46m54s (2026-09-23) | 16 (default) | First build, after a rebase, after a mozconfig change |
| **Incremental**, C++ change | 2 to 15 min | _not yet measured_ | 16 | Editing Gecko. A widely included header touches everything and approaches a full rebuild. |
| **`./mach build faster`** | Seconds to ~2 min | 8s (2026-09-23) | n/a | **Frontend only**: JS, CSS, XHTML, prefs, branding assets. Most of Antumbra's milestone 1 work. |
| **Artifact build** | 1 to 5 min | _not yet measured_ | n/a | Frontend iteration only. See the warning below. |

**Note on the full build measurement.** The 46m54s figure was taken with partial
sccache cache from prior failed build attempts. A true cold build from a clean
object directory is expected to run 60 to 90 minutes. The number serves as a
confirmed upper bound, not a cold-build baseline.

Eight physical cores puts this machine at the slower end of the earlier 8-core
estimate of 60 to 120 minutes, but NVMe and 64 GB of RAM pull it back toward the
optimistic end, since neither IO nor memory will be the bottleneck. Treat 60 to
90 minutes as the working assumption until measured.

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

Run Claude Code from `D:\dev\antumbra\antumbra-browser`, the repository, not
from the Firefox source tree.

**The one integration detail that matters:** `mach` must run inside the
MozillaBuild shell, not in PowerShell. `scripts\mach.cmd` in this repository
handles that, so a single command works from any terminal:

```
scripts\mach.cmd build
scripts\mach.cmd build faster
scripts\mach.cmd run
```

It defaults to `C:\mozilla-build` and `D:\dev\antumbra`, sets
`MOZBUILD_STATE_PATH` if it is not already set, translates the Windows path to
the MSYS2 form the shell needs, and fails with a clear message if either the
MozillaBuild install or the source tree is missing. Override with the
`MOZILLABUILD` and `ANTUMBRA_ROOT` environment variables if the layout differs.

### Milestone 0 checklist

**Status: not started on hardware.** The preparation below was done in a cloud
session; everything requiring the build machine is untouched. Nothing here is
complete until `./mach run` launches a browser.

Prepared, not yet verified on hardware:

- [x] `scripts/setup-windows.ps1`: validates the drive, creates the layout, sets
      `MOZBUILD_STATE_PATH`, adds the three scoped Defender exclusions. Supports
      `-DryRun`. Executed and verified 2026-09-22.
- [x] `scripts/mach.cmd`: MozillaBuild wrapper. Written; not yet exercised for a build.
- [x] `.gitignore` covering `firefox/`, `.mozbuild/`, `obj-*/`.
- [x] Build machine specifications and drive layout recorded above.

Requires the build machine, in order:

- [x] Run `scripts\setup-windows.ps1 -DryRun` and **report D: free space.**
      506.9 GB free of 931.5 GB. Confirmed well above the 150 GB recommendation.
- [x] Run `scripts\setup-windows.ps1` from an Administrator PowerShell.
      Directories and `MOZBUILD_STATE_PATH` set. Defender exclusions skipped
      (Surfshark is the active AV provider; see step 5 note).
- [x] Install Visual Studio Build Tools 2022 (step 2). **Not required as a
      separate install.** `mach bootstrap` downloaded `DIA SDK`, `VC`, and
      `Windows Kits` (the full Windows SDK) into `.mozbuild\vs`. The build
      system uses these directly. No GUI installer or reboot needed.
- [x] Install MozillaBuild to `C:\mozilla-build` (step 3). Version 4.2.1 installed.
- [x] Bootstrap and check out the pinned ESR tag (step 4). See real-hardware notes
      above. Tree cloned, toolchains installed, sccache enabled.
      Checked out `FIREFOX_153_3_0esr_RELEASE`. Applied one-time patch to
      `python/mozboot/mozboot/bootstrap.py` to skip `check_agentic_tools()`.
      Ran `./mach configure` after second bootstrap to fix VS 14.51/14.50 mismatch.
- [x] Verify Defender exclusions are exactly the three scoped paths (step 5).
      Windows Defender not applicable (Surfshark is active AV). Three paths added
      manually in Surfshark settings.
- [x] First full build, `./mach run` confirmed working, **time and job count
      recorded** in the table above (step 6). Full build: 46m54s at j16.
      `./mach run` launched browser confirmed 2026-09-23.
- [x] `./mach build faster` timed and recorded. 8s (2026-09-23).
- [ ] Install Claude Code on the machine; confirm `scripts\mach.cmd` drives a
      build from an ordinary terminal (step 7).
- [x] Configure `sccache`. Enabled during bootstrap. Keep the artifact-build
      mozconfig separate from the release mozconfig (not yet created).
- [x] Pin `upstream.conf` to a specific Firefox ESR tag. Pinned to
      `FIREFOX_153_3_0esr_RELEASE` (ESR 153, latest as of 2026-09-22). See D8.
- [ ] Create the rest of the repository skeleton from ARCHITECTURE.md section 9.2.
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
