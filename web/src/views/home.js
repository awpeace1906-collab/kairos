import { el } from "../components.js";
import { makeSearch } from "../lib/search.js";
import { applyLens } from "../lib/settingLens.js";
import { prefs, CARE_SETTING_KEY, activeCareSetting } from "../lib/prefs.js";

export function renderHome(store, router) {
  const search = makeSearch(store.searchEntries);
  const results = el("div", { class: "results" });
  let setting = activeCareSetting();

  // per-section item counts for the tile badges
  const countBySection = {};
  for (const e of store.searchEntries) countBySection[e.section] = (countBySection[e.section] || 0) + 1;

  const input = el("input", {
    type: "search",
    class: "search-input",
    placeholder: "Search — “chest pain”, “epi dose”, “VExUS”",
    autocomplete: "off",
    onInput: () => update(),
  });

  let sectionFilter = null;
  const chips = el(
    "div",
    { class: "chips", hidden: true },
    el("button", { type: "button", class: "chip selected", onClick: (e) => setFilter(null, e) }, "All"),
    store.sections.map((s) =>
      el("button", { type: "button", class: "chip", onClick: (e) => setFilter(s.title, e) }, s.title)
    )
  );

  function setFilter(title, e) {
    sectionFilter = title;
    chips.querySelectorAll(".chip").forEach((c) => c.classList.remove("selected"));
    e.currentTarget.classList.add("selected");
    update();
  }

  // Care-setting lens selector — a lens, not a fork: it reorders, never filters.
  const settingChips = (store.careSettings || []).length
    ? el(
        "div",
        { class: "chips setting-chips" },
        el("span", { class: "setting-label" }, "Setting"),
        settingChip(null, "Any"),
        ...store.careSettings.slice().sort((a, b) => a.order - b.order).map((s) => settingChip(s.id, s.label))
      )
    : null;

  function settingChip(id, label) {
    const btn = el(
      "button",
      {
        type: "button",
        class: `chip${setting === id ? " selected" : ""}`,
        onClick: () => {
          setting = id;
          prefs.set(CARE_SETTING_KEY, id);
          settingChips.querySelectorAll(".chip").forEach((c) => c.classList.remove("selected"));
          btn.classList.add("selected");
          update();
        },
      },
      label
    );
    return btn;
  }

  // The one list of sections — each with its core-question description.
  const tiles = el(
    "div",
    { class: "section-tiles" },
    store.sections.map((s) =>
      el(
        "a",
        { class: "tile", href: `#/section/${s.id}`, "data-section": s.id },
        el("span", { class: "tile-mark", "aria-hidden": "true" }),
        el("span", { class: "tile-title" }, s.title),
        el("span", { class: "tile-count" }, String(countBySection[s.title] ?? "")),
        el("span", { class: "tile-q" }, s.coreQuestion)
      )
    )
  );
  const browse = el(
    "div",
    {},
    el("p", { class: "section-tiles-label" }, "Browse"),
    tiles
  );

  function update() {
    const q = input.value.trim();
    if (!q) {
      results.replaceChildren();
      results.hidden = true;
      chips.hidden = true;
      browse.hidden = false;
      return;
    }
    results.hidden = false;
    chips.hidden = false;
    browse.hidden = true;
    const hits = search(q, { section: sectionFilter, setting });
    if (!hits.length) {
      results.replaceChildren(el("p", { class: "muted" }, `No matches for “${q}”.`));
      return;
    }
    const bySection = groupBy(hits, (h) => h.section);
    results.replaceChildren(
      ...Object.entries(bySection).map(([section, items]) =>
        el(
          "div",
          { class: "result-group" },
          el("h3", { class: "result-section" }, section),
          el(
            "ul",
            {},
            applyLens(items, setting).map((it) =>
              el(
                "li",
                {},
                el(
                  "a",
                  { href: `#${it.route}`, class: "result-item" },
                  el("span", { class: "ri-title" }, it.title),
                  el("span", { class: "ri-cat" }, it.category)
                )
              )
            )
          )
        )
      )
    );
  }
  results.hidden = true;

  return el(
    "section",
    { class: "home" },
    el("div", { class: "brand" }, el("h1", {}, "Kairos"), el("p", {}, "the critical moment")),
    el("div", { class: "searchbar" }, input),
    settingChips,
    chips,
    results,
    browse,
    el(
      "p",
      { class: "home-footer" },
      el("a", { href: "#/about" }, "About"),
      " · ",
      el("a", { href: "#/sources" }, "Sources")
    )
  );
}

function groupBy(arr, fn) {
  return arr.reduce((acc, x) => {
    const k = fn(x);
    (acc[k] ||= []).push(x);
    return acc;
  }, {});
}
