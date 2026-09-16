# Section 3: Drug & Dosing Cards — Weight-Based Resuscitation Dosing & Equipment Spec

**This fills the one real content gap left in the Drug & Dosing Cards tab.** Everything else
in that tab is either already built (AnesCalc's 55 drug cards) or already has its formulas in
`Calculator_Logic_Build_Spec.md` (the 8 moved dosing-math calculators). This file is the actual
data for "Peds Resuscitation Meds & Equipment by Weight," "Peds Dosing (RSI/DKA/Resuscitation),"
"Pedi Tape Dosing," and "Peds Dose Calculator" — which the spreadsheet only had as source-app
names until now.

**Design decision:** build this as **per-kg formulas computed live from the patient's actual
weight**, not fixed weight-bands like a printed Broselow tape. A formula gives an exact dose for
an exact weight; a band gives an approximate dose for a range of weights, which is precisely the
kind of thing that becomes a rounding/medication-error risk under pressure. The worked table below
is a **precomputed convenience reference** at common weight points — useful for sanity-checking
or a quick-glance card — but the app itself should calculate from the formula against the entered
weight, not look up a band.

---

## Weight Estimation (when actual weight is unavailable)

Use actual measured weight whenever possible. If unavailable, standard age-based estimation
formulas (APLS):
- **0–12 months:** Weight (kg) = (0.5 × age in months) + 4
- **1–5 years:** Weight (kg) = (2 × age in years) + 8
- **6–12 years:** Weight (kg) = (3 × age in years) + 7

These are estimates — always prefer a measured or reported actual weight when it's available.

---

## CPR / Cardiac Arrest Medications (per-kg formulas)

| Medication | Dose | Notes |
|---|---|---|
| Epinephrine (cardiac arrest) | 0.01 mg/kg IV/IO (= 0.1 mL/kg of 1:10,000 concentration) | Max single dose 1mg; repeat every 3–5 min |
| Atropine (symptomatic bradycardia from vagal tone/AV block) | 0.02 mg/kg IV/IO | Minimum single dose 0.1mg (avoids paradoxical bradycardia at very low doses); max single dose 0.5mg (child) / 1mg (adolescent). **Not routine for PEA/asystole** — reserved for suspected vagal/primary AV block bradycardia |
| Amiodarone (VF/pulseless VT) | 5 mg/kg IV/IO bolus (max 300mg first dose) | *Corrected:* may repeat up to 3 total doses, but subsequent doses are capped at 150mg each, not another 300mg — confirmed against the official 2025 AHA PALS cardiac arrest algorithm PDF |
| Lidocaine (alternative to amiodarone) | 1 mg/kg IV/IO load | |
| Adenosine (stable SVT) | 0.1 mg/kg first dose (max 6mg); 0.2 mg/kg second dose (max 12mg) | Rapid IV push, immediately followed by saline flush |
| Defibrillation | 2 J/kg first shock; 4 J/kg subsequent shocks | Up to adult max dose (~10 J/kg ceiling) |
| Synchronized cardioversion | 0.5–1 J/kg first attempt; 2 J/kg subsequent | |
| Naloxone (opioid reversal) | 0.1 mg/kg IV/IM/IN | Cap per dose varies by formulation/local protocol, commonly up to 2mg |
| Dextrose (hypoglycemia) | D10: 5–10 mL/kg IV; D25: 2–4 mL/kg IV | Avoid D50 in young children — too hypertonic, risk of extravasation injury |
| Calcium chloride (hyperkalemia, hypocalcemia, CCB toxicity) | 20 mg/kg IV, slow push (10% solution) | |
| Sodium bicarbonate (severe acidosis, hyperkalemia, TCA overdose) | 1 mEq/kg IV | |

**Reversible causes (confirmed from the official 2025 AHA PALS cardiac arrest algorithm) — note this list differs slightly from the adult H's & T's in `Reference_Library_Content_Spec.md`:** Hypovolemia, Hypoxia, Hydrogen ion (acidosis), **Hypoglycemia**, Hypo-/hyperkalemia, Hypothermia, Tension pneumothorax, cardiac Tamponade, Toxins, Thrombosis (pulmonary), Thrombosis (coronary). **Hypoglycemia is called out as its own item in the pediatric algorithm** — it isn't broken out separately in the standard adult H's/T's mnemonic, so don't copy the adult list over for the peds version without this addition.

**New in the 2025 refresh — physiology-directed resuscitation target:** for the first time, PALS guidelines specify an objective coronary-perfusion target during CPR when invasive arterial monitoring is available: **diastolic blood pressure ≥25mmHg in infants, ≥30mmHg in older children.** This is a genuinely new element (not in 2020 guidance) — worth including as an advanced/optional field in the CPR module for centers with arterial line capability, not a universal requirement.

### Quick-reference table at common weight points *(precomputed from the formulas above — not a separate data source)*

| Weight (kg) | Epinephrine (mg / mL of 1:10,000) | Atropine (mg) | Amiodarone (mg) | Defib J (1st / subsequent) |
|---|---|---|---|---|
| 3 | 0.03 / 0.3mL | 0.1 | 15 | 6 / 12 |
| 5 | 0.05 / 0.5mL | 0.1 | 25 | 10 / 20 |
| 10 | 0.1 / 1.0mL | 0.2 | 50 | 20 / 40 |
| 15 | 0.15 / 1.5mL | 0.3 | 75 | 30 / 60 |
| 20 | 0.2 / 2.0mL | 0.4 | 100 | 40 / 80 |
| 25 | 0.25 / 2.5mL | 0.5 | 125 | 50 / 100 |
| 30 | 0.3 / 3.0mL | 0.5 (capped) | 150 | 60 / 120 |
| 40 | 0.4 / 4.0mL | 0.5 (capped) | 200 | 80 / 160 |
| 50 | 0.5 / 5.0mL | 0.5 (capped) | 250 | 100 / 200 |
| 60 | 0.6 / 6.0mL | 0.5 (capped) | 300 | 120 / 240 |
| 70 | 0.7 / 7.0mL | 0.5 (capped) | 350 | 140 / 280 |

---

## Anti-Epileptic / Status Epilepticus Medications (per-kg formulas)

*(This section was cross-checked against two published institutional pathways — Stanford and Riley Children's — and both agreed on the figures below.)*

| Medication | Dose | Notes |
|---|---|---|
| Lorazepam | 0.1 mg/kg IV | Max 4mg/dose; may repeat once in 5 minutes if seizure persists |
| Midazolam | 0.2 mg/kg IM/IN (max 10mg) OR 0.1–0.2 mg/kg IV | IM/IN route when no IV access yet |
| Diazepam (rectal) | **Corrected — age-stratified, not a flat range:** 2–5y: 0.5 mg/kg · 6–11y: 0.3 mg/kg · ≥12y: 0.2 mg/kg (max 20mg) | Rectal route when no IV access; round dose up to nearest 2.5mg |
| Fosphenytoin (2nd line) | 20 mg PE/kg IV (max 1500mg PE) | "PE" = phenytoin equivalents; may repeat 10mg PE/kg (max 750mg), infuse over 10 min (max rate 150mg PE/min) |
| Levetiracetam (2nd line, increasingly preferred alternative) | 40–60 mg/kg IV (max 4500mg) | Infuse over 5 minutes |
| **Phenobarbital (2nd line, neonates)** *(added — missing from earlier draft)* | 20 mg/kg IV | The preferred 2nd-line agent specifically in neonates (≤28 days); may repeat 20mg/kg once before adding a second benzodiazepine dose. Infuse over 20 minutes. This was a genuine gap — the earlier draft went straight from benzodiazepines to fosphenytoin/levetiracetam/valproic acid without a neonatal-specific option |
| Valproic acid (2nd line) | 40 mg/kg IV | Comparable efficacy to levetiracetam/fosphenytoin per recent RCT evidence; less commonly first choice now |

---

## Peds RSI Medications (per-kg formulas — cross-referenced from Peds Module spec, consolidated here as the single source of dosing truth)

| Medication | Dose | Notes |
|---|---|---|
| Etomidate | **Corrected:** 0.2–0.4 mg/kg IV (max 20mg), not a flat 0.3mg/kg | Hemodynamically neutral; **avoid in septic shock specifically** — adrenal suppression concern makes ketamine the preferred agent in that scenario, not just a general preference |
| Ketamine | 1–2 mg/kg IV | Preferred in shock/reactive airway (bronchodilator, hemodynamically supportive); **specifically preferred over etomidate in septic shock** |
| Propofol | 1–2 mg/kg IV | Use cautiously in hemodynamic instability |
| Rocuronium | 1–1.2 mg/kg IV | |
| Succinylcholine | 1–2 mg/kg IV (max 150mg) | Contraindicated if hyperkalemia risk, myopathy, or malignant hyperthermia history |
| Atropine pretreatment | **Revised recommendation, not just a dosing correction:** current evidence does NOT support routine atropine premedication before RSI in children generally, or specifically tied to succinylcholine use — that older blanket practice has fallen out of favor. The narrower, currently-supported indication is **children younger than 1 year undergoing direct laryngoscopy**, independent of which paralytic is used: 0.02 mg/kg IV | This is a genuine practice shift from the earlier draft's framing ("infants receiving succinylcholine") — the trigger is age and laryngoscopy, not succinylcholine specifically |

---

## Fluid Dosing (per-kg formulas)

| Purpose | Formula | Notes |
|---|---|---|
| Resuscitation bolus | 10–20 mL/kg isotonic fluid (NS or LR) | Reassess after each bolus |
| Maintenance fluids (Holliday-Segar formula) | 4 mL/kg/hr for the first 10kg + 2 mL/kg/hr for the next 10kg + 1 mL/kg/hr for each kg over 20kg | Standard pediatric maintenance fluid calculation — build as one reusable formula, not a lookup table |
| DKA fluid resuscitation | 10–20 mL/kg isotonic bolus over 1–2h if in shock | See `Peds_Module_Content_Spec.md` — cautious rate given cerebral edema risk |
| Burn resuscitation | 4 mL × %TBSA × weight (kg) over 24h | Already specified in `Calculator_Logic_Build_Spec.md` (Parkland Formula) — don't duplicate, cross-link |

---

## Dosing Basis in Obese Children *(new — from ERC 2025 Paediatric Life Support guidelines)*

Most resuscitation drugs are hydrophilic and don't distribute meaningfully into fatty
tissue. **Dose by ideal body weight (IBW), not actual body weight, in obese children** —
using actual weight in a high-BMI child risks overdosing and can exceed adult maximum doses
despite the patient being pediatric. Build this as an explicit check in the weight-entry
flow: if entered weight is significantly above the age-expected IBW, flag it and default
dosing calculations to IBW rather than actual weight, with an override available for drugs
where actual weight dosing is specifically indicated (this is a drug-by-drug distinction,
not a blanket rule — flag it per-drug rather than applying one global switch).

---

## Equipment Sizing by Age/Weight

| Equipment | Sizing Rule |
|---|---|
| ETT size (uncuffed) | (Age/4) + 4 |
| ETT size (cuffed) | (Age/4) + 3.5 |
| ETT insertion depth (cm at lip) | ETT size × 3 |
| Laryngoscope blade | Miller (straight) generally preferred in infants (sizes 0–1); Macintosh (curved) sizes 1–2 for older children — build as an age-indexed table alongside ETT size |
| LMA size | Size 1: <5kg · Size 1.5: 5–10kg · Size 2: 10–20kg · Size 2.5: 20–30kg · Size 3: 30–50kg (standard manufacturer sizing, not proprietary) |
| IV catheter gauge | 24g: neonate/infant · 22g: toddler/young child · 20g: older child/adolescent (general guidance, not a strict rule) |
| Defibrillation pads | **Confirmed general threshold:** pediatric pads for age <8 years OR weight <25kg (55lbs); adult pads for age ≥8 years OR weight ≥25kg — this is the consensus figure across AHA-aligned sources and matches what major manufacturers (e.g., ZOLL) build into their pediatric dose-attenuator cutoffs. Still device-specific enough to confirm against your exact defibrillator model, but this is a solid default rather than a placeholder. |
| BP cuff | Width ≈40% of arm circumference — build an age-based sizing chart (neonate/infant/child/adult) rather than a single rule |

---

## Build notes

- **This is the data the "Pedi Tape / Peds Dose Calculator" and "Peds Resuscitation Meds & Equipment by Weight" rows in the spreadsheet were pointing at.** Cross-reference PedsGuide and First 5 Minutes' own published dosing before finalizing — the goal is one validated dataset, not a re-derivation that quietly drifts from what those two apps actually say. Where they agree with the standard formulas above, you're done; where they disagree, that's a discrepancy worth resolving deliberately rather than picking one silently.
- **Defibrillator pad cutoffs and LMA sizing** are manufacturer/device-specific in practice even though the numbers above are the common standard — note this as a per-device verification step in the actual UI copy, not just in this spec.
- **Nothing here overlaps with AnesCalc.** AnesCalc's 55 drug cards are adult anesthesia dosing; this file is pediatric resuscitation/RSI/status epilepticus dosing plus general fluid and equipment formulas. Different patient population, different clinical context — correctly kept as separate content per the original section design.
