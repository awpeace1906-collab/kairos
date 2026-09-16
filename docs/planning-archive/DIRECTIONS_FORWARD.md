# Directions Forward — Read After RESUME.md and OPEN_ITEMS.md

This supplements, doesn't replace, your own tracking. `OPEN_ITEMS.md` is thorough and
accurate — I cross-checked it against the actual content JSON and it holds up. This file
does three things: (1) confirms your self-assessment, (2) adds two decisions made after
this repo's last session that aren't in your tracker yet, (3) gives you a priority order,
since `OPEN_ITEMS.md` is a flat list and some of what's on it matters much more than the
rest right now.

**Per direct instruction: deprioritize the repo-upload/hosting problem.** The GitHub Pages
private-repo paywall, the `ios-ci` Xcode-version mismatch, and the `content-deploy` red
state are real and tracked correctly in your log — but they're explicitly parked. Don't
spend the next session on them. The content and app build matter more right now.

---

## 1. Two decisions from after your last session — neither is in the repo yet

### Setting-based customization (new requirement)

The app needs a customization axis based on **where the user is working right now** —
Prehospital/Flight, ED, OR/Anesthesia, or ICU/Critical Care — not by professional
credential (MD/DO, NP/PA, Nursing, Paramedic; a competing app does it that way, which is
why this got specified explicitly as a divergence). Nothing in the repo currently
implements either axis, so this is a clean add, not a retrofit fight.

- **This is a lens, not a fork.** One setting selection changes which content is
  emphasized/reordered by default — it must never duplicate content per setting. Given
  your existing architecture (flat content JSON + `sections.json` config + a search
  index), the natural implementation is a `defaultSettingRelevance` or similar field per
  module (or per `body` block) that a setting-selector state reorders at render time —
  same pattern as how `weight-zones.json` is config-driven and decoupled from dosing logic.
  Don't build a second copy of any module per setting.
- Suggested storage: a small addition to `content/config/` (e.g.
  `settings.json` — id/label/order for the four settings) plus an optional per-module
  `settingEmphasis` array (which settings this content is most relevant to, in what order)
  living alongside `tags`/`keywords` in each module's frontmatter. This keeps it inside
  your existing schema-validated pattern rather than inventing new architecture.
- UI: likely the same mechanism you'd use for any profile/preference toggle — a
  persisted `SessionStore` value (web) / equivalent (iOS), surfaced in the About/Settings
  screen you already have, affecting home-screen tile ordering and in-module content
  ordering.

### Standard Reference Library entry template

Every Reference Library entry should structurally include:
1. Header (already have this — title/category)
2. **"Why This Matters"** — 2–4 sentences, clinical stakes/context, before the content.
   Your existing `summary` field is close in spirit but not the same thing — `summary` reads
   as a TL;DR of the content itself; "Why This Matters" is upstream of that, framing *why
   you should care* before you read the content at all. Worth deciding whether to repurpose
   `summary` for this or add a new field — repurposing is probably cleaner given how many
   modules already have a `summary`.
3. Main content (already built — the `body` block array)
4. **"Clinical Takeaway"** — bold headline + 2–3 sentence action-oriented close. Not
   currently a field anywhere in the 285 modules I checked.

**This is a schema + retrofit job, not new architecture.** Add `whyThisMatters` and
`clinicalTakeaway` (or similar) to `reference.schema.json`, then backfill across the ~150+
Reference Library modules. Given the volume, this is genuinely a multi-session content pass
— don't try to do it in one batch. Prioritize Tier 1 modules first (septic shock, anticoag
reversal, STEMI criteria, the arrest/RSI content) since those are the highest-stakes entries
where the framing matters most.

**Specialization angle, worth carrying into the actual writing:** where genuinely
applicable, frame "Why This Matters" and "Clinical Takeaway" around the resuscitation
continuum — how this topic's management shifts prehospital → ED → OR → ICU — rather than
generic critical-care framing. Don't force it onto entries where it doesn't fit (a static
lab-values reference doesn't need a continuum angle).

---

## 2. Priority order for the next session (pulling from your own OPEN_ITEMS.md, reordered)

Your list is accurate but flat. Given "the build is more important" than deploy right now,
here's a suggested sequence:

**First — cheap, high-value, already-scoped fixes:**
1. Re-run the 3 fixed-but-unconfirmed iOS UI tests on real hardware (you flagged this as
   the literal first thing to do — still true).
2. `AnesCalc's 55 drug cards need a navigation home` — this is marked as still open despite
   the cards themselves being imported; a content set that exists but isn't reachable in
   navigation is close to not existing for a user. High leverage to close.
3. `Obese-child IBW-vs-actual-weight flag` — not implemented per your tracker. This is a
   Tier-1-adjacent patient-safety item (per `Drug_Dosing_Peds_Weight_Based_Spec.md`), worth
   moving up from "design decision open" to "do this soon."

**Second — the two new items above.** Setting-based customization is architecturally small
(config + one field) even though the UI/UX work to make it feel good takes iteration;
worth prototyping before the Reference Library retrofit, since the retrofit's field
additions should account for how setting-emphasis and content framing interact if they're
going to share a module.

**Third — the content tails already identified as low-yield/deferred in your log**
(Vent's ~30 deep mode-specific subsections, NISS/TRISS, interactive New Orleans rule,
Caprini-2013 40-item, individual nerve-block-technique sub-trees). Your own prioritization
here looked right — these are genuinely lower-value than what's above. No change
recommended.

**Keep parked, per instruction:** GitHub Pages hosting decision, `ios-ci` Xcode mismatch,
`REMOTE_BASE` wiring. Revisit together once the above is further along.

---

## 3. Spec-compliance spot-check — no action needed, just confirming

Checked against the actual repo, not just your log:
- `weight-zones.json` — matches `Dual_Mode_Weight_Zone_Spec.md`'s 9-zone scheme and
  dose/zone decoupling disclaimer almost verbatim. Correct.
- Content schema (`content_version`, `last_reviewed`, `next_review_due`, `review_tier`,
  `sources`, `changelog`) — matches `Content_Update_Architecture_Spec.md`'s design exactly,
  including the tier-review-cadence concept. Correct, and further along than the spec
  actually required at this stage (289 modules already carrying it).
- `search-index.json` + per-module `tags`/`keywords`/`aliases` — matches
  `Search_TOC_Design_Spec.md`'s schema (your `aliases` field is a reasonable addition
  beyond what that spec defined — no objection to it).
- Sections/categories in `sections.json` — match the 5-section design and category
  breakdowns from the content specs closely; no drift found worth flagging.

Nothing here needs fixing. Listed so the next session doesn't spend time re-verifying
things that are already confirmed correct.
