import { el } from "../components.js";
import { makeSearch, buildTOC } from "../lib/search.js";
import { applyLens } from "../lib/settingLens.js";
import { prefs, CARE_SETTING_KEY, activeCareSetting } from "../lib/prefs.js";

const SECTION_META = {
  procedures: { icon: "🩹" },
  calculators: { icon: "🧮" },
  "drug-dosing": { icon: "💊" },
  "reference-library": { icon: "📚" },
  "peds-module": { icon: "🧒" },
};

export function renderHome(store, router) {
  const search = makeSearch(store.searchEntries);
  const results = el("div", { class: "results" });
  const toc = el("div", { class: "toc" });
  let setting = activeCareSetting();

  const input = el("input", {
    type: "search",
    class: "search-input",
    placeholder: "Search all sections — e.g. “chest pain”, “gbs”, “epi dose”",
    autocomplete: "off",
    onInput: () => update(),
  });

  let sectionFilter = null;
  const chips = el(
    "div",
    { class: "chips" },
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

  // Care-setting lens selector (DIRECTIONS_FORWARD §1). A lens, not a fork —
  // it reorders, never filters.
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
      { type: "button", class: `chip${setting === id ? " selected" : ""}`, onClick: () => {
        setting = id;
        prefs.set(CARE_SETTING_KEY, id);
        settingChips.querySelectorAll(".chip").forEach((c) => c.classList.remove("selected"));
        btn.classList.add("selected");
        renderTOC();
        update();
      } },
      label
    );
    return btn;
  }

  function update() {
    const q = input.value.trim();
    if (!q) {
      results.replaceChildren();
      toc.hidden = false;
      return;
    }
    toc.hidden = true;
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

  // Empty-state: collapsible Section -> Category -> Item tree
  function renderTOC() {
    toc.replaceChildren(
      ...buildTOC(store.searchEntries, { sections: store.sections }, setting).map((section) => {
        const meta = SECTION_META[section.id] || {};
        return el(
          "details",
          { class: "toc-section" },
          el("summary", {}, `${meta.icon || "•"} ${section.title} (${section.count})`),
          section.categories.map((cat) =>
            el(
              "details",
              { class: "toc-cat" },
              el("summary", {}, `${cat.title} (${cat.items.length})`),
              el("ul", {}, cat.items.map((it) => el("li", {}, el("a", { href: `#${it.route}` }, it.title))))
            )
          )
        );
      })
    );
  }
  renderTOC();

  const tiles = el(
    "div",
    { class: "section-tiles" },
    store.sections.map((s) =>
      el(
        "a",
        { class: "tile", href: `#/section/${s.id}`, "data-section": s.id },
        el("span", { class: "tile-icon" }, (SECTION_META[s.id] || {}).icon || "•"),
        el("span", { class: "tile-title" }, s.title),
        el("span", { class: "tile-q" }, s.coreQuestion)
      )
    )
  );

  return el(
    "section",
    { class: "home" },
    el("div", { class: "brand" }, el("h1", {}, "Kairos"), el("p", {}, "the critical moment")),
    el("div", { class: "searchbar" }, input),
    chips,
    settingChips,
    results,
    toc,
    tiles,
    el("p", { class: "home-footer" },
      el("a", { href: "#/about" }, "About Kairos"),
      " · ",
      el("a", { href: "#/sources" }, "Sources"))
  );
}

function groupBy(arr, fn) {
  return arr.reduce((acc, x) => {
    const k = fn(x);
    (acc[k] ||= []).push(x);
    return acc;
  }, {});
}
