# NEE Calculator — Build Instructions for Kairos (logic v1.2.0)

## What this is
A norepinephrine equivalents (NEE) calculator for the Kairos **Calculators** section. The user enters the vasopressor infusions currently running and gets one number: total vasopressor load in mcg/kg/min of norepinephrine, with a per-drug breakdown.

## Kit contents (all in `Resources/NEE/`)
| File | Role |
|---|---|
| `nee-logic.json` | **Single source of truth.** Agents, units, conversions, formulas, factors, rules, message text, notes, citations. |
| `nee-engine-reference.js` | Reference implementation of the engine. Port its behavior exactly. |
| `nee-vignettes.json` | 30 test cases with hand-computed expected results. |
| `run-vignettes.js` | Runs the vignettes against the JS reference (`node run-vignettes.js` → 30/30). |
| `SOURCES-AND-VERIFICATION.md` | Where each number came from. Read-only context for you; do not encode anything from it. |

## Non-negotiable rules
1. **All clinical content comes from `nee-logic.json`.** No factor, threshold, unit, conversion, label, or message string may appear in Swift source. Bundle the JSON as a resource and decode it at runtime.
2. **Do not reword, add, or remove clinical content.** That includes the disclaimer and the SSC note.
3. **Factors are stored as fractions (`num`/`den`).** Compute in `Double` as `num / den`. Do not pre-round factors or intermediate values. Round only for display, using `output.display_decimals`.
4. **If anything in the JSON is ambiguous, list it and stop.** Do not resolve it yourself. The JSON gets fixed, not the code.
5. No storage of entered values beyond the current screen session, no patient identifiers, no analytics on entered doses.

## Architecture
- **Engine:** a pure Swift module (suggested name `NEECore`): `computeNEE(logic:input:) -> NEEResult`. No UI imports. Mirror the JS input/output shape field for field (see the header comment in `nee-engine-reference.js`).
- **Tests:** an XCTest target that loads `nee-vignettes.json` and asserts every vignette, using the same comparison rules as `run-vignettes.js` (absolute tolerance from the file; warning/info/error codes compared as sets). All 30 must pass.
- **Skin:** Kairos's own theme (colors, type, spacing, icons). Keep it distinct from AnesCalc and CRISIS. Keep the engine reusable in case AnesCalc adopts it later.

## Engine behavior (summary — the JS file is authoritative)
1. Pick the formula by `formulaId`; if missing, use the one with `default: true`.
2. If weight is given, it must be within `weight.min_inclusive`–`max_inclusive`, else error.
3. For each infusion row: duplicate agent → error; non-numeric → error; negative → error; zero → skip silently; unit not in that agent's `input_units` → error; unit with `per_weight: true` and no weight → error.
4. Any error → return `status: "error"` with all errors collected, no number.
5. Convert to canonical unit: `dose × multiply`, then `÷ weight` if `per_weight`. For norepinephrine only, then `× factor_to_base` of the selected salt.
6. If the agent has a factor in the selected formula: `contribution = canonical × factor`, add to total. If not: amber warning `agent_not_in_formula`, contribution 0, `counted: false`. Never drop it silently.
6a. Agents with `role: "adjunct"` that have a factor in the selected formula: compute `canonical × factor` the same way, add it to `adjunct_mcg_kg_min`, mark `counted: false, adjunct: true`, and **never add it to the NEE total**. Adjuncts are excluded from the canonical doses used by `show_when_all` agent conditions.
7. No positive doses → info `no_inputs`, NEE 0.
8. Evaluate `context_notes` of `type: "info"` using `show_when_all` against canonical doses actually entered.
9. `nee_mcg_min = total × weight` when weight is given, else `null`. `adjunct_mcg_kg_min` is `null` when no adjunct was computed.

## Screen (one screen, top to bottom)
All on-screen wording not listed below as JSON content comes from `ui` in `nee-logic.json` (added in v1.2.0): formula and weight labels, the required marker, the salt control label, "not in this formula", the Adjuncts heading, the NEE label, the adjunct line, the Breakdown and Sources headings, and Clear all. Canonical doses in the breakdown use `output.display_decimals.dose_canonical`. Sources follow `ui.sources_rule`.
1. **Title** from `title`. Search keywords for the home TOC/search index: "NEE", "norepinephrine equivalent", "vasopressor dose", "pressor load".
2. **Formula picker**, default from JSON. Under it, the selected formula's `description`.
3. **Weight (kg)** field, optional. Show it as required (inline, not modal) only when a row uses a per-weight unit.
4. **Infusion rows** in the order of `agents`. Each row: label, numeric field, unit segmented control from `input_units` (preselect `default: true`). Norepinephrine row also has the salt control from `norepinephrine_salt` (default base).
   - Rows for agents not in the selected formula stay visible but are visibly marked "not in this formula".
4a. **Adjuncts section** below the infusion rows, with a heading of "Adjuncts", holding the `role: "adjunct"` agents in JSON order. Same row pattern. Rows stay visible under formulas that lack them, marked "not in this formula".
5. **Result card:** NEE in mcg/kg/min (large), mcg/min beneath it when weight is present. Below the NEE number, when `adjunct_mcg_kg_min` is not null, a visually secondary line: "Adjunct estimate (not included): X mcg/kg/min", followed by the `adjunct_note` text. It must never look like part of the total. Errors replace the number (red, hard stop). Warnings amber. Info notes neutral.
6. **Breakdown:** one line per entered agent: canonical dose → × factor (show `published_as`) → contribution.
7. **Footer:** static notes (`salt_note`, `disclaimer`), then **Sources** listing the citations referenced by the selected formula and the shown notes.
8. **Clear all** button. Results update live as values change.

## Acceptance checklist
- [ ] 30/30 vignettes pass in XCTest.
- [ ] `grep` the engine and NEE screen sources for `0.06`, `0.0025`, `2.5`, `150`, `0.125`, `0.25`, `0.02`, `0.4`, `1440`, and each message string from the JSON. Show me the output and explain any hit (e.g., a UI animation duration is fine; a factor is not).
- [ ] Changing a factor in `nee-logic.json` changes the app's result with no code change (demonstrate once, then revert).
- [ ] Adjunct estimate never changes the NEE number (V26–V29) and is visually separate from it.
- [ ] Formula switch with excluded agents shows the amber warning and counts them as 0.
- [ ] Tool appears under Calculators and is findable from home search/TOC.
- [ ] Dynamic Type and VoiceOver read the result, unit, and any warning.

## Report back
Stack, engine location, how the JSON is bundled, vignette results, grep output, and every ambiguity you stopped on.
