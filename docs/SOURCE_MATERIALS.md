# Source materials — inbound primary content

Batch 1 received 2026-09-01. Original Critical Vector guides + the AnesCalc v2
codebase. These are the maintainer-supplied sources that unblock the Tier 2 / 3
content gaps and the AnesCalc integration.

**Batch 2 (2026-09-01 later):** `CRISIS.zip` (React/Vite PWA — palette captured in
`docs/PALETTES.md`, the last blocker on the Tier 5 colour decision) + updated
`CV Guides.zip` with 8 new guides dated Sep 1:
- `fifth-universal-definition-mi.html` — **currency hit.** Fifth UDMI (2026)
  supersedes the Fourth. Applied to `twelve-lead-stemi-criteria` v2 +
  `heart-score` v2 (sex-specific troponin URL). See `TIER1_VERIFICATION.md`.
- `hope-trial-late-window-alteplase.html` — 🟢 **DONE 2026-09-02** → HOPE entry
  in the new `ebm-study-audits` reference module. (A dedicated stroke-thrombolysis
  algorithm card is still a separate, later build.)
- `ket-mid-pediatric-status-epilepticus.html` — 🟢 **DONE** → `peds-midazolam-status`
  v3 (Ket-Mid RCT note + flumazenil-in-seizure reversal line).
- `methylene-blue-adult-shock.html` — 🟢 **DONE 2026-09-02** → methylene-blue
  entry in `ebm-study-audits` (TSA / effect-size-assumption teaching point).
  (`anescalc-core/methylene-blue` drug card + VIS vasoplegia note still open.)
- `sep1-bundle-mortality.html` — 🟢 **DONE 2026-09-02** → SEP-1 entry in
  `ebm-study-audits` (confounding-by-indication + bundle-vs-component).
- `beta-blocker-cheat-sheet-audit.html` — 🟢 **DONE 2026-09-02** → new
  `beta-blocker-selectivity` reference module (Cardiac / ECG).
- `aid-icu-haloperidol-delirium.html`, `ct-first-trauma-resuscitation.html` —
  🟢 **DONE 2026-09-02** → AID-ICU and CT-first entries in `ebm-study-audits`.

**Batch 3 (2026-09-02):** `peripheralivvasopressoradverseevents.html` (CV
breakdown of ZhangJian 2026 JAMA Netw Open meta-analysis) → **converted** to the
new `peripheral-iv-vasopressors` reference module (Reference Library / Resus &
Airway).

**Batch 4 (2026-09-02):** 4 CV guides:
- `25-years-septic-shock-resuscitation-trials.html` — 🟢 **DONE** → new section
  in `ebm-study-audits` (EGDT→ANDROMEDA-SHOCK-2 arc; no single fixed target
  reproduces; phenotype-driven iterative reassessment).
- `benumof-graph-apneic-desaturation.html` — 🟢 **DONE** → new section in
  `ebm-study-audits` (attribution: desaturation curves are Farmery & Roe 1996,
  not Benumof; FAO2 0.87 → 9.9 min to 60% SaO2; sux recovery 6.8/8.5/10.2 min).
- `pediatric-appendicitis-three-scores.html` — 🟢 **DONE** →
  `pediatric-appendicitis-score` v2 (added the Alvarado/PAS/pARC comparison,
  the pARC AUC + 49%-vs-23%-decisiveness data, sharpened pitfalls).
- `peripheral-iv-vasopressor-adverse-events.html` — ⏹ **duplicate** of the
  batch-3 file (same ZhangJian 2026 meta-analysis), already covered by
  `peripheral-iv-vasopressors`. No action.

**Batch 5 (2026-09-02): the CV Pocket Guides** — `~/Documents/criticalvector/tools/*.html`.
Seven large, self-contained, current (2024–2026) interactive clinical-reference apps
(`const D = {section:{subs:{sub:{label, updated, content:()=>` HTML `}}}}`). These
are the **reference backbone Kairos should be built on** — their topic trees map
almost 1:1 onto a bedside CDS tool. Convert each subsection → a Kairos module (or an
expansion of an existing one). ~90 subsections total.

| Pocket guide | Size | Subsections (→ Kairos targets) |
|---|---|---|
| `anesthesia_reference_v4.html` | 185 KB | 🟡 **IN PROGRESS 2026-09-02** → new `malignant-hyperthermia` (crisis protocol), `neuromuscular-blockade-reversal` (TOF depth + sugammadex/neostigmine + duration table), `neuraxial-anesthesia` (CI, spinal agents/adjuncts/C-S mix, spinal hypotension, epidural levels + urgent top-up, high/total spinal, PDPH), `mac-values` (volatile MAC + age adjustment + modifiers), `preanesthesia-checklist` (MSMAID + ASA 2023 NPO incl. GLP-1). Covered: LAST (`last-lipid-rescue`), neuraxial CI anticoag (`neuraxial-anticoagulation`), CICO (`rsi-seven-ps`/`airway-management-flow`), anaphylaxis/PPH/HTN-pregnancy (OB modules), hyperK (`hyperkalemia-management`). Still: POCUS views, drug-conc math (calc), surgical abx prophylaxis, ASTM colours. |
| `em_pocket_guide_v5_final.html` | 176 KB | 🟡 **IN PROGRESS 2026-09-02** → new `rsi-seven-ps` (7 Ps + agent/NMB tables + LEMON/CICO + post-intubation), `status-epilepticus-adult` (benzo→ESETT→infusion→pentobarb/ketamine), `hyperkalemia-management` (ECG tiers, stabilise/shift/eliminate, BRASH), `sodium-disorders` (3% NaCl dosing, ODS limits, DDAVP rescue, DI, FWD), `toxidromes-and-overdoses` (recognition table + APAP/TCA/BB-CCB/salicylate), `trauma-primary-survey` (ABCDE + hemorrhagic-shock class + MTP + TBI targets + eFAST), `acute-ischemic-stroke` (time algorithm, tPA dosing/BP/CIs, thrombectomy window, ICH targets). **2026-09-03 batch:** `anaphylaxis`, `acute-dyspnea-niv`, `altered-mental-status`, `post-intubation-management`, `hemorrhagic-shock-mtp`, `efast-exam` (+ RUSH), `hs-troponin-chest-pain` (0/1-h + ACS bundle), `trauma-team-activation` (+ CDC field triage). EM guide is now essentially fully converted — only `specific_od` detail (partly in `toxidromes-and-overdoses`) and `ecg` patterns (in `ecg-library` / `twelve-lead-stemi-criteria`) remain. |
| `icu_pocket_guide_v4.html` | 88 KB | 🟡 **IN PROGRESS 2026-09-02** → new `padis-bundle` (RASS scale + 6 domains + sedative quick-ref), `aki-staging-rrt` (KDIGO stages + AEIOU + CRRT settings), `icp-tbi-management` (BTF targets + hyperosmolar dosing + SIBICC tiers). Covered elsewhere: ARDS/weaning (`ventilator-management` v3), pressors (`pressor-inotrope-reference`), shock/sepsis (`septic-shock-resuscitation`), empiric abx (`empiric-antibiotics-ed-icu`), status epilepticus (`status-epilepticus-adult`), electrolytes (`hyperkalemia-management`, `sodium-disorders`), anticoag reversal (`anticoagulation-reversal`), cardiac POCUS (`pocus-guide`). |
| `ob_pocket_guide_v4.html` | 118 KB | 🟡 **IN PROGRESS 2026-09-02** → new `maternal-cardiac-arrest` (BAACC TO LIFE + CPR mods + RCD), `postpartum-hemorrhage` (staging, 4 Ts, uterotonic ladder), `preeclampsia-eclampsia-hellp` (criteria, severe-HTN Rx, Mg protocol, HELLP delivery timing), `obstetric-delivery-emergencies` (shoulder dystocia HELPERR, cord prolapse, abruption), `efm-fetal-heart-rate` (NICHD categories, decel types, intrauterine resus). **2026-09-03:** `ectopic-pregnancy`, `ovarian-torsion`, `pid-tubo-ovarian-abscess`, `abnormal-uterine-bleeding`, `contraception-methods`, `labor-progression` (Zhang + Bishop), `induction-augmentation`, `preterm-labor`, `chronic-htn-gdm-pregnancy` (CHAP era), `prenatal-screening`, `fetal-surveillance` (BPP + Doppler), `bartholin-vulvar-emergencies`. OB guide fully converted except `obpocus` (folded into `anesthesia-pocus`) and `ob_tools` (formulas → calculators). |
| `vent_pocket_guide_v1.html` | 110 KB | 🟡 **IN PROGRESS 2026-09-02** → new `ventilator-modes` (VC/PC/adaptive, SIMV, cross-manufacturer table, APRV 4 params, PRVC/NAVA/PAV+/ASV + evidence) + `ventilator-management` v3 (waveform/loop interpretation, asynchrony types, VIDD + trach timing TracMan, alarm patient-vs-vent table + Pplat branch-point, DOPES/DOTTS, Hernandez 2016 post-extubation). **2026-09-03:** `status-asthmaticus-ventilation`, `copd-invasive-ventilation`, `peep-fio2-ladder` (both ARDSNet ladders), `advanced-ards-ventilation` (APRV 4-param setup + judicious recruitment + IMPROVE/PROVHILO intraop). Remaining ~30 deep mode-specific subsections (NAVA, PAV+, ASV, IntelliVent, cross-manufacturer, Owens tables) are specialist / low bedside yield — not planned. |
| `neonatology_pocket_guide_v1.html` | 139 KB | APGAR, exam timeline, growth params, milestones, developmental-delay eval, **NRP algorithm ABCD (NRP 8th ed / ILCOR 2020)**, LBW/prematurity, SGA/IUGR/LGA, birth injury, infant feeding, immunization, chromosomal disorders, inheritance modes, infant of diabetic mother, neonatal seizures, **neonatal jaundice AAP 2022**, IEM, RDS/surfactant, HIE & therapeutic hypothermia (Sarnat) |
| `em_pocket_guide_v5.html` | 176 KB | identical to `_final` — use `_final` |

Plan: work section-by-section; prefer expanding an existing Kairos module where one
exists (e.g. vent → `ventilator-management`, pressors → `pressor-inotrope-reference`,
sepsis → `septic-shock-resuscitation`, PPH → `emergency-drugs-pregnancy`), else new
module. Neonatology likely warrants its own section (new nav area) — flag for the user.

**Batch 4b (2026-09-02):** 2 more CV guides:
- `erc-2025-pediatric-life-support.html` — 🟢 **DONE** → new `erc-2025-pediatric-life-support`
  reference (ERC 2025 PLS changes: airway numeric limits, adolescent 500 mL bolus cap,
  IBW drug dosing, 4→8 J/kg energy, hydrocortisone + TXA specifics).
- `blood-gas-analysis-chart-audit.html` — actionable bit (P50 = PO₂ at 50% sat ≈ 26.6 mmHg,
  not the 90% point; "small SpO₂ drop = large PaO₂ drop") → fold into `abg-interpretation`.

Locations (not in this repo):
- `~/Desktop/CV Resources/CV Guides/` — 54 guides
- `~/Documents/criticalvector/tools/` — 7 CV Pocket Guides (Batch 5, see table above)
- `~/Desktop/CV Resources/The_Critical_Vector_HTML_Library/` — 19 guides
- `~/Desktop/CV Resources/ddx_master.html` — differential-diagnosis master (1.3 MB)
- `~/Desktop/POCUS_Nerve_Block_Reference.html`
- `~/Documents/School Work/.../AnesthesiaCalc v2/` — AnesCalc v2 Swift source

Status: 🔲 not started · 🟡 mapped, not converted · 🟢 integrated

---

## AnesCalc v2 — drug cards + palette

**`AnesthesiaCalc v2.zip` → `AnesthesiaCalc/Models/DrugCard.swift`** (1317 lines).
`DrugCard` struct: `name, brandName, category, mechanism, onset, duration, dosing,
cautions[], pearls[], colorKey, tallManLetters, reversal`. `DrugCardLibrary.all`
holds ~45 drugs across 14 `DrugCategory` cases (Induction, Benzodiazepine,
Volatile, NMB, Opioid, Local Anesthetic, Vasopressor, Reversal, Anticholinergic,
Antiemetic, GI/Aspiration, Emergency, Methylene Blue, Anticoagulant/Hemostatic).

- 🟡 **Plan:** add a `contentType: "anesthesia-drug-card"` schema (text reference
  card, not a per-kg calculator — distinct from the existing `drug-card` schema)
  OR extend `reference` with a `drugCard` block. Parse `DrugCardLibrary.all` →
  one JSON module per drug under
  `content/modules/drug-dosing/anescalc-core/`. Section "Drug & Dosing Cards",
  category "Existing Core (AnesCalc)". ~45 modules.
- `AnesthesiaCalc/Models/CalculationEngine.swift` (876 lines) + `PatientModel.swift`
  — the MAC age-correction, altitude, infusion math, unit conversions. Cross-check
  against Kairos's dosing-fluid-math calcs; port anything Kairos lacks.
- `AppIcon_source.svg` — AnesCalc's icon (for visual-distinctness comparison).

**Palette** → `AnesthesiaCalc/Utilities/ThemeManager.swift`. Captured in
`docs/PALETTES.md`. Headline: AnesCalc is **dark navy/teal/charcoal grounds +
gold/amber accents**, with an ASTM drug-class color set as the default theme.
Kairos must avoid that space → **not teal, not gold/amber** (the current
placeholder `#4bb3a7` collides with AnesCalc's "Deep Teal" theme — change it).

---

## Procedures — POCUS / Nerve Block (Tier 2, was blocked)

| File | Feeds | Notes |
|---|---|---|
| `POCUS_Nerve_Block_Reference.html` (52 KB) | `pocus-guide`, `nerve-block-guide` | "POCUS-Guided Nerve Block — Procedural Reference". Original CV content → replaces the Tier-2 placeholder text. 🟢 **DONE 2026-09-04** — re-supplied and used to close the "still open: nerve-block as an interactive tree" item: new `pocus-nerve-block-checklist` procedure (workflow outputType, 6-node sequential run-through + a tickable 10-rule safety checklist), built from the guide's Part II step-by-step sequence. `nerve-block-guide` → v3, cross-linked. Dosing tables + the full LAST algorithm deliberately NOT restated (already the single source of truth in `nerve-block-guide` / `last-lipid-rescue`). |
| `CV Guides/POCUS_Master_Guide.html` (7.4 MB) | `pocus-guide` (all exams) | Full POCUS guide, EM/CC/anesthesia. Large — has embedded images; extract text + decide on media. |
| `CV Guides/asra_neuraxial_guide.html` (16 KB) | new `neuraxial-anticoagulation` ref + `nerve-block-guide` | ASRA 5th ed neuraxial-block-on-anticoagulants: DOAC stop/restart times, heparin, antiplatelets, warfarin. |
| `CV Guides/sutures-tying-guide.html` (287 KB) | `laceration-repair` (technique nodes) | Suture/knot-tying technique — deepens the laceration decision tree. |

🟡 mapped. POCUS/nerve-block/ECG Tier-2 flags can move from "needs original
content" → "content supplied, needs conversion".

---

## Reference Library — Infectious Disease (Tier 3, was blocked)

| File | Feeds |
|---|---|
| `CV Guides/board_tested_infections.html` + `infections I - board_tested_infections.html` | 🟢 **DONE 2026-09-02** → `empiric-antibiotics-outpatient` (bacterial + fungal + viral outpatient/floor syndromes; classic triad / signature finding / one regimen). Coverage-class only, doses omitted. |
| `CV Guides/ed_icu_and_critical_infections.html` + `infections 2 - …` | 🟢 **DONE 2026-09-02** → `empiric-antibiotics-ed-icu` (bacterial ED/ICU syndromes incl. HAP/VAP, urosepsis, intra-abdominal, nec fasc, meningitis, febrile neutropenia, endocarditis, CLABSI, diabetic foot, TSS; fungal ICU emergencies; ICU viral; rare/time-critical recognition table). Coverage-class only, doses omitted. |
| `CV Guides/strongyloides_hyperinfection_guide.html` | `board-infections` (parasitic) |
| `~/Desktop/CV Resources/uwhealth-peds-empiric-antibiotics.pdf` | peds antibiotic card |

🟡 This is the reusable Critical Vector antibiotic content the CAP module's
buildNote asked for. Still needs the **local antibiogram** for drug/dose specifics.

---

## Reference Library — Anticoagulation / Hemostasis

| File | Feeds |
|---|---|
| `CV Guides/bleeding_reversal_guide.html` (33 KB) | 🟢 `anticoagulation-reversal` v5 — rewritten from CV content (Andexxa withdrawal, TEG/ROTEM, bedside algorithm, pitfalls). CV guide Part II (antiplatelet decisions — STEMI/PCI loading, NSTE-ACS, stroke DAPT, CYP2C19) → separate module TBD. |
| `CV Guides/antidotes_reversal_agents.html` (62 KB) | 🟢 **DONE 2026-09-02** → new `antidotes-reversal-agents` reference (13 CV sections; adult doses in-line, key peds doses called out; anticoag reversal stays in its own module). |
| `CV Guides/blood_products_guide.html` + `CV_Fibrinogen_vs_Cryoprecipitate.html` | 🟢 **DONE 2026-09-02** → new `blood-products` ref (6 products + fibrinogen concentrate vs cryo + CRYOSTAT-2). `early-calcium-minimal-transfusion.html` (calcium / lethal diamond) still to fold in. |
| `CV Guides/CV_TEG_Interpretation_Guide.html` | 🟢 **DONE 2026-09-02** → new `teg-rotem-interpretation` ref (TEG 5000 + 6s + platelet mapping + ROTEM crosswalk + goal-directed framework + pitfalls). |
| `CV Guides/asra_neuraxial_guide.html` | see Procedures above |

---

## Reference Library — Cardiac / ECG (Tier 2)

| File | Feeds |
|---|---|
| `The_Critical_Vector_HTML_Library/CV_STEMI_Equivalents.html` | `ecg-library` (De Winter / Wellens / Sgarbossa / hyperacute T / posterior / aVR) — original CV text replaces the placeholder |
| `CV Guides/ecg_changes.html` | `ecg-library` (electrolyte / drug ECG effects) |
| `CV Guides/extreme_axis_deviation.html` | `ecg-library` (axis) |
| `CV Guides/CV_TEG_Interpretation_Guide.html` | 🟢 done — see Anticoagulation section |
| `The_Critical_Vector_HTML_Library/CV_cardiac-pulm-physiology.html` | new `cardiopulm-physiology` ref |
| `The_Critical_Vector_HTML_Library/CV_Modified_Shock_Index.html` | 🟢 **DONE 2026-09-02** → new `modified-shock-index` calculator (MSI = HR ÷ MAP; formula engine, 4 interpretation bands, test-locked). |
| `The_Critical_Vector_HTML_Library/CV_Heart_Failure_Chronic_to_Acute.html` | 🟢 **DONE 2026-09-02** → new `heart-failure-continuum` ref (6 cardiomyopathy phenotypes + HFpEF evidence scorecard/phenotype treatment + cardiogenic shock in the DanGer Shock era with SCAI stages, device selection, escalation algorithm). |
| `The_Critical_Vector_HTML_Library/CV_Vasopressors_Inotropes.html` | 🟢 **DONE 2026-09-02** → new `pressor-inotrope-reference` (infusion formulas, mixing cards, tiered receptor/hemodynamic table, vasoplegia rescue). |

---

## Reference Library — Pulmonary / Vent

| File | Feeds |
|---|---|
| `CV Guides/mechanical_ventilation_full.html` (109 KB) | 🟢 `ventilator-management` v2 — expanded from CV content (ARDSNet, PEEP ladder, ΔP, asthma strategy, weaning, VAP bundle). Remaining sub-sections (APRV, loops, capnography-on-vent, closed-loop modes) still to add. |
| `CV Guides/ventilator_loops.html` + `CV_Ventilation_Modes_Reference.html` | `ventilator-management` (loops, modes) |
| `CV Guides/heart-lung-interactions-ards.html` + `CV_Pulmonary_West_Zones_Gas_Exchange.html` + `CV_PEEP_Sepsis_Mortality.html` | vent physiology refs |
| `CV Guides/capnography.html` | 🟢 **DONE 2026-09-02** → new `capnography` reference (waveform phases, abnormal-pattern table, arrest prognostication + ILCOR caveats, setting targets). |
| `CV Guides/invasive_waveform_diagnostics.html` (278 KB) | new `invasive-waveforms` ref (feeds 12-lead/IABP) |

---

## Procedures — Airway

| File | Feeds |
|---|---|
| `CV Guides/physiologically-difficult-airway.html` | 🟢 **DONE 2026-09-02** → new `physiologically-difficult-airway` ref (4 deadly profiles + evidence-corrected induction matrix, incl. RSI trial Dec 2025); `airway-management-flow` v2 cross-links it + adds a physiologic-optimisation step. |
| `CV Guides/difficult_airway.html` + `CV_Difficult_Airway_Physiology.html` | 🟢 **DONE 2026-09-03** → new `anatomically-difficult-airway` ref (DAS 2025 Plans A-D, the Vortex, scalpel-bougie-tube eFONA, human factors, team brief) + new `macocha-score` calculator; `CV_Difficult_Airway_Physiology.html` folded into `physiologically-difficult-airway` v3 (INTUBE figures, 5 stacking phases, agent haemodynamic table). |
| `CV Guides/awake_intubation_guide.html` | 🟢 **DONE 2026-09-02** → new `awake-intubation` procedure (workflow: decide → contraindications → prepare → topicalise ≤ 9 mg/kg LBW → 'just enough' sedation → HFNC → intubate → THEN induce; DSI fallback). |
| `CV Guides/refractory_vf_dsed.html` | 🟢 **DONE 2026-09-02** → `acls-adult-cardiac-arrest` v2 refractory-VF section (vector change vs DSED, DOSE-VF results + honest caveats, sequential-not-simultaneous). |
| `CV Guides/code_blue_guide.html` + `pediatric_code_blue_guide.html` | 🟢 **DONE 2026-09-04** → new `code-leadership-run-the-room` ref (role assignment, closed-loop, CPR-quality targets, epi timing, calcium/bicarb not-routine, refractory-VF move); `acls-adult-cardiac-arrest` → v3 (matching calcium COCA / bicarb BIHCA lines); new `peds-cardiac-arrest` peds-tool (PALS 1-2-4 numbers card). |
| `CV Guides/bis_monitoring.html` | new `bis-monitoring` ref (sedation workflow) |

---

## Drug & Dosing — Peds

| File | Feeds |
|---|---|
| `CV Guides/peds_drug_database_v4_us_complete.html` (82 KB, "Fully Reviewed") | **cross-check every `content/modules/drug-dosing/**` peds card** (the README Tier 4 item) + expand |
| `CV Guides/peds_drug_database.html` + `peds_drugs_reference.html` | same |
| `CV Guides/uw_em_drug_guide.html` (54 KB) | adult ED drug reference — new cards or cross-check |
| `CV Guides/emergency-drugs-pregnancy.html` (49 KB) | new `ob-emergency-drugs` ref (OB/Newborn section) |
| `CV Guides/rocuronium_dosing.html` | `peds-rocuronium-rsi` cross-check |
| `The_Critical_Vector_HTML_Library/CV_ketamine-drip-pcc..html` | 🟢 **DONE 2026-09-04** → folded into the `ketamine` AnesCalc drug card v2 (JTS prolonged-casualty-care sedation infusion: load, starting rate, 3 mg/mL mix, titration step, one-drug-per-bag caution). The rate-conversion tables (mL/hr, drop-count) were left as prose math rather than a live calculator — candidate for a small infusion-rate calculator later. |
| `The_Critical_Vector_HTML_Library/CV_Ketamine_Clinical_Pharmacology.html` + `CV Guides/spice-iii-dexmedetomidine.html` + `remimazolam_guide.html` | sedation drug refs / AnesCalc cards |
| `CV Guides/dex_polyuria_guide.html` | 🟢 **DONE 2026-09-04** → folded into the `dexmedetomidine` AnesCalc drug card v2 (polyuria / DI-mimic caution: 3-pathway AVP-AQP2 mechanism, recognition, exclusion list, management). |

---

## Calculators — cross-check / new

| File | Feeds |
|---|---|
| `CV Guides/cspine_rules_guide.html` | 🟢 **DONE 2026-09-02** → new `decision-rules-cspine-ct-head` reference (NEXUS/CCR/CCHR/NOC, both head-to-head trials, quick-ref). Interactive CCR + CCHR + NOC calculators still a later add. |
| `CV Guides/pe_guideline_cheatsheet_CV.html` | 🟢 **DONE 2026-09-02** → new `acute-pe-guideline-2026` ref (A–E clinical categories, advanced-therapy Table 7, anticoag highlights incl. half-dose extended-phase DOAC, RV-failure sedation caution). sPESI/Hestia calculators still to build. |
| `The_Critical_Vector_HTML_Library/CV_Shock_Classification_Field_Guide.html` | 🟢 **DONE 2026-09-02** → new `shock-classification` reference (4-type hemodynamic table, SCAI stages, bedside algorithm, POCUS accuracy, mixed shock). A dedicated ATLS hemorrhage-class table is still a smaller separate add. |
| `CV Guides/iv_fluids_guide.html` | 🟢 **DONE 2026-09-02** → new `iv-fluids` ref (7-fluid composition + best-use table, sepsis-vs-TBI population choice, permissive hypotension, PROPPR, contradictory prehospital-plasma record, the traps). |
| `CV Guides/volemic_status_resuscitation.html` | 🟢 **DONE 2026-09-02** → Ezplaz (first FDA-licensed US freeze-dried plasma, July 2026) folded into `iv-fluids` v2. Rest is a near-dup of `iv_fluids_guide`. |
| `CV Guides/push-pull-albumin-furosemide.html` | 🟢 **DONE 2026-09-02** → new `albumin-furosemide-push-pull` ref (when it works / is a waste, 25% vs 5%, 30–60 min timing, revised-Starling mechanism, Chalikias 2026). |
| `CV Guides/volemic_status_resuscitation.html` (residual) | 🟢 **DONE 2026-09-04** — the guide is hemorrhagic-shock fluid strategy, not VExUS (that row was mislabelled). Fully covered: `iv-fluids` v2 (Ezplaz + prehospital-plasma record) + `hemorrhagic-shock-mtp` v2 (austere / no-blood-available section: freeze-dried plasma ≠ red cells, crystalloid by population). A true VExUS / venous-congestion module is still worth building from other sources. |
| `CV Guides/hypertonic_saline_vs_mannitol.html` | 🟢 **DONE 2026-09-02** → new `hyperosmolar-therapy` ref (mechanism, acute-window evidence, dosing, safety hard-stops, volume-status bedside decision). |
| `CV Guides/ci_aki_prevention_guide.html` | 🟢 **DONE 2026-09-02** (reference: `contrast-associated-aki`, tracking row missing until now) + 🟢 **DONE 2026-09-04** → new `mehran-ci-akin-score` calculator (the Mehran score existed only as prose/table in the reference; now also an interactive calculator, cross-linked both ways). |
| `The_Critical_Vector_HTML_Library/CV_Drug_Interactions_Reference.html` | 🟢 **DONE 2026-09-04** → new `drug-interactions-high-yield` ref (9 mechanism/risk/fix pairs, 3 antibiotic-specific toxicities, QT-prolonging drug-class quick list). |
| `The_Critical_Vector_HTML_Library/CV_Austere_Disaster_Medicine.html` (Part Three) | 🟢 **DONE 2026-09-04** → new `crush-syndrome` ref (entrapment physiology, 2-hour tourniquet/isolation threshold, hyperkalaemia treatment ladder, goal-directed fluid resuscitation, austere renal-replacement bridging). Parts One/Two still open — see "New content types" below. |
| *(tracking cleanup)* `CV_ICU_Workflow_Admission_Rounding_Signout.html`, `CV_ECMO_Advanced_Circulatory_Support.html`, `CV_Perioperative_Hyperglycemia.html`, `CV_Cesarean_Section_Pain_Management_PROSPECT.html` | Discovered 2026-09-04 to already be **fully converted** (`icu-workflow`, `ecmo-support`, `perioperative-glycemic-management`, `csection-analgesia-prospect`) — these rows were simply never added when the conversions happened. No content gap; documentation-only fix. |
| `CV Guides/biostatistics-for-clinicians.html` | new `ebm` / biostats ref |

### `~/Desktop/CV Resources/Extremis/build_package/ED_ICU_OR_Calculators.xlsx` — the calculator spec

94 target calculators listed; audited 2026-09-02. **Batch 6 + 6b — list closed
out** (45 net new; project ~238 modules; every one of the 94 targets is now built
or consciously covered by a drug-dosing card / reference module): Ottawa Ankle/Knee, Canadian
Syncope, Glasgow-Blatchford, SOFA, NEWS2, ICH Score, P/F ratio, RSBI, Modified
Sgarbossa, Revised Geneva, CIWA-Ar, COWS, Caprini, YEARS, sPESI, PESI (full),
Ottawa SAH, FOUR Score, NEXUS Chest CT, ABC/MTP, Hunter serotonin, MEWS, Surgical
Apgar, ARISCAT, El-Ganzouri, CPOT, Rockall, Revised Trauma Score, Harris-Benedict,
IMPROVE bleed, Ranson, Brugada VT, CAM-ICU, refeeding risk, ARDS Berlin, PSI/PORT,
BODE, ISS, **Canadian CT Head (CCHR), Canadian C-Spine (CCR), PECARN peds head,
APACHE II, Rumack-Matthew/NAC, salicylate toxicity**. **Remainders (refinements
only, low priority):** full 40-item Caprini, NISS/TRISS registry calculators,
interactive New Orleans Criteria. The Done nomogram is deliberately not built —
`salicylate-toxicity` uses level + acid-base + EXTRIP HD criteria instead.

---

## New content types / sections to consider

- **`ddx_master.html` (1.3 MB)** — a full differential-diagnosis reference. Would
  be a new content type (`ddx`) and arguably a 6th nav area, or a Reference
  Library sub-section. Big; defer until batch is fully in and the shape is clear.
- **Badge-buddy references** (`CV_badge-buddy-*`) — dense pocket-card layouts;
  could seed a "quick reference" view or the home-screen cheat sheet.
- **`mnemonics_guide.html`, `perls_map.html`** — cross-cutting; could be a
  Reference Library "pearls & mnemonics" module.
- **`CV_Austere_Disaster_Medicine`** — Reference Library now has an obvious home
  (Resuscitation & Airway, same as hemorrhagic-shock-mtp/trauma-team-activation).
  Part Three (Crush Syndrome) converted 2026-09-04 → new `crush-syndrome`. Parts
  One/Two (hazmat scene management/toxidromes, white-phosphorus/incendiary
  casualties) still to convert — general toxidrome recognition already lives in
  `toxidromes-and-overdoses`, but scene management and incendiary-injury care
  are genuinely uncovered.
- **`ballistics_blast_manual_v6_lightmode.html` (84 KB)** and
  **`intoxicating-substances-reference.html` (154 KB, 12 classes / 39
  substances)** — both large, high-value, and out of scope for a single batch;
  each needs its own dedicated conversion pass (ballistics likely splits into
  several Trauma reference modules; the substances reference likely splits by
  drug class). Next big-ticket content projects.

---

## Immediate next steps (when the maintainer says go)

1. **AnesCalc drug cards** — new schema + parser, ~45 modules. Highest value, self-contained.
2. **Palette** — pull the CRISIS palette too, then propose 2-3 Kairos options that
   avoid both (see `docs/PALETTES.md`).
3. **POCUS / nerve-block / ECG-equivalents** — convert the 3-4 supplied HTML
   guides into the existing `pocus-guide` / `nerve-block-guide` / `ecg-library`
   modules; clear the Tier-2 "needs original content" flags.
4. **Vent + anticoag reversal** — rewrite `ventilator-management` and
   `anticoagulation-reversal` from the CV full guides.
5. **Peds drug cross-check** — reconcile the peds cards against
   `peds_drug_database_v4_us_complete.html`; log discrepancies in
   `docs/TIER1_VERIFICATION.md`.
