import { el } from "../components.js";
import { makeSearch } from "../lib/search.js";

/** A single section: its own search bar (the flat index pre-filtered) + category list. */
export function renderSection(sectionId, store) {
  const section = store.sections.find((s) => s.id === sectionId);
  if (!section) return el("section", { class: "content" }, el("h1", {}, "Unknown section"));

  const search = makeSearch(store.searchEntries);
  const entries = store.searchEntries.filter((e) => e.section === section.title);
  const list = el("div", { class: "section-list" });

  const input = el("input", {
    type: "search",
    class: "search-input",
    placeholder: `Search ${section.title}…`,
    onInput: () => render(input.value.trim()),
  });

  function render(q) {
    const pool = q ? search(q, { section: section.title }) : entries;
    const byCat = {};
    for (const e of pool) (byCat[e.category] ||= []).push(e);
    list.replaceChildren(
      ...section.categories
        .filter((c) => byCat[c.title]?.length)
        .map((c) =>
          el(
            "details",
            { class: "toc-cat", open: !!q },
            el("summary", {}, `${c.title} (${byCat[c.title].length})`),
            el("ul", {}, byCat[c.title].sort((a, b) => a.title.localeCompare(b.title)).map((it) =>
              el("li", {}, el("a", { href: `#${it.route}` }, it.title))
            ))
          )
        )
    );
    if (!pool.length) list.replaceChildren(el("p", { class: "muted" }, "No matches."));
  }

  render("");
  return el(
    "section",
    { class: "content section-view" },
    el("a", { href: "#/", class: "back" }, "‹ Home"),
    el("h1", {}, section.title),
    el("p", { class: "purpose" }, section.coreQuestion),
    el("div", { class: "searchbar" }, input),
    list
  );
}
