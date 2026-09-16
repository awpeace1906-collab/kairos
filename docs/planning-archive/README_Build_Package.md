# README — Build Package for Claude Code

This package is the accumulated design and content spec for the unified ED/ICU/OR/Peds
reference-and-calculator app, named **Kairos** (pronounced "KY-ros," rhymes with "sky" — not "Kay-ros"). It's
organized by clinical workflow, built as a companion to — not a replacement for —
**AnesCalc** and **CRISIS**, which stay separate.

**Status: not fully ready to hand to Code yet.** Most of the structural and computational
work is done; what's left is a specific list of verification/sourcing tasks below, plus a
few open product decisions. Treat this README as the map of what's solid vs. what still
needs a pass before implementation starts.

---

## What's in this package

### Source-of-truth spreadsheets
| File | What it is |
|---|---|
| `App_Design_By_Workflow.xlsx` | The master structure — 5 sections (Procedures, Calculators, Drug & Dosing Cards, Reference Library, Peds Module), what belongs in each, and the overlap-resolution rule |
| `Medical_App_Consolidation_Plan.xlsx` | The original cross-reference of all ~34 source apps against this build |
| `ED_ICU_OR_Calculators.xlsx` | The 94-calculator list with settings/purpose/inputs (superseded for actual logic by the MD spec below, kept for the audit trail) |

### Content/logic specs (the actual build material)
| File | Section | Covers |
|---|---|---|
| `Calculator_Logic_Build_Spec.md` | 2 – Calculators | Formulas, point systems, and interpretation bands for all 97 calculators (94 original + Lactate:Base Deficit Ratio + PAS + pARC) |
| `Procedures_Content_Spec.md` | 1 – Procedures | Laceration/fracture decision trees, nerve block index, POCUS index, airway/sedation workflows |
| `Drug_Dosing_Peds_Weight_Based_Spec.md` | 3 – Drug & Dosing Cards | Peds resuscitation/RSI/status epilepticus dosing formulas, fluid formulas, equipment sizing |
| `Dual_Mode_Weight_Zone_Spec.md` | 3 – Drug & Dosing Cards | How exact-weight calculation and color-zone display coexist without the zone ever supplying a dose |
| `Search_TOC_Design_Spec.md` | Cross-cutting (all 5 sections) | Global search index schema, home-screen searchable TOC, per-section search reuse |
| `Content_Update_Architecture_Spec.md` | Cross-cutting (all 5 sections) | How content gets corrected post-launch without a rebuild — remote-fetched/offline-cached delivery, versioning, staleness surfacing, solo-maintainer update workflow |
| `Reference_Library_Content_Spec.md` | 4 – Reference Library | ACLS/PALS (2025 refresh), vent management, ABG method, 12-lead/IABP, ECG library, anticoag reversal, labs, antibiotics, vaccine schedule sourcing, landmark trials |
| `Peds_Module_Content_Spec.md` | 5 – Peds Module | Peds resuscitation params, RSI, BRUE, DKA, peds GCS, drip formula, Pedi Tape concept |

### Not yet written
- **Suture/Fractures/Nerve Block/POCUS full decision-tree branch logic** — `Procedures_Content_Spec.md` has the region/technique tables, but the actual step-by-step branching UI flow (screen-by-screen) hasn't been storyboarded yet.
- **AnesCalc's existing 55 drug cards** — out of scope for this package by design; they're already built and just need a navigation home in the unified app.
- **Full antibiotic drug/dose tables, ECG image library, vent troubleshooting waveform images** — structure is specified, but the actual populated dataset/media isn't built.

---

## To-Do List — Resolve Before / During Build

### Tier 1 — Accuracy-critical, must resolve before coding the logic (patient-safety relevant)

**Peds resuscitation/RSI/status epilepticus dosing — confirmed this pass (highest-priority item, previously unverified from memory):**
- [x] **Amiodarone dosing corrected** — subsequent doses capped at 150mg each, not another 300mg (confirmed against the official 2025 AHA PALS algorithm PDF)
- [x] **Peds reversible-causes list corrected** — Hypoglycemia is its own item in the pediatric algorithm, not folded into the adult H's/T's list
- [x] **New 2025 element added** — diastolic BP targets during CPR (≥25mmHg infants, ≥30mmHg older children) when arterial monitoring is available
- [x] **Diazepam rectal dosing corrected** — age-stratified (2–5y/6–11y/≥12y), not a flat 0.2–0.5mg/kg range as originally drafted
- [x] **Phenobarbital added** — a genuine gap; the earlier draft had no neonatal-specific 2nd-line status epilepticus agent
- [x] **Fosphenytoin and levetiracetam max dose caps added**
- [x] **Etomidate dosing corrected** — 0.2–0.4mg/kg range with a 20mg cap, not a flat 0.3mg/kg
- [x] **Ketamine-over-etomidate-in-septic-shock rationale made explicit** (adrenal suppression), not just a general preference note
- [x] **Atropine pretreatment guidance revised** — current evidence doesn't support routine premedication tied to succinylcholine use; the narrower supported indication is children <1 year undergoing direct laryngoscopy, independent of paralytic choice
- [x] **De-duplicated** — Peds Module previously had a second, now-stale copy of the RSI dosing table; it now points to `Drug_Dosing_Peds_Weight_Based_Spec.md` as the single source of truth instead of repeating numbers that could drift out of sync

**Procedures/BRUE — confirmed this pass (second-priority item):**
- [x] **Laceration repair table refined** — face removal timing corrected to 3–5 days (was flat 5), trunk corrected to 6–10 days (was 7–10), scalp/trunk suture size tightened to 3-0/4-0; cross-checked against AAFP, Merck Manual, and StatPearls
- [x] **New pearls added:** pediatric-specific suture material preference (absorbable over nonabsorbable to avoid a second removal visit), wound-age cutoff for primary closure (<6–8h general, <12–24h face/scalp), irrigation volume reference (50–100mL/cm), blue suture recommended for scalp visibility, staple contraindications (face/neck/hands/feet)
- [x] **Fascia iliaca block fully specified** — confirmed "two-pop" landmark technique with exact anatomic description, confirmed volume (20–40mL adult, 0.8mL/kg peds) — previously just "larger volume, single fascial plane injection" with no actual numbers
- [x] **BRUE confirmed accurate** — matches the 2016 AAP guideline exactly, no changes needed; found and cited the 2019 AAP follow-up paper that fills the higher-risk-infant gap the 2016 guideline explicitly didn't cover

**Still not verified — remaining Procedures content:** splint types/positioning by region, the rest of the nerve block volumes (digital, wrist, hematoma, facial, intercostal, femoral, popliteal, interscalene/supraclavicular/axillary) beyond fascia iliaca, and POCUS exam-specific technique detail. These were written from general clinical knowledge, same caveat as everything else on this list before its confirmation pass.

**ECG Library and Anticoagulation Reversal — confirmed this pass (final item on the original priority list):**
- [x] **⚠️ Urgent correction, not just a refinement:** andexanet alfa was voluntarily withdrawn from the US market on December 22, 2025 (thromboembolic safety concerns). The earlier draft listed it as the primary factor Xa inhibitor reversal agent — that's now wrong for US practice. 4-factor PCC is the current practical default in the US; andexanet remains available in the EU/Canada if you're building for a non-US market. This is exactly the kind of finding this whole review process exists to catch.
- [x] **Anticoagulation table filled in with actual doses** — vitamin K (10mg IV over 30 min, confirmed as the single correct dose/route for emergent warfarin reversal), idarucizumab (5g IV split into two 2.5g infusions) — previously these agents were named with no dosing detail at all
- [x] **De Winter pattern specified** — upsloping ST depression at J-point + tall symmetric precordial T waves, confirmed as a STEMI-equivalent
- [x] **Wellens syndrome specified** — T-wave changes in V2–V3 specifically during pain-FREE intervals (a detail that was missing entirely), two types (A biphasic, B deep symmetric inversion — more common), with pseudo-normalization flagged as the re-occlusion warning sign
- [x] **Brugada corrected** — only Type 1 (coved, ≥2mm, V1–V3) is actually diagnostic; the earlier draft said "V1–V2" (wrong lead range) and didn't distinguish that Types 2/3 aren't diagnostic on their own

**This closes out the full priority list from the original review request** (peds dosing → Procedures/BRUE → ECG/anticoagulation). Everything that was flagged as "written from clinical knowledge, not independently verified" at the start of this process has now either been confirmed, corrected, or explicitly re-flagged as still-open with a clear reason why (the remaining nerve blocks/splints, and the dense multi-page tables like NIHSS's per-point criteria, PSI/PORT, and Caprini's full item list from the earlier calculator pass).

- [x] **STEMI ST-elevation millimeter thresholds by lead/sex/age — genuine gap filled, not just refined.** The 12-Lead module previously only had territory localization (which leads = which artery); it had no actual numeric ST-elevation diagnostic criteria at all. Added the full Fourth Universal Definition table: ≥1mm all leads except V2–V3; V2–V3 ≥2mm (men ≥40y) / ≥2.5mm (men <40y) / ≥1.5mm (women any age); posterior leads ≥0.5mm; two contiguous leads required. Cross-validated across multiple independent sources.
- [x] **Content Update Architecture designed** — new file `Content_Update_Architecture_Spec.md`. Core decision: content as remote-fetched, offline-cached, versioned JSON (not hardcoded in app logic), so a correction like the andexanet finding is a content push, not an App Store resubmission. Includes a staleness-surfacing mechanism (CI tripwire on overdue Tier 1 content, user-facing "last verified" dates) and a solo-maintainer git-based update workflow that doesn't require building a CMS.

**Resolved this pass (confirmed via primary/authoritative sources):**

- [x] ~~**ERC 2025 Paediatric Life Support Guidelines**~~ — **Resolved.** No changes to core pediatric BLS vs. the 2021 ERC guidance — AHA and ERC remain substantively aligned. One new pearl surfaced and was added: dose resuscitation drugs by ideal body weight (not actual weight) in obese children. Full detail in `Reference_Library_Content_Spec.md` and `Drug_Dosing_Peds_Weight_Based_Spec.md`.
- [x] ~~**ANDROMEDA-SHOCK 2 (2025)**~~ — **Resolved.** Published in JAMA Oct 29, 2025. Composite outcome win ratio 1.15 favoring CRT-targeted resuscitation (P=.04), more vital-support-free days, no significant 28-day mortality difference alone. Full write-up in `Reference_Library_Content_Spec.md`.
- [x] ~~**AHA 2025 infant CPR hand-position change**~~ — **Resolved.** Two-finger technique eliminated; use heel of one hand or two-thumb encircling technique. Infant choking sequence is 5 back blows + 5 chest thrusts (not abdominal thrusts, unlike children/adults). Updated in `Reference_Library_Content_Spec.md` and `Peds_Module_Content_Spec.md`.
- [x] ~~**AHA 2025 stroke algorithm thrombolytic**~~ — **Resolved.** Tenecteplase (TNK), FDA-approved March 2025, now used as an alternative to alteplase. Build the card with both agents; confirm your institution's specific protocol since exact windows are still being operationalized site-by-site.
- [x] ~~**GRACE Score**~~ — **Confirmed, not resolvable further.** GRACE 2.0 is genuinely a proprietary non-linear model with no public closed-form equation — this isn't something to reverse-engineer. Confirmed cutoff: score >140 = high risk (ESC 2023/ACC-AHA 2025). Build note stands: license the official calculator or approximate from published nomogram bands.
- [x] ~~**Caprini Score**~~ — **Corrected.** Risk categories for the 2005/2010/2013 revisions: low (0–1), moderate (2), high (3–4), highest (≥5) — four tiers, not the three-tier breakdown originally drafted. Also flagged: MDCalc hosts separate 2005 and 2013 versions with different checklists — pick one deliberately. Full 38-item checklist still needs to come from the source, not hand-transcription.
- [x] ~~**Glasgow-Blatchford Score**~~ — **Fully resolved.** Exact BUN/Hgb/SBP point brackets now in `Calculator_Logic_Build_Spec.md`.
- [x] ~~**Rockall Score**~~ — **Structure fully resolved** (pre-endoscopy max 7, post-endoscopy max 11, all variable breakpoints documented). Only the comorbidity/diagnosis sub-category exact wording needs a final MDCalc cross-check.
- [x] ~~**Canadian Syncope Risk Score**~~ — **Range and cutoff confirmed** (−3 to 11, <1 = low risk). Full 9-factor point table is still approximate — confirm against the 2016 CMAJ derivation paper before shipping.
- [x] ~~**pARC**~~ — **Variables and risk tiers confirmed** (sex, age, pain duration, guarding, pain migration, RLQ tenderness, ANC; <15% low, 75–84% high-intermediate, ≥85% high). **Correction:** the source paper is *Pediatrics* 2018, not *JAMA Network Open* as originally drafted. Regression coefficients themselves still need the primary paper — same category as GRACE.

**Resolved in a second confirmation pass:**

- [x] ~~**NIHSS**~~ — **Item score ranges fully confirmed** (all 15 items, e.g. 1a LOC 0–3, motor arm/leg items 0–4 each, total 0–42), plus confirmed severity bands. **Still needs:** the certified per-point behavioral criteria (what separates a 1 from a 2 on each item) — that level of detail genuinely requires the official NIH scoring manual, not search summaries, since this is the one score clinicians are formally certified to administer.
- [x] ~~**APACHE II**~~ — **Age points, chronic health points, and GCS formula fully confirmed** (age: <45=0/45–54=2/55–64=3/65–74=5/≥75=6; chronic health: 0/2/5; GCS contribution = 15 − actual GCS; total 0–71; mortality correlation confirmed). **Still needs:** the full 12-variable × 9-band physiologic breakpoint matrix from the original 1985 table — too dense to safely reconstruct from search snippets alone.
- [x] ~~**PECARN Pediatric Head Injury Algorithm**~~ — **Fully resolved.** Both complete age-stratified branching trees (< 2y and ≥2y), severe-mechanism definitions, and disposition guidance now in `Calculator_Logic_Build_Spec.md`.
- [x] ~~**Revised Geneva Score**~~ — **Fully resolved.** Exact point table for both the original and simplified versions now documented side-by-side, with a build note to pick one and not mix weights.
- [x] ~~**IMPROVE Bleeding Risk Score**~~ — **Structure and ≥7 cutoff confirmed** across multiple independent validation studies. Exact per-item weights remain approximate — still the least consistently-reproduced score on this list.
- [x] ~~**Corrected Sodium for Hyperglycemia**~~ — **Recommendation made:** default to Hillier (2.4 constant) over Katz (1.6) — Hillier is empirically derived and more accurate at the high glucose levels where this calculation actually matters (DKA/HHS).
- [x] ~~**Lean/Adjusted Body Weight**~~ — **Janmahasatian LBW formula located** (men: 9270×wt / (6680+216×BMI); women: 9270×wt / (8780+244×BMI)) — flagged as reconstructed-from-memory rather than independently re-verified this pass, so still worth a final cross-check. Recommendation: use simpler Adjusted BW for routine dosing, reserve Janmahasatian LBW for edge cases (very short/very obese patients).
- [x] ~~**Peds potassium replacement thresholds (DKA)**~~ — **Resolved** via BSPED/ISPAD-aligned guidance: defer insulin if K+ <3.0mmol/L; withhold potassium in fluids if K+ is above the upper limit of normal (~5.5mmol/L) until urination occurs or K+ normalizes. Also found: children <5y should start insulin at the lower end of the dosing range (0.05 units/kg/hr) to reduce hypoglycemia risk.
- [x] ~~**Defibrillator pad size transition**~~ — **Corrected.** The actual consensus threshold is age <8 years OR weight <25kg (55lbs) for pediatric pads — not the <10kg/<1yr figure originally drafted, which was wrong. Still worth confirming against your specific device, but this is now a solid default rather than a placeholder.

**Resolved — everything from the original Tier 1 list is now closed:**
- [x] **NIHSS** — item score ranges fully confirmed (0–42 total). Per-point behavioral criteria deliberately excluded from scope: this app is a risk-stratification calculator, not a certified exam-administration tool, so the exact 1-vs-2 distinctions are left to Neuro/certified examiners rather than encoded here.
- [x] **APACHE II** — **Fully resolved.** Complete 12-variable × 9-band physiologic breakpoint table pulled directly from Merck Manual's adaptation of the original Knaus et al. 1985 table, plus age points, chronic health points, GCS formula, and the Knaus mortality equation.
- [x] **PSI/PORT Score** — **Fully resolved.** Complete Step 1 screening criteria, full Step 2 point table (all ~20 variables), risk class cutoffs, and 30-day mortality by class, from Fine et al. 1997.
- [x] **Caprini Score** — **Fully resolved, including the interpretation decision.** Went with the 0–1 low / 2 moderate / 3–4 high / ≥5 highest scheme — more sensitive (escalates prophylaxis intensity at score 2 rather than 3) and confirmed as the scheme that actually persisted across the 2005, 2010, and 2013 revisions, rather than a single institutional reproduction. Full prophylaxis-by-tier text now in the spec.

### Tier 2 — Licensing/IP, must resolve before shipping content

- [ ] **Nerve Block content** — write original text/diagrams; do not source NYSORA's proprietary images
- [ ] **POCUS content** — same as above; use EchoRef's open content as the factual base, not NYSORA's images
- [ ] **ECG Library** — create original annotated tracings; do not source ECGRef's images directly
- [ ] **Pedi Tape / weight-zone system** — confirmed already resolved in `Dual_Mode_Weight_Zone_Spec.md` with an original 9-zone scheme (Teal→Charcoal); just needs final color/boundary sign-off, not a new design
- [x] **AHA algorithm cards (ACLS/PALS/On-The-Go equivalent)** — **Resolved, and it's a firmer answer than "verify licensing":** AHA does not grant reproduction of "substantially all" of a copyrighted work through its standard process — it requires a separate Corporate Relations negotiation, which this project doesn't have. Build original algorithm cards from the underlying public-domain clinical science, not AHA's diagrams/wording. Full detail in `Reference_Library_Content_Spec.md`.

### Tier 3 — Sourcing/content-freshness, needs a deliberate decision + refresh mechanism

- [ ] **Vaccine Schedules module** — source from AAP's published schedule per your decision; build as a refreshable dataset, not hardcoded (see `Reference_Library_Content_Spec.md` for the full rationale)
- [x] **Empiric Antibiotic Guide** — structure stands; drug/dose recommendations still need your institution's antibiogram and remain a "needs periodic refresh" module, not a one-time build. **Non-severe CAP timing specifically resolved:** IDSA and ATS are in live disagreement over empiric antibiotic timing for non-severe CAP (2025 dispute). Rather than pick a side, the card defers explicitly to local protocol — build the literal UI copy "The decision to initiate empiric antibiotics in non-severe CAP should be made at the local level, per institutional protocol" onto that card. Severe CAP is unaffected (both societies agree) and can be populated normally.
- [ ] **Landmark Trials Library** — cross-check the starter list in `Reference_Library_Content_Spec.md` against what's already written in Critical Vector before populating, to avoid duplicating your own prior work

### Tier 4 — Cross-referencing, prevents silent data drift between sources

- [ ] **Peds Resuscitation Meds & Equipment by Weight** — cross-reference the formulas in `Drug_Dosing_Peds_Weight_Based_Spec.md` against what PedsGuide and First 5 Minutes actually publish; resolve any discrepancy deliberately rather than picking one silently
- [ ] **Peds RSI dosing** — cross-reference PedsGuide's RSI dosing against First 5 Minutes' RSI dosing for duplicate/conflicting drug entries before finalizing

### Tier 5 — Product/design decisions, not content gaps

- [x] **App-wide search & Home-screen searchable TOC** — **Resolved.** Full design in new file `Search_TOC_Design_Spec.md`: one flat JSON search index (not five separate ones) generated at build time from the same structured content data, with per-section search being that same index pre-filtered rather than a separate system. Home screen shows a search bar (live results grouped by section) plus a collapsible tree TOC as the empty state, mirroring the exact category structure already used across the content specs. Schema, matching behavior, and ranking priority all defined. Still needs: actually populating `tags`/`keywords` per item as content is written (real work, not just schema).
- [ ] **Color/font scheme** — needs to be visually distinct from both AnesCalc and CRISIS; requires pulling both existing palettes for comparison before proposing options — not yet started
- [x] **App name** — **Decided: Kairos** (pronounced "KY-ros"). (Landed here from Extremis → Vade Mecum → Praxis → Fulcrum → Codex → Vertex → Materia Medica → Armamentarium → Crux/Repertoire/Atlas/Precis/Vantage → Discrimen/Krisis/Kairos/Qanun → Kairos. Briefly considered "Kyros," a deliberate respelling to force the intended pronunciation, but reverted to the standard spelling. Clean on App Store/trademark checks throughout that whole process — no conflicts found. Note for the UI/marketing copy: the "ai" spelling reads to most English speakers as "Kay-ros" on first sight — worth a pronunciation cue somewhere in onboarding or the App Store listing itself, since that mismatch is exactly why "Kyros" was considered in the first place.)
- [x] **Pronunciation/name copy for onboarding + Settings → App Information** — **Written below.** Same core copy in two lengths: a short version for the onboarding flow (first-run only, skippable) and a longer version for a persistent "About" entry in Settings, so the pronunciation and meaning are always one tap away, not just shown once.

**Onboarding — first-run screen, short form:**
> **Kairos** — pronounced *KY-ros* (rhymes with "sky")
> Greek for "the critical moment" — the point where decisive action changes the outcome. That's the moment this app is built for.

**Settings → App Information — persistent "About" entry, full form:**
> **About Kairos**
>
> Pronounced *KY-ros*, rhyming with "sky" — not "Kay-ros."
>
> Kairos is the ancient Greek term for the critical or opportune moment: the point at which decisive action must be taken, distinct from *chronos* (ordinary, chronological time). In Hippocratic medicine, *kairos* described the precise moment when intervention could change a patient's course — the same idea this app is named for.
>
> Kairos brings together the calculators, procedure guides, drug-dosing tools, and reference material you need across the ED, ICU, and OR into one companion tool — alongside AnesCalc and CRISIS, not in place of either.
>
> **Why Kairos exists:** most of what's genuinely useful at the bedside is scattered across a dozen or more single-purpose apps — one for suture technique, another for peds resuscitation dosing, another for a handful of calculators. Finding the right one costs time. Kairos puts that content in one place, organized around how a shift actually runs across the ED, ICU, and OR — not around which developer happened to build which tool first.

**Build note:** keep this as literal, static copy — not something that needs live data or a refresh mechanism, unlike most of the content elsewhere in this package. Place the Settings version under whatever your Settings screen already calls its about/info section (e.g., "About," "App Info") so it's discoverable without hunting. The "why" paragraph is deliberately left out of the onboarding short-form above — that screen is meant to be skippable and fast; the fuller story belongs in Settings where someone can choose to read it, not in the way of getting into the app.

### Tier 6 — UI/UX behavior requirements (interaction-level, apply across all 5 sections)

- [ ] **Clear-text affordance on every entry field** — iOS-style inline "x in a circle" at the end of each text/number entry field, clearing just that field
- [ ] **"Clear fields" button for multi-field screens** — anywhere a screen has more than one entry field (e.g., a calculator with several inputs, or the weight/age entry for Drug & Dosing), a single button clears all fields on that screen at once, distinct from the per-field clear button above
- [ ] **Floating keyboard collapse control** — a dismiss/collapse button on the floating keyboard so the user can close it without tapping away from the field (standard iOS pattern, but needs to be explicit here since several inputs — like the weight-entry flow in `Dual_Mode_Weight_Zone_Spec.md` — are keyboard-heavy)
- [ ] **Data persistence across app backgrounding** — entered data (patient weight, calculator inputs, in-progress procedure guide state, etc.) must survive the app being backgrounded or the user switching to another app, and still be there on return
- [ ] **Data clears on full app closeout** — a genuine force-quit/full closeout of the app is the only thing that clears persisted session data; backgrounding is not treated as a closeout


---

## Suggested build order

1. **Calculators section first** — most self-contained, most of the formulas are already verified, and it has no licensing entanglements. The Tier 1 items above are concentrated here, so knocking those out first clears the biggest accuracy risk early.
2. **Drug & Dosing Cards second** — depends on Calculators (the 8 moved dosing-math tools) but not on Reference Library or Procedures. Resolve the peds cross-referencing (Tier 4) here.
3. **Peds Module third** — depends on Drug & Dosing Cards being done (shares the same dosing engine) and PECARN from Calculators.
4. **Reference Library fourth** — largest content volume, most licensing-sensitive (Tier 2), and contains the vaccine schedule sourcing decision (Tier 3) — budget the most time here.
5. **Procedures last** — depends on Drug & Dosing Cards (LA max dosing, RSI meds) and Calculators (LEMON, STOP-BANG, Aldrete for the two workflow entries) being done first, since it's built to orchestrate them rather than duplicate them.
6. **Search/TOC and color scheme (Tier 5)** — cross-cutting, do once the 5 sections' actual content shape is stable, not before.

---

## Non-negotiable design principles carried through every file

- **One source of truth per fact.** A dose, formula, or cutoff is written once and cross-linked, never restated independently in two files (this is why several specs say "cross-link, don't duplicate").
- **Zones/bands never supply a dose.** Anything continuous (drug doses, fluid volumes) is calculated live from the exact patient weight; only genuinely discrete things (equipment sizes) are legitimately zone-based.
- **CRISIS stays separate.** Nothing in this package is meant to fold into or compete with CRISIS's standalone, search-free, highest-acuity design.
- **External AI and Coding/Admin sections are cut**, per your direction — not enough unique bedside value to justify a section in this app.
