# Resume notes — pick up on the laptop

Quick orientation for the next working session on a machine where the simulator
and disk I/O behave normally.

## State (2026-09-01)

- **~80 content modules**, all validating. Five sections have real content;
  Procedures has the interactive decision-tree walker.
- Pipeline green: `cd tools && npm run ci` (validate + build + JS engine tests +
  staleness). `npm run deploy` assembles `tools/dist/`.
- iOS: `KairosTests` (engine unit tests) pass. `KairosUITests` — 1 of 4 passed
  on the flaky VM (`testProcedureTreeWalker`), the other 3 were fixed after
  first-run harness issues but **not re-run**.
- Everything since the first commit (`6894aef`) is **uncommitted** on the
  default branch (~65+ paths).

## First things to do on the laptop

1. **Re-run the iOS UI tests** (they take ~1 min each on real hardware, vs 900 s
   here):
   ```bash
   cd ios && xcodegen generate
   xcodebuild test -project Kairos.xcodeproj -scheme Kairos \
     -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 16' \
     -only-testing:KairosUITests CODE_SIGNING_ALLOWED=NO
   ```
   Expect all 4 green. If `testFormulaCalculatorFlow` / `testDrugCardDualModeFlow`
   still fail, it's an assertion-string nuance — check the actual rendered label
   in `Debug > View Debugging` or a screenshot from the `.xcresult`.

2. **Sanity-click the app** in Xcode (`⌘R`): open a calculator, a drug card
   (type a weight, watch the zone bar + live dose), walk a procedure tree,
   toggle a segmented `Picker` (e.g. Cockcroft-Gault sex). This is the manual
   pass the tooling here couldn't do.

3. **Decide the content host** and set it up — see `docs/DEPLOY.md`. Minimum:
   enable GitHub Pages, add a `CONTENT_BASE_URL` repo Variable, push. Then set
   `REMOTE_BASE` in `web/src/lib/contentStore.js` and `ContentStore.remoteBase`
   in `ios/Sources/Content/ContentStore.swift` and OTA updates turn on.

4. **Commit strategy** — the working tree is one big pile on the default branch.
   If you want clean history, branch and split into logical commits
   (scaffold / calculators / drug-dosing / peds / reference / procedures /
   tests+deploy). Otherwise one squashed commit is fine.

## The blocked-on-you list (unchanged)

`docs/OPEN_ITEMS.md §2` — palettes (AnesCalc + CRISIS), ~15 primary sources for
Tier 1 content, Tier 2 licensed/original media, AnesCalc's 55-card export, the
app-icon direction (parked — see the pulse-spike explorations).

## Environment gotchas seen this session (should not recur on the laptop)

- `mcp` simulator-control tap/swipe/text never reached the app — use XCUITest.
- `node validate.mjs` cold-start hung 20-120 s (VM I/O); chained
  `a && b && c` timed out at 120 s then finished in the background. Run the
  pipeline steps individually if that happens.
- `git status` timed out at 120 s once. A stale `.git/index.lock` had to be
  cleared once.
