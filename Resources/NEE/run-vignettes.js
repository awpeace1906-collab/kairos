// Runs nee-vignettes.json against nee-engine-reference.js.
// Usage: node run-vignettes.js   (from this folder)
"use strict";
const fs = require("fs");
const path = require("path");
const { computeNEE } = require("./nee-engine-reference.js");

const logic = JSON.parse(fs.readFileSync(path.join(__dirname, "nee-logic.json"), "utf8"));
const suite = JSON.parse(fs.readFileSync(path.join(__dirname, "nee-vignettes.json"), "utf8"));
if (suite.logic_version !== logic.logic_version) {
  console.error(`Version mismatch: vignettes ${suite.logic_version} vs logic ${logic.logic_version}`);
  process.exit(1);
}
const tol = suite.tolerance;
const sameCodes = (a, b) => JSON.stringify([...a].sort()) === JSON.stringify([...b].sort());
const close = (a, b) => (a === null || b === null ? a === b : Math.abs(a - b) <= tol);

let pass = 0;
for (const v of suite.vignettes) {
  const r = computeNEE(logic, v.input);
  const e = v.expect;
  const fails = [];
  if (r.status !== e.status) fails.push(`status ${r.status} != ${e.status}`);
  if (e.status === "ok") {
    if (!close(r.nee_mcg_kg_min, e.nee_mcg_kg_min)) fails.push(`nee_mcg_kg_min ${r.nee_mcg_kg_min} != ${e.nee_mcg_kg_min}`);
    if (!close(r.nee_mcg_min, e.nee_mcg_min)) fails.push(`nee_mcg_min ${r.nee_mcg_min} != ${e.nee_mcg_min}`);
    if (!close(r.adjunct_mcg_kg_min, e.adjunct_mcg_kg_min)) fails.push(`adjunct_mcg_kg_min ${r.adjunct_mcg_kg_min} != ${e.adjunct_mcg_kg_min}`);
    if (!sameCodes(r.warnings.map((w) => w.code), e.warnings)) fails.push(`warnings ${JSON.stringify(r.warnings.map((w) => w.code))}`);
    if (!sameCodes(r.info.map((i) => i.code), e.info)) fails.push(`info ${JSON.stringify(r.info.map((i) => i.code))}`);
    if (e.formula && r.formula !== e.formula) fails.push(`formula ${r.formula} != ${e.formula}`);
  } else {
    if (!sameCodes(r.errors.map((x) => x.code), e.errors)) fails.push(`errors ${JSON.stringify(r.errors.map((x) => x.code))}`);
  }
  if (fails.length) console.log(`FAIL ${v.id} ${v.title}\n   ${fails.join("\n   ")}`);
  else { pass++; console.log(`pass ${v.id} ${v.title}`); }
}
console.log(`\n${pass}/${suite.vignettes.length} vignettes passed`);
process.exit(pass === suite.vignettes.length ? 0 : 1);
