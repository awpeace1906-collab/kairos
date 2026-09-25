// Regenerate content/manifest.json — the lightweight file both clients poll.
// Version numbers + hashes only, never the content itself.
import { writeFile, readdir, readFile } from "node:fs/promises";
import { join, relative } from "node:path";
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

// Binary assets (diagram background plates) under content/assets/. Listed so
// the service worker can precache them — without this a plate only reaches
// the offline cache after someone happens to view it online, which breaks the
// offline-first guarantee on a fresh install. sha1 lets a client tell whether
// its copy is current without downloading it.
async function listAssets(dir) {
  const out = {};
  const walk = async (d) => {
    let entries;
    try {
      entries = await readdir(d, { withFileTypes: true });
    } catch (e) {
      if (e.code === "ENOENT") return;
      throw e;
    }
    for (const e of entries) {
      const full = join(d, e.name);
      if (e.isDirectory()) await walk(full);
      else if (/\.(png|jpe?g|webp)$/i.test(e.name)) {
        const buf = await readFile(full);
        out[relative(CONTENT_DIR, full).split("\\").join("/")] = {
          sha1: createHash("sha1").update(buf).digest("hex"),
          bytes: buf.length,
        };
      }
    }
  };
  await walk(dir);
  return Object.fromEntries(Object.keys(out).sort().map((k) => [k, out[k]]));
}
const assets = await listAssets(join(CONTENT_DIR, "assets"));

const out = {
  generatedAt: iso() + "T00:00:00Z",
  schemaVersion: 1,
  contentBaseHint: process.env.CONTENT_BASE_URL || "https://content.kairos.example/v1/",
  modules: Object.fromEntries(Object.keys(modules).sort().map((k) => [k, modules[k]])),
  assets,
};

await writeFile(join(CONTENT_DIR, "manifest.json"), JSON.stringify(out, null, 2) + "\n");
console.log(`✓ manifest.json — ${mods.length} modules, ${Object.keys(assets).length} assets`);
