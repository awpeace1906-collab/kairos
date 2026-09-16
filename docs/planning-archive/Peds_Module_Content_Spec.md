# Section 5: Peds Module — Content Build Spec

**Currency note:** the PALS-specific content below reflects the October 2025 AHA guidelines
refresh — see `Reference_Library_Content_Spec.md` for the full list of what changed from
2020. Don't build this section from older PALS material without cross-checking.

---

## Peds Diagnostic Scoring

**Pediatric appendicitis — three tools, three different jobs.** Full formulas for all three
live in `Calculator_Logic_Build_Spec.md` (Alvarado is under the adult GI/Renal/Metabolic
section since it's not pediatric-specific; PAS and pARC are documented there but belong here
in the app's navigation). Don't present these as interchangeable — each is suited to a
different setting:

| Tool | Best suited for | Key caveat |
|---|---|---|
| Alvarado Score (adult-derived) | Primary care/outpatient, low-tech settings with limited labs | Heavily weighted toward WBC, which is nonspecific — can overdiagnose in patients with non-appendiceal inflammatory conditions |
| PAS (Pediatric Appendicitis Score) | Fast ED confirmation when clinical suspicion is already high | A low score does NOT reliably rule appendicitis out — don't let it provide false reassurance; cough/hop/percussion findings are unreliable in young or uncooperative kids |
| pARC (Pediatric Appendicitis Risk Calculator) | Most individualized/accurate risk estimate, best for guiding the actual imaging decision in kids ≥5 | Requires ANC as an input; not designed for or validated in children <5, where appendicitis is rare and presents atypically |

**Source:** RebelEM (Dr. Eric Steinberg, St. Joseph's EM, Patterson NJ) — "Pediatric Appendicitis: Three Scores, One Diagnosis," rebelem.com/peds-appy-scores/.

---

Structurally the same cardiac arrest / bradycardia / tachycardia algorithms as adult ACLS
(see Reference Library spec), with pediatric-specific parameters:

- Compression rate 100–120/min, depth 1/3 of AP chest diameter
- Compression-ventilation ratio: 15:2 (2 rescuers) or 30:2 (1 rescuer)
- Epinephrine 0.01mg/kg IV/IO (0.1mL/kg of 0.1mg/mL concentration) every 3–5 min, max single dose 1mg
- Defibrillation: 2J/kg first shock, 4J/kg subsequent shocks, up to adult max dose
- Bradycardia with poor perfusion despite oxygenation/ventilation → chest compressions if HR <60 → epinephrine → atropine specifically for suspected increased vagal tone or primary AV block
- Tachycardia: adenosine for stable narrow-complex SVT — 0.1mg/kg first dose (max 6mg), 0.2mg/kg second dose (max 12mg); synchronized cardioversion for unstable — 0.5–1J/kg first attempt, 2J/kg subsequent

**Confirmed (2025 refresh):** the two-finger technique for infant chest compressions is eliminated. Use the heel of one hand or the two-thumb encircling technique instead. For infant choking/FBAO specifically, the sequence is 5 back blows + 5 CHEST thrusts (not abdominal thrusts — infants get chest thrusts, distinct from the back-blows-plus-abdominal-thrusts sequence used in children/adults).

---

## Peds RSI

**Full dosing table (etomidate, ketamine, propofol, rocuronium, succinylcholine, atropine pretreatment) now lives in `Drug_Dosing_Peds_Weight_Based_Spec.md`** — this section previously duplicated those numbers with a stale etomidate dose (flat 0.3mg/kg) and an outdated atropine-pretreatment framing tied to succinylcholine use specifically. Both have since been corrected in the single source-of-truth file; don't re-copy the old numbers here. Two clinical decision points worth keeping in this module even though the doses live elsewhere:
- **Ketamine over etomidate specifically in septic shock** — adrenal suppression risk with etomidate, not just a general preference
- **Atropine pretreatment is now narrowly indicated** (children <1 year, direct laryngoscopy) rather than a blanket pre-RSI practice

**Equipment sizing by age:**
- ETT size (uncuffed): age/4 + 4
- ETT size (cuffed): age/4 + 3.5
- Laryngoscope blade size scales with age — build as an age-indexed lookup table alongside ETT size, not a separate formula

**Cross-link:** actual dosing math and weight-based calculation should live in Drug & Dosing Cards — this module documents the clinical decision logic (which agent, when), not the computed dose.

---

## BRUE Pathway

*(Confirmed this pass — matches the AAP 2016 clinical practice guideline exactly, still the current standard as of this check; no superseding update found.)*

**Definition:** Brief Resolved Unexplained Event — an episode in an infant <1 year old, lasting <1 minute, involving ≥1 of: cyanosis or pallor; absent, irregular, or decreased breathing; marked change in tone (hyper- or hypotonia); altered level of responsiveness — with no explanation found after history and physical exam.

**Lower-risk criteria (ALL must be met for lower-risk classification):**
- Age >60 days
- Born ≥32 weeks gestation and corrected gestational age ≥45 weeks
- No CPR required by a trained medical provider
- Event duration <1 minute
- First such event (no prior BRUE)
- No concerning history or exam findings

**Disposition:** lower-risk infants may be observed briefly, parents educated on BRUE and CPR, without extensive testing or admission. Higher-risk infants (failing any lower-risk criterion) warrant admission and workup guided by the specific concerning features present.

**Gap filled this pass:** the original 2016 AAP guideline explicitly does NOT provide recommendations for higher-risk infants — it only covers the lower-risk pathway. A 2019 AAP follow-up paper specifically fills that gap: Brooks AF, et al. "A Framework for Evaluation of the Higher-Risk Infant After a Brief Resolved Unexplained Event." *Pediatrics.* 2019;144(2):e20184101. If you're building out the higher-risk side of this module beyond "admission and workup," pull that paper's tiered framework rather than improvising one — the earlier draft's "workup guided by specific concerning features" was vague because there wasn't a source behind it yet.

---

## Peds DKA Management

**Fluid resuscitation:** 10–20mL/kg isotonic fluid bolus over 1–2 hours if in shock; be cautious with rate and volume given cerebral edema risk in pediatric DKA — avoid aggressive rapid correction.

**Insulin:** continuous infusion 0.05–0.1 units/kg/hr, started AFTER initial fluid bolus (no insulin bolus in pediatric DKA — bolus dosing is specifically avoided due to cerebral edema risk, unlike some adult protocols). **Confirmed age-specific refinement:** in children younger than 5 years, use the lower end of the range (0.05 units/kg/hr) as a consensus recommendation to reduce the risk of subsequent hypoglycemia.

**Potassium — thresholds now confirmed (BSPED guideline, ISPAD-aligned):**
- If K+ is LOW on admission (<3.0 mmol/L): defer starting insulin until K+ rises above 3.0 mmol/L — hypokalemia takes priority over acidosis correction here.
- If K+ is ABOVE the upper limit of normal (commonly cited as 5.5 mmol/L) at presentation: do NOT add potassium to IV fluids until the patient has passed urine, or until K+ has fallen to within the normal range.
- Between these thresholds (K+ within normal range): add potassium to maintenance fluids per standard protocol once urine output is confirmed.
- **Source:** BSPED (British Society for Paediatric Endocrinology and Diabetes) DKA Guideline, aligned with ISPAD Clinical Practice Consensus Guidelines 2022.

**Cerebral edema monitoring:** watch for headache, altered mental status, bradycardia, hypertension (Cushing's triad pattern) — if suspected, treat emergently with mannitol or hypertonic saline; this is a time-critical complication specific to pediatric DKA management.

---

## Peds Glasgow Coma Scoring (modified for preverbal children)

- **Eye response:** same 4-point scale as adult GCS
- **Verbal response (modified):** 5 coos/babbles appropriately / 4 irritable cry / 3 cries to pain / 2 moans to pain / 1 none
- **Motor response (modified):** 6 spontaneous movement / 5 withdraws to touch / 4 withdraws to pain / 3 abnormal flexion / 2 abnormal extension / 1 none

Total range 3–15, same as adult scale — the modification is in what each verbal/motor level looks like behaviorally in a preverbal child, not in the point range itself.

---

## Peds Drip Calculators

Standard weight-based infusion-rate formula (generic — applies to any weight-based drip):
`Infusion rate (mL/hr) = [Dose (mcg/kg/min) × Weight (kg) × 60] / Concentration (mcg/mL)`

Apply this generic formula to: dopamine, dobutamine, epinephrine/norepinephrine infusions, fentanyl/midazolam sedation infusions. Build this as ONE reusable calculator with a drug-concentration lookup, not six separate calculators with the same formula.

---

## Pedi Tape / Peds Dose Calculator

**Concept:** a length-based (or weight-based) color-zone system where each zone maps to a pre-calculated set of resuscitation drug doses and equipment sizes, so a provider can estimate a critically ill child's weight from length alone and immediately reference doses without doing math under pressure.

**Build note — licensing:** the specific color-zone scheme, exact weight bands, and tape format from the commercial Broselow system are a trademarked, proprietary product. **Do not replicate Broselow's specific color/weight-band scheme.** Build your own equivalent length-to-weight-zone lookup with your own zone boundaries and labeling, populated with the same underlying (public/standard) drug doses and equipment sizes you're building elsewhere in this app. The underlying clinical dosing data is generic medical knowledge; the specific commercial tape design is not.

---

## Cross-reference: PECARN Pediatric Head Injury Algorithm

Full spec lives in `Calculator_Logic_Build_Spec.md` under the Trauma section (it's the one
calculator that moved from the Calculators tab into this module for navigation purposes,
but its logic is documented once, not duplicated here).

---

## Open items before build
- ~~Verify the 2025 PALS infant CPR hand-position change~~ — **Resolved.** Two-finger technique eliminated; use heel of one hand or two-thumb encircling technique. Infant choking = 5 back blows + 5 chest thrusts (not abdominal thrusts).
- Confirm pediatric-specific potassium replacement thresholds for DKA (don't assume they mirror adult protocols exactly).
- Design an original length/weight-zone system for the Pedi Tape equivalent — flagged as a licensing issue, not just a content gap.
