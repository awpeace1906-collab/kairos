// Interprets a calculator module. Pure — no DOM. Shared shape with
// ios/Sources/Calc/CalculatorEngine.swift.
import { evaluate } from "./expr.js";

/**
 * @param {object} calc  a calculator module (or an embedded peds calculator)
 * @param {object} state  { items: {key: optionIndex}, inputs: {key: value} }
 * @returns {object} { engine, score?, results?, bands: [...], incomplete: bool }
 */
export function runCalculator(calc, state = {}) {
  switch (calc.engine) {
    case "additive":
      return runAdditive(calc, state);
    case "formula":
      return runFormula(calc, state);
    case "classification":
      return { engine: "classification", tiers: calc.tiers || [], bands: calc.interpretation, incomplete: false };
    case "external":
      return { engine: "external", bands: calc.interpretation, buildNote: calc.buildNote, incomplete: true };
    default:
      throw new Error(`unknown engine "${calc.engine}"`);
  }
}

function runAdditive(calc, { items = {} }) {
  let score = 0;
  let answered = 0;
  for (const item of calc.items || []) {
    const choice = items[item.key];
    if (choice == null) continue;
    const opt = item.options[choice];
    if (!opt) continue;
    score += opt.points;
    answered++;
  }
  const incomplete = answered < (calc.items || []).length;
  const matched = incomplete
    ? []
    : (calc.interpretation || []).filter(
        (b) => b.min == null || (score >= b.min && score <= (b.max ?? Infinity))
      );
  return { engine: "additive", score, answered, incomplete, bands: matched, allBands: calc.interpretation };
}

function runFormula(calc, { inputs = {} }) {
  const scope = {};
  for (const inp of calc.inputs || []) {
    const raw = inputs[inp.key];
    if (raw === "" || raw == null) continue;
    scope[inp.key] = Number(raw);
  }
  const results = [];
  for (const f of calc.formulas || []) {
    try {
      const value = evaluate(f.expression, scope);
      if (Number.isFinite(value)) {
        results.push({
          key: f.key,
          label: f.label,
          unit: f.unit,
          value: round(value, f.precision ?? 2),
        });
      }
    } catch {
      // a formula that needs an input not yet supplied — skip silently
    }
  }
  const bandsByKey = {};
  for (const r of results) {
    bandsByKey[r.key] = (calc.interpretation || []).filter(
      (b) => b.forKey === r.key && r.value >= (b.min ?? -Infinity) && r.value <= (b.max ?? Infinity)
    );
  }
  return {
    engine: "formula",
    results,
    bandsByKey,
    incomplete: results.length < (calc.formulas || []).length,
  };
}

function round(n, p) {
  const f = 10 ** p;
  return Math.round(n * f) / f;
}
