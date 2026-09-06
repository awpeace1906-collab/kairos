import { el } from "../components.js";

// Settings -> "Sources". The complete bibliography for every piece of material
// in the app, aggregated from each module's sources[] by tools/build-sources-index.mjs.
// Pass 1 renders the raw citation strings, grouped and de-duplicated; a structured
// citation registry replaces the free text later.

export function renderSources(store) {
  const idx = store.sourcesIndex || { items: [], groupOrder: [] };
  const items = idx.items || [];
  const groups = (idx.groupOrder || []).filter((g) => items.some((it) => it.group === g));

  const search = el("input", {
    type: "search",
    class: "search-input",
    placeholder: "Filter sources…",
    onInput: () => render(search.value.trim().toLowerCase()),
  });
  const list = el("div", { class: "sources-list" });

  function render(q) {
    const shown = q
      ? items.filter((it) => it.text.toLowerCase().includes(q) || it.usedBy.some((u) => u.title.toLowerCase().includes(q)))
      : items;
    const blocks = [];
    for (const g of groups) {
      const gi = shown.filter((it) => it.group === g);
      if (!gi.length) continue;
      blocks.push(
        el("h2", {}, g, el("span", { class: "muted" }, ` · ${gi.length}`)),
        el("ol", { class: "sources-ol" }, gi.map((it) =>
          el("li", {},
            el("span", { class: "src-text" }, it.text),
            el("div", { class: "src-usedby" },
              "Cited in: ",
              it.usedBy.flatMap((u, i) => [
                i ? el("span", {}, ", ") : null,
                el("a", { href: `#${u.route}` }, u.title),
              ].filter(Boolean))
            )
          )
        ))
      );
    }
    list.replaceChildren(...(blocks.length ? blocks : [el("p", { class: "muted" }, "No matching sources.")]));
  }
  render("");

  return el(
    "section",
    { class: "content prose sources-page" },
    el("h1", {}, "Sources"),
    el("p", { class: "purpose" },
      `Every primary source behind the material in Kairos — ${items.length} references across the calculators, guides, drug cards, and reference library. Each page also lists its own sources at the bottom.`),
    el("div", { class: "searchbar" }, search),
    list,
    el("p", { class: "disclaimer" },
      "Listing a source here does not guarantee the linked page's content is current — check each page's own \"Last verified\" date. See ",
      el("a", { href: "#/about" }, "About › Medical & legal disclaimer"),
      " for the full disclaimer."),
    el("p", { class: "last-verified" }, "Generated from content/sources-index.json · citations are being migrated to a structured registry.")
  );
}
