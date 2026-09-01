import { el, mount, clearableField, lastVerified } from "../components.js";
import { renderCalculator } from "./calculator.js";
import { zoneForWeight, doseFromRule, estimateWeight } from "../lib/weightZones.js";
import { session } from "../lib/session.js";

export function renderContent(mod, route, store) {
  switch (mod.contentType) {
    case "calculator":
      return renderCalculator(mod, route);
    case "reference":
      return renderReference(mod);
    case "procedure":
      return renderProcedure(mod);
    case "drug-card":
      return renderDrugCard(mod, route, store);
    case "peds-tool":
      return renderPedsTool(mod, route, store);
    default:
      return el("section", { class: "content" }, el("h1", {}, mod.title), el("p", {}, "Unsupported content type."));
  }
}

function shell(mod, ...body) {
  return el(
    "section",
    { class: `content ${mod.contentType}` },
    el("h1", {}, mod.title),
    mod.summary ? el("p", { class: "purpose" }, mod.summary) : null,
    mod.purpose ? el("p", { class: "purpose" }, mod.purpose) : null,
    ...body,
    mod.buildNote ? el("details", { class: "build-note" }, el("summary", {}, "Build note"), el("p", {}, mod.buildNote)) : null,
    lastVerified(mod)
  );
}

function renderReference(mod) {
  const blocks = (mod.body || []).map((b) => {
    switch (b.type) {
      case "heading":
        return el(`h${b.level || 2}`, {}, b.text);
      case "text":
        return el("p", {}, b.text);
      case "list":
        return el("ul", {}, (b.items || []).map((i) => el("li", {}, i)));
      case "callout":
        return el("div", { class: `callout ${b.tone || "info"}` }, b.text);
      case "table":
        return el(
          "div",
          { class: "table-wrap" },
          el(
            "table",
            {},
            el("thead", {}, el("tr", {}, (b.columns || []).map((c) => el("th", {}, c)))),
            el("tbody", {}, (b.rows || []).map((row) => el("tr", {}, row.map((cell) => el("td", {}, cell)))))
          )
        );
      default:
        return null;
    }
  });
  return shell(mod, el("div", { class: "prose" }, ...blocks));
}

function renderProcedure(mod) {
  return shell(
    mod,
    el("p", { class: "settings" }, `${mod.outputType}${mod.flags?.includes("stub") ? " · stub" : ""}`),
    mod.entryPrompt ? el("p", { class: "entry-prompt" }, mod.entryPrompt) : null,
    mod.nodes?.length
      ? el("ol", { class: "nodes" }, mod.nodes.map((n) =>
          el("li", { class: `node ${n.type}` },
            n.prompt ? el("strong", {}, n.prompt) : null,
            n.body ? el("p", {}, n.body) : null,
            n.choices?.length ? el("ul", {}, n.choices.map((c) => el("li", {}, `${c.label} → ${c.next}`))) : null)
        ))
      : null,
    mod.checklist?.length ? el("div", {}, el("h3", {}, "Checklist"), el("ul", { class: "checklist" }, mod.checklist.map((c) => el("li", {}, el("label", {}, el("input", { type: "checkbox" }), " ", c))))) : null,
    mod.noteTemplate ? el("div", {}, el("h3", {}, "Procedure note template"), el("pre", { class: "note-template" }, mod.noteTemplate)) : null,
    mod.crossLinks?.length ? el("p", { class: "muted" }, "Pulls dosing from: " + mod.crossLinks.join(", ")) : null
  );
}

function renderDrugCard(mod, route, store) {
  const saved = session.get(route);
  const state = { weight: saved.weight ?? "", ageYears: saved.ageYears ?? "" };
  const out = el("div", { class: "dose-output" });
  const zoneBar = el("div", { class: "zone-bar" });
  const cfg = store.weightZones;

  function recompute() {
    session.patch(route, state);
    let weightKg = parseFloat(state.weight);
    let estimated = false;
    if (!Number.isFinite(weightKg) && state.ageYears !== "") {
      const est = estimateWeight(cfg, { ageYears: parseFloat(state.ageYears) });
      if (est) {
        weightKg = est.weightKg;
        estimated = true;
      }
    }
    if (!Number.isFinite(weightKg)) {
      zoneBar.replaceChildren();
      out.replaceChildren(el("p", { class: "muted" }, "Enter an exact weight (preferred) or an age to estimate."));
      return;
    }
    const zone = zoneForWeight(cfg, weightKg);
    zoneBar.replaceChildren(
      el("span", { class: "zone-chip", dataset: { color: zone.color } }, `Zone ${zone.zone} · ${zone.color}`),
      el("span", { class: "zone-weight" }, `${weightKg} kg${estimated ? " (estimated)" : ""}`),
      el("span", { class: "zone-equip" }, `ETT ${zone.equipment.ettUncuffed} · LMA ${zone.equipment.lma} · ${zone.equipment.blade}`)
    );
    out.replaceChildren(
      ...mod.doses.map((d) => {
        const dose = doseFromRule(d.rule, weightKg);
        return el(
          "div",
          { class: "dose-row" },
          el("div", { class: "dose-ind" }, d.indication, el("span", { class: "muted" }, ` · ${d.route}`)),
          el("div", { class: "dose-amt" },
            el("strong", {}, `${dose.amount} ${dose.unit}`),
            dose.volumeMl != null ? el("span", {}, ` = ${dose.volumeMl} mL${dose.concentration ? ` (${dose.concentration})` : ""}`) : null,
            dose.capped ? el("span", { class: "flag" }, " max-dose cap") : null),
          dose.repeat ? el("div", { class: "muted" }, dose.repeat) : null,
          d.notes ? el("div", { class: "muted" }, d.notes) : null
        );
      }),
      el("p", { class: "disclaimer" }, cfg.disclaimer)
    );
  }

  const view = shell(
    mod,
    el("p", { class: "settings" }, `${mod.population || "both"} · weight basis: ${mod.weightBasis || "actual"}`),
    el("div", { class: "field-grid" },
      clearableField({ id: "d-weight", label: "Exact weight", unit: "kg", value: state.weight,
        onInput: (v) => { state.weight = v; recompute(); }, onClear: () => { state.weight = ""; recompute(); } }),
      clearableField({ id: "d-age", label: "Age (fallback estimate only)", unit: "years", value: state.ageYears,
        onInput: (v) => { state.ageYears = v; recompute(); }, onClear: () => { state.ageYears = ""; recompute(); } })
    ),
    zoneBar,
    out,
    mod.contraindications?.length ? el("p", {}, el("strong", {}, "Contraindications: "), mod.contraindications.join("; ")) : null,
    mod.reversal ? el("p", {}, el("strong", {}, "Reversal: "), mod.reversal) : null
  );
  recompute();
  return view;
}

function renderPedsTool(mod, route, store) {
  if (mod.embeddedCalculator) {
    const node = renderCalculator({ ...mod.embeddedCalculator, title: mod.title }, route);
    const intro = mount(el("div"), el("p", { class: "purpose" }, mod.purpose), mod.ageRange ? el("p", { class: "settings" }, mod.ageRange) : null);
    node.prepend(...intro.childNodes);
    return node;
  }
  return shell(
    mod,
    el("p", { class: "settings" }, `${mod.kind}${mod.ageRange ? " · " + mod.ageRange : ""}`),
    mod.sourceOfTruth?.length ? el("p", { class: "muted" }, "Defers to: " + mod.sourceOfTruth.join(", ")) : null
  );
}
