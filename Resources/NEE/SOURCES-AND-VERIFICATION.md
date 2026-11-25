# NEE Kit — Sources and Verification Status (logic v1.1.0, 2026-11-19)

## Verified this session against the source text
| Item | Value in logic | Source |
|---|---|---|
| Kotani factors | NE 1, epi 1, dopamine 1/100, phenylephrine 0.06, vasopressin 2.5 (U/min), angiotensin II 0.0025 (ng/kg/min), terlipressin 10 (mcg/kg/min), methylene blue 0.2 (mg/kg/h), metaraminol 1/8 | Kotani et al., Crit Care 2023;27:29, Fig. 1 as reprinted in the 2025 correction |
| Metaraminol correction | 1/8, not 8 (original misprint) | Kotani et al. correction, Crit Care 2025;29:104 |
| Goradia formula | NE + epi + PE/10 + dopamine/100 + metaraminol/8 + vasopressin×2.5 + angiotensin II×10 (all mcg/kg/min except vasopressin U/min) | Goradia et al., J Crit Care 2021 abstract |
| Goradia angiotensin II conversion | ×10 per mcg/kg/min = ×0.01 per ng/kg/min (arithmetic) | Derived from the above |
| ATHOS-3 formula | NE + epi + dopamine/150 + PE/10 + vasopressin×2.5 (mcg/kg/min, U/min) | Kotani 2023, Table 1 |
| ATHOS-3 enrollment threshold | NEE > 0.2 mcg/kg/min | Kotani 2023 text |
| SSC 2021 vasopressin threshold | NE 0.25–0.5 mcg/kg/min | As cited in Mongardon et al., Crit Care 2023;27:62 |
| Salt factor | tartrate/bitartrate 2 mg/mL ≈ base 1 mg/mL (×1/2) | Mongardon 2023; US bitartrate premix label: 16 mcg/mL base = 31.9 mcg/mL bitartrate monohydrate (exact ratio 0.5016) |
| Base reporting position | SCCM/ESICM task force advocates uniform base reporting | Crit Care Med 2024;52(4):521-530 |

## Known disagreements built into the vignettes
- Phenylephrine: Kotani ×0.06 vs Goradia/ATHOS ×0.1 (V06/V07).
- Angiotensin II: Kotani ×0.0025 vs Goradia ×0.01 per ng/kg/min, a 4-fold difference (V08/V09).
- Dopamine: 1/100 (Kotani, Goradia) vs 1/150 (ATHOS-3) (V12).
- Some online calculators mix these (e.g., dopamine/150 with angiotensin II/10 in ng/kg/min). Kairos should only use a formula exactly as one paper published it.

## Not included in v1, and why
- **Hydroxocobalamin and midodrine as NEE terms:** these are in Kotani's proposed formula (hydroxocobalamin 0.02 × g; midodrine 0.4 × mcg/kg/min; confirmed in the article text 2026-11-19). Kairos shows them as a separate **adjunct estimate that is never added to NEE**, per Andrew's decision. Reasons: the hydroxocobalamin factor comes from one trial (5 g lowered norepinephrine by 0.08 mcg/kg/min) and applies to a one-time dose; the midodrine factor comes from one trial (30 mg/day lowered total norepinephrine by 73 mg over 6 days) and the drug is oral. The paper doesn't explain midodrine's mg/day → mcg/kg/min conversion; Kairos converts mg/day × 1000 / 1440 / weight. Back-calculating the trial result (8.45 mcg/min norepinephrine spared vs 20.8 mcg/min midodrine) gives a ratio of 0.41, which is consistent with Kotani's 0.4 under that conversion and does not depend on weight.
- **SEPSIS-ACT (Laterre 2019) formula:** mixes mcg/min and mcg/kg/min terms in the tabulated version; excluded to avoid unit errors.
- **Bolus doses** (methylene blue load, terlipressin boluses): NEE formulas are defined for infusion rates only.
- **Norepinephrine hydrochloride and epinephrine salt variants:** labeling conventions not verified.

## Decisions for Andrew (not for Code)
1. **Unit-error plausibility warnings** (e.g., NE > some mcg/kg/min ceiling → "check units"). No sourced thresholds, so none are in v1. Set values if you want them.
2. **US availability notes.** From my knowledge, not verified this session: metaraminol isn't marketed in the US, and terlipressin's US approval is for hepatorenal syndrome, not shock. Confirm before adding labels, or hide those rows in a US lens.
3. **Setting lenses:** show in ED, ICU, OR, and Flight, or ICU/OR only?
4. **v1.1 idea:** pump-rate input (mL/h + bag concentration → dose).
5. **AnesCalc:** adopt the same `NEECore` later with its own skin, like the extubation tool?
