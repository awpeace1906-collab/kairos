import { el, mount, clearableField, clearFieldsButton, lastVerified, severityClass, sourcesBlock, tintStyle } from "../components.js";
import { runCalculator } from "../lib/calcEngine.js";
import { evaluate } from "../lib/expr.js";
import { session } from "../lib/session.js";

export function renderCalculator(mod, route) {
  const saved = session.get(route);
  const state = { items: saved.items || {}, inputs: saved.inputs || {} };

  const resultBox = el("div", { class: "result-box" });
  const plotBox = el("div", { class: "plot-box" });
  const container = el("section", { class: "content calculator", style: tintStyle(mod) });

  function recompute() {
    session.patch(route, state);
    resultBox.replaceChildren(...resultView(mod, runCalculator(mod, state)));
    if (mod.plot) plotBox.replaceChildren(nomogram(mod.plot, state.inputs));
  }

  mount(
    container,
    el("h1", {}, mod.title),
    mod.settings?.length ? el("p", { class: "settings" }, mod.settings.join(" · ")) : null,
    el("p", { class: "purpose" }, mod.purpose),
    flagsBanner(mod)
  );

  if (mod.engine === "additive") {
    for (const item of mod.items) {
      container.append(additiveItem(item, state.items[item.key], (idx) => {
        state.items[item.key] = idx;
        recompute();
      }));
    }
  } else if (mod.engine === "formula" || mod.engine === "external") {
    const grid = el("div", { class: "field-grid" });
    for (const inp of mod.inputs || []) {
      if (inp.type === "select") {
        const sel = el(
          "select",
          {
            onChange: (e) => {
              state.inputs[inp.key] = e.target.value;
              recompute();
            },
          },
          el("option", { value: "" }, "—"),
          (inp.options || []).map((o) =>
            el("option", { value: String(o.value), selected: String(state.inputs[inp.key]) === String(o.value) }, o.label)
          )
        );
        grid.append(el("label", { class: "field" }, el("span", { class: "field-label" }, inp.label), el("span", { class: "field-input" }, sel)));
        continue;
      }
      grid.append(
        clearableField({
          id: `f-${inp.key}`,
          label: inp.label,
          unit: inp.unit,
          type: inp.type === "boolean" ? "checkbox" : "number",
          value: state.inputs[inp.key] ?? "",
          min: inp.min,
          max: inp.max,
          onInput: (v) => {
            state.inputs[inp.key] = v;
            recompute();
          },
          onClear: () => {
            delete state.inputs[inp.key];
            recompute();
          },
        })
      );
    }
    container.append(grid);
  } else if (mod.engine === "classification") {
    container.append(
      el(
        "ol",
        { class: "tiers" },
        mod.tiers.map((t) =>
          el("li", {}, el("strong", {}, t.label), " — ", t.description, t.mortality ? el("span", { class: "muted" }, ` (mortality: ${t.mortality})`) : null)
        )
      )
    );
  }

  mount(
    container,
    el("div", { class: "toolbar" }, clearFieldsButton(() => {
      session.clearScreen(route);
      state.items = {};
      state.inputs = {};
      container.querySelectorAll("input").forEach((i) => (i.value = ""));
      container.querySelectorAll("select").forEach((s) => (s.selectedIndex = 0));
      container.querySelectorAll(".opt.selected").forEach((b) => b.classList.remove("selected"));
      recompute();
    })),
    resultBox,
    mod.plot ? plotBox : null,
    mod.notes ? el("p", { class: "notes" }, mod.notes) : null,
    mod.buildNote ? el("details", { class: "build-note" }, el("summary", {}, "Build note"), el("p", {}, mod.buildNote)) : null,
    sourcesBlock(mod),
    lastVerified(mod)
  );

  recompute();
  return container;
}

function additiveItem(item, selectedIdx, onPick) {
  const opts = el(
    "div",
    { class: "opts" },
    item.options.map((o, i) =>
      el(
        "button",
        {
          type: "button",
          class: "opt" + (i === selectedIdx ? " selected" : ""),
          onClick: (e) => {
            e.currentTarget.parentElement.querySelectorAll(".opt").forEach((b) => b.classList.remove("selected"));
            e.currentTarget.classList.add("selected");
            onPick(i);
          },
        },
        el("span", {}, o.label),
        el("span", { class: "pts" }, fmtPts(o.points))
      )
    )
  );
  return el("fieldset", { class: "item" }, el("legend", {}, item.label), item.help ? el("p", { class: "help" }, item.help) : null, opts);
}

function resultView(mod, r) {
  if (r.engine === "additive") {
    if (r.incomplete) return [el("p", { class: "muted" }, `Answer all ${mod.items.length} items — ${r.answered} done`)];
    const band = r.bands[0];
    return [
      el("div", { class: "score" }, "Score ", el("strong", {}, String(r.score))),
      band
        ? el(
            "div",
            { class: `band ${severityClass(band.severity)}` },
            el("strong", {}, band.label),
            band.risk ? el("p", {}, band.risk) : null,
            band.disposition ? el("p", { class: "dispo" }, band.disposition) : null
          )
        : null,
    ];
  }
  if (r.engine === "formula") {
    if (!r.results.length) return [el("p", { class: "muted" }, "Enter values to compute")];
    return r.results.map((res) =>
      el(
        "div",
        { class: "formula-result" },
        el("span", { class: "flabel" }, res.label),
        el("strong", {}, `${res.value}${res.unit ? " " + res.unit : ""}`),
        (r.bandsByKey[res.key] || []).map((b) => el("p", { class: `band ${severityClass(b.severity)}` }, b.label))
      )
    );
  }
  if (r.engine === "classification") return [el("p", { class: "muted" }, "Pick the class that matches the exam.")];
  if (r.engine === "external")
    return [el("p", { class: "band sev-moderate" }, "This score has no open formula — structure and cutoff shown above. See build note.")];
  return [];
}

/* ---- Nomogram / 2-D plot (schema: calculator.plot) --------------------------
   Semi-log-Y plot: linear x, log10 y. Curve expressions are evaluated with the
   free variable `x`; the marker is read from the inputs named by plot.x.key /
   plot.y.key. Rendered as an inline SVG string so it re-themes via CSS vars. */
const esc = (s) => String(s).replace(/[&<>"]/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" }[c]));

function logTicks(min, max) {
  const out = [];
  for (let d = Math.floor(Math.log10(min)); d <= Math.ceil(Math.log10(max)); d++) {
    for (const m of [1, 2, 5]) {
      const v = m * 10 ** d;
      if (v >= min - 1e-9 && v <= max + 1e-9) out.push(v);
    }
  }
  return out;
}
const trimNum = (n) => (Math.abs(n) >= 100 ? Math.round(n) : +n.toFixed(1)).toString();

function nomogram(plot, inputs) {
  const W = 480, H = 320, L = 54, R = 16, T = 14, B = 42;
  const pw = W - L - R, ph = H - T - B;
  const { x: ax, y: ay } = plot;
  const lx = (v) => L + (pw * (v - ax.min)) / (ax.max - ax.min);
  const lgMin = Math.log10(ay.min), lgMax = Math.log10(ay.max);
  const ly = (v) => T + ph * (1 - (Math.log10(Math.max(v, ay.min)) - lgMin) / (lgMax - lgMin));

  const parts = [];
  // frame
  parts.push(`<rect x="${L}" y="${T}" width="${pw}" height="${ph}" fill="var(--surface)" stroke="var(--line)"/>`);
  // y grid + labels
  for (const v of logTicks(ay.min, ay.max)) {
    const y = ly(v);
    parts.push(`<line x1="${L}" y1="${y.toFixed(1)}" x2="${L + pw}" y2="${y.toFixed(1)}" stroke="var(--line)" stroke-width="1"/>`);
    parts.push(`<text x="${L - 6}" y="${(y + 3).toFixed(1)}" text-anchor="end" class="nom-tick">${trimNum(v)}</text>`);
  }
  // x grid + labels
  const xStep = (ax.max - ax.min) / 5;
  for (let i = 0; i <= 5; i++) {
    const v = ax.min + i * xStep, x = lx(v);
    parts.push(`<line x1="${x.toFixed(1)}" y1="${T}" x2="${x.toFixed(1)}" y2="${T + ph}" stroke="var(--line)" stroke-width="1"/>`);
    parts.push(`<text x="${x.toFixed(1)}" y="${T + ph + 16}" text-anchor="middle" class="nom-tick">${trimNum(v)}</text>`);
  }
  // axis titles
  parts.push(`<text x="${L + pw / 2}" y="${H - 4}" text-anchor="middle" class="nom-axis">${esc(ax.label)}${ax.unit ? " (" + esc(ax.unit) + ")" : ""}</text>`);
  parts.push(`<text x="12" y="${T + ph / 2}" text-anchor="middle" class="nom-axis" transform="rotate(-90 12 ${T + ph / 2})">${esc(ay.label)}${ay.unit ? " (" + esc(ay.unit) + ")" : ""}</text>`);

  // curves
  const toneStroke = { accent: "var(--accent)", muted: "var(--muted)", danger: "var(--sev-high)" };
  for (const c of plot.curves) {
    const pts = [];
    for (let i = 0; i <= 100; i++) {
      const xv = ax.min + (i / 100) * (ax.max - ax.min);
      let yv;
      try { yv = evaluate(c.expression, { x: xv }); } catch { yv = NaN; }
      if (!Number.isFinite(yv) || yv < ay.min || yv > ay.max) { if (pts.length) parts.push(`<polyline points="${pts.join(" ")}" fill="none" stroke="${toneStroke[c.tone] || "var(--sev-high)"}" stroke-width="2"/>`), pts.length = 0; continue; }
      pts.push(`${lx(xv).toFixed(1)},${ly(yv).toFixed(1)}`);
    }
    if (pts.length) parts.push(`<polyline points="${pts.join(" ")}" fill="none" stroke="${toneStroke[c.tone] || "var(--sev-high)"}" stroke-width="2"/>`);
    // label near right end of curve
    let lyEnd; try { lyEnd = evaluate(c.expression, { x: ax.max }); } catch { lyEnd = null; }
    if (Number.isFinite(lyEnd) && lyEnd >= ay.min && lyEnd <= ay.max)
      parts.push(`<text x="${(L + pw - 4).toFixed(1)}" y="${(ly(lyEnd) - 6).toFixed(1)}" text-anchor="end" class="nom-curve">${esc(c.label)}</text>`);
  }

  // marker from inputs
  const px = Number(inputs[ax.key]), py = Number(inputs[ay.key]);
  let sub = "Enter a level and a time to plot the point.";
  if (Number.isFinite(px) && Number.isFinite(py) && px >= ax.min && px <= ax.max && py > 0) {
    const cx = lx(px), cy = ly(Math.min(py, ay.max));
    let above = false;
    try { above = py >= evaluate(plot.curves[0].expression, { x: px }); } catch {}
    const col = above ? "var(--sev-high)" : "var(--sev-low)";
    parts.push(`<line x1="${L}" y1="${cy.toFixed(1)}" x2="${cx.toFixed(1)}" y2="${cy.toFixed(1)}" stroke="${col}" stroke-width="1" stroke-dasharray="3 3"/>`);
    parts.push(`<line x1="${cx.toFixed(1)}" y1="${(T + ph).toFixed(1)}" x2="${cx.toFixed(1)}" y2="${cy.toFixed(1)}" stroke="${col}" stroke-width="1" stroke-dasharray="3 3"/>`);
    parts.push(`<circle cx="${cx.toFixed(1)}" cy="${cy.toFixed(1)}" r="4.5" fill="${col}" stroke="var(--surface)" stroke-width="1.5"/>`);
    sub = above
      ? `Point is on or above the ${esc(plot.curves[0].label.toLowerCase())} — treatment indicated.`
      : `Point is below the ${esc(plot.curves[0].label.toLowerCase())}.`;
  }

  const fig = el("figure", { class: "nomogram" });
  fig.innerHTML =
    `<svg viewBox="0 0 ${W} ${H}" role="img" aria-label="${esc(plot.caption || "Nomogram")}">${parts.join("")}</svg>` +
    `<figcaption>${plot.caption ? esc(plot.caption) + " — " : ""}${sub}</figcaption>`;
  return fig;
}

function flagsBanner(mod) {
  if (!mod.flags?.length) return null;
  return el("p", { class: "flags" }, mod.flags.map((f) => el("span", { class: "flag" }, f)));
}
function fmtPts(p) {
  return (p > 0 ? "+" : "") + p;
}
