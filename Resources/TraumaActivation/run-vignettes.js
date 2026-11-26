// node run-vignettes.js
"use strict";
const fs = require("fs"), path = require("path");
const { evaluate } = require("./trauma-engine-reference.js");
const suite = JSON.parse(fs.readFileSync(path.join(__dirname, "trauma-vignettes.json"), "utf8"));
const same = (a, b) => JSON.stringify([...a].sort()) === JSON.stringify([...b].sort());
let pass = 0;
for (const v of suite.vignettes) {
  const profile = JSON.parse(fs.readFileSync(path.join(__dirname, "profiles", v.profile), "utf8"));
  if (profile.profile_version !== suite.profile_version) { console.error("profile version mismatch"); process.exit(1); }
  const r = evaluate(profile, v.input), e = v.expect, f = [];
  if (r.status !== e.status) f.push(`status ${r.status}`);
  if (e.status === "ok") {
    if (r.tier !== e.tier) f.push(`tier ${r.tier} != ${e.tier}`);
    if (e.met_ids && !same(r.met.map((m) => m.id), e.met_ids)) f.push(`met ${JSON.stringify(r.met.map((m) => m.id))}`);
    if (!same(r.compound_hints.map((h) => h.id), e.compound_hints)) f.push(`hints ${JSON.stringify(r.compound_hints.map((h) => h.id))}`);
    if (!same(r.advisories.map((a) => a.id), e.advisories)) f.push(`advisories ${JSON.stringify(r.advisories.map((a) => a.id))}`);
    if (!same(r.notes.map((n) => n.id), e.notes)) f.push(`notes ${JSON.stringify(r.notes.map((n) => n.id))}`);
  } else if (!same(r.errors.map((x) => x.code), e.errors)) f.push(`errors ${JSON.stringify(r.errors.map((x) => x.code))}`);
  if (f.length) console.log(`FAIL ${v.id} ${v.title}\n   ${f.join("\n   ")}`); else { pass++; console.log(`pass ${v.id} ${v.title}`); }
}
console.log(`\n${pass}/${suite.vignettes.length} vignettes passed`);
if (pass !== suite.vignettes.length) process.exitCode = 1;

// ---- Profile validation and import-draft tests ----
{
  const { validateProfile, canSaveDraft } = require("./profile-tools-reference.js");
  const templates = JSON.parse(fs.readFileSync(path.join(__dirname, "rule-templates.json"), "utf8"));
  const pt = JSON.parse(fs.readFileSync(path.join(__dirname, "profile-tests.json"), "utf8"));
  const base = fs.readFileSync(path.join(__dirname, "profiles", pt.base_profile), "utf8");
  let p2 = 0, n2 = 0;
  for (const t of pt.validation) {
    n2++;
    const prof = JSON.parse(base);
    for (const m of t.mutations) {
      let o = prof; for (const k of m.set.slice(0, -1)) o = o[k];
      const last = m.set[m.set.length - 1];
      if (m.value === null) delete o[last]; else o[last] = m.value;
    }
    const codes = [...new Set(validateProfile(prof, templates).map((e) => e.code))];
    if (same(codes, t.expect)) { p2++; console.log(`pass ${t.id} ${t.title}`); }
    else console.log(`FAIL ${t.id} ${t.title}\n   got ${JSON.stringify(codes)}`);
  }
  for (const t of pt.drafts) {
    n2++;
    const r = canSaveDraft(t.draft);
    const codes = [...new Set(r.blocking.map((b) => b.code))];
    if (r.ok === t.expect_ok && same(codes, t.expect)) { p2++; console.log(`pass ${t.id} ${t.title}`); }
    else console.log(`FAIL ${t.id} ${t.title}\n   got ok=${r.ok} ${JSON.stringify(codes)}`);
  }
  console.log(`\n${p2}/${n2} profile/import tests passed`);
  if (p2 !== n2) process.exitCode = 1;
}

// ---- Profile library tests ----
{
  const { addToLibrary, removeFromLibrary, listByInstitution } = require("./profile-tools-reference.js");
  const pt = JSON.parse(fs.readFileSync(path.join(__dirname, "profile-tests.json"), "utf8"));
  let p3 = 0;
  for (const t of pt.library) {
    let lib = { entries: [], default_profile_id: null };
    for (const s of t.steps) lib = s.add ? addToLibrary(lib, s.add, s.at).library : removeFromLibrary(lib, s.remove);
    const groups = listByInstitution(lib).map((g) => ({ current: g.current_profile_id, versions: g.versions.map((v) => v.profile_id) }));
    const got = { count: lib.entries.length, default: lib.default_profile_id, groups };
    if (JSON.stringify(got) === JSON.stringify(t.expect)) { p3++; console.log(`pass ${t.id} ${t.title}`); }
    else console.log(`FAIL ${t.id} ${t.title}\n   got ${JSON.stringify(got)}`);
  }
  console.log(`\n${p3}/${pt.library.length} library tests passed`);
  if (p3 !== pt.library.length) process.exitCode = 1;
}
