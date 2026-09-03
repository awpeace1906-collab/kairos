# Kairos Architecture

Derived from the build-package specs:
`Content_Update_Architecture_Spec.md`, `Search_TOC_Design_Spec.md`,
`Dual_Mode_Weight_Zone_Spec.md`, `Calculator_Logic_Build_Spec.md`.

## 1. Content is data, not code

Every calculator formula, drug dose, reference topic, procedure step, and zone
boundary lives in `content/` as JSON validated against a schema in
`content/schema/`. App code (web + iOS) is a renderer + a small set of
interpreters (calculator engine, weight-zone engine, search). It contains **no**
clinical constants.

```
content/
  schema/          JSON Schema per content type
  config/
    sections.json      5 sections, their categories, theming hooks
    weight-zones.json   9-zone Teal->Charcoal table (equipment sizes only)
    tiers.json          review-cadence table (drives the staleness tripwire)
  modules/
    calculators/<category>/<id>.json
    procedures/<id>.json
    drug-dosing/<id>.json
    reference-library/<id>.json
    peds-module/<id>.json
  manifest.json     GENERATED: per-module content_version + hash
  search-index.json GENERATED: flat projection of every module
```

### Per-module record — fields the update mechanism needs

| Field | Purpose |
|---|---|
| `id` | Stable unique id, never reused. |
| `section` | One of the 5 sections. Drives theme/icon. |
| `category` | Sub-group within the section — matches the spec groupings and the TOC tree. |
| `content_version` | Integer. Increments on **any** factual change, independent of app version. |
| `last_reviewed` / `next_review_due` | ISO dates. Drive the staleness tripwire and the user-facing "Last verified" line. |
| `review_tier` | `1` (drug doses, reversal agents, thresholds, guideline-dependent) … `stable` (validated math — no scheduled review). From `config/tiers.json`. |
| `sources` | Citations, so "why does this say X" has an answer. |
| `changelog[]` | `{version, date, change}` — powers an in-app "what changed". |
| `flags[]` | e.g. `verify-coefficients` for the ⚠️ items in `Calculator_Logic_Build_Spec.md`. |

## 2. Delivery: remote-fetched, offline-cached, version-checked

Both clients implement the same `ContentStore` state machine:

1. **Render from local cache, always.** Never "content unavailable".
2. On launch + periodically (when online), fetch `CONTENT_BASE_URL/manifest.json`
   — version numbers only, cheap, non-blocking.
3. For any module whose manifest `content_version` > cached, fetch that module's
   JSON in the background and swap it into the cache silently. Per-module, so a
   one-fact fix doesn't re-ship unrelated content.
4. **Bundled fallback:** the full `content/` tree ships inside the binary /
   service-worker precache. First launch with no connectivity still works.

`CONTENT_BASE_URL` is a static file host (S3 / Cloudflare Pages / GitHub Pages)
serving the versioned `content/` tree. No API, no database — the content is
identical for every user.

- Web: `web/src/lib/contentStore.js` + `web/sw.js` (Cache API precache of the app
  shell and `content/`).
- iOS: `ios/Sources/Content/ContentStore.swift` (actor; `URLSession` background
  fetch; `Bundle.main` fallback).

## 3. Surfacing staleness

- **CI tripwire:** `tools/check-staleness.mjs` fails when any `review_tier: 1`
  item has `next_review_due` in the past. Wired in
  `.github/workflows/content-ci.yml`.
- **User-facing "Last verified <month year>"** rendered under every calculator /
  reference card, with a "Flag as outdated" affordance (routes to the maintainer;
  transport TBD — mailto stub for now).

## 4. Solo-maintainer update workflow

`content/` is a git repo (this one, or split out later). To correct a fact:

1. Edit the module JSON. Add a `changelog` entry. Bump `content_version`.
2. `cd tools && npm run ci` — validates schema, checks the version bump, rebuilds
   `search-index.json` + `manifest.json`, runs the engine tests + staleness check.
3. Commit. `npm run deploy` assembles `tools/dist/` and it's published to the
   static host (`.github/workflows/content-deploy.yml` does this for GitHub Pages
   on push to `main`). Every app instance picks it up on next connectivity. No
   App Store round trip because no binary changed. Full guide: `docs/DEPLOY.md`.

## 5. Search & home-screen TOC (`Search_TOC_Design_Spec.md`)

**One flat index**, `content/search-index.json`, generated from the modules — never
hand-maintained. Entry: `{id, title, section, category, tags, keywords,
contentType, route}`.

- Home screen: search bar (live, results grouped by section) + collapsible
  Section -> Category -> Item tree as the empty state + 5 section tiles.
- Matching: case-insensitive substring against title / tags / keywords, ranked in
  that order. No fuzzy matching in v1.
- Per-section search = the same index pre-filtered to one `section`. No second
  code path.
- Web: `web/src/lib/search.js`. iOS: `ios/Sources/Search/SearchIndex.swift`.

## 6. Calculator engine (`Calculator_Logic_Build_Spec.md`)

A calculator module declares an `engine`:

| `engine` | Meaning |
|---|---|
| `additive` | Sum of selected option points across `items[]`, mapped to `interpretation[]` bands. (HEART, TIMI, Wells, …) |
| `formula` | Evaluate `formulas[].expression` over named `inputs[]`. Safe expression evaluator — `+ - * / ^ ( ) sqrt cbrt`, variables only. (QTc, Anion Gap, …) |
| `classification` | Pick-one clinical tier, no arithmetic. (Killip, …) |
| `external` | Proprietary / non-closed-form. Render structure + cutoff + a build note; do not fake the math. (GRACE, GRACE-adjacent.) |

Web: `web/src/lib/calcEngine.js` + `expr.js`. iOS:
`ios/Sources/Calc/CalculatorEngine.swift` + `Expression.swift` (via `NSExpression`).

## 7. Dual-mode weight / zone (`Dual_Mode_Weight_Zone_Spec.md`)

`content/config/weight-zones.json` is a pure config table: `weight_min`,
`weight_max`, `color`, and **equipment sizes only**. The zone engine:

- takes an exact weight (or an age -> APLS estimate, flagged "estimated"),
- returns the zone **for equipment staging and visual anchor only**,
- every drug dose / fluid volume is computed live from the exact weight by the
  drug-dosing engine, never read from the zone.

## 8. Session state (Tier 6 UI requirements)

- Entered data (weight, calculator inputs, in-progress procedure state) **survives
  backgrounding / app switch**.
- A genuine force-quit / full closeout is the only thing that clears it.
- Web: `sessionStorage` (matches this lifecycle on iOS PWAs closely). iOS:
  `SessionStore` persisted to a scratch file, cleared on a cold launch that
  detects no prior background transition.
- Plus: per-field clear (x-in-circle), a screen-level "Clear fields" button, and a
  keyboard-collapse control — see `Views/Components/`.
