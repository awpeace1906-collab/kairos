#!/usr/bin/env node
/**
 * American-English guard for the whole repo.
 *
 *   node check-spelling.mjs           # report and exit 1 if anything is found
 *   node check-spelling.mjs --fix     # rewrite in place, then report
 *   node check-spelling.mjs --spelling-only   # skip the INN drug-name rules
 *
 * Runs in `npm run ci`, so a British spelling in newly authored prose fails
 * the build instead of shipping. The 2026-09-16 one-off normalization pass
 * did not survive first contact with new content; this is the version that
 * does not need a human to remember it.
 *
 * Editing is LINE-BASED rather than parse-and-reserialize, for two reasons:
 * a JSON round-trip through JSON.stringify would reformat all 431 content
 * files, burying the real edit in noise; and the same code path then works
 * for .js, .swift and .md.
 *
 * Skipped by design:
 *   - `sources`, `changelog`, `buildNote` regions in content JSON. Journal
 *     and society names legitimately carry British spellings and
 *     "correcting" a citation makes it unfindable.
 *   - Generated files (search-index, manifest, sources-index) — they are
 *     derived, so a hit there is either a duplicate of a module hit or an
 *     expected citation.
 *   - Citation-shaped lines anywhere (an "et al", a "doi:", or a
 *     "2019;140(2):" style locator).
 */

import { readFileSync, writeFileSync, readdirSync, statSync } from "node:fs";
import { join, relative, extname, basename } from "node:path";
import { fileURLToPath } from "node:url";
import { findIssues, fixText } from "./spelling.mjs";

const ROOT = join(fileURLToPath(new URL(".", import.meta.url)), "..");

const FIX = process.argv.includes("--fix");
const CATEGORIES = process.argv.includes("--spelling-only")
  ? ["spelling"]
  : ["spelling", "drug-name"];

/** Trees to sweep, and which extensions matter in each. */
const TARGETS = [
  { dir: "content", exts: [".json"] },
  { dir: "web/src", exts: [".js"] },
  { dir: "web", exts: [".html", ".css"], shallow: true },
  { dir: "ios/Sources", exts: [".swift"] },
  { dir: "docs", exts: [".md"] },
];
const EXTRA_FILES = ["README.md"];

/** Derived artifacts — a hit here is a duplicate or an expected citation. */
const GENERATED = new Set([
  "search-index.json",
  "manifest.json",
  "sources-index.json",
]);

const SKIP_DIRS = new Set([
  "node_modules",
  ".git",
  "dist",
  "planning-archive",
]);

/** Keys whose values are citations or maintainer notes, not clinical prose. */
const SKIP_KEYS = ["sources", "changelog", "buildNote"];

/**
 * Keys that hold SEARCH SYNONYMS, not prose. A British spelling or an INN
 * drug name here is a feature: a clinician who types "paracetamol",
 * "adrenaline" or "haemodynamics" should still find the module. These are
 * reported separately and never rewritten — blind-fixing them silently
 * deletes the synonym that makes the module findable.
 */
const SYNONYM_KEYS = ["aliases", "keywords", "tags"];

/** A line that is plainly a bibliographic reference. */
const CITATION_LINE =
  /\bet al\b|\bdoi:|https?:\/\/|\b(19|20)\d{2};\s*\d|\b(19|20)\d{2}\s*\(\s*(Suppl|\d)|PMID|ISBN/i;

function walk(dir, exts, shallow, out) {
  let entries;
  try {
    entries = readdirSync(dir);
  } catch {
    return;
  }
  for (const name of entries) {
    if (SKIP_DIRS.has(name)) continue;
    const full = join(dir, name);
    const st = statSync(full);
    if (st.isDirectory()) {
      if (!shallow) walk(full, exts, false, out);
    } else if (exts.includes(extname(name)) && !GENERATED.has(basename(name))) {
      out.push(full);
    }
  }
}

function collectFiles() {
  const out = [];
  for (const t of TARGETS) walk(join(ROOT, t.dir), t.exts, t.shallow, out);
  for (const f of EXTRA_FILES) {
    const full = join(ROOT, f);
    try {
      if (statSync(full).isFile()) out.push(full);
    } catch {
      /* optional */
    }
  }
  return [...new Set(out)].sort();
}

/** Net change in bracket/brace depth on a line, ignoring string contents. */
function depthDelta(line) {
  let d = 0;
  let inStr = false;
  for (let i = 0; i < line.length; i += 1) {
    const ch = line[i];
    if (inStr) {
      if (ch === "\\") i += 1;
      else if (ch === '"') inStr = false;
    } else if (ch === '"') inStr = true;
    else if (ch === "[" || ch === "{") d += 1;
    else if (ch === "]" || ch === "}") d -= 1;
  }
  return d;
}

/**
 * Lines to leave alone in a JSON file: anything inside a `sources`,
 * `changelog` or `buildNote` value, whether that value is written on one
 * line or spread over many.
 */
function jsonSkipLines(lines, keys) {
  const skip = new Set();
  let depth = null;
  for (let i = 0; i < lines.length; i += 1) {
    const line = lines[i];
    if (depth !== null) {
      skip.add(i);
      depth += depthDelta(line);
      if (depth <= 0) depth = null;
      continue;
    }
    const key = keys.find((k) => line.includes(`"${k}"`));
    if (!key) continue;
    skip.add(i);
    const d = depthDelta(line);
    if (d > 0) depth = d;
  }
  return skip;
}

/** The whole word a match sits in — a bare "aem -> em" tells you nothing. */
function wordAround(line, issue) {
  let a = issue.index;
  let b = issue.index + issue.match.length;
  while (a > 0 && /[A-Za-z-]/.test(line[a - 1])) a -= 1;
  while (b < line.length && /[A-Za-z-]/.test(line[b])) b += 1;
  return line.slice(a, b);
}

const results = [];
const synonymResults = [];
let fixedFiles = 0;
let totalIssues = 0;

for (const file of collectFiles()) {
  const raw = readFileSync(file, "utf8");
  const lines = raw.split("\n");
  const isJson = extname(file) === ".json";
  const skip = isJson ? jsonSkipLines(lines, SKIP_KEYS) : new Set();
  const synonym = isJson ? jsonSkipLines(lines, SYNONYM_KEYS) : new Set();

  const hits = [];
  const synonymHits = [];
  const nextLines = lines.slice();

  for (let i = 0; i < lines.length; i += 1) {
    if (skip.has(i)) continue;
    const line = lines[i];
    if (CITATION_LINE.test(line)) continue;
    const issues = findIssues(line, { categories: CATEGORIES });
    if (!issues.length) continue;
    const target = synonym.has(i) ? synonymHits : hits;
    for (const issue of issues) {
      target.push({ line: i + 1, word: wordAround(line, issue), ...issue });
    }
    if (FIX && !synonym.has(i)) {
      nextLines[i] = fixText(line, { categories: CATEGORIES });
    }
  }

  if (synonymHits.length) {
    synonymResults.push({ file: relative(ROOT, file), hits: synonymHits });
  }
  if (!hits.length) continue;
  totalIssues += hits.length;
  results.push({ file: relative(ROOT, file), hits });

  if (FIX) {
    const next = nextLines.join("\n");
    if (next !== raw) {
      writeFileSync(file, next);
      fixedFiles += 1;
    }
  }
}

function reportSynonyms() {
  if (!synonymResults.length) return;
  const n = synonymResults.reduce((a, r) => a + r.hits.length, 0);
  console.log(
    `\nLeft alone on purpose — ${n} in search-synonym fields (aliases/keywords/tags),`,
  );
  console.log("where a British spelling or INN name is what makes the module findable:");
  for (const r of synonymResults) {
    const words = [...new Set(r.hits.map((h) => h.word))].join(", ");
    console.log(`  ${r.file}: ${words}`);
  }
}

if (!results.length) {
  console.log("check-spelling: clean — no British spellings or INN drug names");
  reportSynonyms();
  process.exit(0);
}

const byCategory = new Map();
for (const r of results) {
  for (const h of r.hits) {
    byCategory.set(h.category, (byCategory.get(h.category) ?? 0) + 1);
  }
}

for (const r of results) {
  console.log(`\n${r.file}`);
  for (const h of r.hits) {
    const tag = h.category === "drug-name" ? "  (drug name)" : "";
    console.log(`  :${h.line}  ${h.word} -> ${fixText(h.word, { categories: CATEGORIES })}${tag}`);
  }
}

const summary = [...byCategory.entries()]
  .map(([c, n]) => `${n} ${c}`)
  .join(", ");

if (FIX) {
  console.log(`\ncheck-spelling: fixed ${totalIssues} (${summary}) in ${fixedFiles} files`);
  reportSynonyms();
  process.exit(0);
}

console.log(
  `\ncheck-spelling: ${totalIssues} issue(s) (${summary}) in ${results.length} file(s).`,
);
console.log("Run 'npm run check-spelling -- --fix' to rewrite them.");
reportSynonyms();
process.exit(1);
