# Kairos

Pronounced *KY-ros* (rhymes with "sky") — Greek for "the critical moment."

A unified ED / ICU / OR / Peds reference-and-calculator app, organized by clinical
workflow. Companion to **AnesCalc** and **CRISIS** — not a replacement for either.

This repository is the **build scaffold** described in
`../Extremis/build_package/README_Build_Package.md`. It sets up the structure the
content and features drop into; it does **not** yet contain verified clinical content
for all ~150 items. Each `content/modules/**` file shipped here is either a worked
example transcribed from the build-package specs or an explicitly-marked stub.

## Layout

| Path | What it is |
|---|---|
| `content/` | **Source of truth.** All clinical content as versioned JSON, plus JSON Schemas and config. Never hardcode a dose/formula/cutoff in app code — it lives here. |
| `tools/` | The solo-maintainer pipeline: schema validation, search-index generation, version manifest generation, and the Tier-1 staleness tripwire. Node, run from `tools/`. |
| `web/` | PWA shell. Offline-capable, service-worker cached, reads the same `content/` JSON. Plain ES modules, no build step for the app itself. |
| `ios/` | SwiftUI app shell. Xcode project generated from `project.yml` via [XcodeGen]. Bundles `content/` as a resource for the offline fallback. |
| `docs/ARCHITECTURE.md` | How the content-as-data / remote-fetch / offline-cache / staleness-surfacing design fits together across both clients. |

## The five sections

Procedures · Calculators · Drug & Dosing Cards · Reference Library · Peds Module.
Defined in `content/config/sections.json`. Overlap rule: every item lives in exactly
one section — the one matching what you're *doing* with it.

## Quick start

```bash
# 1. Content pipeline
cd tools && npm install
npm run validate          # schema-check every module
npm run build             # regenerate search-index.json + manifest.json
npm run check-staleness   # fail if any Tier 1 item is past next_review_due

# 2. PWA
cd ../web && npm run sync && npm run dev   # http://localhost:5173

# 3. iOS
cd ../ios && brew install xcodegen && xcodegen generate && open Kairos.xcodeproj
```

## Non-negotiable principles (carried from the build package)

- **One source of truth per fact.** A dose/formula/cutoff is written once in `content/`
  and cross-linked, never restated in two files.
- **Zones/bands never supply a dose.** Continuous values (drug doses, fluid volumes) are
  always computed live from the exact weight. Only discrete things (equipment sizes) are
  zone-based. See `content/config/weight-zones.json` and `docs/ARCHITECTURE.md`.
- **CRISIS stays separate.** Nothing here folds into CRISIS's standalone highest-acuity design.
- **Correctable without a rebuild.** A wrong fact (see: andexanet alfa, Dec 2025) is a
  content push — edit JSON, bump `content_version`, run the pipeline, deploy `content/`.

[XcodeGen]: https://github.com/yonaskolb/XcodeGen
