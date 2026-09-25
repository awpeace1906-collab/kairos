// Regression tests for the shared engine logic + a sanity pass over real content.
// Zero-dependency runner. Imports the ACTUAL shipped web modules so a change to
// engine behaviour OR to a tested content module is caught here.
//
//   cd tools && npm test
import { evaluate } from "../web/src/lib/expr.js";
import { runCalculator } from "../web/src/lib/calcEngine.js";
import { zoneForWeight, estimateWeight, doseFromRule } from "../web/src/lib/weightZones.js";
import { makeSearch } from "../web/src/lib/search.js";
import { parseRichText, isStructured, leadLabel, tableColumnWeights, shouldStackTable } from "../web/src/lib/richText.js";
import { loadModules, loadConfig } from "./lib/content.mjs";

let pass = 0;
let fail = 0;
const failures = [];

function ok(name, cond, detail = "") {
  if (cond) { pass++; }
  else { fail++; failures.push(`✗ ${name}${detail ? " — " + detail : ""}`); }
}
function eq(name, actual, expected) {
  ok(name, Object.is(actual, expected) || actual === expected, `got ${JSON.stringify(actual)}, expected ${JSON.stringify(expected)}`);
}
function near(name, actual, expected, tol = 1e-6) {
  ok(name, Math.abs(actual - expected) <= tol, `got ${actual}, expected ${expected} ±${tol}`);
}
function throws(name, fn) {
  try { fn(); ok(name, false, "expected a throw"); }
  catch { ok(name, true); }
}

// ---------------------------------------------------------------- expr.js
near("expr: precedence 2+3*4", evaluate("2+3*4", {}), 14);
near("expr: parens (2+3)*4", evaluate("(2+3)*4", {}), 20);
near("expr: pow right-assoc 2^3^2", evaluate("2^3^2", {}), 512);
near("expr: negative exponent 150*2^(-(8-4)/4)", evaluate("150 * 2 ^ (-(8-4)/4)", {}), 75);
near("expr: cbrt(27)", evaluate("cbrt(27)", {}), 3);
near("expr: sqrt(qt/... ) style", evaluate("qt / sqrt(60/hr)", { qt: 400, hr: 80 }), 400 / Math.sqrt(0.75));
near("expr: min(3,5,1)", evaluate("min(3,5,1)", {}), 1);
near("expr: unary minus", evaluate("-5 + 3", {}), -2);
near("expr: Holliday-Segar piecewise @ 25kg",
  evaluate("4 * min(weight, 10) + 2 * max(0, min(weight - 10, 10)) + 1 * max(0, weight - 20)", { weight: 25 }), 65);
throws("expr: unknown variable throws", () => evaluate("foo + 1", {}));
throws("expr: unknown function throws", () => evaluate("frobnicate(2)", {}));
throws("expr: trailing garbage throws", () => evaluate("2 + + ", {}));

// ---------------------------------------------------------------- weightZones.js
const zones = await loadConfig("weight-zones.json");
eq("zone: 14.3 kg → gap snaps to lower zone (Violet/4)", zoneForWeight(zones, 14.3)?.zone, 4);
eq("zone: 2 kg → clamps to first zone", zoneForWeight(zones, 2)?.zone, 1);
eq("zone: 100 kg → clamps to last zone", zoneForWeight(zones, 100)?.zone, zones.zones[zones.zones.length - 1].zone);
eq("zone: exact boundary 15 kg → Amber/5", zoneForWeight(zones, 15)?.zone, 5);
eq("zone: NaN weight → null", zoneForWeight(zones, NaN), null);

const est = estimateWeight(zones, { ageYears: 2 });
near("estimateWeight: 2 y → (2×2)+8 = 12 kg", est.weightKg, 12);
ok("estimateWeight: flagged estimated", est.estimated === true);

const epiRule = { perKg: 0.01, unit: "mg", maxDose: 1, concentration: "0.1 mg/mL", mlPerUnit: 10 };
const epi = doseFromRule(epiRule, 14.3);
near("dose: epi 0.01 mg/kg × 14.3 kg", epi.amount, 0.143);
near("dose: epi volume = 1.43 mL", epi.volumeMl, 1.43);
ok("dose: epi not capped at 14.3 kg", epi.capped === false);
near("dose: epi capped at 1 mg for 200 kg", doseFromRule(epiRule, 200).amount, 1);
ok("dose: epi flagged capped at 200 kg", doseFromRule(epiRule, 200).capped === true);

const atropineRule = { perKg: 0.02, unit: "mg", minDose: 0.1, maxDose: 0.5 };
near("dose: atropine floored to 0.1 mg at 3 kg", doseFromRule(atropineRule, 3).amount, 0.1);
ok("dose: atropine flagged floored at 3 kg", doseFromRule(atropineRule, 3).floored === true);
near("dose: atropine capped at 0.5 mg at 30 kg", doseFromRule(atropineRule, 30).amount, 0.5);

const rangeRule = { perKg: 0.1, perKgHigh: 0.2, unit: "mg", maxDose: 10 };
const rng = doseFromRule(rangeRule, 20);
near("dose: range low 0.1 mg/kg × 20", rng.amount, 2);
near("dose: range high 0.2 mg/kg × 20", rng.amountHigh, 4);

// ---------------------------------------------------------------- calcEngine.js (against real content)
const mods = await loadModules();
const byId = Object.fromEntries(mods.map((m) => [m.json.id, m.json]));

const heart = byId["heart-score"];
ok("content: heart-score present", !!heart);
const heartMax = runCalculator(heart, { items: Object.fromEntries(heart.items.map((i) => [i.key, i.options.length - 1])) });
eq("HEART: all-max score = 10", heartMax.score, 10);
eq("HEART: all-max band = High risk", heartMax.bands[0]?.label, "High risk");
const heartPartial = runCalculator(heart, { items: { history: 0 } });
ok("HEART: partial → incomplete", heartPartial.incomplete === true);
const heartZero = runCalculator(heart, { items: Object.fromEntries(heart.items.map((i) => [i.key, 0])) });
eq("HEART: all-zero score = 0", heartZero.score, 0);
eq("HEART: all-zero band = Low risk", heartZero.bands[0]?.label, "Low risk");

const wellsDvt = byId["wells-dvt"];
if (wellsDvt) {
  // 3 positive 1-pointers + alternative-dx (−2) = 1 → Moderate band
  const st = { items: {} };
  wellsDvt.items.forEach((it, i) => { st.items[it.key] = i < 3 ? 1 : 0; });
  const altIdx = wellsDvt.items.findIndex((it) => it.key === "altDx");
  st.items[wellsDvt.items[altIdx].key] = 1; // the −2 option
  const r = runCalculator(wellsDvt, st);
  eq("Wells DVT: 3×(+1) + (−2) = 1", r.score, 1);
  ok("Wells DVT: score 1 → Moderate band", /^Moderate probability/.test(r.bands[0]?.label || ""), `got "${r.bands[0]?.label}"`);
}

const qtc = byId["qtc"];
const qr = runCalculator(qtc, { inputs: { qt: "400", hr: "80" } });
const bazett = qr.results.find((x) => x.key === "bazett");
const frid = qr.results.find((x) => x.key === "fridericia");
eq("QTc: Bazett(400,80) rounds to 462", bazett.value, 462);
eq("QTc: Fridericia(400,80) rounds to 440", frid.value, 440);
ok("QTc: Bazett 462 lands in the prolonged (450-499) band", (qr.bandsByKey["bazett"] || []).some((b) => b.min === 450 && b.max === 499));

const msi = byId["modified-shock-index"];
if (msi) {
  const r = runCalculator(msi, { inputs: { hr: "120", sbp: "90", dbp: "60" } });
  eq("MSI: MAP(90/60) → 70 mmHg", r.results.find((x) => x.key === "map").value, 70);
  eq("MSI: 120 / 70 → 1.71", r.results.find((x) => x.key === "msi").value, 1.71);
  ok("MSI: 1.71 lands in the ≥1.7 high-risk band",
    (r.bandsByKey["msi"] || []).some((b) => b.min === 1.7 && /high risk/i.test(b.label)));
}

const hs = byId["holliday-segar-maintenance-fluids"];
if (hs) {
  const r8 = runCalculator(hs, { inputs: { weight: "8" } });
  const r15 = runCalculator(hs, { inputs: { weight: "15" } });
  eq("Holliday-Segar: 8 kg → 32 mL/h", r8.results.find((x) => x.key === "rate").value, 32);
  eq("Holliday-Segar: 15 kg → 50 mL/h", r15.results.find((x) => x.key === "rate").value, 50);
}

const grace = byId["grace-acs"];
if (grace) {
  const r = runCalculator(grace, {});
  eq("GRACE: engine=external is flagged incomplete", r.incomplete, true);
}

// ---------------------------------------------------------------- search.js
const searchEntries = [
  { id: "a", title: "HEART Score", section: "Calculators", category: "Cardiovascular", tags: ["chest pain"], keywords: [] },
  { id: "b", title: "Glasgow-Blatchford", section: "Calculators", category: "GI", tags: [], keywords: ["gbs"] },
  { id: "c", title: "Wells PE", section: "Calculators", category: "Pulmonary", tags: ["chest pain"], keywords: [] },
];
const search = makeSearch(searchEntries);
eq("search: exact title ranks first", search("heart score")[0].id, "a");
eq("search: keyword 'gbs' finds Glasgow-Blatchford", search("gbs")[0].id, "b");
eq("search: tag 'chest pain' returns 2", search("chest pain").length, 2);
eq("search: no query → empty", search("").length, 0);
eq("search: section filter", search("chest pain", { section: "Calculators" }).length, 2);

// ---------------------------------------------------------------- content sanity
for (const m of mods) {
  const j = m.json;
  if (j.contentType === "calculator" && j.engine === "additive") {
    const bad = (j.items || []).find((it) => !it.options || it.options.length < 2);
    ok(`content: ${j.id} additive items have ≥2 options`, !bad, bad ? `item ${bad?.key}` : "");
    // every interpretation band with a min should have a >= min max (or none)
    const badBand = (j.interpretation || []).find((b) => b.min != null && b.max != null && b.max < b.min);
    ok(`content: ${j.id} interpretation bands are ordered`, !badBand);
  }
  if (j.contentType === "calculator" && j.engine === "formula") {
    for (const f of j.formulas || []) {
      // every variable in the expression must be a declared input key or a known fn
      const ids = [...f.expression.matchAll(/[a-zA-Z_]\w*/g)].map((x) => x[0]);
      const inputKeys = new Set((j.inputs || []).map((i) => i.key));
      const fns = new Set(["sqrt", "cbrt", "abs", "ln", "log10", "exp", "min", "max", "round", "floor", "ceil"]);
      const undef = ids.find((id) => !inputKeys.has(id) && !fns.has(id));
      ok(`content: ${j.id} formula "${f.key}" vars all declared`, !undef, undef ? `unknown "${undef}"` : "");
    }
  }
}

// ------------------------------------------------- nested lists (listItem)
// The structure is backward-compatible by design: a plain string is a leaf,
// so every list authored before nesting existed must still be valid. These
// assertions guard both halves of that promise.
{
  const listDepth = (items) =>
    1 +
    Math.max(
      0,
      ...items.map((it) =>
        it && typeof it === "object" && Array.isArray(it.items)
          ? listDepth(it.items)
          : 0,
      ),
    );

  let flatLists = 0;
  let nestedLists = 0;
  let deepest = 0;
  let badItem = null;
  let badSubsteps = null;

  const visitItems = (items, id) => {
    const depth = listDepth(items);
    deepest = Math.max(deepest, depth);
    if (depth > 1) nestedLists += 1;
    else flatLists += 1;
    for (const it of items) {
      if (typeof it === "string") continue;
      if (!it || typeof it !== "object" || typeof it.text !== "string" || !it.text) {
        badItem = `${id}: list entry is neither a string nor { text }`;
      } else if (it.items !== undefined) {
        if (!Array.isArray(it.items) || it.items.length === 0) {
          badItem = `${id}: "${it.text.slice(0, 30)}" has an empty items[]`;
        } else {
          visitItems(it.items, id);
        }
      }
    }
  };

  for (const m of mods) {
    const j = m.json;
    for (const b of j.body || []) {
      if (b.type === "list") visitItems(b.items || [], j.id);
    }
    for (const n of j.nodes || []) {
      if (!n.substeps) continue;
      if (!Array.isArray(n.substeps.items) || n.substeps.items.length === 0) {
        badSubsteps = `${j.id}/${n.id}`;
      } else {
        visitItems(n.substeps.items, `${j.id}/${n.id}`);
      }
    }
  }

  ok("lists: every entry is a string or { text }", !badItem, badItem ?? "");
  ok("lists: no substeps with an empty items[]", !badSubsteps, badSubsteps ?? "");
  ok("lists: flat string lists still present (backward compatible)", flatLists > 0, `${flatLists} flat`);
  ok("lists: nesting is in use", nestedLists > 0, `${nestedLists} nested`);
  ok(
    `lists: nesting stays within the 3-level cap (deepest ${deepest})`,
    deepest <= 3,
    `deepest ${deepest}`,
  );
}

// ------------------------------------------------- text format (richText.js)
{
  const plain = parseRichText("One plain sentence.");
  eq("rich: plain text is one paragraph", plain.length, 1);
  eq("rich: plain text is not structured", isStructured("One plain sentence."), false);

  const b = parseRichText("Intro line.\n\nSecond para\nwith a break.\n- first\n- second\n  - nested\n\n1. step one\n2. step two");
  eq("rich: block count", b.length, 4);
  eq("rich: paragraph 2 keeps its line break", b[1].lines.length, 2);
  eq("rich: bullets are unordered", b[2].ordered, false);
  eq("rich: bullet count", b[2].items.length, 2);
  eq("rich: two-space indent nests", b[2].items[1].items[0].text, "nested");
  eq("rich: numbered list is ordered", b[3].ordered, true);
  eq("rich: numbered text drops its number", b[3].items[1].text, "step two");

  const cont = parseRichText("- a long item\n  that wraps on\n- next");
  eq("rich: indented plain line continues the item", cont[0].items[0].text, "a long item that wraps on");
  eq("rich: decimals are not list markers", parseRichText("2.5 mg/kg IV").length === 1 && parseRichText("2.5 mg/kg IV")[0].type, "p");
  eq("rich: CRLF normalized", parseRichText("a\r\n\r\nb").length, 2);

  eq("rich: ALL-CAPS lead label", JSON.stringify(leadLabel("LEVEL: posterior axillary line")), JSON.stringify(["LEVEL:", "posterior axillary line"]));
  eq("rich: a label alone on its line is a sub-header", JSON.stringify(leadLabel("POSITION:")), JSON.stringify(["POSITION:", ""]));
  eq("rich: sentence colon is not a label", leadLabel("Note the ratio: 2 to 1"), null);
  eq("rich: single capital is not a label", leadLabel("A: something"), null);

  const w = tableColumnWeights(["Agent", "Dose", "Notes"], [["Ketamine", "1-2 mg/kg", "Maintains airway reflexes and respiratory drive in most patients"]]);
  near("table: weights sum to 1", w.reduce((a, x) => a + x, 0), 1);
  ok("table: wordier column is wider", w[2] > w[1] && w[2] > w[0]);
  ok("table: no column far below an even share", Math.min(...w) >= 0.55 / 3);
  const t = tableColumnWeights(["Etiology", "Recognition and treatment"], [["Tension pneumothorax", "Mediastinal shift impairs venous return. Absent breath sounds, tracheal deviation, distended neck veins."]]);
  eq("table: three columns stack on a phone", shouldStackTable(["a", "b", "c"], [["1", "2", "3"]]), true);
  eq("table: short two-column table stays a table", shouldStackTable(["Drug", "Dose"], [["Ketamine", "1-2 mg/kg"]]), false);
  eq("table: label + paragraph table stacks", shouldStackTable(["Etiology", "Recognition"], [["Tension pneumothorax", "Mediastinal shift impairs venous return. Absent breath sounds, tracheal deviation."]]), true);
  ok("table: a column is at least as wide as its longest word", t[0] >= 0.4, `got ${t[0].toFixed(3)}`);
}

// ---------------------------------------------------------------- report
console.log(failures.join("\n"));
console.log(`\ntest: ${pass} passed, ${fail} failed`);
process.exit(fail ? 1 : 0);
