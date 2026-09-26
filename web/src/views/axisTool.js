// EKG Axis Interpreter — the code-backed calculator (engine: "builtin",
// tool: "ekg-axis"). Math lives in lib/axisEngine.js (golden-vector tested);
// every string shown here comes from mod.toolContent. Mirrors
// ios/Sources/Views/AxisToolView.swift.
import { el, lastVerified, sourcesBlock, tintStyle } from "../components.js";
import { interpret, parsePRT } from "../lib/axisEngine.js";
import { session } from "../lib/session.js";
import { richText } from "./prose.js";

const LEADS = ["I", "II", "III", "aVR", "aVL", "aVF"];
const SEV = { normal: "low", borderline: "moderate", abnormal: "high" };
const deg = (v) => `${v > 0 ? "+" : v < 0 ? "−" : ""}${Math.abs(Math.round(v))}°`;
/** Accepts "-42", "−42", "42.5", "42,5"; blank → null. */
const num = (s) => {
  const t = String(s ?? "").trim().replace(/[−–—]/g, "-").replace(",", ".");
  if (t === "" || t === "-") return null;
  const n = Number(t);
  return Number.isFinite(n) ? n : null;
};

export function renderAxisTool(mod, route) {
  const C = mod.toolContent;
  const saved = session.get(route).axis || {};
  // Machine (P-R-T) is where the screen opens, every time; fields are remembered.
  const st = {
    mode: C.modes.find((m) => m.default)?.id || C.modes[0].id,
    prtText: saved.prtText || "",
    p: saved.p ?? "", qrs: saved.qrs ?? "", t: saved.t ?? "",
    pol: saved.pol || {},
    amps: saved.amps || {},
    peds: !!saved.peds, ageVal: saved.ageVal ?? "", ageUnit: saved.ageUnit || "y",
    mods: saved.mods || {},
  };
  const save = () => {
    const { mode, ...rest } = st;
    session.patch(route, { axis: rest });
  };

  const modeBar = el("div", { class: "axis-modes", role: "tablist" });
  const panel = el("div", { class: "axis-panel" });
  const shared = el("div", { class: "axis-shared" });
  const out = el("div", { class: "axis-out", "aria-live": "polite" });
  const section = el("section", { class: "content calculator axis-tool", style: tintStyle(mod) });

  function modeDef() { return C.modes.find((m) => m.id === st.mode); }

  function ageDays() {
    if (!st.peds) return null;
    const v = num(st.ageVal);
    if (v == null || v < 0) return null;
    return st.ageUnit === "d" ? v : st.ageUnit === "m" ? v * 30.4375 : v * 365;
  }

  // ---------------------------------------------------------------- inputs
  let fieldSeq = 0;
  function signedField({ label, unit, value, placeholder, onChange }) {
    const id = `axis-f-${label.replace(/\W/g, "")}-${++fieldSeq}`;
    const input = el("input", {
      id, type: "text", inputmode: "decimal", autocomplete: "off", spellcheck: "false",
      value: value ?? "", placeholder: placeholder || "",
      "aria-label": label,
      onInput: (e) => onChange(e.target.value),
    });
    const toggle = () => {
      const n = num(input.value);
      if (n == null || n === 0) { input.value = input.value.startsWith("-") ? input.value.slice(1) : "-" + input.value; }
      else input.value = String(-n);
      onChange(input.value);
    };
    // iPhone decimal keypads have no minus key, so this button is the only way
    // to go negative. While the field has focus, handle the tap at touchend and
    // cancel it: that keeps focus in the field (no keypad drop and bounce) and
    // suppresses the follow-up click. Pointerdown is cancelled for mouse and
    // Android, which blur on the compatibility mousedown instead.
    const flip = el("button", {
      type: "button", class: "axis-sign", "aria-label": `Toggle sign of ${label}`,
      onPointerdown: (e) => { if (document.activeElement === input) e.preventDefault(); },
      onTouchend: (e) => { if (document.activeElement === input) { e.preventDefault(); toggle(); } },
      onClick: () => { toggle(); input.focus(); },
    }, "±");
    // A wrapping <label> would bind to the ± button (the first labelable
    // child), so tapping the caption flipped the sign. Point it at the input.
    return el("div", { class: "axis-field" },
      el("label", { class: "field-label", for: id }, label),
      el("span", { class: "axis-field-row" }, flip, input, unit ? el("span", { class: "unit" }, unit) : null));
  }

  function renderModes() {
    modeBar.replaceChildren(...C.modes.map((m) =>
      el("button", {
        type: "button", role: "tab", class: "axis-mode" + (m.id === st.mode ? " selected" : ""),
        "aria-selected": String(m.id === st.mode),
        onClick: () => { st.mode = m.id; renderModes(); renderPanel(); compute(); },
      }, m.label)));
  }

  function renderPanel() {
    const m = modeDef();
    const kids = [el("p", { class: "help" }, m.help)];
    if ((m.engineMode || "prt") === "prt") {
      const fields = el("div", { class: "axis-prt-fields" });
      const drawFields = () => fields.replaceChildren(
        signedField({ label: "P", unit: "°", value: st.p, onChange: (v) => { st.p = v; compute(); } }),
        signedField({ label: "QRS", unit: "°", value: st.qrs, onChange: (v) => { st.qrs = v; compute(); } }),
        signedField({ label: "T", unit: "°", value: st.t, onChange: (v) => { st.t = v; compute(); } }));
      drawFields();
      const paste = el("input", {
        type: "text", class: "axis-paste", value: st.prtText, autocomplete: "off", spellcheck: "false",
        placeholder: "P-R-T axes 54 −42 38", "aria-label": "Paste machine axes",
        onInput: (e) => {
          st.prtText = e.target.value;
          const r = parsePRT(st.prtText);
          if (r.ok) {
            st.p = r.p == null ? "" : String(r.p);
            st.qrs = String(r.qrs);
            st.t = r.t == null ? "" : String(r.t);
            drawFields();
          }
          compute();
        },
      });
      kids.push(paste, fields);
    } else if (m.engineMode === "polarity") {
      const sel = (st.pol[m.id] ||= {});
      kids.push(el("div", { class: "axis-leads" }, m.leads.map((lead) =>
        el("div", { class: "axis-lead" },
          el("span", { class: "axis-lead-name" }, lead),
          el("div", { class: "axis-seg", role: "group", "aria-label": `Lead ${lead} QRS polarity` },
            [["pos", "+"], ["iso", "equiphasic"], ["neg", "−"]].map(([v, text]) =>
              el("button", {
                type: "button", class: "axis-seg-btn" + (sel[lead] === v ? " selected" : ""),
                "aria-pressed": String(sel[lead] === v),
                onClick: () => { if (sel[lead] === v) delete sel[lead]; else sel[lead] = v; renderPanel(); compute(); },
              }, text)))))));
    } else {
      kids.push(el("div", { class: "axis-amps" }, m.leads.map((lead) =>
        signedField({ label: lead, unit: "mm", value: st.amps[lead], onChange: (v) => { st.amps[lead] = v; compute(); } }))));
    }
    panel.replaceChildren(...kids);
  }

  function renderShared() {
    const ageRow = el("div", { class: "axis-age" },
      el("div", { class: "axis-seg", role: "group", "aria-label": "Patient age group" },
        [[false, "Adult"], [true, "Peds"]].map(([v, text]) =>
          el("button", {
            type: "button", class: "axis-seg-btn" + (st.peds === v ? " selected" : ""), "aria-pressed": String(st.peds === v),
            onClick: () => { st.peds = v; renderShared(); compute(); },
          }, text))),
      st.peds ? el("span", { class: "axis-age-input" },
        el("input", { type: "text", inputmode: "decimal", value: st.ageVal, placeholder: "age", "aria-label": "Age",
          onInput: (e) => { st.ageVal = e.target.value; compute(); } }),
        el("select", { "aria-label": "Age unit", onChange: (e) => { st.ageUnit = e.target.value; compute(); } },
          [["d", "days"], ["m", "months"], ["y", "years"]].map(([v, t]) => el("option", { value: v, selected: st.ageUnit === v }, t))))
        : null);
    const chips = el("div", { class: "axis-chips", role: "group", "aria-label": "Conduction modifiers" },
      C.modifiers.map((mdf) => el("button", {
        type: "button", class: "axis-chip" + (st.mods[mdf.id] ? " selected" : ""), "aria-pressed": String(!!st.mods[mdf.id]),
        onClick: () => { st.mods[mdf.id] = !st.mods[mdf.id]; renderShared(); compute(); },
      }, mdf.label)));
    shared.replaceChildren(ageRow, chips);
  }

  // ---------------------------------------------------------------- compute
  function engineInput() {
    const m = modeDef();
    const base = { ageDays: ageDays(), modifiers: { ...st.mods } };
    const em = m.engineMode || "prt";
    if (em === "prt") return { ...base, mode: "prt", prt: { p: num(st.p), qrs: num(st.qrs), t: num(st.t) } };
    if (em === "polarity") {
      const pol = {};
      for (const l of m.leads) if (st.pol[m.id]?.[l]) pol[l] = st.pol[m.id][l];
      return { ...base, mode: "polarity", polarities: pol };
    }
    const amps = {};
    for (const l of m.leads) { const v = num(st.amps[l]); if (v != null) amps[l] = v; }
    return { ...base, mode: "amplitudes", amplitudes: amps };
  }

  function compute() {
    save();
    const input = engineInput();
    const m = modeDef();
    const blocks = [];
    let res = null;

    if (input.mode === "prt") {
      const parsed = st.prtText.trim() ? parsePRT(st.prtText) : null;
      if (input.prt.qrs == null) {
        const err = parsed && !parsed.ok ? parsed.error : st.qrs.trim() ? "qrs_missing" : "empty";
        blocks.push(msg(C.statusMessages.errors[err], err === "empty" ? "muted" : "sev-moderate"));
      } else {
        res = interpret(input);
        for (const w of parsed?.ok ? parsed.warnings : []) blocks.push(msg(C.warnings[w], "sev-moderate"));
      }
    } else {
      res = interpret(input);
      if (res.status !== "ok") {
        blocks.push(msg(C.statusMessages[res.status] || C.statusMessages.errors[res.error] || res.status,
          res.status === "no_input" || res.status === "need_two_leads" ? "muted" : "sev-moderate"));
        for (const w of res.warnings || []) blocks.push(msg(C.warnings[w], "sev-moderate"));
        blocks.push(wheel(null));
        res = null;
      }
    }

    if (res) blocks.push(...resultBlocks(res, input, m));
    else if (input.mode === "prt") blocks.push(wheel(null));
    out.replaceChildren(...blocks);
  }

  function msg(text, cls) { return el("p", { class: `axis-msg band ${cls}` }, text); }

  function resultBlocks(r, input, m) {
    const kids = [];
    const qc = r.qrs.class;
    const catLabel = C.qrsCategories[qc.key]?.label || qc.key;
    const value = r.qrs.axis != null ? deg(r.qrs.axis)
      : r.qrs.range ? `${deg(r.qrs.range[0])} to ${deg(r.qrs.range[1])}` : "";
    const band = qc.band;
    const sub = band ? `Normal for age: ${deg(band.lo)} to ${deg(band.hi)}`
      : C.qrsCategories[qc.key]?.range || (qc.key === "spans" ? qc.keys.map((k) => C.qrsCategories[k]?.label || k).join(" / ") : "");
    // 1. QRS headline
    kids.push(el("div", { class: `axis-headline band sev-${SEV[qc.severity] || "moderate"}` },
      el("span", { class: "axis-kicker" }, "QRS axis"),
      el("strong", { class: "axis-value" }, value),
      el("span", { class: "axis-cat" }, catLabel),
      sub ? el("span", { class: "muted axis-sub" }, sub) : null));
    // 2. wheel
    kids.push(wheel(r));
    // 3-4. P, T, QRS-T (machine mode)
    if (input.mode === "prt") {
      const pc = r.p.class;
      kids.push(line("P axis", r.p.axis == null ? "—" : deg(r.p.axis), C.pCategories[pc.key], pc.severity));
      if (r.t) {
        kids.push(line("T axis", deg(r.t.axis), C.tCategories[r.t.class.key], r.t.class.severity));
        const qk = r.qrsT.key;
        kids.push(line("QRS-T angle", `${r.qrsT.angle}°`, C.qrsTCategories[qk],
          qk === "normal" ? "normal" : qk === "abnormal" ? "abnormal" : "borderline"));
      }
    }
    // warnings (polarity/amplitude)
    for (const w of r.warnings || []) {
      if (w === "add_lead_II" && st.mode === "quadrant") {
        kids.push(el("div", { class: "axis-msg band sev-moderate" }, C.warnings[w], " ",
          el("button", { type: "button", class: "axis-jump", onClick: jumpToThreeLead }, "Add lead II ›")));
      } else kids.push(msg(C.warnings[w] || w, "sev-moderate"));
    }
    // 5. flags, warnings first
    const flags = [...r.flags].sort((a, b) => (C.flags[a]?.level === "warning" ? 0 : 1) - (C.flags[b]?.level === "warning" ? 0 : 1));
    for (const f of flags) {
      const def = C.flags[f];
      if (!def) continue;
      const cls = `axis-flag band ${def.level === "warning" ? "sev-high" : "sev-info"}`;
      const cl = def.checklist && C.checklists[def.checklist];
      kids.push(cl
        ? el("details", { class: cls }, el("summary", {}, def.text),
            el("p", { class: "axis-cl-title" }, cl.title),
            el("ul", {}, cl.items.map((i) => el("li", {}, i))),
            cl.caveat ? el("p", { class: "muted" }, cl.caveat) : null)
        : el("div", { class: cls }, def.text));
    }
    // 6. differentials
    if (r.differential && C.differentials[r.differential]) {
      kids.push(el("details", { class: "axis-diff" },
        el("summary", {}, `Differential — ${C.qrsCategories[qc.key]?.label || r.differential}`),
        el("ul", {}, C.differentials[r.differential].map((d) => el("li", {}, d)))));
    }
    if (st.peds) kids.push(el("details", { class: "axis-diff" }, el("summary", {}, "Pediatric normal ranges"),
      el("ul", {}, C.peds.bands.map((b) => el("li", {}, el("strong", {}, b.age), ` ${b.range}`))),
      el("p", { class: "muted" }, C.peds.note)));
    return kids;
  }

  function line(label, value, def, severity) {
    return el("div", { class: `axis-line band sev-${SEV[severity] || "moderate"}` },
      el("span", { class: "axis-line-label" }, label),
      el("strong", {}, value),
      def ? el("span", {}, def.label) : null,
      def?.detail ? el("span", { class: "muted axis-line-detail" }, def.detail) : null);
  }

  function jumpToThreeLead() {
    const q = st.pol.quadrant || {};
    st.pol.three_lead = { ...(st.pol.three_lead || {}), ...(q.I ? { I: q.I } : {}), ...(q.aVF ? { aVF: q.aVF } : {}) };
    st.mode = "three_lead";
    renderModes(); renderPanel(); compute();
  }

  // ---------------------------------------------------------------- wheel
  // Original hexaxial drawing (no LITFL imagery). 0° at lead I (right),
  // +90° at aVF (down) — SVG y grows downward, so angles map directly.
  function wheel(r) {
    const S = 260, c = S / 2, R = 96;
    const pt = (a, rad = R) => [c + rad * Math.cos((a * Math.PI) / 180), c + rad * Math.sin((a * Math.PI) / 180)];
    const f = (n) => n.toFixed(1);
    const wedge = (a1, a2, cls, rad = R) => {
      let span = a2 - a1; while (span < 0) span += 360;
      const [x1, y1] = pt(a1, rad), [x2, y2] = pt(a1 + span, rad);
      return `<path class="${cls}" d="M${c},${c} L${f(x1)},${f(y1)} A${rad},${rad} 0 ${span > 180 ? 1 : 0} 1 ${f(x2)},${f(y2)} Z"/>`;
    };
    const parts = [];
    const band = r?.qrs?.class?.band;
    if (st.peds && band) {
      parts.push(`<circle cx="${c}" cy="${c}" r="${R}" class="ax-sec-bg"/>`);
      parts.push(wedge(band.lo, band.hi, "ax-sec ax-sec-low"));
    } else if (st.peds) {
      parts.push(`<circle cx="${c}" cy="${c}" r="${R}" class="ax-sec-bg"/>`);
    } else {
      parts.push(wedge(-30, 90, "ax-sec ax-sec-low"));
      parts.push(wedge(-45, -30, "ax-sec ax-sec-moderate"));
      parts.push(wedge(-90, -45, "ax-sec ax-sec-high"));
      parts.push(wedge(90, 180, "ax-sec ax-sec-high"));
      parts.push(wedge(-180, -90, "ax-sec ax-sec-critical"));
    }
    if (r?.qrs?.range && r.qrs.axis == null) {
      const [a, b] = r.qrs.range;
      parts.push(wedge(a, b, "ax-range", R + 14));
    }
    // lead spokes
    const leadAngle = { I: 0, II: 60, III: 120, aVR: -150, aVL: -30, aVF: 90 };
    for (const [lead, a] of Object.entries(leadAngle)) {
      const [x1, y1] = pt(a + 180), [x2, y2] = pt(a);
      parts.push(`<line class="ax-spoke-neg" x1="${c}" y1="${c}" x2="${f(x1)}" y2="${f(y1)}"/>`);
      parts.push(`<line class="ax-spoke" x1="${c}" y1="${c}" x2="${f(x2)}" y2="${f(y2)}"/>`);
      const [lx, ly] = pt(a, R + 18);
      parts.push(`<text class="ax-lead" x="${f(lx)}" y="${f(ly + 4)}" text-anchor="middle">${lead}</text>`);
    }
    for (const a of [-120, -60, 30, 150, 180]) {
      const [lx, ly] = pt(a, R - 12);
      parts.push(`<text class="ax-tick" x="${f(lx)}" y="${f(ly + 3)}" text-anchor="middle">${deg(a).replace("+", "")}</text>`);
    }
    parts.push(`<circle cx="${c}" cy="${c}" r="${R}" class="ax-rim"/>`);
    // needles: P thin, T dashed, QRS bold
    const needle = (a, cls, len) => { const [x, y] = pt(a, len); return `<line class="${cls}" x1="${c}" y1="${c}" x2="${f(x)}" y2="${f(y)}"/>`; };
    if (r?.p?.axis != null) parts.push(needle(r.p.axis, "ax-needle-p", R - 8));
    if (r?.t?.axis != null) parts.push(needle(r.t.axis, "ax-needle-t", R - 8));
    const qa = r?.qrs?.axis ?? r?.qrs?.estimate;
    if (qa != null) {
      parts.push(needle(qa, r.qrs.axis != null ? "ax-needle-qrs" : "ax-needle-qrs ax-needle-est", R + 4));
      const [hx, hy] = pt(qa, R + 4);
      parts.push(`<circle class="ax-needle-head" cx="${f(hx)}" cy="${f(hy)}" r="4.5"/>`);
    }
    parts.push(`<circle cx="${c}" cy="${c}" r="3" class="ax-hub"/>`);
    const fig = el("figure", { class: "axis-wheel" });
    fig.innerHTML = `<svg viewBox="0 0 ${S} ${S}" role="img" aria-label="Hexaxial reference: QRS${r?.p?.axis != null ? ", P" : ""}${r?.t?.axis != null ? ", T" : ""} axes">${parts.join("")}</svg>`
      + `<figcaption><span class="ax-key ax-key-qrs"></span>QRS${r?.p?.axis != null ? ' <span class="ax-key ax-key-p"></span>P' : ""}${r?.t?.axis != null ? ' <span class="ax-key ax-key-t"></span>T' : ""}${r?.qrs?.range && r.qrs.axis == null ? ' <span class="ax-key ax-key-range"></span>possible range' : ""}</figcaption>`;
    return fig;
  }

  // ---------------------------------------------------------------- mount
  renderModes(); renderPanel(); renderShared();
  section.append(
    el("h1", {}, mod.title),
    richText(mod.purpose, "purpose"),
    modeBar, panel, shared, out,
    el("details", { class: "axis-why" }, el("summary", {}, "Why this matters"), richText(C.whyThisMatters)),
    el("div", { class: "takeaway" }, el("h4", {}, "Clinical takeaway"), richText(C.clinicalTakeaway)),
    sourcesBlock(mod),
    lastVerified(mod),
  );
  compute();
  return section;
}

