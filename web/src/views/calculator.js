import { el, mount, clearableField, clearFieldsButton, lastVerified, severityClass } from "../components.js";
import { runCalculator } from "../lib/calcEngine.js";
import { session } from "../lib/session.js";

export function renderCalculator(mod, route) {
  const saved = session.get(route);
  const state = { items: saved.items || {}, inputs: saved.inputs || {} };

  const resultBox = el("div", { class: "result-box" });
  const container = el("section", { class: "content calculator" });

  function recompute() {
    session.patch(route, state);
    resultBox.replaceChildren(...resultView(mod, runCalculator(mod, state)));
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
      container.querySelectorAll(".opt.selected").forEach((b) => b.classList.remove("selected"));
      recompute();
    })),
    resultBox,
    mod.notes ? el("p", { class: "notes" }, mod.notes) : null,
    mod.buildNote ? el("details", { class: "build-note" }, el("summary", {}, "Build note"), el("p", {}, mod.buildNote)) : null,
    sourcesList(mod),
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

function flagsBanner(mod) {
  if (!mod.flags?.length) return null;
  return el("p", { class: "flags" }, mod.flags.map((f) => el("span", { class: "flag" }, f)));
}
function sourcesList(mod) {
  if (!mod.sources?.length) return null;
  return el("details", { class: "sources" }, el("summary", {}, "Sources"), el("ul", {}, mod.sources.map((s) => el("li", {}, s))));
}
function fmtPts(p) {
  return (p > 0 ? "+" : "") + p;
}
