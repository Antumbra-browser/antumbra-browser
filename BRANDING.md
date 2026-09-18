# Brand research: "Umbra" and the surrounding name system

Research date: 2026-09-18. Not legal advice. Before any public launch or
merchandise, pay a trademark attorney for a real Class 9 / Class 42 clearance
opinion. Everything below is open-source research, not a clearance search.

---

## 1. Verdict up front

**"Umbra" is not legally blocked, but it is commercially dead on arrival.**

The trademark risk is moderate and survivable. The market-collision risk is
severe: at least five other privacy browsers named Umbra already exist, three of
them with live public websites, and one of them is also a Firefox fork with
tiered privacy levels. Every clean domain is taken. The GitHub handles are taken.

Recommendation: change the browser name. Keep "Blackout mode". Change
"Shroud window".

---

## 2. Existing software named Umbra

### 2.1 Direct competitors (same name, same category, live today)

| Project | Where | What it is |
|---|---|---|
| Umbra | umbrabrowser.app | "Umbra — Privacy-First Browser". Live marketing site. iPhone, macOS, Linux. Blocks ads, strips trackers, isolates every tab. Tagline in use: "Browse in the umbra." |
| Umbra Browser | umbra-browser.org | "Privacy-first browsing", Firefox engine, Linux / macOS / Windows. Site says "currently in development", binaries coming at first release. Search indexes describe it as a Firefox ESR fork with three privacy tiers and uBlock Origin preinstalled. |
| Umbra Browser | umbrabrowser.online | "Privacy That Doesn't Break the Web". |
| umbra-browser | github.com/stillemptyNOW/umbra-browser | Chromium-based private browser. Windows, macOS, Linux, Android, iOS. No telemetry, no account, no sync server. |
| UmbraBrowser | github.com/norsehorse-dev/UmbraBrowser | Privacy-first iOS browser, SwiftUI + WebKit. Created 2026-08-18. |
| umbra | github.com/frteddz/umbra | "Showcase site for Umbra, a privacy-first browser. Pre-release." Created 2026-08-19. |

There is also an **Umbra Browser** entry already on AlternativeTo, which is the
single most important discovery surface for a privacy browser. That listing is
not yours and you cannot have it.

The umbra-browser.org project is the serious problem. It is the same base
(Firefox), the same positioning (usable privacy defaults), and the same tiering
concept (multiple privacy levels) under the same name. Shipping alongside it
guarantees permanent confusion about which project is which, whose CVE response
is whose, and whose build a user actually downloaded.

### 2.2 Adjacent privacy and security products named Umbra

- **Umbra VPN** (umbravpn.io) — open-source self-hosted WireGuard VPN client.
- **Umbra VPN** (umbravpn.app) — "Your Internet, Truly Private".
- **Umbra VPN: Private Proxy** — consumer iOS VPN app, no-logs marketing.
- **UMBRA Technologies Limited** — SD-WAN, VPN, next-generation firewall, data transfer.
- **Umbra Wallet** (github.com/raven-house/umbra-wallet-hub) — privacy-first browser extension wallet for Aztec.
- **Umbra Solutions / Caligo-class OT security vendors** are separate; see section 6.

### 2.3 Large non-software Umbra brands

- **Umbra LLC / Umbra Ltd** (umbra.com) — Toronto housewares and home decor giant. Owns the .com. Well-resourced and active in brand enforcement.
- **Umbra / Umbra Lab, Inc.** (umbra.space) — commercial SAR satellite constellation, Santa Barbara. Defense and intelligence customers. Heavy PR presence, which means they dominate news search for "Umbra".
- **Umbra Software Ltd** — Finnish 3D graphics middleware (occlusion culling).
- **UMBRAGROUP** — Italian aerospace mechanical components.
- **Philips Dynalite Antumbra** — lighting control wall panels (relevant to alternative #1 below).

---

## 3. USPTO trademark findings

No live US registration for the bare word UMBRA covering web browser software
was found. That means a Class 9 / 42 application is not automatically barred.
But the neighborhood is crowded, and crowding is what produces 2(d)
likelihood-of-confusion refusals and opposition letters.

| Mark | Serial / Reg | Owner | Class and goods | Status |
|---|---|---|---|---|
| UMBRA | 85022866 / 3893125 | Umbra LLC | 020 — furniture, mirrors, picture frames, home goods | Registered and renewed |
| UMBRA | 75080561 / 2060967 | UMBRA LTD | Home goods family | Registered |
| UMBRA TECHNOLOGIES | 86562838 / 6119133 | UMBRA Technologies (HK) Limited | Transmission of voice, audio, documents, images and data; Internet access services (Cl. 38) | Registered |
| UMBRA TECHNOLOGIES | 86562839 | UMBRA Technologies (HK) Limited | Related filing | See TSDR |
| UMBRA SECURITY | 99079793 | (applicant) | Technology consultation in the field of cybersecurity | Application, filed 2025-03-12 |
| UMBRA SOFTWARE | 85847001, 78611206 | Umbra Software Ltd | Software (3D graphics middleware) | See TSDR |
| UMBRA (filing) | 86510552 | Umbra Software Ltd | Software | See TSDR |
| UMBRA | 98340296 | Umbra Pay, LLC | Application | Pending |
| UD UMBRADATA | 77822046 | UmbraData | Anti-spyware, anti-virus, botnet protection software | **Cancelled** |

**Risk read:**

- **Highest practical risk: UMBRA Technologies (HK), Reg. 6119133.** Class 38
  covers Internet access and data transmission services, and the company sells
  VPN and firewall products. A privacy browser that ships a built-in Tor window
  is close enough to that description that an examining attorney could raise
  2(d), and close enough that the owner could plausibly send a demand letter.
- **UMBRA SECURITY (99079793)** is a pending application in cybersecurity
  services. If it registers, it further crowds Class 42 around your exact
  positioning.
- **Umbra LLC (home decor)** is in an unrelated class so a refusal is unlikely,
  but they are the kind of well-funded consumer brand that sends letters to
  anyone using their exact word on a consumer product. Defending is cheap in
  principle and expensive in practice for a solo FOSS maintainer.
- The **cancelled UD UMBRADATA** mark is a useful signal: an anti-spyware
  product with "Umbra" in the name already came and went in this space.

Note that a FOSS project with no revenue is a weak defendant, not a protected
one. Lack of commercial use does not stop a demand letter, and responding to one
costs money you would rather spend on builds.

---

## 4. Domain and handle availability

Checked via RDAP on 2026-09-18.

### Registered (unavailable)

`umbra.com` (Umbra home decor), `umbra.org`, `umbra.app`, `umbra.net`,
`umbra.dev`, `getumbra.com`, `getumbra.app`, `getumbra.org`,
`umbrabrowser.com`, `umbrabrowser.app` (live competitor site),
`umbra-browser.org` (live competitor site), `umbrabrowser.online` (live
competitor site), `useumbra.com`.

### Available per RDAP

`umbrabrowser.org`, `umbra-browser.com`, `umbrabrowser.dev`.

All three are one character away from a competitor's live site. Registering
`umbra-browser.com` next to an existing `umbra-browser.org` is actively worse
than having no domain, because it looks like typosquatting on someone else's
project.

### Unverified

`umbra.io`, `umbra.sh`. The registry RDAP endpoints were blocked by the research
environment's network policy. Check these manually.

### GitHub

| Handle | Status |
|---|---|
| `umbra` | Taken (account id 120526) |
| `umbrabrowser` | Taken (account id 71691369) |
| `Umbra-Project` | Taken (id 216579801) |
| `UmbraProjects` | Taken (id 83511456) |
| `UmbraProjects6` | Taken (id 208373894) |
| `umbra-browser` | Not found in user search, likely available |
| `getumbra` | Not found in user search, likely available |

GitHub's HTML endpoints were blocked in this environment, so "likely available"
means the search API returned no such account. Confirm by attempting to create
the org.

---

## 5. Feature name conflicts

### 5.1 "Blackout mode" — KEEP

- No software product meaningfully owns this phrase. Searches for blackout
  mode in the browser / adblock space return nothing that claims it.
- USPTO BLACKOUT marks exist in quantity but sit in unrelated goods: radiation
  shields for electronic products (Survivor 21 LLC, Ser. 88028936, Cl. 9),
  BLACKOUT VR, BLACKOUT BARBELL, BLACKOUT CANNABIS CO., BLACKOUT DESIGNS,
  BLACKOUT BEACON, THE BLACKOUT CLUB.
- A descriptive feature name inside a larger product is a weak mark and is
  rarely worth anyone's enforcement budget.
- Minor semantic drag: "blackout" already means a broadcast restriction and a
  power outage, and "blackout period" is a term of art at the USPTO itself.
  None of this is disqualifying.

**Verdict: low risk. Ship it.** Do not try to register it as a standalone mark.

### 5.2 "Shroud window" — CHANGE

- **Direct conflict:** *Shroud* is a privacy-first web browser published by
  Digital Guide on the Microsoft Store. It blocks trackers, ads and cookies and
  enforces HTTPS. Same word, same category, shipping today.
- **Search-dominance conflict:** "shroud" is one of the best-known handles in
  gaming and streaming (Michael Grzesiek). Your exact target demographic
  produces a wall of unrelated results for that word. You will never rank.
- **Connotation:** a shroud is what a body is wrapped in. For the feature that
  is supposed to make users feel safest, that is the wrong register.

Trademark exposure is low, because it is a feature name inside a larger product
and the Shroud browser is small. The problem is discoverability and tone.

**Suggested replacements, best first:**

1. **Relay window** — technically accurate to Tor's relay architecture,
   calm, and explains itself to a newcomer. "Open a Relay window" reads like
   infrastructure, not theater.
2. **Deep window** — short, evocative, no product collision found.
3. **Onion window** — the most self-explanatory. Onion routing is a generic
   technical term, so this is likely fine, but read the Tor Project's trademark
   policy before shipping, and do not use the Tor onion logo.

Avoid: "Ghost window" (Ghost is a CMS and a dozen VPNs), "Phantom window"
(Phantom is a major crypto wallet), "Incognito" (Google's).

---

## 6. If you change the name: three alternatives

Same spirit as Umbra: Latin-rooted, optical or nocturnal, short enough to say
out loud, dark without being edgelord.

### 6.1 Antumbra (recommended)

*Pronounced ant-UM-bra.* In optics, the antumbra is the region beyond the umbra
where the occluder appears surrounded by a ring of light. You are inside it,
looking out at a complete view of the world, while the thing between you and the
light blocks everything coming back. That is precisely what a content blocker
does, and it is a story no competitor can tell.

- Keeps the exact astronomical family you already picked, so nothing about the
  concept work is wasted.
- Distinctive enough to register. Far stronger as a mark than the common word "Umbra".
- Domains: `antumbra.com`, `.app`, `.org`, `.dev` are all registered (appear
  parked, worth a purchase inquiry). **`antumbrabrowser.com` is available.**
- GitHub: no conflicting org found.
- Known prior use: **Philips Dynalite Antumbra** lighting control wall panels.
  Unrelated goods, different buyer, no software overlap. Check it during formal
  clearance but it should not block Class 9 / 42.
- Downside: four syllables, and people will mistype it as "Anumbra" at first.

### 6.2 Tenebris

*Latin, "in darkness."* Clean, serious, and completely unoccupied in software.

- No privacy, security, VPN or browser product found using it.
- Domains: `tenebris.com`, `.app`, `.org` registered but not by notable software
  companies. **`tenebrisbrowser.com` is available.**
- GitHub: no conflicting org found.
- Downside: reads slightly Catholic-liturgical (Tenebrae), and non-Latin readers
  will be unsure how to say it.

### 6.3 Occulta

*Latin, "hidden things."* The best domain outcome of the three: **`occulta.org`
is available**, and `.org` is the correct TLD for a privacy browser
(torproject.org, mozilla.org). `occulta.com` and `occulta.app` are registered.

- Downside, and it is a real one: English speakers read it as "occult." For a
  project whose single hardest job is convincing people that an unsigned browser
  binary from a stranger is not malware, that is the wrong first impression.
  Listed for completeness, not recommended.

### Rejected during research

- **Caligo** (Latin, darkness/fog). Was the first choice until
  **Caligo Solutions / Caligo Systems** turned up: an Israeli cybersecurity
  company doing ICS and IIoT endpoint protection at caligocyber.com. Same
  industry. Out.
- **Obscura** — Obscura VPN is live and growing, plus Obscura Camera. Out.
- **Penumbra** — Penumbra Inc. is a NYSE-listed medical device company, and
  penumbra.zone is an active crypto privacy project. Out.
- **Noctura** — Noctura 400 is a medical device; all three main domains taken. Out.
- **Nyx, Erebus, Veil, Shade** — all heavily used in security and crypto. Out.

---

## 7. Taglines

1. **"Nothing follows you here."**
   Plain language, no jargon, states the entire value proposition in four words.
   Works on a download page, an F-Droid blurb, and a sticker. This is the one.

2. **"Cast no shadow."**
   Ties directly to the umbra/antumbra concept and means "leave no trace." Short,
   memorable, slightly ominous in a good way. Best as a secondary line under the
   logo.

3. **"Privacy on by default, not by checkbox."**
   The one that earns trust with the technical audience, because it is the exact
   complaint people have about every other browser. Use it in the README, the
   comparison table, and the Hacker News post.

Spare, if you want something with more teeth for merch:
**"Maximum is the default."**

Avoid any tagline referencing Firefox by name. Mozilla's trademark policy
restricts using their marks in product names and promotional taglines, and
"a Firefox fork" belongs in the technical description, not the brand line.

---

## 8. Icon concept: the eclipse

**The mark is a total eclipse.** A solid dark disc offset over a ring of light,
producing a bright crescent at the lower right.

Why it works:

- **Legible at 16px.** It resolves to a dark circle with one bright edge, which
  is all a favicon or an Android launcher icon can carry anyway.
- **Badass without being sketchy.** An eclipse is genuinely dramatic and
  genuinely astronomical. It reads as precision, not as crime.
- **The negative space is the product.** The umbra is the void at the center.
  The browser *is* the shadow.
- **It scales into a system.** The same disc carries every mode.

**Mode variants:**

| Mode | Mark |
|---|---|
| Standard | Dark disc, thin neutral ring |
| Strict | Dark disc, full amber corona |
| Blackout | Pure black disc, hairline outline only, no corona. The light is gone. |
| Relay window (Tor) | Three small dots spaced along the corona, nodding to Tor's three-hop circuit |

**Do not use:** padlocks, shields, hooded figures, masks, Guy Fawkes, keyholes,
fingerprints with a slash, spy silhouettes, or anything in "hacker green on
black." Every one of those reads either as generic stock security art or as
something a user's antivirus should probably quarantine. The single biggest
branding risk for an independent privacy browser is looking like malware, and
the icon is where that judgment gets made in under a second.

---

## 9. Color palette

Principle: trust comes from restraint and contrast discipline. Badass comes from
a near-black ground and exactly one high-chroma accent. Two accents maximum.

### Dark theme (primary)

| Token | Hex | Use |
|---|---|---|
| `--void` | `#0B0D10` | App background. Near-black with a blue cast, not pure `#000`. |
| `--umbra` | `#14181D` | Panels, toolbar, sidebar. |
| `--penumbra` | `#222933` | Borders, dividers, elevated surfaces. |
| `--ash` | `#8B95A3` | Secondary text, disabled states. |
| `--daylight` | `#E8ECF1` | Primary text. |
| `--corona` | `#FFB020` | **Primary accent.** The eclipse ring. Active tab, focus ring, primary buttons. |
| `--relay` | `#7C5CFF` | **Secondary accent.** Tor / Relay window chrome only. |
| `--signal` | `#35D07F` | Protected, verified, connected. |
| `--alarm` | `#FF4D4D` | Blocked count, certificate errors, insecure connection. |

Amber as the primary accent is the deliberate choice. Every privacy and security
brand on earth is blue or purple: ProtonVPN, Mullvad (yellow, the exception),
Tor, Brave (orange, the other exception), NordVPN, DuckDuckGo. Warm amber against
near-black is distinctive, reads as light in darkness, and carries a natural
"caution / high alert" undertone that suits a blocker.

Violet as the Tor accent follows the convention users already know from Firefox
private windows and Tor Browser, so the Relay window announces itself without a
tutorial.

### Light theme

| Token | Hex |
|---|---|
| `--void` | `#F7F8FA` |
| `--umbra` | `#FFFFFF` |
| `--penumbra` | `#DDE2E9` |
| `--ash` | `#5C6672` |
| `--daylight` | `#0B0D10` |
| `--corona` | `#B87400` |
| `--relay` | `#5B3FD9` |

`#FFB020` fails WCAG AA against white, so the light theme darkens the accent to
`#B87400`. Do not reuse the dark-theme amber on light backgrounds.

### Contrast notes

- `--corona` on `--void`: roughly 10:1. Safe for text and UI at any size.
- `--relay` on `--void`: roughly 5.4:1. Safe for large text and UI components.
  For body text on dark, lighten to `#9B85FF`.
- `--ash` on `--void`: roughly 7:1. Safe for secondary text.

### Mode color coding in chrome

- **Standard:** neutral, `--ash` accents. Nothing shouts.
- **Strict:** `--corona` amber accents.
- **Blackout:** chrome goes fully monochrome, pure `#000000` toolbar, no accent
  color at all. Removing the color is the strongest possible signal that
  everything else has been removed too.
- **Relay window:** `--relay` violet chrome throughout, matching the convention
  users already expect from private windows.

---

## 10. Recommended next steps

1. Decide on the name. If keeping Umbra despite the above, at minimum contact
   the umbra-browser.org maintainer first; two identically named Firefox privacy
   forks helps neither of you.
2. If changing: register `antumbrabrowser.com`, claim the GitHub org, and make a
   purchase inquiry on the parked `antumbra.com` / `antumbra.org`.
3. Pay for a real Class 9 and Class 42 clearance search before any merchandise,
   app store listing, or donation page goes live.
4. Rename "Shroud window" to "Relay window" across the codebase before the
   string freeze, while it is still cheap.
5. Keep "Blackout mode" as is.

---

## Sources

- https://umbrabrowser.app/
- https://umbra-browser.org/
- https://umbrabrowser.online/
- https://github.com/stillemptyNOW/umbra-browser
- https://github.com/norsehorse-dev/UmbraBrowser
- https://github.com/frteddz/umbra
- https://alternativeto.net/software/umbra-browser
- https://umbravpn.io/
- https://umbravpn.app/
- https://www.linkedin.com/company/umbratech
- https://umbra.com/
- https://umbra.space/
- https://en.wikipedia.org/wiki/Umbra_(3D_technology_company)
- https://trademarks.justia.com/850/22/umbra-85022866.html
- https://trademarks.justia.com/865/62/umbra-86562838.html
- https://trademarks.justia.com/990/79/umbra-99079793.html
- https://trademarks.justia.com/858/47/umbra-85847001.html
- https://trademarks.justia.com/983/40/umbra-98340296.html
- https://trademark.justia.com/778/22/ud-77822046.html
- https://uspto.report/TM/88028936
- https://apps.microsoft.com/detail/9mtnnzt1fm36
- https://caligocyber.com/
- https://support.brave.app/hc/en-us/articles/360018121491-What-is-a-Private-Window-with-Tor-Connectivity
- https://www.torproject.org/
