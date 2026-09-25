// Regenerate content/manifest.json — the lightweight file both clients poll.
// Version numbers + hashes only, never the content itself.
import { writeFile, readFile } from "node:fs/promises";
import { join } from "node:path";
import { createHash } from "node:crypto";
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

// Binary assets (diagram background plates), listed so the service worker
// can precache them — otherwise a plate reaches the offline cache only after
// someone happens to view it online, which breaks offline-first on a fresh
// install. sha1 lets a client tell whether its copy is current.
//
// Only assets that some diagram REFERENCES are listed — not everything that
// happens to sit in content/assets/. Scanning the folder made the manifest
// depend on untracked files: a plate downloaded but not yet committed was
// listed locally, the committed manifest disagreed with CI's rebuild, and
// content-ci failed as "manifest.json is stale". Driving the list from the
// modules means the manifest can only change when a module does, and a
// referenced plate that is missing from the commit fails validate.mjs with an
// explicit "does not exist" instead.
async function listAssets(modules) {
  const refs = new Set();
  const walk = (v) => {
    if (Array.isArray(v)) return v.forEach(walk);
    if (!v || typeof v !== "object") return;
    if (v.image && typeof v.image.src === "string" && Array.isArray(v.shapes)) refs.add(v.image.src);
    Object.values(v).forEach(walk);
  };
  modules.forEach((m) => walk(m.json));
  const out = {};
  for (const src of [...refs].sort()) {
    try {
      const buf = await readFile(join(CONTENT_DIR, src));
      out[src] = { sha1: createHash("sha1").update(buf).digest("hex"), bytes: buf.length };
    } catch (e) {
      if (e.code !== "ENOENT") throw e;   // validate.mjs reports the missing file
    }
  }
  return out;
}
const assets = await listAssets(mods);

const out = {
  generatedAt: iso() + "T00:00:00Z",
  schemaVersion: 1,
  contentBaseHint: process.env.CONTENT_BASE_URL || "https://content.kairos.example/v1/",
  modules: Object.fromEntries(Object.keys(modules).sort().map((k) => [k, modules[k]])),
  assets,
};

await writeFile(join(CONTENT_DIR, "manifest.json"), JSON.stringify(out, null, 2) + "\n");
console.log(`✓ manifest.json — ${mods.length} modules, ${Object.keys(assets).length} assets`);
