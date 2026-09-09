import { el, tintStyleForSection } from "../components.js";
import { makeSearch } from "../lib/search.js";
import { emphasisRank, isPeds } from "../lib/settingLens.js";
import { activeCareSetting, activePedsLens, prefs, PEDS_LENS_KEY } from "../lib/prefs.js";

/** A single section: its own search bar (the flat index pre-filtered) + category list.
    Modules whose `crossListIn` names this section appear here too, flagged. */
export function renderSection(sectionId, store) {
  const section = store.sections.find((s) => s.id === sectionId);
  if (!section) return el("section", { class: "content" }, el("h1", {}, "Unknown section"));

  const search = makeSearch(store.searchEntries);
  const setting = activeCareSetting();
  let peds = activePedsLens();

  // this section = own modules + anything cross-listed into it
  const homeHere = (e) => e.section === section.title;
  const xListedHere = (e) => (e.crossListIn || []).some((x) => x.section === section.title);
  const inThisSection = (e) => homeHere(e) || xListedHere(e);
  const catFor = (e) =>
    homeHere(e) ? e.category : (e.crossListIn.find((x) => x.section === section.title)?.category ?? e.category);
  const sectionEntries = store.searchEntries.filter(inThisSection);
  const hasPeds = sectionEntries.some(isPeds);

  const list = el("div", { class: "section-list" });
  const input = el("input", {
    type: "search",
    class: "search-input",
    placeholder: `Search ${section.title}…`,
    onInput: () => render(input.value.trim()),
  });
  const pedsToggle = hasPeds
    ? el(
        "button",
        {
          type: "button",
          class: "chip peds-toggle" + (peds ? " selected" : ""),
          "aria-pressed": String(peds),
          onClick: (e) => {
            peds = !peds;
            prefs.set(PEDS_LENS_KEY, peds);
            e.currentTarget.classList.toggle("selected", peds);
            e.currentTarget.setAttribute("aria-pressed", String(peds));
            render(input.value.trim());
          },
        },
        "Peds"
      )
    : null;

  function render(q) {
    const pool = q ? search(q).filter(inThisSection) : sectionEntries;
    const byCat = {};
    for (const e of pool) (byCat[catFor(e)] ||= []).push(e);
    const rank = (a, b) =>
      (peds ? (isPeds(a) ? 0 : 1) - (isPeds(b) ? 0 : 1) : 0) ||
      emphasisRank(a, setting) - emphasisRank(b, setting) ||
      a.title.localeCompare(b.title);
    list.replaceChildren(
      ...section.categories
        .filter((c) => byCat[c.title]?.length)
        .map((c) =>
          el(
            "details",
            { class: "toc-cat", open: !!q },
            el("summary", {}, `${c.title} (${byCat[c.title].length})`),
            el(
              "ul",
              {},
              byCat[c.title].sort(rank).map((it) =>
                el(
                  "li",
                  {},
                  el("a", { href: `#${it.route}` }, it.title),
                  !homeHere(it) ? el("span", { class: "xlist-badge" }, "peds") : null
                )
              )
            )
          )
        )
    );
    if (!pool.length) list.replaceChildren(el("p", { class: "muted" }, "No matches."));
  }

  render("");
  return el(
    "section",
    { class: "content section-view", style: tintStyleForSection(section.title) },
    el("a", { href: "#/", class: "back" }, "‹ Home"),
    el("h1", {}, section.title),
    el("p", { class: "purpose" }, section.coreQuestion),
    el("div", { class: "searchbar" }, input),
    pedsToggle ? el("div", { class: "chips section-lens" }, pedsToggle) : null,
    list
  );
}
