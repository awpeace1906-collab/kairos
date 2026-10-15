// Extubation Decision Tool (engine: "builtin", tool: "extubation").
// Every screen, word, rule and citation comes from the kit's
// extubation-logic.json at runtime (served as content/tools/…); this file only
// lays it out in Kairos's skin. Navigation is derived from evaluate():
// screensShown gives the next/previous screen, and a stop outcome whose last
// shown screen is the current one means its stopIf fired. Answers live in
// this closure only: nothing is saved, and leaving the page discards them.
// Mirrors ios/Sources/Views/ExtubationToolView.swift.
import { el, tintStyle } from "../components.js";
import { evaluate, alertItemIds, alertScreenId } from "../lib/extubationEngine.js";

const LOGIC_URL = "./content/tools/extubation-logic.json";
const APP_NAME = "Kairos";
const SETTING = "setting";

export function renderExtubationTool(mod) {
  const section = el("section", { class: "content calculator ext-tool", style: tintStyle(mod) },
    el("h1", {}, mod.title));
  const body = el("div", { class: "ext-body", "aria-live": "polite" });
  section.append(body);

  fetch(LOGIC_URL)
    .then((r) => { if (!r.ok) throw new Error(String(r.status)); return r.json(); })
    .then((logic) => mountTool(logic, body))
    .catch(() => body.replaceChildren(el("p", { class: "band sev-moderate" }, "This tool could not load. Reconnect once to cache it for offline use.")));
  return section;
}

function mountTool(logic, body) {
  const ui = logic.ui;
  const screens = Object.fromEntries(logic.screens.map((s) => [s.id, s]));
  let answers = {};
  let current = SETTING;   // a screen id, or null for the result
  let acks = {};           // alertId -> item ids listed when it was acknowledged

  const result = () => evaluate(logic, answers);
  const track = () => answers.setting;

  function clearAll() { answers = {}; acks = {}; current = SETTING; }

  /** Ack holds while the alert's list stays the same or shrinks; a new item clears it. */
  function refreshAcks() {
    for (const id of Object.keys(acks)) {
      const now = alertItemIds(logic, answers, id);
      if (now.some((x) => !acks[id].includes(x))) delete acks[id];
    }
  }

  function screenAlerts(screenId) {
    if (!track()) return [];
    return result().alerts.filter((a) => a.requiresAck && alertScreenId(logic, a.id) === screenId);
  }

  function canAdvance(sc) {
    if (sc.required) {
      const a = answers[sc.id];
      if (sc.type === "text_fields") {
        if (!sc.fields.every((f) => String(a?.[f.id] ?? "").trim() !== "")) return false;
      } else if (!a) return false;
    }
    return screenAlerts(sc.id).every((al) => acks[al.id]);
  }

  // ---------------------------------------------------------------- navigation
  function next() {
    const sc = screens[current];
    if (!canAdvance(sc)) return;
    const r = result();
    if (current === SETTING) { current = r.screensShown[0]; return render(); }
    const i = r.screensShown.indexOf(current);
    current = i >= 0 && i + 1 < r.screensShown.length ? r.screensShown[i + 1] : null;
    render();
  }
  function back() {
    const shown = track() ? result().screensShown : [];
    if (current === null) current = shown[shown.length - 1];
    else {
      const i = shown.indexOf(current);
      current = i > 0 ? shown[i - 1] : SETTING;
    }
    render();
  }

  // ---------------------------------------------------------------- dialogs
  function confirmDialog(message, onConfirm) {
    const dlg = el("dialog", { class: "ext-dialog" },
      el("p", {}, message),
      el("div", { class: "ext-dialog-actions" },
        el("button", { type: "button", class: "ext-btn", onClick: () => dlg.close() }, ui.buttons.cancel),
        el("button", { type: "button", class: "ext-btn ext-btn-primary", onClick: () => { dlg.close(); onConfirm(); } }, ui.buttons.confirm)));
    dlg.addEventListener("close", () => dlg.remove());
    document.body.append(dlg);
    dlg.showModal();
  }
  const startOver = () => confirmDialog(ui.buttons.startOverConfirm, () => { clearAll(); render(); });

  // ---------------------------------------------------------------- pieces
  function topBar(sc) {
    if (sc.id === SETTING) return null; // flowRules: step 0 has no top bar
    const t = logic.tracks[track()];
    return el("div", { class: "ext-topbar" },
      el("div", { class: "ext-topbar-text" },
        el("span", { class: "ext-track" }, t.title),
        el("span", { class: "ext-step" }, ui.stepLabel.replace("{current}", String(sc.step)).replace("{total}", String(t.totalSteps)))),
      el("button", { type: "button", class: "ext-btn ext-btn-quiet", onClick: startOver }, ui.buttons.reset));
  }

  function choiceButtons(sc, options) {
    return el("div", { class: "ext-choices", role: "group", "aria-label": sc.title },
      options.map((o) => {
        const on = (sc.id === SETTING ? answers.setting : answers[sc.id]) === o.id;
        return el("button", {
          type: "button", class: "ext-choice" + (on ? " selected" : ""), "aria-pressed": String(on),
          onClick: () => pick(sc, o.id),
        }, o.label);
      }));
  }

  function pick(sc, id) {
    if (sc.id === SETTING) {
      const hasOther = Object.keys(answers).some((k) => k !== SETTING);
      if (answers.setting && answers.setting !== id && hasOther) {
        return confirmDialog(ui.buttons.resetConfirm, () => { clearAll(); answers.setting = id; render(); });
      }
      answers.setting = id;
    } else answers[sc.id] = id;
    render();
  }

  function control(sc) {
    switch (sc.type) {
      case "single_choice": return choiceButtons(sc, sc.options);
      case "yes_no": return choiceButtons(sc, [{ id: "yes", label: ui.buttons.yes }, { id: "no", label: ui.buttons.no }]);
      case "checklist": {
        const checked = answers[sc.id] || [];
        return el("div", { class: "ext-checklist" }, sc.items.map((it) => el("label", { class: "ext-check" },
          el("input", { type: "checkbox", checked: checked.includes(it.id), onChange: (e) => {
            const set = new Set(answers[sc.id] || []);
            e.target.checked ? set.add(it.id) : set.delete(it.id);
            answers[sc.id] = sc.items.map((x) => x.id).filter((x) => set.has(x));
            refreshAcks();
            render();
          } }),
          el("span", {}, it.label))));
      }
      case "text_fields": {
        const vals = answers[sc.id] || {};
        return el("div", { class: "ext-fields" }, sc.fields.map((f) => {
          const id = `ext-${sc.id}-${f.id}`;
          return el("div", { class: "ext-field" },
            el("label", { class: "field-label", for: id }, f.label),
            el("input", { id, type: "text", autocomplete: "off", value: vals[f.id] ?? "", onInput: (e) => {
              answers[sc.id] = { ...(answers[sc.id] || {}), [f.id]: e.target.value };
              nextBtn.disabled = !canAdvance(sc);
            } }));
        }));
      }
    }
    return null;
  }

  function alertBox(a, informational) {
    const box = el("div", { class: `band ext-alert ${a.level === "red" ? "sev-high" : "sev-moderate"}`, role: "alert" },
      el("p", {}, a.text));
    if (a.requiresAck) {
      box.append(el("label", { class: "ext-ack" },
        el("input", { type: "checkbox", checked: !!acks[a.id], onChange: (e) => {
          if (e.target.checked) acks[a.id] = alertItemIds(logic, answers, a.id);
          else delete acks[a.id];
          if (informational) return;
          render();
        } }),
        el("span", {}, ui.acknowledge)));
    }
    return box;
  }

  function sourceLabels(keys) { return keys.map((k) => logic.sources[k]?.short).filter(Boolean).join(" · "); }

  function rescueBlock(r) {
    const sc = r.screensShown.map((id) => screens[id]).find((s) => s.type === "text_fields");
    const vals = sc && answers[sc.id];
    if (!vals) return null;
    return el("dl", { class: "ext-rescue" }, sc.fields.map((f) => [el("dt", {}, f.label), el("dd", {}, vals[f.id] ?? "")]));
  }

  // ---------------------------------------------------------------- screens
  let nextBtn;
  function renderScreen(sc) {
    nextBtn = el("button", { type: "button", class: "ext-btn ext-btn-primary", disabled: !canAdvance(sc), onClick: next }, ui.buttons.next);
    return [
      topBar(sc),
      el("h2", { class: "ext-title" }, sc.title),
      el("p", { class: "ext-prompt" }, sc.prompt),
      sc.info ? el("div", { class: "band sev-info ext-info" }, el("p", {}, sc.info),
        sc.infoSources?.length ? el("p", { class: "muted ext-info-src" }, sourceLabels(sc.infoSources)) : null) : null,
      control(sc),
      sc.note ? el("p", { class: "muted ext-note" }, sc.note,
        sc.noteSources?.length ? el("span", { class: "ext-note-src" }, " " + sourceLabels(sc.noteSources)) : null) : null,
      screenAlerts(sc.id).map((a) => alertBox(a, false)),
      sc.id === SETTING ? el("p", { class: "muted ext-disclaimer" }, ui.disclaimer) : null,
      el("div", { class: "ext-bottombar" },
        el("button", { type: "button", class: "ext-btn", disabled: sc.id === SETTING, onClick: back }, ui.buttons.back),
        nextBtn),
    ];
  }

  function renderResult() {
    const r = result();
    const sev = r.class === "stop" ? "sev-high" : r.class === "high" ? "sev-moderate" : "sev-low";
    const t = logic.tracks[track()];
    // Order follows logic.resultLayout; sections have no headings (layoutRules).
    return [
      el("div", { class: "ext-topbar" },
        el("div", { class: "ext-topbar-text" }, el("span", { class: "ext-track" }, t.title)),
        el("button", { type: "button", class: "ext-btn ext-btn-quiet", onClick: startOver }, ui.buttons.reset)),
      el("span", { class: `ext-chip ${sev}` }, r.chip),
      el("h2", { class: "ext-title" }, r.title),
      el("p", { class: `band ${sev} ext-rec` }, r.recommendation),
      r.alerts.map((a) => alertBox(a, true)),
      r.why.length ? el("ul", { class: "ext-why" }, r.why.map((w) => el("li", {}, w))) : null,
      rescueBlock(r),
      el("details", { class: "ext-evidence" }, el("summary", {}, ui.buttons.evidence),
        el("ol", {}, r.sources.map((k) => el("li", {}, logic.sources[k].full)))),
      el("p", { class: "muted ext-disclaimer" }, ui.disclaimer),
      el("div", { class: "ext-bottombar" },
        el("button", { type: "button", class: "ext-btn", onClick: back }, ui.buttons.back),
        el("div", { class: "ext-result-actions" },
          el("button", { type: "button", class: "ext-btn ext-btn-primary", onClick: () => printCard(r) }, ui.buttons.print),
          el("button", { type: "button", class: "ext-btn", onClick: startOver }, ui.buttons.reset))),
    ];
  }

  // ---------------------------------------------------------------- handoff card (print)
  function printCard(r) {
    document.querySelectorAll(".ext-print-root").forEach((n) => n.remove());
    const t = logic.tracks[track()];
    const card = el("div", { class: "ext-print-root" }, el("article", { class: "ext-card" },
      el("header", { class: "ext-card-head" },
        el("strong", {}, APP_NAME), el("span", {}, ui.card.header), el("span", {}, t.title),
        el("span", {}, new Date().toLocaleString())),
      el("div", { class: "ext-card-label" }, el("span", {}, ui.card.patientLabel)),
      el("p", { class: "ext-card-chip" }, r.chip),
      el("h2", {}, r.title),
      el("p", {}, r.recommendation),
      r.alerts.map((a) => el("p", { class: `ext-card-alert ${a.level}` }, a.text)),
      r.why.length ? el("ul", {}, r.why.map((w) => el("li", {}, w))) : null,
      rescueBlock(r),
      el("p", { class: "ext-card-refs" }, sourceLabels(r.sources)),
      el("ol", { class: "ext-card-cites" }, r.sources.map((k) => el("li", {}, logic.sources[k].full))),
      el("p", { class: "ext-card-disclaimer" }, ui.disclaimer)));
    document.body.append(card);
    document.body.classList.add("ext-printing");
    const done = () => {
      document.body.classList.remove("ext-printing"); card.remove();
      window.removeEventListener("afterprint", done); window.removeEventListener("hashchange", done);
    };
    window.addEventListener("afterprint", done);
    window.addEventListener("hashchange", done); // browsers that never fire afterprint
    window.print();
  }

  function render() {
    body.replaceChildren(...[current === null ? renderResult() : renderScreen(screens[current])].flat(Infinity).filter(Boolean));
  }
  render();
}
