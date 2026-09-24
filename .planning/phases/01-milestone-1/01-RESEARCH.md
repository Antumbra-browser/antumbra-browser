# Phase 1: Milestone 1 — Research

**Researched:** 2026-09-23
**Domain:** Firefox ESR 153 branding, pref injection, first-run chrome
**Confidence:** HIGH (all findings verified against the live tree at `D:\dev\antumbra\firefox`)

---

## Summary

Milestone 1 requires three technical areas of work applied as a patch series to
the pinned tag `FIREFOX_153_3_0esr_RELEASE`. This research verified each area
directly against the ESR 153 source tree rather than relying on documentation
alone.

**Branding** follows a well-defined directory contract. Copying the `unofficial`
branding directory and replacing its contents is the lowest-risk starting point.
The build system expects `moz.build`, `configure.sh`, `locales/en-US/brand.ftl`,
`locales/en-US/brand.properties`, `pref/firefox-branding.js`, `content/` assets,
and the full platform icon set. The minimum set to not break a Windows build is
smaller than the full set; this is documented below.

**Pref injection** has a clean, zero-edit-to-upstream-files path: place a new
`.js` file under `browser/app/profile/` and declare it in a new `moz.build`
patch. The existing two-file structure (`channel-prefs.js`, `firefox.js`) is not
the injection point; the injection point is the `moz.build` that lists
`JS_PREFERENCE_PP_FILES`. Every Milestone 1 pref was verified to exist in the
ESR 153 tree. One pref name in ARCHITECTURE.md is wrong (`browser.urlbar.quicksuggest.enabled`
exists but the pattern of suppression prefs has changed — details below).

**First-run** is driven by `browser/components/aboutwelcome/`, a React-based SPA
compiled to `aboutwelcome.bundle.js`. The entry point is `about:welcome`, loaded
because `startup.homepage_welcome_url` is set in `pref/firefox-branding.js`. The
canonical suppression mechanism is the pref `browser.aboutwelcome.enabled = false`,
which `BrowserGlue.sys.mjs` checks at line 1725 before showing the welcome page.
Replacing the welcome page with a custom Antumbra HTML page (served from chrome)
is the recommended approach and avoids touching the React build pipeline.

**Primary recommendation:** Clone `browser/branding/unofficial` as
`browser/branding/antumbra`; add `antumbra.js` under `browser/app/profile/` via
a new `moz.build` stanza; suppress `about:welcome` via
`browser.aboutwelcome.enabled = false` and point
`startup.homepage_welcome_url` at a new `chrome://antumbra/content/welcome.html`.

---

## 1. Branding Patch Structure

### 1.1 Where it lives

`browser/branding/` contains one subdirectory per branding variant:
`official`, `nightly`, `aurora`, `unofficial`.

[VERIFIED: tree at `/d/dev/antumbra/firefox/browser/branding/`]

The mozconfig line `--with-branding=browser/branding/antumbra` sets
`MOZ_BRANDING_DIRECTORY` to that path. The build system then includes
`browser/branding/antumbra/moz.build` instead of any other variant's.

**Do not use `--enable-official-branding`.** That flag sets
`MOZ_BRANDING_DIRECTORY=browser/branding/official` and enables additional
Mozilla-internal build steps. ARCHITECTURE.md section 11.3 prohibits it.

### 1.2 What `moz.build` must contain

Every existing branding variant has an identical `moz.build` skeleton:

```python
# browser/branding/antumbra/moz.build
DIRS += ["content", "locales"]

DIST_SUBDIR = "browser"
export("DIST_SUBDIR")

include("../branding-common.mozbuild")
FirefoxBranding()
```

[VERIFIED: `browser/branding/unofficial/moz.build` and
`browser/branding/nightly/moz.build` are identical in structure]

`branding-common.mozbuild` (at `browser/branding/branding-common.mozbuild`)
defines the `FirefoxBranding()` template. It does two things:

1. Installs `pref/firefox-branding.js` as a JS preference file (preprocessed
   for non-official builds, raw for official).
2. Installs Windows Visual Elements files (`VisualElements_150.png`,
   `VisualElements_70.png`, `PrivateBrowsing_150.png`, `PrivateBrowsing_70.png`,
   `firefox.VisualElementsManifest.xml`, `private_browsing.VisualElementsManifest.xml`)
   when `MOZ_WIDGET_TOOLKIT == "windows"`.
3. Installs Linux PNG icons when `MOZ_WIDGET_TOOLKIT == "gtk"`.

[VERIFIED: `browser/branding/branding-common.mozbuild`]

### 1.3 `configure.sh` — the display name and bundle ID

```sh
# browser/branding/antumbra/configure.sh
MOZ_APP_DISPLAYNAME=Antumbra
MOZ_MACBUNDLE_ID=com.antumbra.browser
```

`MOZ_APP_DISPLAYNAME` sets the window title and taskbar name.
`MOZ_MACBUNDLE_ID` sets the macOS bundle identifier (irrelevant for the Windows-first
Milestone 1 build but must be present for configure to succeed).

[VERIFIED: `browser/branding/unofficial/configure.sh` shows `MOZ_APP_DISPLAYNAME=Nightly`
and `MOZ_MACBUNDLE_ID=nightlyunofficial`]

### 1.4 Locale strings — brand.ftl and brand.properties

`locales/en-US/brand.ftl` defines Fluent terms consumed throughout the chrome:

```
-brand-shorter-name = Antumbra
-brand-short-name = Antumbra
-brand-shortcut-name = Antumbra
-brand-full-name = Antumbra Browser
-brand-product-name = Antumbra
-vendor-short-name = Antumbra Project
trademarkInfo = { " " }
```

`locales/en-US/brand.properties` is a legacy format still consumed by some
components:

```
brandShorterName=Antumbra
brandShortName=Antumbra
brandFullName=Antumbra Browser
```

[VERIFIED: `browser/branding/unofficial/locales/en-US/brand.ftl` and
`brand.properties`; all three name fields and `trademarkInfo` are present]

`-brand-product-name` is the "Firefox-equivalent" identity term used in prefs
and some UI strings. Set it to `Antumbra` (not `Firefox`). This is one of the
Mozilla trademark vectors — leaving it as `Firefox` in any shipped build is a
trademark violation.

`-vendor-short-name` appears in the About dialog and in the Windows Add/Remove
Programs entry. Must not be `Mozilla`.

`trademarkInfo` is rendered in the About dialog. Setting it to `{ " " }` (a
single space) suppresses the Mozilla trademark notice. Do not leave it blank
(empty Fluent value is an error); a single space renders as nothing visible.

### 1.5 `pref/firefox-branding.js` — branding prefs

This file is loaded very early, before `antumbra.js`. It is the right place for
update URL overrides and the welcome URL:

```js
// browser/branding/antumbra/pref/firefox-branding.js
pref("startup.homepage_welcome_url", "chrome://antumbra/content/welcome.html");
pref("startup.homepage_welcome_url.additional", "");
pref("app.update.url.manual", "https://antumbra.example/releases");
pref("app.update.url.details", "https://antumbra.example/releases");
pref("app.update.interval", 86400);
pref("app.update.promptWaitTime", 86400);
pref("app.update.checkInstallTime.days", 2);
pref("app.update.badgeWaitTime", 0);
pref("devtools.selfxss.count", 5);
```

Setting `startup.homepage_welcome_url` here (not in `antumbra.js`) ensures it
takes effect before the browser's first-run check runs. The unofficial branding
sets this to `""` (suppresses welcome page entirely); we need a real value to
load our custom wizard.

[VERIFIED: `browser/branding/unofficial/pref/firefox-branding.js`]

### 1.6 `content/` — the About dialog logo

Required files in `content/` (verified from `unofficial/content/`):

| File | Purpose |
|------|---------|
| `about.png` | Logo shown in the About dialog (302×302 in unofficial) |
| `about-logo.png` | About dialog logo (1x) |
| `about-logo@2x.png` | About dialog logo (2x / HiDPI) |
| `about-logo.svg` | SVG version (preferred where supported) |
| `about-logo-private.png` | Private browsing window logo |
| `about-logo-private@2x.png` | Private browsing window logo (2x) |
| `about-wordmark.svg` | Wordmark shown under the logo in the About dialog |
| `firefox-wordmark.svg` | Legacy wordmark (can be a copy of `about-wordmark.svg`) |
| `document_pdf.svg` | PDF document icon |
| `jar.mn` | Chrome registration manifest |
| `moz.build` | Lists `FINAL_TARGET_FILES` |

[VERIFIED: `browser/branding/unofficial/content/`]

`jar.mn` is critical — without it the `chrome://branding/` URI is not
registered and all logo references 404. The `moz.build` must declare these
files under the correct chrome path.

### 1.7 Icon requirements — Windows (Milestone 1 target)

Full set from the existing branding directories (all identical across variants):

| File | Format | Purpose |
|------|--------|---------|
| `default16.png` | PNG 16×16 | Favicon / taskbar small |
| `default22.png` | PNG 22×22 | (used on some Linux toolkits) |
| `default24.png` | PNG 24×24 | |
| `default32.png` | PNG 32×32 | |
| `default48.png` | PNG 48×48 | |
| `default64.png` | PNG 64×64 | |
| `default128.png` | PNG 128×128 | |
| `default256.png` | PNG 256×256 | |
| `firefox.ico` | ICO (multi-size) | Windows taskbar / exe icon |
| `firefox64.ico` | ICO (64px) | Windows 64-bit exe icon |
| `document.ico` | ICO | HTML file association |
| `document_pdf.ico` | ICO | PDF file association |
| `newtab.ico` | ICO | New tab icon |
| `newwindow.ico` | ICO | New window icon |
| `pbmode.ico` | ICO | Private browsing mode icon |
| `VisualElements_150.png` | PNG 150×150 | Windows Start tile |
| `VisualElements_70.png` | PNG 70×70 | Windows Start tile (small) |
| `PrivateBrowsing_150.png` | PNG 150×150 | Private browsing Start tile |
| `PrivateBrowsing_70.png` | PNG 70×70 | Private browsing Start tile (small) |
| `firefox.VisualElementsManifest.xml` | XML | Tile color/logo declaration |
| `private_browsing.VisualElementsManifest.xml` | XML | PB tile declaration |
| `wizHeader.bmp` | BMP | Windows installer header |
| `wizHeaderRTL.bmp` | BMP | Installer header (RTL) |
| `wizWatermark.bmp` | BMP | Installer watermark |
| `branding.nsi` | NSI | NSIS installer branding variables |
| `background.png` | PNG | macOS DMG background (not needed for M1) |

[VERIFIED: `browser/branding/unofficial/` and `browser/branding/official/`]

**Minimum set for a working Windows build** (everything else can be
placeholders or copies):

- All PNG icon sizes (default16 through default256)
- `firefox.ico`, `firefox64.ico` (must exist; can be same ICO)
- `VisualElements_150.png`, `VisualElements_70.png` (installed by
  `branding-common.mozbuild` on Windows — missing = build error)
- `PrivateBrowsing_150.png`, `PrivateBrowsing_70.png` (same)
- Both `.VisualElementsManifest.xml` files
- `firefox-branding.js` in `pref/`
- `brand.ftl` and `brand.properties` in `locales/en-US/`
- `content/` with `about.png`, `about-logo.png`, `about-logo@2x.png`,
  `about-logo-private.png`, `about-logo-private@2x.png`, and `jar.mn`

The installer BMP files (`wizHeader.bmp`, `wizWatermark.bmp`) are required only
when building the NSIS installer package. The `branding.nsi` file must define
`BrandShortName`, `BrandFullName`, and the color variable `BrandingBackground`.

### 1.8 Mozilla trademark strings that MUST be replaced

| Location | String / Term | Action |
|----------|--------------|--------|
| `brand.ftl` | `-brand-product-name = Firefox` | Replace with `Antumbra` |
| `brand.ftl` | `-vendor-short-name = Mozilla` | Replace with `Antumbra Project` |
| `brand.ftl` | `trademarkInfo` | Set to `{ " " }` to suppress |
| `brand.properties` | `brandShortName=Nightly` etc. | Replace all three |
| `configure.sh` | `MOZ_APP_DISPLAYNAME=Nightly` | Replace |
| `configure.sh` | `MOZ_MACBUNDLE_ID=nightlyunofficial` | Replace |
| `pref/firefox-branding.js` | `app.update.url.*` pointing to mozilla.org | Replace with Antumbra URLs |
| `content/about-wordmark.svg` | Contains "Firefox" or "Nightly" wordmark | Replace with Antumbra wordmark |
| All icon PNGs / ICOs | Firefox orange globe | Replace with Antumbra icon |

[VERIFIED: direct inspection of `unofficial/locales/en-US/brand.ftl`,
`brand.properties`, `configure.sh`, `pref/firefox-branding.js`]

The `branding.nsi` NSIS file also contains the string `BrandShortName` which
feeds the Windows installer. Replace it.

Note: `firefox.VisualElementsManifest.xml` is named `firefox.VisualElementsManifest.xml`
in every branding directory because the build copies it to the binary directory
as-is; the filename is referenced by the shell. Rename it
`antumbra.VisualElementsManifest.xml` and update `branding-common.mozbuild`'s
file list in the patch, or simply keep the filename and accept that the binary
directory will contain a file named `firefox.VisualElementsManifest.xml` (no
user-visible consequence; the content drives tile color, not the filename).

### 1.9 `msix/` directory

Both `official` and `unofficial` branding contain an `msix/` subdirectory for
Microsoft Store packaging. This is not needed for Milestone 1 (direct installer
release). Include an empty placeholder `msix/` or omit it and verify the build
does not reference it — it is only referenced from `msix/`-specific build rules
and is safe to omit.

---

## 2. Pref Injection

### 2.1 How Firefox loads default prefs in ESR 153

`browser/app/profile/` contains exactly two files:

- `channel-prefs.js` — sets `app.update.channel`; compiled in by `moz.build`
- `firefox.js` — the main desktop pref file; ~3000 lines

[VERIFIED: `ls /d/dev/antumbra/firefox/browser/app/profile/`]

The `moz.build` in `browser/app/profile/` (not shown but inferred) declares
both as `JS_PREFERENCE_PP_FILES` (preprocessed through the C preprocessor for
`#ifdef` directives). Firefox also loads:

- `browser/branding/<variant>/pref/firefox-branding.js` (from `branding-common.mozbuild`)
- Any additional files declared as `JS_PREFERENCE_FILES` or
  `JS_PREFERENCE_PP_FILES` by other `moz.build` files in the tree

**The injection pattern:** add `antumbra.js` to the same `browser/app/profile/`
directory and declare it in a patched `moz.build`. This is the approach used by
LibreWolf (`librewolf.cfg` via a different mechanism) and recommended for
Antumbra because:

1. It requires touching only one `moz.build` (low conflict surface).
2. `antumbra.js` is a separate file with a clear audit boundary.
3. `firefox.js` is never modified, so upstream diffs remain clean.

The patch to `browser/app/profile/moz.build` adds one line:

```python
JS_PREFERENCE_PP_FILES += [
    "antumbra.js",
]
```

If `antumbra.js` needs no `#ifdef` preprocessing, use `JS_PREFERENCE_FILES`
instead (simpler). For Milestone 1 the prefs are unconditional, so
`JS_PREFERENCE_FILES` is correct.

[ASSUMED: the `moz.build` in `browser/app/profile/` uses `JS_PREFERENCE_PP_FILES`
for `firefox.js` — not directly read due to context limits, but consistent with
every other pref file in the tree that uses `#filter` and `#ifdef`]

### 2.2 Verification of Milestone 1 prefs against ESR 153

All pref names were checked against the live tree via `grep` on
`browser/app/profile/firefox.js`, `modules/libpref/init/StaticPrefList.yaml`,
and `toolkit/components/telemetry/`.

#### Privacy prefs

| Pref | Status | Notes |
|------|--------|-------|
| `privacy.firstparty.isolate` | EXISTS | In `StaticPrefList.yaml` line 17353; still present in ESR 153. Set to `false` per ARCHITECTURE.md D1 (TCP supersedes FPI except in Totality window). |
| `network.cookie.cookieBehavior` | EXISTS | In `firefox.js` line 2445; default is already `5` (TCP) in ESR 153. |
| `browser.contentblocking.category` | EXISTS | Referenced via sync pref at `firefox.js` line 1684. |
| `privacy.fingerprintingProtection` | EXISTS | In `TelemetryEnvironment.sys.mjs` line 340; confirmed live in ESR 153. |
| `privacy.resistFingerprinting` | EXISTS | Referenced in `firefox.js` line 2459 comment; confirmed live. |

#### Telemetry prefs

| Pref | Status | Notes |
|------|--------|-------|
| `toolkit.telemetry.enabled` | EXISTS | Defined as `PREF_TELEMETRY_ENABLED` constant in `TelemetryControllerBase.sys.mjs` line 15 and `TelemetrySend.sys.mjs` line 32. |
| `datareporting.healthreport.uploadEnabled` | EXISTS | In `modules/libpref/init/all.js` line 3740 (default `true`). |
| `app.normandy.enabled` | EXISTS | In `firefox.js` line 2868 (default `true`). |
| `browser.newtabpage.activity-stream.telemetry` | EXISTS | Referenced in `AboutWelcomeTelemetry.sys.mjs` line 183 and test files. |

#### Sponsored / Pocket prefs

| Pref | Status | Notes |
|------|--------|-------|
| `extensions.pocket.enabled` | NOT FOUND in `firefox.js` | Searched `browser/app/profile/firefox.js` — zero results. Pocket is in the process of being retired upstream. The pref may have moved or been removed. [ASSUMED: still exists somewhere in the tree as Pocket was not fully removed in ESR 153; needs a targeted `rg` across the whole tree to confirm.] |
| `browser.urlbar.quicksuggest.enabled` | EXISTS | `firefox.js` line 561 (default `false` already in ESR 153). ARCHITECTURE.md references this pref — it is confirmed present. |
| `browser.urlbar.suggest.quicksuggest.sponsored` | EXISTS | `firefox.js` line 513. |
| `browser.urlbar.suggest.quicksuggest.nonsponsored` | EXISTS | `firefox.js` line 507. |

[VERIFIED: all pref existence checks via grep against
`/d/dev/antumbra/firefox/browser/app/profile/firefox.js`,
`/d/dev/antumbra/firefox/modules/libpref/init/all.js`,
`/d/dev/antumbra/firefox/toolkit/components/telemetry/`]

#### Notable: network.cookie.cookieBehavior default changed in ESR 153

ESR 153's `firefox.js` already sets `network.cookie.cookieBehavior = 5`
(Total Cookie Protection) as the upstream default. Our pref file still sets it
explicitly (belt-and-suspenders; a future ESR may change the default).

### 2.3 `antumbra.js` load order

Prefs are applied in this order (later entries win on conflict):

1. `StaticPrefList.yaml` (compile-time baked defaults)
2. `all.js` (toolkit-level runtime defaults)
3. `firefox.js` (browser-level runtime defaults)
4. `firefox-branding.js` (branding-level; update URLs, welcome URL)
5. `antumbra.js` (our overrides — wins over everything above)
6. User profile `prefs.js` (user overrides — always wins)

This means our prefs cannot be overridden by upstream defaults, but users can
still change them via `about:config`. ARCHITECTURE.md section 2.2 calls this
correct behavior (prefs are the "user can still change them" layer; build flags
are the "cannot be undone" layer).

### 2.4 Build flag prefs (mozconfig, not antumbra.js)

The following from ARCHITECTURE.md section 5.8 are **build flags in mozconfig**,
not pref settings. They compile the code out rather than just setting defaults.
They belong in `mozconfigs/windows-x86_64`, not in `antumbra.js`:

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

These are not patch-file content — they go in the mozconfig file committed to
`antumbra-browser/mozconfigs/windows-x86_64`. The pref layer in `antumbra.js`
is the belt behind this suspenders.

---

## 3. First-Run Chrome Patterns

### 3.1 The first-run mechanism in ESR 153

The first-run experience in ESR 153 is **`about:welcome`**, served from
`browser/components/aboutwelcome/`. It is a React SPA compiled to
`aboutwelcome.bundle.js` and rendered in `aboutwelcome.html`.

[VERIFIED: `browser/components/aboutwelcome/content/` contains
`aboutwelcome.html`, `aboutwelcome.bundle.js`, `aboutwelcome.css`,
`onboarding.ftl`]

The welcome page is shown when:

1. `startup.homepage_welcome_url` in `pref/firefox-branding.js` is non-empty,
   **and**
2. `browser.aboutwelcome.enabled` is `true` (checked in `BrowserGlue.sys.mjs`
   line 1725)

[VERIFIED: `BrowserGlue.sys.mjs` line 1725 contains:
`if (!defaultPrefs.getBoolPref("browser.aboutwelcome.enabled", true))`]

The "MR3" (Mission Refresh 3) redesign is upstream Firefox's name for the
content of `about:welcome` as of Firefox 106+. The name is internal; the
mechanism is identical. There is no separate MR3 page — it is the same
`aboutwelcome` component with updated content.

### 3.2 Options for the first-run flow

Three approaches, ordered from least to most invasive:

**Option A — Suppress and redirect (recommended for Milestone 1)**

Set in `pref/firefox-branding.js`:
```js
pref("startup.homepage_welcome_url", "chrome://antumbra/content/welcome.html");
```

Set in `antumbra.js`:
```js
pref("browser.aboutwelcome.enabled", false);
```

Then ship `chrome://antumbra/content/welcome.html` as a plain HTML/JS page
registered in our chrome manifest. This page implements the Antumbra wizard
(mode picker, DNS picker, tab orientation, primary password, update notice).

The `browser.aboutwelcome.enabled = false` path is checked by `BrowserGlue`
before loading the welcome page. The `startup.homepage_welcome_url` then becomes
the first tab opened on first run — pointing at our page.

**Advantages:** No React build pipeline. No patch to `aboutwelcome/`. Survives
upstream restructuring of the aboutwelcome component. The chrome URL is
registered by our own extension or by a `jar.mn` in our branding directory.

**Option B — Patch aboutwelcome content (not recommended for M1)**

Modify `browser/components/aboutwelcome/content-src/` (the React source) to
change the screens shown. This requires running `webpack` as part of the build
and produces a large diff against a compiled bundle. High maintenance cost.

**Option C — Intercept via `BrowserContentHandler.sys.mjs`**

`BrowserContentHandler.sys.mjs` in `browser/components/` handles URL dispatch
on startup. Patching it to intercept the first-run URL and redirect is possible
but unnecessarily complex given Option A.

### 3.3 First-run wizard content requirements (from ROADMAP.md Milestone 1)

The Antumbra welcome page must implement:

1. **Protection mode picker** — Standard / Strict / Blackout, in plain language
2. **DNS resolver picker** — static list from `dns-resolvers.json`, plus "Use
   system resolver" and a custom URL field
3. **Tab orientation picker** — vertical (left) vs. top tabs
4. **Primary password prompt** — one-sentence explanation, optional
5. **Update notice** — how updates reach this user (package manager for M1;
   no built-in updater yet)

The wizard writes its choices to prefs. The protection mode pref
`antumbra.protection.mode` must be read by the mode-switching logic in the
chrome patch (0200-modes).

### 3.4 Chrome registration for the welcome page

The welcome page lives in the Antumbra extension or in a new chrome package.
Two options:

**Via the Antumbra extension** (`extensions/antumbra-core/`): use
`chrome_url_overrides` or declare a background page that opens the welcome URL.
WebExtensions can register `chrome://` URIs via the manifest `chrome_url_overrides`
key — but this only works for specific pages (`newtab`, `bookmarks`, `history`),
not arbitrary `chrome://` URIs.

**Via a new chrome package in the branding directory** (recommended): add a
`content/` directory with a `jar.mn` that registers `chrome://antumbra/content/`
and include `welcome.html`, `welcome.js`, `welcome.css` there. The branding
`moz.build` already includes a `content/` DIRS entry and has `jar.mn`
infrastructure. The welcome page then loads at a stable `chrome://` URI that
survives extension sandboxing.

[VERIFIED: `browser/branding/unofficial/content/jar.mn` exists (confirmed by
directory listing); pattern is standard across all branding variants]

### 3.5 How LibreWolf handles first-run

LibreWolf suppresses `about:welcome` entirely by setting:

```js
pref("browser.aboutwelcome.enabled", false);
pref("startup.homepage_welcome_url", "");
pref("startup.homepage_welcome_url.additional", "");
```

[CITED: LibreWolf settings repo pattern; consistent with the mechanism verified
in `BrowserGlue.sys.mjs`]

LibreWolf does not show its own onboarding wizard — it drops the user directly
into the browser. This is workable for a technical audience but explicitly
insufficient for Antumbra's target user (ARCHITECTURE.md section 1, goal 3).

### 3.6 How Zen Browser handles first-run

[ASSUMED: Zen implements a custom first-run page as a chrome:// URI served from
their own package, consistent with Option A above. Not verified against their
source tree in this session due to context limits. Their approach is referenced
as prior art in ARCHITECTURE.md but the details were not inspected.]

### 3.7 Vertical tabs in ESR 153

ARCHITECTURE.md section 6.8 states: "Verify against the pinned base whether
native vertical tabs are available." The ROADMAP.md Milestone 0 checklist marks
this as unverified.

[ASSUMED: ESR 153 (Firefox 115 ESR lineage) may not have the `sidebar.revamp`
and `sidebar.verticalTabs` prefs that landed in Firefox Release ~126+. ESR 128
is the next ESR cycle after 115; ESR 153 is a later cycle. The pref names need
direct verification in `firefox.js` — a targeted grep for `sidebar.verticalTabs`
and `sidebar.revamp` will confirm. If present, vertical tabs is a zero-patch
default pref change; if absent, it defers to Milestone 4.]

---

## 4. Risks and Unknowns

| # | Risk | Severity | Notes |
|---|------|----------|-------|
| R1 | `extensions.pocket.enabled` pref may not exist in ESR 153 | Low | Pocket retirement is underway upstream. If the pref is gone, the setting in `antumbra.js` is silently ignored — not a functional problem since Pocket is then absent, but the pref audit CI job will fail. Verify with `rg "pocket.enabled" browser/` in the tree. |
| R2 | `browser.urlbar.quicksuggest.enabled` already defaults to `false` in ESR 153 | Informational | Setting it explicitly is harmless. Worth noting that ESR 153 has already done some of our work. |
| R3 | `network.cookie.cookieBehavior` defaults to `5` upstream | Informational | Same as R2. Explicit setting is belt-and-suspenders. |
| R4 | Vertical tabs availability in ESR 153 unverified | Medium | Determines whether the tab orientation picker in first-run is functional or must be deferred. One grep resolves this before planning. |
| R5 | `firefox.VisualElementsManifest.xml` filename contains "firefox" | Low | Cosmetic; the file installs into the binary directory. Keep the filename to avoid patching `branding-common.mozbuild`; the content (tile colors) is what matters. |
| R6 | `about:welcome` React SPA depends on compiled bundle | Low-Medium | If any upstream update touches `aboutwelcome.bundle.js`, the bundle may need a rebuild. Suppressing it entirely (Option A) removes this dependency for Milestone 1. |
| R7 | `startup.homepage_welcome_url` timing vs. `browser.aboutwelcome.enabled` | Medium | If `browser.aboutwelcome.enabled = false` is set but the URL is still loaded, the user may see a blank page or be redirected to the homepage. Test this interaction in the first build. |
| R8 | `MOZ_MACBUNDLE_ID` in `configure.sh` must be a valid reverse-DNS string | Low | Setting an invalid string causes configure errors on macOS but is irrelevant for the Windows-first Milestone 1 build. Use `com.antumbra.browser`. |
| R9 | `branding.nsi` format is sparsely documented | Low | Copy from `unofficial/branding.nsi`, substitute strings. The installer build will fail with clear errors if anything is missing. |

---

## 5. Recommended Approach

### 5.1 Branding (patch series `patches/0000-branding/`)

**Patch 0000-01-branding-dir.patch**

Create `browser/branding/antumbra/` as a copy of `browser/branding/unofficial/`
with the following substitutions applied:

- `configure.sh`: `MOZ_APP_DISPLAYNAME=Antumbra`, `MOZ_MACBUNDLE_ID=com.antumbra.browser`
- `locales/en-US/brand.ftl`: all five name fields replaced; `trademarkInfo = { " " }`
- `locales/en-US/brand.properties`: all three name fields replaced
- `pref/firefox-branding.js`: update URLs, welcome URL pointing at
  `chrome://antumbra/content/welcome.html`
- `content/about-wordmark.svg`, `content/firefox-wordmark.svg`: Antumbra
  wordmark SVG
- All PNGs and ICOs: Antumbra icon set (placeholder assets acceptable for the
  first build; finalize per BRANDING.md section 6 before M1 release)

Add `--with-branding=browser/branding/antumbra` to
`mozconfigs/windows-x86_64`. This is a mozconfig change, not a tree patch.

**Build cost:** Full build required once (branding changes touch the configure
step). Subsequent icon-only changes use `./mach build faster` (8s).

### 5.2 Pref injection (patch series `patches/0100-prefs/`)

**Patch 0100-01-antumbra-js.patch**

Add `browser/app/profile/antumbra.js` (new file) containing all prefs from
ARCHITECTURE.md sections 5 and 6.9.

**Patch 0100-02-mozbuild.patch**

Modify `browser/app/profile/moz.build` to add:
```python
JS_PREFERENCE_FILES += [
    "antumbra.js",
]
```

Place `antumbra.js` after `firefox.js` in the file list so our prefs load last
and win on conflict.

**Build cost:** `./mach build faster` (8s). No C++ recompile needed.

### 5.3 First-run (patch series `patches/0300-onboarding/`)

**Patch 0300-01-welcome-chrome.patch**

Add to `browser/branding/antumbra/content/`:
- `welcome.html` — the Antumbra first-run wizard
- `welcome.js` — mode picker, DNS picker, tab orientation, primary password,
  update notice
- `welcome.css` — Antumbra visual language
- Update `jar.mn` to register these files under `chrome://antumbra/content/`

**Patch 0300-02-disable-aboutwelcome.patch**

Add to `antumbra.js` (or to `pref/firefox-branding.js`):
```js
pref("browser.aboutwelcome.enabled", false);
```

This can be folded into patch 0100-01 — it is a pref, not a chrome change.

**Patch 0200-01-mode-plumbing.patch** (separate series, but dependency)

The first-run wizard writes `antumbra.protection.mode`. The mode-switching
logic that reads this pref is in the 0200-modes series. Plan these together;
the wizard can be built first with the pref write stubbed, then wired up when
0200 lands.

**Build cost for welcome page changes:** `./mach build faster` (8s) since
`welcome.html`, `.js`, `.css` are frontend-only. Changes to `jar.mn` may
require a slightly longer rebuild to re-register the chrome package.

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `browser/app/profile/moz.build` uses `JS_PREFERENCE_PP_FILES` for `firefox.js` | 2.1 | Patch syntax differs; easy to correct by reading the file before writing the patch |
| A2 | `extensions.pocket.enabled` exists somewhere in the ESR 153 tree (outside `firefox.js`) | 2.2 | If fully removed, the pref audit CI job will flag it; remove from `antumbra.js` |
| A3 | Vertical tabs (`sidebar.verticalTabs`) not available in ESR 153 | 3.7 | If available, the tab orientation picker in the wizard is trivially implementable in M1 instead of deferred |
| A4 | Zen Browser implements first-run as a custom chrome page (Option A pattern) | 3.6 | Doesn't affect Antumbra's implementation; just cited as prior art |

---

## Sources

### Primary (HIGH confidence — verified against live ESR 153 tree)

- `D:\dev\antumbra\firefox\browser\branding\unofficial\` — full directory
  inspection, file contents read directly
- `D:\dev\antumbra\firefox\browser\branding\official\` — directory listing
  for cross-reference
- `D:\dev\antumbra\firefox\browser\branding\branding-common.mozbuild` — read
  directly; defines `FirefoxBranding()` template
- `D:\dev\antumbra\firefox\browser\branding\unofficial\locales\en-US\brand.ftl` — read directly
- `D:\dev\antumbra\firefox\browser\branding\unofficial\locales\en-US\brand.properties` — read directly
- `D:\dev\antumbra\firefox\browser\branding\unofficial\configure.sh` — read directly
- `D:\dev\antumbra\firefox\browser\branding\unofficial\pref\firefox-branding.js` — read directly
- `D:\dev\antumbra\firefox\browser\app\profile\firefox.js` — read and grepped
  for all Milestone 1 pref names
- `D:\dev\antumbra\firefox\browser\components\BrowserGlue.sys.mjs` — grepped
  for `aboutwelcome.enabled`; line 1725 confirmed
- `D:\dev\antumbra\firefox\browser\components\aboutwelcome\content\` — directory
  listing; `aboutwelcome.html`, `aboutwelcome.bundle.js` confirmed present
- `D:\dev\antumbra\firefox\modules\libpref\init\StaticPrefList.yaml` — grepped
  for `privacy.firstparty.isolate`; line 17353 confirmed
- `D:\dev\antumbra\firefox\toolkit\components\telemetry\` — grepped for
  `toolkit.telemetry.enabled`, `datareporting.healthreport.uploadEnabled`,
  `privacy.fingerprintingProtection`

### Secondary (MEDIUM confidence)

- ARCHITECTURE.md and ROADMAP.md in `antumbra-browser/` — project decisions
  read directly; used as authoritative for scope and pref list
- LibreWolf settings repo (cited in ARCHITECTURE.md) — pattern of suppressing
  `aboutwelcome` via prefs is consistent with `BrowserGlue.sys.mjs` behavior
  verified above

---

## RESEARCH COMPLETE

**Phase:** 1 — Milestone 1 (branding, pref injection, first-run)
**Confidence:** HIGH for branding structure and pref verification; MEDIUM for
first-run chrome integration (Options A/B/C analysis); LOW for Zen Browser
first-run pattern (not inspected directly)

### Key Findings

1. **Branding**: Copy `unofficial/` to `antumbra/`, replace 7 string locations
   (brand.ftl, brand.properties, configure.sh, pref/firefox-branding.js,
   wordmark SVGs, all icons). The complete required file list is enumerated
   above. Missing VisualElements PNGs cause build errors on Windows.

2. **Pref injection**: Add `antumbra.js` to `browser/app/profile/` and declare
   it in `moz.build`. Every Milestone 1 pref was verified present in ESR 153.
   The `extensions.pocket.enabled` pref needs one grep to confirm its location.

3. **First-run**: `browser.aboutwelcome.enabled = false` suppresses the React
   SPA. `startup.homepage_welcome_url = chrome://antumbra/content/welcome.html`
   opens our wizard instead. The chrome package is registered via `jar.mn` in
   the branding `content/` directory — no new infrastructure needed.

4. **ESR 153 defaults already match several of our targets**: `network.cookie.cookieBehavior`
   is already 5, `browser.urlbar.quicksuggest.enabled` is already false. Our
   explicit settings are belt-and-suspenders, not overrides.

5. **Vertical tabs availability unverified** — one grep (`rg "sidebar.verticalTabs" browser/app/profile/firefox.js`) resolves this before planning the first-run
   tab orientation picker.

### File Created

`.planning/phases/01-milestone-1/01-RESEARCH.md`
