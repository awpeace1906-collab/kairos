# Drug & Dosing Cards — Dual-Mode Interface Spec (Exact Entry + Color Zones)

**Supersedes the "pick one format" framing in the earlier specs.** This is how the exact-weight
calculator and the color-zone tape-style view coexist in the same tool without compromising
either. The core rule that makes this safe:

> **The color zone is a visual/navigation layer only. It never supplies a dose. Every drug
> dose and fluid volume shown on screen is computed live from the exact weight entered (or
> estimated), full stop — the zone just tells you which themed screen you're looking at and
> which discrete equipment sizes apply.**

That distinction matters because two different kinds of data behave differently here:
- **Drug doses and fluid volumes are continuous** (a 14.3kg child's epinephrine dose is a
  specific number, not "whatever the 12–14kg zone says") — these must always come from the
  live per-kg formula in `Drug_Dosing_Peds_Weight_Based_Spec.md`.
- **Equipment sizes are inherently discrete** (ETT/LMA/blades/pads only come in the sizes
  manufacturers make) — these are legitimately zone-appropriate, since "round to the nearest
  real size" is correct behavior, not a compromise.

---

## Input flow

1. **Primary input: exact weight entry** (kg, with an optional lb toggle). This is the
   preferred path whenever a weight is known or measurable.
2. **Fallback input: age** — if weight is genuinely unavailable, use the APLS age-based
   estimate formulas already in `Drug_Dosing_Peds_Weight_Based_Spec.md` to derive an estimated
   weight, clearly labeled "estimated" on screen (different visual treatment than a measured
   weight — e.g., italicized or with an estimate icon — so no one mistakes it for measured).
3. Either path feeds the **same calculation engine**. There is no separate "zone mode" that
   bypasses the formula — the zone is derived FROM the resulting weight, not the other way
   around.

## What happens once a weight is set

- The screen displays a **color band/header** corresponding to the patient's zone (see table
  below) — this is the fast visual anchor, useful for team communication ("we're in the teal
  zone") and for muscle-memory recognition under stress.
- Below/alongside it, **every drug dose and fluid volume is the exact computed number** for
  that specific weight — not the zone's representative value.
- **Equipment sizes** (ETT, LMA, blade, defib pads, BP cuff) are pulled from the zone's
  equipment table, since those are correctly banded by design.

## Pre-arrival / weight-unknown use case

Before a patient arrives (e.g., peds trauma activation with only an estimated age radioed in),
the app can show a **zone reference card** — the typical equipment sizes and a representative
dose range for that zone — so the team can stage equipment in advance. The moment an actual
weight is available (scale, tape measure, or parent-reported), the app should prompt to enter
it and immediately switch from "zone estimate" to "exact calculation," visually distinguishing
the two states so no one keeps treating the pre-arrival estimate as the final number.

---

## Original Zone Scheme

**Not the Broselow color/weight-band scheme** — per the earlier licensing flag, this is an
original set of boundaries and colors built for this app.

| Zone | Color | Weight Range | ETT Size (uncuffed) | LMA Size | Blade | Defib Pads | BP Cuff |
|---|---|---|---|---|---|---|---|
| 1 | Teal | 3–5 kg | 3.0–3.5 | 1 | Miller 0–1 | Pediatric | Neonatal |
| 2 | Sky | 6–8 kg | 3.5–4.0 | 1 | Miller 1 | Pediatric | Infant |
| 3 | Indigo | 9–11 kg | 4.0–4.5 | 1.5 | Miller 1 | Pediatric | Infant |
| 4 | Violet | 12–14 kg | 4.5–5.0 | 2 | Miller 1–2 | Pediatric | Child (small) |
| 5 | Amber | 15–18 kg | 5.0–5.5 | 2 | Macintosh 2 | Pediatric | Child |
| 6 | Coral | 19–23 kg | 5.5–6.0 | 2.5 | Macintosh 2 | Pediatric/Adult transition* | Child |
| 7 | Slate | 24–29 kg | 6.0 (consider cuffed) | 2.5 | Macintosh 2 | Adult | Child (large) |
| 8 | Forest | 30–36 kg | 6.0–6.5 cuffed | 3 | Macintosh 2–3 | Adult | Adult (small) |
| 9 | Charcoal | 37–50 kg | 6.5–7.0 cuffed | 3 | Macintosh 3 | Adult | Adult |

*Zone 6 is the pediatric/adult defibrillation pad transition — **verify the exact crossover
weight against your specific defibrillator model**, this varies by manufacturer and shouldn't
be treated as a fixed universal cutoff.

ETT sizes above are drawn from the (Age/4)+4 formula's typical output at the midpoint of each
zone, shown here for the equipment-staging use case — but note the app should still calculate
the exact age-based ETT size from the specific patient's actual age when available, using zone
placement only for the pre-arrival staging view.

---

## Drug dose display — worked example

Patient weight entered: **14.3 kg** (exact)
- Zone shown: **Violet (12–14kg)** — for equipment: LMA 2, Miller 1–2 blade
- Epinephrine dose shown: **0.143 mg (1.43 mL of 1:10,000)** — computed live from 14.3kg via the 0.01mg/kg formula, NOT the zone's representative value
- Amiodarone shown: **71.5 mg** — computed live, not zone-derived

This is the concrete difference from a printed tape: the tape would give you "the Violet zone
dose," a single number covering the whole 12–14kg range. This app gives you the zone for
equipment and quick recognition, plus the actual 14.3kg-specific dose for anything you're
administering.

---

## Build notes

- The zone color/boundary table above is a first draft — reasonable starting points, but treat
  them as adjustable design parameters, not clinical constants. Nothing about patient safety
  depends on exactly where a zone boundary sits, since doses are never read from the zone.
- Consider making zone boundaries a simple config table (weight_min, weight_max, color, equipment
  sizes) so they're easy to tune during design/testing without touching the dosing formulas at all
  — the two systems should be architecturally decoupled, matching the decoupled logic above.
- Cross-check the defibrillation pad transition weight (Zone 6/7 boundary) against whichever
  actual defibrillator model(s) this app's users carry — that's the one line item above still
  worth pinning to a real source rather than treating as a design placeholder.
