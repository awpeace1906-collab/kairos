# App-Wide Search & Home-Screen TOC — Design Spec

**Resolves the two open Tier 5 items from the original design notes:** per-section search and
a searchable home-screen table of contents/site map. Both are designed here as one system,
not two — the home-screen search IS the global index; each section's local search is just
that same index pre-filtered to one section.

---

## Core architecture decision

**One flat search index, not five separate ones.** Every searchable item across all 5
sections — every calculator, drug card, procedure guide, reference topic, peds tool — gets
one entry in a single JSON array, bundled with the app as a static asset (not a live server
query). Given the content is static reference data numbering in the hundreds of items, not
tens of thousands, a linear/substring scan against this array is fast enough on-device
without needing a search server, Elasticsearch, or similar — this is a deliberate
"don't over-engineer it" call.

```json
{
  "id": "calc-heart-score",
  "title": "HEART Score for Major Cardiac Events",
  "section": "Calculators",
  "category": "Cardiovascular / Chest Pain / Arrhythmia",
  "tags": ["chest pain", "ACS", "risk stratification", "ED"],
  "keywords": ["heart score", "mace", "cardiac risk"],
  "contentType": "calculator",
  "route": "/calculators/cardiovascular/heart-score"
}
```

- **id** — stable unique identifier, never reused even if content is later removed
- **title** — exact display name (what appears in search results)
- **section** — one of the 5 top-level sections, drives the color/theme applied to the result card and which icon shows
- **category** — the sub-category within that section (matches the groupings already used in `Calculator_Logic_Build_Spec.md` and the other content specs), shown as a subtitle in search results
- **tags** — clinician-facing synonyms and related concepts (what someone would actually type under pressure — "chest pain" not just "HEART Score")
- **keywords** — abbreviations, alternate names, common misspellings (e.g., "GBS" for Glasgow-Blatchford)
- **contentType** — `calculator` / `procedure` / `reference` / `drug-card` / `peds-tool` — drives which icon/visual treatment renders
- **route** — the in-app deep link so tapping a search result navigates directly to that item, not just its section

**Generation approach:** don't hand-write this index separately from the content. Generate it
at build time from the same source data used to render each section (i.e., every content spec
in this package — `Calculator_Logic_Build_Spec.md`, `Procedures_Content_Spec.md`, etc. —
should ultimately live as structured data, not prose, and the search index is a flattened
projection of that data). This guarantees the index can never drift out of sync with what's
actually in the app, which a hand-maintained parallel list would risk.

---

## Home-screen searchable TOC

The home screen shows:
1. **A search bar at the top** — typing here searches the full flat index above, live,
   with results grouped by section (small section-colored header above each group) rather
   than one undifferentiated list. This is what makes it a "site map" and not just a search
   box — even with no query typed, tapping into the search bar could optionally show the
   full TOC as a scrollable, collapsible tree (Section → Category → Item) as the empty state,
   so browsing and searching are the same interface, not two separate ones.
2. **5 section entry tiles below the search bar** (Procedures, Calculators, Drug & Dosing
   Cards, Reference Library, Peds Module) for direct navigation when the user already knows
   which section they want and doesn't need search.

**Empty-state TOC structure** (what renders when the search bar is tapped but empty):
```
▸ Procedures (6)
▸ Calculators (85)
  ▾ Cardiovascular / Chest Pain / Arrhythmia (10)
      HEART Score for Major Cardiac Events
      TIMI Risk Score (UA/NSTEMI)
      ...
  ▸ Pulmonary / PE / DVT / Resp Failure (10)
  ▸ Neuro / Stroke / Head Injury (10)
  ...
▸ Drug & Dosing Cards
▸ Reference Library
▸ Peds Module
```
Collapsed by default at the Section level; tapping a section expands to categories; tapping
a category expands to items. This mirrors the exact grouping structure already used
throughout the content specs, so there's no separate information architecture to design or
maintain — the TOC's tree IS the same category structure the content is already organized
into.

---

## Search matching behavior

- **Match against:** title, tags, and keywords (in that priority order for ranking — a title
  match ranks above a tag match, which ranks above a keyword match).
- **Substring match, not exact match** — "gbs" should surface Glasgow-Blatchford via its
  keyword entry; "chest pain" should surface HEART, TIMI, GRACE, and anything else tagged
  with it, not just items with "chest pain" literally in the title.
- **No fuzzy/typo-tolerant matching in v1** — given the dataset size and that most users are
  typing on a phone under time pressure (short queries, likely to be entered carefully),
  substring matching against a well-tagged index should cover the real use cases. Revisit
  only if user feedback shows a specific recurring miss.
- **Section filter chips** above the results — let the user narrow to just "Calculators" or
  just "Peds Module" after an initial broad search, rather than requiring a new query.

---

## Per-section local search

Not a separate system — when a user is already inside, say, the Calculators section and uses
that section's search bar, it's the exact same index and matching logic, just pre-filtered
to `section: "Calculators"` before the query runs. No separate index, no separate matching
code path. This is the main payoff of the "one flat index" architecture decision above: local
search is free once global search exists, rather than being a second thing to build.

---

## What's NOT resolved by this spec

- **The actual index population** — this spec defines the schema and behavior; populating
  the `tags`/`keywords` arrays for all ~150+ items across the 5 sections is real content work
  that should happen alongside writing each section's actual content, not as an afterthought
  pass at the end. Budget time for it in each section's build, not as a separate phase.
- **Analytics on search misses** — worth logging queries that return zero results once the
  app is live, to catch tagging gaps you didn't anticipate. Not needed for v1 launch, but
  cheap to add now if the logging infrastructure is already being built for other purposes.
