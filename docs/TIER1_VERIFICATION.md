# Tier 1 content verification log

Double-checking accuracy-critical formulas, doses, and thresholds against
primary / authoritative sources. Started 2026-09-01.

Legend: ✅ confirmed as-is · ✏️ corrected · ⚠️ still needs a primary source the
maintainer must supply · 🔲 not yet checked

---

## Calculators — formulas

### ✅ MELD-Na (`gi-renal-metabolic/meld-na.json`)
- Coefficients `3.78·ln(bili) + 11.2·ln(INR) + 9.57·ln(Cr) + 6.43` **confirmed** —
  identical to the OPTN 2016 form `0.957·ln(Cr) + 0.378·ln(bili) + 1.120·ln(INR)
  + 0.643`, ×10. (MDCalc / OPTN policy.)
- Floor labs at 1.0, cap Cr at 4.0 (or dialysis) — implemented via
  `min(max(Cr,1),4)`, `max(bili,1)`, `max(INR,1)`. ✅
- Na bounded 125–137 before the correction — implemented. ✅
- Engine output spot-check: bili 5 / INR 2 / Cr 1.5 / Na 130 → MELD 24, MELD-Na 28
  (hand calc 27.8). ✅
- **Deviation, documented:** OPTN only applies the Na term when MELD(i) > 11, and
  clamps the final score to 6–40. The module applies the Na term always (matches
  MDCalc's displayed "MELD-Na") and does not clamp. Fine for a bedside estimate;
  noted in `buildNote`. Flag downgraded from `verify-coefficients` → keep a note.

---

# Full Tier 1 sweep — calculators/ + drug-dosing/ (59 modules)

Verification pass 2026-09-01. Every module below was checked against the cited
primary derivation paper and/or MDCalc. Emoji per the legend at the top of this
file. Numeric spot-claims are listed; unremarkable descriptive text is not.

## Weighted / additive scores

### ✅ padua-prediction-score
- 11 items, point weights 3/3/3/3 (cancer, prior VTE, reduced mobility, thrombophilia),
  2 (recent trauma/surgery ≤1 mo), 1×6 (age ≥70, cardioresp failure, acute MI/stroke,
  acute infection/rheum, obesity BMI ≥30, hormonal Rx): all confirmed vs Barbar 2010.
- Max score 20: confirmed.
- Cutoff: low 0–3 / high ≥4: confirmed (Barbar high-risk = ≥4).
- Source(s): Barbar S et al. J Thromb Haemost 2010;8:2450–7 (PMID 20738765);
  https://www.mdcalc.com/calc/1752/padua-prediction-score-risk-vte

### ✅ four-ts-hit
- Thrombocytopenia 0/1/2, Timing 0/1/2, Thrombosis 0/1/2, oTher cause 0/1/2 — all
  sub-option wording and points match Lo 2006 and MDCalc (incl. "fall >50% AND nadir
  ≥20, no surgery within 3 days" = 2; timing "days 5–10 or ≤1 day w/ heparin in past
  30 d" = 2; other cause "none apparent" = 2).
- Bands: low 0–3, intermediate 4–5, high 6–8: confirmed.
- Source(s): Lo GK et al. J Thromb Haemost 2006;4:759–65 (PMID 16634744);
  https://www.mdcalc.com/calc/1787/4ts-score-heparin-induced-thrombocytopenia

### ✅ wells-pe
- Item weights 3 (DVT signs), 3 (PE #1 dx), 1.5 (HR >100), 1.5 (immob/surgery),
  1.5 (prior VTE), 1 (hemoptysis), 1 (malignancy): confirmed vs Wells 2000.
- 3-tier bands low <2 / moderate 2–6 / high >6 (module: 0–1.5 / 2–6 / 6.5–12.5): correct.
- Dichotomized ≤4 "unlikely" / >4 "likely": confirmed (Wells 2001).
- Risk annotations (~1.3–3% / ~16% / ~40%) in line with published 3-tier rates.
- Source(s): Wells PS et al. Thromb Haemost 2000;83:416–20; Wells PS et al. Ann Intern
  Med 2001;135:98–107; https://www.mdcalc.com/calc/115/wells-criteria-pulmonary-embolism

### ✅ wells-dvt
- 9 items at +1, alternative diagnosis at −2: confirmed vs Wells 1997 / 2003 modified
  (module correctly includes "previously documented DVT" +1 = the 2003 revision).
- 3-tier bands: low ≤0 / moderate 1–2 / high ≥3 (module −2–0 / 1–2 / 3–9): correct.
- Risk ~5% / ~17% / ~53%: consistent with commonly cited rates.
- Note (not an error): the modified 2-tier reading (≥2 "DVT likely" / <2 "unlikely")
  is not shown; add for completeness.
- Source(s): Wells PS et al. Lancet 1997;350:1795–8; Wells PS et al. NEJM
  2003;349:1227–35; https://www.mdcalc.com/calc/362/wells-criteria-dvt

### ✏️ rcri
- 6 items at 1 point each (high-risk surgery, IHD, CHF, cerebrovascular disease,
  insulin-treated DM, creatinine >2.0 mg/dL): confirmed vs Lee 1999.
- Class boundaries 0 / 1 / 2 / ≥3: confirmed.
- CORRECTION (risk annotations): module lists Class III ≈ 2.4% and Class IV ≈ 5.4%+.
  No published cohort supports those; every source puts ≥2 factors materially higher.
  Lee 1999 validation cohort: I 0.4%, II 0.9%, III 6.6%, IV 11%. Contemporary
  nationwide cohort: 0.2% / 1.0% / 4% / 8%. VISION/CCS-2017 pooled: 3.9% / 6.0% /
  10.1% / 15.0%. Recommend adopting the Lee 1999 validation set (0.4 / 0.9 / 6.6 / 11%)
  or the nationwide contemporary set (0.2 / 1.0 / 4 / 8%) with an explicit citation.
  Class I (~0.4%) and Class II (~1%) as written are fine.
- Source(s): Lee TH et al. Circulation 1999;100:1043–9 (PMID 10477528);
  https://en.wikipedia.org/wiki/Revised_Cardiac_Risk_Index;
  Devereaux/CCS 2017 (Duceppe et al. Can J Cardiol 2017;33:17–32).

### ✅ heart-score
- History 0/1/2, ECG 0/1/2, Age <45=0 / 45–64=1 / ≥65=2, Risk factors 0/1/2
  (≥3 RF or known atherosclerotic disease = 2), Troponin ≤1×=0 / 1–3×=1 / >3×=2:
  matches the Backus 2013 validation form used by MDCalc.
- Bands 0–3 low (~1–2%) / 4–6 moderate (~12–17%) / 7–10 high (~50–65%): confirmed.
- Note: the 2008 original (Six et al.) used 1–2×/>2× troponin bins; module follows the
  dominant validated version. Acceptable, no change needed.
- Source(s): Six AJ et al. Neth Heart J 2008;16:191–6; Backus BE et al. Int J Cardiol
  2013;168:2153–8; https://www.mdcalc.com/calc/1752/heart-score-major-cardiac-events

### ✅ timi-nstemi
- 7 predictors at 1 point each: confirmed vs Antman 2000 and MDCalc.
- Risk bands: 0–1 ~5% (paper 4.7%), 2–4 ~8–20% (8.3 / 13.2 / 19.9%), 5–7 ~26–41%
  (26.2 / 40.9%): all consistent with the JAMA 2000 table.
- Source(s): Antman EM et al. JAMA 2000;284:835–42 (PMID 10938172);
  https://www.mdcalc.com/calc/111/timi-risk-score-ua-nstemi

### ✅ lrinec
- CRP ≥150 = 4; WBC <15/15–25/>25 = 0/1/2; Hgb >13.5/11–13.5/<11 = 0/1/2;
  Na <135 = 2; Cr >1.6 mg/dL = 2; glucose >180 mg/dL = 1: all confirmed vs Wong 2004
  (glucose is correctly weighted 1, not 2).
- Max 13: confirmed. Bands ≤5 low (<50%) / 6–7 intermediate (50–75%) / ≥8 high (>75%):
  confirmed.
- Source(s): Wong CH et al. Crit Care Med 2004;32:1535–41 (PMID 15241098);
  https://www.mdcalc.com/calc/1734/lrinec-score-necrotizing-soft-tissue-infection

### ✅ abcd2
- Age ≥60 = 1; BP ≥140/90 = 1; clinical: unilateral weakness = 2 / speech disturbance
  w/o weakness = 1 / other = 0; duration ≥60 min = 2 / 10–59 = 1 / <10 = 0; diabetes = 1:
  all confirmed vs Johnston 2007.
- Bands 0–3 / 4–5 / 6–7 with 2-day stroke risk ~1% / ~4% / ~8% (paper 1.0 / 4.1 / 8.1%):
  confirmed.
- Source(s): Johnston SC et al. Lancet 2007;369:283–92 (PMID 17258668).

### ✅ cha2ds2-vasc
- CHF 1, HTN 1, Age ≥75 = 2 / 65–74 = 1, DM 1, Stroke/TIA/TE = 2, Vascular disease 1,
  Female 1: confirmed vs Lip 2010. Max 9.
- Disposition logic (score 0 men = none; score 1 = consider; female sex-only point
  treated as low risk; ≥2 = anticoagulate): matches ESC 2020.
- Annual-risk figures (~0.2 / ~0.6 / ≥2.2%/yr) are on the low end but within the range
  of published cohorts (Friberg/Swedish). Acceptable.
- Source(s): Lip GYH et al. Chest 2010;137:263–72; ESC 2020 AF guidelines
  (Hindricks G et al. Eur Heart J 2021;42:373–498).

### ✅ has-bled
- 9 items at 1 point each (HTN uncontrolled SBP >160; abnormal renal — dialysis/
  transplant/Cr >2.26 mg/dL; abnormal liver; stroke; bleeding hx; labile INR TTR <60%;
  elderly >65; drugs antiplatelet/NSAID; alcohol ≥8/wk): confirmed vs Pisters 2010.
  Renal and liver score separately, drugs and alcohol score separately → max 9: correct.
- Bands 0–2 low / ≥3 high: confirmed.
- Source(s): Pisters R et al. Chest 2010;138:1093–100 (PMID 20299623).

### ✅ apfel-ponv
- 4 factors (female, non-smoker, PONV/motion-sickness hx, postop opioids), 1 each.
- Per-score risk 0→~10%, 1→~20%, 2→~40%, 3→~60%, 4→~80%: matches Apfel 1999
  (10 / 21 / 39 / 61 / 79%).
- Source(s): Apfel CC et al. Anesthesiology 1999;91:693–700 (PMID 10485781).

### ✅ stop-bang
- 8 yes/no items (Snoring, Tired, Observed apnea, Pressure/HTN, BMI >35, Age >50,
  Neck >40 cm, male sex): confirmed vs Chung 2008.
- Bands 0–2 low / 3–4 intermediate / 5–8 high for moderate–severe OSA: confirmed.
- Source(s): Chung F et al. Anesthesiology 2008;108:812–21; Chung F et al. Br J
  Anaesth 2012;108:768–75.

### ✅ alvarado
- Migration 1, Anorexia 1, Nausea/vomiting 1, RLQ tenderness 2, Rebound 1,
  Temp ≥37.3 °C 1, Leukocytosis >10k 2, Left shift 1: confirmed vs Alvarado 1986. Max 10.
- Bands 1–4 unlikely / 5–6 equivocal / 7–10 high: standard grouping, confirmed.
- Source(s): Alvarado A. Ann Emerg Med 1986;15:557–64 (PMID 3963537).

### ✅ aims65
- Albumin <3.0 g/dL, INR >1.5, altered Mental status, SBP ≤90, Age ≥65 — 1 point each.
- Mortality bands 0–1 ~0.3–1% / 2 ~3% / 3–5 ~9–25%: matches Saltzman 2011
  (0.3 / 1 / 3 / 9 / 15 / 25%).
- Minor: original Saltzman wording is "age >65"; module and MDCalc use "≥65". Affects
  only patients exactly 65 — note, not a required change.
- Source(s): Saltzman JR et al. Gastrointest Endosc 2011;74:1215–24 (PMID 21907980).

### ✅ bisap
- BUN >25 mg/dL, impaired mental status, SIRS ≥2, Age >60, pleural effusion — 1 each.
- Bands 0–2 (<2% mortality) / 3–5 (higher): consistent with Wu 2008 (0→0.1%, 2→1.6%,
  3→3.6%, 4→7.4%, 5→9.5–22%).
- Source(s): Wu BU et al. Gut 2008;57:1698–703 (PMID 18519429).

### ✅ curb-65
- Confusion, Urea >7 mmol/L (BUN >19), RR ≥30, SBP <90 or DBP ≤60, Age ≥65 — 1 each.
- Bands 0–1 (~1.5%) / 2 (~9%) / 3–5 (~22%) 30-day mortality: matches Lim 2003
  (0.6–2.7% / 9.2% / 14.5–57%).
- Source(s): Lim WS et al. Thorax 2003;58:377–82 (PMID 12728155).

### ✅ perc-rule
- 8 criteria (age ≥50, HR ≥100, SpO2 <95%, unilateral leg swelling, hemoptysis,
  recent surgery/trauma ≤4 wk, prior VTE, hormone use): confirmed vs Kline 2004/2008.
- PERC-negative (all absent) → <2% PE in low-pretest population: confirmed.
- Source(s): Kline JA et al. J Thromb Haemost 2004;2:1247–55; Kline JA et al. J Thromb
  Haemost 2008;6:772–80.

### ✅ centor-mcisaac
- Exudate 1, tender anterior nodes 1, fever >38 °C 1, cough absent 1; McIsaac age
  3–14 = +1 / 15–44 = 0 / ≥45 = −1: confirmed vs Centor 1981 + McIsaac 1998.
- Bands (−1–1 low / 2–3 intermediate / 4–5 high) with GAS probability ~1–10% / ~11–35% /
  ~50%+: consistent with McIsaac validation.
- Source(s): Centor RM et al. Med Decis Making 1981;1:239–46; McIsaac WJ et al. CMAJ
  1998;158:75–83.

### ✅ qsofa
- RR ≥22, altered mentation (GCS <15), SBP ≤100 — 1 each; ≥2 = high risk: confirmed
  vs Seymour/Sepsis-3 2016. Note against single-tool screening use matches SSC 2021.
- Source(s): Seymour CW et al. JAMA 2016;315:762–74 (PMID 26903335).

### ✅ sirs
- Temp >38 or <36; HR >90; RR >20 or PaCO2 <32 mmHg; WBC >12k, <4k, or >10% bands —
  1 each; ≥2 = SIRS: confirmed vs ACCP/SCCM 1992.
- Source(s): Bone RC et al. Chest 1992;101:1644–55 (PMID 1303622).

### ✅ nexus-cspine
- 5 criteria (midline c-spine tenderness, focal neuro deficit, altered alertness,
  intoxication, distracting injury); all absent → no imaging: confirmed vs Hoffman 2000.
- Source(s): Hoffman JR et al. NEJM 2000;343:94–9 (PMID 10891516).

### ✅ lemon-airway
- L 0–1, E (3-3-2) 0–3, M (Mallampati ≥3) 0–1, O 0–1, N 0–1 → max 7: matches the
  Reed 2005 LEMON score construction. No validated numeric cutoff exists; the module's
  bands are explicitly labelled pragmatic UI guidance — acceptable.
- Source(s): Reed MJ et al. Emerg Med J 2005;22:99–102 (PMID 15662058).

## Classification scales (no arithmetic)

### ✅ asa-physical-status
- ASA I–VI descriptions and examples match the ASA 2020 approved wording (incl.
  BMI bands, MI/CVA >3 mo vs <3 mo, "E" modifier). Confirmed.
- Source: https://www.asahq.org/standards-and-practice-parameters/statement-on-asa-physical-status-classification-system

### ✅ cormack-lehane
- Grades 1 / 2a / 2b / 3 / 4 with the Yentis 1998 2a/2b split (2a = partial glottis,
  2b = arytenoids/posterior cords only): confirmed.
- Source(s): Cormack RS, Lehane J. Anaesthesia 1984;39:1105–11; Yentis SM, Lee DJ.
  Anaesthesia 1998;53:1041–4.

### ✅ mallampati
- Class I–IV oropharyngeal-structure definitions match Mallampati 1985 / Samsoon &
  Young 1987. Confirmed.
- Source(s): Mallampati SR et al. Can Anaesth Soc J 1985;32:429–34; Samsoon GL,
  Young JR. Anaesthesia 1987;42:487–90.

### ✅ modified-aldrete
- 5 categories × 0–2 (Activity, Respiration, Circulation ±20/±20–50/±50 mmHg,
  Consciousness, SpO2 >92% RA / needs O2 / <90% on O2), max 10; discharge ≥9
  (some centres ≥8): confirmed vs Aldrete 1995.
- Source(s): Aldrete JA. J Clin Anesth 1995;7:89–91 (PMID 7772368).

### ✅ killip-classification
- Class I–IV (no CHF / rales-S3-JVP / frank pulmonary edema / cardiogenic shock):
  confirmed vs Killip & Kimball 1967.
- Source(s): Killip T, Kimball JT. Am J Cardiol 1967;20:457–64 (PMID 6059183).

### ✅ rass
- +4…−5 with the validated descriptors (−1 ≥10 s eye contact to voice, −2 <10 s,
  −3 movement/eye-opening no eye contact, −4 movement to physical stim, −5 none);
  CAM-ICU arousal gate RASS ≥ −3: confirmed vs Sessler 2002.
- Source(s): Sessler CN et al. Am J Respir Crit Care Med 2002;166:1338–44 (PMID 12421743).

### ✅ gcs
- Eye 1–4, Verbal 1–5, Motor 1–6 with standard descriptors; severity mild 13–15 /
  moderate 9–12 / severe ≤8: confirmed vs Teasdale & Jennett 1974.
- Source(s): Teasdale G, Jennett B. Lancet 1974;304:81–4 (PMID 4136544).

### ✅ hunt-hess
- Grades I–V descriptors (asymptomatic/mild HA → deep coma/decerebrate): confirmed
  vs Hunt & Hess 1968. Mortality ranges are approximate but directionally standard.
- Source(s): Hunt WE, Hess RM. J Neurosurg 1968;28:14–20 (PMID 5635959).

## Formula calculators

### ✅ qtc
- Bazett QTc = QT / √(RR), RR = 60/HR → `qt / sqrt(60/hr)`: correct.
- Fridericia QTc = QT / RR^(1/3) → `qt / cbrt(60/hr)`: correct.
- Bands <440 normal / 440–499 borderline–prolonged / ≥500 markedly prolonged: a
  defensible convention. Note: AHA/ACCF/HRS 2009 defines "prolonged" at >450 ms (men) /
  >460 ms (women) and "markedly abnormal" at ≥500; module's note already states the
  460 ms women threshold. No change required, but the borderline band could start at
  450 for men to match the 2009 statement.
- Interpretation is attached only to `bazett`; consider adding a Fridericia band set.
- Source(s): Bazett HC. Heart 1920;7:353–70; Fridericia LS. Acta Med Scand 1920;53:
  469–86; Rautaharju PM et al. (AHA/ACCF/HRS) Circulation 2009;119:e241–50.

### ✅ anion-gap
- AG = Na − (Cl + HCO3): correct.
- Albumin-corrected AG = AG + 2.5 × (4 − albumin g/dL): correct (Figge).
- Normal ≤11 / high ≥12 (K+ not included): matches MDCalc's elevated-at-≥12 convention;
  method-dependent, note in UI.
- Source(s): Emmett M, Narins RG. Medicine (Baltimore) 1977;56:38–54; Figge J et al.
  J Lab Clin Med 1991;117:453–67; https://www.mdcalc.com/calc/1669/anion-gap

### ✅ corrected-calcium
- Corrected Ca = measured Ca + 0.8 × (4.0 − albumin g/dL): confirmed vs Payne 1973.
- Normal band 8.5–10.5 mg/dL: standard. Caveat about ionized Ca in critical illness
  correctly stated.
- Source(s): Payne RB et al. Br Med J 1973;4:643–6 (PMID 4758544).

### ✅ corrected-sodium-hyperglycemia
- Hillier: corrected Na = measured Na + 2.4 × ((glucose − 100)/100): confirmed vs
  Hillier 1999. Katz constant (1.6) correctly attributed and deliberately omitted.
- Normal band 135–145: standard.
- Source(s): Hillier TA et al. Am J Med 1999;106:399–403 (PMID 10225241); Katz MA.
  N Engl J Med 1973;289:843–4.

### ✅ maddrey-df
- DF = 4.6 × (patient PT − control PT) + total bilirubin (mg/dL): confirmed vs Maddrey
  1978 / Carithers 1989. Severe ≥32: confirmed. Prednisolone 40 mg/day + Lille day-7
  reassessment: consistent with STOPAH-era practice.
- Source(s): Maddrey WC et al. Gastroenterology 1978;75:193–9 (PMID 208754);
  Carithers RL et al. Ann Intern Med 1989;110:685–90 (PMID 2648927).

### ✅ meld-na
- Re-confirmed in agreement with the existing entry above (OPTN 2016 form ×10;
  coefficients 3.78 / 11.2 / 9.57 / 6.43; lab floors/caps as described).

### ✅ cockcroft-gault
- CrCl = ((140 − age) × wt × (1 − 0.15·female)) / (72 × SCr): the 0.85 female factor is
  correctly encoded as (1 − 0.15). Confirmed vs Cockcroft & Gault 1976.
- Bands are CKD GFR categories (<15 / 15–29 / 30–59 / ≥60): fine.
- Source(s): Cockcroft DW, Gault MH. Nephron 1976;16:31–41 (PMID 1244564).

### ✅ ideal-body-weight
- Devine: men 50 + 2.3×(in − 60); women 45.5 + 2.3×(in − 60) — encoded as
  50 − 4.5·female + 2.3×(heightIn − 60): correct.
- ARDSNet TV at 6 and 8 mL/kg IBW: correct multiplication.
- Source(s): Devine BJ. Drug Intell Clin Pharm 1974;8:650–5; ARDSNet, NEJM
  2000;342:1301–8.

### ✅ adjusted-body-weight
- AdjBW = IBW + 0.4 × (actual − IBW): standard.
- Janmahasatian LBW — men (9270·wt)/(6680 + 216·BMI), women (9270·wt)/(8780 + 244·BMI):
  confirmed (agrees with the session's prior verification). The `verify-coefficients`
  flag and buildNote can be cleared.
- BMI = wt / height_m²: correct.
- Source(s): Janmahasatian S et al. Clin Pharmacokinet 2005;44:1051–65 (PMID 16176118);
  https://www.mdcalc.com/calc/68/ideal-body-weight-adjusted-body-weight

### ✅ parkland-formula
- Total 24 h = 4 × %TBSA × kg (LR); first 8 h = half; rate8 = half/8; rate16 = half/16:
  all correct. UOP targets 0.5 mL/kg/h adult, 1 mL/kg/h child <30 kg: correct. Modified
  Brooke (2 mL/kg/%) alternative correctly noted.
- Source(s): Baxter CR, Shires T. Ann N Y Acad Sci 1968;150:874–94; ABA Advanced Burn
  Life Support.

### ✅ free-water-deficit
- TBW fraction map 0.6 / 0.5 / 0.45 via (0.6 − 0.1·sel) with sel = 0 / 1 / 1.5: arithmetic
  checks out.
- Deficit = TBW × ((currentNa/140) − 1): the standard free-water-deficit formula.
- Correction rate ≤8–10 mEq/L/24 h: correct.
- Note: the cited Adrogué–Madias 2000 paper's headline equation is the "Δ[Na] per litre
  of infusate" formula; the deficit formula used here is the conventional one and is
  fine, but a more exact citation (e.g. Rose/Adrogué textbook) would be tidier.
- Source(s): Adrogué HJ, Madias NE. N Engl J Med 2000;342:1493–9 (PMID 10816188).

### ✅ holliday-segar-maintenance-fluids
- Hourly 4-2-1 piecewise: 4·min(wt,10) + 2·clip(wt−10,0,10) + 1·max(wt−20,0): correct.
- daily = 24 × hourly. Minor: this is the 4-2-1 approximation (≈96/48/24 mL/kg/day),
  slightly below the exact daily method (100/50/20 mL/kg/day) — e.g. 10 kg → 960 vs
  1000 mL/day. Both are "Holliday-Segar"; acceptable, worth a one-line note.
- Source(s): Holliday MA, Segar WE. Pediatrics 1957;19:823–32 (PMID 13431307).

### ✅ vasoactive-inotropic-score
- VIS = dopamine + dobutamine + 100·epi + 100·norepi + 10·milrinone + 10000·vasopressin:
  matches the original Gaies 2010 formula (norepinephrine ×100 IS part of the original;
  phenylephrine ×100 is an optional later add-on, correctly noted as omitted).
- Bands 0–15 / 15–30 / >30 are explicitly labelled approximate/cohort-dependent —
  acceptable (no canonical cutoffs exist).
- Source(s): Gaies MG et al. Pediatr Crit Care Med 2010;11:234–8 (PMID 19794327);
  Koponen T et al. Br J Anaesth 2019;122:428–36.

### ✅ apap-nac-dosing
- Rumack-Matthew treatment line 150 × 2^(−(h−4)/4): halves every 4 h from 150 at 4 h;
  gives 4.7 µg/mL at 24 h — matches the nomogram's 24 h endpoint exactly. Correct
  approximation.
- IV NAC 3-bag: 150 mg/kg load, 50 mg/kg/4 h, 100 mg/kg/16 h (300 mg/kg / 21 h):
  confirmed (Prescott protocol).
- Source(s): Rumack BH, Matthew H. Pediatrics 1975;55:871–6; Prescott LF et al. Br Med
  J 1979;2:1097–100; https://www.mdcalc.com/calc/86/acetaminophen-overdose-nac-dosing

### ✅ peds-drip-rate
- rate (mL/h) = dose (mcg/kg/min) × wt (kg) × 60 / concentration (mcg/mL):
  dimensionally correct; unit-conversion caveat (mg/mL → mcg/mL ×1000) stated.

### ✅ osmolal-gap
- Calc osm = 2·Na + glucose/18 + BUN/2.8 + ethanol/3.7: standard US (mg/dL) form;
  ethanol/3.7 is the conventional divisor (MDCalc uses the same). Gap >10 abnormal:
  standard. Alternative 1.86·Na − 9 form correctly noted.
- Source(s): Krasowski MD et al. BMC Clin Pathol 2012;12:1; https://www.mdcalc.com/calc/91/serum-osmolality-osmolarity

### ✅ shock-index
- SI = HR / SBP; normal 0.5–0.7, borderline 0.7–1.0, ≥1.0 = occult shock likely:
  confirmed vs Allgöwer & Burri 1967 and modern trauma literature.
- Source(s): Allgöwer M, Burri C. Dtsch Med Wochenschr 1967;92:1947–50; Rady MY et al.
  Am J Emerg Med 1994;12:1–6.

### ✅ rox-index
- ROX = (SpO2/FiO2) / RR; ≥4.88 success / 3.85–4.87 indeterminate / <3.85 high failure
  risk: confirmed vs Roca 2019 (agrees with session's prior verification).
- Source(s): Roca O et al. Am J Respir Crit Care Med 2019;199:1368–76 (PMID 30576221).

### ✅ nihss
- All 15 item ranges correct (1a 0–3, 1b 0–2, 1c 0–2, 2 0–2, 3 0–3, 4 0–3, 5a/5b 0–4,
  6a/6b 0–4, 7 0–2, 8 0–2, 9 0–3, 10 0–2, 11 0–2); sum max 42.
- Severity bands 0 / 1–4 / 5–15 / 16–20 / 21–42: one of several published schemes;
  buildNote acknowledges the alternate <5 / 5–14 / 15–24 cut-points. Acceptable;
  cite the chosen scheme in the UI.
- Source(s): Brott T et al. Stroke 1989;20:864–70 (PMID 2749846); NIH/NINDS official
  NIHSS.

### ⚠️ grace-acs
- engine = external; only input structure + cutoffs shipped, by design.
- Cutoffs <109 low (<1% in-hospital mortality) / 109–140 intermediate (1–3%) / >140
  high (>3%): confirmed against the published GRACE risk bands and ESC 2023 "early
  invasive at GRACE >140".
- Cannot verify the proprietary GRACE 2.0 non-linear coefficients — none are published;
  the module correctly does not attempt them. Maintainer must license gracescore.org
  logic or ship a labelled nomogram approximation.
- Source(s): Fox KAA et al. BMJ 2006;333:1091 (PMID 17032691); Byrne RA et al. (ESC
  2023 ACS) Eur Heart J 2023;44:3720–3826.

## Drug-dosing cards

### ✅ peds-epinephrine-arrest
- 0.01 mg/kg IV/IO (0.1 mL/kg of 0.1 mg/mL), max single dose 1 mg, q3–5 min: confirmed
  vs PALS. ETT 0.1 mg/kg (1 mg/mL), max 2.5 mg, 10× IV/IO dose: confirmed.
- Source(s): AHA PALS 2020/2023 (Topjian AA et al. Circulation 2020;142:S469–S523).

### ✅ peds-adenosine-svt
- 1st 0.1 mg/kg (max 6 mg), 2nd 0.2 mg/kg (max 12 mg): confirmed vs PALS. Unstable →
  synchronized cardioversion 0.5–1 J/kg then 2 J/kg: confirmed.
- Source(s): AHA PALS 2020/2023.

### ✅ peds-atropine-bradycardia
- 0.02 mg/kg IV/IO, min single dose 0.1 mg, max single dose 0.5 mg (child) / 1 mg
  (adolescent), may repeat once: confirmed vs PALS. Not for PEA/asystole: correct.
- Note: the 0.1 mg minimum is retained by most current references (PALS provider
  manual, Lexicomp), though the 2020 guidelines noted weak evidence for a hard floor.
  Keeping it is the safe/standard choice.
- Source(s): AHA PALS 2020/2023.

### ✅ peds-amiodarone-arrest
- 5 mg/kg IV/IO bolus, max single dose 300 mg, may repeat ×2 (3 doses total) for
  refractory VF/pVT: confirmed vs PALS (agrees with session's correction removing the
  erroneous 150 mg subsequent cap). Lidocaine 1 mg/kg alternative: correct.
- Source(s): AHA PALS 2020/2023; Circulation 2020;142:S469–S523.

### ✅ peds-ketamine-rsi
- 1–2 mg/kg IV/IO induction: confirmed (common EM/anesthesia range; 1.5–2 mg/kg also
  cited). IM 3–4 mg/kg when no IV: acceptable — some sources use 4–5 mg/kg IM for a
  dissociative dose; consider widening the note to "3–5 mg/kg IM".
- Age <3 months laryngospasm caution: recognised relative contraindication.
- Source(s): Green SM et al. Ann Emerg Med 2011;57:449–61; ATOTW / peds RSI references.

### ✅ peds-rocuronium-rsi
- 1–1.2 mg/kg IV/IO for RSI: confirmed. Onset ~45–60 s, duration 30–60 min: correct.
- Sugammadex 16 mg/kg for immediate reversal of an RSI dose: confirmed.
- Succinylcholine alternative 1–2 mg/kg IV, max 150 mg: correct.
- Source(s): rocuronium/sugammadex labelling; Lexicomp Pediatric.

### ✅ peds-lorazepam-status
- 0.1 mg/kg IV, max 4 mg/dose, may repeat once after 5 min: confirmed vs AES 2016
  status epilepticus guideline.
- Source(s): Glauser T et al. Epilepsy Curr 2016;16:48–61 (PMID 26900382).

### ⚠️ peds-midazolam-status
- IM 0.2 mg/kg, max 10 mg: confirmed vs AES 2016 / RAMPART (RAMPART used 10 mg for
  ≥40 kg, 5 mg for 13–40 kg).
- IV 0.1–0.2 mg/kg, max 10 mg, may repeat once: the per-dose IV cap varies by source
  (many peds pathways cap IV midazolam at 5 mg/dose; AES does not list IV midazolam as
  first-line). Acceptable but flag for the maintainer to confirm against their local
  pathway.
- IN (intranasal) 0.2 mg/kg, max 10 mg: some references cap intranasal at 5 mg/dose
  (volume/absorption); confirm the intended max.
- Source(s): Glauser T et al. Epilepsy Curr 2016;16:48–61; Silbergleit R et al. (RAMPART)
  NEJM 2012;366:591–600.

### ✅ steroid-conversion
- Equivalent (anti-inflammatory) doses: hydrocortisone 20, cortisone 25, prednisone 5,
  prednisolone 5, methylprednisolone 4, triamcinolone 4, dexamethasone 0.75 mg — all
  match standard endocrinology tables. Relative potencies (1 / 0.8 / 4 / 4 / 5 / 5 /
  25–30) and durations correct.
- Worked example checks: prednisone 40 → methylprednisolone 32 (×4/5), dexamethasone 6
  (×0.75/5), hydrocortisone 160 (×20/5): all arithmetically correct.
- Mineralocorticoid caveat correctly stated.
- Source(s): standard (e.g. Williams Textbook of Endocrinology; Lexicomp glucocorticoid
  comparison table).

---

## Summary of corrections needed

1. **rcri** → interpretation risk annotations → Class III "≈2.4%" and Class IV "≈5.4%+"
   → replace with a citeable set: Lee 1999 validation **0.4% / 0.9% / 6.6% / 11%**
   (classes I–IV) or contemporary nationwide cohort **0.2% / 1.0% / 4% / 8%**; add the
   citation. Current III/IV values understate risk and match no published cohort.
   (Lee TH et al. Circulation 1999;100:1043–9.)

### Non-blocking notes (no correction required, maintainer discretion)

- **adjusted-body-weight**: Janmahasatian coefficients now verified twice — clear the
  `verify-coefficients` flag and the buildNote.
- **aims65**: original wording is "age >65"; module uses "≥65" (matches MDCalc). Harmonise
  if desired.
- **qtc**: consider starting the borderline band at 450 ms (men) to match AHA/ACCF/HRS
  2009; add an interpretation band set for the Fridericia output.
- **holliday-segar-maintenance-fluids**: `daily` uses 24×(4-2-1) ≈ 96/48/24 mL/kg/day,
  marginally below the exact 100/50/20 daily method — add a one-line note.
- **wells-dvt**: add the modified 2-tier reading (≥2 "DVT likely" / <2 "unlikely").
- **peds-midazolam-status**: confirm intended per-dose IV and intranasal caps (5 vs
  10 mg) against the local pathway.
- **peds-ketamine-rsi**: IM note could read "3–5 mg/kg" to match common dissociative-dose
  references.
- **free-water-deficit**: deficit formula is standard but is not the headline equation of
  the cited Adrogué–Madias 2000 paper; a textbook citation would be cleaner.
- **grace-acs** / **nihss**: `⚠️` reflects deliberate scope limits (proprietary model /
  examiner-scored items), not defects — cutoffs and item ranges are correct.

---

## Corrections applied (2026-09-01)

All 10 modules bumped `content_version` with a changelog entry; pipeline green
(`validate` 81/0/0, `test` 137/137, `check-staleness` 0 overdue).

| Module | Change |
|---|---|
| `rcri` v2 | Class III/IV risk 2.4% / 5.4%+ → **6.6% / 11%** (Lee 1999 validation), + a `notes` line on contemporary-cohort ranges. Score logic unchanged. |
| `peds-amiodarone-arrest` v2 | Removed the unverifiable 150 mg subsequent-dose cap → **5 mg/kg / max 300 mg all doses**, repeat ×2. |
| `adjusted-body-weight` v2 | Janmahasatian coefficients confirmed → `verify-coefficients` flag removed, sources expanded. |
| `meld-na` v2 | Coefficients confirmed as OPTN 2016 ×10 → `verify-coefficients` flag removed. |
| `qtc` v2 | Added a Fridericia interpretation band set; borderline band now starts at **450 ms** (men) per AHA/ACCF/HRS 2009. |
| `wells-dvt` v2 | Added the modified **2-tier reading** (≤1 unlikely → D-dimer / ≥2 likely → US); 3-tier labels tagged "(3-tier)". |
| `peds-midazolam-status` v2 | `institution-specific` flag + RAMPART fixed-dose bands (10 mg ≥40 kg / 5 mg 13-40 kg); IV & IN per-dose caps flagged for local reconciliation. |
| `peds-ketamine-rsi` v2 | IM route note 3-4 → **3-5 mg/kg** (dissociative dose). |
| `holliday-segar-maintenance-fluids` v2 | Note added: 24-h figure is 24×(4-2-1) ≈ 96/48/24, vs exact daily 100/50/20. |
| `free-water-deficit` v2 | Primary citation → standard textbook form (Rose/Post); Adrogué-Madias kept for rate-of-correction. |

**Net:** across 60 Tier-1 modules, **one** scoring/prognosis error found and fixed
(`rcri` risk %), plus the earlier `peds-amiodarone` dose-cap fix. Everything else
— all item weights, formula coefficients, drug doses, and interpretation
cutoffs — verified correct against primary sources.

**Still needs the maintainer:** GRACE 2.0 proprietary coefficients (module ships
inputs + cutoffs only, by design); `peds-midazolam-status` IV/IN caps to be set
per local pathway.

---

## Currency update — Fifth Universal Definition of MI (2026-09-01)

Source: CV `fifth-universal-definition-mi.html` (audits the ESC/ACC/AHA/WHF Fifth
UDMI, presented ESC Munich 2026-08-30, *Eur Heart J* 2026;ehag101 /
*JACC* 2026).

- **`twelve-lead-stemi-criteria` v2** — added the Fifth-UDMI framing: Type 1-5
  numbering → primary / secondary / procedure-related; procedure-related MI drops
  the fixed biomarker multiple (was >5× / >10× URL); **sex-specific troponin
  99th-percentile URLs**; MINOCA = myocardial *injury* (working dx). **The
  ST-elevation mm thresholds are unchanged** and still correct.
- **`heart-score` v2** — note added: the troponin "normal limit" is the assay's
  sex-specific 99th-percentile URL. Scoring unchanged.
- No other module's *logic* is affected — troponin-band scores (HEART, TIMI) just
  inherit the new reference limit.

---

# Batch 6 / 6b sweep — the xlsx calculators (2026-09-03)

Verification pass over the ~45 calculators added from `ED_ICU_OR_Calculators.xlsx`,
cross-checked against `build_package/Calculator_Logic_Build_Spec.md` (itself a
research pass vs MDCalc/derivation papers) and primary sources. Emoji per the
legend at the top of this file.

## ✏️ Corrected this pass

### ✏️ harris-benedict — coefficients
- Was built with the Roza-Shizgal 1984 revision (`88.362 + 13.397·W …`). Spec and
  MDCalc use the **original 1918** equation. Switched to
  men `66.5 + 13.75·W + 5.003·H − 6.775·A`, women `655.1 + 9.563·W + 1.850·H − 4.676·A`. v2.

### ✏️ news2 — temperature band
- `35.1–36.0 °C` was grouped with `≥ 39.1` at **2 points**; the RCP NEWS2 chart
  scores `35.1–36.0` at **1 point**. Split into `35.1–36.0 or 38.1–39.0 = 1`,
  `≥ 39.1 = 2`. v2.

### ✏️ apache-ii — GCS item
- Was banded (`GCS 6–8 → 8 pts`). APACHE points = `15 − actual GCS` exactly.
  Rebuilt as 13 per-value options (GCS 15→0 … GCS 3→12). All 12 APS variable
  bands, age points, and chronic-health points re-checked against the Knaus 1985
  table (via Merck Manual adaptation) — **all correct**.

### ✏️ caprini-vte — checklist + tiers
- Was an abbreviated ~12-item set with non-standard "count each" groupings and a
  0–1 / 2 / 3–4 / ≥5 scheme labelled very-low/low/moderate/high.
- Rebuilt to the **full 2005 checklist** (24 item rows incl. all 1/2/3/5-point
  factors) and the spec's **0–1 low / 2 moderate / 3–4 high / ≥5 highest** tier
  labels with the 2013-model prophylaxis text. v2.

### ✏️ psi-port — age term not summed
- Additive engine, but the `age` term ("age in years, −10 for women") was an
  option worth **0 points** → age contributed nothing to the score. Converted to
  the **formula engine** (like PESI): `psi = age − 10·sex + Σ weighted selects`.
  All 17 weighted point values re-verified against the spec — unchanged and
  correct. Class bands + mortality ranges aligned to Fine 1997 (I–II ≤70,
  III 71–90, IV 91–130, V >130). v2.

### ✏️ improve-bleed — age weight
- `age 40–84` was **1**; the Decousus 2011 model weights it **1.5**. Corrected.
  All other weights (GD ulcer 4.5, recent bleed 4, plt <50k 4, age ≥85 3.5,
  hepatic failure 2.5, severe renal 2.5, ICU 2.5, CVC 2, rheumatic 2, cancer 2,
  male 1, moderate renal 1) confirmed. Threshold ≥7 confirmed. v2.

### ✏️ ciwa-ar — severe band
- Severe band started at **≥16**; standard CIWA-Ar cut-point is **≥15**. Moved to
  `[0–8] / [9–14] / [15–67]`. 10 items × correct max (9×7 + orientation 4 = 67)
  confirmed. v2.

### ✏️ refeeding-risk — minor thresholds + banding
- `bmi` minor was `16–20` (should be NICE `< 18.5`); `weightLoss` minor was
  `> 5% in 3 months` (should be `> 10% in 3–6 months`). Fixed.
- Banding let a **single** minor criterion read as "at risk". Re-banded
  `[0–1] not at risk / [2] at risk (2 minor) / [3+] high (≥1 major or ≥3 minor)`,
  consistent with the NICE "1 major OR ≥2 minor" rule. v2.

## ✅ Confirmed as-is (spec + primary source)

- **Ottawa Knee Rule** — 5 factors, any positive → X-ray. Exact match (Stiell 1997).
- **Ottawa SAH Rule** — 6 factors, any positive → workup. Exact (Perry 2013).
- **YEARS** — 3 items; 0 → D-dimer 1000, ≥1 → 500. Exact (van der Hulle 2017).
- **Modified Sgarbossa** — concordant STE ≥1 / concordant STD V1–V3 / ST-S ratio
  ≤ −0.25; any positive. Exact (Smith 2012).
- **Brugada VT** — 4 sequential steps, any → VT. Exact (Brugada 1991).
- **Hunter serotonin** — 5 decision pathways, any → toxicity. Exact (Dunkley 2003).
- **CAM-ICU** — (Feat 1 AND Feat 2) AND (Feat 3 OR Feat 4). Rule in interpretation
  text; additive sum is a helper only. Correct (Ely 2001).
- **MEWS** — SBP/HR/RR/temp/AVPU bands match Subbe 2001; escalate ≥5.
- **CPOT** — 4 domains × 0–2, total 0–8, treat if > 2. Exact (Gélinas 2006).
- **ARDS Berlin** — 3 mandatory criteria (3 pts) + P/F band; totals 4/5/6 =
  mild/moderate/severe. P/F boundaries match Berlin (200 → moderate, 100 → severe).
- **SOFA, ICH, Canadian Syncope, Revised Geneva (original weights), Rockall,
  Ranson, COWS, Revised Trauma Score (T-RTS), FOUR, ABC/MTP, sPESI, PESI, BODE,
  ARISCAT, Surgical Apgar, El-Ganzouri, Canadian CT Head (CCHR), Canadian C-Spine
  (CCR), PECARN, Glasgow-Blatchford, ISS, RSBI, P/F ratio, salicylate-toxicity**
  — point values / formulas / bands all match the spec and cited sources.

## ⚠️ Known modelling limitations (not defects)

- **Ottawa Ankle Rules** — the rule is conjunctive (zone pain AND a bony-tenderness
  or weight-bearing finding). The additive engine flags any single positive input
  as "imaging indicated", which over-triages a lone "malleolar pain" entry. The
  interpretation text states the real conjunctive logic, and over-triage is the
  safe direction for a rule-*out* tool. Left as-is; a conjunctive engine would be
  the only true fix.
- **PECARN / Canadian rules / Sgarbossa / Brugada** — same pattern: additive sum
  is a helper, the branching logic lives in the interpretation text (weighted
  "high-risk" items force the correct band).

Pipeline after fixes: pending (validate/build/test/sync).
