/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

/* Antumbra first-run wizard controller.
 * Runs in a privileged chrome page (chrome://antumbra/content/welcome.html).
 * Writes user choices to prefs via Services.prefs and closes.
 */

"use strict";

const { Services } = ChromeUtils.importESModule(
  "resource://gre/modules/Services.sys.mjs"
);
const { AntumbraMode } = ChromeUtils.importESModule(
  "resource://antumbra/AntumbraMode.sys.mjs"
);

// --- State ---
let selectedMode = "standard";
let selectedResolver = null;
let selectedTabs = "vertical";
let resolvers = [];

// --- Screen navigation ---
const screens = ["screen-mode", "screen-dns", "screen-tabs", "screen-password", "screen-updates"];
let currentScreen = 0;

function showScreen(idx) {
  screens.forEach((id, i) => {
    document.getElementById(id).classList.toggle("active", i === idx);
  });
  currentScreen = idx;
}

// --- Mode picker ---
document.querySelectorAll(".mode-card").forEach(card => {
  card.addEventListener("click", () => {
    document.querySelectorAll(".mode-card").forEach(c => c.classList.remove("selected"));
    card.classList.add("selected");
    selectedMode = card.dataset.mode;
  });
  card.addEventListener("keydown", e => {
    if (e.key === "Enter" || e.key === " ") card.click();
  });
});

document.getElementById("mode-next").addEventListener("click", () => showScreen(1));

// --- DNS resolver picker ---
async function loadResolvers() {
  try {
    const resp = await fetch("chrome://antumbra/content/dns-resolvers.json");
    const data = await resp.json();
    resolvers = data.resolvers;
  } catch {
    // Fallback: Quad9 only.
    resolvers = [{
      id: "quad9", name: "Quad9",
      url: "https://dns.quad9.net/dns-query",
      description: "Non-profit. Switzerland. No logging of source IPs.",
      default: true
    }];
  }

  const list = document.getElementById("resolver-list");
  list.innerHTML = "";
  resolvers.forEach(r => {
    const item = document.createElement("div");
    item.className = "resolver-item" + (r.default ? " selected" : "");
    item.dataset.id = r.id;
    item.innerHTML = `
      <input type="radio" name="resolver" value="${r.id}" ${r.default ? "checked" : ""}>
      <div>
        <div class="r-name">${r.name}</div>
        <div class="r-desc">${r.description}</div>
      </div>`;
    item.addEventListener("click", () => {
      document.querySelectorAll(".resolver-item").forEach(el => el.classList.remove("selected"));
      item.classList.add("selected");
      item.querySelector("input").checked = true;
      selectedResolver = r;
      document.getElementById("custom-url-row").style.display =
        r.id === "custom" ? "block" : "none";
    });
    list.appendChild(item);
    if (r.default) selectedResolver = r;
  });
}

loadResolvers();

document.getElementById("dns-back").addEventListener("click", () => showScreen(0));
document.getElementById("dns-next").addEventListener("click", () => showScreen(2));

// --- Tab layout ---
document.querySelectorAll(".tab-option").forEach(opt => {
  opt.addEventListener("click", () => {
    document.querySelectorAll(".tab-option").forEach(o => o.classList.remove("selected"));
    opt.classList.add("selected");
    selectedTabs = opt.dataset.tabs;
  });
});

document.getElementById("tabs-back").addEventListener("click", () => showScreen(1));
document.getElementById("tabs-next").addEventListener("click", () => showScreen(3));

// --- Password screen ---
document.getElementById("pw-back").addEventListener("click", () => showScreen(2));
document.getElementById("pw-next").addEventListener("click", () => showScreen(4));

// --- Updates screen ---
document.getElementById("updates-back").addEventListener("click", () => showScreen(3));
document.getElementById("updates-finish").addEventListener("click", applyChoicesAndClose);

// --- Apply all choices ---
function applyChoicesAndClose() {
  // 1. Protection mode
  try {
    AntumbraMode.applyMode(selectedMode);
  } catch (e) {
    console.error("AntumbraMode.applyMode failed:", e);
  }

  // 2. DNS resolver
  if (selectedResolver) {
    if (selectedResolver.id === "system") {
      // System resolver: disable TRR (mode 0).
      Services.prefs.setIntPref("network.trr.mode", 0);
    } else if (selectedResolver.id === "custom") {
      const url = document.getElementById("custom-url").value.trim();
      if (url) {
        Services.prefs.setCharPref("network.trr.uri", url);
        Services.prefs.setCharPref("network.trr.custom_uri", url);
        Services.prefs.setIntPref("network.trr.mode", 2);
      }
    } else if (selectedResolver.url) {
      Services.prefs.setCharPref("network.trr.uri", selectedResolver.url);
      Services.prefs.setCharPref("network.trr.custom_uri", selectedResolver.url);
      Services.prefs.setIntPref("network.trr.mode", 2);
    }
  }

  // 3. Tab layout
  try {
    // sidebar.verticalTabs may not exist in all ESR 153 builds (ARCHITECTURE.md 6.8).
    if (Services.prefs.getPrefType("sidebar.verticalTabs") !== Services.prefs.PREF_INVALID) {
      Services.prefs.setBoolPref("sidebar.verticalTabs", selectedTabs === "vertical");
    }
    if (Services.prefs.getPrefType("sidebar.revamp") !== Services.prefs.PREF_INVALID) {
      Services.prefs.setBoolPref("sidebar.revamp", selectedTabs === "vertical");
    }
  } catch (e) {
    console.warn("sidebar prefs not available in this build:", e);
  }

  // 4. Mark first run complete so the wizard does not re-open.
  Services.prefs.setBoolPref("antumbra.firstrun.complete", true);
  // Clear the welcome URL so subsequent new tabs go to about:newtab.
  Services.prefs.setCharPref("startup.homepage_welcome_url", "");

  // 5. Close this tab.
  window.close();
}
