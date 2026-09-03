# Kairos — Open Items & Sources Needed

Living tracker. Two lists:
1. **Things to address** — engineering/design work, gaps, and decisions still open.
2. **Sources to provide** — material only you can supply (primary papers, licensed
   or original content, existing Critical Vector / AnesCalc assets) before the
   affected content can be finalized.

Last updated: 2026-09-01

## Progress log
- 2026-08-31 — Scaffold: content pipeline + PWA + SwiftUI shells, 10 modules.
- 2026-08-31 — +14 calculators (25 total), About/Settings screen both clients,
  `select` input support (web `<select>`, iOS segmented `Picker`).
- 2026-08-31 — +8 Drug & Dosing "Dosing & Fluid Math" calcs + steroid-conversion
  reference (37 total).
- 2026-08-31 — Peds batch: 6 peds resus/RSI/status drug cards, Holliday-Segar +
  generic drip-rate calcs, BRUE / DKA / infant-CPR / PAS peds-tools (**50 total**).
  Drug-card engine now supports per-kg **ranges** (`perKgHigh`) and a **min-dose
  floor** (`minDose`). Peds-tools can carry a `body` block array (shared renderer
  with reference modules).
- 2026-08-31 — Reference Library batch (**58 total**): ventilator management, ABG
  interpretation, 12-lead STEMI criteria, ECG library (text criteria; Tier 2),
  lab interpretation, ACLS adult cardiac-arrest card (original wording; Tier 2),
  landmark sepsis/resus trials (Tier 3), empiric antibiotics — CAP (Tier 3).
  Anticoag-reversal bumped to v4 (added UFH/LMWH rows). `validate.mjs` now
  decouples a peds-tool's `embeddedCalculator` before validating (ajv perf).
- 2026-09-01 — Procedures section (**67 total**): **interactive decision-tree
  walker** built (web + iOS) — question → choice → recommendation/warning, with
  breadcrumb / back / start-over, plus a `{{placeholder}}` note-template form.
  Expanded laceration-repair to a full region tree (v2); added fracture-splinting
  guide, airway-management-flow + procedural-sedation-workflow (workflow type),
  nerve-block-guide + pocus-guide (Tier 2), last-lipid-rescue (shared LAST ref).
  Added LEMON, STOP-BANG, Modified Aldrete calculators so the workflow
  cross-links resolve.
- 2026-09-01 — **JS engine regression test suite** (`tools/test.mjs`, `npm test`,
  in `npm run ci`): 116 assertions against the real web engine modules + real
  content — expr evaluator, weight-zone gaps, dose clamps, HEART/Wells/QTc/
  Holliday-Segar vs shipped JSON, search ranking, content-sanity pass. Web PWA
  icon + favicon + manifest SVG. Service worker precaches every content module
  from the manifest at install (true first-visit-offline).
- 2026-09-01 — **Swift engine test target** (`ios/Tests/EngineTests.swift`,
  `KairosTests`): 10 cases mirroring the JS suite, all passing on the simulator;
  same expected values (Bazett 462, zone-gap → 4, dose clamps, search ranking) —
  proves the Swift ports match the web engines. Added `.github/workflows/ios-ci.yml`
  (macOS runner: xcodegen + xcodebuild test).
- 2026-09-01 — **Deploy pipeline**: `tools/deploy.mjs` → `tools/dist/` (73-file
  static bundle, `contentBaseHint` stamped from `CONTENT_BASE_URL`);
  `content-deploy.yml` → GitHub Pages on push to `main`; `docs/DEPLOY.md`.
  Makes "content push, not App Store resubmission" real end to end.
- 2026-09-01 — **`KairosUITests` XCUITest target** + `accessibilityIdentifier`s
  across Home / Section / Calculator / DrugCard / ProcedureWalker / ClearableField.
  First run: `testProcedureTreeWalker` PASSED on the simulator (iOS taps +
  navigation + tree walk + Back confirmed working); the other 3 flows failed on
  harness issues, now fixed (scroll helper + loosened assertions), rebuild
  clean, re-run pending a healthy environment.
- 2026-09-01 — **+14 calculators** (**81 modules**), all no-external-source
  transcriptions from `Calculator_Logic_Build_Spec.md`: Mallampati, Cormack-Lehane
  (closes the airway-flow cross-link), RASS, SIRS, Centor/McIsaac, RCRI, Apfel,
  Padua, 4Ts, AIMS65, BISAP, Alvarado, Maddrey DF, MELD-Na. JS test suite 137/137;
  MELD-Na (28) + Maddrey (54) formula output spot-checked. `docs/RESUME.md` added
  for the laptop pickup.
- 2026-09-01 — **Tier 1 verification** — full sweep of all 60 calculator +
  drug-dosing modules (research subagent) vs primary papers + MDCalc. 1 scoring
  error found + fixed (`rcri` risk %) + an earlier `peds-amiodarone` dose-cap fix.
  10 modules corrected (v2). `docs/TIER1_VERIFICATION.md`. Pipeline green.
- 2026-09-01 — **Batch 1 of primary content received** — 73 Critical Vector HTML
  guides + AnesCalc v2 source + `ddx_master.html`. Inventoried and mapped in
  `docs/SOURCE_MATERIALS.md`; AnesCalc palette extracted to `docs/PALETTES.md`.
- 2026-09-01 — **AnesCalc drug cards integrated (Option A)** — `DrugCard.swift`
  → 55 `anesthesia-drug-card` modules (new schema + contentType + web/iOS
  renderers + 14 categories). **136 modules total** (Drug & Dosing 42→73).
  `validate 136/0/0`, `test 137/137`, iOS builds clean. `export_anescalc.swift`
  + `tools/import-anescalc.mjs` are re-runnable if AnesCalc's library changes.
- 2026-09-01 — **POCUS / nerve-block / ECG converted from CV originals** —
  `nerve-block-guide` v2 (6-phase framework, LA table, LAST, block index),
  `pocus-guide` v2 (FoCUS/lung/eFAST/IVC/RUSH/DVT/procedural anchors),
  `ecg-library` v2 (8 OMI patterns + Brugada + hyperK/WPW/TdP/dig), new
  `neuraxial-anticoagulation` (ASRA 5th-ed hold times), `last-lipid-rescue` v2
  (ASRA 2023). Tier-2 licensing/placeholder flags cleared. **137 modules.**
  `validate 137/0/0`, `test 137/137`, iOS builds clean.
- 2026-09-02 — **`ventilator-management` v2** (expanded from the CV full guide:
  ARDSNet step-by-step + PEEP/FiO₂ ladder, driving pressure, PBW/VT formulas,
  status-asthmaticus strategy, Boles weaning + cuff leak, IHI VAP bundle),
  **`anticoagulation-reversal` v5** (rewritten from the CV Bleeding/Reversal
  guide: major-bleeding definition, cause classification, cascade map, weight/INR
  4F-PCC dosing, DOAC table with the Dec 2025 US andexanet withdrawal, TEG/ROTEM
  interpretation, bedside algorithm, pitfalls), + new
  **`peripheral-iv-vasopressors`** reference (CV breakdown of ZhangJian 2026 —
  49 studies / 33,060 catheters). **138 modules.** `validate 138/0/0`, `test 137/137`.
- 2026-09-02 — **`peds-midazolam-status` v3** (added the Ket-Mid RCT note +
  flumazenil-contraindicated-in-seizure reversal line) and new
  **`empiric-antibiotics-ed-icu`** Reference Library module — converted from the
  CV *ED/ICU & Critical Infections* guide: bacterial ED/ICU syndromes
  (sepsis-unknown, HAP/VAP, aspiration, urosepsis, intra-abdominal, nec fasc,
  febrile neutropenia, meningitis, endocarditis, CLABSI, diabetic foot, TSS),
  fungal ICU emergencies, ICU-level viral, and the rare/time-critical
  recognition table (meningococcemia, RMSF, anthrax, plague, tularemia, botulism,
  lepto). Coverage-class only, doses omitted by design, `institution-specific`.
  CAP module cross-linked. **139 modules.** `validate 139/0/0`, `build 139`,
  `test 137/137`.
- 2026-09-02 — **`empiric-antibiotics-outpatient`** Reference Library module —
  converted from the CV *Board-Tested Infections* guide (companion to the ED/ICU
  one): bacterial (pharyngitis, CAP typical/atypical, cystitis, pyelo, AOM,
  sinusitis, neonatal + adult meningitis, cellulitis, Lyme, pertussis, C. diff,
  H. pylori, GC/CT, syphilis), fungal (candidiasis, cryptococcal meningitis,
  histo, cocci), viral (flu, HSV, VZV, EBV, CMV, acute HIV, HCV). Coverage-class
  only, doses omitted, `institution-specific`. Cross-links CURB-65 + Centor-McIsaac
  (both exist). **140 modules.** `validate 140/0/0`, `build 140`, `test 137/137`.
- 2026-09-02 — Batch-2 EBM guides converted: new **`ebm-study-audits`** reference
  module (SEP-1 compliance/mortality, methylene blue in shock + the TSA
  effect-size-assumption dispute, AID-ICU frequentist-vs-Bayesian, HOPE
  late-window alteplase, CT-first trauma resuscitation — each with the nuance a
  social summary drops) + new **`beta-blocker-selectivity`** reference (receptor
  grid + mechanism table + the dose-dependence caveats, Cardiac/ECG).
  **142 modules.** `validate 142/0/0`, `build 142`, `test 137/137`.
- 2026-09-02 — More CV batch conversions: new **`modified-shock-index`**
  calculator (MSI = HR ÷ MAP, MAP = (SBP+2·DBP)/3; bands < 0.7 / 0.7–1.3 /
  > 1.3 / ≥ 1.7; from `CV_Modified_Shock_Index.html`) with 3 locked test
  assertions (worked example HR 120, 90/60 → MAP 70, MSI 1.71 → high risk), and
  new **`shock-classification`** reference (from `CV_Shock_Classification_Field_Guide.html`:
  four-type hemodynamic table, SCAI A–E stages + arrest modifier, obstructive /
  distributive detail, the 60-second bedside algorithm, POCUS accuracy table,
  mixed shock, the 2026 intrapericardial-TXA tamponade series).
  **144 modules.** `validate 144/0/0`, `build 144`, `test 142/142`.
- 2026-09-02 — Two more CV references: new **`capnography`** (waveform phases,
  abnormal patterns table incl. shark-fin/curare-cleft/rebreathing, arrest
  prognostication with the ILCOR caveats, setting-specific EtCO2 targets; from
  `capnography.html`) and new **`decision-rules-cspine-ct-head`** (NEXUS vs
  Canadian C-Spine + Canadian CT Head vs New Orleans, both head-to-head trials,
  structural why-CCR-wins, exclusions, quick-ref table; from
  `cspine_rules_guide.html` — companion to the `nexus-cspine` calculator).
  **146 modules.** `validate 146/0/0`, `build 146`, `test 142/142`.
- 2026-09-02 — Two more CV references: new **`pressor-inotrope-reference`**
  (the two infusion formulas, mixing cards for NE/epi/vasopressin/dopamine/
  dobutamine, tiered receptor/hemodynamic table — inodilators / pure pressors /
  inopressors — with PIV-safety figures, refractory-vasoplegia rescue sequence,
  quick-ref concentrations; from `CV_Vasopressors_Inotropes.html`,
  `institution-specific`) and new **`antidotes-reversal-agents`** (anaphylaxis/
  shock, sedation/opioid/NMB reversal, poison-induced cardiogenic-shock ladder
  incl. HIE, toxidrome rescue, MH/LAST, antidote-by-substance table, chelation,
  envenomation; from the 13-section `antidotes_reversal_agents.html` — adult
  doses in-line, key peds doses called out; anticoag reversal deferred to its own
  module). **148 modules.** `validate 148/0/0`, `build 148`, `test 142/142`.
- 2026-09-02 — Transfusion/hemostasis pair: new **`blood-products`** (6 core
  products — PRBC/platelets/FFP/cryo/whole blood/4F-PCC — with AABB 2023 RBC +
  2025 AABB/ICTMG platelet thresholds verified exact, the 30-minute rule, and the
  fibrinogen-concentrate-vs-cryoprecipitate decision framework + CRYOSTAT-2; from
  `blood_products_guide.html` + `CV_Fibrinogen_vs_Cryoprecipitate.html`) and new
  **`teg-rotem-interpretation`** (TEG 5000 five params, TEG 6s four channels,
  platelet mapping, the 5000↔6s↔ROTEM crosswalk, goal-directed transfusion
  table, tracing-by-shape, pitfalls, pregnancy/cirrhosis/peds; from
  `CV_TEG_Interpretation_Guide.html`). Both Anticoagulation & Labs; the TEG/ROTEM
  table in `anticoagulation-reversal` can now link to the deep module.
  **150 modules.** `validate 150/0/0`, `build 150`, `test 142/142`.
- 2026-09-02 — Two more CV references: new **`acute-pe-guideline-2026`** (Tier 1
  currency — 2026 multi-society Acute PE guideline: the A–E clinical categories
  replacing massive/submassive, 'normotensive shock' D2, advanced-therapy
  Table 7, anticoag highlights incl. Class 1 half-dose extended-phase DOAC and
  the RV-failure sedation Class-3-harm caution; from `pe_guideline_cheatsheet_CV.html`)
  and new **`hyperosmolar-therapy`** (HTS vs mannitol — mechanism / reflection
  coefficient, the acute-window evidence nuance, dosing, safety hard-stops
  osm > 320 / Na > 160, volume-status bedside decision; from
  `hypertonic_saline_vs_mannitol.html`). **152 modules.**
  `validate 152/0/0`, `build 152`, `test 142/142`.
- 2026-09-02 — New **`heart-failure-continuum`** reference (Tier 1 currency —
  from `CV_Heart_Failure_Chronic_to_Acute.html`): Part 1 the six cardiomyopathy
  phenotypes (DCM/HCM/ARVC/takotsubo/ATTR-CM/PPCM) with the defining clue +
  disease-modifying therapy; Part 2 the HFpEF evidence scorecard (SGLT2i +
  finerenone work; ACE-I/ARB/ARNI/spironolactone missed) + phenotype-driven
  treatment; Part 3 cardiogenic shock in the DanGer Shock era — SCAI A–E
  mortality, Impella-CP-not-IABP for STEMI+CS (NNT 8), device selection table,
  6-step escalation algorithm. **153 modules.**
- 2026-09-02 — New **`physiologically-difficult-airway`** reference (Tier 1
  currency — from `physiologically-difficult-airway.html`): the four deadly
  profiles (hypoxemic/shunt, hypotensive, acidotic, RV-failure) + the
  evidence-corrected induction matrix, folding in PREOXI (NIV preox), FELLOW
  (ApOx adds little), PrePARE/PREPARE II (no fluid-bolus benefit), and the RSI
  trial (NEJM Dec 2025 — ketamine ≠ safer than etomidate, more collapse).
  **`airway-management-flow` v2** — added a physiologic-optimisation step,
  NIV/PEEP preox per PREOXI, and cross-links to the new ref + modified-shock-index
  + capnography. **154 modules.**
- 2026-09-02 — New **`iv-fluids`** reference (from `iv_fluids_guide.html`):
  7-fluid composition table + best-use/avoid table, the population-specific
  choice (balanced for sepsis OR 0.84, saline for TBI OR 0.55 — 2020 network
  meta-analysis), permissive hypotension (Bickell + EAST targets + TBI carve-out),
  PROPPR 1:1:1 caveat, the contradictory prehospital-plasma record
  (PAMPer + / COMBAT − / RePHILL − for lyophilized), and the traps (HES, D5W,
  balanced-in-TBI, hypotonic-to-resuscitate, fluid warming). **155 modules.**
- 2026-09-02 — Batch 4 (4 CV guides) + **direction correction**. User feedback:
  this is a *bedside clinical decision support tool* for EM/ICU/Anes — adapt
  source material into **management content** (targets, doses, titration,
  what-to-do / what-to-avoid), NOT trial summaries or "audit of a social post"
  write-ups. Action taken:
  - **Deleted `ebm-study-audits`** (trial-audit framing, not bedside-actionable).
  - New **`septic-shock-resuscitation`** (Tier 1, management): first-hour actions,
    MAP target + when to raise it, the norepi → vasopressin → hydrocortisone →
    angiotensin II sequence, "test fluid responsiveness before every bolus",
    CRT/lactate perfusion targets (+ the lactate-after-12h trap), phenotype-driven
    escalation table, and an explicit "what NOT to chase" list. Absorbs the
    actionable residue of the 25-years-of-septic-shock review.
  - **`physiologically-difficult-airway` v2** — added a preoxygenation-reserve
    section (desaturation time by patient type at FAO2 0.87 vs room air; sux
    recovery timeline) as an actionable item; absorbs the Benumof-graph numbers.
  - **`pediatric-appendicitis-score` v2** — Alvarado/PAS/pARC comparison table,
    pARC AUC + 49%-vs-23% decisiveness, per-tool pitfalls (a decision tool, kept).
  - 4th guide (`peripheral-iv-vasopressor-adverse-events.html`) = duplicate of
    the batch-3 file, no action.
  - **Folded in + deleted `landmark-trials-sepsis-resuscitation`** — its
    bedside-actionable rows (EGDT null, SAFE, CLASSIC, VASST, NICE-SUGAR glucose
    ≤ 180, TRISS Hgb 7, ANDROMEDA CRT) became an "adjunct targets the trials
    settled" table + two "what NOT to chase" lines in `septic-shock-resuscitation`.
    4 `related`-array refs repointed.
  **154 modules.** `validate 154/0/0`, `build 154`, `test 142/142`. PWA verified
  live on the dev server: 154 modules synced, deleted modules gone,
  `septic-shock-resuscitation` renders, MSI calc computes (120, 90/60 → MAP 70,
  MSI 1.71 → high-risk band), search ranks it top for "septic shock".
  **Going forward:** every CV conversion is management-first. No more study-audit
  modules.
- 2026-09-02 — Big batch. Deleted `landmark-trials-sepsis-resuscitation` (folded
  into `septic-shock-resuscitation`). New management modules: `septic-shock-resuscitation`,
  `albumin-furosemide-push-pull`, `ecmo-support`, `icu-workflow`,
  `perioperative-glycemic-management`, `contrast-associated-aki`, `awake-intubation`
  (procedure), `emergency-drugs-pregnancy`, `csection-analgesia-prospect`,
  `sedation-analgesia-agents`, `erc-2025-pediatric-life-support`. Updated:
  `iv-fluids` v2 (Ezplaz), `acls-adult-cardiac-arrest` v2 (refractory VF / DSED),
  `physiologically-difficult-airway` v2 (preox reserve), `abg-interpretation` v2
  (P50), `pediatric-appendicitis-score` v2. New reference categories:
  `critical-care`, `perioperative`, `obstetric`. **164 modules**, green.
- 2026-09-02 — **Batch 5: the 7 CV Pocket Guides** (`~/Documents/criticalvector/tools/`).
  Big, current (2024–26) structured reference apps for EM / ICU / OB / Vent /
  Neonatology / Anesthesia — ~90 subsections, mapped in `SOURCE_MATERIALS.md`.
  This is the reference backbone to build the rest of Kairos on: convert
  subsection-by-subsection, expanding an existing module where one exists.
  Neonatology probably needs its own nav section — decision for the user.
- 2026-09-02 — Vent pocket guide: new **`ventilator-modes`** + **`ventilator-management` v3**.
- 2026-09-02 — EM pocket guide batch 1: `rsi-seven-ps`, `status-epilepticus-adult`,
  `hyperkalemia-management`, `sodium-disorders`, `toxidromes-and-overdoses`,
  `trauma-primary-survey`, `acute-ischemic-stroke`.
- 2026-09-02 — ICU pocket guide batch 1: `padis-bundle`, `aki-staging-rrt`,
  `icp-tbi-management`.
- 2026-09-02 — OB pocket guide batch 1: `maternal-cardiac-arrest`,
  `postpartum-hemorrhage`, `preeclampsia-eclampsia-hellp`,
  `obstetric-delivery-emergencies`, `efm-fetal-heart-rate`.
- 2026-09-02 — Anesthesia pocket guide batch 1: `malignant-hyperthermia`,
  `neuromuscular-blockade-reversal`, `neuraxial-anesthesia`, `mac-values`,
  `preanesthesia-checklist`. **193 modules.** Remaining pocket-guide tails:
  anesthesia POCUS/drug-conc-math/abx-prophylaxis, OB outpatient GYN, EM/ICU
  (anaphylaxis, dyspnea/NIV, AMS, syncope calc, EM & critical-care scores).
- 2026-09-02 — **Neonatology subsection added to the Peds Module** (new category
  `neonatology` in sections.json). First 5 modules from the neonatology pocket
  guide: `nrp-algorithm` (NRP 2021 — 3 questions, HR-triggered PPV→compressions→
  epi, doses, pre-ductal SpO2 targets), `neonatal-jaundice` (AAP 2022 — screening,
  escalation-of-care triggers, breastfeeding-vs-breast-milk, phototherapy/exchange/
  IVIG), `neonatal-hie-cooling` (Sarnat staging, cooling eligibility + 33.5–34.5 °C
  ×72 h, multiorgan involvement), `neonatal-seizures` (jitteriness vs seizure,
  Volpe types, correct-glucose/Ca/Mg-first, phenobarb→fosphenytoin/LEV→pyridoxine),
  `infant-of-diabetic-mother` (hyperinsulinaemia, AAP vs PES glucose thresholds,
  D10W 2 mL/kg + GIR 6–8), plus `apgar-score` (peds-tool + embedded additive
  calc), `neonatal-rds` (surfactant deficiency, antenatal steroids, CPAP-first),
  `newborn-routine-care` (normal vitals, vit K, eye prophylaxis, 3 exams, normal
  variants, discharge checklist). **8 neonatology modules.** Still optional:
  prematurity-by-system, birth injury, IEM, growth/milestones, chromosomal.
- 2026-09-02 — **Batch 6: the missing calculators** (audit of `ED_ICU_OR_Calculators.xlsx`
  — 94 targets, ~43 built → filling the gap). New this batch: `ottawa-ankle-rules`,
  `ottawa-knee-rule`, `canadian-syncope-risk-score`, `glasgow-blatchford`, `sofa-score`,
  `news2`, `ich-score`, `pf-ratio`, `rsbi`, `modified-sgarbossa`, `revised-geneva`,
  `ciwa-ar`, `cows`, `caprini-vte`, `years-pe`, `spesi`, `ottawa-sah-rule`, `four-score`,
  `nexus-chest-ct`, `abc-score-mtp`, `hunter-serotonin`, `mews`, `surgical-apgar`,
  `ariscat`, `el-ganzouri`, `cpot`, `rockall`, `revised-trauma-score`, `harris-benedict`
  (formula), `improve-bleed`, `ranson`, `brugada-vt`, `cam-icu`, `refeeding-risk`,
  `ards-berlin`, `pesi` (full, formula), `psi-port`, `bode-index`, `injury-severity-score`
  (formula). Dropped 2 as duplicates of existing drug-dosing cards (`cockcroft-gault`,
  `parkland-formula`).
- 2026-09-02 — **Batch 6b — xlsx list closed out.** Final 6: `canadian-ct-head` (CCHR),
  `canadian-cspine` (CCR 3-step), `pecarn-head` (age-stratified peds), `apache-ii`
  (15-item APS+age+chronic, mortality bands + logistic eqn noted), `rumack-matthew-nac`
  (formula — 150-line threshold + ratio), `salicylate-toxicity` (formula — level bands,
  EXTRIP HD criteria; Done nomogram deliberately NOT implemented). **All 94 xlsx
  target calculators now built or consciously covered elsewhere.** ~238 modules.
  VIS lives at `drug-dosing/dosing-fluid-math/vasoactive-inotropic-score`; Parkland,
  Cockcroft-Gault, Free-water deficit, IBW/adjusted-BW, steroid-conversion are
  drug-dosing cards. Only true remainders are refinements: NISS/TRISS and interactive
  NOC (New Orleans) — both low priority.
- 2026-09-02 — **Inputs / formula audit vs `Calculator_Logic_Build_Spec.md`.**
  Fixes: deleted `rumack-matthew-nac` (duplicate of the canonical `apap-nac-dosing`
  drug card); `harris-benedict` switched from Roza-Shizgal 1984 → original 1918
  coefficients (matches spec + MDCalc), v2; `news2` temperature band corrected
  (35.1–36.0 °C = 1 pt, was wrongly 2), v2; `apache-ii` GCS item made exact
  per-value (15 − GCS) instead of banded; `caprini-vte` rebuilt to the full 2005
  checklist + the 0–1 / 2 / 3–4 / ≥5 four-tier scheme, v2. Spot-checked ARISCAT,
  Surgical Apgar, BODE, sPESI, Revised Geneva, Rockall, Ranson, COWS, RTS, SOFA,
  ICH, Canadian Syncope, El-Ganzouri against the spec — all correct.
- 2026-09-03 — **Tier-1 verification pass on the batch-6/6b calculators** (full
  log in `docs/TIER1_VERIFICATION.md`). 4 more defects fixed: `psi-port` converted
  to the formula engine (the age term was contributing 0 in the additive build);
  `improve-bleed` age 40–84 weight 1 → 1.5 (Decousus 2011); `ciwa-ar` severe band
  ≥16 → ≥15; `refeeding-risk` minor thresholds corrected to NICE (BMI < 18.5,
  weight loss > 10%/3–6 mo) and re-banded so a lone minor ≠ "at risk". ~30 other
  new calcs confirmed correct against the spec + primary sources.
- 2026-09-03 — **Content tails — OB/GYN, EM, anesthesia.** Reference-library
  `obstetric` category renamed **Obstetric & Gynecologic** (7 existing modules
  recategorised). New: `ectopic-pregnancy`, `ovarian-torsion`,
  `pid-tubo-ovarian-abscess`, `abnormal-uterine-bleeding`, `contraception-methods`
  (from the OB pocket guide); `anaphylaxis`, `acute-dyspnea-niv`,
  `altered-mental-status` (EM pocket guide); `surgical-antibiotic-prophylaxis`,
  `anesthesia-pocus`, `drug-concentration-math` (Anesthesia Reference). +11 modules.
  Remaining pocket-guide tails: OB labor-progression / induction / preterm /
  Bartholin; anesthesia neuraxial-US already folded into `anesthesia-pocus`;
  EM post-intubation / CO poisoning cards.
- 2026-09-03 — **Task 3 content.** `childhood-immunization-schedule` (CDC/ACIP
  2025 routine 0–18 y schedule + catch-up principles; review_tier 3, needs an
  annual refresh check). Peds Module screens: `pedi-tape-weight-zones` (readable
  9-zone equipment table + weight-estimate formulae + rules of thumb, over
  `weight-zones.json`), `peds-rsi-decision-card` (7-P sequence, agent selection
  by scenario, weight-based dose ranges), `peds-drip-concentrations` (standard
  concentration vs rule-of-6, common-infusion table, rate conversion — companion
  to the `peds-drip-rate` calculator). +4 modules.
  **Still open (task 3): Procedures decision-tree branch logic** — suture
  technique nodes, fracture-pattern branches, nerve-block and POCUS trees. This
  needs a storyboarding pass (each tree's actual branches) and possibly a new
  content shape; deferred rather than rushed.

---

## 1. Things to address

### Build / infra
- [ ] **Content-CTA sub-modules still to write:** Reference Library — vent
  waveform/IABP troubleshooting media, hyperkalemia/CBC images, an
  outpatient/floor empiric-antibiotic companion (from `board_tested_infections.html`)
  and an antibiogram-driven agent-selection worksheet (needs the local
  antibiogram — see list 2); the ED/ICU + rare/time-critical syndromes are done
  (`empiric-antibiotics-ed-icu`, 2026-09-02). Vaccine Schedules (needs AAP source
  — see list 2). Peds Module
  — peds RSI decision card, Pedi Tape zone reference, peds drip concentration
  picker. Procedures — all four decision trees.
- [ ] **Pipeline wall-clock is slow in some environments** — `node validate.mjs`
  used ~24 s wall for ~0.3 s CPU on a cold VM (I/O / process-spawn latency, not
  ajv). Harmless for CI; just don't expect it to be instant. The
  `embeddedCalculator` decouple in `validate.mjs` keeps ajv itself fast as the
  content set grows.
- [x] **Deploy pipeline built** (2026-09-01) — `tools/deploy.mjs` (`npm run
  deploy`) validates + assembles `tools/dist/` (manifest, search-index, config,
  modules, `_deploy.json`; no schemas). `.github/workflows/content-deploy.yml`
  publishes it to GitHub Pages on push to `main`. `docs/DEPLOY.md` covers S3 /
  Cloudflare alternatives. **Still needs you:** pick the host, set the
  `CONTENT_BASE_URL` repo Variable, enable Pages (or swap the deploy job).
- [ ] **Point clients at the live URL.** `REMOTE_BASE` (web
  `contentStore.js`) and `ContentStore.remoteBase` (iOS) are still `null` —
  set them once the bundle is live so OTA updates turn on.
- [x] **Web app icon** — `web/public/icons/icon.svg` (2026-09-01); manifest +
  favicon + apple-touch-icon wired.
- [ ] **iOS `AppIcon` + launch screen.** Still needs raster PNGs (1024 master
  min). The web SVG (`web/public/icons/icon.svg`) is the master mark — render it
  to the iOS icon sizes and drop them into an `Assets.xcassets/AppIcon.appiconset`,
  add that to `ios/project.yml` sources.
- [x] **Swift engine tests** — `ios/Tests/EngineTests.swift` (target
  `KairosTests`, 10 cases / ~40 assertions), mirrors `tools/test.mjs`;
  `.github/workflows/ios-ci.yml` runs it on a macOS runner. 2026-09-01.
- [ ] **Xcode signing.** `ios/project.yml` `DEVELOPMENT_TEAM` is blank —
  fine for the simulator, needs a team for device installs.
- [ ] **"Flag as outdated" is a `mailto:` stub** (`content@kairos.example`).
  Decide the real routing target (email, a form, a GitHub issue template).

### Verification still owed
- [~] **iOS interaction.** The simulator-control tooling in this environment
  can't inject synthetic taps, so a `KairosUITests` XCUITest target was added
  instead (runs via `xcodebuild test`, which works). **`testProcedureTreeWalker`
  PASSED on-device** — proves taps, `NavigationStack` push, the decision-tree
  walker, terminal nodes, and Back all work. The additive-calculator,
  formula-calculator, and drug-card flows failed their first run on
  test-harness issues (below-the-fold lazy `List` tiles + strict assertion
  strings); fixed (`openSection(_:)` scroll helper, `CONTAINS` predicates) and
  the target rebuilds, but **not re-run** — one UI test took 916 s on this
  session's degraded-I/O VM. Needs a clean run in Xcode / on the `ios-ci`
  runner to confirm the three fixed cases.
- [ ] **Service worker** registration errors inside the sandboxed preview browser
  (harmless there). Confirm it registers in a real browser / installed PWA and
  that offline mode actually serves the precached shell + content.
- [ ] **Tier 6 "data clears only on full closeout"** — the `SessionStore`
  cold-launch-vs-background logic needs device testing (backgrounding, app
  switch, force-quit).

### Design decisions open
- [ ] **Tier 5 — colour/font scheme.** Both reference palettes now captured
  (`docs/PALETTES.md`). Proposed Kairos direction there: light-first, single
  geometric sans, cobalt-indigo accent (no teal — both apps use it; no gold —
  AnesCalc's). Needs: your sign-off on the direction → a swatch artifact → swap
  the tokens in `web/styles.css` `:root` + `ios/.../Theme.swift` + the section
  token map + the placeholder app icon colour + `weight-zones.json` zone colours.
- [ ] **App icon — PARKED, revisit.** Current `web/public/icons/icon.svg` is a
  converging-caret placeholder. Explored a "pulse spike hitting a point" family
  (scratchpad `pulse-a/b/c.svg`: full ECG trace / single bold spike / flatline
  breaking into one spike). None landed — the user wants to come back to it.
  Whatever's chosen re-colours with the Tier 5 palette.
- [x] **Procedure decision-tree walker UI** — built (web + iOS), 2026-09-01.
  Laceration & fracture have real region trees; the deeper branch logic (pattern
  recognition, reduction technique, peds-specific fracture patterns like buckle
  vs. Salter-Harris) is still a content-authoring pass.
- [ ] **Nerve-block volumes beyond fascia iliaca** (digital, wrist, hematoma,
  facial, intercostal, popliteal, upper-extremity) were written from general
  knowledge — `needs-primary-source` verification pass owed.
- [x] **Cormack-Lehane + Mallampati** calculators built (2026-09-01) —
  airway-flow cross-links resolve. El-Ganzouri Airway Risk Index still to add.
- [ ] **POCUS / ECG / nerve-block original image libraries** still to be created
  (Tier 2 — text criteria are in place, media is not).
- [ ] **AnesCalc's 55 drug cards** need a navigation home in the unified app —
  out of scope as content, but the nav slot / import path isn't built.
- [ ] **Obese-child dosing:** the IBW-vs-actual-weight flag in the weight-entry
  flow (per-drug, per `Drug_Dosing_Peds_Weight_Based_Spec.md`) is not implemented.
- [ ] **Pre-arrival "zone reference card"** flow (age → APLS estimate → staged
  equipment before a weight is known) — `weightZones` lib supports the estimate
  but there's no dedicated pre-arrival screen.
- [ ] **`external`-engine calculators** (GRACE, and any future proprietary score)
  render structure + cutoff only. Need licensed logic or a nomogram
  approximation before they compute.
- [ ] **Search `tags` / `keywords`** are populated only on a handful of modules —
  ongoing per-item content work, budget it alongside writing each module.
- [ ] **NIHSS severity bands** — one of several published stratifications was
  chosen; the UI must cite which.

### Content structure notes
- [ ] Decide whether **PAS** and **pARC** (peds appendicitis) live in the Peds
  Module nav (spec says yes) vs. Calculators.
- [ ] **Higher-risk BRUE** side of the pathway is a stub — needs the 2019 AAP
  framework (source below) rather than improvised tiers.
- [ ] `content/config/tiers.json` holds the Tier table; every module has a
  `review_tier`, but a few `stable` calls could be argued (e.g. corrected Ca in
  critical illness).

---

## 2. Sources to provide

### From your own existing work (Critical Vector / AnesCalc)
- [x] **Batch 1 received 2026-09-01** — 73 CV HTML guides + AnesCalc v2 source +
  `ddx_master.html`. Full inventory & integration plan in `docs/SOURCE_MATERIALS.md`.
- [x] **AnesCalc palette** — extracted to `docs/PALETTES.md` (dark navy/teal/
  charcoal + gold/amber; ASTM drug colours). Kairos must avoid teal + gold.
- [x] **CRISIS palette** — received in batch 2 (`CRISIS/App/src/styles/tokens.css`).
  Near-black `#0a0e14` ground + bright teal `#00d4aa` + teal/blue/red/amber/purple
  semantic set; Source Serif 4 / Syne / IBM Plex Mono. Captured in
  `docs/PALETTES.md` with a proposed Kairos direction (light-first, geometric
  sans, cobalt-indigo `#3D5AFE` accent — no teal, no gold). Awaiting sign-off,
  then a swatch-comparison artifact + the token swap in `styles.css` / `Theme.swift`.
- [x] **AnesCalc drug cards — DONE (Option A, full conversion), 2026-09-01.**
  `export_anescalc.swift` (compiles `DrugCard.swift`, dumps JSON) →
  `tools/import-anescalc.mjs` → **55 modules** under
  `content/modules/drug-dosing/anescalc-core/`, new `anesthesia-drug-card` schema
  + contentType, web + iOS renderers, 14 `AnesCalc — …` categories in
  `sections.json`. Drug & Dosing now 73 modules; total 136. Pipeline green.
  Still to do: port `CalculationEngine.swift` (MAC age-correction, altitude,
  infusion math, unit conversions) — cross-check vs Kairos's dosing-fluid-math.
- [x] **CV antibiotic guides** — `board_tested_infections.html`,
  `ed_icu_and_critical_infections.html` supplied → feed the empiric-antibiotic
  syndrome cards. Still need the **local antibiogram** for drug/dose specifics.
- [ ] **CV landmark-trial write-ups** — not in batch 1; still needed to
  cross-check `landmark-trials-sepsis-resuscitation.json`.
- [x] **CV originals for Tier 2 — POCUS / nerve-block / ECG CONVERTED
  2026-09-01.** `nerve-block-guide` v2 (6-phase framework + LA table + LAST +
  block index), `pocus-guide` v2 (exam-by-exam anchors: FoCUS, lung, eFAST, IVC,
  RUSH, DVT, procedural guidance), `ecg-library` v2 (all 8 OMI patterns + Brugada
  + hyperK/WPW/TdP/dig), new `neuraxial-anticoagulation` (ASRA 5th ed hold
  times), `last-lipid-rescue` v2 (ASRA 2023). Licensing/needs-primary-source
  flags cleared. Still to convert: vent (`mechanical_ventilation_full.html`),
  anticoag reversal (`bleeding_reversal_guide.html`), sutures technique,
  difficult airway.

### Tier 1 — primary-source verification (patient-safety critical)
- [x] **Full sweep of all 60 built calculator + drug-dosing modules** done
  2026-09-01 (research agent, against primary papers + MDCalc) — see
  `docs/TIER1_VERIFICATION.md`. Result: **1 scoring error** (`rcri` Class III/IV
  risk %, now fixed) + the earlier `peds-amiodarone` dose-cap fix. All other item
  weights, coefficients, doses, and cutoffs verified correct. 10 modules corrected
  and re-verified; pipeline green.
- [ ] **GRACE 2.0** — proprietary coefficients still unpublished. Module ships
  inputs + cutoffs only (cutoffs verified). License gracescore.org logic or ship a
  labelled nomogram approximation.
- [ ] **`peds-midazolam-status`** — IV and intranasal per-dose caps (5 vs 10 mg)
  vary by pathway; set them per your local status-epilepticus protocol (flagged
  `institution-specific`).
- [ ] **Peds dosing cross-check vs PedsGuide / First 5 Minutes** — the peds cards
  match PALS / AES 2016 / RAMPART; a cross-check against those two source apps'
  published numbers (README Tier 4) is still worthwhile for any that differ.
- [ ] Not-yet-built scores flagged in their build notes for when they ARE built:
  **Canadian Syncope** (9-factor table vs 2016 CMAJ), **pARC** (Pediatrics 2018
  coefficients), **Caprini** (38-item checklist, 2005 vs 2013), **IMPROVE**
  (per-item weights), **APACHE II** (Knaus diagnostic-category weights).
- [ ] **Defibrillator pad transition weight** — confirm against the specific
  defibrillator model(s) your users carry (affects `weight-zones.json` zone 6/7).
- [ ] **LMA sizing + laryngoscope blade age table** — confirm against your
  device / manufacturer.

### Tier 2 — licensing / IP (you must supply original or licensed content)
- [x] **Nerve Block** — `POCUS_Nerve_Block_Reference.html` + `asra_neuraxial_guide.html`
  supplied (CV originals). Needs conversion into `nerve-block-guide`.
- [x] **POCUS** — `POCUS_Master_Guide.html` (7.4 MB) + the nerve-block ref supplied.
  Needs conversion + a media decision (embedded images).
- [x] **ECG Library** — `CV_STEMI_Equivalents.html`, `ecg_changes.html`,
  `extreme_axis_deviation.html` supplied. Convert into `ecg-library`; original
  annotated tracings (media) still to produce.
- [ ] **AHA ACLS / PALS algorithm cards** — `code_blue_guide.html` +
  `pediatric_code_blue_guide.html` supplied (CV originals from public-domain
  science). Confirm the approach and convert into `acls-adult-cardiac-arrest`.
- [ ] **Pedi Tape / weight-zone** — final colour + boundary sign-off on the
  original 9-zone Teal→Charcoal scheme in `weight-zones.json` (also gets recoloured
  with the Tier 5 palette — currently collides with AnesCalc's teal).

### Tier 3 — sourcing / freshness
- [ ] **Vaccine schedule** — the AAP/CDC published schedule (public domain) to
  build as a refreshable dataset.
- [ ] **Empiric Antibiotic Guide** — your institution's antibiogram (plus the CAP
  "defer to local protocol" UI copy is already specified).
- [ ] **Landmark Trials** — the starter list from `Reference_Library_Content_Spec.md`
  to cross-check against your Critical Vector writing.

### Specific papers referenced by stubs
- [ ] **Brooks AF, et al. "A Framework for Evaluation of the Higher-Risk Infant
  After a Brief Resolved Unexplained Event." *Pediatrics.* 2019;144(2):e20184101** —
  for the higher-risk BRUE pathway.
- [ ] Full **screen-by-screen decision-tree branch logic** for Suture / Fractures
  / Nerve Block / POCUS (needs a storyboarding pass — you, or a dedicated content
  task).
