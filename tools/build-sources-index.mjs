// Aggregate every module's `sources[]` into content/sources-index.json — the
// data behind the global "Sources" page and (later) the per-page numbered lists.
// Pass 1: the raw free-text strings, de-duplicated. A structured citation
// registry (content/config/citations.json) will replace the free text later.
import { writeFile } from "node:fs/promises";
import { join } from "node:path";
import { loadModules, routeFor, iso, CONTENT_DIR } from "./lib/content.mjs";

const mods = await loadModules();

// normalise for dedup: trim, collapse whitespace, drop a single trailing period
const keyOf = (s) => String(s).replace(/\s+/g, " ").trim().replace(/\.\s*$/, "").toLowerCase();

const byKey = new Map();
for (const mod of mods) {
  const j = mod.json;
  for (const raw of j.sources || []) {
    const k = keyOf(raw);
    if (!k) continue;
    const surface = String(raw).replace(/\s+/g, " ").trim();
    let rec = byKey.get(k);
    if (!rec) {
      rec = { text: surface, usedBy: [] };
      byKey.set(k, rec);
    } else if (surface.length > rec.text.length) {
      rec.text = surface; // keep the fullest surface form seen
    }
    if (!rec.usedBy.some((u) => u.id === j.id)) {
      rec.usedBy.push({ id: j.id, title: j.title, section: j.section, route: routeFor(mod) });
    }
  }
}

// crude type bucket for grouping on the page
function bucket(text) {
  const t = text.toLowerCase();
  if (/\bguidelines?\b|\bconsensus\b|\bscientific statement\b|\bfocused update\b|\bACC\/AHA\b|\bAHA\b|\bASA\b|\bDAS\b|\bNICE\b|\bKDIGO\b|\bGOLD\b|\bSurviving Sepsis\b|\bWSES\b|\bACOG\b|\bIDSA\b/i.test(text)) return "Guidelines & consensus statements";
  if (/\btrial\b|randomi[sz]ed|\bRCT\b|\bNEJM\b|\bLancet\b|\bJAMA\b/i.test(text)) return "Randomized trials & major studies";
  if (/\bcohort\b|observational|registry|meta-analysis|systematic review|derivation|validation/i.test(t)) return "Cohort, registry & systematic reviews";
  if (/miller'?s|barash|\bATLS\b|\bUpToDate\b|textbook|\bStoelting\b|\brosen'?s\b|\btintinalli\b|pocket guide|drug library|drugcard/i.test(t)) return "Reference texts & drug libraries";
  return "Other primary sources";
}

const BUCKET_ORDER = [
  "Guidelines & consensus statements",
  "Randomized trials & major studies",
  "Cohort, registry & systematic reviews",
  "Reference texts & drug libraries",
  "Other primary sources",
];

const items = [...byKey.values()].map((r) => ({
  text: r.text,
  group: bucket(r.text),
  usedBy: r.usedBy.sort((a, b) => a.title.localeCompare(b.title)),
}));

// sort: group order, then by a rough "first author / first word" key
const sortKey = (t) => t.replace(/^["'“”]/, "").toLowerCase();
items.sort((a, b) => {
  const g = BUCKET_ORDER.indexOf(a.group) - BUCKET_ORDER.indexOf(b.group);
  return g !== 0 ? g : sortKey(a.text).localeCompare(sortKey(b.text));
});

const out = {
  generatedAt: iso() + "T00:00:00Z",
  groupOrder: BUCKET_ORDER,
  count: items.length,
  items,
};
await writeFile(join(CONTENT_DIR, "sources-index.json"), JSON.stringify(out, null, 2) + "\n");
console.log(`✓ sources-index.json — ${items.length} unique sources across ${mods.length} modules`);
