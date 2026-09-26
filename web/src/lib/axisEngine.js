// EKG Axis Interpreter — reference engine (pure functions, no dependencies).
// Source of truth for behavior. ios/Sources/Calc/AxisEngine.swift must pass the
// same golden vectors (tools/fixtures/axis-golden-vectors.json), which both
// tools/test.mjs and the XCTest suite run. The engine returns keys, never prose:
// every user-facing string lives in the module's toolContent
// (content/modules/calculators/cardiovascular/ekg-axis-interpreter.json).

const ROOT3_2 = Math.sqrt(3) / 2;

// Hexaxial leads. Augmented leads read √3/2 of the true projection relative
// to bipolar leads (Goldberger), which is why naive atan2(aVF, I) is wrong.
const LEADS = {
  I:   { angle: 0,    gain: 1 },
  II:  { angle: 60,   gain: 1 },
  III: { angle: 120,  gain: 1 },
  aVR: { angle: -150, gain: ROOT3_2 },
  aVL: { angle: -30,  gain: ROOT3_2 },
  aVF: { angle: 90,   gain: ROOT3_2 },
};
const LEAD_ORDER = ['I', 'II', 'III', 'aVR', 'aVL', 'aVF'];

const rad = (d) => (d * Math.PI) / 180;
const deg = (r) => (r * 180) / Math.PI;

/** Normalize any angle to (-180, 180]. */
function normalize(d) {
  let x = ((d % 360) + 360) % 360;
  if (x > 180) x -= 360;
  return x;
}

/** Smallest absolute angular difference, 0..180. */
function angularDiff(a, b) {
  return Math.abs(normalize(a - b));
}

/** Wrap-aware arc membership; lo..hi may exceed 180 (e.g. 30..190). */
function inArc(theta, lo, hi) {
  let t = theta;
  while (t < lo) t += 360;
  while (t >= lo + 360) t -= 360;
  return t <= hi;
}

// ---------------------------------------------------------------- QRS bands

// Adult (LITFL / AHA convention):
// normal [-30, +90], LAD [-90, -30) split borderline (-45, -30) / marked [-90, -45],
// RAD (+90, +180], extreme (-180, -90).
function classifyQrsAdult(q) {
  const a = normalize(q);
  if (a >= -30 && a <= 90) return { key: 'normal', severity: 'normal' };
  if (a > -45 && a < -30) return { key: 'lad_borderline', severity: 'borderline' };
  if (a >= -90 && a <= -45) return { key: 'lad_marked', severity: 'abnormal' };
  if (a > 90 && a <= 180) return { key: 'rad', severity: 'abnormal' };
  return { key: 'extreme', severity: 'abnormal' };
}

// Pediatric normal ranges by age: AHA/ACCF/HRS 2009 Part III, Table (Mean
// Frontal Plane Axis). Adult limits apply from 16 years, matching the same
// document's 16-year cutoff for LPFB and QRS duration. The document's text
// gives 10-110 for ages 1-5; the table (used here) gives 5-100.
const PEDS_BANDS = [
  { id: 'neonate',  maxDays: 30,       lo: 30, hi: 190 },
  { id: '1m_1y',    maxDays: 365,      lo: 10, hi: 120 },
  { id: '1y_5y',    maxDays: 5 * 365,  lo: 5,  hi: 100 },
  { id: '5y_8y',    maxDays: 8 * 365,  lo: 0,  hi: 140 },
  { id: '8y_16y',   maxDays: 16 * 365, lo: 0,  hi: 120 },
];

function pedsBand(ageDays) {
  if (ageDays == null || !(ageDays >= 0)) return null;
  return PEDS_BANDS.find((b) => ageDays < b.maxDays) || null; // null => adult
}

function classifyQrs(q, ageDays) {
  const band = pedsBand(ageDays);
  if (!band) return { ...classifyQrsAdult(q), population: 'adult' };
  const a = normalize(q);
  if (inArc(a, band.lo, band.hi)) {
    return { key: 'normal_for_age', severity: 'normal', population: 'peds', band };
  }
  const key = angularDiff(a, band.hi) < angularDiff(a, band.lo)
    ? 'rightward_for_age' : 'leftward_for_age';
  return { key, severity: 'abnormal', population: 'peds', band };
}

// ------------------------------------------------------------------ P and T

function classifyP(p) {
  if (p == null) return { key: 'absent', severity: 'borderline' };
  const a = normalize(p);
  if (Math.abs(a) > 90) return { key: 'negative_lead_I', severity: 'abnormal', superior: a < 0 };
  if (a < 0) return { key: 'superior', severity: 'abnormal' };
  if (a <= 75) return { key: 'normal', severity: 'normal' };
  return { key: 'vertical', severity: 'borderline' }; // (75, 90]
}

function classifyT(t) {
  if (t == null) return null;
  const a = normalize(t);
  return a >= 0 && a <= 90
    ? { key: 'normal', severity: 'normal' }
    : { key: 'outside_reference', severity: 'borderline' };
}

const SECONDARY_REPOL = ['lbbb', 'rbbb', 'paced', 'lvh', 'wpw', 'wideQrs'];

function qrsTAngle(q, t, modifiers = {}) {
  if (q == null || t == null) return null;
  const angle = Math.round(angularDiff(q, t));
  const secondary = SECONDARY_REPOL.some((m) => modifiers[m]);
  let key;
  if (secondary) key = 'secondary_repolarization';
  else if (angle < 45) key = 'normal';
  else if (angle <= 90) key = 'borderline';
  else key = 'abnormal';
  return { angle, key, highRisk: !secondary && angle >= 100 };
}

// ----------------------------------------------------------- P-R-T parsing

const TOKEN = /(-?\d{1,3}(?:\.\d+)?|\*{1,3}|-{2,3}|n\/?a)/gi;
const NAMED = /\b(P|QRS|R|T)\b\s*(?:axis)?\s*[:=]?\s*(-?\d{1,3}(?:\.\d+)?|\*{1,3}|-{2,3})/gi;

function tokenToValue(tok) {
  if (/^-?\d/.test(tok)) return Number(tok);
  return null; // ***, ---, n/a => not reported
}

/**
 * Parse machine axis output. Accepts e.g.
 *  "P-R-T axes 54 -42 38", "54/-42/38", "P 54 QRS -42 T 38",
 *  "*** 72 45", or a full pasted header containing "axes".
 */
function parsePRT(text) {
  const warnings = [];
  if (typeof text !== 'string' || !text.trim()) return { ok: false, error: 'empty' };
  let s = text.replace(/[\u2212\u2013\u2014]/g, '-');

  let p, qrs, t;
  const axesIdx = s.toLowerCase().lastIndexOf('axes');
  if (axesIdx >= 0) {
    const toks = s.slice(axesIdx + 4).match(TOKEN) || [];
    if (toks.length >= 3) [p, qrs, t] = toks.slice(0, 3).map(tokenToValue);
    else if (toks.length === 2) {
      p = null; [qrs, t] = toks.map(tokenToValue);
      warnings.push('p_assumed_absent');
    } else return { ok: false, error: 'unparseable' };
  } else {
    const named = {};
    let m;
    while ((m = NAMED.exec(s)) !== null) {
      const k = m[1].toUpperCase() === 'R' ? 'QRS' : m[1].toUpperCase();
      if (!(k in named)) named[k] = tokenToValue(m[2]);
    }
    NAMED.lastIndex = 0;
    if ('QRS' in named) {
      p = 'P' in named ? named.P : null;
      qrs = named.QRS;
      t = 'T' in named ? named.T : null;
    } else {
      const toks = s.match(TOKEN) || [];
      if (toks.length >= 3) [p, qrs, t] = toks.slice(0, 3).map(tokenToValue);
      else if (toks.length === 2) {
        p = null; [qrs, t] = toks.map(tokenToValue);
        warnings.push('p_assumed_absent');
      } else return { ok: false, error: 'unparseable' };
    }
  }
  if (qrs == null) return { ok: false, error: 'qrs_missing' };
  for (const v of [p, qrs, t]) {
    if (v != null && (v < -360 || v > 360)) return { ok: false, error: 'out_of_range' };
  }
  const n = (v) => (v == null ? null : normalize(v));
  return { ok: true, p: n(p), qrs: n(qrs), t: n(t), warnings };
}

// ------------------------------------------------- polarity-based methods
// Covers Quadrant (I, aVF), Three-lead (I, II, aVF) and Isoelectric-lead
// methods with one solver: each lead's polarity constrains the axis to a
// half-circle (pos/neg) or a pair of points (iso); intersect them.

function solvePolarities(pol) {
  const keys = LEAD_ORDER.filter((k) => pol[k]);
  if (!keys.length) return { status: 'no_input' };
  const hits = [];
  for (let d = -179; d <= 180; d++) {
    let ok = true;
    for (const k of keys) {
      const c = Math.cos(rad(d - LEADS[k].angle));
      const v = pol[k];
      if ((v === 'pos' && !(c > 1e-9)) || (v === 'neg' && !(c < -1e-9)) ||
          (v === 'iso' && Math.abs(c) > 1e-9)) { ok = false; break; }
    }
    if (ok) hits.push(d);
  }
  if (!hits.length) return { status: 'inconsistent', leads: keys };

  // group into contiguous arcs, wrap-aware (180 -> -179)
  const arcs = [];
  let start = hits[0], prev = hits[0];
  for (let i = 1; i < hits.length; i++) {
    if (hits[i] !== prev + 1) { arcs.push([start, prev]); start = hits[i]; }
    prev = hits[i];
  }
  arcs.push([start, prev]);
  if (arcs.length > 1 && arcs[0][0] === -179 && arcs[arcs.length - 1][1] === 180) {
    const last = arcs.pop();
    arcs[0] = [last[0], arcs[0][1]]; // from > to means it wraps through 180
  }
  const out = arcs.map(([from, to]) => {
    const width = to >= from ? to - from : to + 360 - from;
    return { from, to, width, mid: normalize(from + width / 2) };
  });
  return { status: out.length === 1 ? 'resolved' : 'ambiguous', arcs: out, leads: keys };
}

// ----------------------------------------------- amplitude-based (precise)

/** Net QRS amplitudes (mm, R minus Q/S) for any >=2 limb leads. */
function solveAmplitudes(amps) {
  const keys = LEAD_ORDER.filter((k) => amps[k] != null && Number.isFinite(amps[k]));
  if (keys.length < 2) return { status: 'need_two_leads' };
  let sxx = 0, sxy = 0, syy = 0, bx = 0, by = 0;
  for (const k of keys) {
    const { angle, gain } = LEADS[k];
    const ux = gain * Math.cos(rad(angle)), uy = gain * Math.sin(rad(angle));
    const v = amps[k];
    sxx += ux * ux; sxy += ux * uy; syy += uy * uy; bx += ux * v; by += uy * v;
  }
  const det = sxx * syy - sxy * sxy;
  const x = (syy * bx - sxy * by) / det;
  const y = (sxx * by - sxy * bx) / det;
  const magnitude = Math.hypot(x, y);
  const warnings = [];
  if (['I', 'II', 'III'].every((k) => keys.includes(k)) &&
      Math.abs(amps.I + amps.III - amps.II) > 1) warnings.push('einthoven_mismatch');
  if (['aVR', 'aVL', 'aVF'].every((k) => keys.includes(k)) &&
      Math.abs(amps.aVR + amps.aVL + amps.aVF) > 1) warnings.push('goldberger_mismatch');
  if (magnitude < 0.25) return { status: 'indeterminate', warnings };
  return { status: 'resolved', axis: Math.round(normalize(deg(Math.atan2(y, x)))), magnitude, warnings };
}

// ------------------------------------------------------------ interpret()

function flagsFor({ p, qrs, pClass, qrsClass, modifiers = {}, ageDays }) {
  const flags = [];
  const m = modifiers;
  // Negative P in lead I + negative QRS in lead I => limb lead reversal vs dextrocardia
  if (p != null && qrs != null && Math.abs(normalize(p)) > 90 && Math.abs(normalize(qrs)) > 90) {
    flags.push('limb_lead_reversal_vs_dextrocardia');
  }
  if (qrsClass && qrsClass.population === 'adult') {
    const conductionConfounder = m.lbbb || m.paced || m.wideQrs;
    if (qrsClass.key === 'lad_marked' && !conductionConfounder) flags.push('lafb_checklist');
    if (qrsClass.key === 'rad' && !(m.lbbb || m.paced || m.wideQrs)) flags.push('lpfb_checklist');
  }
  if (qrsClass && qrsClass.population === 'peds' && ageDays < 365 &&
      qrs != null && normalize(qrs) < -90) flags.push('infant_superior_axis');
  if (m.paced) flags.push('paced_axis_caveat');
  if (pClass && pClass.key === 'absent') flags.push('check_rhythm_no_p');
  return flags;
}

function differentialKey(qrsClass) {
  if (!qrsClass || qrsClass.population !== 'adult') return null;
  if (qrsClass.key.startsWith('lad')) return 'lad';
  if (qrsClass.key === 'rad') return 'rad';
  if (qrsClass.key === 'extreme') return 'extreme';
  return null;
}

/**
 * input = {
 *   mode: 'prt' | 'polarity' | 'amplitudes',
 *   prt: { text } | { p, qrs, t },
 *   polarities: { I:'pos'|'neg'|'iso', ... },
 *   amplitudes: { I: mm, II: mm, ... },
 *   ageDays: number|null   (null/undefined => adult),
 *   modifiers: { lbbb, rbbb, paced, lvh, wpw, wideQrs }
 * }
 */
function interpret(input) {
  const ageDays = input.ageDays ?? null;
  const modifiers = input.modifiers || {};
  const res = { mode: input.mode, warnings: [], qrs: null, p: null, t: null, qrsT: null, flags: [] };

  if (input.mode === 'prt') {
    let v = input.prt || {};
    if (typeof v.text === 'string') {
      const parsed = parsePRT(v.text);
      if (!parsed.ok) return { ...res, status: 'error', error: parsed.error };
      res.warnings.push(...parsed.warnings);
      v = parsed;
    }
    if (v.qrs == null) return { ...res, status: 'error', error: 'qrs_missing' };
    const q = normalize(v.qrs);
    const p = v.p == null ? null : normalize(v.p);
    const t = v.t == null ? null : normalize(v.t);
    res.qrs = { axis: q, class: classifyQrs(q, ageDays) };
    res.p = { axis: p, class: classifyP(p) };
    res.t = t == null ? null : { axis: t, class: classifyT(t) };
    res.qrsT = qrsTAngle(q, t, modifiers);
    if (res.qrsT && res.qrsT.highRisk) res.flags.push('qrs_t_angle_high_risk');
    res.flags.push(...flagsFor({ p, qrs: q, pClass: res.p.class, qrsClass: res.qrs.class, modifiers, ageDays }));
  } else if (input.mode === 'polarity') {
    const sol = solvePolarities(input.polarities || {});
    if (sol.status !== 'resolved') return { ...res, status: sol.status, solution: sol };
    const arc = sol.arcs[0];
    const cats = new Set();
    for (let i = 0; i <= arc.width; i++) cats.add(classifyQrs(normalize(arc.from + i), ageDays).key);
    res.qrs = {
      axis: arc.width === 0 ? arc.from : null,
      estimate: Math.round(arc.mid),
      range: [arc.from, arc.to],
      class: cats.size === 1 ? classifyQrs(arc.mid, ageDays) : { key: 'spans', severity: 'borderline', keys: [...cats] },
    };
    if (cats.size > 1 && !(input.polarities || {}).II && cats.has('normal') &&
        [...cats].some((k) => k.startsWith('lad'))) res.warnings.push('add_lead_II');
    else if (cats.size > 1) res.warnings.push('add_leads_or_use_precise');
    if (cats.size === 1) res.flags.push(...flagsFor({ p: null, qrs: arc.mid, qrsClass: res.qrs.class, modifiers, ageDays }));
  } else if (input.mode === 'amplitudes') {
    const sol = solveAmplitudes(input.amplitudes || {});
    res.warnings.push(...(sol.warnings || []));
    if (sol.status !== 'resolved') return { ...res, status: sol.status };
    res.qrs = { axis: sol.axis, class: classifyQrs(sol.axis, ageDays) };
    res.flags.push(...flagsFor({ p: null, qrs: sol.axis, qrsClass: res.qrs.class, modifiers, ageDays }));
  } else {
    return { ...res, status: 'error', error: 'unknown_mode' };
  }
  res.differential = differentialKey(res.qrs && res.qrs.class);
  res.status = 'ok';
  return res;
}

export {
  LEADS, LEAD_ORDER, PEDS_BANDS, normalize, angularDiff, inArc,
  classifyQrsAdult, classifyQrs, classifyP, classifyT, qrsTAngle,
  parsePRT, solvePolarities, solveAmplitudes, interpret,
};
