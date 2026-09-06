import { el } from "../components.js";
import { makeSearch, buildTOC } from "../lib/search.js";

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

  function update() {
    const q = input.value.trim();
    if (!q) {
      results.replaceChildren();
      toc.hidden = false;
      return;
    }
    toc.hidden = true;
    const hits = search(q, { section: sectionFilter });
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
            items.map((it) =>
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
  for (const section of buildTOC(store.searchEntries, { sections: store.sections })) {
    const meta = SECTION_META[section.id] || {};
    toc.append(
      el(
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
      )
    );
  }

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
