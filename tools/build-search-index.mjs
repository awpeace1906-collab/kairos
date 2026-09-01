// Flatten every module into content/search-index.json — one flat array, generated,
// never hand-maintained (Search_TOC_Design_Spec.md).
import { writeFile } from "node:fs/promises";
import { join } from "node:path";
import { loadModules, routeFor, iso, CONTENT_DIR } from "./lib/content.mjs";

const mods = await loadModules();

const entries = mods.map((mod) => {
  const j = mod.json;
  return {
    id: j.id,
    title: j.title,
    section: j.section,
    category: j.category,
    tags: dedupe(j.tags),
    keywords: dedupe([...(j.keywords || []), ...(j.aliases || [])]),
    contentType: j.contentType,
    route: routeFor(mod),
  };
});

entries.sort((a, b) => (a.section + a.category + a.title).localeCompare(b.section + b.category + b.title));

const out = { generatedAt: iso() + "T00:00:00Z", entries };
await writeFile(join(CONTENT_DIR, "search-index.json"), JSON.stringify(out, null, 2) + "\n");
console.log(`✓ search-index.json — ${entries.length} entries`);

function dedupe(arr) {
  return [...new Set((arr || []).map((s) => String(s).trim()).filter(Boolean))];
}
