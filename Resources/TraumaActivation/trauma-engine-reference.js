// trauma-engine-reference.js
// Reference evaluator for a local trauma-activation profile. Pure function; no UI, no storage.
// Every criterion, threshold, tier, and string comes from the profile JSON.
//
// evaluate(profile, input)
//   input = {
//     checked: ["criterion.id", ...],   // criteria the user tapped (for compound: tapping = base is true)
//     vitals: { age_years, sbp, hr, rr, gcs_total, gcs_motor }   // any subset; omit unknowns
//   }
// returns {
//   status: "ok" | "error",
//   errors: [{ code, vital, text }],
//   tier: "red" | "yellow" | "green" | null,      // highest tier met; null = no criteria met
//   met: [{ id, tier, source: "checked" | "auto" | "compound" | "discretion" }],
//   compound_hints: [{ id, text }],               // compound base true but requirement unmet
//   notes: [{ id, text }],                         // per-criterion notes for met criteria
//   advisories: [{ id, text }],                    // advisory criteria shown for the result tier
//   team_response: [...] | null, response_time: string | null
// }
"use strict";

// Three-valued expression evaluation: returns number, boolean, or null (unknown).
function ev(node, vitals) {
  if (typeof node === "number") return node;
  if (node === null || typeof node !== "object") return null;
  if ("var" in node) {
    const v = vitals[node.var];
    return typeof v === "number" && isFinite(v) ? v : null;
  }
  const [op] = Object.keys(node);
  const args = node[op];
  const vals = () => args.map((a) => ev(a, vitals));
  switch (op) {
    case "lt": case "lte": case "gt": case "gte": {
      const [a, b] = vals();
      if (a === null || b === null) return null;
      return op === "lt" ? a < b : op === "lte" ? a <= b : op === "gt" ? a > b : a >= b;
    }
    case "add": { const v = vals(); return v.includes(null) ? null : v.reduce((s, x) => s + x, 0); }
    case "mul": { const v = vals(); return v.includes(null) ? null : v.reduce((s, x) => s * x, 1); }
    case "div": { const [a, b] = vals(); return a === null || b === null || b === 0 ? null : a / b; }
    case "and": {
      const v = vals();
      if (v.includes(false)) return false;
      return v.includes(null) ? null : true;
    }
    case "or": {
      const v = vals();
      if (v.includes(true)) return true;
      return v.includes(null) ? null : false;
    }
    default:
      throw new Error(`Unknown operator ${op}`);
  }
}

function evaluate(profile, input) {
  const checked = new Set(input.checked || []);
  const vitals = input.vitals || {};
  const errors = [];

  for (const def of profile.vitals) {
    const v = vitals[def.id];
    if (v === undefined || v === null) continue;
    if (typeof v !== "number" || !isFinite(v) || v < def.min || v > def.max) {
      errors.push({ code: "vital_out_of_range", vital: def.id, text: `${def.label} must be between ${def.min} and ${def.max}.` });
    }
  }
  const ids = new Set(profile.criteria.map((c) => c.id));
  for (const id of checked) if (!ids.has(id)) errors.push({ code: "unknown_criterion", text: `Unknown criterion ${id}.` });
  if (errors.length) {
    return { status: "error", errors, tier: null, met: [], compound_hints: [], notes: [], advisories: [], team_response: null, response_time: null };
  }

  const met = [];
  const isMet = new Set();
  // Pass 1: ordinary and discretion criteria.
  for (const c of profile.criteria) {
    if (c.kind === "criterion") {
      if (checked.has(c.id)) { met.push({ id: c.id, tier: c.tier, source: "checked" }); isMet.add(c.id); }
      else if (c.auto && ev(c.auto.rule, vitals) === true) { met.push({ id: c.id, tier: c.tier, source: "auto" }); isMet.add(c.id); }
    } else if (c.kind === "discretion" && checked.has(c.id)) {
      met.push({ id: c.id, tier: c.tier, source: "discretion" }); isMet.add(c.id);
    }
  }
  // Pass 2: compound criteria. "Any criterion of tier X" counts only kind === "criterion".
  const compound_hints = [];
  for (const c of profile.criteria) {
    if (c.kind !== "compound") continue;
    const base = checked.has(c.id) || (c.compound.base_auto ? ev(c.compound.base_auto, vitals) === true : false);
    if (!base) continue;
    const reqTier = c.compound.requires_any_criterion_of_tier;
    const satisfied = profile.criteria.some((o) => o.kind === "criterion" && o.tier === reqTier && isMet.has(o.id));
    if (satisfied) { met.push({ id: c.id, tier: c.tier, source: "compound" }); isMet.add(c.id); }
    else compound_hints.push({ id: c.id, text: c.compound.unmet_hint });
  }

  const rank = Object.fromEntries(profile.tiers.map((t) => [t.id, t.rank]));
  let tier = null;
  for (const m of met) if (tier === null || rank[m.tier] > rank[tier]) tier = m.tier;
  const tierDef = profile.tiers.find((t) => t.id === tier) || null;

  const notes = profile.criteria.filter((c) => isMet.has(c.id) && c.note).map((c) => ({ id: c.id, text: c.note }));
  const advisories = profile.criteria
    .filter((c) => c.kind === "advisory" && tier !== null && c.show_when_result_tier === tier)
    .map((c) => ({ id: c.id, text: c.text }));

  return {
    status: "ok", errors, tier, met, compound_hints, notes, advisories,
    team_response: tierDef ? tierDef.team_response : null,
    response_time: tierDef ? tierDef.response_time : null,
  };
}

if (typeof module !== "undefined") module.exports = { evaluate, ev };
