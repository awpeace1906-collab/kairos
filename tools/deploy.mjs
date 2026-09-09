// Assemble the publishable bundle into tools/dist/ — the exact tree the host
// serves. It contains BOTH:
//   /            the PWA shell (web/ minus dev-only files)
//   /content/    the versioned content tree the clients fetch (manifest,
//                search-index, config, modules) — same layout the iOS app
//                polls at REMOTE_BASE.
// This is a static-file drop: no server, no API. rsync/upload dist/ anywhere,
// or let .github/workflows/deploy.yml publish it to GitHub Pages.
//
//   node deploy.mjs                 # validate, build, assemble dist/
//   node deploy.mjs --skip-validate # assemble only (CI already validated)
//   CONTENT_BASE_URL=https://… node deploy.mjs   # stamp the manifest hint
import { cp, rm, mkdir, writeFile, readdir, stat } from "node:fs/promises";
import { join } from "node:path";
import { ROOT, CONTENT_DIR } from "./lib/content.mjs";

const REPO_ROOT = join(ROOT, "..");
const WEB_DIR = join(REPO_ROOT, "web");
const DIST = join(ROOT, "dist");
const skipValidate = process.argv.includes("--skip-validate");

if (!skipValidate) {
  await import("./validate.mjs"); // exits non-zero on failure
}
await import("./build.mjs"); // regenerate search-index.json + manifest.json

await rm(DIST, { recursive: true, force: true });
await mkdir(join(DIST, "content"), { recursive: true });

// 1. the PWA shell — the static files web/ ships (skip dev server + package.json).
for (const name of ["index.html", "styles.css", "sw.js", "manifest.webmanifest", "src", "public"]) {
  await cp(join(WEB_DIR, name), join(DIST, name), { recursive: true });
}

// 2. the served content subset — schemas are NOT shipped (no runtime validation).
for (const name of ["manifest.json", "search-index.json", "sources-index.json", "config", "modules"]) {
  await cp(join(CONTENT_DIR, name), join(DIST, "content", name), { recursive: true });
}

// Deploy metadata — handy for cache busting / rollback.
const files = await walkCount(DIST);
await writeFile(
  join(DIST, "_deploy.json"),
  JSON.stringify(
    { generatedAt: new Date().toISOString(), files, contentBaseUrl: process.env.CONTENT_BASE_URL || null },
    null,
    2
  ) + "\n"
);

console.log(`\n✓ dist/ assembled — ${files} files (PWA shell + /content/)`);
console.log(`  publish: push to main (deploy.yml → GitHub Pages), or rsync ./dist/ to any static host.`);
console.log(`  iOS OTA: ContentStore.remoteBase = <site>/content/`);

async function walkCount(dir) {
  let n = 0;
  for (const e of await readdir(dir, { withFileTypes: true })) {
    const full = join(dir, e.name);
    if (e.isDirectory()) n += await walkCount(full);
    else if ((await stat(full)).isFile()) n++;
  }
  return n;
}
