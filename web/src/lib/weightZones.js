// Dual-mode weight/zone logic (Dual_Mode_Weight_Zone_Spec.md).
// The zone supplies equipment sizes + a visual anchor ONLY. Drug doses and fluid
// volumes are computed by dosing.js from the exact weight, never read from here.
import { evaluate } from "./expr.js";

export function zoneForWeight(cfg, weightKg) {
  if (!Number.isFinite(weightKg)) return null;
  // Ranges are integer bands with gaps (e.g. 14->15). A weight landing in a gap
  // belongs to the lower zone: pick the last zone whose min the weight clears.
  // Matches the Dual_Mode spec worked example (14.3 kg -> Violet / zone 4).
  let match = null;
  for (const z of cfg.zones) {
    if (weightKg >= z.weight_min) match = z;
    else break;
  }
  return match || cfg.zones[0];
}

/** APLS-style estimate. Result must be surfaced flagged "estimated". */
export function estimateWeight(cfg, { ageMonths, ageYears }) {
  const months = ageMonths ?? (ageYears != null ? ageYears * 12 : null);
  if (months == null) return null;
  const band = cfg.ageEstimate.formulas.find((f) => months >= f.minMonths && months < f.maxMonths);
  if (!band) return null;
  const value = evaluate(band.expression, {
    ageMonths: months,
    ageYears: months / 12,
  });
  return { weightKg: Math.round(value * 10) / 10, estimated: true, band: band.ageBandLabel };
}

/**
 * Live per-kg dose from a drug-card `rule`. `weightKg` is the exact entered (or
 * estimated) weight — the zone is never consulted for this number.
 */
export function doseFromRule(rule, weightKg) {
  if (!Number.isFinite(weightKg)) return null;
  let mg = rule.perKg * weightKg;
  let capped = false;
  if (rule.maxDose != null && mg > rule.maxDose) {
    mg = rule.maxDose;
    capped = true;
  }
  const out = {
    amount: round(mg, 3),
    unit: rule.unit || "mg",
    capped,
    perKg: rule.perKg,
    weightKg,
  };
  if (rule.mlPerUnit != null) {
    out.volumeMl = round(mg * rule.mlPerUnit, 2);
    out.concentration = rule.concentration;
  }
  if (rule.repeat) out.repeat = rule.repeat;
  return out;
}

function round(n, p) {
  const f = 10 ** p;
  return Math.round(n * f) / f;
}
