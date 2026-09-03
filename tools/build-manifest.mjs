// Regenerate content/manifest.json — the lightweight file both clients poll.
// Version numbers + hashes only, never the content itself.
import { writeFile } from "node:fs/promises";
import { join } from "node:path";
import { loadModules, contentHash, iso, CONTENT_DIR } from "./lib/content.mjs";

const mods = await loadModules();
const modules = {};

for (const mod of mods) {
  const j = mod.json;
  modules[mod.key] = {
    content_version: j.content_version,
    hash: contentHash(j),
    path: mod.relPath,
    contentType: j.contentType,
    section: j.section,
    ...(j.review_tier !== undefined ? { review_tier: j.review_tier } : {}),
    ...(j.next_review_due ? { next_review_due: j.next_review_due } : {}),
  };
}

const out = {
  generatedAt: iso() + "T00:00:00Z",
  schemaVersion: 1,
  contentBaseHint: process.env.CONTENT_BASE_URL || "https://content.kairos.example/v1/",
  modules: Object.fromEntries(Object.keys(modules).sort().map((k) => [k, modules[k]])),
};

await writeFile(join(CONTENT_DIR, "manifest.json"), JSON.stringify(out, null, 2) + "\n");
console.log(`✓ manifest.json — ${mods.length} modules`);
