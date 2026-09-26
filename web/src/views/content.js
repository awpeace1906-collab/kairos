import { el, mount, clearableField, lastVerified, sourcesBlock, tintStyle } from "../components.js";
import { renderCalculator } from "./calculator.js";
import { zoneForWeight, doseFromRule, estimateWeight, obesityCheck } from "../lib/weightZones.js";
import { session } from "../lib/session.js";
import { assetUrl } from "../lib/contentStore.js";
import { renderList, renderTable, richText } from "./prose.js";

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
    { class: `content ${mod.contentType}`, style: tintStyle(mod) },
    el("h1", {}, mod.title),
    richText(mod.summary, "purpose"),
    richText(mod.purpose, "purpose"),
    ...body,
    mod.buildNote ? el("details", { class: "build-note" }, el("summary", {}, "Build note"), el("p", {}, mod.buildNote)) : null,
    sourcesBlock(mod),
    lastVerified(mod)
  );
}

/** Semantic diagram tokens -> CSS custom properties, so a figure stays legible
    in both themes (styles.css defines the light/dark values). Never raw hex in
    content. Mirrors DiagramView.swift's `color(_:)`. */
const DIAGRAM_TOKENS = {
  outline: "--dg-outline", surface: "--dg-surface", tissue: "--dg-tissue",
  bone: "--dg-bone", lumen: "--dg-lumen", muscle: "--dg-muscle",
  vessel: "--dg-vessel", accent: "--dg-accent", danger: "--dg-danger",
  warning: "--dg-warning", good: "--dg-good", muted: "--dg-muted", text: "--dg-text",
};
const dgColor = (tok) => (tok && DIAGRAM_TOKENS[tok] ? `var(${DIAGRAM_TOKENS[tok]})` : "none");

/** Build one SVG element (namespaced — `el()` makes HTML elements, which don't
    render inside an <svg>). */
function svgEl(tag, attrs, ...children) {
  const n = document.createElementNS("http://www.w3.org/2000/svg", tag);
  for (const [k, v] of Object.entries(attrs || {})) {
    if (v !== null && v !== undefined) n.setAttribute(k, String(v));
  }
  for (const c of children.flat()) if (c != null) n.appendChild(c);
  return n;
}

function diagramShape(s) {
  const common = {
    fill: dgColor(s.fill),
    stroke: dgColor(s.stroke),
    "stroke-width": s.strokeWidth ?? 1.5,
    "stroke-linecap": "round",
    "stroke-linejoin": "round",
    opacity: s.opacity,
  };
  if (s.dash) common["stroke-dasharray"] = "5 4";

  switch (s.kind) {
    case "path":
      return svgEl("path", { ...common, d: s.d });
    case "line":
      return svgEl("line", { ...common, x1: s.from?.[0], y1: s.from?.[1], x2: s.to?.[0], y2: s.to?.[1], fill: "none" });
    case "polyline":
      return svgEl("polyline", { ...common, fill: dgColor(s.fill), points: (s.points || []).map((p) => p.join(",")).join(" ") });
    case "rect":
      return svgEl("rect", { ...common, x: s.at?.[0], y: s.at?.[1], width: s.size?.[0], height: s.size?.[1], rx: s.rx });
    case "circle":
      return svgEl("circle", { ...common, cx: s.at?.[0], cy: s.at?.[1], r: s.r });
    case "ellipse":
      return svgEl("ellipse", { ...common, cx: s.at?.[0], cy: s.at?.[1], rx: s.rx, ry: s.ry });
    case "arrow": {
      // Head drawn as a filled triangle rather than a <marker>, so its color
      // follows the same token and no shared <defs> id can collide.
      const [x1, y1] = s.from || [0, 0], [x2, y2] = s.to || [0, 0];
      const a = Math.atan2(y2 - y1, x2 - x1), h = 7, w = 3.6;
      const tip = [x2, y2];
      const back = [x2 - h * Math.cos(a), y2 - h * Math.sin(a)];
      const left = [back[0] + w * Math.sin(a), back[1] - w * Math.cos(a)];
      const right = [back[0] - w * Math.sin(a), back[1] + w * Math.cos(a)];
      return svgEl(
        "g", {},
        svgEl("line", { ...common, x1, y1, x2: back[0], y2: back[1], fill: "none" }),
        svgEl("polygon", { points: [tip, left, right].map((p) => p.join(",")).join(" "), fill: dgColor(s.stroke), opacity: s.opacity })
      );
    }
    case "text":
      return svgEl(
        "text",
        {
          x: s.at?.[0], y: s.at?.[1],
          "font-size": s.fontSize ?? 11,
          "font-weight": s.weight === "bold" ? 600 : 400,
          "text-anchor": s.anchor || "start",
          fill: dgColor(s.fill || "text"),
          stroke: "none",
          opacity: s.opacity,
        },
        document.createTextNode(s.text || "")
      );
    default:
      return null;
  }
}

/** Render a `diagram` — an original declarative vector figure. Mirrors the iOS
    DiagramView; see common.schema.json#/$defs/diagram. */
export function renderDiagram(d) {
  if (!d || !Array.isArray(d.viewBox) || !Array.isArray(d.shapes)) return null;
  const img = d.image;
  // A background plate is drawn first so every shape sits on top of it, in
  // the plate's own pixel coordinates (see common.schema.json#/$defs/diagram).
  const plate = img
    ? svgEl("image", {
        href: assetUrl(img.src),
        x: img.at?.[0] ?? 0,
        y: img.at?.[1] ?? 0,
        width: img.width,
        height: img.height,
        preserveAspectRatio: "none",
      })
    : null;
  const svg = svgEl(
    "svg",
    {
      viewBox: d.viewBox.join(" "),
      class: img ? "diagram-svg diagram-svg--plate" : "diagram-svg",
      role: "img",
      "aria-label": d.title || d.caption || "clinical diagram",
      preserveAspectRatio: "xMidYMid meet",
    },
    plate,
    d.shapes.map(diagramShape)
  );
  return el(
    "figure",
    { class: img ? "diagram diagram--plate" : "diagram" },
    d.title ? el("figcaption", { class: "diagram-title" }, d.title) : null,
    svg,
    d.caption ? el("p", { class: "diagram-caption" }, d.caption) : null,
    img ? el("p", { class: "diagram-credit" }, img.credit) : null
  );
}

/** Shared renderer for the `body` block array used by reference and peds-tool modules. */
export function renderBlocks(body) {
  return (body || []).map((b) => {
    switch (b.type) {
      case "heading":
        return el(`h${b.level || 2}`, {}, b.text);
      case "text":
        return richText(b.text);
      case "list":
        return renderList(b.items, b.ordered);
      case "callout":
        return el("div", { class: `callout ${b.tone || "info"}` }, richText(b.text));
      case "diagram":
        return renderDiagram(b.diagram);
      case "table":
        return renderTable(b.columns, b.rows);
      default:
        return null;
    }
  });
}

function renderReference(mod) {
  return shell(
    mod,
    mod.whyThisMatters ? el("div", { class: "why-matters" }, el("h4", {}, "Why this matters"), richText(mod.whyThisMatters)) : null,
    el("div", { class: "prose" }, ...renderBlocks(mod.body)),
    mod.clinicalTakeaway ? el("div", { class: "takeaway" }, el("h4", {}, "Clinical takeaway"), richText(mod.clinicalTakeaway)) : null
  );
}

/** AnesCalc-origin anesthesia drug card — prose reference, no live math. */
function renderAnesthesiaDrugCard(mod) {
  const field = (label, value) =>
    value ? el("div", { class: "adc-field" }, el("span", { class: "adc-label" }, label), el("span", {}, value)) : null;
  const list = (label, items) =>
    items?.length ? el("div", {}, el("h3", {}, label), el("ul", {}, items.map((i) => el("li", {}, richText(i))))) : null;
  const dosingRows = (text) => {
    if (!text) return null;
    return el(
      "div",
      {},
      text.split("\n").filter(Boolean).map((line) => {
        const i = line.indexOf(": ");
        return i === -1
          ? el("div", { class: "dose-row" }, el("div", { class: "dose-amt" }, line))
          : el(
              "div",
              { class: "dose-row" },
              el("div", { class: "dose-ind" }, line.slice(0, i)),
              el("div", { class: "dose-amt" }, line.slice(i + 2))
            );
      })
    );
  };

  return el(
    "section",
    { class: "content anesthesia-drug-card", style: tintStyle(mod) },
    el("h1", {}, mod.title),
    el("p", { class: "adc-sub" },
      mod.tallManLetters ? el("strong", { class: "tall-man" }, mod.tallManLetters) : mod.title,
      mod.brandName ? el("span", { class: "muted" }, ` · ${mod.brandName}`) : null,
      el("span", { class: "muted" }, ` · ${mod.drugClassLabel}`)),
    richText(mod.mechanism, "purpose"),
    el("div", { class: "adc-grid" },
      field("Onset", mod.onset),
      field("Duration", mod.duration),
      mod.reversal ? field("Reversal", mod.reversal) : null),
    el("div", {}, el("h3", {}, "Dosing"), dosingRows(mod.dosing)),
    list("Cautions", mod.cautions),
    list("Pearls", mod.pearls),
    sourcesBlock(mod),
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
  let stepNum = 0;
  return el("ol", { class: "nodes" }, mod.nodes.map((n) => {
    const isWarning = n.type === "warning";
    if (!isWarning) stepNum++;
    return el(
      "li",
      { class: `node ${n.type}` },
      el("span", { class: "node-badge", "aria-hidden": "true" }, isWarning ? "!" : String(stepNum)),
      el(
        "div",
        { class: "node-body" },
        n.prompt ? el("strong", {}, n.prompt) : null,
        richText(n.body),
        n.substeps ? renderList(n.substeps.items, n.substeps.ordered) : null,
        n.diagram ? renderDiagram(n.diagram) : null
      )
    );
  }));
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
      richText(node.body, `node ${node.type}`),
      node.substeps ? renderList(node.substeps.items, node.substeps.ordered) : null,
      node.diagram ? renderDiagram(node.diagram) : null,
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
  const state = { weight: saved.weight ?? "", ageYears: saved.ageYears ?? "", obeseOverride: saved.obeseOverride ?? false };
  const out = el("div", { class: "dose-output" });
  const zoneBar = el("div", { class: "zone-bar" });
  const cfg = store.weightZones;

  function recompute() {
    session.patch(route, state);
    const actualKg = parseFloat(state.weight);
    let weightKg = actualKg;
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

    // Obese-child IBW check (Drug_Dosing_Peds_Weight_Based_Spec.md). Needs an
    // actual weight AND an age; only acts when this drug opts in via obeseWeightBasis.
    const ob = (mod.obeseWeightBasis && state.ageYears !== "")
      ? obesityCheck(cfg, actualKg, { ageYears: parseFloat(state.ageYears) })
      : null;
    let dosingKg = weightKg;
    let obeseNote = null;
    if (ob?.flagged && mod.obeseWeightBasis === "ideal") {
      dosingKg = state.obeseOverride ? actualKg : ob.ibwKg;
      obeseNote = el("div", { class: "callout warning" },
        el("strong", {}, "Obesity flag — dosing from ideal body weight. "),
        `Entered weight ${actualKg} kg is ~${ob.pctOver}% above the age-expected weight (${ob.ibwKg} kg). This drug is hydrophilic — actual-weight dosing risks overdose. Doses below use ${state.obeseOverride ? `actual weight (${actualKg} kg)` : `${ob.ibwKg} kg`}. `,
        el("button", { type: "button", class: "clear-all",
          onClick: () => { state.obeseOverride = !state.obeseOverride; recompute(); } },
          state.obeseOverride ? "Use ideal body weight" : "Use actual weight instead"));
    } else if (ob?.flagged && mod.obeseWeightBasis === "actual") {
      obeseNote = el("div", { class: "callout info" },
        `Entered weight is ~${ob.pctOver}% above the age-expected weight, but this drug is dosed by total (actual) body weight even in obesity — no adjustment.`);
    }

    const zone = zoneForWeight(cfg, weightKg);
    zoneBar.replaceChildren(
      el("span", { class: "zone-chip" },
        zone.colorHex ? el("i", { class: "zone-dot", style: `background:${zone.colorHex}` }) : null,
        `Zone ${zone.zone} · ${zone.color}`),
      el("span", { class: "zone-weight" }, `${weightKg} kg${estimated ? " (estimated)" : ""}`),
      el("span", { class: "zone-equip" }, `ETT ${zone.equipment.ettUncuffed} · LMA ${zone.equipment.lma} · ${zone.equipment.blade}`)
    );
    out.replaceChildren(...[
      obeseNote,
      ...mod.doses.map((d) => {
        const dose = doseFromRule(d.rule, dosingKg);
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
          richText(d.notes, "muted")
        );
      }),
      el("p", { class: "disclaimer" }, cfg.disclaimer)
    ].filter(Boolean));
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
    const intro = mount(el("div"), richText(mod.purpose, "purpose"), mod.ageRange ? el("p", { class: "muted" }, mod.ageRange) : null);
    node.prepend(...intro.childNodes);
    // A peds-tool may carry an explanatory body alongside its calculator
    // (matches the iOS PedsToolBody behavior).
    if (mod.body?.length) node.append(el("div", { class: "prose" }, ...renderBlocks(mod.body)));
    return node;
  }
  return shell(
    mod,
    el("p", { class: "settings" }, mod.kind),
    mod.ageRange ? el("p", { class: "muted" }, mod.ageRange) : null,
    mod.sourceOfTruth?.length ? el("p", { class: "muted" }, "Defers to: " + mod.sourceOfTruth.join(", ")) : null,
    mod.body?.length ? el("div", { class: "prose" }, ...renderBlocks(mod.body)) : null
  );
}
