// Schema-check every content module + config file, plus the pipeline invariants
// the build package calls out ("did you break the format, did you forget to bump
// content_version").
import Ajv from "ajv/dist/2020.js";
import { basename } from "node:path";
import {
  loadModules,
  loadConfig,
  loadAllSchemas,
  SCHEMA_FOR_TYPE,
} from "./lib/content.mjs";

const ajv = new Ajv({ allErrors: true, strict: false });
for (const [, schema] of await loadAllSchemas()) ajv.addSchema(schema);

const errors = [];
const warnings = [];
const fail = (where, msg) => errors.push(`✗ ${where}: ${msg}`);
const warn = (where, msg) => warnings.push(`! ${where}: ${msg}`);

function validateAgainst(schemaFile, data, where) {
  const validate = ajv.getSchema(`https://kairos.app/schema/${schemaFile}`);
  if (!validate) return fail(where, `no schema loaded for ${schemaFile}`);
  if (!validate(data)) {
    for (const e of validate.errors) fail(where, `${e.instancePath || "/"} ${e.message}`);
  }
}

// ---- config files ----------------------------------------------------------
validateAgainst("config.sections.schema.json", await loadConfig("sections.json"), "config/sections.json");
validateAgainst("config.weight-zones.schema.json", await loadConfig("weight-zones.json"), "config/weight-zones.json");
validateAgainst("config.tiers.schema.json", await loadConfig("tiers.json"), "config/tiers.json");

const sectionsCfg = await loadConfig("sections.json");
const knownCategories = new Set(
  sectionsCfg.sections.flatMap((s) => s.categories.map((c) => c.title))
);

// ---- modules --------------------------------------------------------------
const mods = await loadModules();
if (mods.length === 0) fail("content/modules", "no module JSON files found");

const seenIds = new Set();

for (const mod of mods) {
  const where = mod.relPath;
  const { json } = mod;

  const schemaFile = SCHEMA_FOR_TYPE[json.contentType];
  if (!schemaFile) {
    fail(where, `unknown contentType "${json.contentType}"`);
    continue;
  }

  // Decouple a peds-tool's embeddedCalculator: validate it on its own against the
  // calculator schema, then validate the wrapper without it. Nesting two
  // `unevaluatedProperties: false` schemas via $ref is an ajv performance cliff.
  if (json.contentType === "peds-tool" && json.embeddedCalculator) {
    validateAgainst("calculator.schema.json", json.embeddedCalculator, `${where} › embeddedCalculator`);
    const { embeddedCalculator, ...rest } = json;
    validateAgainst(schemaFile, rest, where);
  } else {
    validateAgainst(schemaFile, json, where);
  }

  // filename == id
  if (json.id && basename(mod.key) !== json.id) {
    fail(where, `id "${json.id}" does not match filename "${basename(mod.key)}.json"`);
  }

  // unique id
  if (json.id) {
    if (seenIds.has(json.id)) fail(where, `duplicate id "${json.id}"`);
    seenIds.add(json.id);
  }

  // section matches the directory it lives in
  if (mod.expectedSection && json.section !== mod.expectedSection) {
    fail(where, `section "${json.section}" but lives under modules/${mod.topDir}/ (expected "${mod.expectedSection}")`);
  }

  // category is one the sections config knows about
  if (json.category && !knownCategories.has(json.category)) {
    warn(where, `category "${json.category}" is not listed in config/sections.json`);
  }

  // content_version bump discipline
  if (Array.isArray(json.changelog) && json.changelog.length > 0) {
    const latest = Math.max(...json.changelog.map((c) => c.version));
    if (latest !== json.content_version) {
      fail(where, `content_version is ${json.content_version} but newest changelog entry is v${latest} — bump content_version (or add the changelog entry) before shipping`);
    }
  } else {
    warn(where, "no changelog[] — add one so 'why does this say X' has an answer");
  }

  // tiered content must carry review metadata (belt-and-suspenders over the schema)
  if (typeof json.review_tier === "number") {
    for (const f of ["last_reviewed", "next_review_due", "sources"]) {
      if (!json[f] || (Array.isArray(json[f]) && json[f].length === 0)) {
        fail(where, `review_tier ${json.review_tier} requires "${f}"`);
      }
    }
  }
  if (json.review_tier === undefined) {
    warn(where, "no review_tier — set one (1/2/3 or \"stable\") so the staleness tripwire knows what to do");
  }
}

// ---- report -------------------------------------------------------------
for (const w of warnings) console.warn(w);
console.log(`\nvalidate: ${mods.length} modules, ${errors.length} errors, ${warnings.length} warnings`);
if (errors.length) {
  console.error("\n" + errors.join("\n"));
  process.exit(1);
}
console.log("✓ all content valid");
