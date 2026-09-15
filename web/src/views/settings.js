import { el } from "../components.js";
import {
  prefs,
  CARE_SETTING_KEY,
  activeCareSetting,
  THEME_KEY,
  activeTheme,
  applyTheme,
  PEDS_LENS_KEY,
  activePedsLens,
  PINS_KEY,
} from "../lib/prefs.js";
import { newIssueURL, APP_VERSION } from "../lib/appConfig.js";

// The Settings tab's root. Frequently touched preferences (care setting, Peds
// lens, appearance) stay inline; read-once-then-forget info (About, Legal,
// Acknowledgments) lives behind submenus (#/about/info etc.) instead of one
// long scroll.

function chipRow(options, active, onPick) {
  const row = el("div", { class: "chips" });
  const buttons = options.map(([id, label]) => {
    const b = el("button", {
      type: "button",
      class: `chip${active === id ? " selected" : ""}`,
      onClick: () => {
        onPick(id);
        row.querySelectorAll(".chip").forEach((c) => c.classList.remove("selected"));
        b.classList.add("selected");
      },
    }, label);
    return b;
  });
  row.append(...buttons);
  return row;
}

function appearancePicker() {
  return el(
    "div", { class: "settings-row" },
    el("h2", {}, "Appearance"),
    chipRow(
      [["system", "System"], ["light", "Light"], ["dark", "Dark"]],
      activeTheme(),
      (id) => { prefs.set(THEME_KEY, id === "system" ? null : id); applyTheme(); }
    )
  );
}

function careSettingPicker(store) {
  const opts = (store?.careSettings || []).slice().sort((a, b) => a.order - b.order);
  if (!opts.length) return null;
  return el(
    "div", { class: "settings-row" },
    el("h2", {}, "Care setting"),
    el("p", { class: "muted" }, "Tune the app to where you're working now. It reorders and emphasizes — it never hides content or changes a dose."),
    chipRow(
      [[null, "Any"], ...opts.map((o) => [o.id, o.label])],
      activeCareSetting(),
      (id) => prefs.set(CARE_SETTING_KEY, id)
    )
  );
}

function pedsLensToggle() {
  let on = activePedsLens();
  const btn = el(
    "button",
    {
      type: "button",
      class: "chip peds-toggle" + (on ? " selected" : ""),
      onClick: () => {
        on = !on;
        prefs.set(PEDS_LENS_KEY, on);
        btn.classList.toggle("selected", on);
      },
    },
    "Peds lens"
  );
  return el(
    "div", { class: "settings-row" },
    el("h2", {}, "Peds lens"),
    el("p", { class: "muted" }, "Floats pediatric content to the top of any list — it never hides the adult content underneath."),
    btn
  );
}

function contentSection() {
  const resetBtn = el("button", { type: "button", class: "opt" }, "Reset pinned shortcuts to default");
  resetBtn.disabled = prefs.get(PINS_KEY, null) === null;
  resetBtn.addEventListener("click", () => {
    prefs.set(PINS_KEY, null);
    resetBtn.disabled = true;
  });
  return el("div", { class: "settings-row" }, el("h2", {}, "Content"), resetBtn);
}

function infoLinks() {
  return el(
    "div", { class: "settings-row settings-links" },
    el("h2", {}, "Info"),
    el("a", { class: "settings-link", href: "#/about/info" }, "About Kairos", el("span", { "aria-hidden": "true" }, "›")),
    el("a", { class: "settings-link", href: "#/about/disclaimer" }, "Medical & Legal Disclaimer", el("span", { "aria-hidden": "true" }, "›")),
    el("a", { class: "settings-link", href: "#/about/acknowledgments" }, "Acknowledgments", el("span", { "aria-hidden": "true" }, "›"))
  );
}

function supportLinks() {
  const url = newIssueURL();
  return el(
    "div", { class: "settings-row settings-links" },
    el("h2", {}, "Support"),
    el("a", { class: "settings-link", href: url, target: "_blank", rel: "noopener" }, "Report an issue")
  );
}

export function renderSettings(store) {
  return el(
    "section",
    { class: "content settings" },
    el("h1", {}, "Settings"),
    appearancePicker(),
    careSettingPicker(store),
    pedsLensToggle(),
    contentSection(),
    infoLinks(),
    supportLinks(),
    el("p", { class: "last-verified" }, `Kairos v${APP_VERSION} · content bundle from content/manifest.json`)
  );
}
