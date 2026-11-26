// profile-tools-reference.js
// Reference implementations for profile creation/import:
//   expandTemplate(templates, ref)       -> rule expression
//   validateProfile(profile, templates)  -> [{ code, where }]   (empty = valid)
//   needsDoubleCheck(text)               -> boolean
//   canSaveDraft(draft)                  -> { ok, blocking: [{ code, line }] }
// No clinical content lives here.
"use strict";

const OPS = new Set(["lt", "lte", "gt", "gte", "add", "mul", "div", "and", "or"]);

function substitute(node, params) {
  if (typeof node === "string") {
    const m = node.match(/^\{(\w+)\}$/);
    if (!m) return node;
    if (!(m[1] in params)) throw { code: "template_param_missing", param: m[1] };
    return params[m[1]];
  }
  if (Array.isArray(node)) return node.map((n) => substitute(n, params));
  if (node && typeof node === "object") {
    const out = {};
    for (const [k, v] of Object.entries(node)) out[k] = substitute(v, params);
    return out;
  }
  return node;
}

function expandTemplate(templates, ref) {
  const t = templates.templates.find((x) => x.id === ref.id);
  if (!t) throw { code: "template_unknown", id: ref.id };
  for (const p of t.params) {
    const v = ref.params[p.id];
    if (v === undefined) throw { code: "template_param_missing", param: p.id };
    if (p.type === "number" && (typeof v !== "number" || !isFinite(v))) throw { code: "template_param_invalid", param: p.id };
    if (p.type === "vital_id" && typeof v !== "string") throw { code: "template_param_invalid", param: p.id };
  }
  return substitute(t.rule, ref.params);
}

function varsIn(node, acc = []) {
  if (Array.isArray(node)) node.forEach((n) => varsIn(n, acc));
  else if (node && typeof node === "object") {
    if ("var" in node) acc.push(node.var);
    else for (const [k, v] of Object.entries(node)) { if (!OPS.has(k)) acc.push(`__badop:${k}`); varsIn(v, acc); }
  }
  return acc;
}

const same = (a, b) => JSON.stringify(a) === JSON.stringify(b);

function checkRule(rule, templateRef, where, vitalIds, templates, errors) {
  for (const v of varsIn(rule)) {
    if (v.startsWith("__badop:")) errors.push({ code: "rule_unknown_operator", where });
    else if (!vitalIds.has(v)) errors.push({ code: "rule_unknown_vital", where });
  }
  if (!templateRef) return;
  try {
    const t = templates.templates.find((x) => x.id === templateRef.id);
    if (t) for (const p of t.params) if (p.type === "vital_id" && !vitalIds.has(templateRef.params[p.id])) throw { code: "template_param_invalid" };
    const expanded = expandTemplate(templates, templateRef);
    if (!same(expanded, rule)) errors.push({ code: "template_mismatch", where });
  } catch (e) {
    errors.push({ code: e.code || "template_error", where });
  }
}

function validateProfile(profile, templates) {
  const errors = [];
  for (const k of ["institution", "title", "source_revision_date", "distribution"]) {
    if (!profile[k]) errors.push({ code: "missing_metadata", where: k });
  }
  if (profile.distribution && profile.distribution !== "personal_only") errors.push({ code: "distribution_not_personal", where: "distribution" });
  if (profile.source_revision_date && !/^\d{4}-\d{2}-\d{2}$/.test(profile.source_revision_date)) errors.push({ code: "bad_revision_date", where: "source_revision_date" });

  const tierIds = new Set(), ranks = new Set();
  for (const t of profile.tiers || []) {
    if (tierIds.has(t.id)) errors.push({ code: "duplicate_tier_id", where: t.id });
    if (ranks.has(t.rank)) errors.push({ code: "duplicate_tier_rank", where: t.id });
    tierIds.add(t.id); ranks.add(t.rank);
  }
  if (tierIds.size === 0) errors.push({ code: "no_tiers", where: "tiers" });

  const vitalIds = new Set((profile.vitals || []).map((v) => v.id));
  const critIds = new Set();
  for (const c of profile.criteria || []) {
    if (critIds.has(c.id)) errors.push({ code: "duplicate_criterion_id", where: c.id });
    critIds.add(c.id);
    if (!tierIds.has(c.tier)) errors.push({ code: "unknown_tier", where: c.id });
    if (!["criterion", "discretion", "compound", "advisory"].includes(c.kind)) errors.push({ code: "unknown_kind", where: c.id });
    if (c.auto) checkRule(c.auto.rule, c.auto.template, c.id, vitalIds, templates, errors);
    if (c.kind === "compound") {
      if (!c.compound || !tierIds.has(c.compound.requires_any_criterion_of_tier)) errors.push({ code: "compound_unknown_tier", where: c.id });
      else if (c.compound.base_auto) checkRule(c.compound.base_auto, c.compound.base_template, c.id, vitalIds, templates, errors);
    }
    if (c.kind === "advisory" && !tierIds.has(c.show_when_result_tier)) errors.push({ code: "advisory_unknown_tier", where: c.id });
  }
  return errors;
}

// Lines with digits or comparison symbols are where OCR errors are most dangerous
// (e.g., "≤" read as "<", "29" read as "20"); they need a second explicit confirmation.
function needsDoubleCheck(text) {
  return /[0-9<>≤≥=%]/.test(text);
}

// draft = { institution, source_revision_date, lines: [{ id, text, role, confirmed, double_checked }] }
// role: "ignore" | "criterion" | "tier_header" | "group_header" | "team_response" | "response_time" | "note" | "metadata"
function canSaveDraft(draft) {
  const blocking = [];
  if (!draft.institution) blocking.push({ code: "missing_institution" });
  if (!draft.source_revision_date) blocking.push({ code: "missing_revision_date" });
  for (const l of draft.lines) {
    if (l.role === "ignore") continue;
    if (!l.role) { blocking.push({ code: "unassigned_line", line: l.id }); continue; }
    if (!l.confirmed) blocking.push({ code: "unconfirmed_line", line: l.id });
    else if (needsDoubleCheck(l.text) && !l.double_checked) blocking.push({ code: "needs_double_check", line: l.id });
  }
  return { ok: blocking.length === 0, blocking };
}

if (typeof module !== "undefined") module.exports = { expandTemplate, validateProfile, needsDoubleCheck, canSaveDraft };

// ---- Profile library (many facilities, many revisions; nothing is overwritten) ----
// library = { entries: [{ profile, added_at }], default_profile_id: string | null }
const instKey = (s) => (s || "").trim().toLowerCase();

function addToLibrary(library, profile, addedAt) {
  const lib = { entries: [...library.entries], default_profile_id: library.default_profile_id };
  const ids = new Set(lib.entries.map((e) => e.profile.profile_id));
  let id = profile.profile_id, n = 2;
  while (ids.has(id)) id = `${profile.profile_id}-${n++}`;
  lib.entries.push({ profile: { ...profile, profile_id: id }, added_at: addedAt });
  if (!lib.default_profile_id) lib.default_profile_id = id;
  return { library: lib, id };
}

function removeFromLibrary(library, profileId) {
  const entries = library.entries.filter((e) => e.profile.profile_id !== profileId);
  let def = library.default_profile_id;
  if (def === profileId) def = entries.length ? entries[0].profile.profile_id : null;
  return { entries, default_profile_id: def };
}

// Newest source_revision_date is "current"; ties go to the most recently added.
function byNewest(a, b) {
  if (a.profile.source_revision_date !== b.profile.source_revision_date)
    return a.profile.source_revision_date < b.profile.source_revision_date ? 1 : -1;
  return a.added_at < b.added_at ? 1 : -1;
}

function listByInstitution(library) {
  const groups = new Map();
  for (const e of library.entries) {
    const k = instKey(e.profile.institution);
    if (!groups.has(k)) groups.set(k, { institution: e.profile.institution, versions: [] });
    groups.get(k).versions.push(e);
  }
  return [...groups.values()]
    .map((g) => {
      const v = [...g.versions].sort(byNewest);
      return {
        institution: g.institution,
        current_profile_id: v[0].profile.profile_id,
        versions: v.map((e) => ({ profile_id: e.profile.profile_id, source_revision_date: e.profile.source_revision_date, added_at: e.added_at })),
      };
    })
    .sort((a, b) => instKey(a.institution).localeCompare(instKey(b.institution)));
}

if (typeof module !== "undefined") Object.assign(module.exports, { addToLibrary, removeFromLibrary, listByInstitution });
