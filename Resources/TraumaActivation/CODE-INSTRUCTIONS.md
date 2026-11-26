# Local Trauma Activation — Build Instructions for Kairos (kit v1.2.0)

## What this is
A **Local Protocols** feature. Users photograph, upload, or import the trauma-activation card or policy PDF for **each facility they work at**, keep all of them on the device, and tap through the right one at the bedside to get the highest tier met, who responds, and how fast. Plus a link card to the national ACS field triage guideline.

## Kit contents (`Resources/TraumaActivation/`)
| File | Role |
|---|---|
| `profiles/bumct-card-photo-TEST-FIXTURE.jpg` | The photo the fixture was transcribed from. Use it to test photo import. Never bundled. |
| `profiles/bumct-card-SCANNED-TEST-FIXTURE.pdf` | The same photo as an image-only PDF (no text layer). Tests the scanned-PDF path. Never bundled. |
| `profiles/bumct-card-TEXT-TEST-FIXTURE.pdf` | A text-layer PDF rebuilt from the fixture profile (marked as a test fixture, not a Banner document). Tests the embedded-text path. Never bundled. |
| `profiles/bumct-2026-02-23.json` | Andrew's Banner Tucson profile. **Test fixture only — never bundled in any build.** Loaded on-device through file import. |
| `trauma-engine-reference.js` | Evaluator (tier logic). Port exactly. |
| `profile-tools-reference.js` | Template expansion, profile validation, import save-gate, profile library. Port exactly. |
| `rule-templates.json` | Library of auto-rule templates users can attach to criteria. Bundled. |
| `trauma-vignettes.json` | 27 evaluator tests. |
| `profile-tests.json` | 10 validation, 4 import-gate, and 3 library tests. |
| `run-vignettes.js` | `node run-vignettes.js` → 27/27, 14/14, 3/3. |
| `acs-field-triage-link-card.json` | External link card. |

## Non-negotiable rules
1. **Profiles are data.** No criterion text, threshold, tier, team list, or response time in Swift source.
2. **No profile ships in the app.** Every profile comes from the user (photo or file import) and is stored on device only. Add a build-time check that fails if any file under `profiles/` is in the app bundle.
3. **Every profile is `personal_only`.** Imports are forced to it; `validateProfile` rejects anything else.
4. **Source images and PDFs never leave the device.** Text recognition is on-device (Vision `VNRecognizeTextRequest`, `.accurate`; PDFKit for PDF text). No network calls anywhere in this feature. Keep the source file only if the user opts in, stored with the profile for later re-checking.
5. **No patient data persists.** Checks and vitals live in memory for the current screen; Clear resets them.
6. **Every profile screen shows** institution, `source_revision_date`, and `banner_text`.
7. **Do not reword clinical content** in the fixture. If anything is ambiguous, list it and stop.

## Profile library (multiple facilities, all kept)
Port `addToLibrary`, `removeFromLibrary`, `listByInstitution` exactly.
- Unlimited profiles across unlimited facilities. **Nothing is ever overwritten**: re-importing a facility adds a new version.
- Grouped by institution (case- and whitespace-insensitive). Within a facility, newest `source_revision_date` is **current**; ties go to the most recent import. Older versions stay, marked "superseded," still viewable.
- One **default** profile opens first (user can change it; first import becomes default; deleting the default reassigns it).
- Library screen: facility list → versions. Actions: set default, rename institution, view source photo, export JSON, delete (with confirmation). Delete is the only way anything is removed.
- Quick switcher on the checklist screen to jump between facilities (e.g., moving between rotation sites).
- Persistence: app sandbox, `FileProtectionType.complete`. Excluded from iCloud backup unless the user turns it on in Settings.

## Import flow A: photo or PDF (Phase 1)
1. **Source** — any of:
   - Camera capture.
   - Photo library (PhotosPicker).
   - Files app / share sheet: images (JPEG, PNG, HEIC) and **PDFs**.
   Multiple sources can be combined into one draft (e.g., front and back photos, or two PDF pages).
2. **PDF handling:**
   - Show page thumbnails; the user selects which pages to import (default: all).
   - Per page, if PDFKit finds an embedded text layer, use it, with line bounding boxes from text selections.
   - If a page has no usable text layer (scanned PDF), render it at ≥ 300 dpi and run the same Vision recognition as photos.
   - Password-protected PDFs: ask for the password; on failure, stop with a clear message.
   - Embedded text is **not** trusted more than OCR. It goes through the identical review, double-check, and save gate, because policy PDFs often have stray headers, footers, and reflowed columns.
3. **Recognize** text on-device for images and scanned pages. Keep each line's bounding box and source (file, page). Order lines by column (x clusters), then top to bottom, so multi-column cards like the BUMCT one read column by column.
4. **Tiers:** user creates tiers (label, color, rank order), pre-suggested from header lines but always user-confirmed.
5. **Line review:** one line at a time, with the source page or photo zoomed to that line's bounding box. The user assigns a role (`criterion`, `tier_header`, `group_header`, `team_response`, `response_time`, `note`, `metadata`, `ignore`), a tier, and a group; can edit text, merge lines (wrapped text), or split them.
6. **Kind and rules:** for each criterion, choose `criterion`, `discretion`, `compound`, or `advisory`. Optionally attach an auto-rule from `rule-templates.json`; the user types every parameter from the card, and the screen shows the template's `plain` sentence filled in ("RR < 10 or > 29") for confirmation. Rules are never inferred from text.
7. **Double check:** any line containing digits or `< > ≤ ≥ = %` (`needsDoubleCheck`) needs a second explicit confirmation, with those characters highlighted. This is where OCR errors hurt (≤ read as <, 29 read as 20).
8. **Save gate:** `canSaveDraft` must return `ok`: institution and revision date entered, every line assigned and confirmed, every numeric line double-checked. Then build the profile, run `validateProfile` (must return no errors), and add it with `addToLibrary`.
9. Draft progress is saved locally so a long card can be finished later.

## Import flow B: JSON file
Files app / share sheet → `.json` → `validateProfile` → show a summary (institution, revision date, criteria count per tier) → user confirms → `addToLibrary`. Export writes the same format. This is how the BUMCT fixture gets onto Andrew's phone.

## Evaluator and checklist screen
Port `trauma-engine-reference.js` exactly (three-valued rule logic, two-pass compound evaluation, tier = highest rank met, `null` → "No criteria selected", never "No activation").
- Header: institution, revision date ("revised N months ago"), banner text, facility switcher.
- Vitals strip (optional). Auto-met rows show "auto: <label>" and stay checked while vitals meet them.
- Criteria grouped tier → section → group. Compound rows show `base_text`, with the full text beneath.
- Sticky result bar in the tier color: label and response time; expands to team, met list, hints, notes, advisories.
- Clear button. ACS link card reachable from here and from search.

## Acceptance checklist
- [ ] All tests pass in XCTest: 27 evaluator, 14 profile/import, 3 library, with the same comparison rules as `run-vignettes.js`.
- [ ] Build fails if a profile file is bundled (demonstrate).
- [ ] Photo import of the BUMCT card photo produces a profile that, after review, evaluates T01–T27 the same as the fixture (use the fixture as the answer key).
- [ ] Two facilities plus two BUMCT revisions coexist; current/superseded labels are correct; the switcher works.
- [ ] Both PDF fixtures import: the text PDF uses the embedded-text path and the scanned PDF uses OCR (log which path each page took). After review, each profile evaluates T01–T27 the same as the fixture.
- [ ] Photo library and Files-app image uploads work, as well as camera capture.
- [ ] Airplane mode: photo and PDF import work end to end (proves on-device).
- [ ] Grep finds no criterion text or thresholds in Swift sources. Show output; explain any hit.
- [ ] VoiceOver reads the result tier and response time.

## Report back
Stack, module locations, storage location and protection class, build-exclusion proof, test results, the BUMCT photo-import comparison, grep output, and every ambiguity you stopped on.
