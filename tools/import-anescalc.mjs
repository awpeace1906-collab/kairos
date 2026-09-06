// One-shot importer: /tmp/anescalc_json/*.json (produced by export_anescalc.swift
// from AnesCalc v2's DrugCard.swift) -> Kairos anesthesia-drug-card modules under
// content/modules/drug-dosing/anescalc-core/.
//
//   node import-anescalc.mjs [srcDir]
import { readdir, readFile, writeFile, mkdir, rm } from "node:fs/promises";
import { join } from "node:path";
import { CONTENT_DIR } from "./lib/content.mjs";

const SRC = process.argv[2] || "/tmp/anescalc_json";
const DEST = join(CONTENT_DIR, "modules", "drug-dosing", "anescalc-core");

// Drug-class -> Kairos menu category. These are Kairos's own perioperative
// categories (the "AnesCalc — " prefix was dropped and singletons merged
// 2026-09-04); keep in sync with content/config/sections.json.
const CATEGORY = {
  induction: "Induction & Sedation Agents",
  benzodiazepine: "Induction & Sedation Agents",
  volatile: "Volatile Anesthetics",
  nmb: "Neuromuscular Blockers",
  opioid: "Opioids",
  local: "Local Anesthetics",
  vasopressor: "Vasopressors & Inotropes",
  reversal: "Reversal & Anticholinergic Agents",
  anticholinergic: "Reversal & Anticholinergic Agents",
  antiemetic: "Antiemetics & Aspiration Prophylaxis",
  gi: "Antiemetics & Aspiration Prophylaxis",
  emergency: "Crisis / Rescue Drugs",
  "methylene-blue": "Crisis / Rescue Drugs",
  anticoagulant: "Anticoagulants & Hemostatics",
};

await rm(DEST, { recursive: true, force: true });
await mkdir(DEST, { recursive: true });

const files = (await readdir(SRC)).filter((f) => f.endsWith(".json") && f !== "_index.json");
let n = 0;
for (const f of files) {
  const src = JSON.parse(await readFile(join(SRC, f), "utf8"));
  const id = f.replace(/\.json$/, "");
  const cat = CATEGORY[src.category];
  if (!cat) throw new Error(`${id}: unknown drug class "${src.category}"`);

  const mod = {
    id,
    section: "Drug & Dosing Cards",
    category: cat,
    title: src.name,
    ...(src.brandName ? { aliases: [src.brandName] } : {}),
    tags: dedupe(["anesthesia", "perioperative", src.category, ...(src.name.toLowerCase().split(/[^a-z0-9]+/).filter(Boolean))]),
    contentType: "anesthesia-drug-card",
    content_version: 1,
    last_reviewed: "2026-09-01",
    next_review_due: "2026-12-01",
    review_tier: 1,
    sources: ["AnesCalc v2 drug library (DrugCard.swift), imported 2026-09-01"],
    changelog: [
      { version: 1, date: "2026-09-01", change: "Imported from AnesCalc v2 DrugCard.swift via tools/import-anescalc.mjs." },
    ],
    ...(src.brandName ? { brandName: src.brandName } : {}),
    ...(src.tallManLetters ? { tallManLetters: src.tallManLetters } : {}),
    drugClass: src.category,
    drugClassLabel: src.categoryLabel,
    mechanism: src.mechanism,
    onset: src.onset,
    duration: src.duration,
    dosing: src.dosing,
    cautions: src.cautions,
    pearls: src.pearls,
    ...(src.reversal ? { reversal: src.reversal } : {}),
  };

  await writeFile(join(DEST, `${id}.json`), JSON.stringify(mod, null, 2) + "\n");
  n++;
}
console.log(`✓ imported ${n} AnesCalc drug cards -> ${DEST}`);

function dedupe(a) {
  return [...new Set(a.map((s) => String(s).trim()).filter((s) => s.length > 1))];
}
