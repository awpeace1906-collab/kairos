// Extubation decision engine — a line-for-line port of
// Resources/Extubation/extubation-engine-reference.js (cv-extubation-logic).
// Pure: no UI, no app state, no network. Every clinical word, rule and number
// lives in extubation-logic.json; this file only interprets its structure.
// Tested against Resources/Extubation/extubation-vignettes.json (tools/test.mjs).
// Swift twin: ios/Packages/ExtubationEngine.

export function evaluate(logic, answers) {
  // answers: { setting: "or"|"icu", <checklistScreenId>: [checkedItemIds], <yesNoId>: "yes"|"no",
  //            <singleChoiceId>: optionId, <textFieldsId>: {fieldId: text} }
  const screens = Object.fromEntries(logic.screens.map(s => [s.id, s]));
  const track = answers.setting;
  const checked = id => answers[id] || [];
  const items = id => screens[id].items;
  const cond = c => {
    if (!c) return true;
    if (c.always) return true;
    if ("count" in c) { const n = checked(c.count).length; return ("eq" in c) ? n === c.eq : n >= c.gte; }
    if ("answer" in c) return answers[c.answer] === c.eq;
    if ("anyUnchecked" in c) {
      return items(c.anyUnchecked).some(it => !checked(c.anyUnchecked).includes(it.id) &&
        (c.hardOnly ? it.hard === true : c.softOnly ? it.hard === false : true));
    }
    throw new Error("Unknown condition " + JSON.stringify(c));
  };
  const shown = [];
  let outcome = null;
  for (const st of logic.flow[track]) {
    const sc = screens[st.at];
    if (sc.showIf && !cond(sc.showIf)) continue;
    shown.push(sc.id);
    if (st.stopIf && cond(st.stopIf)) { outcome = st.outcome; break; }
  }
  if (!outcome) outcome = logic.outcomeRules.find(r => r.track === track && cond(r.when)).outcome;
  const oc = logic.outcomes[outcome];
  const isStop = oc.class === "stop";
  const labelsOf = (id, pred) => items(id).filter(pred).map(it => it.label);
  let why = [];
  if (oc.why.fixed) why = oc.why.fixed.slice();
  if (oc.why.checked) why = labelsOf(oc.why.checked, it => checked(oc.why.checked).includes(it.id));
  if (oc.why.uncheckedHard) why = labelsOf(oc.why.uncheckedHard, it => it.hard && !checked(oc.why.uncheckedHard).includes(it.id)).map(l => oc.why.prefix + l);
  const count = track === "icu" ? checked("icu_reint").length : null;
  const alerts = [];
  if (!isStop) {
    const ids = Object.keys(logic.alerts).filter(k => logic.alerts[k].tracks.includes(track) && cond(logic.alerts[k].when));
    const ordered = [...ids.filter(k => logic.alerts[k].level === "red"), ...ids.filter(k => logic.alerts[k].level === "amber")];
    for (const k of ordered) {
      const a = logic.alerts[k]; let text = a.text;
      if (a.items) {
        const [mode, sid] = Object.entries(a.items)[0];
        const labels = items(sid).filter(it => !checked(sid).includes(it.id) && (mode === "uncheckedSoft" ? it.hard === false : true)).map(it => it.label.toLowerCase());
        text = text.replace("{items}", labels.join("; "));
      }
      alerts.push({ id: k, level: a.level, text, requiresAck: !!a.requiresAck });
    }
  }
  const srcKeys = [];
  for (const k of [...oc.sources, ...alerts.flatMap(a => logic.alerts[a.id].sources)]) if (!srcKeys.includes(k)) srcKeys.push(k);
  return {
    outcome, class: oc.class, chip: oc.chip.replace("{count}", String(count)), title: oc.title,
    recommendation: logic.ui.recommendationPrefix + " " + oc.text, riskCount: count,
    why, alerts, sources: srcKeys, screensShown: shown
  };
}

// ---------------------------------------------------------------------------
// Helpers for the UI layer (not part of the reference engine). They read the
// same structure evaluate() reads and add no clinical rules of their own.

/** The item ids an alert with an `items` spec is currently listing — used to
    decide when an acknowledgment must clear ("a new item appeared"). Mirrors
    the {items} filter in evaluate(). */
export function alertItemIds(logic, answers, alertId) {
  const a = logic.alerts[alertId];
  if (!a?.items) return [];
  const [mode, sid] = Object.entries(a.items)[0];
  const screen = logic.screens.find(s => s.id === sid);
  const checked = answers[sid] || [];
  return screen.items.filter(it => !checked.includes(it.id) && (mode === "uncheckedSoft" ? it.hard === false : true)).map(it => it.id);
}

/** The screen an alert's condition reads (its `when` names one screen id), so a
    requiresAck alert can be shown on that screen. Null for `always` alerts. */
export function alertScreenId(logic, alertId) {
  const w = logic.alerts[alertId]?.when || {};
  const ids = new Set(logic.screens.map(s => s.id));
  for (const k of ["anyUnchecked", "count", "answer"]) if (ids.has(w[k])) return w[k];
  return null;
}
