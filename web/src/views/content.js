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
      return renderProcedure(mod, route);
    case "drug-card":
      return renderDrugCard(mod, route, store);
    case "anesthesia-drug-card":
      return renderAnesthesiaDrugCard(mod);
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

/** Shared renderer for the `body` block array used by reference and peds-tool modules. */
export function renderBlocks(body) {
  return (body || []).map((b) => {
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
}

function renderReference(mod) {
  return shell(mod, el("div", { class: "prose" }, ...renderBlocks(mod.body)));
}

/** AnesCalc-origin anesthesia drug card — prose reference, no live math. */
function renderAnesthesiaDrugCard(mod) {
  const field = (label, value) =>
    value ? el("div", { class: "adc-field" }, el("span", { class: "adc-label" }, label), el("span", {}, value)) : null;
  const list = (label, items) =>
    items?.length ? el("div", {}, el("h3", {}, label), el("ul", {}, items.map((i) => el("li", {}, i)))) : null;

  return el(
    "section",
    { class: "content anesthesia-drug-card" },
    el("h1", {}, mod.title),
    el("p", { class: "adc-sub" },
      mod.tallManLetters ? el("strong", { class: "tall-man" }, mod.tallManLetters) : mod.title,
      mod.brandName ? el("span", { class: "muted" }, ` · ${mod.brandName}`) : null,
      el("span", { class: "muted" }, ` · ${mod.drugClassLabel}`)),
    el("p", { class: "purpose" }, mod.mechanism),
    el("div", { class: "adc-grid" },
      field("Onset", mod.onset),
      field("Duration", mod.duration),
      mod.reversal ? field("Reversal", mod.reversal) : null),
    el("div", {}, el("h3", {}, "Dosing"), el("pre", { class: "adc-dosing" }, mod.dosing)),
    list("Cautions", mod.cautions),
    list("Pearls", mod.pearls),
    lastVerified(mod)
  );
}

function renderProcedure(mod, route) {
  const isTree = mod.outputType === "decision-tree" && (mod.nodes || []).length > 0;
  return shell(
    mod,
    el("p", { class: "settings" }, `${mod.outputType}${mod.flags?.includes("stub") ? " · stub" : ""}`),
    !isTree && mod.entryPrompt ? el("p", { class: "entry-prompt" }, mod.entryPrompt) : null,
    isTree ? treeWalker(mod) : workflowList(mod),
    mod.checklist?.length ? el("div", {}, el("h3", {}, "Checklist"), el("ul", { class: "checklist" }, mod.checklist.map((c) => el("li", {}, el("label", {}, el("input", { type: "checkbox" }), " ", c))))) : null,
    mod.noteTemplate ? noteTemplateForm(mod, route) : null,
    mod.crossLinks?.length ? el("p", { class: "muted" }, "Orchestrates: " + mod.crossLinks.join(", ")) : null
  );
}

function workflowList(mod) {
  if (!mod.nodes?.length) return null;
  return el("ol", { class: "nodes" }, mod.nodes.map((n) =>
    el("li", { class: `node ${n.type}` },
      n.prompt ? el("strong", {}, n.prompt) : null,
      n.body ? el("p", {}, n.body) : null)
  ));
}

/** Interactive walk of a decision-tree procedure. */
function treeWalker(mod) {
  const byId = Object.fromEntries(mod.nodes.map((n) => [n.id, n]));
  const startId = byId.start ? "start" : (mod.nodes.find((n) => n.type === "question") || mod.nodes[0]).id;
  const container = el("div", { class: "tree-walker" });
  let path = [startId];

  function render() {
    const node = byId[path[path.length - 1]];
    const crumbs = el("div", { class: "tree-crumbs" }, path.map((id, i) => {
      const n = byId[id];
      const label = n.prompt || n.body?.slice(0, 24) || id;
      return el("span", {}, i > 0 ? " › " : "", i < path.length - 1
        ? el("a", { href: "#", onClick: (e) => { e.preventDefault(); path = path.slice(0, i + 1); render(); } }, label)
        : label);
    }));
    const bodyEls = [
      node.prompt ? el("h3", {}, node.prompt) : null,
      node.body ? el("p", { class: `node ${node.type}` }, node.body) : null,
    ];
    if (node.choices?.length) {
      bodyEls.push(el("div", { class: "opts" }, node.choices.map((c) =>
        el("button", { type: "button", class: "opt", onClick: () => { path = [...path, c.next]; render(); } }, c.label)
      )));
    } else {
      bodyEls.push(el("p", { class: "muted" }, "End of this branch."));
    }
    const nav = el("div", { class: "toolbar" },
      path.length > 1 ? el("button", { type: "button", class: "clear-all", onClick: () => { path = path.slice(0, -1); render(); } }, "‹ Back") : null,
      path.length > 1 ? el("button", { type: "button", class: "clear-all", onClick: () => { path = [startId]; render(); } }, "Start over") : null
    );
    container.replaceChildren(crumbs, ...bodyEls.filter(Boolean), nav);
  }
  render();
  return container;
}

/** Fill {{placeholders}} in the note template from a small form. */
function noteTemplateForm(mod, route) {
  const keys = [...new Set([...mod.noteTemplate.matchAll(/\{\{(\w+)\}\}/g)].map((m) => m[1]))];
  const saved = session.get(route);
  const state = { ...(saved.note || {}) };
  const out = el("pre", { class: "note-template" });
  function fill() {
    session.patch(route, { note: state });
    out.textContent = mod.noteTemplate.replace(/\{\{(\w+)\}\}/g, (_, k) => state[k] || `{{${k}}}`);
  }
  const grid = el("div", { class: "field-grid" }, keys.map((k) =>
    el("label", { class: "field" },
      el("span", { class: "field-label" }, k),
      el("span", { class: "field-input" }, el("input", {
        type: "text", value: state[k] || "",
        onInput: (e) => { state[k] = e.target.value; fill(); },
      })))
  ));
  fill();
  return el("div", {}, el("h3", {}, "Procedure note"), grid, out);
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
            el("strong", {}, dose.amountHigh != null && dose.amountHigh !== dose.amount
              ? `${dose.amount}–${dose.amountHigh} ${dose.unit}`
              : `${dose.amount} ${dose.unit}`),
            dose.volumeMl != null ? el("span", {}, dose.volumeMlHigh != null && dose.volumeMlHigh !== dose.volumeMl
              ? ` = ${dose.volumeMl}–${dose.volumeMlHigh} mL${dose.concentration ? ` (${dose.concentration})` : ""}`
              : ` = ${dose.volumeMl} mL${dose.concentration ? ` (${dose.concentration})` : ""}`) : null,
            dose.capped ? el("span", { class: "flag" }, " max-dose cap") : null,
            dose.floored ? el("span", { class: "flag" }, " min-dose floor") : null),
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
    mod.sourceOfTruth?.length ? el("p", { class: "muted" }, "Defers to: " + mod.sourceOfTruth.join(", ")) : null,
    mod.body?.length ? el("div", { class: "prose" }, ...renderBlocks(mod.body)) : null
  );
}
