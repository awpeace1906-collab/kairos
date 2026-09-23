# Kairos — Open Items & Sources Needed

Living tracker. Two lists:
1. **Things to address** — engineering/design work, gaps, and decisions still open.
2. **Sources to provide** — material only you can supply (primary papers, licensed
   or original content, existing Critical Vector / AnesCalc assets) before the
   affected content can be finalized.

Last updated: 2026-09-23 — see the fresh-look audit entries in the Progress
log below for current state. The **Progress log** further down is an
append-only chronological record; trust it over any summary above it for
"what happened when."

## ▶ NEXT SESSION — start here (2026-09-23)
State: **431 modules**, pipeline green (validate 431/0, build/sync/test
281/0), iOS `TEST SUCCEEDED` (10/10 EngineTests). The original 2026-09-14
content audit closed at Batch 5 (384 modules). The **fresh follow-up gap
audit** (4 parallel domain agents, 2026-09-15) that found 49 genuine,
non-duplicate candidate gaps is now **fully closed too** — Batch 6 (→ 398),
Batch 7 (→ 413), and Batch 8 (→ 431) shipped all 49 candidates across three
batches. See the progress log entries below for full per-batch lists.
**No queued backlog remains from either audit cycle** — the next content
work starts from a fresh look, the same way this cycle itself began.

Still open from the prior cycle:
1. **UI Phase 4 — full visual pass.** Open-ended, unchanged since 2026-09-14.
2. **Things only the user can supply**, still genuinely open: the local
   antibiogram (empiric-antibiotic agent selection), GRACE 2.0's proprietary
   coefficients, defibrillator pad transition weight and LMA/blade sizing for
   your specific device models, and a storyboarding pass on deeper procedure
   decision-tree branch logic (suture technique / fracture patterns /
   nerve-block sub-techniques / POCUS exam trees).
3. **Xcode `DEVELOPMENT_TEAM` — actively being set up (2026-09-15).** User
   confirmed a paid Apple Developer account; next step is getting the Team ID
   from developer.apple.com/account into `ios/project.yml` so a real-device
   build/install actually works. This is now the blocking step for getting
   the ContentStore fix below (and everything else built this session) onto
   the user's phone at all — see that progress log entry for why.
4. ~~American English normalization pass~~ — **DONE 2026-09-16**, see the
   progress log entry below (1,025 word edits across 179 files).
5. **Depth/media/sources expansion — requested 2026-09-16, NOT started,
   needs scoping decisions first.** User asked to "dive into greater detail
   on ALL subjects" with "complete, DETAILED procedure instructions with
   instructional images or videos" and "even better sources researched."
   Current corpus baseline for scoping: **431 modules / 273,708 prose words /
   median 543 words per module** (references ~160k words are the meatiest;
   calculators are thinnest, with the 12 thinnest all 93-127 words —
   `shock-index`, `apfel-ponv`, `killip-classification`, `aims65`, `gcs`,
   `bisap`, `hunt-hess`, `abcd2`, `qsofa`, `nexus-cspine`, `curb-65`,
   `sirs`). Meaningfully deepening all 431 is roughly several times the
   total content volume produced across Batches 1-8 combined — it is a
   multi-session program, not a batch. **Two blockers to settle before any
   building starts:**
   - **Media has no schema or client support.** `body[]` block types are
     only `heading|text|list|table|callout` — there is no image, video, or
     diagram type, and neither client can render one. The one existing
     visual precedent is the calculator `plot` field (semilogy nomogram →
     web SVG in `calculator.js` `nomogram()`, iOS `Canvas` in
     `NomogramView.swift`), used by exactly one module
     (`apap-nac-dosing`). That precedent is the cheapest credible path: a
     new `diagram` body block carrying original inline SVG would render
     natively on both platforms, stay offline-first, stay tiny, and be
     theme-aware and license-clean.
   - **Licensed raster/video media is an external dependency, not a build
     task.** Procedure photos and instructional video cannot be lawfully
     copied from textbooks, journals, or YouTube, and bundling video fights
     the offline-first architecture and both clients' size limits. Options
     are (a) original SVG/vector diagrams authored in-repo, (b) outbound
     deep links to open-access resources — breaks offline use, (c)
     user-supplied or properly licensed assets. This is the same
     dependency already logged for the POCUS/ECG/nerve-block media
     libraries.
6. **User notes captured 2026-09-21 — verbatim backlog, not yet scoped.**
   Sent mid-session while the thoracentesis depth pass was in flight. Split
   into the two kinds of work they actually are:

   *Cross-cutting formatting/QA passes (affect many modules):*
   - **Eliminate British English** — a re-sweep. The 2026-09-16 scripted pass
     covered `content/`, but (a) newly authored modules can reintroduce
     spellings (the thoracentesis v2 draft did: `favor`, `color`, `liter`,
     `milliliters`, `centimeters`, `analyzed` — all caught and fixed before
     commit), and (b) the pass never covered `web/src/`, `ios/Sources/`, or
     `docs/`. Needs: a re-run over `content/`, an extension to UI strings,
     and ideally a CI guard so it cannot regress.
   - **Nested lists / sub-steps.** Many numbered steps contain a paragraph
     that is really a list of sub-steps. The `list` block type is flat, and
     procedure `nodes[].body` is a plain string — so there is currently no
     way to express a sub-list at all. This is a **schema + both-clients
     change**, the same shape of work as the `diagram` block: either a
     nested `items[]` (items that may themselves be lists) or a
     `sub-list`/`steps` block type. Should be settled BEFORE the bulk of the
     depth expansion, because every deepened module will want it.

   *Content restructuring:*
   - **CICO — subdivide.** Front-of-neck access and each individual
     procedure should each be its own subsection within CICO rather than one
     flat run.

   *New content to add:*
   - **IBW & adjusted body weight** — calculator/reference (check against
     AnesCalc first; must not duplicate).
   - **McConnell's sign** — ensure it is present and correctly described
     (RV free-wall akinesis with apical sparing, acute PE).
   - **TAPSE** — measurement technique: apical 4-chamber as the ideal view,
     M-mode through the lateral tricuspid annulus.
   - **Hyperviscosity syndrome.**
   - **irAE (immune-related adverse events)** — wants a nomenclature
     image/diagram (candidate for the new `diagram` block).
   - **Transplant-related emergencies** — rejection, plus an
     infection-timeline figure (post-transplant timeline by period; another
     `diagram` candidate).

   *Reference photos supplied 2026-09-21 — transcribed here because the
   photos themselves live only in the chat transcript.* Four phone photos of
   a lecture deck. Treat as a POINTER to the underlying clinical content,
   not as material to reproduce: build original modules and verify every
   item against a primary source before shipping (the deck is someone
   else's work, and at least one slide looks garbled — see the note below).

   1. **Biologic/immunotherapy nomenclature.** RESEARCHED 2026-09-21
      against the primary WHO INN documents (INN Working Doc. 17.416,
      26 May 2017, Tables 1 and 2; INN Working Doc. 21.531 / 22.542 for the
      2021-22 revision). DECISION, per the user: **keep the legacy
      species/target scheme — it decodes the several hundred drugs actually
      in use, and rough day-to-day identification is the whole point.**
      Frame it as a decoder for existing names, with the current scheme
      noted so nobody applies it to a drug approved last year.

      LEGACY scheme (WHO Table 1 = prefix + substem A + substem B +
      `-mab`). Substem A, TARGET CLASS: `-b(a)-` bacterial · `-am(i)-`
      serum amyloid protein (SAP)/amyloidosis · `-c(i)-` cardiovascular ·
      `-f(u)-` fungal · `-gr(o)-` skeletal-muscle-mass-related growth
      factors and receptors · `-k(i)-` interleukin · `-l(i)-`
      immunomodulating · `-n(e)-` neural · `-s(o)-` bone · `-tox(a)-`
      toxin · `-t(u)-` tumor · `-v(i)-` viral. Substem B, SOURCE SPECIES:
      `-a-` rat · `-axo-` rat/mouse · `-e-` hamster · `-i-` primate ·
      `-o-` mouse · `-u-` human · `-xi-` chimeric · `-xizu-`
      chimeric-humanized · `-zu-` humanized · `-vet-` veterinary.

      Four corrections to the photographed slide, each checked against the
      WHO table: `-ci-` is CARDIOVASCULAR, not "circulation"; `-gro-` is
      specifically skeletal-muscle-mass-related growth factors, not growth
      factors generally; `-ki-` (interleukin) and `-li-`
      (immunomodulating) are two DIFFERENT targets, not one "interleukin
      or immune" bucket; and the slide omits `-am(i)-`, `-tox(a)-`,
      `-n(e)-` and `-v(i)-` entirely. The slide's `-cept` (a receptor-Fc
      fusion protein — etanercept, aflibercept) is correct but belongs to
      a different stem family from `-mab`, not a variant of it. Worth
      keeping, worth labeling as such.

      WHAT CHANGED, and why the card has to say so. At the 64th INN
      Consultation (2017) the Expert Group DISCONTINUED substem B, the
      source infix, except `-vet-`. Two stated reasons: unique
      pronounceable names were getting hard to find, and the species infix
      was being used as a marketing tool — particular infixes treated as
      "better" with no supporting data. Target substems were respelled at
      the same time: `-ba-`, `-ami-`, `-ci-`, `-fung-`, `-gros-`, `-ki-`,
      `-li-`, `-ne-`, `-os-`, `-toxa-`, `-ta-` (tumor, replacing `-t(u)-`),
      `-vet-`, `-vi-`. Then at the 73rd INN Consultation (October 2021)
      `-mab` itself was retired for NEW names and split four ways by
      molecular form: `-tug` full-length unmodified immunoglobulin ·
      `-bart` full-length artificial, one or more engineered regions ·
      `-ment` monospecific fragment derived from a variable domain ·
      `-mig` bi- or multi-specific immunoglobulin of any format. Existing
      names were not renamed, which is precisely why the legacy decoder
      stays useful.

      Build shape: a reference module with a `diagram` (name anatomy —
      prefix / target / species / stem as labeled segments of a real
      example) plus a table per substem list, cross-linked to the irAE
      content rather than restating it.
   2. **Febrile transplant recipient — timing table.** As photographed:
      Week 1 → most likely surgical site infection / catheter / aspiration;
      high suspicion donor-derived infection. Month 1-3 → opportunistic
      (CMV), UTI, community; high suspicion BK virus, Listeria. Month 3-6 →
      opportunistic, community-acquired; high suspicion Aspergillus,
      Nocardia. >6 months → community-acquired; high suspicion
      chronic/recurrent CMV. **Resolve against Fishman NEJM 2007 (and its
      updates) before building** — the canonical periods are <1 month
      (nosocomial / surgical / donor-derived), 1-6 months (opportunistic,
      with PJP and CMV prophylaxis shifting the curve), and >6 months
      (community-acquired) — the slide's 1-3 / 3-6 split and its
      "Opportunistic (CMV) UTI, Community" row read as compressed lecture
      shorthand, not as the source of truth. This timeline is the
      `diagram` candidate the user asked for.

      NEWER SOURCES, FOUND 2026-09-21 because the user asked (the lecture
      was given Friday). Three things supersede or qualify the 2007 figure,
      and the second changes what the card should actually say:

      - **Fishman JA. Infection in organ transplantation. Am J Transplant.
        2017;17(4):856-879.** The author's own update and the direct
        successor to the 2007 NEJM piece — same three-period framework, but
        the emphasis moves to prophylaxis DELAYING rather than preventing
        disease, so late CMV appears after prophylaxis stops rather than
        inside the 1-6 month window. Cite this for the structure, not the
        2007 figure. Also the source for "net state of immunosuppression"
        as the risk determinant that interacts with epidemiologic exposure.
      - **van Delden C, et al. Burden and timeline of infectious diseases
        in the first year after solid organ transplantation in the Swiss
        Transplant Cohort Study. Clin Infect Dis. 2020;71(7):e159-e169.**
        The modern empirical challenge, and the most useful finding for a
        bedside card: of 2,761 recipients with 12 months of follow-up, 55%
        had an infection (3,520 events), and **bacteria caused 63% and
        predominated THROUGHOUT the year** (Enterobacteriaceae 54%), while
        the classic opportunists were rare — CMV 6%, Aspergillus fumigatus
        1.4%. Herpesviruses were 51% of 1,039 viral infections; Candida 60%
        of 263 fungal ones, mostly digestive-tract in liver recipients.
        Implication: in the current prophylaxis era the honest first move
        on a febrile transplant recipient at almost any timepoint is a
        bacterial workup. The timeline tells you what ELSE to think about,
        not what is most likely.
      - **AST Infectious Diseases Community of Practice guidelines, 4th
        edition. Clin Transplant. 2019;33(9)** (special issue) for
        operational specifics — donor-derived infection, surgical site
        infection, safe living. Newer companion: van Delden C, et al. The
        Swiss Transplant Cohort Study: implications for transplant
        infectious diseases research. Transpl Infect Dis. 2025 (PMID
        40127403). NOTE: the AST 2024 "Post-transplant Infectious Diseases
        Considerations" PDF on myast.org turned out to be an annotated
        bibliography, not a timeline chapter — do not cite it for the
        periods.

      So the diagram carries the three periods AS A DIFFERENTIAL PROMPT,
      with a standing caveat that bacteria dominate at every point in year
      one. The slide's "Most Likely / High-Suspicion" column split is a
      good format worth keeping; its contents need reconciling against the
      above.
   3. **Stem cell transplant (HSCT) complications by day 100.** <100 days:
      acute GVHD, CMV reactivation, engraftment syndrome. >100 days:
      chronic GVHD, bronchiolitis obliterans, cardiovascular disease,
      secondary malignancies, endocrinopathies, autoimmune cytopenias,
      iron overload, VTE.
   4. **GVHD.** Acute vs chronic split at day 100; rare in solid organ
      transplant, common in HSCT; occurs when immune cells transplanted
      from a non-identical donor recognize the recipient as foreign and
      attack. Needs the bedside half the slide does not have: what it looks
      like (skin / gut / liver), grading, and what the ED/ICU actually does
      about it.

## Progress log
- 2026-09-23 (later) — **User notes backlog closed: 437 -> 440 modules.**
  Every item from the 2026-09-21 list is now either built or verified as
  already present.
  - **TAPSE added, McConnell's corrected** (`pocus-guide` v4). TAPSE was
    absent from the entire corpus; it now carries its acquisition technique
    as a 3-level nested sub-list — apical 4-chamber, M-mode through the
    LATERAL tricuspid annulus as parallel to its motion as possible (it is
    angle-dependent), total excursion end-diastole to end-systole, <17 mm
    means RV systolic dysfunction, with the caveat that it reads one wall in
    one direction. **McConnell's was already present and was overstated:**
    v3 called it "specific for acute PE", and it is specific but not
    pathognomonic — RV infarction and other acute RV pressure loads produce
    the same free-wall akinesis with apical sparing. Corrected.
  - **`hyperviscosity-leukostasis`** (NEW). One card covering three
    mechanisms, because the bedside problem is undifferentiated: paraprotein
    (IgM in Waldenström, up to 30%; myeloma 2-6%; uncommon below ~4 g/dL),
    leukostasis (an AML problem — rare in ALL/CLL at the same counts, and
    possible at WBC as low as 50,000), and symptomatic polycythemia. Normal
    viscosity ~1.5 cP, symptoms usually above 4, most symptomatic above 6.
    Mortality >50% untreated, 10-20% with prompt apheresis plus
    cytoreduction. The two danger callouts are the reflexes rather than the
    knowledge: **do not transfuse red cells before apheresis**, and do not
    diurese. Also covers the lab artifacts (pseudohyponatremia, spurious
    hyperkalemia) that have caused real treatment errors.
  - **`immune-related-adverse-events`** (NEW). Written for the
    non-oncologist, ordered by LETHALITY rather than frequency, because the
    card's job is to make the reader send a troponin: ICI myocarditis is
    ~1% but kills 40-50%, typically around 30 days in, with a normal
    ejection fraction not excluding it. Three documented misses are called
    out explicitly — the myocarditis/myositis/myasthenia overlap, the fact
    that toxicity can appear months after the last dose, and endocrine irAEs
    being the exception to the steroid reflex (replace the hormone, do not
    immunosuppress). Cross-links to `biologic-drug-nomenclature`, which is
    what lets a reader identify an unfamiliar -mab as an immunotherapy at
    all.
  - **`transplant-rejection-graft-dysfunction`** (NEW), the companion to
    `febrile-transplant-recipient`. Framed as a three-way differential —
    rejection, infection, drug toxicity — because they are indistinguishable
    at the bedside and pull treatment in opposite directions. Leads with the
    cheapest discriminator (send a calcineurin inhibitor trough on every
    unwell transplant patient) and the two commonest precipitants
    (non-adherence, a new CYP3A4-interacting drug). Organ sections lead with
    the trap: the denervated heart has no angina and does not answer to
    atropine; the lung recipient's home spirometry is the earliest sign and
    lung has the highest rejection rate of any organ.
  - **IBW/adjusted body weight was already built** (`adjusted-body-weight`)
    and computed four weights correctly — but said almost nothing about
    WHICH one to use, which is the actual bedside question. v3 adds
    per-formula guidance, a which-weight-for-what summary (tidal volume uses
    IDEAL at 6 mL/kg; succinylcholine, resuscitation drugs and defibrillation
    use ACTUAL; propofol induction uses LEAN; adjusted is the routine
    default), a BMI >= 40 prompt to check drug-specific dosing, and search
    keywords — it had none, so it was hard to find by the phrase anyone
    would type.
  - Verified: validate 440/0, check-spelling clean, tools 286/0, and all
    four new/edited pages rendered — including the TAPSE sub-list resolving
    to three levels with lower-alpha markers, which is the nested-list
    structure doing real work in real content rather than in a test.
- 2026-09-23 — **CICO subdivided into a category of five, and both requested
  diagrams built.** 431 -> 437 modules.
  - **New category: Procedures / CICO & Front-of-Neck Access.** CICO
    previously existed only as one node inside `airway-management-flow` and
    as the opening step of the cricothyroidotomy card; there was no place
    that answered "which technique, for this patient", and three of the four
    techniques had no coverage at all. Now five subsections:
    `cico-declare-and-choose` (entry/decision — recognition, the attempt
    ladder, role assignment, technique choice), `cricothyroidotomy`
    (scalpel-finger-bougie, the adult default), `cannula-cricothyroidotomy`,
    `seldinger-cricothyroidotomy`, and `peds-front-of-neck-access`
    (cross-listed into Peds Resuscitation & Decision Support).
  - **Two clinical corrections came out of the research, both against
    current guidelines rather than the previous content.**
    1. **DAS 2025 deletes the palpable/impalpable incision fork.**
       `cricothyroidotomy` v2 taught DAS 2015: transverse stab if you can
       feel the membrane, vertical incision only if you cannot. DAS 2025
       (Br J Anaesth 2026;136:283-307) standardizes a midline VERTICAL skin
       incision in EVERY neck, up to 8 cm, caudad to cephalad — because
       palpation is unreliable even in controlled conditions, a decision
       point mid-crisis costs time, and vertical exposes more either way.
       Equipment is likewise fixed (size 10 blade, bougie, 6.0 cuffed tube)
       on the explicit rationale that choice under pressure degrades
       performance. The card states the change rather than quietly making
       it, since most readers were trained on the old fork.
    2. **Needle cricothyroidotomy is no longer acceptable in infants.** The
       2024 ESAIC/BJA joint guidelines state that surgical cricothyroidotomy
       AND percutaneous needle cricothyroidotomy are not suitable options in
       neonates and infants — surgical tracheotomy is first-line. Roughly
       1-8 years: surgical tracheotomy preferred where a trained operator is
       present. 8 years and up: the adult technique. This contradicts the
       needle-first teaching most clinicians received, so the peds card
       leads with it.
  - The cannula card is written as an honest appraisal rather than a neutral
    how-to, with NAP4's roughly 60% failure rate and the 18% vs 83% porcine
    rescue-oxygenation figures in a warning node up front — the technique's
    main danger is being chosen for the wrong reason. Its exhalation /
    barotrauma physiology gets a step of its own.
  - **Diagram 1 — "Anatomy of a biologic's name"** in the new
    `biologic-drug-nomenclature` reference module. Four labeled segments of
    a real legacy name (tras + tu + zu + mab) over a second row showing the
    species slot struck out, so the 2017 change is seen rather than read
    about. Built from the primary WHO documents; the four slide errors
    recorded in item 6 are corrected, and the card is framed as a legacy
    decoder with a stated expiry date, per the user's call to keep it for
    rough day-to-day identification.
  - **Diagram 2 — post-transplant infection timeline** in the new
    `febrile-transplant-recipient` reference module. Three period bands over
    a full-width "BACTERIA — 63%, at every point in year one" bar, with a
    dashed arrow for prophylaxis pushing disease later. The bar is the whole
    point: the Swiss Transplant Cohort Study finding is what stops a reader
    treating the periods as a probability ranking and hunting CMV while the
    patient has a line infection.
  - The new spelling guard earned itself: it caught four British spellings
    in this batch's own freshly written prose (millilitres, centre, <!-- spelling-ok -->
    millimetres, centimetres) before commit. <!-- spelling-ok -->
  - Verified: validate 437/0, check-spelling clean, tools tests 286/0, and
    both diagrams rasterized and inspected — no viewBox overflow, no label
    collisions beyond same-paragraph line spacing.
- 2026-09-21 — **American English became a pipeline rule; nested lists
  shipped; two research questions answered.** Four commits, all pushed.
  - **Spelling guard.** `tools/spelling.mjs` (rule table) +
    `tools/check-spelling.mjs` (sweep / `--fix`), wired into `npm run ci`
    and into `content-ci`, whose path filters now include `web/`,
    `ios/Sources/` and `docs/` so a British spelling in a Swift or JS
    string actually trips the build. **233 findings across 80 files** — the
    user was right that there were "multiples"; the 2026-09-16 pass only
    ever looked at `content/`. Fixed 221 automatically plus two by hand:
    "goes urgently to theatre" became "to the OR" (the mechanical fix gives <!-- spelling-ok -->
    "theater", British idiom in American spelling — worse), and
    "Amethocaine (tetracaine) gel" became "Tetracaine gel (AMETOP)" with <!-- spelling-ok -->
    the British name moved to `keywords`. Design points worth remembering:
    `-ise`/`-yse` use an explicit stem allowlist (a blanket rule mangles
    advertise/comprise/exercise/expertise/franchise/premise/promise/
    supervise/surprise); the `-yse` suffix set omits `-es` because
    "analyses"/"dialyses"/"paralyses" are correct American noun plurals;
    `sources`/`changelog`/`buildNote` are skipped; and `aliases`/`keywords`/
    `tags` are REPORTED BUT NEVER REWRITTEN, because a British spelling or
    INN name there is what makes the module findable. Caught one real
    compounding bug pre-commit: rules whose British form is a prefix of the
    American one re-fire every pass (enrollment -> enrolllment ->
    enrollllment) and now carry a negative lookahead.
  - **Nested lists.** `common.schema.json#/$defs/listItem` is recursive and
    backward-compatible — a plain string is still a leaf, so no existing
    list needed migrating. `$defs/nestedList` wraps items with an `ordered`
    flag; the reference `list` block gained `ordered`; procedure nodes
    gained `substeps`, which is the thing that did not exist before (a
    numbered step whose content is itself a sequence). Depth capped at 3 by
    a `validate.mjs` invariant rather than in the schema, since JSON Schema
    can express recursion but not a bound on it — guard verified by feeding
    it a 4-deep list. Both renderers recurse (`renderList` in content.js,
    `ContentListView.swift`) with markers changing per level
    (disc/circle/square, 1./a./i.) because screen width is the scarce
    resource, not indentation. Web markers are set explicitly at every
    level: a step's substeps list lives inside `ol.nodes`, where the UA
    rule `ol ul` silently starts level 1 at `circle` and makes it
    indistinguishable from level 2 — found by reading computed styles, not
    by looking. Thoracentesis v3 is the first use; its three prose-faked
    lists are converted and the fluid-studies step is now the two-level
    hierarchy it always was on the page.
  - **Nomenclature research.** Answered against the primary WHO INN
    documents rather than the slide. Kept the legacy species/target scheme
    per the user's call, with four corrections to the photographed slide
    and the 2017 and 2021 revisions documented. Detail in item 6 above.
  - **Newer than Fishman 2007.** Found: Fishman's own 2017 AJT review is
    the direct successor, and the Swiss Transplant Cohort Study (CID 2020)
    is the modern empirical challenge — bacteria caused 63% of infections
    and predominated throughout year one, while CMV was 6% and Aspergillus
    1.4%. That changes the card's lead: the timeline is a differential
    prompt, not a probability ranking. Detail in item 6 above.
  - Verified: validate 431/0, check-spelling clean, tools tests **286/0**
    (5 new list tests), iOS **16/16** (6 new `ListItem` decode tests — the
    engine tests would never have exercised the heterogeneous string/object
    array), staleness 0 overdue, and the rendered page at 375px with no
    horizontal scroll.
- 2026-09-21 — **Depth expansion begun: `thoracentesis` v1 → v2, the first
  module rebuilt under the "greater detail + better sources" directive.**
  Sequencing follows the user's own call ("Build the diagram first. Then the
  deep dive") — the `diagram` block shipped 2026-09-16, so this is the first
  content to use it in anger. Target chosen because geometry is the crux of
  the procedure (so a diagram earns its place) AND the text was thin (479
  words, 5 outline steps).
  - **Now 10 fully-specified steps, ~3,200 prose words**, a 13-item
    checklist (was 5), and a `noteTemplate` (following the
    `laceration-repair` precedent). Validate 431/0, build/sync green, test
    281/0.
  - **Ten primary sources replace two**, all WebSearch/WebFetch-verified
    against the originals rather than recalled: BTS 2023 guideline + BTS
    2023 pleural procedures clinical statement, Boccatonda 2024 (Diagnostics
    14(11):1124), Gordon 2010 (Arch Intern Med 170(4):332-9), Feller-Kopman
    2007 (Ann Thorac Surg 84(5):1656-61), Ault 2015 (Thorax 70(2):127-32),
    Hibbert 2013 (Chest 144(2):456-63), Helm 2013 (Chest 143(3):634-9),
    Mohammed 2024 (Medicine 103(1):e36850), Thomsen 2006 (NEJM).
  - **Three substantive clinical corrections to v1**, each a live
    teaching-point error rather than a gap:
    1. **The 1-1.5 L volume cap is retired** in favor of symptom-limited
       drainage. v1 taught the cap as a hard limit. Feller-Kopman 2007: in
       185 large-volume taps, radiographic REPE was 2.2%, clinically silent
       in every case, and NOT associated with volume, pleural pressure, or
       elastance; Ault 2015 puts REPE at 0.01% across 9,320 procedures.
       Stop on symptoms (chest tightness / cough / dyspnea) or pleural
       pressure below about -20 cm H2O, not on a number.
    2. **Routine coagulopathy correction before an ultrasound-guided tap is
       no longer supported** (Hibbert 2013, BTS 2023). Bleeding was 0.2% in
       9,320 procedures. v1 was silent; the card now says explicitly that
       transfusing to "cover" a tap trades real transfusion risk for a risk
       that is not measurably there.
    3. **The lateral-6 cm intercostal-artery rule was missing entirely.**
       Helm 2013 (CT, 298 arteries): only 17% of intercostal arteries are
       shielded by the rib above at 3 cm from the spine, versus 97% at 6 cm.
       This is the mechanism behind the one complication most likely to
       kill, and "above the rib" alone does not prevent it.
  - Also added that v1 lacked: explicit DEPTH discipline (measure and state
    skin-to-pleura AND skin-to-lung; never exceed the latter), the 15 mm
    minimum pocket with one interspace of margin above and below, marking
    the diaphragm apex at end-expiration, ultrasound-ASSISTED vs -GUIDED
    (and in-plane needle visualization), catheter-over-needle before
    draining volume, post-procedure lung-sliding check BEFORE ordering any
    film, pneumothorax ex vacuo, and a real pleural-fluid send list
    (including pH in a gas syringe on ice, and the albumin gradient /
    NT-proBNP rescue for Light's-misclassified heart failure).
  - **Diagram: intercostal anatomy at the insertion site**, 34 shapes.
    Carries BOTH rules in one figure — level (bundle in the groove under the
    rib above → hug the top of the rib below) and depth (corridor ends at
    the lung surface), the second of which text-only teaching usually drops.
    **First draft had a real defect**, caught by rasterizing the rendered
    SVG to PNG and actually looking at it: with the chest wall drawn as a
    horizontal band, the needle visually crossed straight THROUGH both rib
    cross-sections — the exact opposite of the teaching point. Re-laid out
    as a proper cross-section (skin left, lung right, ribs stacked
    cranial/caudal, needle passing through the interspace hugging the lower
    rib's superior border). Verified: zero labels overflow the viewBox, no
    label collisions beyond same-paragraph line spacing.
  - **Verification note worth keeping:** the browser pane can be *hidden*,
    in which case `computer{screenshot}` returns an all-black image with no
    error. Structural checks (`getBBox` overflow/collision sweeps) still
    work, and for an actual look, serialize the live SVG with computed
    colors inlined, rasterize via canvas, and read the PNG back.
  - Newly authored prose reintroduced British spellings (`favor`, `color`,
    `liter`, `milliliters`, `centimeters`, `analyzed`) despite the
    2026-09-16 normalization pass — caught and fixed pre-commit. Logged as
    item 6 above: the normalizer needs a re-run and a CI guard.
- 2026-09-16 — **American English normalization complete: 1,025 word edits
  across 179 of 431 modules.** Done as a scripted single pass
  (`scratchpad/americanize.py`, line-based raw-text editing so original file
  formatting survives byte-for-byte — re-serializing through `json.dumps`
  would have reformatted every compact array and buried the real changes).
  Families converted: `-emia/-emic` (the largest by far, ~280
  occurrences — hyperkalemia, hypoglycemia, hypovolemia, hypoxemia,
  ischemic, anemia, leukemia …), `hemo-/hemat-/hemorrh-/hemost-`,
  `edema`, `anesthe-`, `pediatr-`, the `-oea` respiratory set
  (apnea/dyspnea/tachypnea — heavily used in a critical-care corpus),
  `esophag-`, `cesarean`, `orthopedic`, `gynecolog-`, `paresthesi-`,
  `maneuver`, `-our` (color/behavior/labor/favor/vapor/tumor),
  `-re` (fiber/center/liter), plus `gray`, `program`, `aluminum`,
  `paralyzed/analyzed/emphasized`, and an explicit `-ise/-isation` stem
  allowlist.
  **Three traps found and handled, each of which would have introduced a
  real error under a naive global find-and-replace:**
  1. **`Haemophilus` is the correct genus name** — a blanket `hem→hem`
     would have produced "Hemophilus influenzae". Sentinel-shielded.
  2. **Citations must quote journal names and article titles verbatim.**
     `sources[]` is skipped wholesale, and inline citations appearing in
     prose/`buildNote`/table rows are separately shielded — `Thromb
     Haemost`, `Br J Anaesth`, `Paediatr Anaesth`, `Lancet Haematol`,
     `Acta Anaesthesiol Scand`, `J Anaesthesiol Clin Pharmacol`, `Royal
     College of Anaesthetists`, and the article titles containing
     "cesarean section" / "central venous catheterization". 21 British
     spellings survive on purpose, all inside citations; a verification
     pass confirmed exactly one outside `sources[]` and it is the protected
     `Paediatr Anaesth 2019` reference inside a buildNote.
  3. **A blanket `-ise→-ize` rule is wrong** — `otherwise`, `compromise`,
     `precise`, `stepwise`, `expertise`, `immunocompromised`, `analysis`,
     `emphasis` are all correct American English. Used an explicit stem
     allowlist instead, and restricted `analys-/emphasis-/paralys-` to the
     verb inflections so the nouns survive.
  Also caught a self-introduced bug in dry-run review before applying:
  a stem-only `manoeuvr→maneuver` rule produced "maneuver**e**" /
  "maneuver**es**" because the trailing vowel survived — fixed by
  enumerating the inflections. Verified post-apply: 7 `maneuver`, 0
  `maneuvere`. Pipeline: validate 431/0, build/sync/test 281/0.

- 2026-09-15 — **Real bug found and fixed: the iOS app's OTA content sync
  could never make brand-new modules or categories discoverable, no matter
  how many deploys succeeded.** User reported "it's not automatically
  updating" after Batch 8 deployed cleanly; reading `ContentStore.swift`
  confirmed the actual mechanism — `checkForUpdates()` downloads
  changed/new module JSON into `Caches/` and bumps `manifest`, but NEVER
  refreshed `search-index.json` or `config/sections.json`, both of which
  were read only once, from the build-time bundle, in `load()`. Since
  nothing ever pointed a route or a browse category at a module that didn't
  exist when the app was last built, every module added since whatever
  build is on a given device — which for the user's phone (still v0.1.0) is
  effectively the entire Batch 2-8 output — was structurally invisible via
  search or section browsing, even though its raw JSON may have silently
  synced into cache in the background. **Fixed**: `checkForUpdates()` now
  also fetches `search-index.json` and `config/sections.json` fresh on
  every check (they aren't per-module-versioned, so unlike modules they're
  just always refreshed rather than diffed) and updates the `@Published
  searchIndex`/`sections` directly; both are also persisted to `Caches/`
  via a new `fetchAndCache()` helper, and `load()` now prefers that cached
  copy over the bundle via a new `cachedOrBundled()` helper (mirroring how
  `loadModuleData` already preferred cache over bundle for individual
  modules) — so a relaunch shows the last-synced state immediately, not
  just whatever was true when the app was built. **Important caveat stated
  directly to the user**: this is a CODE fix, and the very mechanism it
  fixes only ever delivered CONTENT — so the user's already-installed app
  cannot receive this fix over the air. It needs a fresh install, which
  needs `DEVELOPMENT_TEAM` signing (see the NEXT SESSION item above) since
  there's no App Store/TestFlight distribution set up.

  **Also fixed while in there** (user asked, unrelated to the sync bug but
  same area of the app): the Settings screen's version string
  (`"Kairos v0.1.0"`) was hardcoded in `AboutView.swift` instead of reading
  the bundle — added `AppConfig.appVersion` (reads
  `CFBundleShortVersionString`) so bumping `MARKETING_VERSION` in
  `project.yml` is now the only edit needed for iOS. The web client versions
  independently (no shared build pipeline between the two platforms), so a
  parallel `APP_VERSION` constant was added to `web/src/lib/appConfig.js`
  instead, with a comment on both sides pointing at the other — two files to
  bump instead of one, but each is now a single clean edit point rather than
  a string buried in UI code. Also added TEE Compass and a yet-to-be-named
  POCUS guide to the "Companion apps" paragraph in Acknowledgments on both
  clients (iOS `AcknowledgmentsView` in `AboutView.swift`, web
  `acknowledgments.js`) per the user's explicit request. iOS: build/test run
  twice (once mid-edit, once clean after all three changes landed) — both
  `TEST SUCCEEDED`, 10/10. Web: live-verified in browser after hitting the
  now-familiar stale-dev-server-cache issue again, this time from the
  browser's in-memory ES module cache surviving a hash-only `navigate` call
  rather than the service worker — fixed with an explicit
  `window.location.reload()` (SW unregister/cache-clear alone didn't touch
  it this time, worth remembering as a second variant of the same class of
  gotcha).


- 2026-09-15 — **Fresh-look content audit Batch 8 shipped (→ 431 modules) —
  closes the ENTIRE fresh-look audit cycle (all 49 candidates across Batches
  6-8).** New Reference Library: `acute-scrotum` (torsion salvage collapses
  from ~90-96% within 4-6h to under 20% beyond 24h; low-flow vs high-flow
  priapism distinguished since the wrong approach for one doesn't address
  the other's mechanism; Fournier's explicitly cross-linked to
  `necrotizing-soft-tissue-infection` rather than restated),
  `accidental-hypothermia-staging` (Revised Swiss System I-IV; "not dead
  until warm and dead"; gentle-handling warning since a cold, irritable
  myocardium can fibrillate from rough movement alone — the natural
  counterpart to the existing `heat-stroke` module), `hints-vertigo`
  (explicitly scoped to acute vestibular syndrome only, NOT episodic/BPPV
  vertigo; states plainly that a NORMAL head impulse test is the worrisome
  central-cause finding, the counterintuitive part everyone gets backwards
  the first time; explicit operator-dependence caveat since the exam's
  reported ~100%/90-94% sensitivity/specificity was demonstrated by trained
  examiners specifically), `invasive-hemodynamic-monitoring` (square-wave
  test technique for a damped arterial line; explicitly states CVP is a
  weaker fluid-responsiveness predictor than commonly assumed), `icu-nutrition`
  (expands icu-workflow's existing one-liner into a real protocol — hold,
  don't switch to parenteral, during hemodynamic instability),
  `severe-alcohol-withdrawal-dts` (the ICU escalation companion to the
  existing CIWA-Ar calculator; phenobarbital's dual GABA/NMDA mechanism
  framed as a genuine next step, not a last resort, once a patient is
  benzodiazepine-refractory), `mcs-device-selection` (deliberately titled
  "what the intensivist should know" per the user's own scoping direction —
  bedside physiology/complications, not a device-choice protocol; states
  that VA-ECMO can paradoxically INCREASE LV afterload and cause
  ventricular distension, the counterintuitive point most worth knowing),
  `opioid-withdrawal-induction` (deliberately principles-only per the
  user's own scoping direction, not a fixed dosing ladder, since protocols
  genuinely vary by institution — traditional vs low-dose/microdosing
  induction contrasted, with fentanyl's tissue accumulation flagged as a
  reason for extra caution even when COWS-based timing looks correct),
  `intraoperative-awareness` (neuromuscular blockade as the single most
  commonly implicated risk factor — a paralyzed patient can't signal
  distress even if aware; BIS's EMG-interference caveat in a paralyzed
  patient stated explicitly), `emergence-delirium-pod` (distinguishes the
  two entities by timing/population, then leads with "rule out a reversible
  cause first" — hypoxia, pain, a full bladder, residual paralysis — before
  either is diagnosed by exclusion), `pneumoperitoneum-trendelenburg-
  physiology` (states that pneumoperitoneum's SVR rise can mask a real fall
  in cardiac output/cerebral perfusion behind a normal-looking blood
  pressure — the single highest-value counterintuitive point), `one-lung-
  ventilation-basics` (fiberoptic bronchoscopy, not auscultation, as the
  gold standard — clinical exam alone has reported malposition rates as
  high as ~50%; a clear position-then-suction-then-escalate hypoxemia
  troubleshooting sequence), `anesthesia-machine-checkout` (the ASA 2008
  15-item full / 8-item abbreviated structure; explicitly distinguished
  from the existing patient-facing `preanesthesia-checklist` despite both
  sharing "pre-" in their names), `peripartum-cardiomyopathy` (all four
  diagnostic criteria stated together, not just the EF cutoff; leads with
  how easily PPCM symptoms get misattributed to normal late pregnancy;
  bromocriptine's 2025 meta-analysis evidence included with its own
  not-yet-universal-practice caveat preserved from the source), `amniotic-
  fluid-embolism` (states plainly that coagulopathy is present in ~83% of
  cases and is part of the DEFINING diagnostic pattern, not a downstream
  complication — a collapse without evolving DIC should prompt reconsidering
  the diagnosis; pregnancy-modified DIC fibrinogen threshold of <200 mg/dL
  vs the standard <100; cross-linked to, not duplicated from, the existing
  one-line AFE mention inside `maternal-cardiac-arrest`, including flagging
  that mention's own "A-OK" regimen as unproven). New Procedures:
  `epistaxis-management` (leads with topical TXA ahead of reflexive
  anterior packing per head-to-head trial evidence — 73% bleeding cessation
  at 10 minutes vs 29% for packing — with the biggest advantage in exactly
  the anticoagulated/antiplatelet patients most often reflexively packed),
  `peds-nonsedation-procedural-pain` (onset-time table for LMX4/EMLA/
  buffered lidocaine/vapocoolant with an explicit warning that mistimed
  application is the single most common failure mode; infant sucrose framed
  as a real evidence-based analgesic, not merely distraction — corrected a
  schema mistake mid-build, see Errors below). Pipeline: validate 431/0,
  build/sync/test 281/0, iOS `TEST SUCCEEDED` 10/10. Live-verified
  `peds-nonsedation-procedural-pain` rendering correctly post-fix. **This
  closes the entire fresh-look audit cycle — 49/49 candidates built across
  Batches 6-8, 0 duplicates found or built, nothing left queued from either
  the original 2026-09-14 audit or this follow-up cycle.**

  **Error caught and fixed mid-batch**: `peds-nonsedation-procedural-pain.json`
  was initially built with a `procedure` contentType but used a top-level
  `body` array (the `reference`/`peds-tool` block-content pattern) — the
  `procedure.schema.json` has NO `body` field, only `nodes[]` with each
  node's content as a plain string. Caught by reading the schema again
  before running validate (not by a failed validate run) and converted the
  heading/table/list/callout blocks into four `nodes[]` steps with
  prose-converted body strings. Worth remembering: `procedure` modules take
  `nodes[]`, not `body[]` — only `reference` and `peds-tool` use the
  richer block-content `body` array.

- 2026-09-15 — **Fresh-look content audit Batch 7 shipped (→ 413 modules).**
  Continuation of the same fresh-look audit that shipped Batch 6 — 15 more of
  the 49 candidate gaps built, prioritizing the next tier of acuity across
  all four domains. Third module added to the Vascular Emergencies category:
  `acute-limb-ischemia` (Rutherford I-III classification table; paresthesia/
  paralysis flagged as late, ominous findings, not just uncomfortable
  symptoms). New Procedures: `pelvic-binder-placement` (the single highest-
  yield technical point — level at the GREATER TROCHANTERS, not the iliac
  crests, since placement too high is a common, quantified error that nearly
  triples the residual fracture gap). New Reference Library:
  `blunt-chest-trauma` (aggressive multimodal analgesia framed as the actual
  treatment for rib fractures, since poor pain control → shallow breathing →
  pneumonia is the real killer, not the fracture; elderly patients with 3+
  rib fractures flagged for a lower admission threshold even when they look
  fine in the ED), `necrotizing-soft-tissue-infection` (explicitly frames
  LRINEC, which already existed as a calculator, as a risk-FLAG tool per its
  own original validation intent, not a rule-out test — a low score doesn't
  exclude the diagnosis in a patient you're still worried about),
  `abdominal-compartment-syndrome` (WSACS IAH grading I-IV plus the ACS
  definition — IAP>20 PLUS new organ dysfunction, not the pressure number
  alone), `rv-failure-pulmonary-hypertensive-crisis` (the four H's framework;
  explicitly states the failing-RV preload response is close to the OPPOSITE
  of the default shock-resuscitation fluid-bolus reflex), `post-cardiac-
  surgery-vasoplegia` (methylene blue vs hydroxocobalamin dosing/mechanism/
  contraindications — methylene blue's serotonin-syndrome risk on SSRIs and
  G6PD-deficiency risk both WebSearch-verified before inclusion),
  `ponv-treatment-algorithm` (companion to the existing Apfel score
  calculator — the highest-yield rule is switching antiemetic RECEPTOR CLASS
  for rescue rather than repeating whatever was already given for
  prophylaxis within 6 hours), `perioperative-home-medication-management`
  (leads with the GLP-1 guidance reversal — ASA's June 2023 "hold it"
  recommendation was reversed in October 2024 to "continue most patients,"
  flagged explicitly since this is the kind of fact that goes stale fast),
  `perioperative-positioning-nerve-injury` (ulnar neuropathy as the single
  most common perioperative nerve injury claim; axillary roll goes under the
  DOWN CHEST in lateral position, not the axilla itself; prone-position eye
  checks need to repeat through a long case, not happen once at setup). New
  Calculators: `scai-cardiogenic-shock-staging` (classification engine, tiers
  A-E; live-verified rendering in browser showing all 5 tiers with mortality
  figures). New Peds Module: `peds-asthma-exacerbation-management`
  (deliberately distinguished from the existing `bronchiolitis-management` in
  its own opening callout, since the two conditions look like the same
  "wheezing child" at a glance but need different evidence-based approaches;
  escalation is explicitly by RESPONSE to the last intervention, not a fixed
  timer), `abusive-head-trauma` (complements rather than duplicates the
  existing `nat-ten4-facesp-screening` bruising tool — this covers the
  neurologic/intracranial presentation; skeletal survey yield of 30-70%
  occult fractures stated explicitly as a reason not to skip it just because
  the exam looks otherwise normal). New Drug & Dosing:
  `peds-epinephrine-anaphylaxis` (IM 1:1,000 dosing, explicitly distinguished
  in its own notes from the existing IV/IO 1:10,000 arrest-dosing card to
  prevent a concentration mix-up; commercial autoinjector weight tiers —
  0.1/0.15/0.3 mg — included as bedside reference alongside the computed
  manual dose). New Peds Module: `neonatal-hypoglycemia` (deliberately did
  NOT state a single numeric glucose threshold — WebSearch confirmed genuine,
  persistent disagreement across AAP/BAPM/PES guideline bodies on the exact
  cutoff and screening timing — presented the shared principles instead:
  targeted screening of at-risk infants, symptomatic hypoglycemia treated
  immediately regardless of the number, and 40% dextrose gel as now
  widely-endorsed first-line therapy for the well-appearing at-risk infant;
  cross-referenced rather than duplicated against the existing
  `infant-of-diabetic-mother` module for that specific mechanism/context).
  Pipeline: validate 413/0, build/sync/test 281/0, iOS `TEST SUCCEEDED`
  10/10. Live-verified `scai-cardiogenic-shock-staging` (all 5 tiers +
  mortality rendering correctly) and confirmed `pelvic-binder-placement`
  indexed correctly under Wound & Fracture Care. **18 of the original 49
  fresh-look candidates remain queued** — see the NEXT SESSION block above,
  itemized by domain.

- 2026-09-15 — **Fresh-look content audit + Batch 6 shipped (→ 398
  modules).** A follow-up gap audit (separate from and after the 2026-09-14
  audit, which fully closed at Batch 5) ran via 4 parallel domain-scoped
  research agents, each instructed to cross-check the live 384-module
  inventory before proposing anything — found **49 genuine candidate gaps**,
  0 duplicates of existing content. Built the highest-acuity ~14 as Batch 6;
  the other 35 are queued and itemized in the NEXT SESSION block above.
  Two new Reference Library categories added: `vascular-emergencies` and
  `ent-ophtho` ("ENT / Ophtho / Dental / GU"); a matching Procedures category
  `ent-ophtho-procedures` was also added for the one new ENT/ophtho
  procedure. New Reference Library: `aortic-dissection-ruptured-aaa`
  (ADD-RS scoring + Stanford A/B impulse control, paired with ruptured-AAA
  permissive-hypotension management in one module), `acute-mesenteric-
  ischemia` (pain-out-of-proportion-to-exam as the core teaching point; a
  normal lactate does NOT rule it out early), `carbon-monoxide-cyanide-
  poisoning` (pulse oximetry reads falsely normal — co-oximetry required;
  HBO indications; empiric hydroxocobalamin for suspected concurrent cyanide
  in structure-fire smoke inhalation, without waiting for a level),
  `ophthalmologic-emergencies` (angle-closure glaucoma, globe rupture, CRAO,
  chemical injury, PLUS orbital compartment syndrome/retrobulbar hemorrhage
  as a 5th emergency added mid-build once its role as the actual indication
  for lateral canthotomy became clear), `deep-neck-space-infections` (PTA,
  adult epiglottitis — explicitly NOT just a peds disease — and Ludwig's
  angina, organized around a shared airway-first theme), `post-cardiac-
  arrest-care-ttm` (TTM2-driven shift from mandatory 33°C hypothermia to
  active fever-prevention/normothermia as the primary strategy; the ≥72h
  neuroprognostication window is counted from normothermia, not from ROSC —
  cross-linked back from `acls-adult-cardiac-arrest`, whose thin 2-line
  post-ROSC callout now points here instead of being expanded in place), and
  `or-fire-safety` (fire triangle + timeout risk assessment; airway fire's
  stop-gas/remove-tube/irrigate-with-saline/reventilate-with-air-before-
  oxygen sequence). Extended (not duplicated) `advanced-ards-ventilation`
  with a rescue-therapies section — prone positioning (PROSEVA: 16.2%
  absolute mortality reduction, bigger than any other single ARDS
  intervention studied, apply EARLY not as a last resort), neuromuscular
  blockade (ROSE trial reversed the earlier continuous-infusion default —
  as-needed only), inhaled nitric oxide (bridge/rescue only, never shown a
  mortality benefit) — chosen over a new file since this module's own title
  ("Beyond Lung-Protective") already scoped it as the right home. New
  Calculators: `isth-dic-score` (additive engine; 2025 ISTH update
  quantified the D-dimer point thresholds at >3x/>7x ULN; live-verified in
  browser — selections summing to 7 correctly banded as "Compatible with
  overt DIC"). New Procedures: `lateral-canthotomy` (scalpel-finger-bougie-
  style sequence verified against StatPearls/Merck Manual — canthotomy, then
  inferior crus by 'strumming' identification cut inferoposteriorly, superior
  crus only if IOP still >40; live-verified rendering in browser) and
  `cricothyroidotomy` (scalpel-finger-bougie technique, 6.0 cuffed ETT
  railroad target — previously only referenced as the difficult-airway
  algorithm's terminal endpoint with no standalone procedure card of its
  own). New Peds Module: `kawasaki-disease` (classic vs incomplete criteria —
  incomplete is NOT a lesser diagnosis, especially under 6 months; IVIG 2g/kg
  within 10 days is what actually prevents coronary aneurysm),
  `peds-status-epilepticus-ladder` (the 2016 AES four-phase timed algorithm —
  built using `sourceOfTruth` to point at the 5 individual peds anti-seizure
  drug cards that already existed but had never been unified into a timed
  structure, matching what `status-epilepticus-adult` already has),
  `neonatal-early-onset-sepsis-risk` (deliberately built as an orientation
  reference, NOT a reproduced calculator — WebSearch confirmed the Kaiser
  model is a multivariable Bayesian regression that also requires the user's
  own institution's baseline EOS incidence as an input, making a static
  point-based reproduction both infeasible and risky; same no-fabrication
  call as GRACE ACS being left external/incomplete), and
  `peds-toxic-ingestion-one-pill-can-kill` (scoped to avoid restating
  CCB/beta-blocker/clonidine/TCA/opioid/sulfonylurea management that already
  lives elsewhere in the corpus — genuinely new standalone content only for
  camphor, methyl salicylate/oil of wintergreen, and chloroquine, none of
  which existed anywhere before). Both double-checks the user flagged before
  approving the batch were honored: MCS device selection and opioid
  withdrawal induction were explicitly deferred to the 35-item backlog above
  rather than built now, precisely because they need the "what to know, not
  a rigid protocol" framing called out at scoping time. Pipeline: validate
  398/0, build/sync/test 281/0, iOS `TEST SUCCEEDED` 10/10 — note the
  simulator destination needed an explicit `OS=26.5` added to the
  `-destination` flag this session (bare `name:iPhone 17 Pro` started
  erroring as "no available devices matched" once multiple OS versions of
  that simulator existed on this machine; future sessions should use
  `platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5` or check `xcodebuild
  -showdestinations` if that stops working too). Also hit and fixed the
  already-known local `git` breakage at the start of this session — every
  git command was failing with an Xcode license prompt (`sudo xcodebuild
  -license`) that needed the user's own interactive terminal; not a Kairos
  repo issue, just noting it here in case it recurs on this machine.

- 2026-09-15 — **Content audit Batch 5 shipped (→ 384 modules) — closes out
- 2026-09-15 — **Content audit Batch 5 shipped (→ 384 modules) — closes out
  every remaining item from the original 2026-09-14 audit's gap list.**
  Pre-build verification pass caught **one more false positive**: "electrolyte
  repletion protocols (K/Mg/Phos)" was already fully covered by a solid table
  in `lab-interpretation.json` — confirmed by reading the actual file before
  building anything, skipped rather than duplicated. New Peds Module:
  `peds-procedural-sedation` (the existing `procedural-sedation-workflow`
  procedure genuinely has zero peds content, confirmed by direct search —
  ketamine as the peds ED workhorse at procedural-sedation doses distinct
  from RSI dosing, NPO status as a risk-modifying factor not an absolute
  gate, and emergence-agitation counseling), `peds-trauma-resuscitation`
  (compensated shock — a normal BP does NOT rule out significant pediatric
  blood loss, hypotension is a late finding; TXA 15mg/kg load max 1g then
  2mg/kg/h, WebSearch-verified), `nat-ten4-facesp-screening` (the validated
  bruising-pattern clinical decision rule — 96% sensitive/87% specific in
  children under 4 — filling the gap next to the fracture-pattern and
  burn-pattern NAT red flags already in `fracture-splinting-guide` and
  `pediatric-burn-management`, neither of which covers bruising). New Drug &
  Dosing: `push-dose-pressors` (phenylephrine + epinephrine prep/dosing as
  one two-drug technique card, distinct from the OR-bolus anescalc cards),
  `calcium-chloride-gluconate` and `sodium-bicarbonate` (generalized from
  their existing hyperkalemia-specific dosing in `hyperkalemia-management`
  to their OTHER real indications — CCB overdose and citrate toxicity for
  calcium; TCA overdose and salicylate alkalinization for bicarb — without
  duplicating the hyperkalemia content itself), `high-dose-naloxone-
  nalmefene` (Kloxxado 8mg IN naloxone and Opvee 2.7mg IN nalmefene —
  WebSearch-verified that NEITHER has shown a proven survival benefit over
  standard-dose naloxone and both carry a real risk of more severe
  precipitated withdrawal, so the card leads with that evidence gap rather
  than the fentanyl-era marketing rationale, consistent with the existing
  `tox-opioids` reference's standard-dose-first philosophy). New Procedures,
  in two new categories (**Obstetric Delivery**, **Cardiac Procedures**) plus
  existing ones: `abscess-incision-drainage` (general, distinct from the
  already-existing Bartholin-specific I&D — loop drainage vs. packing vs.
  neither, and antibiotics as selective not universal), `foreign-body-
  removal` (button battery given its own warning node — esophageal/nasal/
  aural removal is a true 2-hour emergency, WebSearch-verified against the
  National Capital Poison Center guideline including the honey/sucralfate
  dosing and the poison-control hotline number), `nasogastric-orogastric-
  tube-placement` (the basilar-skull-fracture contraindication to the nasal
  route as its own warning node; auscultation-alone is not reliable
  confirmation), `urinary-catheterization` (blood-at-the-meatus/high-riding-
  prostate/perineal-hematoma trauma red flags as an absolute stop-and-image
  gate; CAUTI prevention framing), `escharotomy` (explicitly distinguished
  from fasciotomy — eschar+fat only, never muscle — since conflating the two
  is a real and consequential error), `precipitous-vaginal-delivery` (the
  actual delivery MECHANICS that the existing `obstetric-delivery-
  emergencies` module assumes are already known — that module covers
  shoulder dystocia/cord prolapse/abruption, confirmed by reading its
  headings before building this as a genuinely non-duplicative companion),
  `adult-synchronized-cardioversion` (only peds cardioversion energy dosing
  existed before this — energy doses WebSearch-verified against the current
  2025 AHA Electrical Cardioversion Algorithm: 200J AFib/flutter, 100J
  narrow SVT/monomorphic VT; the sync-mode-resets-after-every-shock trap
  given its own warning node). validate 384/0, build/sync/test 279/0, iOS
  `xcodebuild test` run in parallel. Live-verified `foreign-body-removal`
  rendering correctly (warning-node button-battery content, numbered steps,
  checklist, cross-links) and `adult-synchronized-cardioversion` indexed
  correctly under the new Cardiac Procedures category. **This closes the
  entire originally-scoped 2026-09-14 content audit** — Batches 1 through 5
  covered every confirmed real gap from that audit's four-subagent research
  pass; anything not built was checked and found to already exist. Future
  content work is a fresh audit or user-directed, not a queued backlog.
- 2026-09-15 — **Content audit Batch 4 shipped (→ 370 modules).** Structural
  housekeeping first: fixed `advanced-ards-ventilation` and `ventilator-
  liberation-weaning` (Reference Library) which were miscategorized as "ICU /
  Critical Care" — that title belongs only to the Calculators section's ICU
  category; the Reference Library one is plain "Critical Care" — both
  corrected. `apache-ii` recategorized from "Sepsis / Infectious Disease" to
  "ICU / Critical Care" (a general severity score, not sepsis-specific) and
  moved to match on disk. Added missing `tags[]` to `grace-acs`, `killip-
  classification`, `qtc`, `anion-gap`. Moved `peds-epinephrine-arrest.json`
  into `resus-dosing/` alongside its category-mates. Renamed the
  misleadingly-named "Weight/Age-Based Resuscitation Dosing (Adult + Peds)"
  category to "...Pediatric Resuscitation Dosing" — every one of its 12
  cards was peds-only, confirmed by listing the category's actual contents
  before renaming rather than assuming the audit's claim was right. **Two
  more false positives caught and corrected before building anything**:
  KDIGO/AKIN AKI staging was flagged as missing but already exists as a full
  table in `aki-staging-rrt`; MASCC was checked against `empiric-antibiotics-
  ed-icu` first and confirmed genuinely absent (that module covers antibiotic
  *choice* for febrile neutropenia, not the admission-vs-outpatient risk
  score) before building it. New calculators (EDACS/TIMI-STEMI/DECAF/Light's-
  Criteria/CKD-EPI shipped in Batch 3; these are Batch 4's five additions):
  `mascc-score`, `charlson-comorbidity-index` (implemented as a count-of-
  how-many-apply select per point-tier rather than 16 individual toggles,
  sized to the ACTUAL number of conditions per tier — 10 for the 1-point
  tier, 6 for the 2-point tier — after catching and fixing an initial
  version that arbitrarily capped at "5 or more"/"3 or more" and would have
  undercounted a high-comorbidity patient), `baux-score` (revised Baux,
  hand-verified formula), `braden-scale` (6 subscales, correctly the
  *inverse* direction of most scores — lower means higher risk), `winters-
  formula` (three named formula outputs for the ±2 range since the app can't
  display a single formula as a range — live-verified in the browser:
  HCO3=15 → 28.5/30.5/32.5, exact match to hand calculation). New Reference
  Library: `blunt-cerebrovascular-injury-screening` (Denver/Memphis BCVI —
  built as an any-one-risk-factor-triggers-CTA reference rather than a false-
  precision scored checklist, since Denver alone has been revised three
  times and Memphis differs from it), `hiv-post-exposure-prophylaxis` (built
  against the genuinely recent 2025 CDC nPEP + USPHS occupational-exposure
  updates — simplified single-tablet preferred regimen, and a follow-up-
  testing window shortened to 12 weeks that many clinicians still
  misremember as 6 months), `thyroid-storm-myxedema-coma` (the antithyroid-
  drug-before-iodine sequencing trap, and the never-levothyroxine-alone-
  without-steroids rule for myxedema coma), `adrenal-crisis`, `electrical-
  injury-lightning` (the >1000V high/low-voltage cutoff, and lightning's
  reverse-triage rule explained mechanistically rather than stated as a bare
  rule), `sickle-cell-crisis` (exchange-transfusion indications, and the
  don't-push-Hgb-above-10-with-simple-transfusion viscosity trap),
  `acute-liver-failure` (King's College Criteria for both acetaminophen and
  non-acetaminophen etiologies, each with their single-criterion-alone
  pathway; NAC recommended regardless of etiology; the don't-prophylactically-
  correct-coagulopathy counterintuitive point), `gi-bleed-variceal-
  hemorrhage` (restrictive transfusion matters MORE in variceal bleeding
  specifically since over-transfusion raises portal pressure; the three-
  concurrent-therapies point for suspected variceal bleeding), `heat-stroke`
  (cooling speed over method; no antipyretics), `drowning` ('near-drowning'
  is retired terminology; ventilation-first resuscitation; no routine C-spine
  immobilization absent a trauma mechanism), `perioperative-anaphylaxis`
  (cause distribution WebSearch-verified — NMBA ~38%, not food/stings like
  the general population; sugammadex as an emerging cause in its own right;
  tryptase timing/interpretation math — cross-linked both directions with the
  existing ED/prehospital-only `anaphylaxis` module, which had no `related[]`
  field at all until this pass). validate 370/0, build/sync/test 279/0, iOS
  `xcodebuild test` run in parallel. Live-verified `winters-formula`'s three
  outputs and `charlson-comorbidity-index`'s full condition-list rendering
  on web; `acute-liver-failure`'s King's College table (with `\n`-separated
  multi-line cells) confirmed rendering correctly. **This closes out the
  originally-scoped Content audit 2026-09-14 priority list** — remaining
  items from that audit (procedural-sedation peds content, peds trauma
  resuscitation, NAT/TEN-4-FACESp screening, push-dose pressor prep cards,
  standalone calcium/bicarb cards, electrolyte repletion protocols,
  high-dose intranasal naloxone/nalmefene, general abscess I&D, foreign-body
  removal, NG/OG tube placement, urinary catheterization, escharotomy,
  precipitous delivery technique, adult synchronized cardioversion
  technique) are real but genuinely lower-yield/more niche — a Batch 5 if
  there's appetite for it, not an urgent gap.
- 2026-09-15 — **Content audit Batch 3 shipped (→ 354 modules).** Calculators:
  `edacs` and `timi-stemi` (Cardiovascular — the STEMI-specific TIMI score,
  distinct from the existing NSTEMI/UA one), `lights-criteria` and
  `decaf-score` (Pulmonary — Light's Criteria built as an any-one-positive
  additive checklist, same reuse pattern as preeclampsia-severe-features),
  `ckd-epi-egfr` (GI/Renal — the real gap; race-free 2021 equation, its
  sex-dependent kappa/alpha/female-multiplier terms pre-resolved into linear
  functions of a 0/1 select since the formula grammar has no conditional
  branching, hand-verified against two test cases live in the browser: 50yo
  male Scr 1.0 → 92 mL/min, 50yo female Scr 0.8 → 90 mL/min, both matching
  hand calculation exactly). **A real false-positive caught mid-batch**:
  went to build a `cockcroft-gault-crcl` calculator for the audit's
  "Cockcroft-Gault/CKD-EPI as a standalone calculator" gap, and — while
  searching the live app to verify the new CKD-EPI card rendered — found
  Cockcroft-Gault already existed as `cockcroft-gault` under Drug & Dosing.
  Deleted the duplicate file and instead added `crossListIn` on the existing
  card into Calculators/GI-Renal-Metabolic (the same pattern as
  `apgar-score`'s OB-Newborn cross-list), with a changelog entry on that
  card documenting exactly what almost happened and why — this is the same
  cross-verification discipline applied throughout the audit, just caught
  one step later than the other false positives from the original scoping
  pass. New Reference Library: `renal-dose-adjustment-critical-illness-
  antibiotics` (Critical Care) — the companion reference the Batch 2
  antimicrobial cards already pointed to qualitatively; explains augmented
  renal clearance and CRRT-effluent-rate dosing as the reasons a single
  fixed CrCl table is often the wrong tool in the ICU, and includes an
  honest table of which antibiotics do/don't get a precise number in this
  app and why. New Peds Module: `peds-difficult-airway` (the DAS 2015
  needle-vs-surgical cricothyrotomy age cutoff — WebSearch-verified that
  the <8yo needle-first recommendation is real but that there is NO firm
  evidence-based transition age above 8, contemporary reviews cite 8-12
  with size mattering more than age; built with that genuine uncertainty
  stated rather than presenting a single cutoff as more settled than it
  is) and `pediatric-burn-management` (Lund-Browder age-banded head/thigh/
  leg percentages, WebSearch-verified across multiple source fragments and
  assembled into one table; the maintenance-fluid-addition teaching point
  that the existing adult-oriented `parkland-formula` card doesn't cover;
  ABA burn-center referral thresholds). New Procedures, in a new
  **Aspiration & Drainage Procedures** category: `lumbar-puncture`,
  `thoracentesis` (cross-linked to the new `lights-criteria` calculator),
  `paracentesis` (SBP PMN≥250 threshold, Z-track technique, large-volume
  albumin replacement), `arthrocentesis`; plus `ed-joint-reductions` (under
  the existing Wound & Fracture Care category — shoulder/nursemaid-elbow/
  patella/digit, with the nursemaid's-elbow hyperpronation-vs-supination-
  flexion success rates WebSearch-verified against a Cochrane meta-analysis
  rather than asserted from memory: ~91% vs ~74% first-attempt success).
  **A real tooling gotcha hit and resolved**: after restarting the local
  dev server (it had silently died hours earlier — `preview_list` showed it
  in the "recently ended" list, not running — so an earlier browser tab was
  serving genuinely stale content, which is why the croup/transfusion-
  reactions verification in the Batch 2 session needed a force-reload to
  work), the app's search still couldn't find any of the 5 new Procedures
  modules even after confirming via direct `fetch()` that they were present
  in `search-index.json`. Traced to a stale Service Worker cache serving an
  old precached copy of that file to the app's own internal fetch calls
  (the manual `fetch(..., {cache:'no-store'})` used to check the data
  bypassed it, which is why the data looked fine while the UI didn't).
  Unregistering the service worker and clearing the Cache Storage resolved
  it — a pure local-dev-verification artifact, not a content or build bug;
  worth remembering this failure signature (data confirmed present via
  direct fetch, but UI search still returns nothing) as a services-worker
  cache red flag for future sessions rather than re-diagnosing from
  scratch. validate 354/0, build/sync/test 269/0, iOS `xcodebuild test` run
  in parallel. Live-verified `arthrocentesis` and the CKD-EPI/Cockcroft-
  Gault cross-list rendering correctly post-fix. **Batch 4 of the content
  audit remains queued** — see the "Content audit 2026-09-14" section above
  for the full scoped list (niche references — acute liver failure, heat
  stroke, drowning, electrical injury, sickle cell crisis, HIV PEP, thyroid
  storm/adrenal crisis, perioperative-specific anaphylaxis — plus
  structural housekeeping: category-label normalization, missing tags on
  older files, the misplaced peds-epinephrine-arrest file).
- 2026-09-14 — **Content audit Batch 2 shipped (→ 341 modules).** All eight
  Batch 2 items from the priority scope, plus one mid-batch addition the user
  asked for directly. Calculators/Obstetric-Newborn: `bishop-score` (additive,
  0-13, unfavorable/intermediate/favorable bands), `preeclampsia-severe-
  features` (additive engine repurposed for any-one-positive checklist logic
  rather than a threshold score — `notes` field documents that reuse; also
  carries the Mississippi Triple-Class HELLP system), `postpartum-hemorrhage-
  staging` (`engine: classification`, matching `killip-classification`'s
  tiers[] pattern — CMQCC Stage 0-3 with EBL thresholds and escalation
  actions per stage). Verified along the way that the audit's "no Obstetric/
  Newborn category" and "no scored APGAR" findings were both **false
  positives** — `ob-newborn` already existed in `sections.json` and
  `apgar-score` already cross-lists into it via `crossListIn` +
  `embeddedCalculator`; corrected rather than duplicated. `child-pugh`
  (additive, Class A/B/C) and `modified-rankin-scale` (`engine:
  classification`, tiers 0-6, with a note on mRS 0-1 as typical thrombectomy-
  trial enrollment and mRS 0-2 at 90 days as the standard "good outcome"
  threshold) round out Calculators. **New Antimicrobial Dosing category**
  added to Drug & Dosing Cards (`sections.json`) after the user asked mid-
  batch to check antimicrobial dosing coverage more broadly, not just one
  drug: `vancomycin` (drug-card, weight-based loading + AUC-guided
  maintenance — hit two schema validation errors along the way, missing
  `purpose` and a disallowed top-level `cautions` key that doesn't exist on
  `drug-card.schema.json`, both fixed), `piperacillin-tazobactam` and
  `meropenem` (extended-infusion dosing strategy, renal adjustment — pip-
  tazo's given qualitatively per source rather than a fabricated CrCl table,
  meropenem's given as a sourced table with an explicit "confirm locally"
  caveat since a real table was actually found), `cefepime` (leads with
  cefepime-induced neurotoxicity as the defining safety issue — occurs in
  ~15% of medical ICU patients, in ~26% of cases *despite* correct renal
  dosing, reversible in 2-3 days off the drug). These three fixed-dose
  antibiotics didn't fit either drug schema (`drug-card` requires per-kg
  dosing; `anesthesia-drug-card`'s `drugClass` enum had no antimicrobial
  option) — extended `anesthesia-drug-card.schema.json`'s `drugClass` enum
  with `"antimicrobial"` after grepping both clients to confirm `drugClass`
  drives zero rendering/color logic (only the free-text `drugClassLabel`
  does), a safe minimal schema change. Reference Library: `transfusion-
  reactions` (AHTR, FNHTR, allergic/anaphylactic, delayed hemolytic,
  transfusion sepsis, TA-GVHD, plus a TRALI-vs-TACO comparison table since
  those two are easy to confuse and need near-opposite management —
  cross-linked into `blood-products`' `related[]`). `acute-ischemic-stroke`
  currency update: replaced a vague "see the HOPE trial" wake-up-stroke
  mention with the actual verified 2026 AHA/ASA guideline position — a new
  Class 2a recommendation for IV thrombolysis 4.5-9h post-onset or wake-up
  stroke with advanced-imaging (DWI-FLAIR/perfusion mismatch) selection,
  sourced to TRACE-III/EXTEND/WAKE-UP; also updated tenecteplase to reflect
  the 2026 guideline endorsing it as equivalent to alteplase across the full
  4.5h window, not just pre-thrombectomy. Peds Module: `bronchiolitis-
  management` (AAP 2014 CPG, still standing — built mostly as a "what NOT to
  do" reference: no bronchodilators/steroids/routine CXR/viral testing; HFNC
  given qualitatively per a 2026 Delphi/RAND-UCLA appropriateness consensus
  rather than a fabricated flow-rate table) and `croup-management` (Westley
  score 0-17 table verified component-by-component via WebSearch, severity-
  tiered treatment, and the discharge-timing pitfall that epinephrine's
  effect wanes by ~2h so a good 20-minute recheck isn't a discharge basis —
  plus the less-known finding that low-dose 0.15mg/kg dexamethasone performs
  comparably to the standard 0.6mg/kg). `peds-tool.schema.json` has no
  `related[]` field (unlike `reference.schema.json`) — cross-links between
  the two peds modules and back to febrile-infant-risk-stratification are
  noted in `buildNote` prose instead, matching the schema's actual
  constraint rather than fighting it. validate 341/0, build/sync/test 260/0.
  Live-verified `croup-management` and `transfusion-reactions` rendering on
  web (Westley table, TRALI/TACO comparison table, warning callouts all
  correct); iOS `xcodebuild test` run in parallel. **Batches 3-4 of the
  content audit remain queued** — see the "Content audit 2026-09-14" section
  above for the full scoped list.
- 2026-09-14 — **Content audit Batch 1 shipped (→ 329 modules).** All seven
  Batch 1 items from the priority scope: `aspects` (Alberta Stroke Program
  Early CT Score — additive engine, 10 regions each worth 1 point normal,
  interpretation notes the 2023 large-core trials SELECT2/ANGEL-ASPECT that
  extended thrombectomy benefit below the traditional ASPECTS ≥6 cutoff);
  `modified-duke-criteria` (infective endocarditis — built as a structured
  reference, not a numeric calculator, since Definite/Possible/Rejected is
  combinatorial logic that a point-threshold would misrepresent);
  `pericardiocentesis` (new Vascular & Thoracic Access procedure — tamponade
  recognition, ultrasound-guided technique, the traumatic-hemopericardium
  "bridge not definitive" caveat as a warning node; cross-linked from the 5
  modules that already referenced it as if it existed);
  `febrile-infant-risk-stratification` (peds-tool, kind: decision-tree — the
  AAP 2021 three-age-band pathway: 8-21d mandatory full workup, 22-28d
  markers gate the LP, 29-60d full marker-driven algorithm with exact
  procalcitonin/ANC/CRP thresholds); `peds-succinylcholine-rsi` +
  `peds-fosphenytoin-status` + `peds-levetiracetam-status` +
  `peds-valproate-status` (the two sets that were self-flagged inside
  existing content via `buildNote` — peds-rocuronium-rsi's and
  peds-lorazepam-status's missing companions, now built and cross-linked
  both directions, plus a `sugammadec`→`sugammadex` typo fix caught in the
  same file). **The `septic-shock-resuscitation` SSC-2026 currency update**:
  researched the actual guideline specifics via WebSearch rather than
  guessing (peripheral-vasopressor timing reinforced, age ≥65 gets a lower
  60-65 mmHg initial MAP target, hydrocortisone broadened from a
  vasopressor-dose gate to any septic-shock-on-pressors with the ADRENAL/
  APROCCHSS mixed-evidence caveat kept explicit, active de-resuscitation
  formalized as its own step and cross-linked to the already-built
  venous-congestion-deresuscitation module which this module's own buildNote
  had predicted as a natural follow-on back in 2026-09-02). Found the
  module's existing trial-driven content (CRT-guided resuscitation,
  fluid-responsiveness testing, phenotype-driven escalation) had already
  substantively anticipated 2026 SSC's direction — the actual edit needed
  was targeted, not a rewrite. ASPECTS scoring verified live (all-normal →
  10; 4 abnormal → 6, correct band); pericardiocentesis verified rendering
  correctly on both web and iOS with the workflow-card treatment from the
  last visual pass. validate 329/0, test 254/0, iOS BUILD SUCCEEDED + 10/10
  engine tests. **Batches 2-4 of the content audit remain queued** — see the
  "Content audit 2026-09-14" section above for the full scoped list.
- 2026-09-14 — **Full content audit: OPEN_ITEMS.md self-verification +
  currency/gap analysis across all 321 modules.** User asked to confirm the
  earlier same-day OPEN_ITEMS.md reconciliation was accurate AND to audit
  the content library itself for currency and gaps, "using all tools." Part
  1: directly spot-verified ~15 of the reconciliation's "done" claims
  (El-Ganzouri, childhood-immunization-schedule, canadian-syncope/caprini/
  improve-bleed/apache-ii/pARC, flagOutdatedURL on both clients, iOS AppIcon
  asset, 7 self-hosted font files each platform, brue-pathway v2's Merritt
  citation, GRACE `engine: external`, Xcode DEVELOPMENT_TEAM absent) — all
  confirmed accurate, no holes found in the reconciliation itself. Part 2:
  four parallel research subagents (one per section) plus direct WebSearch
  research on flagship guidelines (2025 AHA ACLS/CPR, 2026 Surviving Sepsis
  Campaign, 2026 AHA/ASA stroke, 2026 multi-society PE guideline, ciraparantag
  approval status, Ezplaz freeze-dried-plasma licensure, ERC 2025 peds
  guideline) — see the new "Content audit 2026-09-14" section under Things
  to address for the full, cross-checked, false-positive-corrected findings.
  Headline: **no wrong clinical number found anywhere sampled** — every
  currency concern was either a real gap (missing coverage) or resolved as
  already-current on verification; the pipeline's sourcing discipline held
  up well under an adversarial check. The one significant currency gap is
  `septic-shock-resuscitation` still citing SSC 2021 when a major SSC 2026
  revision exists. A long list of specific, confirmed content gaps was
  compiled across Calculators, Drug & Dosing, Reference Library, Procedures,
  and Peds Module — highest-yield single items: ASPECTS, Duke Criteria,
  Child-Pugh, febrile-infant risk stratification, pericardiocentesis, and
  the fact that Calculators has no Obstetric/Newborn category at all despite
  it being one of the eleven intended categories. Two gaps in Drug & Dosing
  were already self-flagged inside the content via `buildNote` (peds status-
  epilepticus second/third-line agents, peds succinylcholine) — genuine
  quick wins. No content changes made this pass — this was audit-only;
  building against these findings is the natural next session.
- 2026-09-14 — **Phase 4 visual pass, round 2 (procedures, drug cards,
  reference lists) on both clients.** Toured screen types not yet covered in
  round 1 (Home + a calculator). Found and fixed three concrete "reads like a
  website" spots: (1) static `workflow`-type procedures (e.g.
  `airway-management-flow`) rendered as a plain numbered `<ol>`/`<li>` dump
  with no visual separation — now each step is a card with a numbered ember
  badge (or a red "!" badge for a `warning`-type node like CICO/LAST), on both
  web (`.nodes .node`, `content.js` `workflowList`) and iOS (new
  `WorkflowNodeCard`, `ContentDetailView.swift`). (2) Anesthesia drug cards'
  "Dosing" section (all 55 AnesCalc cards) was one monospace pre-wrapped text
  blob with embedded `\n`s — now parsed into discrete indication/dose rows
  reusing the exact same `.dose-row`/`.dose-ind`/`.dose-amt` styling a
  computed weight-based dose already uses, so a static card and a live
  calculated one now look identical (web `dosingRows()`, iOS `dosingRow()`).
  (3) Generic reference/peds-tool bullet lists (`renderBlocks`/`BlockList`,
  used across most of the content library) now bold a short "Term: " lead-in
  when a list item has that shape — purely presentational, degrades to a
  plain bullet for ordinary prose; verified no false positives on numbered
  prose lists that happen to contain a colon. Also caught and fixed a smaller
  readability bug while checking a peds-tool page: `ageRange` text (a full
  sentence, e.g. "Term neonate (post-resuscitation) to adolescent (~3-50 kg)")
  was being routed through the `.settings` class, meant for short eyebrow
  tags — it was rendering as a wall of shouty uppercase mono. Split apart so
  short tags (`outputType`, `kind`) keep the eyebrow treatment and `ageRange`
  gets calm sentence-case (`.muted`); iOS was already correct, no fix needed
  there. SW `SHELL_CACHE` → v12. iOS BUILD SUCCEEDED, 10/10 engine tests;
  both platforms verified live. validate 321/0, test 252/0 (content
  unaffected — this round was rendering-only, no schema/module changes).
  **Phase 4 status**: this closes out the concrete "still reads like a
  website" complaints identified across Home, calculators, procedures, drug
  cards, and reference pages. What's left is genuinely open-ended — continued
  fresh eyes on any screen, not a discrete remaining task.
- 2026-09-14 — **3 flagged content-gap modules built + full OPEN_ITEMS.md
  reconciliation (→ 321 modules).** `brain-death-determination` (Reference
  Library/Critical Care) — the 2023 AAN/AAP/CNS/SCCM consensus guideline:
  prerequisites, clinical exam, apnea test, ancillary testing (and EEG's
  removal from the pathway), pediatric/adult exam-count harmonization.
  `traumatic-cardiac-arrest` (Reference Library/Resuscitation & Airway) — ERC
  2021 special-circumstances guideline + ATLS: the reversible-cause-first
  sequence, where it breaks from standard ACLS, and a resuscitative-thoracotomy
  candidacy table by mechanism. `primary-palliative-care-icu` (Reference
  Library/Critical Care) — combines two flagged audit-page gaps into one
  module: recognizing when a goals-of-care conversation is due, Ask-Tell-Ask/
  NURSE frameworks, exactly what changes with comfort-focused care, and
  terminal-extubation technique. All three cross-linked to existing trauma/
  neurocritical-care modules; `icp-tbi-management`'s `related` array updated to
  point at the two neuro-adjacent ones. validate 321/0, test 252/0, all three
  verified rendering live. **Then a full pass through `docs/OPEN_ITEMS.md`**:
  the "NEXT SESSION" summary block and both checklists ("Things to address",
  "Sources to provide") were reconciled against actual current state — a
  meaningful fraction of the unchecked items turned out to already be done
  (live deploy, iOS app icon, self-hosted fonts, El-Ganzouri calculator, NIHSS
  band citations, the "not yet built" scores list, vaccine schedule, higher-risk
  BRUE, and more) and were checked off or marked resolved/superseded, with a
  stale contradiction caught in passing (an "App icon — PARKED" note sitting
  next to a shipped, locked icon). The chronological Progress log itself
  (this section) was left untouched as the authoritative history. Genuinely
  open items that survived the pass: the antibiogram, GRACE 2.0's proprietary
  coefficients, defib pad weight / LMA sizing for specific devices, Xcode
  signing, media/image libraries (POCUS/ECG/nerve-block), and a storyboarding
  pass on deeper procedure decision trees.
- 2026-09-14 — **UI Phase 3 (calculator selects, keyboard checkmark, lateral
  scroll) + Phase 4 start (peds-lens visibility) shipped.** `nihss` → v3: all
  15 items converted from free-entry integers to `select` dropdowns carrying
  the official NIH Stroke Scale category text per score (per user feedback —
  a fixed small scored set should be a picker, not a numeric field). Audited
  every other calculator for the same gap: the `additive` engine already does
  this natively (`items[].options[]`), so NIHSS (a `formula`-engine calc with
  raw exam-finding inputs) was the one real gap; `grace-acs`'s integer inputs
  and `harris-benedict`'s stress-factor number input are genuinely continuous
  values, correctly left alone. iOS `ClearableField`'s keyboard toolbar "Done"
  button replaced with a yellow checkmark — the confirm affordance for
  continuous, patient-specific fields (HR, BP, weight) that can't be a
  dropdown. iOS `ContentDetailView`'s table renderer: tables with ≤3 columns
  now lay out full-width with flexible wrapping columns (no forced horizontal
  scroll); only genuinely dense 4+-column tables (e.g. an induction-agent
  hemodynamic table) keep the fixed-width horizontal-scroll behavior — fixes
  the "lateral scrolling on some screens" complaint. Peds lens visibility: the
  lens now visibly tags floated items with a "peds" badge (reusing the
  existing cross-list badge styling) instead of only silently reordering,
  on both web (`home.js`, `section.js`) and iOS (`HomeView`, `SectionView`).
  **Found and fixed a real bug while verifying NIHSS in the simulator:**
  `ContentStore.checkForUpdates()` compared each remote module's version
  against `cachedVersions[key] ?? 0` — on ANY fresh install with network
  access, this treated "never downloaded" as version 0 and eagerly
  overwrote freshly-bundled local content with whatever is still live on
  the deployed GitHub Pages site (even if older), silently masking every
  local content edit during simulator testing. Fixed to fall back to the
  *bundled* manifest's version as the baseline instead of 0. This means any
  session testing local content changes in the simulator before this fix may
  have been looking at stale (deployed) content without realizing it —
  worth keeping in mind if past verification claims about content changes
  ever seem suspect. iOS BUILD SUCCEEDED, 10/10 engine tests, verified live
  (simulator: NIHSS dropdowns + labels correct after the cache fix; Settings
  structure). validate 318/0, test 252/0. **Phase 4's broader "full visual
  pass" is still open** — everything concrete from the original backlog is
  now done; a fresh top-to-bottom look (now that tab bar + settings + these
  fixes are all live) is the natural next step whenever picked back up.
- 2026-09-13 — **Phase 5 (Procedures gap) + Settings redesign shipped on both
  clients (→ 318 modules).** Procedures: new "Vascular & Thoracic Access"
  category (`content/config/sections.json`) with two genuine content-gap
  modules — `central-line-placement` (site selection IJ/subclavian/femoral,
  maximal sterile barrier prep, ultrasound-guided Seldinger sequence,
  confirm-venous-before-dilating, CXR/lung-US confirmation) and
  `tube-thoracostomy` (triangle-of-safety landmark, blunt dissection above the
  rib, finger sweep, tube sizing/direction, massive-hemothorax ≥1500 mL/≥200
  mL-per-hr and re-expansion-pulmonary-edema decision points). Both
  `workflow`-type procedures, cross-linked to existing trauma/vascular
  reference modules, verified rendering on web + iOS. Settings: full redesign
  per the plan agreed last session — a native grouped-list root
  (`ios/Sources/Views/AboutView.swift` rewritten; new `web/src/views/settings.js`)
  with Appearance (System/Light/Dark) + Care setting + Peds lens inline, a
  Content section (reset pinned shortcuts), and Info/Support submenus (About
  Kairos, Medical & Legal Disclaimer, Acknowledgments, Report an issue) split
  into their own pages instead of one long scroll. Appearance override wired
  end-to-end: iOS `.preferredColorScheme` off `@AppStorage("kairos.appearance")`
  at the WindowGroup level; web `documentElement.dataset.theme` +
  `:root[data-theme]` CSS overrides guarding the existing
  `prefers-color-scheme` blocks, so an explicit choice wins over the OS
  setting in both directions. SW `SHELL_CACHE` → v10. iOS BUILD SUCCEEDED,
  10/10 engine tests; both verified live (simulator + browser preview).
  validate 318/0, test 252/0.
- 2026-09-13 — **UI overhaul Phase 1 (bottom tab bar) + Phase 2 (count-badge
  removal) shipped on both clients.** iOS: `RootView` no longer owns a bare
  `NavigationStack` — a new `MainTabView` (`ios/Sources/App/KairosApp.swift`)
  wraps a `TabView` with Home / Sources / Settings tabs, each its own
  `NavigationStack` (mirrors CRISIS's `ContentView.swift`). `Route.about` was
  removed (Settings tab hosts `AboutView` directly as its root, now also
  carrying the Peds-lens toggle — it's a real settings screen, not just About);
  `Route.sources` stays (also reachable as a push from inside a content page's
  "All sources ›" link — `Components/ClearableField.swift`'s `SourcesBlock`).
  Web: mobile-width (`< 960px`) now shows a fixed bottom tab bar (`#tab-bar` in
  `index.html`, built in `main.js`) mirroring the same 3 destinations — the
  desktop nav rail is unchanged, exactly one of the two shows per the same
  breakpoint. Removed every "(N)" count badge next to a browse item — Home's
  section tiles, the nav rail, and each section page's category headers (web
  `section.js` + iOS `SectionView.swift`) — per user feedback that it read as
  a website's index page, not an app menu. iOS: BUILD SUCCEEDED, 10/10 engine
  tests. Web: verified live at mobile width (tab bar, no counts) and confirmed
  the rail-driven desktop layout is untouched. SW `SHELL_CACHE` → v9.
  **Phase 3 (calculator select-input conversion + lateral-scroll fix) is next**
  — see the UI backlog in memory (`project_kairos.md`).
- 2026-09-13 — **CV Guides re-review — 16 new files, 1 fold-in, 3 flagged as
  new-module candidates.** User re-supplied `CV Guides.zip`; diffed against
  `SOURCE_MATERIALS.md`'s tracked list. Of 16 genuinely new files, 13 are the
  same "Content Audit / Verified" social-post-audit format already excluded by
  the 2026-09-02 direction, with no new actionable delta over existing
  coverage (`code-blue-leadership` duplicates `code-leadership-run-the-room`;
  `hemorrhagic-shock-crystalloid` duplicates `hemorrhagic-shock-mtp` v2;
  `rsi-trial-ketamine-etomidate`'s finding is already in
  `physiologically-difficult-airway`'s induction-agent table; `colcot_guide` /
  `magnesium_lactate_summary` / `snapp_trial_summary` / others are single-trial
  write-ups outside Kairos's acute-bedside scope or too preliminary). One
  fold-in shipped: `acute-dyspnea-niv` → v3, new "Don't withhold oxygen in
  COPD" section (hypoxic-drive teaching is overweighted vs. the dominant
  V/Q-mismatch mechanism; SpO2 88–92% target, never withhold O2). **Flagged
  for a future session, not yet built** (genuine content gaps, deserve careful
  primary-source builds rather than a rushed pass): `brain-death-bd-dnc-framework`
  (BD/DNC determination — Kairos has nothing on this), `traumatic-cardiac-arrest`
  (reversible-cause-first algorithm, distinct from medical ACLS), and
  `primary-palliative-care-icu` + `comfort-focused-care-transition` (ICU
  comfort-focused-care transition — likely one combined module). validate
  316/0 (unaffected — content-only fold-in), test 252/0.
- 2026-09-09 — **Guide fold-ins (6, no new modules).** From the deferred list in
  the CV Guides review: `capnography` v3 (new EtCO2–PaCO2 gradient section);
  `airway-management-flow` v3 (Plan A → VL > DL / hyperangulated > Macintosh per
  COVALENT 2026; post-intubation alkalinized-lidocaine-cuff pearl);
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
  **`bone-cement-implantation-syndrome`** (Peri-op / Anesthesia — Donaldson
  grading, mechanism, prevention checklist, grade-by-grade RV-failure
  management). **`alcoholic-ketoacidosis`** (Critical Care — NADH/NAD⁺ mechanism,
  the β-OHB-under-reads point, work-up + mimics, dextrose/thiamine/electrolytes,
  no-insulin/no-bicarb; companion to `dka-hhs-adult-management`). **`icp-tbi-management`
  → v3** — folded in the 2025 ICM review (Robba et al.): ICP-monitoring camps,
  PaO2 80–120 + hyperoxemia caution, no TXA benefit in isolated TBI, CPPopt,
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
  `null` (same-origin, SW stale-while-revalidate). manifest.webmanifest colors
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
  `Expression.evaluate` with the free variable `x`, marker + above/below color
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
  gray) vs CLINICAL-TAKEAWAY (ember) split, mono table headers, load fade.
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
  **`airway-management-flow` v2** — added a physiologic-optimization step,
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
  `infant-of-diabetic-mother` (hyperinsulinemia, AAP vs PES glucose thresholds,
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
    supracondylar, knee dislocation), a pediatric branch (buckle / greenstick /
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
  `ios/Sources/App/Theme.swift` (section + severity colors to the Option A
  hexes; added `Theme.accent`). Full token table + swatch-artifact link in
  `docs/PALETTES.md`; the old cobalt-indigo proposal there is marked superseded.
  Follow-ups: self-host **IBM Plex Sans/Mono** woff2 (stack falls back to system
  until then); wire `--sec-*` tints into section headers / detail views beyond
  the home tiles; iOS dark-mode color set via asset catalog; recolour
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
  phases; the induction-agent hemodynamic-profile table). `validate.mjs` on the
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
    ischemia/reperfusion physiology, the 2-hour tourniquet/isolation
    threshold, the hyperkalemia treatment ladder, goal-directed fluid
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
    color swatch dot, not just a text label — web (`.zone-dot`) and iOS
    (`Color(hex:)` init added to Theme.swift). Pine/Scarlet deliberately reuse
    the severity-low/high hexes (green zone = "good", red zone = "urgent").
  - **Section tints wired beyond the home tiles**: every content page and the
    section-list page now carry a 3px top-border in their owning section's
    tint (`--tint` custom property + `tintStyle()`/`tintStyleForSection()` in
    `components.js`). iOS: a matching `Rectangle` accent in
    `ContentDetailView`, `.tint(Theme.sectionColor(...))` on `SectionView`'s
    list.
  - **iOS dark-mode color set via asset catalog** (the last Tier-5
    follow-up): 9 Color Sets added to `Assets.xcassets`
    (AccentEmber, Section×5, Severity×3 — moderate reuses AccentEmber),
    each with a light + dark appearance. `Theme.swift` now resolves through
    `Color("Name")` instead of hardcoded RGB literals, so dark mode picks up
    the lifted tones automatically. All verified live in the web app
    (zone dot color, tint borders, category list) via the dev server.
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

### Content audit 2026-09-14 — currency + gap analysis
A full pass across all 321 modules: this session's own OPEN_ITEMS.md
reconciliation claims were independently spot-verified (all checked out —
see the progress log), then four parallel research passes (one per section)
plus direct web research checked (a) whether any cited guideline has been
superseded and (b) what a comprehensive ED/ICU/OR/Peds bedside tool would be
expected to cover that isn't here. Cross-referenced findings against each
other to remove false positives before listing anything below (e.g. an
initial "missing Rumack-Matthew nomogram" and "missing VIS" flag were both
wrong — both exist as drug-dosing cards with a live nomogram plot, just not
filed under Calculators).

**Currency — confirmed real findings only** (not fabricated; each was
checked against a live source):
- [ ] **`septic-shock-resuscitation` is built on Surviving Sepsis Campaign
  2021** — a new SSC 2026 guideline exists (129 statements, 46 new,
  described by its authors as a paradigm shift toward risk-stratified
  precision medicine and whole-course/post-discharge management). This is
  the single most significant currency gap found — a full guideline
  revision, not a minor tweak. Needs a dedicated update pass, not a quick
  patch.
- [ ] **`acute-ischemic-stroke` doesn't cover the extended thrombolysis
  window** (4.5–9 h, or wake-up stroke, advanced-imaging-selected) that a
  new Feb 2026 AHA/ASA guideline formalizes — the module currently extends
  imaging-based selection to thrombectomy only, not to thrombolysis itself.
  Alteplase/tenecteplase dosing and the standard 4.5 h window are otherwise
  current and correct.
- [ ] **`acls-adult-cardiac-arrest` doesn't cover the new EMS-provider-
  stratified termination-of-resuscitation criteria** from the Oct 2025 AHA
  refresh (different TOR rules for BLS vs. ALS vs. universal application).
  Lower priority than the two above — arguably more an EMS/prehospital-
  protocol detail than a hospital ED/ICU one, but Kairos does carry a
  prehospital setting lens. Note: everything else checked in this module
  (IV-preferred-over-IO, vasopressin removed, calcium/bicarbonate not
  routine citing COCA/BIHCA, DSED not recommended, infant two-finger
  technique eliminated) already correctly reflects the Oct 2025 update —
  this module is otherwise a good example of the pipeline's currency
  discipline.
- **Verified NOT problems** (checked and cleared, don't re-flag): the
  `twelve-lead-stemi-criteria` "Fifth Universal Definition of MI (2026)"
  citation looked potentially fabricated on first pass (an unfamiliar
  journal DOI pattern) but is a real, verified publication (ESC/ACC/AHA/WHF
  joint statement) with the exact classification framework Kairos already
  cites; `acute-pe-guideline-2026` already correctly reflects the real new
  2026 multi-society AHA/ACC PE guideline (A–E clinical categories); the
  freeze-dried-plasma FDA-licensure citation in `iv-fluids`/`hemorrhagic-
  shock-mtp` is accurate (Ezplaz, licensed July 29 2026); `erc-2025-
  pediatric-life-support` is built on a real guideline; anticoagulation-
  reversal correctly excludes ciraparantag (still investigational, not
  FDA-approved). No wrong dose, coefficient, or threshold was found in
  anything sampled across all four passes — the gaps below are absence of
  coverage, not errors in what's written.

**Confirmed content gaps, by section** (real, specific, cross-checked
against the actual inventory — not guessed):

*Calculators* — the standalone Obstetric/Newborn category doesn't exist at
all (OB/newborn content is narrative-only); missing a scored Bishop Score,
a true scored APGAR, a preeclampsia/HELLP severity tool, a PPH blood-loss
estimator. Also missing, by category: Cardiovascular — EDACS, TIMI-STEMI
(only the NSTEMI variant exists), ASCVD/Framingham risk. Pulmonary —
Light's Criteria (pleural effusion), DECAF. **Neuro — ASPECTS is a
significant gap** (central to thrombectomy decision-making alongside
NIHSS, which is present), also Modified Rankin Scale, Modified Fisher
Grade, LAMS/RACE. Trauma — Baux Score, Denver/Memphis criteria for blunt
cerebrovascular injury (Parkland is NOT a gap — it's a drug-dosing card).
**Sepsis/ID — Duke Criteria for infective endocarditis is a significant
gap**, also MASCC, Charlson Comorbidity Index. GI/Renal/Metabolic —
**Child-Pugh is a surprising gap given MELD-Na exists**, also Cockcroft-
Gault/CKD-EPI as a standalone calculator, Winter's Formula, formal
KDIGO/AKIN AKI staging. ICU — Braden Scale (VIS is NOT a gap — it's a
drug-dosing card with a live plot). Minor structural notes: APACHE II is
filed under Sepsis/ID rather than ICU/Critical Care; a few older files
(`grace-acs`, `killip-classification`, `qtc`, `anion-gap`) have no `tags`.

*Drug & Dosing* — real gaps: a vancomycin dosing card (loading + AUC:MIC
maintenance — currently name-only in antibiotic references), renal
dose-adjustment reference for critical-illness antibiotics (pip-tazo
extended infusion, meropenem/cefepime by CrCl/CRRT), ED/ICU push-dose
pressor prep cards (distinct concentration/prep from the existing OR-bolus
cards), standalone IV calcium chloride/gluconate and sodium bicarbonate
cards, electrolyte repletion protocols (K/Mg/Phos — hyperkalemia
*treatment* is covered, repletion isn't), high-dose intranasal
naloxone/nalmefene (fentanyl-era reversal). Two gaps are **self-flagged
inside the content itself** (a `buildNote` naming its own missing
companion) — worth doing first since they're already scoped: peds
second/third-line status-epilepticus agents (diazepam rectal, fosphenytoin,
levetiracetam, valproate, phenobarbital — named in
`peds-lorazepam-status.json`'s buildNote) and a peds succinylcholine RSI
calculator (named in `peds-rocuronium-rsi.json`'s buildNote). Structural:
`peds-epinephrine-arrest.json` is misplaced (sits outside `resus-dosing/`
with everything else in its category); the "Weight/Age-Based Resuscitation
Dosing (Adult + Peds)" category has zero adult cards despite the name;
typo "sugammadec" → "sugammadex" in `peds-rocuronium-rsi.json`; the two
tox-withdrawal calculators (`digoxin-immune-fab-dosing`,
`high-dose-insulin-euglycemia-dosing`) are excellent but effectively
invisible to anyone browsing only the Drug & Dosing section.

*Reference Library* — real gaps: transfusion reactions (acute hemolytic,
TRALI, TACO, febrile non-hemolytic, anaphylactic — `blood-products.json`
covers product selection only), acute liver failure, GI bleed/variceal
hemorrhage management (the scoring tools exist as calculators, no
narrative companion), heat stroke, drowning, electrical injury/lightning,
sickle cell crisis, HIV PEP, thyroid storm/myxedema coma, adrenal crisis,
perioperative-specific anaphylaxis (the existing `anaphylaxis.json` is
ED/prehospital-only — NMBA/rocuronium, chlorhexidine, latex, and tryptase
timing are OR-specific and absent), a general ED/ICU vascular-access
escalation reference, VTE prophylaxis timing in trauma/neurosurgery. A
pericardiocentesis *procedure* card (see Procedures below) is referenced
from several reference modules but doesn't exist as its own walkthrough.
Structural: two modules (`advanced-ards-ventilation`,
`ventilator-liberation-weaning`) use category `"ICU / Critical Care"` while
the other 24 critical-care modules use plain `"Critical Care"` — fragments
category-based navigation into a spurious extra bucket, should be
normalized.

*Procedures* — real gaps: pericardiocentesis, lumbar puncture,
paracentesis, thoracentesis, arthrocentesis, isolated ED joint reductions
(anterior shoulder, nursemaid elbow, patella, digit — distinct from the
fracture-associated dislocations `fracture-splinting-guide` already
covers), general abscess I&D (Bartholin-specific I&D already exists),
foreign-body removal, NG/OG tube placement, urinary catheterization,
escharotomy, precipitous/vaginal delivery *technique* (existing OB content
covers complications and staging, assumes delivery mechanics are already
known), and adult synchronized cardioversion for unstable tachyarrhythmia
(pad placement gets one passing mention; no dedicated technique/energy
algorithm). Cricothyrotomy does NOT need a separate dedicated procedure —
`anatomically-difficult-airway`'s embedded 7-step technique is solid and a
second version would be duplicative.

*Peds Module* — real gaps: **febrile infant/neonate risk stratification is
a significant gap** (Step-by-Step, PECARN febrile infant, or Rochester
criteria — zero coverage despite BRUE/appendicitis/PECARN-head all being
present as a model for exactly this kind of tool), bronchiolitis
management, croup severity/treatment, peds-specific procedural sedation
(the existing workflow has zero pediatric content; the one peds ketamine
card is for RSI, a different indication/dosing/monitoring context), peds
difficult-airway approach including the surgical-vs-needle cricothyrotomy
age cutoff (absent entirely), pediatric burn management (the existing
Parkland card is adult-oriented — no Lund-Browder %TBSA chart or
maintenance-fluid addition for peds), pediatric-specific trauma
resuscitation (weight-based blood product/TXA dosing, compensated-shock
recognition). Partially covered, worth strengthening: a unified NAT/child-
abuse screening tool (currently only an orthopedic-context warning inside
`fracture-splinting-guide`, no standalone tool like TEN-4-FACESp).
Structural: the `peds-dosing-refs` ("Peds Dosing References") category in
`sections.json` is completely empty — zero files use it; `peds-drip-
concentrations` would naturally fit there but is filed elsewhere.

### Build / infra
- [x] **Deploy pipeline — fully live.** `tools/deploy.mjs` assembles the
  combined PWA+content bundle; `deploy.yml` publishes it to GitHub Pages on
  every push to main. Repo Pages Source = "GitHub Actions", `CONTENT_BASE_URL`
  is set. Confirmed 2026-09-14: all 4 CI checks green on a real commit, and the
  live `manifest.json` at the deployed URL matches local content exactly.
- [x] **Point clients at the live URL — done.** iOS `ContentStore.remoteBase`
  is the live Pages content URL and OTA-syncs against it (a real bug in that
  sync path — using 0 instead of the bundled version as the update-comparison
  baseline — was found and fixed 2026-09-14). Web `REMOTE_BASE` stays `null`
  by design (same-origin, service-worker stale-while-revalidate).
- [x] **Web app icon** — wired (manifest, favicon, apple-touch-icon).
- [x] **iOS `AppIcon`** — the "broken ring" mark is locked and rendered into
  `Assets.xcassets/AppIcon.appiconset` (2026-09-03). The "PARKED, revisit" note
  that used to live here was stale — this was decided and shipped.
- [x] **Swift engine tests** — `ios/Tests/EngineTests.swift` (`KairosTests`),
  runs in `ios-ci.yml` on every push, currently green (10/10).
- [x] **"Flag as outdated"** — no longer a `mailto:` stub. Opens a prefilled
  GitHub issue on the content repo (module id/version/dates/client in the
  body) from every content page; a general (non-module) "Report an issue" link
  was added to the new Settings screen 2026-09-13.
- [ ] **Xcode signing.** `ios/project.yml` `DEVELOPMENT_TEAM` is still blank —
  fine for the simulator, needs a team ID for a real-device install.
- [ ] **Content-CTA sub-modules still genuinely open:** vent
  waveform/IABP-troubleshooting media and hyperkalemia/CBC images (Tier 2 —
  text criteria exist, no images produced), an antibiogram-driven
  agent-selection worksheet (needs the local antibiogram — see list 2), and
  original POCUS/ECG/nerve-block image libraries (same media gap). Everything
  else once listed here (peds RSI decision card, Pedi Tape zone reference, peds
  drip-concentration picker, the outpatient antibiotic companion, the vaccine
  schedule) has since been built.
- [ ] **Deeper procedure decision-tree branch logic** — laceration and fracture
  have real region trees, but pattern-recognition-level branching (peds
  fracture patterns like buckle vs. Salter-Harris, individual nerve-block
  sub-techniques beyond fascia iliaca, POCUS exam-specific trees) is still a
  storyboarding pass, from the user or a dedicated content session.

### Verification still owed
- [x] **iOS interaction** — resolved. Direct simulator taps work reliably (the
  earlier note that the tooling "can't inject synthetic taps" no longer
  applies); this session's work was verified live via simulator taps repeatedly.
  `testProcedureTreeWalker` also passed on-device via the `KairosUITests`
  target. The other 3 XCUITest flows were fixed for a harness issue but their
  clean re-run status on `ios-ci` (which currently skips `KairosUITests` as
  flaky-headless) is still unconfirmed — low priority given direct-tap
  verification now covers the same ground.
- [x] **Service worker / offline** — the deployed PWA is confirmed live and
  reachable (manifest fetches correctly from the real GitHub Pages URL,
  `SHELL_CACHE` is at v10). Specifically testing "installed PWA, airplane
  mode" end-to-end hasn't been done, but the underlying precache + OTA
  machinery is proven working in production, not just local dev.
- [ ] **Tier 6 "data clears only on full closeout"** — the `SessionStore`
  cold-launch-vs-background logic still hasn't had dedicated device testing
  (backgrounding, app switch, force-quit). Low priority.

### Design decisions open
- [x] **Tier 5 — color/font scheme — fully done.** "Ink & Ember on Parchment"
  is shipped everywhere (`docs/PALETTES.md` has the token table); IBM Plex
  Sans/Mono are self-hosted on both clients (the "still falls back to system
  fonts" note that used to live here is stale — the actual TTFs were sourced
  and bundled 2026-09-08).
- [x] **Procedure decision-tree walker UI** — built and working on both
  platforms. The deeper branch-logic content gap is tracked above under
  Build/infra, not here.
- [x] **Cormack-Lehane, Mallampati, and El-Ganzouri Airway Risk Index** — all
  three built (the El-Ganzouri item that used to say "still to add" shipped in
  the 2026-09-02 calculator batch).
- [ ] **Nerve-block volumes beyond fascia iliaca** (digital, wrist, hematoma,
  facial, intercostal, popliteal, upper-extremity) were written from general
  knowledge — a `needs-primary-source` verification pass is still owed.
- [x] **AnesCalc's 55 drug cards** — fully reachable, verified end-to-end.
- [x] **Obese-child dosing** — the IBW-vs-actual-weight flag is implemented and
  applied to the four unambiguous hydrophilic arrest drugs. **Still open:**
  per-drug review of the rest (benzos/ketamine likely TBW-based; rocuronium
  lean; succinylcholine actual) plus the adult-obesity cards.
- [x] **Pre-arrival zone-reference flow** — effectively delivered by
  `peds-pre-arrival-card` (one weight in, ~20 resus numbers out, plus the
  age→weight and equipment-by-zone tables) rather than a separate dedicated
  screen; functionally the same ask.
- [ ] **`external`-engine calculators** (GRACE, and any future proprietary
  score) still render structure + cutoffs only — needs licensed logic or a
  labeled nomogram approximation before it computes. Tracked with the GRACE
  2.0 sourcing item below.
- [ ] **Search `tags` / `keywords`** are populated only on a handful of
  modules — ongoing per-item content work, not a discrete task.
- [x] **NIHSS severity bands** — the chosen stratification and its named
  alternate are both cited in the module's notes (done 2026-09-07); the items
  themselves were further converted to descriptive dropdowns 2026-09-14.

### Content structure notes
- [x] **PAS / pARC nav placement** — resolved via the `audience`/`crossListIn`
  hybrid (2026-09-08): both live in Calculators and are cross-listed/tagged for
  the Peds lens, rather than moved into the Peds Module nav.
- [x] **Higher-risk BRUE** — no longer a stub; `brue-pathway` v2 built the
  higher-risk branch from a 2019 framework (Merritt et al.) — see the note
  under "Specific papers referenced by stubs" below on how this relates to the
  originally-identified Brooks et al. citation.
- [ ] `content/config/tiers.json` review-tier calls — a few `stable`
  classifications could be argued (e.g. corrected calcium in critical
  illness). Minor, low priority.

---

## 2. Sources to provide

### From your own existing work (Critical Vector / AnesCalc)
- [x] **CV Guides + AnesCalc + CRISIS integration — done.** Every batch of
  supplied guides (batches 1-6, plus the two later `CV Guides.zip` re-reviews
  in 2026-09) has been inventoried and either converted, folded into an
  existing module, or explicitly logged as skipped (audit-format / duplicate /
  out of scope) in `docs/SOURCE_MATERIALS.md`. AnesCalc's 55 drug cards and
  palette, and CRISIS's palette, are fully integrated — Kairos's own "Ink &
  Ember on Parchment" palette was chosen specifically to be distinct from both.
  `CalculationEngine.swift`'s MAC-age-correction/altitude/infusion math was
  never ported — low priority, cross-check against `dosing-fluid-math` if it's
  ever needed.
- [x] **CV antibiotic guides converted** — `empiric-antibiotics-ed-icu` and
  `empiric-antibiotics-outpatient` both built. **Still open:** your local
  antibiogram, for the drug/dose specifics an institution-specific worksheet
  would need (coverage-class guidance is in place without it).
- [x] **CV landmark-trial write-ups** — superseded by a direction change
  (2026-09-02): Kairos converts sources into management content directly
  rather than trial-summary write-ups, so a separate landmark-trials source
  document is no longer needed. `landmark-trials-sepsis-resuscitation` was
  folded into `septic-shock-resuscitation` and deleted for the same reason.

### Tier 1 — primary-source verification (patient-safety critical)
- [x] **Full sweep of all 60 original calculator + drug-dosing modules** —
  done 2026-09-01, 1 scoring error found and fixed (`rcri`); see
  `docs/TIER1_VERIFICATION.md`.
- [x] **Every score once flagged here as "not yet built"** — Canadian Syncope,
  pARC, Caprini, IMPROVE, and APACHE II — has since been built with verified
  coefficients (pARC's specifically cross-checked against the NCT02633735
  SAP/Appy-CDS coefficient table; the others against their primary papers
  during Tier-1 verification).
- [ ] **GRACE 2.0** — proprietary coefficients are still unpublished; the
  module ships inputs + verified cutoffs only. Needs a licensed source or a
  labeled nomogram approximation before it can compute a score.
- [ ] **`peds-midazolam-status`** IV/intranasal per-dose caps — intentionally
  flagged `institution-specific` (5 vs 10 mg varies by local status-epilepticus
  protocol), not a gap to close so much as a place for you to set your own
  number if it should differ from what's shipped.
- [ ] **Peds dosing cross-check vs. PedsGuide / First 5 Minutes** — the peds
  cards match PALS/AES-2016/RAMPART; a cross-check against those two other
  source apps' published numbers is still worthwhile for anything that
  differs, but hasn't been done.
- [ ] **Defibrillator pad transition weight** and **LMA sizing + laryngoscope
  blade age table** — both need confirming against the specific device
  models your users actually carry; these are genuinely yours to supply.

### Tier 2 — licensing / IP
- [x] **Nerve Block, POCUS, and ECG Library** — all converted from your
  supplied CV originals (`nerve-block-guide`, `pocus-guide`, `ecg-library`).
  **Still open:** none of the three have original annotated media (tracings,
  ultrasound images) — text criteria are complete, image libraries are not.
- [x] **AHA ACLS/PALS algorithm cards** — converted (`acls-adult-cardiac-arrest`,
  `peds-cardiac-arrest`) from your supplied public-domain-science originals.
- [x] **Pedi Tape / weight-zone color sign-off** — done; recoloured
  Dove-Umber to stop colliding with AnesCalc's teal, with real rendered
  swatches per zone.

### Tier 3 — sourcing / freshness
- [x] **Vaccine schedule** — built as `childhood-immunization-schedule`
  (review tier 3, flagged for its annual refresh cadence).
- [ ] **Empiric Antibiotic Guide antibiogram** — same open item as above under
  Critical Vector integration; this is the one piece of Tier 3 sourcing still
  genuinely outstanding.

### Specific papers referenced by stubs
- [x] **Higher-risk BRUE** — resolved. `brue-pathway` v2 was built from a 2019
  higher-risk framework (Merritt et al.), not the originally-identified Brooks
  et al. 2019 *Pediatrics* paper — both describe the same AAP-era higher-risk
  BRUE evaluation approach, but if you specifically want the pathway
  cross-checked against Brooks et al. by name, flag it and that's a quick diff,
  not a rebuild.
- [ ] **Screen-by-screen decision-tree branch logic** for Suture / Fractures /
  Nerve Block / POCUS — still needs a storyboarding pass, from you or a
  dedicated content session; tracked with the same item under "Build / infra"
  above.
