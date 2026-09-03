# Kairos iOS (SwiftUI)

Native client. The Xcode project is **generated** from `project.yml` with
[XcodeGen] — the `.xcodeproj` is gitignored so the source of truth is the YAML +
`Sources/`.

## Run

```bash
brew install xcodegen        # once
cd ios
xcodegen generate
open Kairos.xcodeproj         # ⌘R, iOS 16+ simulator or device
```

Or headless:

```bash
xcodebuild -project Kairos.xcodeproj -scheme Kairos \
  -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' \
  build CODE_SIGNING_ALLOWED=NO
```

## Tests

`ios/Tests/EngineTests.swift` (target `KairosTests`) mirrors `tools/test.mjs` —
the same cases against `Expression` / `CalculatorEngine` / `WeightZones` /
`SearchIndex`, so the Swift ports are proven equivalent to the web engines
(Bazett 462, Fridericia 440, zone gap → 4, dose min/max/range clamps, …).

```bash
xcodebuild test -project Kairos.xcodeproj -scheme Kairos \
  -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 15' \
  CODE_SIGNING_ALLOWED=NO
```

CI: `.github/workflows/ios-ci.yml` runs `xcodegen generate` + `xcodebuild test`
on a macOS runner.

## How it's wired

| Piece | File |
|---|---|
| Codable mirrors of `content/schema/*` | `Sources/Models/ContentModels.swift` |
| Delivery state machine (bundle-first, manifest poll, OTA swap into Caches/) | `Sources/Content/ContentStore.swift` |
| Flat search index + Section→Category→Item tree | `Sources/Search/SearchIndex.swift` |
| Calculator engine (`additive` / `formula` / `classification` / `external`) | `Sources/Calc/CalculatorEngine.swift` + `Expression.swift` |
| Dual-mode weight/zone (equipment from zone, dose always from exact weight) | `Sources/Dosing/WeightZones.swift` |
| Tier 6: per-field clear, "Clear fields", keyboard "Done", session persistence | `Sources/Views/Components/ClearableField.swift`, `Sources/State/SessionStore.swift` |
| Screens | `Sources/Views/HomeView.swift`, `SectionView.swift`, `ContentDetailView.swift`, `CalculatorView.swift`, `DrugCardView.swift` |
| Placeholder palette / section theming | `Sources/App/Theme.swift` |

`Expression.swift`, `CalculatorEngine.swift`, `WeightZones.swift`, and
`SearchIndex.swift` are line-for-line ports of their `web/src/lib/` counterparts —
keep the two in sync when you change engine behaviour.

## Content bundling

`project.yml` adds `../content` as a **folder reference** (`type: folder`). It
lands in the app bundle as `content/` (lowercase — Xcode uses the on-disk folder
name). `ContentStore.bundledData` resolves both `content/` and `Content/` and
falls back to a flat lookup, so the casing can't silently break the offline
bundle. Re-run `cd ../tools && npm run build` before archiving so
`search-index.json` / `manifest.json` are current.

## Enabling over-the-air content updates

Set `ContentStore.remoteBase` to the CDN base serving the versioned `content/`
tree. The store then polls `manifest.json`, downloads only changed modules into
`Caches/KairosContent/`, and reads those over the bundled baseline.

## Not done here (scaffold)

- App icon / launch screen art.
- Settings screen with the full "About Kairos" copy (text is in the build package).
- Procedure decision-tree walking UI (schema + stub only).
- Real content beyond the 10 example/stub modules.
- Visual design — palette/typography is an open Tier 5 decision.

[XcodeGen]: https://github.com/yonaskolb/XcodeGen
