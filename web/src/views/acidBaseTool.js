// Acid-Base Analyzer — the code-backed calculator (engine: "builtin",
// tool: "acid-base"). Math lives in lib/acidBaseEngine.js (golden-vector
// tested); every string shown here comes from mod.toolContent. Mirrors
// ios/Sources/Views/AcidBaseToolView.swift. Reuses the axis tool's styles.
import { el, lastVerified, sourcesBlock, tintStyle } from "../components.js";
import { interpret } from "../lib/acidBaseEngine.js";
import { session } from "../lib/session.js";
import { richText } from "./prose.js";

const FIELDS = ["ph", "paco2", "hco3", "na", "cl", "albumin"];
/** Accepts "7.32", "7,32"; blank → null. */
const num = (s) => {
  const t = String(s ?? "").trim().replace(",", ".");
  if (t === "") return null;
  const n = Number(t);
  return Number.isFinite(n) ? n : null;
};
const fmt = (v) => (v == null ? "—" : String(v));

export function renderAcidBaseTool(mod, route) {
  const C = mod.toolContent;
  const saved = session.get(route).abg || {};
  const st = { chronicity: saved.chronicity || "unknown" };
  for (const k of FIELDS) st[k] = saved[k] ?? "";
  const save = () => session.patch(route, { abg: { ...st } });

  const fields = el("div", { class: "axis-panel" });
  const out = el("div", { class: "axis-out", "aria-live": "polite" });
  const section = el("section", { class: "content calculator axis-tool abg-tool", style: tintStyle(mod) });

  // ---------------------------------------------------------------- inputs
  function field(key) {
    const def = C.fields[key];
    const id = `abg-${key}`;
    return el("div", { class: "axis-field" },
      el("label", { class: "field-label", for: id }, def.label, def.unit ? el("span", { class: "unit" }, ` ${def.unit}`) : null),
      el("span", { class: "axis-field-row" },
        el("input", { id, type: "text", inputmode: "decimal", autocomplete: "off", spellcheck: "false", value: st[key],
          "aria-describedby": def.help ? `${id}-help` : null,
          onInput: (e) => { st[key] = e.target.value; compute(); } })),
      def.help ? el("span", { class: "muted abg-help", id: `${id}-help` }, def.help) : null);
  }

  function renderFields() {
    const chron = el("div", { class: "abg-chron" },
      el("span", { class: "field-label" }, C.chronicity.label),
      el("div", { class: "axis-seg", role: "group", "aria-label": C.chronicity.label },
        ["unknown", "acute", "chronic"].map((v) => el("button", {
          type: "button", class: "axis-seg-btn" + (st.chronicity === v ? " selected" : ""), "aria-pressed": String(st.chronicity === v),
          onClick: () => { st.chronicity = v; renderFields(); compute(); },
        }, C.chronicity.options[v]))),
      el("span", { class: "muted abg-help" }, C.chronicity.help));
    fields.replaceChildren(
      el("div", { class: "axis-prt-fields" }, field("ph"), field("paco2"), field("hco3")),
      el("div", { class: "axis-prt-fields abg-lytes" }, field("na"), field("cl"), field("albumin")),
      chron);
  }

  // ---------------------------------------------------------------- compute
  function compute() {
    save();
    const input = { chronicity: st.chronicity };
    for (const k of FIELDS) input[k] = num(st[k]);
    const r = interpret(input);
    if (r.status === "incomplete") return out.replaceChildren(msg(C.statusMessages.incomplete, "muted"));
    if (r.status === "error") return out.replaceChildren(msg(C.statusMessages.errors[r.error] || r.error, "sev-moderate"));
    out.replaceChildren(...resultBlocks(r));
  }

  function msg(text, cls) { return el("p", { class: `axis-msg band ${cls}` }, text); }
  const disorderLabel = (d) => C.primary[d]?.label || d;

  function resultBlocks(r) {
    const kids = [];
    const p = C.primary[r.primary] || { label: r.primary, detail: "" };
    const sev = r.phStatus !== "normal" ? "high" : r.disorders.length ? "moderate" : "low";
    // 1. Headline: primary disorder + pH status
    kids.push(el("div", { class: `axis-headline band sev-${sev}` },
      el("span", { class: "axis-kicker" }, `pH ${fmt(num(st.ph))}`),
      el("strong", { class: "axis-cat abg-primary" }, p.label),
      el("span", { class: "axis-sub" }, C.phStatus[r.phStatus]),
      el("span", { class: "muted axis-sub" }, p.detail)));
    if (r.disorders.length > 1) {
      kids.push(el("div", { class: "axis-line band sev-high" },
        el("span", { class: "axis-line-label" }, "Disorders present"),
        el("strong", {}, r.disorders.map(disorderLabel).join(" + "))));
    }
    // 2. Compensation
    if (r.compensation) kids.push(compensationBlock(r.compensation));
    // 3. Anion gap + delta ratio
    if (r.ag) {
      const corrected = r.ag.corrected != null && r.ag.corrected !== r.ag.value;
      kids.push(el("div", { class: `axis-line band sev-${r.ag.key === "high" ? "high" : "low"}` },
        el("span", { class: "axis-line-label" }, C.anionGap.label),
        el("strong", {}, corrected ? `${r.ag.corrected} (measured ${r.ag.value})` : String(r.ag.value)),
        el("span", {}, r.ag.key === "high" ? C.anionGap.high : C.anionGap.normal),
        corrected ? el("span", { class: "muted axis-line-detail" }, C.anionGap.correctedNote) : null));
    }
    if (r.deltaRatio) {
      kids.push(el("div", { class: `axis-line band sev-${r.deltaRatio.key === "hagma" ? "low" : "moderate"}` },
        el("span", { class: "axis-line-label" }, C.deltaRatio.label),
        el("strong", {}, String(r.deltaRatio.value)),
        el("span", {}, C.deltaRatio.bands[r.deltaRatio.key]),
        el("span", { class: "muted axis-line-detail" }, C.deltaRatio.caution)));
    }
    // 4. Flags, warnings first
    const flags = [...r.flags].sort((a, b) => (C.flags[a]?.level === "warning" ? 0 : 1) - (C.flags[b]?.level === "warning" ? 0 : 1));
    for (const f of flags) {
      const def = C.flags[f];
      if (def) kids.push(el("div", { class: `axis-flag band ${def.level === "warning" ? "sev-high" : "sev-info"}` }, def.text));
    }
    // 5. Differentials
    for (const d of r.differentials) {
      const def = C.differentials[d];
      if (!def) continue;
      kids.push(el("details", { class: "axis-diff" }, el("summary", {}, def.title),
        el("ul", {}, def.items.map((i) => el("li", {}, i))),
        def.note ? el("p", { class: "muted" }, def.note) : null));
    }
    return kids;
  }

  function compensationBlock(c) {
    const rule = C.compensationRules[c.rule];
    const target = c.measured === "paco2" ? "PaCO₂" : "HCO₃⁻";
    const range = (b) => `${b.lo}–${b.hi}`;
    // Metabolic rules give one band; respiratory rules give acute and chronic.
    const exp = c.expected.acute ? `acute ${range(c.expected.acute)}, chronic ${range(c.expected.chronic)}` : range(c.expected);
    const good = c.key === "appropriate" || c.key.startsWith("fits") || c.key === "acute_or_chronic";
    return el("div", { class: `axis-line band sev-${good ? "low" : "moderate"}` },
      el("span", { class: "axis-line-label" }, rule?.label || c.rule),
      el("strong", {}, `Expected ${target} ${exp} · measured ${c.actual}`),
      el("span", {}, C.compensation[c.key] || c.key),
      rule ? el("span", { class: "muted axis-line-detail" }, rule.formula) : null);
  }

  // ---------------------------------------------------------------- mount
  renderFields();
  section.append(
    el("h1", {}, mod.title),
    richText(mod.purpose, "purpose"),
    fields, out,
    el("details", { class: "axis-why" }, el("summary", {}, "Why this matters"), richText(C.whyThisMatters)),
    el("div", { class: "takeaway" }, el("h4", {}, "Clinical takeaway"), richText(C.clinicalTakeaway)),
    sourcesBlock(mod),
    lastVerified(mod),
  );
  compute();
  return section;
}
