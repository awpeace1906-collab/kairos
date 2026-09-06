import Foundation

// Dual-mode weight/zone logic. Mirrors web/src/lib/weightZones.js.
// The zone supplies equipment sizes + a visual anchor ONLY — never a drug dose.

struct EstimatedWeight { let weightKg: Double; let band: String; let estimated = true }

struct DoseComputation {
    let amount: Double
    let amountHigh: Double?
    let unit: String
    let capped: Bool
    let floored: Bool
    let volumeMl: Double?
    let volumeMlHigh: Double?
    let concentration: String?
    let repeatText: String?
}

enum WeightZones {

    /// Ranges are integer bands with gaps (14 -> 15). A weight in a gap belongs to
    /// the lower zone — matches the Dual_Mode spec worked example (14.3 kg -> zone 4).
    static func zone(for weightKg: Double, in cfg: WeightZonesConfig) -> WeightZonesConfig.Zone? {
        guard weightKg.isFinite else { return nil }
        var match: WeightZonesConfig.Zone?
        for z in cfg.zones {
            if weightKg >= z.weightMin { match = z } else { break }
        }
        return match ?? cfg.zones.first
    }

    /// APLS-style fallback. Result must be surfaced flagged "estimated".
    static func estimateWeight(ageYears: Double, in cfg: WeightZonesConfig) -> EstimatedWeight? {
        let months = ageYears * 12
        guard let band = cfg.ageEstimate.formulas.first(where: { months >= $0.minMonths && months < $0.maxMonths }) else { return nil }
        guard let v = try? Expression.evaluate(band.expression, scope: ["ageMonths": months, "ageYears": ageYears]) else { return nil }
        return EstimatedWeight(weightKg: (v * 10).rounded() / 10, band: band.ageBandLabel)
    }

    /// Ideal body weight proxy for a child — the APLS age-expected weight (no
    /// height is collected). Same number as estimateWeight, named as IBW.
    static func idealBodyWeight(ageYears: Double, in cfg: WeightZonesConfig) -> Double? {
        estimateWeight(ageYears: ageYears, in: cfg)?.weightKg
    }

    struct ObesityCheck { let ibwKg: Double; let actualKg: Double; let pctOver: Int; let flagged: Bool }

    /// Obese-child check for the drug-card flow (Drug_Dosing_Peds_Weight_Based_Spec).
    /// Needs both an actual weight and an age; nil if either is missing or the
    /// ratio isn't configured.
    static func obesityCheck(actualKg: Double, ageYears: Double, in cfg: WeightZonesConfig) -> ObesityCheck? {
        guard let ratio = cfg.obesityFlagRatio, actualKg.isFinite,
              let ibw = idealBodyWeight(ageYears: ageYears, in: cfg), ibw > 0 else { return nil }
        let over = actualKg / ibw
        return ObesityCheck(ibwKg: ibw, actualKg: actualKg,
                            pctOver: Int(((over - 1) * 100).rounded()), flagged: over > ratio)
    }

    /// Live per-kg dose from a drug-card rule. The zone is never consulted here.
    static func dose(from rule: DrugCard.Rule, weightKg: Double) -> DoseComputation? {
        guard weightKg.isFinite else { return nil }

        func clamp(_ perKg: Double) -> (mg: Double, capped: Bool, floored: Bool) {
            var mg = perKg * weightKg
            var capped = false, floored = false
            if let cap = rule.maxDose, mg > cap { mg = cap; capped = true }
            if let floor = rule.minDose, mg < floor { mg = floor; floored = true }
            return (mg, capped, floored)
        }
        let lo = clamp(rule.perKg)
        let hi = rule.perKgHigh.map(clamp)

        let round3 = { (v: Double) in (v * 1000).rounded() / 1000 }
        let round2 = { (v: Double) in (v * 100).rounded() / 100 }
        return DoseComputation(
            amount: round3(lo.mg),
            amountHigh: hi.map { round3($0.mg) },
            unit: rule.unit ?? "mg",
            capped: lo.capped || (hi?.capped ?? false),
            floored: lo.floored,
            volumeMl: rule.mlPerUnit.map { round2(lo.mg * $0) },
            volumeMlHigh: (rule.mlPerUnit != nil && hi != nil) ? round2(hi!.mg * rule.mlPerUnit!) : nil,
            concentration: rule.concentration,
            repeatText: rule.repeatText
        )
    }
}
