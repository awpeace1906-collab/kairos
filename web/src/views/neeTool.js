// NEE calculator (engine: "builtin", tool: "nee"). Every agent, unit, factor,
// label, message, note and citation comes from the kit's nee-logic.json
// (served as content/tools/…); this file only lays it out in Kairos's skin,
// following Resources/NEE/CODE-INSTRUCTIONS.md. Values live in this closure
// only and update live; nothing is saved. Mirrors ios/Sources/Views/NEEToolView.swift.
import { el, tintStyle } from "../components.js";
import { computeNEE } from "../lib/neeEngine.js";

const LOGIC_URL = "./content/tools/nee-logic.json";

export function renderNEETool(mod) {
  const section = el("section", { class: "content calculator nee-tool", style: tintStyle(mod) }, el("h1", {}, mod.title));
  const body = el("div", { class: "nee-body" });
  section.append(body);
  fetch(LOGIC_URL)
    .then((r) => { if (!r.ok) throw new Error(String(r.status)); return r.json(); })
    .then((logic) => mountTool(logic, body))
    .catch(() => body.replaceChildren(el("p", { class: "band sev-moderate" }, "This tool could not load. Reconnect once to cache it for offline use.")));
  return section;
}

function mountTool(logic, body) {
  const ui = logic.ui;
  const dec = logic.output.display_decimals;
  const fmt = (v, d) => (v == null ? "" : Number(v).toFixed(d));
  const fill = (t, vars) => t.replace(/\{(\w+)\}/g, (_, k) => (k in vars ? String(vars[k]) : `{${k}}`));
  const defaultUnit = (a) => (a.input_units.find((u) => u.default) || a.input_units[0]).unit;
  const fresh = () => ({
    formulaId: logic.formulas.find((f) => f.default).id,
    weight: "",
    salt: logic.norepinephrine_salt.default,
    doses: {},
    units: Object.fromEntries(logic.agents.map((a) => [a.id, defaultUnit(a)])),
  });
  let st = fresh();

  const num = (s) => {
    const t = String(s ?? "").trim().replace(",", ".");
    if (t === "") return undefined;
    const n = Number(t);
    return Number.isFinite(n) ? n : NaN;
  };
  const input = () => ({
    formulaId: st.formulaId,
    weightKg: num(st.weight),
    neSalt: st.salt,
    infusions: logic.agents
      .filter((a) => num(st.doses[a.id]) !== undefined)
      .map((a) => ({ agent: a.id, dose: num(st.doses[a.id]), unit: st.units[a.id] })),
  });
  const formula = () => logic.formulas.find((f) => f.id === st.formulaId);
  const unitDef = (a) => a.input_units.find((u) => u.unit === st.units[a.id]);
  const weightNeeded = () => logic.agents.some((a) => num(st.doses[a.id]) !== undefined && unitDef(a)?.per_weight);

  // ---------------------------------------------------------------- inputs
  const inputsBox = el("div", { class: "nee-inputs" });
  const resultBox = el("div", { class: "nee-result", "aria-live": "polite" });
  const footer = el("div", { class: "nee-footer" });

  function seg(label, options, value, onPick) {
    return el("div", { class: "axis-seg", role: "group", "aria-label": label },
      options.map((o) => el("button", {
        type: "button", class: "axis-seg-btn" + (o.id === value ? " selected" : ""), "aria-pressed": String(o.id === value),
        onClick: () => onPick(o.id),
      }, o.label)));
  }

  function agentRow(a) {
    const inFormula = !!formula().factors[a.id];
    const id = `nee-${a.id}`;
    const field = el("input", { id, type: "text", inputmode: "decimal", autocomplete: "off", value: st.doses[a.id] ?? "",
      onInput: (e) => { st.doses[a.id] = e.target.value; refreshWeight(); compute(); } });
    const units = a.input_units.length > 1
      ? seg(`${a.label} unit`, a.input_units.map((u) => ({ id: u.unit, label: u.unit })), st.units[a.id], (u) => { st.units[a.id] = u; renderInputs(); compute(); })
      : el("span", { class: "nee-unit" }, a.input_units[0].unit);
    const salt = a.id === logic.norepinephrine_salt.applies_to_agent
      ? el("div", { class: "nee-salt" }, el("span", { class: "field-label" }, ui.salt_label),
          seg(ui.salt_label, logic.norepinephrine_salt.options, st.salt, (s) => { st.salt = s; renderInputs(); compute(); }))
      : null;
    return el("div", { class: "nee-row" + (inFormula ? "" : " nee-row-out") },
      el("div", { class: "nee-row-head" },
        el("label", { class: "nee-agent", for: id }, a.label),
        inFormula ? null : el("span", { class: "nee-out-marker" }, ui.not_in_formula_marker)),
      el("div", { class: "nee-row-controls" }, field, units),
      salt);
  }

  let weightMarker;
  function refreshWeight() { if (weightMarker) weightMarker.hidden = !weightNeeded(); }

  function renderInputs() {
    const f = formula();
    weightMarker = el("span", { class: "nee-required", hidden: !weightNeeded() }, ui.weight_required_marker);
    inputsBox.replaceChildren(
      el("div", { class: "nee-formula" },
        el("span", { class: "field-label" }, ui.formula_label),
        seg(ui.formula_label, logic.formulas.map((x) => ({ id: x.id, label: x.label })), st.formulaId, (id) => { st.formulaId = id; renderInputs(); compute(); }),
        el("p", { class: "muted nee-formula-desc" }, f.description)),
      el("div", { class: "nee-weight" },
        el("label", { class: "field-label", for: "nee-weight" }, ui.weight_label, " ", weightMarker),
        el("input", { id: "nee-weight", type: "text", inputmode: "decimal", autocomplete: "off", value: st.weight,
          onInput: (e) => { st.weight = e.target.value; compute(); } })),
      el("div", { class: "nee-rows" }, logic.agents.filter((a) => a.role !== "adjunct").map(agentRow)),
      el("h3", { class: "nee-heading" }, ui.adjuncts_heading),
      el("div", { class: "nee-rows" }, logic.agents.filter((a) => a.role === "adjunct").map(agentRow)),
      el("button", { type: "button", class: "clear-all", onClick: () => { st = fresh(); renderInputs(); compute(); } }, ui.clear_all));
  }

  // ---------------------------------------------------------------- result
  function compute() {
    const r = computeNEE(logic, input());
    const agent = (id) => logic.agents.find((a) => a.id === id);
    const kids = [];
    if (r.status === "error") {
      for (const e of r.errors) kids.push(el("p", { class: "band sev-high nee-error", role: "alert" }, e.text));
    } else {
      kids.push(el("div", { class: "nee-number" },
        el("span", { class: "nee-label" }, ui.result_label),
        el("strong", { class: "nee-value" }, fmt(r.nee_mcg_kg_min, dec.nee_mcg_kg_min)),
        el("span", { class: "nee-unit-big" }, logic.output.primary_unit),
        r.nee_mcg_min != null ? el("span", { class: "nee-secondary" }, `${fmt(r.nee_mcg_min, dec.nee_mcg_min)} ${logic.output.secondary_unit}`) : null));
      if (r.adjunct_mcg_kg_min != null) {
        const note = r.info.find((i) => i.code === "adjunct_note");
        kids.push(el("div", { class: "nee-adjunct" },
          el("p", {}, fill(ui.adjunct_line, { value: fmt(r.adjunct_mcg_kg_min, dec.adjunct_mcg_kg_min), unit: logic.output.adjunct_unit })),
          note ? el("p", { class: "muted" }, note.text) : null));
      }
      for (const w of r.warnings) kids.push(el("p", { class: "band sev-moderate" }, w.text));
      for (const i of r.info) if (i.code !== "adjunct_note") kids.push(el("p", { class: "band sev-info" }, i.text));
      if (r.breakdown.length) {
        kids.push(el("h3", { class: "nee-heading" }, ui.breakdown_heading),
          el("ul", { class: "nee-breakdown" }, r.breakdown.map((b) => {
            const a = agent(b.agent);
            const pub = formula().factors[b.agent]?.published_as;
            const outUnit = b.adjunct ? logic.output.adjunct_unit : logic.output.primary_unit;
            return el("li", { class: b.counted ? "" : "nee-breakdown-out" },
              el("strong", {}, a.label), " ",
              `${fmt(b.dose_canonical, dec.dose_canonical)} ${b.canonical_unit}`,
              pub ? ` → ${pub} → ${fmt(b.contribution, dec.contribution_mcg_kg_min)} ${outUnit}` : ` → ${ui.not_in_formula_marker}`);
          })));
      }
    }
    resultBox.replaceChildren(...kids);

    // Footer: static notes, then sources per ui.sources_rule.
    const statics = logic.context_notes.filter((n) => n.type === "static");
    const shownInfo = r.status === "ok" ? r.info.map((i) => i.code).filter((c) => logic.context_notes.some((n) => n.id === c)) : [];
    const ids = [formula().citation_id];
    for (const nid of [...shownInfo, ...statics.map((n) => n.id)]) {
      const c = logic.context_notes.find((n) => n.id === nid)?.citation_id;
      if (c && !ids.includes(c)) ids.push(c);
    }
    footer.replaceChildren(
      ...statics.map((n) => el("p", { class: "muted nee-static" }, n.text)),
      el("section", { class: "sources-block" }, el("h2", {}, ui.sources_heading),
        el("ol", {}, ids.map((k) => el("li", {}, logic.citations[k])))));
  }

  renderInputs();
  compute();
  body.replaceChildren(inputsBox, resultBox, footer);
}
