# Calculator Logic Build Spec

**Purpose:** This is the computational layer the spreadsheets didn't have — actual point
values, formulas, and interpretation bands for every tool in `2 - Calculators`,
`3 - Drug & Dosing Cards`, and the PECARN entry in `5 - Peds Module`. Use this as the
source-of-truth spec when you actually build the calculator logic.

**Before you ship any of this:** A handful of these are complex, continuously-weighted,
or multi-page scoring systems (flagged below with ⚠️) where I've given you the structure
and cutoffs but you should verify the exact published coefficient table against MDCalc or
the original derivation paper before coding it — small transcription errors in a weighted
regression score are easy to make and hard to spot. Everything else below is a standard,
stable, well-published scoring system I'm confident in, but a second-source check against
MDCalc before go-live is still good practice for anything patient-facing.

---

## Section 2: Calculators

### Cardiovascular / Chest Pain / Arrhythmia

**HEART Score**
5 domains, 0–2 points each, total 0–10:
- History: slightly suspicious (0) / moderately suspicious (1) / highly suspicious (2)
- ECG: normal (0) / nonspecific repolarization change (1) / significant ST deviation (2)
- Age: <45 (0) / 45–64 (1) / ≥65 (2)
- Risk factors (HTN, hyperlipidemia, DM, obesity, smoking, family hx, atherosclerotic dz): 0 factors (0) / 1–2 factors (1) / ≥3 factors or known atherosclerotic disease (2)
- Troponin: ≤ normal limit (0) / 1–3× normal (1) / >3× normal (2)
- **Interpretation:** 0–3 low risk (~1–2% MACE) → discharge; 4–6 moderate (~12–17%) → observation/further testing; 7–10 high (~50–65%) → early invasive management

**TIMI Risk Score (UA/NSTEMI)**
7 factors, 1 point each, total 0–7: age ≥65, ≥3 CAD risk factors, known CAD (stenosis ≥50%), ASA use in prior 7 days, severe angina (≥2 episodes/24h), ST deviation ≥0.5mm, positive cardiac marker.
- **Interpretation:** higher score = higher 14-day risk of death/MI/urgent revascularization (roughly 5% at 0–1 up to 41% at 6–7).

**GRACE ACS Risk/Mortality Calculator** ⚠️ *(re-confirmed)*
Weighted regression model (not a simple additive point table) using age, heart rate, systolic BP, creatinine, Killip class, cardiac arrest at admission, ST-segment deviation, and elevated cardiac markers. Output converts to in-hospital and 1–3-year mortality percentages via the published GRACE 2.0 non-linear model (2014 revision).
- **Confirmed:** GRACE 2.0 has no publicly published simple closed-form equation — it's a proprietary non-linear model (originally built by QxMD from the 250-hospital, 102,341-patient GRACE registry). This isn't something to reverse-engineer from search results.
- **Confirmed cutoff:** GRACE score >140 identifies high-risk NSTE-ACS patients for early invasive strategy per both ESC 2023 and ACC/AHA 2025 guidelines.
- **Build note (unchanged):** either license/embed the official GRACE calculator logic (gracescore.org) or build an approximation from published nomogram risk bands — don't attempt to hand-derive the regression coefficients.

**Killip Classification**
Not a point score — a 4-tier clinical classification: I no CHF signs; II rales/S3/JVD; III frank pulmonary edema; IV cardiogenic shock. Mortality rises by class.

**CHA₂DS₂-VASc Score**
CHF/LV dysfunction (1), HTN (1), Age ≥75 (2), Diabetes (1), prior Stroke/TIA/thromboembolism (2), Vascular disease (1), Age 65–74 (1), Sex category female (1). Total 0–9.
- **Interpretation:** ≥2 (men) or ≥3 (women) generally supports anticoagulation.

**HAS-BLED Score**
1 point each: uncontrolled HTN (SBP>160), renal disease (dialysis/transplant/Cr>2.26mg/dL), liver disease, prior stroke, bleeding history/predisposition, labile INR, age >65, drugs (antiplatelet/NSAID), alcohol use (≥8 drinks/week). Total 0–9.
- **Interpretation:** ≥3 = high bleeding risk — weigh against CHA₂DS₂-VASc, don't withhold anticoagulation on this alone.

**Corrected QT Interval (QTc)**
- Bazett: `QTc = QT / sqrt(RR in seconds)`
- Fridericia (more accurate at extremes of HR): `QTc = QT / (RR)^(1/3)`
- **Interpretation:** normal <440ms (men) / <460ms (women); >500ms = high torsades risk, especially before adding another QT-prolonging drug.

**Modified Sgarbossa Criteria**
Positive if ANY of: concordant ST elevation ≥1mm in any lead; concordant ST depression ≥1mm in V1–V3; excessively discordant ST elevation with ST/S ratio ≤ −0.25 in at least one lead (proportional/Smith-modified criterion — this is the version that replaced the original's fixed ≥5mm discordant cutoff).

**Brugada Criteria for VT (4-step algorithm)**
1. Absence of RS complex in ALL precordial leads → VT
2. R-to-S interval >100ms in any one precordial lead → VT
3. AV dissociation present → VT
4. Morphology criteria for VT present in both V1-2 and V6 → VT
If none of the above → SVT with aberrancy.

**Canadian Syncope Risk Score** ⚠️ *(range and cutoff confirmed; full per-item table still needs final MDCalc cross-check)*
Weighted variables (approximate published values): predisposition to vasovagal symptoms (−1), history of heart disease (+1), any SBP <90 or >180 in ED (+2), elevated troponin above normal (+2), abnormal QRS axis (+1), QRS duration >130ms (+1), corrected QT >480ms (+2), ED diagnosis of vasovagal syncope (−2) or cardiac syncope (+2).
- **Confirmed:** total range is −3 (lowest risk) to 11 (highest risk). Confirmed via a worked example in the literature: predisposition to vasovagal (−1) + QTc >480ms (+2) + vasovagal diagnosis (−2) = −1 total, correctly falling in the low-risk band.
- **Confirmed cutoff:** score <1 = low/very-low risk (<1% chance of 30-day serious adverse event) — supports ED discharge. Score ≥1 = medium/high risk, warranting further workup.
- Applicable to patients ≥16 years old presenting within 24 hours of syncope; excludes patients with prolonged LOC (>5 min), altered baseline mental status, witnessed seizure, major trauma, intoxication, or language barrier.
- **Build note:** the point weights above are approximate/reconstructed — confirm the complete 9-factor table against MDCalc or the original 2016 CMAJ derivation paper before shipping, since this is a newer, less universally-reproduced score.

---

### Pulmonary / PE / DVT / Resp Failure

**Wells' Criteria for PE**
Clinical signs/symptoms of DVT (3), PE is #1 diagnosis (3), HR>100 (1.5), immobilization ≥3 days or surgery in past 4 weeks (1.5), prior objectively-diagnosed PE/DVT (1.5), hemoptysis (1), malignancy treated within 6 months or palliative (1).
- **Interpretation (3-tier):** <2 low, 2–6 moderate, >6 high. **(2-tier/dichotomized):** ≤4 PE unlikely, >4 PE likely.

**PERC Rule**
All 8 must be ABSENT to rule out PE (in a low pretest-probability patient, without ordering any test): age ≥50, HR ≥100, O2 sat <95%, unilateral leg swelling, hemoptysis, recent surgery/trauma (hospitalized within 4 weeks), prior PE/DVT, hormone use.

**Revised Geneva Score** *(fully resolved — both versions now confirmed)*
Developed by Le Gal et al. 2006. Two versions with different point weights per item:

| Item | Original | Simplified |
|---|---|---|
| Age >65 | 1 | 1 |
| Previous DVT or PE | 3 | 1 |
| Surgery or fracture within 1 month | 2 | 1 |
| Active malignant condition | 2 | 1 |
| Unilateral lower limb pain | 3 | 1 |
| Hemoptysis | 2 | 1 |
| Heart rate 75–94 bpm | 3 | 1 |
| Heart rate ≥95 bpm | 5 | 2 |
| Pain on deep venous palpation + unilateral edema | 4 | 1 |

- **Interpretation, Original:** low 0–3, intermediate 4–10, high ≥11.
- **Interpretation, Simplified:** dichotomized — ≤2 PE unlikely, ≥3 PE likely.
- **Build note:** pick one version and label it clearly in the UI — the point values genuinely diverge (e.g., previous DVT/PE is 3 points original vs. 1 point simplified), and mixing weights from both versions would produce a meaningless score.

**YEARS Algorithm**
3 items: clinical signs of DVT, hemoptysis, PE is the most likely diagnosis.
- If 0 items present → D-dimer cutoff 1000 ng/mL rules out PE.
- If ≥1 item present → D-dimer cutoff 500 ng/mL rules out PE.

**Wells' Criteria for DVT**
1 point each: active cancer, paralysis/paresis/recent leg immobilization, bedridden >3 days or major surgery within 12 weeks, localized tenderness along deep venous system, entire leg swollen, calf swelling >3cm vs. asymptomatic leg, pitting edema (symptomatic leg only), collateral superficial veins, previously documented DVT; alternative diagnosis at least as likely: **−2**.
- **Interpretation:** ≥3 high, 1–2 moderate, ≤0 low.

**PESI / sPESI**
Full PESI: age (in years, added directly as points) + male sex (+10) + cancer (+30) + heart failure (+10) + chronic lung disease (+10) + HR ≥110 (+20) + SBP <100 (+30) + RR ≥30 (+20) + temp <36°C (+20) + altered mental status (+60) + O2 sat <90% (+20). Total maps to Classes I–V.
**sPESI (simplified):** 1 point each for age >80, cancer, chronic cardiopulmonary disease, HR ≥110, SBP <100, O2 sat <90%.
- **Interpretation (sPESI):** 0 = low risk (consider outpatient), ≥1 = high risk.

**CURB-65**
1 point each: Confusion, Urea >7mmol/L (BUN >19mg/dL), RR ≥30, BP (SBP<90 or DBP≤60), Age ≥65.
- **Interpretation:** 0–1 outpatient, 2 consider admission, ≥3 severe (consider ICU).

**PSI / PORT Score** *(fully resolved)*

**Step 1 — screen for automatic Class I (low risk, no scoring needed):** if the patient is <50 years old AND has none of [neoplastic disease, CHF, cerebrovascular disease, renal disease, liver disease history] AND has none of [altered mental status, pulse ≥125, RR ≥30, SBP ≤90, temp <35°C or ≥40°C] → Class I, stop here. Otherwise proceed to Step 2.

**Step 2 — point-based scoring:**

*Demographics:*
- Age: men = age in years; women = age in years − 10
- Nursing home resident: +10

*Comorbidities:*
- Neoplastic disease (any cancer except basal/squamous cell skin cancer, active or diagnosed within 1 year): +30
- Liver disease (cirrhosis or active hepatitis): +20
- Congestive heart failure: +10
- Cerebrovascular disease (stroke or TIA history): +10
- Renal disease (dialysis or creatinine >1.2, per some sources; original criteria: history of renal disease): +10

*Physical exam:*
- Altered mental status: +20
- Respiratory rate ≥30: +20
- Systolic BP <90mmHg: +20
- Temperature <35°C or ≥40°C: +15
- Pulse ≥125: +10

*Labs & imaging:*
- Arterial pH <7.35: +30
- BUN ≥30mg/dL (11mmol/L): +20
- Sodium <130mEq/L: +20
- Glucose ≥250mg/dL (14mmol/L): +10
- Hematocrit <30%: +10
- PaO2 <60mmHg or SpO2 <90%: +10
- Pleural effusion on imaging: +10

**Risk classes (Step 2 total, for anyone who didn't screen out as Class I):** Class II ≤70 / Class III 71–90 / Class IV 91–130 / Class V ≥131.

**30-day mortality by class:** I 0–0.4% / II 0.4–1.0% / III 0.9–3.8% / IV 6.0–11.4% / V 16.8–38.3%.

**Disposition guidance:** Classes I–II generally appropriate for outpatient treatment; Class III consider observation or short admission; Classes IV–V typically warrant inpatient admission (Class V often ICU-level).

**Source:** Fine MJ, Auble TE, Yealy DM, et al. A prediction rule to identify low-risk patients with community-acquired pneumonia. *N Engl J Med.* 1997;336:243-250.

**ROX Index**
`ROX = (SpO2 / FiO2) / Respiratory Rate`
- **Interpretation:** measured at 2, 6, and 12 hours on HFNC. ≥4.88 predicts HFNC success; <3.85 predicts likely need for intubation.

**BODE Index**
BMI: >21 (0) / ≤21 (1). FEV1% predicted: ≥65 (0) / 50–64 (1) / 36–49 (2) / ≤35 (3). mMRC dyspnea: 0–1 (0) / 2 (1) / 3 (2) / 4 (3). 6-min walk distance: ≥350m (0) / 250–349 (1) / 150–249 (2) / ≤149 (3).
- **Interpretation:** total 0–10, higher = higher 4-year mortality.

---

### Neuro / Stroke / Head Injury

**NIH Stroke Scale (NIHSS)** *(fully resolved for this app's scope)*
15 items, each with its own confirmed score range:
- 1a Level of Consciousness (0–3), 1b LOC Questions (0–2), 1c LOC Commands (0–2)
- 2 Best Gaze (0–2), 3 Visual Fields (0–3), 4 Facial Palsy (0–3)
- 5a Motor Arm–Left (0–4), 5b Motor Arm–Right (0–4), 6a Motor Leg–Left (0–4), 6b Motor Leg–Right (0–4)
- 7 Limb Ataxia (0–2), 8 Sensory (0–2), 9 Best Language (0–3), 10 Dysarthria (0–2), 11 Extinction/Inattention (0–2)
- Total range 0–42. A score of 0 = normal exam.
- **Confirmed severity bands** (one commonly cited stratification): 1–4 minor, 5–15 moderate, 16–20 moderate-to-severe, 21–42 severe. (Other sources use slightly different cut-points, e.g. <5 mild/5–14 mild-moderate/15–24 severe — this varies by source, pick one and cite it.)
- **Scope decision, made deliberately:** the per-point behavioral criteria (what separates a 1 from a 2 on a given item) are intentionally left out of this app. This tool is for risk stratification, not diagnosis or certified exam administration — the item score ranges above are sufficient for a calculator that sums points a trained examiner has already determined via their own certified exam. Defining item-level behavioral criteria is Neuro's domain (and a certification matter), not something this app should encode or imply authority over.

**ABCD2 Score**
Age ≥60 (1), BP ≥140/90 (1), Clinical features: unilateral weakness (2) or speech disturbance without weakness (1) or other (0), Duration: ≥60min (2) / 10–59min (1) / <10min (0), Diabetes (1).
- **Interpretation:** 0–3 low, 4–5 moderate, 6–7 high 2-day stroke risk.

**Canadian CT Head Injury/Trauma Rule**
Applies to GCS 13–15 with witnessed LOC, amnesia, or confusion. High-risk criteria (any → CT needed): GCS <15 at 2h post-injury, suspected open/depressed skull fracture, any sign of basilar skull fracture, ≥2 episodes of vomiting, age ≥65. Medium-risk: amnesia before impact >30 min, dangerous mechanism.

**Ottawa SAH Rule**
Applies to age ≥15, new severe atraumatic headache reaching maximum intensity within 1 hour. Any ONE of the following warrants further workup: age ≥40, neck pain/stiffness, witnessed LOC, onset during exertion, thunderclap headache (instantly peaking), limited neck flexion on exam.

**Hunt-Hess Classification**
I: asymptomatic or mild headache. II: moderate-severe headache, nuchal rigidity, no deficit other than cranial nerve palsy. III: drowsiness/confusion, mild focal deficit. IV: stupor, moderate-severe hemiparesis. V: deep coma, decerebrate posturing.

**ICH Score**
GCS 3–4 (2) / 5–12 (1) / 13–15 (0); ICH volume ≥30cm³ (1); intraventricular hemorrhage present (1); infratentorial origin (1); age ≥80 (1). Total 0–6.
- **Interpretation:** higher score = higher 30-day mortality (0=0%, up to 5–6≈100% in the derivation cohort).

**Glasgow Coma Scale (GCS)**
- Eye: 4 spontaneous / 3 to voice / 2 to pain / 1 none
- Verbal: 5 oriented / 4 confused / 3 inappropriate words / 2 incomprehensible sounds / 1 none
- Motor: 6 obeys commands / 5 localizes pain / 4 withdraws from pain / 3 abnormal flexion (decorticate) / 2 abnormal extension (decerebrate) / 1 none
- Total 3–15 (report intubated patients' verbal component as "T", e.g., "10T").

**FOUR Score**
4 domains, each 0–4: Eye response, Motor response, Brainstem reflexes, Respiration pattern. Designed to remain valid in intubated/sedated patients where GCS's verbal component is meaningless. Total 0–16.

**RASS (Richmond Agitation-Sedation Scale)**
10-point scale from −5 (unarousable) to +4 (combative), with 0 = alert and calm. Each level has a specific behavioral descriptor (e.g., −2 = light sedation, briefly awakens with eye contact to voice; +2 = frequent non-purposeful movement).

**CAM-ICU**
Positive requires Feature 1 (acute onset or fluctuating course) AND Feature 2 (inattention) AND EITHER Feature 3 (altered level of consciousness, RASS ≠ 0) OR Feature 4 (disorganized thinking).

---

### Trauma

**Canadian C-Spine Rule**
Applies to alert (GCS 15), stable trauma patients. If ANY high-risk factor present (age ≥65, dangerous mechanism, paresthesias in extremities) → imaging required. If no high-risk factor, check for a low-risk factor allowing safe range-of-motion testing (simple rear-end MVC, sitting position in ED, ambulatory at any point since injury, delayed-onset neck pain, absence of midline C-spine tenderness); if none of these present → imaging required; if present → have patient rotate neck 45° left and right; if able → no imaging needed.

**NEXUS Criteria (C-Spine)**
No imaging needed if ALL absent: midline cervical tenderness, focal neurologic deficit, altered level of alertness, intoxication, distracting painful injury.

**NEXUS Chest Decision Instrument**
Low risk for significant thoracic injury if ALL absent: age >60, rapid deceleration mechanism, chest pain, intoxication, altered mental status, distracting painful injury, chest wall tenderness on exam.

**Ottawa Ankle Rules**
Ankle X-ray series indicated if pain in the malleolar zone AND any of: bone tenderness at posterior edge/tip of lateral malleolus, bone tenderness at posterior edge/tip of medial malleolus, inability to bear weight both immediately after injury and for 4 steps in the ED.
Foot X-ray series indicated if pain in the midfoot zone AND any of: tenderness at base of 5th metatarsal, tenderness at navicular, inability to bear weight (same criteria).

**Ottawa Knee Rule**
X-ray indicated if ANY of: age ≥55, isolated patellar tenderness (no other bone tenderness), fibular head tenderness, inability to flex knee to 90°, inability to bear weight both immediately and in the ED for 4 steps.

**PECARN Pediatric Head Injury/Trauma Algorithm** *(fully resolved — see also Section 5 – Peds Module)*
Two separate age-stratified decision trees, both applying only to GCS ≥14 patients within 24h of blunt head trauma:

**Age <2 years:**
- **High risk (CT recommended):** GCS <15, palpable skull fracture, or altered mental status (agitation, somnolence, slow response, repetitive questioning)
- **Intermediate risk (CT vs. observation, clinical judgment):** occipital/parietal/temporal scalp hematoma, LOC ≥5 seconds, severe mechanism of injury, or not acting normally per parent
- **Low risk (no imaging needed):** none of the above present

**Age ≥2 years:**
- **High risk (CT recommended):** GCS <15, signs of basilar skull fracture, or altered mental status
- **Intermediate risk:** history of LOC, vomiting, severe headache, or severe mechanism of injury
- **Low risk:** none of the above present — note that vomiting, LOC, severe headache, or severe mechanism of injury ALONE (isolated, without other findings) are specifically NOT associated with increased ciTBI risk per the original study

**Severe mechanism of injury (shared definition):** MVC with patient ejection, rollover, or fatality; pedestrian or unhelmeted cyclist struck by a vehicle; fall >0.9m/3ft (age <2) or >1.5m/5ft (age ≥2); head struck by a high-impact object.

**Disposition:** high risk → CT. Intermediate risk → CT or a 4–6 hour observation period is a reasonable alternative, particularly with only one intermediate factor, improving symptoms, or age >3 months. Low risk → no imaging, reassurance/education/return precautions.

**Performance (as validated):** NPV 100% and sensitivity 100% for ciTBI in the <2y group; NPV 99.95% and sensitivity 96.8% in the ≥2y group.

**Source:** Kuppermann N, Holmes JF, Dayan PS, et al. *Lancet.* 2009;374(9696):1160-1170.

**Shock Index**
`Shock Index = HR / SBP`
- **Interpretation:** normal 0.5–0.7; >0.9–1.0 suggests occult shock/higher transfusion likelihood.

**ABC Score for Massive Transfusion**
4 binary criteria, 1 point each: penetrating mechanism, SBP ≤90mmHg on arrival, HR ≥120bpm, positive FAST.
- **Interpretation:** score ≥2 → activate massive transfusion protocol.

**Revised Trauma Score (RTS)**
GCS coded to 0–4 (13–15=4, 9–12=3, 6–8=2, 4–5=1, 3=0) + SBP coded to 0–4 (>89=4, 76–89=3, 50–75=2, 1–49=1, 0=0) + RR coded to 0–4 (10–29=4, >29=3, 6–9=2, 1–5=1, 0=0).
Triage RTS = simple sum (0–12) for field triage. Weighted RTS (for outcome prediction) = (GCS-coded × 0.9368) + (SBP-coded × 0.7326) + (RR-coded × 0.2908), range 0–7.84.

**Injury Severity Score (ISS)**
Sum of the squares of the three highest AIS (Abbreviated Injury Scale, 1–6) scores, each from a DIFFERENT body region. Range 0–75. Any single AIS of 6 automatically sets ISS to 75 (considered unsurvivable).

---

### Sepsis / Infectious Disease

**qSOFA**
1 point each: RR ≥22, altered mentation (GCS <15), SBP ≤100.
- **Interpretation:** ≥2 = high risk for poor sepsis-related outcome.

**SOFA Score**
6 organ systems, each scored 0–4:
- Respiration: PaO2/FiO2 ratio (± ventilatory support)
- Coagulation: platelet count
- Liver: bilirubin
- Cardiovascular: MAP and/or vasopressor type+dose
- CNS: GCS
- Renal: creatinine or urine output
Total 0–24. Trend, don't just spot-check.

**SIRS Criteria**
≥2 of: temp >38°C or <36°C; HR >90; RR >20 or PaCO2 <32mmHg; WBC >12,000 or <4,000 or >10% bands.

**APACHE II** *(fully resolved — complete table pulled from Merck Manual's direct adaptation of Knaus et al. 1985)*
Total = Acute Physiology Score + Age Points + Chronic Health Points. Use the WORST value of each variable in the first 24 hours of ICU admission.

**Acute Physiology Score — 12 variables, each scored on the table below (points shown for each band; "—" means no band at that point value for that variable):**

| Variable | +4 | +3 | +2 | +1 | 0 | +1 | +2 | +3 | +4 |
|---|---|---|---|---|---|---|---|---|---|
| Temperature, core (°C) | ≥41 | 39–40.9 | — | 38.5–38.9 | 36–38.4 | 34–35.9 | 32–33.9 | 30–31.9 | ≤29.9 |
| Mean arterial pressure (mmHg) | ≥160 | 130–159 | 110–129 | — | 70–109 | — | 50–69 | — | ≤49 |
| Heart rate | ≥180 | 140–179 | 110–139 | — | 70–109 | — | 55–69 | 40–54 | ≤39 |
| Respiratory rate (vent. or non-vent.) | ≥50 | 35–49 | — | 25–34 | 12–24 | 10–11 | 6–9 | — | ≤5 |
| Oxygenation — FiO2≥0.5: use A-aDO2 | ≥500 | 350–499 | 200–349 | — | <200 | — | — | — | — |
| Oxygenation — FiO2<0.5: use PaO2 (mmHg) | — | — | — | — | >70 | 61–70 | — | 55–60 | <55 |
| Arterial pH | ≥7.7 | 7.6–7.69 | — | 7.5–7.59 | 7.33–7.49 | — | 7.25–7.32 | 7.15–7.24 | <7.15 |
| Serum sodium (mmol/L) | ≥180 | 160–179 | 155–159 | 150–154 | 130–149 | — | 120–129 | 111–119 | ≤110 |
| Serum potassium (mmol/L) | ≥7 | 6–6.9 | — | 5.5–5.9 | 3.5–5.4 | 3–3.4 | 2.5–2.9 | — | <2.5 |
| Serum creatinine (mg/dL) — double points if acute renal failure | ≥3.5 | 2–3.4 | 1.5–1.9 | — | 0.6–1.4 | — | <0.6 | — | — |
| Hematocrit (%) | ≥60 | — | 50–59.9 | 46–49.9 | 30–45.9 | — | 20–29.9 | — | <20 |
| WBC (in 1000s) | ≥40 | — | 20–39.9 | 15–19.9 | 3–14.9 | — | 1–2.9 | — | <1 |

**Serum bicarbonate (optional 13th variable — only use if no arterial blood gas available):**
| ≥52 | 41–51.9 | — | 32–40.9 | 22–31.9 | — | 18–21.9 | 15–17.9 | <15 |

- **GCS contribution:** APACHE II points = 15 − actual GCS (a fully alert patient contributes 0; a GCS of 3 contributes 12).
- **Age points:** <45 (0) / 45–54 (2) / 55–64 (3) / 65–74 (5) / ≥75 (6).
- **Chronic health points:** 2 points for an elective postoperative patient with immunocompromise or a history of severe organ insufficiency; 5 points for a nonoperative patient or emergency postoperative patient with the same criteria. (Organ insufficiency/immunocompromise must have preceded the current admission.)
- Total range 0–71. Confirmed mortality correlation: scores >25 correspond to >50% predicted mortality, >30 to >75%.
- Predicted mortality via the Knaus logistic equation: logit(R) = −3.517 + 0.146×(APACHE II score) + diagnostic category weight.
- **Source:** Knaus WA, Draper EA, Wagner DP, Zimmerman JE. APACHE II: A severity of disease classification system. *Critical Care Medicine* 1985;13:818–829, as adapted in the Merck Manual Professional Edition.

**LRINEC Score** *(verified against current sources)*
6 lab values:

- CRP (mg/L): <150 (0) / ≥150 (4)
- WBC (/mm³): <15,000 (0) / 15,000–25,000 (1) / >25,000 (2)
- Hemoglobin (g/dL): >13.5 (0) / 11–13.5 (1) / <11 (2)
- Sodium (mmol/L): ≥135 (0) / <135 (2)
- Creatinine (mg/dL): ≤1.6 (0) / >1.6 (2)
- Glucose (mg/dL): ≤180 (0) / >180 (1)
- **Interpretation:** total 0–13. ≤5 low risk (<50% NF probability), 6–7 intermediate (50–75%), ≥8 high (>75%). Score <6 does NOT rule out necrotizing fasciitis — index of suspicion still governs.

**Centor Score / McIsaac Modification**
1 point each: tonsillar exudate, tender anterior cervical lymphadenopathy, fever >38°C, absence of cough. McIsaac adds age adjustment: age 3–14 (+1), 15–44 (+0), ≥45 (−1).
- **Interpretation (McIsaac):** 0–1 no testing/antibiotics needed, 2–3 rapid strep test, ≥4 consider empiric treatment.

**Lactate:Base Deficit Ratio** *(new — differentiates sepsis from hypovolemia as the driver of shock)*
`Ratio = Lactate (mmol/L) / Base Deficit (mmol/L)`
- **Interpretation:** ratio >1 (typically ≥1) suggests sepsis — early mitochondrial dysfunction and impaired oxygen utilization drive lactate disproportionately high relative to base deficit. Ratio <1 suggests hypovolemia — decreased perfusion drives anaerobic metabolism and a base deficit disproportionately high relative to lactate. 0.8–1.0 is a gray zone requiring clinical correlation.
- **Caveats to build into the UI, not just the tooltip:** not an absolute rule — use alongside clinical assessment, hemodynamics, and other labs; earliest measurements (within 1–3 hours of presentation) are most informative; the two conditions can overlap, so reassess frequently rather than anchoring on one calculation.
- **Source:** Ospina-Tascón GA, et al. Lactate/Base Deficit Ratio: Use in Differential Diagnosis Between Sepsis and Hypovolemic Shock. *Intensive Care Med.* 2016;42(7):e35–e36.

---

### GI / Renal / Metabolic

**Glasgow-Blatchford Bleeding Score** *(fully resolved)*
- BUN (mg/dL): 18.2–22.4 (2) / 22.4–28 (3) / 28–70 (4) / >70 (6)
- Hemoglobin, men (g/dL): 12–13 (1) / 10–12 (3) / <10 (6)
- Hemoglobin, women (g/dL): 10–12 (1) / <10 (6)
- SBP (mmHg): 100–109 (1) / 90–99 (2) / <90 (3)
- Pulse ≥100 (1), Melena present (1), Syncope (2), Hepatic disease (2), Cardiac failure (2)
- Total 0–23.
- **Interpretation:** score of 0 requires ALL of: Hgb >12.9 (men)/>11.9 (women), SBP >109, pulse <100, BUN <18.2, no melena, no syncope, no hepatic disease, no cardiac failure — this combination = very low risk, safe for outpatient management without endoscopy. Per NICE guidance, GBS of 0 is the threshold to consider early discharge.

**Rockall Score** *(structure resolved — full comorbidity/diagnosis point sub-tables still need MDCalc cross-check)*
**Pre-endoscopy (3 clinical variables, max 7):**
- Age: <60 (0) / 60–79 (1) / ≥80 (2)
- Shock: SBP ≥100 & HR <100 (0) / SBP ≥100 & HR ≥100 (1) / SBP <100 (2)
- Comorbidity: none major (0) / cardiac failure, ischemic heart disease, or other major comorbidity (2) / renal failure, liver failure, or disseminated malignancy (3)

**Post-endoscopy adds 2 more variables (full score max 11):**
- Diagnosis: Mallory-Weiss tear or no lesion identified (0) / all other diagnoses (1) / malignancy of the upper GI tract (2)
- Stigmata of recent hemorrhage: none or dark spot only (0) / blood in upper GI tract, adherent clot, visible or spurting vessel (2)

- **Interpretation:** pre-endoscopy score of 3 ≈10% mortality, score of 6 ≈50% mortality. Full (post-endoscopy) score 0–2 = low risk (<0.2% mortality, <5% rebleeding) — consider early discharge; higher scores drive ICU vs. floor admission and repeat-endoscopy timing decisions.
- **Caveat to build into the UI:** per ACG guidelines, neither Rockall nor Glasgow-Blatchford reliably predicts which *individual* patients will need intervention — the one exception is a Glasgow-Blatchford of 0, which does reliably identify very-low-risk patients. Don't present Rockall as equally precise at the low end.

**AIMS65**
1 point each: Albumin <3.0 g/dL, INR >1.5, altered Mental status, SBP ≤90mmHg, age ≥65.
- **Interpretation:** total 0–5, higher score = higher inpatient mortality.

**MELD-Na Score**
`MELD = 3.78×ln(bilirubin mg/dL) + 11.2×ln(INR) + 9.57×ln(creatinine mg/dL) + 6.43`
(Lab values below 1.0 are set to 1.0 before taking the log; creatinine capped at 4.0 or dialysis-adjusted per protocol.)
`MELD-Na = MELD + 1.32×(137 − Na) − [0.033×MELD×(137 − Na)]`
(Sodium bounded to 125–137 mEq/L before applying the correction.)

**Ranson's Criteria**
On admission (1 point each): age >55, WBC >16,000, glucose >200mg/dL, LDH >350 IU/L, AST >250 IU/L.
At 48 hours (1 point each): hematocrit drop >10%, BUN increase >5mg/dL, calcium <8mg/dL, PaO2 <60mmHg, base deficit >4mEq/L, fluid sequestration >6L.
- **Interpretation:** total 0–11; ≥3 predicts severe pancreatitis course.

**BISAP Score**
1 point each: BUN >25mg/dL, impaired mental status, SIRS ≥2 criteria, age >60, pleural effusion on imaging.
- **Interpretation:** ≥3 associated with substantially higher mortality.

**Alvarado Score**
Migration of pain to RLQ (1), Anorexia (1), Nausea/vomiting (1), RLQ tenderness (2), Rebound pain (1), Elevated temp >37.3°C (1), Leukocytosis >10,000 (2), Left shift/neutrophilia (1). Total 0–10.
- **Interpretation:** ≥7 high probability of appendicitis, 5–6 equivocal (imaging/observation), <5 unlikely.
- **Note:** this is the adult-derived score. For pediatric patients, use PAS or pARC below instead — see `Peds_Module_Content_Spec.md` for the setting-specific guidance on which of the three to reach for.

**Pediatric Appendicitis Score (PAS)** *(new — belongs in Peds Module for navigation; logic documented once here)*
8 items, total 0–10:
- Anorexia (1)
- Nausea/vomiting (1)
- Migration of pain to RLQ (1)
- Fever ≥38°C (1)
- Pain with cough, percussion, or hopping (2)
- RLQ tenderness (2)
- Leukocytosis — WBC >10,000/mm³ (1)
- Neutrophilia/left shift — ANC >7,500/mm³ (1)
- **Interpretation:** 0–3 low risk, 4–6 intermediate/equivocal, 7–10 high risk.
- **Known limitation, build into the UI as a caution, not just a footnote:** a PAS <4 does NOT reliably exclude appendicitis and can provide false reassurance in some patients. The cough/hop/percussion tenderness item is unreliable in young or uncooperative children. Should not be used as the sole decision tool in patients with known GI disease, pregnancy, or prior abdominal surgery.

**pARC (Pediatric Appendicitis Risk Calculator)** ⚠️ *(variables and risk tiers confirmed; regression coefficients still need primary-source pull)*
Not a simple additive point score — a multivariable logistic regression model outputting a predicted percent risk of appendicitis.
- **Confirmed variables (7):** sex, age, duration of pain, guarding, pain migration, maximal tenderness in the right lower quadrant, and absolute neutrophil count (ANC).
- **Correction:** the derivation/validation paper is Kharbanda AB, et al. *Pediatrics.* 2018;141(4):e20172699 — not *JAMA Network Open* as noted in the earlier draft.
- **Confirmed risk tiers:** <15% = low risk (candidate for safe discharge/observation without advanced imaging); 75–84% = high-intermediate (specificity 97.5%); ≥85% = high risk (specificity 99.7%, candidate to potentially skip advanced imaging and proceed toward surgical evaluation). Roughly the middle 15–74% band is intermediate risk requiring further workup/imaging.
- **Performance context:** outperformed PAS in validation (AUC 0.85 vs. 0.77) and classified nearly half of patients into a confidently low- or high-risk category, vs. only 23% for a comparably confident PAS cutoff.
- **Build note (unchanged):** the actual regression coefficients still need to come from the primary 2018 *Pediatrics* paper (or a licensed MDCalc implementation) — I don't have those memorized precisely enough to hand-transcribe, same caution as GRACE.
- **Applicability:** validated in children ≥5 years old presenting with abdominal pain <96 hours duration. Not designed for or validated in children <5, where appendicitis is rare and presents atypically. Not for critically ill children with an obvious surgical abdomen — those need immediate surgical involvement regardless of score.
- **Requires ANC** as an input (not just WBC), which distinguishes it from PAS.

**Maddrey's Discriminant Function**
`DF = 4.6 × (patient PT − control PT, in seconds) + total bilirubin (mg/dL)`
- **Interpretation:** DF ≥32 defines severe alcoholic hepatitis — consider corticosteroid therapy.

**Corrected Calcium (Hypoalbuminemia)**
`Corrected Ca (mg/dL) = Measured Ca + 0.8 × (4.0 − Albumin g/dL)`

**Corrected Sodium for Hyperglycemia** *(recommendation given — this was a genuine choice, not a lookup)*
Katz formula: `Corrected Na = Measured Na + 1.6 × [(Glucose − 100) / 100]`
Hillier formula: `Corrected Na = Measured Na + 2.4 × [(Glucose − 100) / 100]`
- **Recommendation:** implement Hillier as the default. It was derived from actual measured (not assumed) relationships between glucose and sodium and is more accurate at the higher glucose levels (DKA/HHS) where this calculation actually matters clinically — Katz's 1.6 constant was a theoretical estimate, not empirically derived. Label whichever you ship so users know which constant is in use; don't offer both without clear labeling, since silently switching formulas would produce inconsistent results.

**Anion Gap**
`AG = Na − (Cl + HCO3)` — normal ~8–12 mEq/L.
With potassium: `AG = (Na + K) − (Cl + HCO3)` — normal ~10–16 mEq/L.

---

### Toxicology / Withdrawal

**Osmolal Gap**
`Calculated Osm = 2×Na + (Glucose/18) + (BUN/2.8)` (+ Ethanol/3.7 if measured ethanol is being accounted for)
`Osmolal Gap = Measured Osm − Calculated Osm`
- **Interpretation:** gap >10–15 suggests unmeasured osmotically active substances (toxic alcohols).

**Serotonin Syndrome (Hunter Criteria)**
Requires a serotonergic agent PLUS ONE of: spontaneous clonus; inducible clonus + (agitation OR diaphoresis); ocular clonus + (agitation OR diaphoresis); tremor + hyperreflexia; hypertonia + temp >38°C + (ocular clonus OR inducible clonus).

**CIWA-Ar**
10 items, each 0–7 except orientation (0–4): nausea/vomiting, tremor, paroxysmal sweats, anxiety, agitation, tactile disturbances, auditory disturbances, visual disturbances, headache/fullness in head, orientation/clouding of sensorium. Total 0–67.
- **Interpretation:** <8 minimal, 8–15 mild-moderate, ≥15 severe (higher seizure/DT risk); most protocols trigger symptom-triggered dosing at ≥8–10.

**COWS (Clinical Opiate Withdrawal Scale)**
11 items (resting pulse, sweating, restlessness, pupil size, bone/joint aches, rhinorrhea/lacrimation, GI upset, tremor, yawning, anxiety/irritability, gooseflesh skin), each scored 0–4 or 0–5 depending on item. Total 0–48ish.
- **Interpretation:** 5–12 mild, 13–24 moderate, 25–36 moderately severe, >36 severe.

---

### Early Warning / Resuscitation

**NEWS2**
7 parameters, each 0–3: RR, O2 saturation (two different scoring scales depending on whether the patient has a hypercapnic drive to breathe), use of supplemental O2, temperature, SBP, HR, level of consciousness (new confusion counts as abnormal).
- **Interpretation:** aggregate ≥7 = high risk; 5–6 (or any single parameter scoring 3) = medium/urgent; 0–4 = low.

**MEWS**
RR, HR, SBP, temperature, and AVPU/consciousness level, each scored 0–3. Trigger thresholds for escalation vary by institution (commonly ≥5).

---

### ICU / Critical Care

**PaO2/FiO2 (P/F) Ratio**
`P/F = PaO2 / FiO2` (FiO2 as a decimal, e.g., 0.4 for 40%)
- **Interpretation:** normal ~400–500. ARDS severity (with PEEP ≥5): mild 200–300, moderate 100–200, severe <100.

**ARDS Berlin Definition**
All of: onset within 1 week of a known clinical insult or new/worsening respiratory symptoms; bilateral opacities on CXR/CT not fully explained by effusions, lobar/lung collapse, or nodules; respiratory failure not fully explained by cardiac failure or fluid overload (objective assessment, e.g., echo, needed if no risk factor present); oxygenation impairment classified by P/F ratio with PEEP ≥5cmH2O as above.

**Rapid Shallow Breathing Index (RSBI)**
`RSBI = Respiratory Rate / Tidal Volume (in liters)`
- **Interpretation:** <105 predicts successful extubation; ≥105 predicts likely weaning failure.

**Harris-Benedict Equation**
Men: `BEE = 66.5 + (13.75 × weight kg) + (5.003 × height cm) − (6.775 × age)`
Women: `BEE = 655.1 + (9.563 × weight kg) + (1.850 × height cm) − (4.676 × age)`
Multiply BEE by an activity/stress factor (institution-specific, typically 1.2–1.5 for critically ill) for total daily energy needs.

**Refeeding Syndrome Risk (NICE criteria)**
High risk if ≥1 major criterion (BMI <16, unintentional weight loss >15% in 3–6 months, little/no nutritional intake >10 days, low K/Mg/Phos before feeding) OR ≥2 minor criteria (BMI <18.5, weight loss >10% in 3–6 months, little/no intake >5 days, history of alcohol/drug misuse or certain medications e.g. insulin/chemo/antacids/diuretics).

**Padua Prediction Score** *(cutoff verified against current sources)*
11 weighted criteria: active cancer (3), previous VTE (3), reduced mobility ≥3 days (3), known thrombophilia (3), recent (≤1 month) trauma/surgery (2), age ≥70 (1), heart and/or respiratory failure (1), acute MI or ischemic stroke (1), acute infection or rheumatologic disorder (1), obesity BMI ≥30 (1), ongoing hormonal treatment (1).
- **Interpretation:** ≥4 = high risk, supports pharmacologic thromboprophylaxis.

**IMPROVE Bleeding Risk Score** ⚠️ *(structure and cutoff confirmed; exact per-item weights still approximate)*
11 risk factors, each weighted 1 to 4.5 points: age, male sex, moderate renal failure (GFR 30–59), severe renal failure (GFR <30), current cancer, rheumatic disease, central venous catheter, ICU/CCU admission, hepatic failure (INR >1.5), platelet count <50k, bleeding within 3 months before admission, and active gastroduodenal ulcer. (Approximate published weights, still needing final confirmation: moderate renal failure 1, male sex 1, age 40–84 1.5, current cancer 2, rheumatic disease 2, central venous catheter 2, ICU/CCU 2.5, severe renal failure 2.5, hepatic failure 2.5, age ≥85 3.5, platelet count <50k 4, active gastroduodenal ulcer 4.5, bleeding in prior 3 months 4.)
- **Confirmed interpretation:** score ≥7 = high bleeding risk — weigh against Padua before starting pharmacologic VTE prophylaxis. This cutoff is independently confirmed across multiple validation studies.
- **Build note (narrowed):** the item list and cutoff are now solid; the exact per-item weight table above is still approximate — cross-check against MDCalc/the original Decousus 2011 derivation before shipping. This remains the least consistently-reproduced score on this list.

**CPOT (Critical-Care Pain Observation Tool)**
4 domains, each 0–2: facial expression, body movements, muscle tension, compliance with ventilator (for intubated patients) or vocalization (for extubated patients). Total 0–8.
- **Interpretation:** score >2 indicates significant pain — treat.

**4Ts Score for HIT** *(cutoffs verified against current sources)*
4 domains, each scored 0–2:
- **T**hrombocytopenia: degree of platelet fall and nadir
- **T**iming of platelet fall relative to heparin exposure
- **T**hrombosis or other sequelae
- o**T**her causes of thrombocytopenia excluded
Total 0–8.
- **Interpretation:** 0–3 low probability, 4–5 intermediate, 6–8 high probability of HIT.

---

### Anesthesia / Airway / OR

**ASA Physical Status Classification**
I: healthy. II: mild systemic disease. III: severe systemic disease. IV: severe systemic disease that is a constant threat to life. V: moribund, not expected to survive without the operation. VI: declared brain-dead organ donor. Append "E" for emergency cases.

**Revised Cardiac Risk Index (RCRI)**
6 predictors, 1 point each: high-risk surgery (intraperitoneal, intrathoracic, or suprainguinal vascular), ischemic heart disease, history of CHF, history of cerebrovascular disease, insulin-dependent diabetes, creatinine >2.0mg/dL.
- **Interpretation (approximate original rates):** 0 factors ≈0.4% risk of major cardiac event, 1 ≈1%, 2 ≈2.4%, ≥3 ≈5.4%.

**Mallampati Score**
Class I: soft palate, uvula, fauces, pillars all visible. II: soft palate, uvula, fauces visible (pillars not). III: soft palate, base of uvula visible. IV: only hard palate visible.

**El-Ganzouri Airway Risk Index**
7 factors, each 0–2 points: mouth opening, thyromental distance, Mallampati class, neck movement, ability to prognath, weight, history of difficult intubation. Total 0–12.
- **Interpretation:** ≥4 predicts difficult intubation.

**LEMON Law (Difficult Airway Risk Assessment)**
- **L**ook externally (1 point if abnormal features present: facial trauma, large incisors, beard, large tongue)
- **E**valuate 3-3-2 rule (1 point per abnormal finding: mouth opening <3 fingerbreadths, hyoid-to-chin distance <3 fingerbreadths, thyroid notch-to-floor-of-mouth distance <2 fingerbreadths)
- **M**allampati class ≥3 (1 point)
- **O**bstruction/obesity present (1 point)
- **N**eck mobility limited (1 point)
- **Interpretation:** no single validated cutoff — higher score plus clinical gestalt predicts more difficult intubation; used as a fast pre-intubation checklist rather than a strict threshold.

**Cormack-Lehane Classification**
Grade 1: full view of glottis. Grade 2a: partial view of glottis. Grade 2b: only posterior extent of glottis or arytenoids visible. Grade 3: only epiglottis seen, no glottis visible. Grade 4: neither glottis nor epiglottis visible.

**STOP-BANG Score**
1 point each: Snoring, Tiredness/daytime sleepiness, Observed apnea, high blood Pressure, BMI >35, Age >50, Neck circumference >40cm, male Gender. Total 0–8.
- **Interpretation:** 0–2 low risk, 3–4 intermediate, ≥5 high risk for OSA.

**Caprini Score (2005 version)** *(fully resolved — complete checklist below, direct from a source citing Caprini 2005)*

| 1 point | 2 points | 3 points | 5 points |
|---|---|---|---|
| Age 41–60 | Age 61–74 | Age ≥75 | Elective major lower extremity arthroplasty |
| Minor surgery (<45 min) planned | Arthroscopic surgery | History of DVT or PE | Hip, pelvis, or leg fracture within the last month |
| History of major surgery (>45 min) within the last month | Malignancy (present or previous) | Family history of thrombosis | Stroke within the last month |
| Varicose veins | Major surgery (>45 min) | Positive Factor V Leiden | Multiple traumas within the last month |
| History of inflammatory bowel disease | Laparoscopic surgery (>45 min) | Positive Prothrombin 20210A | Acute spinal cord injury (paralysis) within the last month |
| Swollen legs (current) | Confined to bed ≥72 hours | Elevated serum homocysteine | |
| Obesity (BMI ≥25) | Immobilizing plaster cast <1 month | Positive lupus anticoagulant | |
| Acute myocardial infarction | Central venous access | Elevated anticardiolipin antibodies | |
| Congestive heart failure within the last month | Heparin-induced thrombocytopenia (HIT) | | |
| Sepsis within the last month | Other congenital or acquired thrombophilia | | |
| Serious lung disease (incl. pneumonia) within the last month | | | |
| Abnormal pulmonary function (e.g. COPD) | | | |
| Currently at bed rest | | | |
| Oral contraceptives or hormone replacement therapy | | | |
| Pregnancy or postpartum <1 month | | | |
| History of unexplained stillbirth, recurrent (≥3) spontaneous abortion, premature birth with toxemia, or growth-restricted infant | | | |

Sum all applicable points across all four columns.

- **Interpretation — decision made:** use the 4-tier scheme that persisted across the 2005, 2010, AND 2013 revisions (confirmed via a JVS Venous systematic review as the standard, validated categorization, not a one-off institutional variant): **0–1 low / 2 moderate / 3–4 high / ≥5 highest (very high).** This was chosen over the alternative Queensland-sourced breakdown (0 very low / 1–2 low / 3–4 moderate / ≥5 high) for two reasons: it's more sensitive — it escalates recommended prophylaxis intensity at a lower score (moderate risk starts at 2, not 3), and it's the scheme that current society-level guidance and the most recent (2013) model continuity actually reflect, rather than a single reproduction of the original 2005 paper.
- **Prophylaxis by tier (StatPearls, 2013 model — use this, not the earlier draft's mapping):**
  - Low (0–1): early ambulation generally sufficient; no pharmacologic or mechanical prophylaxis typically required
  - Moderate (2): mechanical prophylaxis (e.g., intermittent pneumatic compression), OR pharmacologic prophylaxis may be considered based on clinical context
  - High (3–4): pharmacologic prophylaxis recommended during hospitalization, with mechanical methods added if appropriate
  - Highest/Very high (≥5): combined pharmacologic AND mechanical prophylaxis, often with extended pharmacologic prophylaxis postdischarge (7–10 days); scores >8 may warrant up to 30 days
- **Version note:** this is scored using the 2005 checklist items (table above); the 2013 revision adds a few additional items (e.g., smoking, insulin-dependent diabetes, chemotherapy, blood transfusions, surgery >2h, additional female-specific factors) that aren't in the table above — if you want the fuller 2013 item set rather than just its risk-tier scheme, that's a separate follow-up pull.
- **Source for interpretation decision:** Lobastov K, et al. (JVS Venous, 2022 systematic review, cited in `Calculator_Logic_Build_Spec.md` research pass) confirming the 0–1/2/3–4/≥5 scheme across 2005/2010/2013; StatPearls (Abduljabbar, Ross, Song; last updated June 2025) for the prophylaxis-by-tier text.
- **Checklist source:** Caprini J. Thrombosis risk assessment as a guide to quality patient care. *Disease-a-Month.* 2005;51:70-78, as reproduced by Queensland Health.

**ARISCAT Score**
Age: ≤50 (0) / 51–80 (3) / >80 (16). Preop SpO2: ≥96% (0) / 91–95% (8) / ≤90% (24). Respiratory infection in last month (17). Preop anemia Hgb ≤10 g/dL (11). Surgical incision: peripheral (0) / upper abdominal (15) / intrathoracic (24). Duration of surgery: ≤2h (0) / 2–3h (16) / >3h (23). Emergency procedure (8).
- **Interpretation:** total <26 low risk, 26–44 intermediate, ≥45 high risk of postoperative pulmonary complications.

**Apfel Score for PONV**
1 point each: female sex, nonsmoker, history of PONV or motion sickness, planned postoperative opioid use.
- **Interpretation (approximate risk by score):** 0≈10%, 1≈20%, 2≈40%, 3≈60%, 4≈80% risk of PONV.

**Surgical Apgar Score**
Estimated blood loss: ≤100mL (3) / 101–600mL (2) / 601–1000mL (1) / >1000mL (0). Lowest MAP: ≥70 (3) / 55–69 (2) / 40–54 (1) / <40 (0). Lowest HR: ≤55 (4) / 56–65 (3) / 66–75 (2) / 76–85 (1) / >85 (0). Total 0–10.
- **Interpretation:** lower score = substantially higher risk of major postoperative complications within 30 days.

**Modified Aldrete Score**
5 domains, each 0–2: Activity, Respiration, Circulation (BP relative to baseline), Consciousness, O2 saturation. Total 0–10.
- **Interpretation:** ≥9 (some institutions use ≥8) generally considered fit for PACU discharge.

---

### Obstetric / Newborn

**APGAR Score**
5 domains, each 0–2, assessed at 1 and 5 minutes (repeat at 10 min if 5-min score <7):
- **A**ppearance (color): blue/pale (0) / body pink, extremities blue (1) / completely pink (2)
- **P**ulse (HR): absent (0) / <100bpm (1) / ≥100bpm (2)
- **G**rimace (reflex irritability): no response (0) / grimace (1) / cry/cough/sneeze (2)
- **A**ctivity (muscle tone): limp (0) / some flexion (1) / active motion (2)
- **R**espiration: absent (0) / weak/irregular (1) / strong cry (2)
Total 0–10.

---

## Section 3: Drug & Dosing Cards — Moved Calculators

**Ideal Body Weight (Devine Formula)**
Men: `IBW (kg) = 50 + 2.3 × (height in inches − 60)`
Women: `IBW (kg) = 45.5 + 2.3 × (height in inches − 60)`

**Lean Body Weight / Adjusted Body Weight** ⚠️ *(Janmahasatian formula located; confidence flagged below)*
Adjusted body weight (common for dosing in obesity): `AdjBW = IBW + 0.4 × (Actual Weight − IBW)`

True lean body weight — Janmahasatian formula (derived and validated from actual patient data, unlike Devine's IBW):
Men: `LBW (kg) = (9270 × Total Weight) / (6680 + 216 × BMI)`
Women: `LBW (kg) = (9270 × Total Weight) / (8780 + 244 × BMI)`
(BMI = Total Weight (kg) / Height (m)²)

- **Confidence note:** the Janmahasatian coefficients above are reconstructed from general clinical knowledge, not independently re-verified against the original 2005 *Clin Pharmacokinet* paper in this pass — treat this one specifically as needing a final cross-check against the primary source or a tool like MDCalc/Evidencio before shipping, even though the formula's existence and general validity are well-confirmed.
- **Recommendation:** use Adjusted Body Weight for routine drug dosing (simpler, well-established in that context); reserve the Janmahasatian LBW formula for cases needing more precision, particularly patients who are very short or very obese, per the literature.

**Steroid Conversion (Equivalent Dosing)**
Approximate equipotent doses (mg): Hydrocortisone 20 = Cortisone 25 = Prednisone 5 = Prednisolone 5 = Methylprednisolone 4 = Triamcinolone 4 = Dexamethasone 0.75.

**Parkland Formula for Burns**
`Total fluid (mL) in first 24h = 4 mL × %TBSA burned × weight (kg)`
Give half of the total in the first 8 hours from the time of the burn (not from time of arrival), and the remaining half over the next 16 hours.

**Free Water Deficit**
`Total Body Water (L) = Weight (kg) × 0.6 (men) or 0.5 (women)` (use ~0.5/0.45 for elderly)
`Free Water Deficit (L) = TBW × [(Current Na / 140) − 1]`
Correct slowly — no more than 8–10 mEq/L/24h to avoid osmotic demyelination.

**Acetaminophen (APAP) Overdose / NAC Dosing (Rumack-Matthew Nomogram)**
The nomogram plots serum APAP level (mcg/mL) against hours since a single acute ingestion, on a semi-log scale, starting at 4 hours post-ingestion (before which absorption may be incomplete).
- US "150-line" (treatment line): 150 mcg/mL at 4h, 37.5 mcg/mL at 12h (level halves roughly every 4 hours along the treatment line).
- If the plotted level is AT OR ABOVE the treatment line → initiate NAC.
- Standard 21-hour IV NAC protocol: 150 mg/kg over 60 min, then 50 mg/kg over 4h, then 100 mg/kg over 16h.
- **Not valid for:** unknown time of ingestion, staggered/chronic ingestion, or presentation >24h post-ingestion — different criteria apply (any detectable level + abnormal LFTs, or empiric treatment while awaiting levels).

**Vasoactive-Inotropic Score (VIS)**
`VIS = Dopamine dose (mcg/kg/min) + Dobutamine dose (mcg/kg/min) + 100 × Epinephrine dose (mcg/kg/min) + 10 × Milrinone dose (mcg/kg/min) + 10,000 × Vasopressin dose (units/kg/min) + 100 × Norepinephrine dose (mcg/kg/min)`
Trend over time rather than interpreting a single value in isolation.

**Cockcroft-Gault Creatinine Clearance**
`CrCl (mL/min) = [(140 − Age) × Weight (kg) × (0.85 if female)] / (72 × Serum Creatinine [mg/dL])`

---

## Section 5: Peds Module — PECARN (cross-reference)

See **PECARN Pediatric Head Injury/Trauma Algorithm** under Section 2 Trauma above — now fully resolved with both complete age-stratified branching trees, severe-mechanism definitions, and disposition guidance. It's listed in both places because it's filed in the Peds Module for navigation but its logic is identical to the entry documented in the Trauma section.

---

## What's NOT in this file

- **AnesCalc's 55 existing drug cards** — already built and live; nothing to reconstruct.
- **Suture, Fractures, Nerve Block, and POCUS decision-tree logic** — these are branching procedural workflows, not formulas, and belong in a separate build spec once you're ready to write out each decision tree's actual branches.
- **PedsGuide/First 5 Minutes/palmEM/Stable-ish weight-based dosing tables** — these are lookup tables (drug × weight-band → dose), not formulas; they need the actual dataset pulled from each source rather than a formula spec.
- **Reference Library content** (ACLS/PALS algorithms, vent management, ABG interpretation, antibiotic guide, vaccine schedules, ECG library, coag reference, lab reference, landmark trials) — this is prose/knowledge content, not computational logic, and is out of scope for this file.
