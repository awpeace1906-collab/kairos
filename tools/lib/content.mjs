// Shared helpers for the Kairos content pipeline.
import { readdir, readFile } from "node:fs/promises";
import { createHash } from "node:crypto";
import { join, relative, sep } from "node:path";
import { fileURLToPath } from "node:url";

export const ROOT = fileURLToPath(new URL("..", import.meta.url));
export const CONTENT_DIR = join(ROOT, "..", "content");
export const MODULES_DIR = join(CONTENT_DIR, "modules");
export const SCHEMA_DIR = join(CONTENT_DIR, "schema");
export const CONFIG_DIR = join(CONTENT_DIR, "config");

// contentType -> schema filename
export const SCHEMA_FOR_TYPE = {
  calculator: "calculator.schema.json",
  procedure: "procedure.schema.json",
  "drug-card": "drug-card.schema.json",
  reference: "reference.schema.json",
  "peds-tool": "peds-tool.schema.json",
};

// top-level modules/ subdir -> the section title its records must declare
export const SECTION_FOR_DIR = {
  calculators: "Calculators",
  procedures: "Procedures",
  "drug-dosing": "Drug & Dosing Cards",
  "reference-library": "Reference Library",
  "peds-module": "Peds Module",
};

async function walk(dir) {
  const out = [];
  for (const entry of await readdir(dir, { withFileTypes: true })) {
    const full = join(dir, entry.name);
    if (entry.isDirectory()) out.push(...(await walk(full)));
    else if (entry.isFile() && entry.name.endsWith(".json")) out.push(full);
  }
  return out;
}

/** Every module JSON under content/modules, with its repo-relative key. */
export async function loadModules() {
  const files = (await walk(MODULES_DIR)).sort();
  const mods = [];
  for (const file of files) {
    const rel = relative(MODULES_DIR, file).split(sep).join("/");
    const topDir = rel.split("/")[0];
    const raw = await readFile(file, "utf8");
    let json;
    try {
      json = JSON.parse(raw);
    } catch (err) {
      throw new Error(`${rel}: invalid JSON — ${err.message}`);
    }
    mods.push({
      key: rel.replace(/\.json$/, ""),
      relPath: `modules/${rel}`,
      topDir,
      expectedSection: SECTION_FOR_DIR[topDir],
      json,
      raw,
    });
  }
  return mods;
}

export async function loadConfig(name) {
  return JSON.parse(await readFile(join(CONFIG_DIR, name), "utf8"));
}

export async function loadSchema(name) {
  return JSON.parse(await readFile(join(SCHEMA_DIR, name), "utf8"));
}

export async function loadAllSchemas() {
  const files = (await readdir(SCHEMA_DIR)).filter((f) => f.endsWith(".schema.json"));
  return Promise.all(files.map(async (f) => [f, await loadSchema(f)]));
}

/** Stable hash of a JSON value: sorted keys, first 16 hex chars of sha256. */
export function contentHash(value) {
  const canonical = JSON.stringify(sortKeys(value));
  return createHash("sha256").update(canonical).digest("hex").slice(0, 16);
}

function sortKeys(v) {
  if (Array.isArray(v)) return v.map(sortKeys);
  if (v && typeof v === "object") {
    return Object.fromEntries(
      Object.keys(v)
        .sort()
        .map((k) => [k, sortKeys(v[k])])
    );
  }
  return v;
}

export function routeFor(mod) {
  if (mod.json.route) return mod.json.route;
  const category = (mod.json.category || "misc")
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/(^-|-$)/g, "");
  return `/${mod.topDir}/${category}/${mod.json.id}`;
}

export const iso = (d = new Date()) => d.toISOString().slice(0, 10);
