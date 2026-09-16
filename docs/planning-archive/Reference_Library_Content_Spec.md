# Section 4: Reference Library — Content Build Spec

**Currency note:** The AHA published a full guidelines refresh on **October 22, 2025**,
superseding the 2020 ACLS/BLS/PALS guidelines (valid through ~2030). The ACLS/PALS content
below reflects the 2025 refresh, not the older 2020 version — flagging this explicitly
because it's recent enough that older reference material (including possibly your own
prior notes) may still reflect 2020 guidance.

**Second currency note — pediatric-specific, now resolved:** the European Resuscitation
Council also published a 2025 guidelines update specifically for pediatric life support
(Djakow J, Turner NM, Skellett S, et al. European Resuscitation Council Guidelines 2025
Paediatric Life Support. *Resuscitation.* 2025;215(Suppl 1):110767). Per the Resuscitation
Council UK's comparison against their prior 2021 guidance: **there were no changes to core
paediatric BLS recommendations** — the ERC and AHA/AAP pediatric BLS approaches remain
substantively aligned, so the AHA-based content below doesn't need a structural rework.
One genuinely new, worth-adding clinical pearl did surface in the ERC update: **most
resuscitation drugs are hydrophilic and don't distribute into fatty tissue, so they should
be dosed by ideal body weight, not actual body weight, in obese children** — watch for
exceeding adult max doses in children with a high BMI. This has been added to
`Drug_Dosing_Peds_Weight_Based_Spec.md`. ERC also confirms the NLS (Newborn Life Support)
vs. PLS (Pediatric Life Support) boundary: use NLS during the neonatal/maternity unit stay,
or up to 24 hours of life if born out-of-hospital, then transition to PLS.

**Separate flag — Vaccine Schedules module, build decision made and status re-confirmed:**
source this module from the **AAP-published immunization schedule** (aap.org /
redbook.solutions, also mirrored at immunize.org), not directly from CDC.gov. Context: in
January 2026 the HHS-directed CDC revised the childhood schedule without the usual ACIP
process, cutting recommended vaccines from 17 to 11 and moving others to shared clinical
decision-making. A federal court (*American Academy of Pediatrics v. Kennedy*, D. Mass.)
issued a preliminary injunction in March 2026 staying that revision — along with the ACIP
member appointments used to push it through — reverting the legally-operative schedule to
the pre-2026 version, which is what AAP and the other plaintiff organizations (ACP, APHA,
IDSA, SMFM, and others) are publishing. **As of the most recent filings (July 2026), that
injunction remains in effect** — the case is still active on two tracks (an appeal of the
stay, and discovery on the administrative record at the trial court), so nothing has
resolved definitively, but the AAP-aligned schedule remains the operative one right now.
So the AAP schedule is both the evidence-based source and, currently, the legally operative
one. **Still build the lookup as a live-updatable dataset, not a hardcoded static table** —
that part of the original caution stands regardless of source: whoever is publishing the
authoritative schedule, it's a document that gets revised, and litigation status can change
again before this app ships. Re-check the source at build time and don't treat this note's
July 2026 status as permanent.

---

## ACLS / PALS Algorithms *(2025 AHA refresh)*

**Licensing — resolved, and this changes how you build this section:** AHA's copyright
policy explicitly states that permission to reproduce "all or substantially all" of an AHA
copyrighted work — which an ACLS/PALS algorithm section is — is NOT granted through their
normal permissions process. It's referred to AHA Corporate Relations for a separate business
negotiation, and even standard permission grants require a processing fee, a signed Copyright
Use Agreement, are restricted to non-commercial/educational use, and cap at 10% of text or
25% of charts/illustrations per request. The existing "AHA ACLS" app on the App Store is
officially AHA-endorsed and built in direct collaboration with AHA — that's the licensed path,
and it's not one this project has.

**What this means for the build:** don't reproduce AHA's algorithm diagrams, exact step
sequences, or wording. The underlying clinical science (compression rates, drug doses, drug
sequencing, reversible-cause mnemonics) is public-domain medical knowledge, not AHA's
copyrighted expression of it — write your own algorithm cards, in your own layout and
wording, describing the same clinical steps. This is exactly the same distinction already
applied to Nerve Blocks/POCUS/ECG Library elsewhere in this package (rebuild from the
underlying facts, don't copy the source's specific expression) — apply it here too, and treat
it as resolved guidance rather than an open question.

### What changed from 2020 (know this before writing algorithm cards)
- **One unified Chain of Survival** now covers adult AND pediatric, in-hospital AND out-of-hospital arrest (previously separate chains)
- **IV access now preferred over IO** for medication delivery (higher sustained ROSC in recent studies) — IO remains acceptable when IV isn't feasible
- **Choking/FBAO sequence changed, confirmed with an important age distinction:** adults/children — alternating cycles of 5 back blows + 5 abdominal thrusts. **Infants — 5 back blows + 5 CHEST thrusts (not abdominal thrusts)**, using the heel of the hand. Continue until the object clears or the patient becomes unresponsive.
- **Infant chest compression technique, confirmed:** the two-finger technique is eliminated. Use the heel of one hand or the two-thumb encircling technique instead.
- **Explicit chest-compression-pause limit:** pauses must be <10 seconds — 2020 emphasized minimizing interruptions without setting a defined limit.
- **Rescuer switching:** switch compressors every 2–5 minutes, reassessing heart rate/rhythm at transitions.
- **Post-arrest temperature control:** maintain temperature control for at least 36 hours in adults who remain unresponsive to verbal commands (extends the prior TTM guidance with an explicit minimum duration).
- **Naloxone explicitly integrated into the BLS algorithm** at the point of suspected opioid-associated respiratory/cardiac arrest, alongside a broader push for public naloxone availability
- **Vasopressin removed** from the standard cardiac arrest drug sequence — pull it from code carts
- **DSED/vector-change defibrillation** for refractory VF/pVT remains "not established/not recommended" — same conclusion as 2020
- **Stroke algorithm thrombolytic, confirmed:** tenecteplase (TNK) received FDA approval in March 2025 and is increasingly used as an alternative to alteplase for acute ischemic stroke — build the card with both agents rather than alteplase alone, but confirm your institution's specific eligibility/dosing protocol since adoption and exact windows are still being operationalized site-by-site.
- **New Ethics of CPR and ECC chapter** — covers neonatal-to-geriatric ethical considerations; worth a Reference Library entry of its own if you want to be comprehensive, though it's lower priority than the clinical algorithm changes.
- Compression rate (100–120/min), depth, and the 30:2 single-rescuer ratio are unchanged

### Adult cardiac arrest algorithm (structure)
1. Continuous high-quality CPR: rate 100–120/min, depth ≥2 in (adult), full chest recoil, minimize interruptions to <10 sec
2. Rhythm check every 2 minutes
3. **Shockable (VF/pVT):** defibrillate → resume CPR immediately → epinephrine 1mg IV (preferred)/IO every 3–5 min → amiodarone 300mg first dose/150mg second dose OR lidocaine 1–1.5mg/kg for refractory VF/pVT after the 3rd shock
4. **Non-shockable (PEA/asystole):** continue CPR → epinephrine 1mg every 3–5 min → treat reversible causes
5. **Reversible causes (H's & T's):** Hypovolemia, Hypoxia, Hydrogen ion (acidosis), Hypo/hyperkalemia, Hypothermia; Tension pneumothorax, cardiac Tamponade, Toxins, Thrombosis (pulmonary), Thrombosis (coronary)
6. **Post-ROSC care** is framed as continuation of resuscitation, not an afterthought: targeted temperature management, avoid hypotension, ventilation/oxygenation targets, early cath lab evaluation if cardiac etiology suspected

### Bradycardia algorithm (structure)
Symptomatic bradycardia with poor perfusion → atropine 1mg (may repeat) → consider transcutaneous pacing → epinephrine or dopamine infusion if refractory to atropine/pacing

### Tachycardia algorithm (structure)
Determine stable vs. unstable first.
- **Unstable** → synchronized cardioversion
- **Stable, narrow, regular** → vagal maneuvers → adenosine
- **Stable, wide** → antiarrhythmics/expert consultation

### PALS-specific parameters
- Compression rate 100–120/min, depth 1/3 of AP chest diameter
- Compression-ventilation ratio: 15:2 (2 rescuers) or 30:2 (1 rescuer)
- Epinephrine 0.01mg/kg IV/IO (0.1mL/kg of 0.1mg/mL concentration) every 3–5 min, max 1mg/dose
- Defibrillation: 2J/kg first shock, 4J/kg subsequent shocks, up to adult max (~10J/kg)
- **Build note:** the 2025 refresh reportedly changed infant CPR hand positioning guidance — verify the exact change against the published guideline before writing this into a card; don't assume it's unchanged from 2020.

---

## Ventilator Management

**Initial settings (Volume-control AC, typical adult):**
- Tidal volume: 6–8mL/kg IBW (6mL/kg specifically for ARDS — lung-protective strategy)
- RR: 12–20/min
- PEEP: start at 5cmH2O, titrate per ARDSnet PEEP/FiO2 table
- FiO2: titrate to SpO2 88–95% (ARDS) or ≥92% (general)
- Plateau pressure goal: <30cmH2O
- Driving pressure goal: <15cmH2O

**Troubleshooting high peak pressure:** check plateau pressure to distinguish airway-resistance problem (peak high, plateau normal → obstruction/kink/mucus plug/bronchospasm) from a compliance problem (both peak and plateau elevated → pneumothorax, worsening ARDS, abdominal distension, patient-ventilator dyssynchrony).

**DOPE mnemonic** for the acutely decompensating vented patient: **D**isplacement of the tube, **O**bstruction, **P**neumothorax, **E**quipment failure — disconnect and bag-mask ventilate while troubleshooting.

**Weaning/extubation readiness:** spontaneous breathing trial + RSBI <105 (pulled from Calculators) + adequate oxygenation, hemodynamics, and mental status.

---

## ABG Interpretation

**Stepwise method:**
1. Check pH: acidemia <7.35, alkalemia >7.45
2. Check PaCO2: high = respiratory acidosis component, low = respiratory alkalosis component
3. Check HCO3: assess the metabolic component
4. Determine the primary disorder
5. Calculate expected compensation — **Winter's formula** (for metabolic acidosis): expected PaCO2 = (1.5 × HCO3) + 8 ± 2; if the actual PaCO2 falls outside this range, a mixed disorder is present
6. If metabolic acidosis is present, calculate the anion gap (pulled from Calculators)
7. If AG is elevated, calculate delta-delta to assess for a concurrent non-gap process

**A-a gradient** (assesses oxygenation independent of ventilation — useful for distinguishing hypoxemia causes):
`A-a gradient = P(A)O2 − P(a)O2`, where on room air at sea level `P(A)O2 ≈ 150 − (1.25 × PaCO2)`.
Expected normal upper limit ≈ `(Age / 4) + 4` mmHg — an A-a gradient wider than this points toward a diffusion/V-Q mismatch/shunt problem rather than pure hypoventilation.

**Oxyhemoglobin dissociation curve — bedside pearl worth building into the UI as a callout, not just a chart:**
The curve is sigmoidal, not linear. Around SpO2 88% (roughly a 10-point drop from normal), PaO2 is only ~50mmHg — meaning tissues are receiving about half the oxygen they would at a normal saturation. A small drop in SpO2 in the high-80s represents a much larger drop in delivered oxygen than the same point-drop would in the mid-90s. Pulse oximetry is good for trending, but if oxygenation is genuinely in question, an ABG's actual PaO2 is more informative than the saturation number alone.

---

## 12-Lead / IABP Monitoring

**ST-elevation diagnostic thresholds by lead, sex, and age — genuine gap filled this pass.** This is the actual numeric criterion behind "STEMI" and was missing entirely from the earlier draft; only the territory-localization table (below) existed. Per the Fourth Universal Definition of Myocardial Infarction (Thygesen et al., *Circulation* 2018), confirmed across multiple independent sources:

| Lead group | Threshold |
|---|---|
| All leads EXCEPT V2–V3 | ≥1mm (0.1mV) J-point elevation, any sex/age |
| V2–V3, men ≥40 years | ≥2mm (0.2mV) |
| V2–V3, men <40 years | ≥2.5mm (0.25mV) |
| V2–V3, women (any age) | ≥1.5mm (0.15mV) |
| Posterior leads (V7–V9) | ≥0.5mm |
| New LBBB with hemodynamic instability or new heart failure | Treat as STEMI-equivalent (discuss urgent PCI/fibrinolytics) regardless of ST measurements |
| Pre-existing LBBB or paced rhythm | Use Modified Sgarbossa criteria instead (full point criteria in `Calculator_Logic_Build_Spec.md`) |

**Why V2–V3 get different thresholds specifically:** normal J-point elevation is physiologically higher in V2–V3 than other leads, and higher in men than women — so a flat ≥1mm rule across all leads would systematically under-call STEMI in young men (needs a higher bar to avoid false positives from normal variant elevation) and over-threshold women and older patients relative to what's actually pathologic for them. This isn't an arbitrary rule — it's correcting for a real physiologic baseline difference, and building it as a single flat number for all patients would be a genuine accuracy loss, not just a simplification.

**Required in ALL cases regardless of lead/sex/age:** the ST elevation must be present in **two contiguous leads** to meet criteria — a single lead alone doesn't qualify.

**ECG lead placement:** standard 10-electrode system. **STEMI localization by territory:**
- Anterior: V1–V4 (LAD)
- Inferior: II, III, aVF (RCA or LCx) — get right-sided leads (especially V4R) to assess RV involvement
- Lateral: I, aVL, V5–V6 (LCx)
- Posterior: reciprocal ST depression in V1–V3 ± confirmatory posterior leads V7–V9 (≥0.5mm threshold, per the table above)

**IABP timing:** inflation at the dicrotic notch (early diastole) to augment coronary perfusion; deflation just before systole to reduce afterload. Early/late inflation and early/late deflation each produce a characteristic waveform abnormality — build a troubleshooting reference table pairing waveform appearance to the specific timing error.

---

## ECG Library — key patterns to include

*(Diagnostic criteria confirmed this pass for the three STEMI-equivalent patterns and Brugada — significantly more specific than the earlier one-line descriptions.)*

**STEMI equivalents:**
- **De Winter pattern:** upsloping ST-segment depression at the J-point with tall, symmetrical T-waves across the precordial leads (V1–V6) — signifies proximal LAD occlusion. Considered a STEMI-equivalent requiring immediate reperfusion, not just a "watch closely" finding. Occurs in ~2.5% of anterior MIs.
- **Wellens syndrome:** T-wave changes specifically in V2–V3, occurring during PAIN-FREE intervals (this timing detail matters — it's not seen during active chest pain), indicating critical proximal LAD stenosis after a recent ischemic episode. Two types: **Type A** — biphasic T waves; **Type B** — deep, symmetric T-wave inversion (more common, ~75% of cases). **Pseudo-normalization of the T waves is the warning sign of re-occlusion** — if inverted T waves flip back to upright with returning chest pain, that's an emergency, not reassurance.
- **Modified Sgarbossa criteria** (LBBB/paced rhythm) — full point criteria already in `Calculator_Logic_Build_Spec.md`, cross-link rather than duplicate here.

**Brugada pattern — corrected, only one type is actually diagnostic:**
- **Type 1** (the only diagnostic pattern): coved ST-segment elevation ≥2mm in V1–V3 (not just V1–V2 as the earlier draft said), followed by a negative T-wave, with little/no isoelectric separation between the ST segment and T wave.
- **Type 2** (saddleback morphology, J-wave ≥2mm, gradually descending ST staying ≥1mm above baseline): no longer considered diagnostic on its own — warrants further testing (e.g., sodium channel blocker challenge), not an automatic Brugada diagnosis.
- **Type 3**: <1mm ST elevation, either coved or saddleback morphology — least specific.
- Build the module to clearly flag that only Type 1 supports the diagnosis; presenting Type 2/3 with equal diagnostic weight would be a real accuracy problem, not just an oversimplification.

**Other patterns:**
- Hyperkalemia progression: peaked T waves → PR prolongation → QRS widening → sine wave pattern
- WPW: delta wave, short PR interval
- Torsades de pointes
- Digoxin effect (scooped ST) vs. digoxin toxicity (arrhythmias, especially with hypokalemia)

**Build note:** create your own annotated tracings rather than sourcing ECGRef's images directly.

---

## Anticoagulation / Reversal Reference

**Urgent correction — this changes what the app should recommend, not just a citation update:** andexanet alfa was **voluntarily withdrawn from the US market on December 22, 2025**, due to thromboembolic event safety concerns identified after approval. It remains available in the EU, Canada, and other countries — but **the earlier draft's US-facing recommendation of andexanet alfa as the primary factor Xa inhibitor reversal agent is now wrong for this app's likely user base.** 4-factor PCC (off-label for this indication, but recommended in current guidelines) is now effectively the primary practical option in the US, not the fallback.

| Agent | Reversal |
|---|---|
| Warfarin/VKA | Vitamin K 10mg IV, infused over 30 minutes (the one dose/route that should be used for emergent reversal) + 4-factor PCC — dose by INR and bleeding severity. PCC restores vitamin K-dependent factors even when post-treatment INR remains >1.5; INR is still used as the routine monitoring surrogate but can underestimate factor restoration |
| Dabigatran | Idarucizumab 5g IV, split into two 2.5g infusions given 5–10 minutes apart. A repeat 5g dose is reasonable if bleeding persists with lab evidence of ongoing dabigatran effect, or before a second invasive procedure |
| Factor Xa inhibitors (apixaban, rivaroxaban) | **Corrected for current US availability:** 4-factor PCC is now the primary practical option in the US following andexanet alfa's December 2025 market withdrawal (see note above). If your build targets a non-US market where andexanet remains available, that's a legitimate build-time branch to add, not a universal default |
| Unfractionated heparin | Protamine sulfate, ~1mg per 100 units of heparin given in the preceding 2–3 hours |
| LMWH | Protamine only partially effective |

Include a periprocedural bridging framework (weighing thrombotic risk of the underlying condition against bleeding risk of the planned procedure) — pulls conceptually from Caprini/Padua/IMPROVE in Calculators rather than duplicating that logic here.

---

## Lab Interpretation

- CBC key patterns (leukocytosis with left shift, cytopenias, MCV-based anemia workup)
- BMP/CMP interpretation and critical-value triggers
- Microbiology quick-reference: gram stain morphology → likely organism → empiric coverage class (not specific drugs/doses — see Empiric Antibiotic Guide caveat below)
- Electrolyte replacement protocols: potassium, magnesium, phosphate — replacement dosing and infusion-rate limits

---

## Empiric Antibiotic Guide

Organize by clinical syndrome, not by drug: CAP, HAP/VAP, UTI/pyelonephritis, intra-abdominal infection, skin/soft-tissue infection (cellulitis vs. purulent vs. necrotizing — cross-link LRINEC from Calculators), meningitis, sepsis of unknown source.

**Critical build note:** actual drug and dose selection MUST reflect your institution's current antibiogram and IDSA guideline updates — antibiotic resistance patterns are regionally variable and change over time. Don't hardcode specific drug/dose recommendations as permanent content; structure this module so the syndrome categories are stable but the drug recommendations are the part you're most likely to need to revisit and update.

**This isn't a theoretical caution — it's live right now, specifically for CAP, and it's now resolved with a decision:** IDSA declined to endorse a 2025 ATS guideline update on community-acquired pneumonia, publishing a position statement disagreeing with parts of it — specifically around the timing/threshold for empiric antibiotics in non-severe CAP and viral-coinfection assumptions. Both societies agree empiric antibiotics for **severe** CAP are settled (delay causes harm, treat promptly) — the disagreement is confined to **non-severe** CAP timing. Rather than encode either 2025 position, the app defers explicitly: **"The decision to initiate empiric antibiotics in non-severe CAP should be made at the local level, per institutional protocol."** Build this as literal UI copy on the non-severe CAP card, not just an internal note — the app states the society-level disagreement exists and points the user to local protocol rather than adjudicating it. Severe CAP content isn't affected by this and can be populated normally.

---

## Vaccine Schedules

Source: AAP-published schedule (see currency flag at top of this file), not CDC.gov directly.
Build the module as an age-based lookup (birth–18 for the child/adolescent schedule, 19+ for
the adult schedule), populated from AAP's current published tables. Structure the data model
so the source document can be swapped/refreshed without a schema change — the sourcing
decision here is stable, but the underlying document isn't guaranteed to be.

---

## Landmark Trials Library — starter list

| Trial | One-Line Takeaway |
|---|---|
| ARISE / ProCESS / ProMISe | Protocolized early goal-directed therapy showed no mortality benefit over usual sepsis care |
| ARISE FLUIDS | *(Already integrated into your sepsis resuscitation cards per Critical Vector — cross-reference rather than duplicate)* |
| LACTATE (Jansen 2010) | Lactate-guided resuscitation reduced mortality vs. standard care in early septic shock — established lactate clearance as a resuscitation target |
| SEPSISPAM (2014) | Higher MAP target (80–85) vs. standard (65–70) showed no overall mortality benefit in septic shock, though possibly beneficial in patients with chronic hypertension |
| ANDROMEDA-SHOCK (2019) | Capillary refill time-targeted resuscitation trended toward lower mortality vs. lactate-targeted resuscitation (not statistically significant in the original trial) — raised capillary refill as a viable, faster bedside alternative to serial lactates |
| CLASSIC (2022) | Restrictive IV fluid strategy was safe/non-inferior to standard fluid therapy in septic shock in the ICU |
| ANDROMEDA-SHOCK 2 (JAMA, published Oct 29, 2025) | 1,501 patients across 86 ICUs/19 countries randomized to capillary-refill-time-targeted personalized hemodynamic resuscitation (hourly CRT checks driving a two-tier algorithm — pulse pressure/fluids/norepinephrine first, then echo-guided therapy if CRT didn't normalize) vs. usual care. On the primary hierarchical composite outcome (28-day mortality, duration of vital support, length of stay), the CRT-targeted group won more pairwise comparisons than usual care (win ratio 1.15, 94% CI 1.02–1.33, P=.04) and had more vital-support-free days (16.5 vs. 15.4). **28-day mortality alone was not significantly different between groups** — the benefit shows up in the composite/support-free-days outcome, not a mortality signal. Builds on the original ANDROMEDA-SHOCK finding that CRT-targeted resuscitation looked at least as good as lactate-targeted, now in a much larger, more rigorous trial. |
| TTM2 | Targeted temperature management at 33°C showed no benefit over normothermia + fever avoidance post-arrest |
| CRASH-2 | Early TXA reduced mortality in trauma patients with significant hemorrhage |
| PROPPR | 1:1:1 vs. 1:1:2 plasma:platelet:RBC transfusion ratio in massive transfusion — no significant mortality difference, but 1:1:1 achieved hemostasis faster |
| FEAST | Fluid boluses increased mortality in febrile children with impaired perfusion in a resource-limited setting — reshaped pediatric fluid resuscitation thinking |
| SAFE | Albumin vs. saline for fluid resuscitation in ICU patients — no overall mortality difference |
| NICE-SUGAR | Intensive glucose control (80–108) increased mortality vs. conventional control (≤180) in critically ill patients |
| VASST | Vasopressin vs. norepinephrine in septic shock — no overall mortality difference |
| TRISS | Restrictive (Hgb 7) vs. liberal (Hgb 9) transfusion threshold in septic shock — no mortality difference |

**Source for the 2025 addition:** Hernandez G, Hunsicker O, de Backer D, et al. Twenty-five years of septic shock hemodynamic resuscitation trials: a conceptual perspective. *Crit Care.* 2026;30:400. This is a perspective/review piece mapping the full EGDT→ANDROMEDA-SHOCK 2 timeline and the underlying conceptual shift (global oxygen delivery → metabolic resuscitation → pressure targets → CRT as a reperfusion signal → avoiding fluid excess → personalized, phenotype-driven resuscitation) — worth reading in full before writing the module's framing narrative, since it's the connective tissue between all these trials, not just one more entry in the table.

**Build note:** cross-check against your existing Critical Vector content before populating this module — some of these may already be written up there, and the goal is one source of truth, not a duplicate.
