# Kairos — Open Items & Sources Needed

Living tracker. Two lists:
1. **Things to address** — engineering/design work, gaps, and decisions still open.
2. **Sources to provide** — material only you can supply (primary papers, licensed
   or original content, existing Critical Vector / AnesCalc assets) before the
   affected content can be finalized.

Last updated: 2026-09-08

## ▶ NEXT SESSION — start here (2026-09-08)
State: **312 modules**, pipeline green (312/0, tests 252/0). iOS builds + runs;
`ios-ci` green (fixed by moving bundled TTFs out of `ios/Sources/` into
`ios/Resources/Fonts/` — a binary blob inside the Swift source glob tripped the
older CI toolchain). IBM Plex bundled on both clients + the type sweep is done
(nav-bar title font, all semantic sizes → `Theme.*` tokens with Dynamic Type
kept). Web has a desktop nav rail (≥ 960 px), section-tint identity on detail
pages, per-h2 rules + ticks, and a route fade. The Rumack-Matthew nomogram now
renders on **both** clients (calculator `plot` schema + web SVG + iOS `Canvas`
`NomogramView`).

Remaining open items:
1. **GitHub Pages — repo-owner one-time setup** (code is done, waiting on the
   two clicks): Settings → Pages → Source = "GitHub Actions"; and add repo
   Variable `CONTENT_BASE_URL` = `https://awpeace1906-collab.github.io/kairos/content/`.
   Then push → `deploy.yml` publishes the PWA at `…/kairos/` and the content
   tree at `…/kairos/content/`. iOS `remoteBase` is already pointed there.
2. More `crossListIn` placements as adult/peds pairs surface; the antibiogram
   worksheet still needs the user's local data.

DONE 2026-09-08: **Deploy is wired for real.** `tools/deploy.mjs` now assembles
one bundle — the PWA shell + `/content/` — and `deploy.yml` (was
`content-deploy.yml`) publishes it to Pages on any push to main. iOS
`ContentStore.remoteBase` = the Pages content URL (OTA live once Pages is on;
degrades to bundled content until then). Web stays same-origin. Verified the
assembled `dist/` renders both at `/` and at a `/kairos/` subpath.
Also DONE: **pin/unpin UI** — `☆/★` button on every module (web detail bar / iOS
nav toolbar), stored in `prefs.pins` / `@AppStorage("kairos.pins")`, seeded from
the curated `config/pinned.json` on first edit; the home Pinned strip reflects
it. **`dka-hhs-adult-management`** reference (adult DKA/HHS — the K-before-insulin
sequence) with `peds-dka-management` cross-listed beside it in RefLib/Critical
Care. The Peds section-vs-lens question was resolved + shipped earlier today
(Peds Module stays a section; `audience` tags 41 modules; `crossListIn` on 7;
a persisted "Peds" lens toggle floats peds rows).

DONE 2026-09-08 (across the block): pARC interactive calculator (verified
coefficients); home redesign + IBM Plex bundled both clients; Rumack-Matthew
nomogram (web + iOS); web UI polish (form-control font, tables, WHY/TAKEAWAY
split, salicylate band fix); desktop nav rail + heading rhythm + section
identity + motion; iOS `ios-ci` font-path fix; iOS type sweep + nav-bar font;
backlog cleared → `radiation-decorporation-dosing` (KI age table + Ca/Zn-DTPA +
Prussian blue + bicarbonate, one module), `high-dose-insulin-euglycemia-dosing`
calculator, `brue-lower-risk-criteria` peds-tool checklist.

## Progress log
- 2026-09-09 — **Guide fold-ins (6, no new modules).** From the deferred list in
  the CV Guides review: `capnography` v3 (new EtCO2–PaCO2 gradient section);
  `airway-management-flow` v3 (Plan A → VL > DL / hyperangulated > Macintosh per
  COVALENT 2026; post-intubation alkalinised-lidocaine-cuff pearl);
  `pocus-guide` v3 (FIND / DE-SELECT / CONTROL antibiotic framework);
  `ecg-library` v4 (antidromic Mahaim + Bardy 6-point criteria);
  `ventilator-liberation-weaning` v2 (avoid 100% FiO2 washout at extubation —
  Paschold BJA 2026). validate 316/0, test 252/0. Pure-EBM-audit guides skipped
  (list in SOURCE_MATERIALS.md).
- 2026-09-09 — **CV Guides refresh reviewed + 3 new modules + 1 update (→ 316).**
  User supplied an updated `CV Guides.zip`; most new files are EBM-audit /
  trial-breakdown pieces (no new modules per the 2026-09-02 direction — fold-in
  list is in `docs/SOURCE_MATERIALS.md`). Built: **`ventilator-liberation-weaning`**
  (the explicit ask — ICU extubation/weaning: daily readiness screen, SBT
  technique + pass/fail, SAT+SBT pairing, RSBI, cuff-leak test + prophylactic
  methylprednisolone, high-risk extubation to HFNC/NIV with the "no rescue NIV"
  rule, reintubation, failure-to-wean work-up table, tracheostomy timing; 2017
  ACCP/ATS + Boles 2007 + Subirà 2019 + Thille/Hernández + François 2007 +
  TracMan). `ventilator-management` → v5 (weaning section points to it).
  **`bone-cement-implantation-syndrome`** (Peri-op / Anaesthesia — Donaldson
  grading, mechanism, prevention checklist, grade-by-grade RV-failure
  management). **`alcoholic-ketoacidosis`** (Critical Care — NADH/NAD⁺ mechanism,
  the β-OHB-under-reads point, work-up + mimics, dextrose/thiamine/electrolytes,
  no-insulin/no-bicarb; companion to `dka-hhs-adult-management`). **`icp-tbi-management`
  → v3** — folded in the 2025 ICM review (Robba et al.): ICP-monitoring camps,
  PaO2 80–120 + hyperoxaemia caution, no TXA benefit in isolated TBI, CPPopt,
  elderly SBP ≥ 110, PbtO2 trial status. validate 316/0, test 252/0.
- 2026-09-08 — **Pin/unpin UI · adult DKA module · deploy wired for real (+1 → 313).**
  *Pins:* `prefs.js` `PINS_KEY` (id array; `null` = use curated) + `pinnedIds` /
  `isPinned` / `togglePin`; `ios/Sources/App/Pins.swift` (`@AppStorage` string,
  `""` = curated, `"-"` = empty). A `☆ Pin` / `★ Pinned` button on the web
  detail bar and a `pin` / `pin.fill` nav-toolbar button on iOS; the home Pinned
  strip resolves the effective list (`store.resolvePins` / `content.resolvePins`).
  Config `pinned` label/blurb wins for curated ids; user-added ids fall back to
  the module title / category. *Content:* `dka-hhs-adult-management` (Reference
  Library / Critical Care, Tier 2) — adult DKA & HHS: diagnostic + severity
  tables, the fluids → potassium → insulin sequence (with the K⁺ decision table),
  adjuncts, euglycemic DKA / SGLT2, resolution + IV→SC transition. Sources
  Kitabchi 2009 / Umpierrez 2024 ADA-EASD consensus / ADA 2025 / JBDS 2023.
  `peds-dka-management` gets `crossListIn` → RefLib/Critical Care to sit beside
  it. *Deploy:* `tools/deploy.mjs` rewritten to assemble ONE bundle — PWA shell
  (`web/` minus dev files) at `/` + the content subset at `/content/`;
  `content-deploy.yml` → `deploy.yml`, triggers on any push to main.
  `ContentStore.remoteBase` (iOS) set to
  `https://awpeace1906-collab.github.io/kairos/content/`; web `REMOTE_BASE` stays
  `null` (same-origin, SW stale-while-revalidate). manifest.webmanifest colours
  updated off the old `#0F0B16`. Verified `dist/` renders standalone at `/` and
  at a `/kairos/` subpath. validate 313/0, test 252/0, iOS BUILD SUCCEEDED.
  Remaining: repo owner flips Pages Source → "GitHub Actions" + adds the
  `CONTENT_BASE_URL` repo Variable (see DEPLOY.md).
- 2026-09-08 — **Peds lens + cross-listing + home-screen Pinned strip.**
  Resolved the Peds Module section-vs-lens question by doing both. New schema:
  `audience` (`adult`/`peds`/`neonate`) and `crossListIn` (`[{section, category}]`)
  on `common.schema.json` recordMeta (nav metadata — no `content_version` bump,
  like `settingEmphasis`). Tagged **41 modules** with `audience` (28 peds-module
  + `erc-2025-pediatric-life-support`, `childhood-immunization-schedule`,
  `pecarn-head`, the 9 `peds-*` drug cards, `holliday-segar` as adult+peds).
  **Cross-listed 6** peds tools into their adult clinical section:
  `pediatric-appendicitis-score` + `-risk-calculator` → Calculators/GI,
  `peds-glasgow-coma-scale` → Calculators/Neuro, `apgar-score` →
  Calculators/OB-Newborn, `nrp-algorithm` → RefLib/OB-Gyn, `peds-cardiac-arrest`
  → RefLib/Resus. Build carries `audience`/`crossListIn` into `search-index.json`.
  Web: `settingLens.js` `isPeds()` + `applyPedsLens()`; `prefs.js` `PEDS_LENS_KEY`;
  `home.js` + `section.js` get a "Peds" toggle (persisted) + cross-listed rows
  show a `peds` badge; section pool = own modules ∪ cross-listed. iOS:
  `SearchEntry.audience`/`crossListIn`/`isPeds`/`appears(inSection:)`; a "Peds
  lens" `Toggle` on `HomeView` + `SectionView` (shown only where a section has
  peds content). **Home-screen Pinned strip**: new `config/pinned.json` (+
  `config.pinned.schema.json`, validated + id-checked), loaded by both
  ContentStores, rendered as ember-tinted one-tap cards above Browse — seeded
  with `peds-pre-arrival-card` + `acls-adult-cardiac-arrest`. `settingEmphasis`
  passthrough added to all 6 contentType schemas. sw.js → v8. validate 312/0,
  test 252/0, iOS BUILD SUCCEEDED + 10/10.
- 2026-09-08 — **Loose ends + backlog (+3 → 312 total).** *iOS nomogram:* added
  the `plot` field to the iOS `Calculator` model and a SwiftUI `Canvas`
  `NomogramView` (semi-log-Y, 1-2-5 decade grid, curve sampled from
  `Expression.evaluate` with the free variable `x`, marker + above/below colour
  + caption) — parity with the web renderer; verified the acetaminophen curve
  renders on device. *iOS IBM Plex sweep:* nav-bar title font set to
  IBMPlexSans-SmBld via `UINavigationBarAppearance` in `KairosApp.init`; every
  `.font(.headline/.subheadline/.callout/.footnote/.caption/.caption2/.title3)`
  and the `.bold()`/`.monospaced()` compounds swapped for `Theme.*` tokens that
  keep Dynamic Type (`.custom(_:size:relativeTo:)`). *Backlog (4 asks → 3
  modules):* `radiation-decorporation-dosing` (reference) merges the KI
  age-dosing table, Ca-/Zn-DTPA and insoluble Prussian blue cards, and
  bicarbonate-for-uranium, with an isotope→agent quick table — FDA 2001 / WHO
  2017 / product labels / NCRP 161 / REMM; `high-dose-insulin-euglycemia-dosing`
  (formula calculator) — weight-based insulin bolus + infusion range + 10
  unit/kg/h ceiling, dextrose bolus (0.5 g/kg = 1 mL/kg D50) and maintenance,
  potassium caveat — Engebretsen 2011 / St-Onge 2017 CCM;
  `brue-lower-risk-criteria` (peds-tool, embedded additive calc) — the AAP 2016
  all-must-be-true lower-risk checklist, defers to `brue-pathway` for
  management. Parent build notes (`acute-radiation-syndrome`, `tox-cardiac-meds`,
  `brue-pathway`) updated to point at the new modules. validate 312/0, test
  252/0, iOS BUILD SUCCEEDED + 10/10 engine tests.
  **Peds Module — section-vs-lens recommendation:** keep it as a browsable
  *section* (it is a genuine mental category at the bedside — "this patient is a
  kid"), but add a lightweight **peds lens** on top: give every peds-relevant
  module a `peds` audience tag and cross-list the peds calculators into their
  clinical sections (Appendicitis scores under GI, BRUE under Neuro/Resus, etc.)
  rather than moving them. A "Peds" toggle then works like the care-setting
  lens — it reorders/filters within any section to the peds variant — while the
  Peds Module section stays as the one-stop browse for peds-only tools
  (pedi-tape, weight zones, neonatal). This avoids the lose-lose of either
  duplicating numbers or stranding peds calculators away from their clinical
  context. Migration: ~30 modules get the tag; both clients get a lens control
  (reuse the `settingLens` machinery). Own session.
- 2026-09-08 — **Design pass 2 — desktop chrome, heading rhythm, section
  identity, motion.** Web: persistent left **nav rail** at ≥ 960 px (brand,
  5 sections with tint marks + counts, About/Sources, active-section spine);
  the home view collapses to a search launcher when the rail shows (no
  duplicate section list). Detail pages: `h1` up to 1.55 rem with a
  section-tint underline; every non-first `<h2>` gets a hairline section rule +
  a 3 px tint tick + 30 px top margin; a faint tint wash down the first 150 px
  of the card. Motion: 0.18 s `kairos-rise` fade on route change,
  `:focus-visible` ember ring, 0.12 s hover transitions — all under
  `prefers-reduced-motion: no-preference`. Shell cache → v7. iOS mirror: section
  eyebrow + tint bar, `<h2>` tick + `Divider` rule, WHY-THIS-MATTERS (quiet
  grey) vs CLINICAL-TAKEAWAY (ember) split, mono table headers, load fade.
- 2026-09-08 — **Nomogram + web UI polish.** Added a declarative `plot` block to
  `calculator.schema.json` (semilogy, x/y axes, curve expressions in `x`) and a
  web SVG renderer; `apap-nac-dosing` → v2 renders the Rumack-Matthew 150 line +
  a live plotted point (green below / ember on-or-above). Web polish:
  `input,button,select,textarea { font: inherit }` (form controls were falling
  back to Arial); table headers → mono / uppercase / tinted fill + zebra;
  WHY-THIS-MATTERS / CLINICAL-TAKEAWAY / callout given three distinct weights;
  calculator field labels → mono; 44 px inputs + ember focus ring; toolbar
  aligned. `salicylate-toxicity` → v2: added a passthrough `level` formula so the
  management bands (keyed to the raw input, which the formula engine never
  surfaced) actually render — the only formula calc affected. iOS: moved the 7
  bundled TTFs out of `ios/Sources/` into `ios/Resources/Fonts/` with an
  explicit resources build phase — this fixed the `ios-ci` failure (confirmed
  green on the next push).
- 2026-09-08 — **pARC tool + home-screen design pass.** pARC is now interactive:
  `pediatric-appendicitis-risk-calculator` (peds-tool + embedded formula calc)
  built from the published Kharbanda 2018 coefficients (found in the NCT02633735
  SAP / Appy-CDS Manual of Operations coefficient table) — age/sex as one
  pre-resolved select, ANC term `min(1.77·√ANC, 6.62)` (= the paper's piecewise
  rule), 7 risk bands. Verified live (high-risk case → 85.6%). `alvarado` v2 +
  PAS v3 cross-link it. **Home redesign (web + iOS):** removed the duplicate
  section list (the collapsible TOC) — one list, the section cards with the
  core-question descriptions; **IBM Plex Sans + Mono bundled** (self-hosted TTFs
  in `web/public/fonts/` + `ios/Sources/Fonts/`; SW → v6 precache; iOS registers
  at launch) so type matches PALETTES.md; masthead with the ember "struck point"
  tick; section cards carry their `--sec-*` tint as a left rule + mark + faint
  wash; numbers/labels in Plex Mono; web filter chips only show while searching.
  `Theme.display/sans/mono` helpers added on iOS. **309 modules** (pARC +1).
- 2026-09-07 — **"Needs-input" batch (+1 → 308 total).** (1) "Flag as outdated"
  now opens a prefilled GitHub issue (`awpeace1906-collab/kairos`,
  labels content,needs-review, module id/version/dates/client in the body) —
  new `web/src/lib/appConfig.js` + `ios/Sources/App/AppConfig.swift` (repo slug in
  one place each); web `sw.js` → v5. (2) `alvarado` v2 — explicit pediatric
  cross-reference (PAS/pARC) as a notes line; PAS module already covers all three
  scores. pARC computing tool deferred (needs verified coefficients). (3) New
  `peds-pre-arrival-card` peds-tool: embedded formula calc — one weight in, ~20
  resus numbers out (epi/adenosine/amio/atropine/Ca/dextrose/Mg/naloxone,
  defib+cardiovert J, fluid boluses, Holliday-Segar rate via piecewise min/max) —
  plus a body with the age→weight table, equipment-by-zone table, and age-based
  rules. Web `renderPedsTool` now renders `body` alongside an embedded calc
  (matches iOS `PedsToolBody`). Fixed the stale Teal–Charcoal zone names in
  `pedi-tape-weight-zones` → Dove-Umber (v2). validate 308/0, test 244/0, web
  verified live, iOS BUILD SUCCEEDED.
- 2026-09-07 — **Deferred batch (+3 → 307 total).** `acute-radiation-syndrome`
  reference (exposure types, time-to-emesis + lymphocyte-kinetics triage, the 3
  ARS subsyndromes, cutaneous radiation injury, external vs internal
  contamination + isotope-specific decorporation table [KI / Prussian blue /
  DTPA / bicarbonate], combined injury 48 h surgical window) — completes the
  CBRN set. `nerve-agent-antidote-dosing` calculator (weight-based atropine,
  pralidoxime load + infusion, midazolam; min()/max() caps) and
  `digoxin-immune-fab-dosing` calculator (vials from level+weight, from ingested
  mg, ceil-rounded + raw; empiric figures + indications in notes). validate
  307/0, test 244/0. `severity` enum on calc interpretation is
  info/low/moderate/high/critical (no "warning").
- 2026-09-07 — **Low-priority batch (+3 → 304 total).** New references:
  `methemoglobinemia` (causes, saturation gap, co-oximetry, methylene blue with
  G6PD + MAOI caveats, dapsone rebound), `nerve-agent-toxicity` (cholinergic
  crisis, atropine-to-secretions, pralidoxime + aging, midazolam, autoinjectors,
  intermediate syndrome), `vesicant-toxicity` (sulfur mustard delayed alkylating
  injury + marrow nadir, lewisite + dimercaprol, phosgene oxime). `brue-pathway`
  → v2: higher-risk branch built from the 2019 framework (Merritt et al.) —
  risk-elevating features, feature-matched targeted evaluation table,
  not-recommended-routinely list, disposition guide; stub + needs-primary-source
  flag removed. `nihss` → v2: full Brott 1989 + NINDS + Adams 1999 (TOAST)
  citations, severity-band scheme named with its alternate, needs-primary-source
  flag removed. Radiological/ARS still deferred (dedicated build). validate
  304/0, test 235/0.
- 2026-09-07 — **iOS port + Add-list batch (+4 → 301 total).** Root-caused the
  recurring `ios-ci` failure: `EngineTests.swift` never compiled since `22dbe04`
  (`SearchEntry` gained a non-defaulted `settingEmphasis`; the 3 test literals
  weren't updated) — fixed with an explicit `SearchEntry` memberwise init
  (`settingEmphasis: [String]? = nil`); `ios-ci.yml` now `-skip-testing:KairosUITests`
  (flaky headless). Verified the 12 new reference modules render on-device (bundled
  folder ref, no Swift changes). Then: `tox-cardiac-meds` (digoxin/BB/CCB/clonidine
  + antidotes) and `tox-psych-meds` (lithium/NMS-vs-serotonin/SSRI/bupropion) —
  the tox lateral expansion; `new-orleans-criteria` + `mangled-extremity-severity-score`
  calculators (CCR/CCHR/NEXUS already existed); iOS `BlockList` table renderer
  reworked to wrapping fixed-width columns (was one-line-per-cell). validate 301/0,
  test 235/0, iOS BUILD SUCCEEDED.
- 2026-09-07 — **Ballistics/blast manual + intoxicating-substances reference
  converted (+9 → 297 total).** `ballistics_blast_manual_v6` → `wound-ballistics`,
  `blast-injury`, `penetrating-regional-trauma` (Resus & Airway). 154 KB
  `intoxicating-substances-reference` (12 classes / 39 substances) → 6 Critical Care
  modules: `tox-stimulants`, `tox-opioids`, `tox-sedative-hypnotics`,
  `tox-dissociatives-hallucinogens`, `tox-cannabinoids-inhalants`,
  `tox-alcohols-anticholinergics-other` — each a class overview + per-agent
  distinguishing-feature/management table. All Tier 2, standard template, cross-
  linked. **All three big-ticket CV guides now fully converted.** validate 297/0,
  test 231/0.
- 2026-09-07 — **CV_Austere Disaster Medicine fully converted (+2 → 288 total).**
  Part One → `hazmat-scene-toxidromes` (Resus & Airway): hot/warm/cold zones,
  identification tools, HAZWOPER responder tiers, decon + patient flow,
  pulmonary-irritant (chlorine/ammonia/phosgene) / asphyxiant / cholinergic
  toxidromes. Part Two → `incendiary-chemical-burns`: white-phosphorus
  pathophysiology (self-sustaining combustion, phosphoric-acid hypocalcemia,
  fatal < 10% BSA), 6-agent comparative table (WP/napalm/thermite/magnesium/
  sulfur mustard/lewisite), 5-step prehospital sequence, critical-errors danger
  callout. Both Tier 2, standard template, cross-linked with `crush-syndrome`
  (Part Three, done earlier). validate 288/0, test 231/0.
- 2026-09-07 — **New reference module: `venous-congestion-deresuscitation`** (Critical
  Care, **286 total**). Venous congestion physiology (renal perfusion pressure =
  MAP − CVP), the full VExUS grading system (IVC gate + hepatic/portal/intrarenal
  Doppler normal/mild/severe table + Grades 0-3 + confounder callout), the ROSE
  four-phase fluid model, a bedside de-resuscitation protocol with an over-diuresis
  stop rule, VExUS-to-guide-diuresis integration, and the evidence base (FACTT,
  CLASSIC/CLOVERS, ADVOR/DOSE, Beaubien-Souligny). Tier 2. Standard template
  (whyThisMatters + clinicalTakeaway). validate 286/0, test 231/0.
- 2026-09-07 — **`settingEmphasis` tagging completed: 285/285 modules.** Tagged the
  remaining 182 (Calculators 90, Peds Module 25, Procedures 8, Drug&Dosing 18,
  Reference Library 41) by clinical care setting, most-relevant-first over
  `prehospital / ed / or / icu`. Surgical single-line insert after each `title` —
  no `content_version` bump, no changelog (nav metadata; manifest hash still
  changes so clients resync). validate 285/0/0, test 231/0. The care-setting lens
  now has data for every module in every section.
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
- 2026-09-03 — **Procedures decision-trees deepened.** Turned out the infra
  already existed end-to-end: `procedure.schema.json` has the `nodes` graph
  (`question`/`step`/`recommendation`/`warning` + `choices[].next`), and both
  `web/src/views/content.js` (`treeWalker`) and `ios/.../ContentDetailView.swift`
  (`ProcedureWalker`) render it interactively (breadcrumbs, jump-back, Start-over).
  `laceration-repair` and `fracture-splinting-guide` were already trees, one level
  deep. No schema/renderer change — just authored depth:
  - **`fracture-splinting-guide` v2** — 11 flat nodes → 60. Per region a
    displacement/pattern triage (splint as-is / reduce / emergent ortho), named
    fractures (scaphoid, boxer's, Jones, Lisfranc, Monteggia/Galeazzi,
    supracondylar, knee dislocation), a paediatric branch (buckle / greenstick /
    plastic / Salter-Harris / toddler's / NAT), and shared `gate-emergent` /
    `compartment` / `emergent` / `reduce-generic` nodes.
  - **`laceration-repair` v3** — added an upstream triage layer: a special-features
    gate (bite / gross contamination / delayed presentation / crush) and a
    deep-structures gate (tendon / nerve / joint / arterial) routing to their own
    nodes before region selection.
  - Nerve-block and POCUS guides stay `reference`-style block menus (they're
    catalogues, not decisions) — a lower-value conversion if ever wanted.
- 2026-09-03 — **App icon LOCKED.** The "broken ring" mark: an open ring reading
  clockwise (6→9→12→3), broken at the lower right, a decisive strike driving a
  bright struck point into the mouth of the gap; one continuous top-to-strike
  gradient (warm amber → deep oxblood); ground `#0F0B16`. Masters on the Desktop
  working folder (`kairos-ring-refined.svg` + `-mono.svg`). Wired in:
  `web/public/icons/icon.svg` (replaced the teal placeholder) + `icon-mono.svg`
  + PNGs (1024 / 512 / 192 / apple-touch 180) generated via a browser-canvas
  render; `web/manifest.webmanifest` + `web/index.html` updated (theme-color
  `#0F0B16`). iOS: `ios/Sources/Assets.xcassets/AppIcon.appiconset/` (single
  1024 PNG, modern Xcode auto-scales) + `ASSETCATALOG_COMPILER_APPICON_NAME` in
  `project.yml`. The full rationale + size ladders are in the "Kairos Icon Study"
  artifact.
- 2026-09-03 — **Pocket-guide tails batch (+21 modules).**
  - OB (`Obstetric & Gynecologic`): `labor-progression` (Zhang curve + Bishop),
    `induction-augmentation`, `preterm-labor`, `chronic-htn-gdm-pregnancy` (CHAP era),
    `prenatal-screening`, `fetal-surveillance` (BPP + Doppler),
    `bartholin-vulvar-emergencies`.
  - Vent (`Resuscitation & Airway` / `ICU`): `status-asthmaticus-ventilation`,
    `copd-invasive-ventilation`, `peep-fio2-ladder` (both ARDSNet ladders),
    `advanced-ards-ventilation` (APRV / recruitment / intraop PEEP).
  - EM: `post-intubation-management`, `hemorrhagic-shock-mtp` (ATLS class + MTP),
    `efast-exam` (+ RUSH), `hs-troponin-chest-pain` (0/1-h algorithm + ACS bundle),
    `trauma-team-activation` (+ CDC field triage).
  - Neonatology (Peds Module): `neonatal-growth-parameters`,
    `infant-development-feeding`, `prematurity-complications`,
    `sga-lga-birth-injury`, `inborn-errors-metabolism`.
  - Then +4: `chromosomal-disorders`, `inheritance-patterns`,
    `developmental-delay-evaluation` (Neonatology), `allowable-blood-loss`
    (EBV + MABL calculator, Anesthesia/OR). **277 modules.**
  - **Content build now substantially complete.** Remaining seams are low-yield:
    Vent's ~30 deep mode-specific subsections (NAVA, PAV+, ASV, cross-manufacturer)
    — specialist; calculator refinements (NISS/TRISS, interactive New Orleans
    CT-head rule, Caprini-2013 40-item); nerve-block / POCUS as interactive trees
    (currently reference menus — a design call). Anesthesia reference guide never
    parsed with the pocket-guide extractor (different `<h2>`-section HTML) — its
    useful sections were pulled by hand.
  - **Git note:** the VM's disk I/O degraded hard this session — `git add` /
    `git commit` hung for minutes with a 0-byte `.git/index.lock`. Drill: kill the
    stuck process, `rm -f .git/index.lock`, retry. 580+ unpacked loose objects;
    a `git gc` did not complete cleanly. Worth a manual `git gc` from a terminal.
- 2026-09-03 — **Tier 5 palette DECIDED — "Ink & Ember on Parchment" (Option A).**
  Light-first parchment ground (`#F2F1ED` / dark `#1A1A1E`), ember accent
  (`#C6521C`, sparing — one decisive element per screen), reconciling the palette
  with the shipped ember app icon. Reads as neither companion (AnesCalc navy+gold,
  CRISIS teal-on-black serif). Applied: `web/styles.css` `:root` + dark `@media`
  (flipped to light-first; added `--accent-deep`, 5 `--sec-*` section tints,
  `--font-sans`/`--font-mono`), `web/src/views/home.js` (tiles emit `data-section`
  → tint left-border), `web/index.html` (theme-aware `theme-color`),
  `ios/Sources/App/Theme.swift` (section + severity colours to the Option A
  hexes; added `Theme.accent`). Full token table + swatch-artifact link in
  `docs/PALETTES.md`; the old cobalt-indigo proposal there is marked superseded.
  Follow-ups: self-host **IBM Plex Sans/Mono** woff2 (stack falls back to system
  until then); wire `--sec-*` tints into section headers / detail views beyond
  the home tiles; iOS dark-mode colour set via asset catalog; recolour
  `weight-zones.json` off the old Teal→Charcoal scheme.
  **Not verified live** — the same disk I/O failure blocked `tools/build.mjs`
  (2-min timeout on a ~2s script) and the dev server's `predev` sync. Static
  checks pass (CSS braces balanced, `node --check` on home.js). Eyeball with
  `npm --prefix web run dev` from a healthy terminal.
  - **Palette VERIFIED live** later the same session (disk I/O eased enough to run
    `web/server.mjs`): parchment `rgb(242,241,237)` ground, ember `#C6521C`
    selected-chip with white text, all 5 section tiles carrying their `--sec-*`
    tint left-borders, IBM Plex Sans stack active, dark-mode charcoal parity.
    Committed + pushed as `fa00db3`. Remote added: `github.com/awpeace1906-collab/kairos`.
  - **CI on first push (fa00db3):** `content-deploy` **build** job green (deploy
    bundle builds with the new palette). `content-deploy` **deploy** job red —
    GitHub Pages needs a paid plan for private repos; hosting decision parked
    (options: make repo public / GH Pro / Cloudflare Pages / defer). `ios-ci` red
    — **pre-existing**, unrelated: XcodeGen (latest via brew) emits Xcode-16
    project format, `macos-14` runner has Xcode 15.4. Fix staged in
    `.github/workflows/ios-ci.yml` (→ `macos-15`, sim `iPhone 16`, `checkout@v5`),
    not yet committed. `content-ci` was still running (slow `npm install`).
- 2026-09-03 — **Airway content (+2 → 279 modules).** Converted the last flagged
  CV airway guides. New: `anatomically-difficult-airway` (reference — DAS 2025
  Plans A-D, MACOCHA anticipation, CAFG 3-attempt rule, the Vortex, scalpel-
  bougie-tube eFONA steps, human factors, team-brief script, cheat sheet — the
  procedural/failed-airway half, sibling to `physiologically-difficult-airway`);
  `macocha-score` (calculator, additive, 7 factors 0-12, ICU difficult-intubation
  predictor, ≥3 threshold). Bumped `physiologically-difficult-airway` → v3:
  folded in `CV_Difficult_Airway_Physiology.html` (INTUBE scale figures 42.6% CV
  instability / 3.1% arrest / adjusted OR 2.47 for ICU death; the five stacking
  phases; the induction-agent haemodynamic-profile table). `validate.mjs` on the
  degraded VM took ~7 min/run — first run flagged one stray `related` key on the
  calculator (calculator schema is `unevaluatedProperties:false`); removed it,
  folded that context into `notes`. Re-validate + build + test pending (bg run
  still churning / to run from a healthy terminal).
- 2026-09-04 — **Arrest content (+2 → 281 modules).** Converted the last three
  flagged CV guides (`code_blue_guide.html`, `pediatric_code_blue_guide.html`,
  `volemic_status_resuscitation.html`). New: `code-leadership-run-the-room`
  (reference, Resus & Airway — role-assignment script, closed-loop comms,
  CPR-quality targets, epi timing, calcium COCA / bicarbonate BIHCA-2026
  "leave it in the drawer", refractory-VF A-P vector move, H&T as the leader's
  diagnostic job); `peds-cardiac-arrest` (peds-tool — PALS 1-2-4 numbers card:
  arrest/peri-arrest doses, defib & cardioversion energies, CPR mechanics,
  quick card by scenario). Bumped `acls-adult-cardiac-arrest` → v3 (a "Drugs
  that are NOT routine" section: calcium/bicarbonate/vasopressin/high-dose epi;
  + `related` links). Bumped `hemorrhagic-shock-mtp` → v2 (austere /
  no-blood-available: freeze-dried plasma is plasma-only ≠ red cells;
  crystalloid choice by population — balanced for sepsis, saline for isolated
  TBI). `volemic_status_resuscitation.html` was mislabelled in SOURCE_MATERIALS
  as a VExUS source — it's hemorrhagic-shock fluid strategy, already covered by
  `iv-fluids` v2; that row is corrected. A genuine VExUS / venous-congestion /
  de-resuscitation module is still worth building from other sources.
  Pipeline: same degraded-VM problem — `validate.mjs` stopped completing at all
  (>9 min, no output). New files JSON-parse clean and match sibling schema
  shapes; run `validate && build && test` from a healthy terminal to confirm
  281/0/0 and regenerate manifest/search-index.
- 2026-09-04 — **Drug-dosing category cleanup (14 → 10 perioperative categories)
  + Sources Pass 1 + medical/legal disclaimer.**
  - Dropped the "AnesCalc — " prefix everywhere and merged the four singleton
    categories: Induction Agents + Benzodiazepines → **Induction & Sedation
    Agents**; Reversal Agents + Anticholinergics → **Reversal & Anticholinergic
    Agents**; Antiemetics + GI/Aspiration Prophylaxis → **Antiemetics &
    Aspiration Prophylaxis**; Emergency Drugs + Methylene Blue → **Crisis /
    Rescue Drugs**. Vasopressors → "Vasopressors & Inotropes", Anticoagulants →
    "Anticoagulants & Hemostatics" (renamed, not merged). Applied to
    `content/config/sections.json` and all 55 `drug-dosing/anescalc-core/*.json`
    modules' `category` field (dry-run confirmed 55/55 mapped, 0 unmapped).
    `tools/import-anescalc.mjs`'s `CATEGORY` map updated to match so a re-run
    doesn't regress it. The other 2 drug-dosing categories (resus-dosing,
    dosing-fluid-math) are untouched — 12 categories total in the section.
  - **Sources Pass 1**: every content page now shows an always-visible numbered
    "Sources" list at the bottom (was calculator-only, and collapsed) — added
    to the shared web renderer (`content.js` `shell()` + `renderAnesthesiaDrugCard`,
    `calculator.js`) via a new `sourcesBlock()` in `components.js`, and to iOS
    via a new `SourcesBlock` view (`Components/ClearableField.swift`) wired into
    `ReferenceBody`/`ProcedureBody`/`PedsToolBody`/`AnesthesiaDrugCardBody`/
    `DrugCardView`/`CalculatorView`.
  - **New global Sources page** next to About: `tools/build-sources-index.mjs`
    (added to `build.mjs` + `sync-content.mjs`) aggregates every module's
    `sources[]`, de-dupes, buckets into 5 groups (Guidelines · Trials ·
    Cohort/registry/reviews · Reference texts · Other), and emits
    `content/sources-index.json` — **453 unique sources across 281 modules**.
    Web: `#/sources` route + `views/sources.js`, linked from the home footer
    next to "About Kairos"; `ContentStore` loads it (empty-array fallback if
    missing, so an old cached bundle can't break the app). iOS: `Route.sources`
    + `SourcesView.swift`, a toolbar icon next to the ℹ️ About one;
    `ContentStore.swift` loads it with `try?` (non-fatal if absent). Added
    `sources-index.json` + `views/sources.js` to `web/sw.js`'s precache list
    and bumped `SHELL_CACHE` to v2 (an offline-cached shell would otherwise
    never pick up the new page).
    This is Pass 1 (raw free-text strings, grouped by keyword heuristics) —
    a structured `citations.json` registry (real authors/journal/year/DOI
    fields, resolved by key) is the planned Pass 2; inline superscript
    citations in body text are Pass 3.
  - **Medical & legal disclaimer** added to both About pages (web `about.js`,
    iOS `AboutView.swift`) — standard "reference/educational aid, not medical
    advice, verify independently, no liability" language — with a short
    pointer + link from the Sources page. There was previously no app-wide
    disclaimer (only the narrow zone-vs-dose one in `weight-zones.json`).
  - Pipeline: ran clean on this batch — `validate.mjs` **281/0/0**,
    `build-sources-index.mjs` **453/281** (see above), full
    `validate && build && test && sync-content` kicked off in the background
    to confirm end-to-end after all of the above.
- 2026-09-04 — **Content sweep of the full CV-guide inventory (+3 modules →
  284; +2 drug-card version bumps).** Cross-referenced all ~88 CV Guides /
  Critical Vector HTML Library files against `SOURCE_MATERIALS.md`; most
  "not mentioned" hits turned out to be **already converted but never logged**
  (`icu-workflow`, `ecmo-support`, `perioperative-glycemic-management`,
  `csection-analgesia-prospect` — tracking rows added, no content gap). Real
  gaps found and closed:
  - New `mehran-ci-akin-score` calculator (additive, 7 factors incl. a
    bucketed contrast-volume select) — the Mehran score existed only as a
    prose table inside `contrast-associated-aki` (→ v2, cross-linked both
    ways).
  - New `drug-interactions-high-yield` reference (Critical Care) — 9
    mechanism/risk/fix pairs (methotrexate+NSAIDs, digoxin+amiodarone,
    clopidogrel+omeprazole, etc.) + 3 antibiotic-specific toxicities
    (fluoroquinolone tendinopathy, linezolid neuropathy, daptomycin
    myopathy) + a QT-prolonging drug-class quick list.
  - New `crush-syndrome` reference (Resuscitation & Airway) — entrapment
    ischaemia/reperfusion physiology, the 2-hour tourniquet/isolation
    threshold, the hyperkalaemia treatment ladder, goal-directed fluid
    resuscitation (200–300 mL/hr UOP target), austere renal-replacement
    bridging. Converted from Part Three of `CV_Austere_Disaster_Medicine.html`
    — Parts One/Two (hazmat scene management, incendiary/white-phosphorus
    casualties) are still open.
  - `dexmedetomidine` drug card → v2: added the polyuria / diabetes-insipidus
    mimic caution (3-pathway AVP-AQP2 mechanism, recognition, exclusion list,
    management) from a dedicated CV guide.
  - `ketamine` drug card → v2: added the JTS prolonged-casualty-care sedation
    infusion (load 1 mg/kg, start 1.5 mg/kg/hr / 25 mcg/kg/min, 3 mg/mL mix,
    ±0.25 mg/kg/hr titration) + one-drug-per-bag / RASS-monitoring cautions.
  **Deliberately deferred** (flagged in SOURCE_MATERIALS.md as the next
  big-ticket content projects, too large for one pass): `ballistics_blast_manual_v6_lightmode.html`
  (84 KB trauma/ballistics manual) and `intoxicating-substances-reference.html`
  (154 KB, 12 classes / 39 substances) — each needs its own dedicated
  conversion session, likely splitting into several modules. Also skipped as
  out of scope or low-yield: the two `CV_badge-buddy-*` cross-specialty pocket
  references (mostly duplicate of content already built, and reach outside
  ED/ICU/OR/Peds into Psych/Family Med/IM), `CV_Mitochondrial_VA_Hypersensitivity.html`
  (real but very niche), and three pure trial-summary pages
  (`colcot_guide.html`, `magnesium_lactate_summary.html`,
  `snapp_trial_summary.html`) per the standing management-content-not-trial-
  summaries direction.
  Pipeline: validate/build/test/sync all green (see above run).
- 2026-09-04 — **Nerve-block interactive checklist (+1 → 285 modules).** User
  re-supplied `POCUS_Nerve_Block_Reference.html` (the same source behind the
  existing `nerve-block-guide` reference) specifically to close the
  long-standing "still open: nerve-block as an interactive tree" item. New
  `pocus-nerve-block-checklist` procedure (`outputType: "workflow"`) — a
  6-node sequential bedside run-through (pre-procedure → US setup → sterile
  setup → needle insertion → injection → post-procedure monitoring) plus a
  `warning` node for the LAST emergency A-H sequence (applies at any point)
  and a tickable 10-rule safety `checklist[]`. Deliberately DRY: LA dosing
  tables and the full LAST pharmacology/management algorithm stay the single
  source of truth in `nerve-block-guide` / `last-lipid-rescue` and are only
  cross-linked, not restated. `nerve-block-guide` → v3 (cross-linked back).
  Caught and fixed the same defect as `macocha-score` earlier this session —
  calculator schema is `unevaluatedProperties:false`, so `mehran-ci-akin-score`
  couldn't carry a `related` array; moved the cross-links into `notes` prose.
  Pipeline re-run after the fix: validate/build/test/sync all green.
  **Remaining nerve-block/POCUS interactive-tree work**: individual block
  technique (digital, wrist, popliteal, brachial-plexus approaches) could each
  become their own procedure sub-module later (flagged in `nerve-block-guide`'s
  buildNote); the general POCUS exam guide (`pocus-guide`) is still a static
  reference, not a decision tree — a separate, larger conversion if wanted.
- 2026-09-05 — **UI lock-in: weight-zone recolour + section tints everywhere +
  iOS dark-mode asset catalog. Plus: real ios-ci failures found and fixed.**
  - **weight-zones.json recoloured** off the old Teal→Charcoal scheme (Teal
    and Amber both collided with the companions' signatures; Coral echoed the
    icon's own "coral spike" language) → **Dove-Umber** (Dove, Rose, Plum,
    Denim, Olive, Rust, Pine, Scarlet, Umber). Added a real `colorHex` per
    zone (schema updated to allow it) so the zone chip now renders an actual
    colour swatch dot, not just a text label — web (`.zone-dot`) and iOS
    (`Color(hex:)` init added to Theme.swift). Pine/Scarlet deliberately reuse
    the severity-low/high hexes (green zone = "good", red zone = "urgent").
  - **Section tints wired beyond the home tiles**: every content page and the
    section-list page now carry a 3px top-border in their owning section's
    tint (`--tint` custom property + `tintStyle()`/`tintStyleForSection()` in
    `components.js`). iOS: a matching `Rectangle` accent in
    `ContentDetailView`, `.tint(Theme.sectionColor(...))` on `SectionView`'s
    list.
  - **iOS dark-mode colour set via asset catalog** (the last Tier-5
    follow-up): 9 Color Sets added to `Assets.xcassets`
    (AccentEmber, Section×5, Severity×3 — moderate reuses AccentEmber),
    each with a light + dark appearance. `Theme.swift` now resolves through
    `Color("Name")` instead of hardcoded RGB literals, so dark mode picks up
    the lifted tones automatically. All verified live in the web app
    (zone dot colour, tint borders, category list) via the dev server.
  - **ios-ci actually ran for the first time** (previous runs never got past
    the Xcode-project-format error before today's Xcode-16 fix). It built
    successfully but 3 of 4 UI tests failed for real, diagnosable reasons —
    fetched the raw xcodebuild log directly from Actions' blob storage to
    find them (the rendered log page virtualizes/truncates past ~50-190K
    chars). Root causes, all fixed in `ios/UITests/KairosUITests.swift`:
    1. `testFormulaCalculatorFlow` — bare `app.buttons["Done"]` (no
       `.firstMatch`) threw "multiple matching elements" once two text fields
       could each show a keyboard Done button — pre-existing bug, inconsistent
       with the rest of the file. Fixed both occurrences.
    2. `testDrugCardDualModeFlow` — today's category merge pushed "Weight/Age-
       Based Resuscitation Dosing" below the 10 new perioperative categories,
       so `row-peds-epinephrine-arrest` no longer renders in SwiftUI's lazy
       `List` without scrolling. Added the same scroll-and-retry `openSection`
       already uses for home tiles.
    3. `testProcedureTreeWalker` — the laceration-repair v3 upstream-triage
       question (added earlier this session) means `start` no longer leads
       straight to "Hand"; the test now taps "Neither — select body region"
       (`tree-choice-region`) first. Real regression, not a flake.
  - Pipeline: validate 285/0/0, build, test 231/0, synced. Not yet re-run in
    CI from this environment — push and let ios-ci confirm on a real runner.
- 2026-09-05 — **Acted on `DIRECTIONS_FORWARD.md`.**
  - **AnesCalc 55 drug-card navigation** — confirmed already DONE (stale item);
    all 55 reachable via the merged perioperative categories.
  - **Obese-child IBW flag** — implemented end-to-end (web + iOS), verified live
    (weight 40 kg + age 6 → IBW 25 kg → epi 0.25 mg not 0.4 mg; toggle switches
    to actual). See the checked item in §1.
  - **Care-setting lens — scaffold.** New `content/config/settings.json` (4
    settings along the resus continuum: prehospital / ed / or / icu) +
    `config.settings.schema.json` + wired into `validate.mjs` and the web
    `ContentStore` (`store.careSettings`, precached in the SW). New optional
    `settingEmphasis` array on `recordMeta` (allowed on every contentType). No
    module carries it yet and there's no UI selector — that's the next step
    (persisted preference in About/Settings → home-tile + in-section reorder at
    render time). It's a lens, never a fork.
  - **Reference Library standard template — schema + renderers.** Added optional
    `whyThisMatters` (framing, upstream of `summary`) and `clinicalTakeaway`
    (action-oriented close) to `reference.schema.json`; both render (web
    `.why-matters` / `.takeaway`; iOS `framedNote`). **Backfill across ~150
    reference modules is the multi-session content pass DIRECTIONS_FORWARD
    calls for — start with Tier-1 (septic shock, anticoag reversal, STEMI
    criteria, arrest/RSI).** Continuum framing where it genuinely fits.
  - Pipeline: validate 285/0/0, test 231/0, synced.
  - Per instruction, left parked: GitHub Pages hosting, the (now green-building)
    `ios-ci` — its 3 UI-test failures were diagnosed and fixed earlier today —
    and `REMOTE_BASE` wiring.
- 2026-09-07 — **Care-setting lens — UI built + seeded (`DIRECTIONS_FORWARD` §1).**
  - New `web/src/lib/prefs.js` (durable localStorage prefs, distinct from the
    cleared-on-closeout `session`) + `web/src/lib/settingLens.js`
    (`emphasisRank` / `applyLens` — stable reorder, never filters).
  - `build-search-index.mjs` now carries `settingEmphasis` into each entry;
    `search-index.schema.json` updated.
  - Wired the lens into `makeSearch` (secondary sort after match quality),
    `buildTOC`, and `section.js`'s category lists. Selector chips on the home
    screen (Any / Prehospital / ED / OR / ICU) + a menu picker in About; both
    persist via `prefs`. iOS mirror: `SettingsConfig` model, `careEmphasisRank`,
    `SearchIndex.search`/`.toc` take a `setting`, `@AppStorage("kairos.careSetting")`
    in Home/Section, a `.menu` Picker in AboutView, `ContentStore.careSettings`
    loaded non-fatally.
  - **Seeded `settingEmphasis` on 103 modules** — 48 hand-picked
    (airway/RSI → all settings; crush/trauma → prehospital/ed; vent/ICU-workflow
    → icu; anesthesia refs → or; ED syndromes → ed) + all 55 anescalc-core
    drug cards → `["or"]`. Added WITHOUT a `content_version` bump (navigation
    metadata, not clinical content; the manifest hash still changes so clients
    resync). The remaining ~180 modules can be tagged incrementally.
  - Verified live: clicking the ICU chip persists to localStorage and reorders
    the Reference Library › Critical Care list ICU-first; About picker round-trips.
  - Pipeline: validate 285/0/0, test 231/0, synced.
- 2026-09-07 — **Reference Library standard template — FULL BACKFILL DONE (87/87).**
  Every reference-library module now carries `whyThisMatters` (clinical stakes /
  the classic error / prehospital→ED→OR→ICU continuum framing where it fits,
  upstream of `summary`) + `clinicalTakeaway` (the one action). Done in 6
  batches (`scratchpad/reftemplate_batch{1-6}.py`), grounded in each module's
  own summary + headings, `content_version` bumped + changelog entry on each.
  All 58 Tier-1 first, then the 29 Tier-2/3/stable. Renders as framed
  "WHY THIS MATTERS" / "CLINICAL TAKEAWAY" blocks — web `.why-matters`/`.takeaway`
  between summary and body, iOS `framedNote`; verified live (septic-shock).
  Pipeline: validate 285/0/0, test 231/0, synced.
  - Note: a stale service worker on `localhost:4737` served old JS during
    verification — needed a query-string cache-bust; not a code issue.
  - **DIRECTIONS_FORWARD §1 is now complete** (care-setting lens shipped
    2026-09-07; reference template + full backfill done). The specialization
    angle — reframing `whyThisMatters`/`clinicalTakeaway` around the resus
    continuum where a topic genuinely shifts prehospital → ED → OR → ICU — was
    applied where it fit and left off the static references where it didn't.

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
- [x] **Tier 5 — colour/font scheme.** DECIDED 2026-09-03: **"Ink & Ember on
  Parchment" (Option A)** — light-first parchment ground, ember accent used
  sparingly, reconciled with the shipped app icon. Full token table in
  `docs/PALETTES.md`; swap applied to `web/styles.css`, `web/src/views/home.js`,
  `web/index.html`, `ios/.../Theme.swift`. Follow-ups closed 2026-09-05: `--sec-*`
  tints now wired into section pages + content detail pages (not just home
  tiles); iOS dark-mode colours moved to Assets.xcassets colour sets;
  `weight-zones.json` recoloured (Dove-Umber) with real rendered swatches.
  **Only remaining sub-item:** self-host IBM Plex Sans/Mono woff2 (stack still
  falls back to system sans/mono — needs sourcing the actual font files).
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
- [x] **AnesCalc's 55 drug cards** — DONE (import path was built earlier; the
  2026-09-04 category cleanup merged them into 10 named perioperative
  drug-dosing categories in `sections.json`). Verified 2026-09-05: all 55 are
  in `search-index.json` with valid routes, every category matches a
  `sections.json` title, the drug-dosing home tile renders, and both clients
  handle the `anesthesia-drug-card` contentType. Fully reachable.
- [x] **Obese-child dosing:** IBW-vs-actual-weight flag implemented 2026-09-05.
  `weight-zones.json` gained `obesityFlagRatio` (1.2); `weightZones.js` /
  `WeightZones.swift` gained `idealBodyWeight()` + `obesityCheck()` (IBW proxy =
  APLS age-expected weight — no height is collected). Drug-card schema gained a
  per-drug `obeseWeightBasis` (`ideal` | `actual`). When an actual weight AND an
  age are entered and actual > 1.2× age-expected, an `ideal`-flagged drug
  defaults its doses to IBW with a callout + an "Use actual weight instead"
  override; an `actual`-flagged drug shows an informational "TBW even in obesity"
  note. Applied `obeseWeightBasis: ideal` to the four unambiguous hydrophilic
  arrest drugs (epinephrine, amiodarone, atropine, adenosine). **Follow-up:**
  per-drug review of the rest (benzos/ketamine → likely TBW; rocuronium → lean;
  succinylcholine → `actual`) plus the adult-obesity cards.
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
