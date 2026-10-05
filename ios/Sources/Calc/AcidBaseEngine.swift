// Acid-base analyzer — Swift port of web/src/lib/acidBaseEngine.js.
// Behavior must match the JS reference exactly: AcidBaseParityTests runs the
// shared golden vectors (tools/fixtures/acid-base-golden-vectors.json), the same
// file tools/test.mjs runs against the JS engine. If the two disagree, fix the
// Swift. Rules and sources are documented in the JS header.

import Foundation

public enum AcidBaseEngine {

    public enum Chronicity: String { case acute, chronic, unknown }

    public struct Input {
        public var ph: Double?, paco2: Double?, hco3: Double?
        public var na: Double?, cl: Double?, albumin: Double?
        public var chronicity: Chronicity = .unknown
        public init(ph: Double?, paco2: Double?, hco3: Double?, na: Double? = nil, cl: Double? = nil,
                    albumin: Double? = nil, chronicity: Chronicity = .unknown) {
            self.ph = ph; self.paco2 = paco2; self.hco3 = hco3; self.na = na; self.cl = cl
            self.albumin = albumin; self.chronicity = chronicity
        }
    }

    public struct Band: Equatable { public let center: Double; public let lo: Double; public let hi: Double }

    public struct Compensation {
        public let rule: String            // winters | met_alk | resp_acid | resp_alk
        public let measured: String        // paco2 | hco3
        public let actual: Double
        public let expected: Band?         // metabolic rules
        public let acute: Band?            // respiratory rules
        public let chronic: Band?
        public let chronicity: Chronicity?
        public let key: String
    }

    public struct AnionGap { public let value: Double; public let corrected: Double?; public let used: Double; public let key: String }
    public struct DeltaRatio { public let value: Double; public let key: String }

    public struct Result {
        public var status = "ok"
        public var error: String?
        public var phStatus: String?
        public var primary: String?
        public var calculatedPh: Double?
        public var phDifference: Double?
        public var compensation: Compensation?
        public var ag: AnionGap?
        public var deltaRatio: DeltaRatio?
        public var disorders: [String] = []
        public var differentials: [String] = []
        public var flags: [String] = []
    }

    // Reference values (Brandis): centers 40 / 24, ranges 35-45 / 22-26, AG 12.
    static let phLo = 7.35, phHi = 7.45, co2Lo = 35.0, co2Hi = 45.0, co2N = 40.0
    static let hco3Lo = 22.0, hco3Hi = 26.0, hco3N = 24.0, agN = 12.0, albN = 4.0
    static let hhTolerance = 0.05
    static let limits: [(String, ClosedRange<Double>)] = [
        ("ph", 6.5...8.0), ("paco2", 5...150), ("hco3", 2...60), ("na", 100...180), ("cl", 60...140), ("albumin", 0.5...6),
    ]

    /// JS Math.round semantics (half toward +∞), so negative halves match the web.
    static func round(_ x: Double, _ d: Int = 1) -> Double {
        let f = pow(10.0, Double(d)); return (x * f + 0.5).rounded(.down) / f
    }
    static func band(_ center: Double, _ tol: Double) -> Band {
        Band(center: round(center), lo: round(center - tol), hi: round(center + tol))
    }
    public static func hhPh(paco2: Double, hco3: Double) -> Double { 6.1 + log10(hco3 / (0.03 * paco2)) }

    static func respExpected(_ paco2: Double, acidosis: Bool) -> (acute: Band, chronic: Band) {
        let d = (paco2 - co2N) / 10
        return acidosis ? (band(hco3N + 1 * d, 2), band(hco3N + 4 * d, 2))
                        : (band(hco3N + 2 * d, 2), band(hco3N + 5 * d, 2))
    }

    static func respKey(_ hco3: Double, _ exp: (acute: Band, chronic: Band), _ c: Chronicity) -> String {
        let inA = hco3 >= exp.acute.lo && hco3 <= exp.acute.hi
        let inC = hco3 >= exp.chronic.lo && hco3 <= exp.chronic.hi
        let lowest = min(exp.acute.lo, exp.chronic.lo), highest = max(exp.acute.hi, exp.chronic.hi)
        if c != .unknown {
            let e = c == .acute ? exp.acute : exp.chronic
            if hco3 > e.hi { return "plus_metabolic_alkalosis" }
            if hco3 < e.lo { return "plus_metabolic_acidosis" }
            return "appropriate"
        }
        if inA && inC { return "acute_or_chronic" }
        if inA { return "fits_acute" }
        if inC { return "fits_chronic" }
        if hco3 > highest { return "plus_metabolic_alkalosis" }
        if hco3 < lowest { return "plus_metabolic_acidosis" }
        return "between_acute_and_chronic"
    }

    static func metKey(_ paco2: Double, _ e: Band) -> String {
        paco2 > e.hi ? "plus_respiratory_acidosis" : paco2 < e.lo ? "plus_respiratory_alkalosis" : "appropriate"
    }

    static let second: [String: String] = [
        "plus_metabolic_alkalosis": "metabolic_alkalosis", "plus_metabolic_acidosis": "metabolic_acidosis",
        "plus_respiratory_acidosis": "respiratory_acidosis", "plus_respiratory_alkalosis": "respiratory_alkalosis",
    ]
    static let simple = ["metabolic_acidosis", "metabolic_alkalosis", "respiratory_acidosis", "respiratory_alkalosis"]

    public static func interpret(_ input: Input) -> Result {
        var res = Result()
        guard let ph = input.ph, let paco2 = input.paco2, let hco3 = input.hco3 else { res.status = "incomplete"; return res }
        let values: [String: Double?] = ["ph": ph, "paco2": paco2, "hco3": hco3, "na": input.na, "cl": input.cl, "albumin": input.albumin]
        for (k, r) in limits { if let v = values[k] ?? nil, !r.contains(v) { res.status = "error"; res.error = "out_of_range_\(k)"; return res } }

        // Step 0 — Henderson-Hasselbalch consistency.
        let calc = hhPh(paco2: paco2, hco3: hco3)
        res.calculatedPh = round(calc, 2); res.phDifference = round(ph - calc, 2)
        if abs(ph - calc) > hhTolerance { res.flags.append("hh_inconsistent") }

        // Step 1 — pH.
        let phStatus = ph < phLo ? "acidemia" : ph > phHi ? "alkalemia" : "normal"
        res.phStatus = phStatus

        // Step 2 — pattern → primary.
        let cHi = paco2 > co2Hi, cLo = paco2 < co2Lo, bHi = hco3 > hco3Hi, bLo = hco3 < hco3Lo
        var primary: String
        switch phStatus {
        case "acidemia":
            if cHi && bLo { primary = "combined_acidosis" }
            else if cHi { primary = "respiratory_acidosis" }
            else if bLo { primary = "metabolic_acidosis" }
            else {
                let r = paco2 > co2N ? (paco2 - co2N) / 5 : 0, m = hco3 < hco3N ? (hco3N - hco3) / 2 : 0
                primary = r >= m && r > 0 ? "respiratory_acidosis" : m > 0 ? "metabolic_acidosis" : "unclassified"
            }
        case "alkalemia":
            if cLo && bHi { primary = "combined_alkalosis" }
            else if cLo { primary = "respiratory_alkalosis" }
            else if bHi { primary = "metabolic_alkalosis" }
            else {
                let r = paco2 < co2N ? (co2N - paco2) / 5 : 0, m = hco3 > hco3N ? (hco3 - hco3N) / 2 : 0
                primary = r >= m && r > 0 ? "respiratory_alkalosis" : m > 0 ? "metabolic_alkalosis" : "unclassified"
            }
        default:
            if cHi && bHi {
                let exp = respExpected(paco2, acidosis: true)
                let fits = hco3 >= exp.chronic.lo && hco3 <= exp.chronic.hi
                primary = fits ? "compensated_chronic_respiratory_acidosis" : "respiratory_acidosis_with_metabolic_alkalosis"
                res.compensation = Compensation(rule: "resp_acid", measured: "hco3", actual: hco3, expected: nil, acute: exp.acute,
                                                chronic: exp.chronic, chronicity: .chronic, key: fits ? "appropriate" : "plus_metabolic_alkalosis")
            } else if cLo && bLo {
                let exp = respExpected(paco2, acidosis: false)
                let fits = hco3 >= exp.chronic.lo && hco3 <= exp.chronic.hi
                primary = fits ? "compensated_chronic_respiratory_alkalosis" : "metabolic_acidosis_with_respiratory_alkalosis"
                res.compensation = Compensation(rule: "resp_alk", measured: "hco3", actual: hco3, expected: nil, acute: exp.acute,
                                                chronic: exp.chronic, chronicity: .chronic, key: fits ? "appropriate" : "plus_metabolic_acidosis")
            } else if cHi || cLo || bHi || bLo { primary = "normal_ph_single_abnormal" }
            else { primary = "normal" }
        }
        res.primary = primary

        func add(_ d: String) { if !res.disorders.contains(d) { res.disorders.append(d) } }
        if simple.contains(primary) { add(primary) }
        switch primary {
        case "combined_acidosis": add("respiratory_acidosis"); add("metabolic_acidosis")
        case "combined_alkalosis": add("respiratory_alkalosis"); add("metabolic_alkalosis")
        case "compensated_chronic_respiratory_acidosis": add("respiratory_acidosis")
        case "compensated_chronic_respiratory_alkalosis": add("respiratory_alkalosis")
        case "respiratory_acidosis_with_metabolic_alkalosis": add("respiratory_acidosis"); add("metabolic_alkalosis")
        case "metabolic_acidosis_with_respiratory_alkalosis": add("metabolic_acidosis"); add("respiratory_alkalosis")
        default: break
        }

        // Step 4 — compensation for a single primary process.
        if simple.contains(primary) {
            let comp: Compensation
            switch primary {
            case "metabolic_acidosis":
                let e = band(1.5 * hco3 + 8, 2)
                comp = Compensation(rule: "winters", measured: "paco2", actual: paco2, expected: e, acute: nil, chronic: nil, chronicity: nil, key: metKey(paco2, e))
            case "metabolic_alkalosis":
                let e = band(0.7 * hco3 + 20, 5)
                comp = Compensation(rule: "met_alk", measured: "paco2", actual: paco2, expected: e, acute: nil, chronic: nil, chronicity: nil, key: metKey(paco2, e))
            default:
                let acid = primary == "respiratory_acidosis"
                let exp = respExpected(paco2, acidosis: acid)
                comp = Compensation(rule: acid ? "resp_acid" : "resp_alk", measured: "hco3", actual: hco3, expected: nil, acute: exp.acute,
                                    chronic: exp.chronic, chronicity: input.chronicity, key: respKey(hco3, exp, input.chronicity))
            }
            res.compensation = comp
            if let s = second[comp.key] { add(s) }
        }

        // Step 3 — anion gap and delta ratio.
        if let na = input.na, let cl = input.cl {
            let ag = na - cl - hco3
            let corrected = input.albumin.map { ag + 2.5 * (albN - $0) }
            let used = corrected ?? ag
            res.ag = AnionGap(value: round(ag), corrected: corrected.map { round($0) }, used: round(used), key: used >= 12 ? "high" : "normal")
            if input.albumin == nil { res.flags.append("albumin_not_entered") }
            if !res.disorders.contains("metabolic_acidosis") {
                if used > 30 { res.flags.append("hidden_acidosis_definite") }
                else if used >= 20 { res.flags.append("hidden_acidosis_likely") }
            } else if hco3 < hco3N {
                let dr = (used - agN) / (hco3N - hco3)
                let key = dr < 0.4 ? "nagma" : dr < 0.8 ? "hagma_plus_nagma" : dr <= 2 ? "hagma" : "hagma_plus_high_hco3"
                res.deltaRatio = DeltaRatio(value: round(dr, 2), key: key)
            }
        } else if res.disorders.contains("metabolic_acidosis") {
            res.flags.append("enter_electrolytes_for_gap")
        }

        var diffs: [String] = []
        for d in res.disorders {
            guard d == "metabolic_acidosis" else { diffs.append(d); continue }
            switch res.deltaRatio?.key {
            case "nagma": diffs.append("nagma")
            case "hagma_plus_nagma": diffs += ["hagma", "nagma"]
            case .some: diffs.append("hagma")
            case nil:
                if let ag = res.ag { diffs.append(ag.key == "high" ? "hagma" : "nagma") } else { diffs += ["hagma", "nagma"] }
            }
        }
        if res.flags.contains("hidden_acidosis_likely") || res.flags.contains("hidden_acidosis_definite") { diffs.append("hagma") }
        var seen = Set<String>()
        res.differentials = diffs.filter { seen.insert($0).inserted }
        return res
    }
}
