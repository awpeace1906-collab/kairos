// nee-engine-reference.js
// Reference implementation of the NEE calculator. Pure function, no UI, no storage.
// All clinical numbers come from nee-logic.json. This file must not contain any
// conversion factor, threshold, or clinical wording of its own.
//
// Usage: computeNEE(logic, input)
//   input = {
//     formulaId: "kotani_2023",          // optional; defaults to the formula with default=true
//     weightKg: 80,                      // optional unless a per_weight unit is used
//     neSalt: "base",                    // optional; defaults to logic.norepinephrine_salt.default
//     infusions: [ { agent: "norepinephrine", dose: 0.1, unit: "mcg/kg/min" }, ... ]
//   }
//
// Returns {
//   status: "ok" | "error",
//   formula: <formula id>,
//   errors:   [ { code, agent?, unit?, text } ],
//   warnings: [ { code, agent, text } ],
//   info:     [ { code, text } ],          // dynamic notes (no_inputs, ssc_vasopressin)
//   nee_mcg_kg_min: number | null,         // unrounded
//   nee_mcg_min: number | null,            // unrounded; null when no weight
//   adjunct_mcg_kg_min: number | null,     // adjunct estimate, NOT included in NEE; null when none
//   breakdown: [ { agent, dose_entered, unit_entered, dose_canonical, canonical_unit,
//                  factor, contribution, counted, adjunct } ]
// }

"use strict";

function frac(f) {
  return f.num / f.den;
}

function fill(template, vars) {
  return template.replace(/\{(\w+)\}/g, (_, k) => (k in vars ? String(vars[k]) : `{${k}}`));
}

function computeNEE(logic, input) {
  const errors = [];
  const warnings = [];
  const info = [];
  const msg = logic.messages;

  const formula =
    logic.formulas.find((f) => f.id === input.formulaId) ||
    logic.formulas.find((f) => f.default);
  const agentsById = Object.fromEntries(logic.agents.map((a) => [a.id, a]));
  const saltId = input.neSalt || logic.norepinephrine_salt.default;
  const salt = logic.norepinephrine_salt.options.find((o) => o.id === saltId);

  const weight = input.weightKg;
  const weightGiven = weight !== undefined && weight !== null;
  if (weightGiven) {
    const w = logic.weight;
    if (typeof weight !== "number" || !isFinite(weight) || weight < w.min_inclusive || weight > w.max_inclusive) {
      errors.push({ code: "weight_out_of_range", text: msg.error_weight_out_of_range });
    }
  }

  const seen = new Set();
  const rows = [];
  for (const inf of input.infusions || []) {
    const agent = agentsById[inf.agent];
    const label = agent ? agent.label : inf.agent;
    if (seen.has(inf.agent)) {
      errors.push({ code: "duplicate_agent", agent: inf.agent, text: fill(msg.error_duplicate_agent, { agent: label }) });
      continue;
    }
    seen.add(inf.agent);
    if (typeof inf.dose !== "number" || !isFinite(inf.dose)) {
      errors.push({ code: "non_numeric_dose", agent: inf.agent, text: fill(msg.error_non_numeric_dose, { agent: label }) });
      continue;
    }
    if (inf.dose < 0) {
      errors.push({ code: "negative_dose", agent: inf.agent, text: fill(msg.error_negative_dose, { agent: label }) });
      continue;
    }
    if (inf.dose === 0) continue; // zero_dose: ignore_row
    const unitDef = agent && agent.input_units.find((u) => u.unit === inf.unit);
    if (!unitDef) {
      errors.push({ code: "unknown_unit", agent: inf.agent, unit: inf.unit, text: fill(msg.error_unknown_unit, { agent: label, unit: inf.unit }) });
      continue;
    }
    if (unitDef.per_weight && !weightGiven) {
      errors.push({ code: "weight_required", agent: inf.agent, unit: inf.unit, text: fill(msg.error_weight_required, { agent: label, unit: inf.unit }) });
      continue;
    }
    rows.push({ inf, agent, unitDef });
  }

  if (errors.length) {
    return { status: "error", formula: formula.id, errors, warnings, info, nee_mcg_kg_min: null, nee_mcg_min: null, adjunct_mcg_kg_min: null, breakdown: [] };
  }

  const breakdown = [];
  let total = 0;
  let adjunctTotal = null;
  for (const { inf, agent, unitDef } of rows) {
    let canonical = inf.dose * frac(unitDef.multiply);
    if (unitDef.per_weight) canonical = canonical / weight;
    if (agent.id === logic.norepinephrine_salt.applies_to_agent) {
      canonical = canonical * frac(salt.factor_to_base);
    }
    const f = formula.factors[agent.id];
    if (!f) {
      warnings.push({
        code: "agent_not_in_formula",
        agent: agent.id,
        text: fill(msg.warning_agent_not_in_formula, { agent: agent.label, formula: formula.label }),
      });
      breakdown.push({ agent: agent.id, dose_entered: inf.dose, unit_entered: inf.unit, dose_canonical: canonical, canonical_unit: agent.canonical_unit, factor: null, contribution: 0, counted: false, adjunct: agent.role === "adjunct" });
      continue;
    }
    const factor = frac(f.factor);
    const contribution = canonical * factor;
    if (agent.role === "adjunct") {
      // rules.adjunct_role: computed with the formula's factor, shown separately, never added.
      adjunctTotal = (adjunctTotal || 0) + contribution;
      breakdown.push({ agent: agent.id, dose_entered: inf.dose, unit_entered: inf.unit, dose_canonical: canonical, canonical_unit: agent.canonical_unit, factor, contribution, counted: false, adjunct: true });
      continue;
    }
    total += contribution;
    breakdown.push({ agent: agent.id, dose_entered: inf.dose, unit_entered: inf.unit, dose_canonical: canonical, canonical_unit: agent.canonical_unit, factor, contribution, counted: true, adjunct: false });
  }

  if (rows.length === 0) {
    info.push({ code: "no_inputs", text: msg.info_no_inputs });
  }

  // Canonical doses actually entered (norepinephrine already converted to base).
  const canonicalByAgent = Object.fromEntries(breakdown.filter((b) => !b.adjunct).map((b) => [b.agent, b.dose_canonical]));
  for (const note of logic.context_notes) {
    if (note.type !== "info" || !note.show_when_all) continue;
    const show = note.show_when_all.every((c) => {
      const d = canonicalByAgent[c.agent];
      if (c.adjunct_estimate_present) return adjunctTotal !== null;
      if (c.absent) return d === undefined;
      if (c.canonical_dose_gte) return d !== undefined && d >= frac(c.canonical_dose_gte);
      return false;
    });
    if (show) info.push({ code: note.id, text: note.text });
  }

  return {
    status: "ok",
    formula: formula.id,
    errors,
    warnings,
    info,
    nee_mcg_kg_min: total,
    nee_mcg_min: weightGiven ? total * weight : null,
    adjunct_mcg_kg_min: adjunctTotal,
    breakdown,
  };
}

if (typeof module !== "undefined") module.exports = { computeNEE };
