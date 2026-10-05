// Acid-base analyzer engine — reference implementation.
// Ported to ios/Sources/Calc/AcidBaseEngine.swift; both must pass
// tools/fixtures/acid-base-golden-vectors.json. Returns keys only; the module
// JSON (toolContent) maps every key to copy.
//
// Rules (Brandis K, Acid-Base Physiology, sections 3.3, 9.2, 9.3):
//   metabolic acidosis    expected PaCO2 = 1.5 × HCO3 + 8        (± 2)
//   metabolic alkalosis   expected PaCO2 = 0.7 × HCO3 + 20       (± 5)
//   respiratory acidosis  HCO3 +1 (acute) / +4 (chronic) per 10 mmHg above 40
//   respiratory alkalosis HCO3 −2 (acute) / −5 (chronic) per 10 mmHg below 40
//   delta ratio = (AG − 12) / (24 − HCO3)
// Brandis gives ± 2 for the chronic respiratory alkalosis rule; the same ± 2
// band is applied to the other respiratory rules here (design choice).
// Albumin-corrected AG = AG + 2.5 × (4 − albumin g/dL) (Figge 1998).

const N = { phLo: 7.35, phHi: 7.45, co2Lo: 35, co2Hi: 45, co2: 40, hco3Lo: 22, hco3Hi: 26, hco3: 24, ag: 12, alb: 4 };
const LIMITS = { ph: [6.5, 8.0], paco2: [5, 150], hco3: [2, 60], na: [100, 180], cl: [60, 140], albumin: [0.5, 6] };
const HH_TOLERANCE = 0.05;   // pH units; design choice, see buildNote

const round = (x, d = 1) => Math.round(x * 10 ** d) / 10 ** d;
const band = (center, tol) => ({ center: round(center), lo: round(center - tol), hi: round(center + tol) });

function hhPh(paco2, hco3) {
  return 6.1 + Math.log10(hco3 / (0.03 * paco2));
}

// Expected HCO3 for a respiratory disorder at this PaCO2.
function respExpected(paco2, kind) {
  const d = (paco2 - N.co2) / 10;              // + above 40, − below 40
  if (kind === 'resp_acid') return { acute: band(N.hco3 + 1 * d, 2), chronic: band(N.hco3 + 4 * d, 2) };
  return { acute: band(N.hco3 + 2 * d, 2), chronic: band(N.hco3 + 5 * d, 2) }; // d < 0 lowers HCO3
}

// Where the measured HCO3 sits against acute/chronic respiratory expectations.
function respCompensation(hco3, exp, chronicity) {
  const inA = hco3 >= exp.acute.lo && hco3 <= exp.acute.hi;
  const inC = hco3 >= exp.chronic.lo && hco3 <= exp.chronic.hi;
  const lowest = Math.min(exp.acute.lo, exp.chronic.lo), highest = Math.max(exp.acute.hi, exp.chronic.hi);
  if (chronicity === 'acute' || chronicity === 'chronic') {
    const e = exp[chronicity];
    if (hco3 > e.hi) return 'plus_metabolic_alkalosis';
    if (hco3 < e.lo) return 'plus_metabolic_acidosis';
    return 'appropriate';
  }
  if (inA && inC) return 'acute_or_chronic';
  if (inA) return 'fits_acute';
  if (inC) return 'fits_chronic';
  if (hco3 > highest) return 'plus_metabolic_alkalosis';
  if (hco3 < lowest) return 'plus_metabolic_acidosis';
  return 'between_acute_and_chronic';
}

function metCompensation(paco2, exp) {
  if (paco2 > exp.hi) return 'plus_respiratory_acidosis';
  if (paco2 < exp.lo) return 'plus_respiratory_alkalosis';
  return 'appropriate';
}

const SECOND = {
  plus_metabolic_alkalosis: 'metabolic_alkalosis', plus_metabolic_acidosis: 'metabolic_acidosis',
  plus_respiratory_acidosis: 'respiratory_acidosis', plus_respiratory_alkalosis: 'respiratory_alkalosis',
};

function compensate(primary, { paco2, hco3, chronicity }) {
  if (primary === 'metabolic_acidosis') {
    const expected = band(1.5 * hco3 + 8, 2);
    return { rule: 'winters', measured: 'paco2', actual: paco2, expected, key: metCompensation(paco2, expected) };
  }
  if (primary === 'metabolic_alkalosis') {
    const expected = band(0.7 * hco3 + 20, 5);
    return { rule: 'met_alk', measured: 'paco2', actual: paco2, expected, key: metCompensation(paco2, expected) };
  }
  if (primary === 'respiratory_acidosis' || primary === 'respiratory_alkalosis') {
    const kind = primary === 'respiratory_acidosis' ? 'resp_acid' : 'resp_alk';
    const exp = respExpected(paco2, kind);
    return { rule: kind, measured: 'hco3', actual: hco3, expected: exp, chronicity, key: respCompensation(hco3, exp, chronicity) };
  }
  return null;
}

export function validate(input) {
  const { ph, paco2, hco3 } = input;
  if ([ph, paco2, hco3].some((v) => v == null || Number.isNaN(v))) return 'incomplete';
  for (const [k, [lo, hi]] of Object.entries(LIMITS)) {
    const v = input[k];
    if (v != null && !Number.isNaN(v) && (v < lo || v > hi)) return `out_of_range_${k}`;
  }
  return null;
}

/**
 * input: { ph, paco2 (mmHg), hco3 (mmol/L), na?, cl?, albumin? (g/dL),
 *          chronicity?: 'acute' | 'chronic' | 'unknown' }
 */
export function interpret(input) {
  const err = validate(input);
  if (err === 'incomplete') return { status: 'incomplete' };
  if (err) return { status: 'error', error: err };

  const { ph, paco2, hco3 } = input;
  const chronicity = input.chronicity === 'acute' || input.chronicity === 'chronic' ? input.chronicity : 'unknown';
  const res = { status: 'ok', flags: [], disorders: [], differentials: [] };

  // Step 0 — internal consistency (Henderson-Hasselbalch).
  const calc = hhPh(paco2, hco3);
  res.hh = { calculatedPh: round(calc, 2), difference: round(ph - calc, 2) };
  if (Math.abs(ph - calc) > HH_TOLERANCE) res.flags.push('hh_inconsistent');

  // Step 1 — pH.
  res.phStatus = ph < N.phLo ? 'acidemia' : ph > N.phHi ? 'alkalemia' : 'normal';

  // Step 2 — pattern → primary disorder.
  const co2Hi = paco2 > N.co2Hi, co2Lo = paco2 < N.co2Lo, bHi = hco3 > N.hco3Hi, bLo = hco3 < N.hco3Lo;
  let primary;
  if (res.phStatus === 'acidemia') {
    if (co2Hi && bLo) primary = 'combined_acidosis';
    else if (co2Hi) primary = 'respiratory_acidosis';
    else if (bLo) primary = 'metabolic_acidosis';
    else {
      // Both inside the reference ranges: the component past its midpoint,
      // larger deviation (scaled to each half-range) wins.
      const r = paco2 > N.co2 ? (paco2 - N.co2) / 5 : 0, m = hco3 < N.hco3 ? (N.hco3 - hco3) / 2 : 0;
      primary = r >= m && r > 0 ? 'respiratory_acidosis' : m > 0 ? 'metabolic_acidosis' : 'unclassified';
    }
  } else if (res.phStatus === 'alkalemia') {
    if (co2Lo && bHi) primary = 'combined_alkalosis';
    else if (co2Lo) primary = 'respiratory_alkalosis';
    else if (bHi) primary = 'metabolic_alkalosis';
    else {
      const r = paco2 < N.co2 ? (N.co2 - paco2) / 5 : 0, m = hco3 > N.hco3 ? (hco3 - N.hco3) / 2 : 0;
      primary = r >= m && r > 0 ? 'respiratory_alkalosis' : m > 0 ? 'metabolic_alkalosis' : 'unclassified';
    }
  } else {
    // Normal pH: no disorder, or an acidosis and alkalosis offsetting each other
    // (Brandis 9.2). A well-compensated chronic respiratory disorder can also
    // sit here, so test the chronic rule before calling it mixed.
    if (co2Hi && bHi) {
      const exp = respExpected(paco2, 'resp_acid').chronic;
      primary = hco3 >= exp.lo && hco3 <= exp.hi ? 'compensated_chronic_respiratory_acidosis' : 'respiratory_acidosis_with_metabolic_alkalosis';
      res.compensation = { rule: 'resp_acid', measured: 'hco3', actual: hco3, expected: respExpected(paco2, 'resp_acid'), chronicity: 'chronic',
        key: primary.startsWith('compensated') ? 'appropriate' : 'plus_metabolic_alkalosis' };
    } else if (co2Lo && bLo) {
      const exp = respExpected(paco2, 'resp_alk').chronic;
      primary = hco3 >= exp.lo && hco3 <= exp.hi ? 'compensated_chronic_respiratory_alkalosis' : 'metabolic_acidosis_with_respiratory_alkalosis';
      res.compensation = { rule: 'resp_alk', measured: 'hco3', actual: hco3, expected: respExpected(paco2, 'resp_alk'), chronicity: 'chronic',
        key: primary.startsWith('compensated') ? 'appropriate' : 'plus_metabolic_acidosis' };
    } else if (co2Hi || co2Lo || bHi || bLo) primary = 'normal_ph_single_abnormal';
    else primary = 'normal';
  }
  res.primary = primary;

  // Disorders present (for differentials and the delta ratio).
  const add = (d) => { if (!res.disorders.includes(d)) res.disorders.push(d); };
  const SIMPLE = ['metabolic_acidosis', 'metabolic_alkalosis', 'respiratory_acidosis', 'respiratory_alkalosis'];
  if (SIMPLE.includes(primary)) add(primary);
  if (primary === 'combined_acidosis') { add('respiratory_acidosis'); add('metabolic_acidosis'); }
  if (primary === 'combined_alkalosis') { add('respiratory_alkalosis'); add('metabolic_alkalosis'); }
  if (primary === 'compensated_chronic_respiratory_acidosis') add('respiratory_acidosis');
  if (primary === 'compensated_chronic_respiratory_alkalosis') add('respiratory_alkalosis');
  if (primary === 'respiratory_acidosis_with_metabolic_alkalosis') { add('respiratory_acidosis'); add('metabolic_alkalosis'); }
  if (primary === 'metabolic_acidosis_with_respiratory_alkalosis') { add('metabolic_acidosis'); add('respiratory_alkalosis'); }

  // Step 4 — compensation for a single primary process.
  if (SIMPLE.includes(primary)) {
    res.compensation = compensate(primary, { paco2, hco3, chronicity });
    const second = SECOND[res.compensation.key];
    if (second) add(second);
  }

  // Step 3 — anion gap and delta ratio.
  const { na, cl, albumin } = input;
  if (na != null && cl != null && !Number.isNaN(na) && !Number.isNaN(cl)) {
    const ag = na - cl - hco3;
    const hasAlb = albumin != null && !Number.isNaN(albumin);
    const corrected = hasAlb ? ag + 2.5 * (N.alb - albumin) : null;
    const used = corrected ?? ag;
    res.ag = { value: round(ag), corrected: corrected == null ? null : round(corrected), used: round(used), key: used >= 12 ? 'high' : 'normal' };
    if (!hasAlb) res.flags.push('albumin_not_entered');
    if (!res.disorders.includes('metabolic_acidosis')) {
      if (used > 30) res.flags.push('hidden_acidosis_definite');
      else if (used >= 20) res.flags.push('hidden_acidosis_likely');
    } else if (hco3 < N.hco3) {
      const dr = (used - N.ag) / (N.hco3 - hco3);
      const key = dr < 0.4 ? 'nagma' : dr < 0.8 ? 'hagma_plus_nagma' : dr <= 2 ? 'hagma' : 'hagma_plus_high_hco3';
      res.deltaRatio = { value: round(dr, 2), key };
    }
  } else if (res.disorders.includes('metabolic_acidosis')) {
    res.flags.push('enter_electrolytes_for_gap');
  }

  // Differentials, one list per disorder; metabolic acidosis split by gap type.
  for (const d of res.disorders) {
    if (d !== 'metabolic_acidosis') { res.differentials.push(d); continue; }
    const k = res.deltaRatio?.key;
    if (k === 'nagma') res.differentials.push('nagma');
    else if (k === 'hagma_plus_nagma') res.differentials.push('hagma', 'nagma');
    else if (k) res.differentials.push('hagma');
    else if (res.ag) res.differentials.push(res.ag.key === 'high' ? 'hagma' : 'nagma');
    else res.differentials.push('hagma', 'nagma');
  }
  if (res.flags.includes('hidden_acidosis_likely') || res.flags.includes('hidden_acidosis_definite')) res.differentials.push('hagma');
  res.differentials = [...new Set(res.differentials)];
  return res;
}

export { N as NORMALS, hhPh, respExpected };
