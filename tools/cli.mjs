#!/usr/bin/env node
// Thin dispatcher so the pipeline is one command in CI and locally.
const cmd = process.argv[2];
const map = {
  validate: "./validate.mjs",
  build: "./build.mjs",
  "search-index": "./build-search-index.mjs",
  manifest: "./build-manifest.mjs",
  "check-staleness": "./check-staleness.mjs",
  sync: "./sync-content.mjs",
};
if (cmd === "ci") {
  for (const step of ["./validate.mjs", "./build.mjs", "./check-staleness.mjs"]) {
    await import(step);
  }
} else if (map[cmd]) {
  await import(map[cmd]);
} else {
  console.log(`usage: kairos-content <${Object.keys(map).join(" | ")} | ci>`);
  process.exit(cmd ? 1 : 0);
}
