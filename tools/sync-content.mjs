// Copy the canonical content/ tree into the web client's served folder
// (web/content/, gitignored) so the PWA can fetch it in dev without a CDN.
// The iOS client bundles ../content directly via project.yml, so it needs no copy.
import { cp, rm, mkdir } from "node:fs/promises";
import { join } from "node:path";
import { ROOT, CONTENT_DIR } from "./lib/content.mjs";

const dest = join(ROOT, "..", "web", "content");
await rm(dest, { recursive: true, force: true });
await mkdir(dest, { recursive: true });
for (const name of ["schema", "config", "modules", "manifest.json", "search-index.json", "sources-index.json"]) {
  await cp(join(CONTENT_DIR, name), join(dest, name), { recursive: true }).catch((e) => {
    if (e.code !== "ENOENT") throw e;
    console.warn(`! skipped ${name} (not found — run 'npm run build' first)`);
  });
}
console.log(`✓ synced content -> web/content/`);
