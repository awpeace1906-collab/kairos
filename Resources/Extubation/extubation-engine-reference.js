// Reference engine for cv-extubation-logic v1.3. Pure function, no UI.
// Ports (Swift, etc.) must produce identical results for every vignette.
"use strict";
function evaluate(logic, answers) {
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
if (typeof module !== "undefined") module.exports = { evaluate };
