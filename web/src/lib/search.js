// One flat index, substring match, ranked title > tags > keywords
// (Search_TOC_Design_Spec.md). Per-section search = this, pre-filtered by section.

export function makeSearch(entries) {
  return function search(query, { section = null } = {}) {
    const q = query.trim().toLowerCase();
    const pool = section ? entries.filter((e) => e.section === section) : entries;
    if (!q) return [];
    const scored = [];
    for (const e of pool) {
      const rank = matchRank(e, q);
      if (rank > 0) scored.push({ entry: e, rank });
    }
    scored.sort((a, b) => b.rank - a.rank || a.entry.title.localeCompare(b.entry.title));
    return scored.map((s) => s.entry);
  };
}

function matchRank(e, q) {
  const title = e.title.toLowerCase();
  if (title === q) return 100;
  if (title.startsWith(q)) return 80;
  if (title.includes(q)) return 60;
  if ((e.tags || []).some((t) => t.toLowerCase().includes(q))) return 40;
  if ((e.keywords || []).some((k) => k.toLowerCase().includes(q))) return 20;
  if (e.category.toLowerCase().includes(q)) return 10;
  return 0;
}

/** Section -> Category -> Item tree for the empty-state TOC. */
export function buildTOC(entries, sectionsConfig) {
  return sectionsConfig.sections.map((section) => {
    const inSection = entries.filter((e) => e.section === section.title);
    return {
      id: section.id,
      title: section.title,
      count: inSection.length,
      categories: section.categories
        .map((cat) => ({
          id: cat.id,
          title: cat.title,
          items: inSection
            .filter((e) => e.category === cat.title)
            .sort((a, b) => a.title.localeCompare(b.title)),
        }))
        .filter((c) => c.items.length > 0),
    };
  });
}
