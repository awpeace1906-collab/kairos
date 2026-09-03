// Assemble the publishable content bundle into tools/dist/ — the exact tree the
// clients fetch from CONTENT_BASE_URL. This is a static-file drop: no server, no
// API. rsync/upload dist/ to S3 / Cloudflare Pages / GitHub Pages, or let
// .github/workflows/content-deploy.yml publish it to GitHub Pages.
//
//   node deploy.mjs                 # validate, build, assemble dist/
//   node deploy.mjs --skip-validate # assemble only (CI already validated)
//   CONTENT_BASE_URL=https://… node deploy.mjs   # stamp the manifest hint
import { cp, rm, mkdir, writeFile, readdir, stat } from "node:fs/promises";
import { join } from "node:path";
import { ROOT, CONTENT_DIR } from "./lib/content.mjs";

const DIST = join(ROOT, "dist");
const skipValidate = process.argv.includes("--skip-validate");

if (!skipValidate) {
  await import("./validate.mjs");   // exits non-zero on failure
}
await import("./build.mjs");        // regenerate search-index.json + manifest.json

await rm(DIST, { recursive: true, force: true });
await mkdir(DIST, { recursive: true });

// The served subset — schemas are NOT shipped (clients don't validate at runtime).
for (const name of ["manifest.json", "search-index.json", "config", "modules"]) {
  await cp(join(CONTENT_DIR, name), join(DIST, name), { recursive: true });
}

// A tiny landing page so the bucket root isn't a 403/blank.
await writeFile(
  join(DIST, "index.html"),
  `<!doctype html><meta charset="utf-8"><title>Kairos content</title>
<body style="font-family:system-ui;max-width:40rem;margin:3rem auto;padding:0 1rem;color:#16212c">
<h1>Kairos content bundle</h1>
<p>Static, versioned clinical content for the Kairos app. Clients poll
<a href="./manifest.json">manifest.json</a> and fetch only changed modules.</p>
<p>Generated ${new Date().toISOString()}.</p>
</body>`
);

// Deploy metadata — handy for cache busting / rollback.
const files = await walkCount(DIST);
await writeFile(
  join(DIST, "_deploy.json"),
  JSON.stringify({ generatedAt: new Date().toISOString(), files, contentBaseUrl: process.env.CONTENT_BASE_URL || null }, null, 2) + "\n"
);

console.log(`\n✓ dist/ assembled — ${files} files`);
console.log(`  next: rsync/upload ./dist/ to your static host, or push to publish via GitHub Pages.`);
console.log(`  clients: set REMOTE_BASE (web) / remoteBase (iOS) to that URL.`);

async function walkCount(dir) {
  let n = 0;
  for (const e of await readdir(dir, { withFileTypes: true })) {
    const full = join(dir, e.name);
    if (e.isDirectory()) n += await walkCount(full);
    else if ((await stat(full)).isFile()) n++;
  }
  return n;
}
