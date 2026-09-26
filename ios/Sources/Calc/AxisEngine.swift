// EKG Axis Interpreter — Swift port of web/src/lib/axisEngine.js.
// Behavior must match the JS reference exactly: AxisEngineParityTests runs the
// shared golden vectors (tools/fixtures/axis-golden-vectors.json), the same file
// tools/test.mjs runs against the JS engine. If the two disagree, fix the Swift.

import Foundation

public enum AxisEngine {

    // MARK: Leads

    public struct Lead { public let angle: Double; public let gain: Double }
    static let root3over2 = 3.0.squareRoot() / 2.0
    public static let leadOrder = ["I", "II", "III", "aVR", "aVL", "aVF"]
    public static let leads: [String: Lead] = [
        "I":   Lead(angle: 0,    gain: 1),
        "II":  Lead(angle: 60,   gain: 1),
        "III": Lead(angle: 120,  gain: 1),
        "aVR": Lead(angle: -150, gain: root3over2),
        "aVL": Lead(angle: -30,  gain: root3over2),
        "aVF": Lead(angle: 90,   gain: root3over2),
    ]

    static func rad(_ d: Double) -> Double { d * .pi / 180 }
    static func deg(_ r: Double) -> Double { r * 180 / .pi }

    /// Normalize to (-180, 180].
    public static func normalize(_ d: Double) -> Double {
        var x = (d.truncatingRemainder(dividingBy: 360) + 360).truncatingRemainder(dividingBy: 360)
        if x > 180 { x -= 360 }
        return x
    }

    public static func angularDiff(_ a: Double, _ b: Double) -> Double { abs(normalize(a - b)) }

    public static func inArc(_ theta: Double, lo: Double, hi: Double) -> Bool {
        var t = theta
        while t < lo { t += 360 }
        while t >= lo + 360 { t -= 360 }
        return t <= hi
    }

    // MARK: Classification

    public struct PedsBand: Equatable { public let id: String; public let maxDays: Double; public let lo: Double; public let hi: Double }
    // AHA/ACCF/HRS 2009 Part III table; adult limits from 16 years (see axisEngine.js).
    public static let pedsBands: [PedsBand] = [
        PedsBand(id: "neonate",  maxDays: 30,       lo: 30, hi: 190),
        PedsBand(id: "1m_1y",    maxDays: 365,      lo: 10, hi: 120),
        PedsBand(id: "1y_5y",    maxDays: 5 * 365,  lo: 5,  hi: 100),
        PedsBand(id: "5y_8y",    maxDays: 8 * 365,  lo: 0,  hi: 140),
        PedsBand(id: "8y_16y",   maxDays: 16 * 365, lo: 0,  hi: 120),
    ]

    public struct Classification: Equatable {
        public var key: String
        public var severity: String          // normal | borderline | abnormal
        public var population: String? = nil // adult | peds (QRS only)
        public var band: PedsBand? = nil
        public var keys: [String]? = nil     // for "spans"
    }

    public static func classifyQrsAdult(_ q: Double) -> Classification {
        let a = normalize(q)
        if a >= -30 && a <= 90 { return .init(key: "normal", severity: "normal") }
        if a > -45 && a < -30 { return .init(key: "lad_borderline", severity: "borderline") }
        if a >= -90 && a <= -45 { return .init(key: "lad_marked", severity: "abnormal") }
        if a > 90 && a <= 180 { return .init(key: "rad", severity: "abnormal") }
        return .init(key: "extreme", severity: "abnormal")
    }

    static func pedsBand(_ ageDays: Double?) -> PedsBand? {
        guard let d = ageDays, d >= 0 else { return nil }
        return pedsBands.first { d < $0.maxDays }
    }

    public static func classifyQrs(_ q: Double, ageDays: Double?) -> Classification {
        guard let band = pedsBand(ageDays) else {
            var c = classifyQrsAdult(q); c.population = "adult"; return c
        }
        let a = normalize(q)
        if inArc(a, lo: band.lo, hi: band.hi) {
            return .init(key: "normal_for_age", severity: "normal", population: "peds", band: band)
        }
        let key = angularDiff(a, band.hi) < angularDiff(a, band.lo) ? "rightward_for_age" : "leftward_for_age"
        return .init(key: key, severity: "abnormal", population: "peds", band: band)
    }

    public static func classifyP(_ p: Double?) -> Classification {
        guard let p = p else { return .init(key: "absent", severity: "borderline") }
        let a = normalize(p)
        if abs(a) > 90 { return .init(key: "negative_lead_I", severity: "abnormal") }
        if a < 0 { return .init(key: "superior", severity: "abnormal") }
        if a <= 75 { return .init(key: "normal", severity: "normal") }
        return .init(key: "vertical", severity: "borderline")
    }

    public static func classifyT(_ t: Double?) -> Classification? {
        guard let t = t else { return nil }
        let a = normalize(t)
        return (a >= 0 && a <= 90) ? .init(key: "normal", severity: "normal")
                                   : .init(key: "outside_reference", severity: "borderline")
    }

    public struct Modifiers: Equatable {
        public var lbbb = false, rbbb = false, paced = false, lvh = false, wpw = false, wideQrs = false
        public init(lbbb: Bool = false, rbbb: Bool = false, paced: Bool = false,
                    lvh: Bool = false, wpw: Bool = false, wideQrs: Bool = false) {
            self.lbbb = lbbb; self.rbbb = rbbb; self.paced = paced
            self.lvh = lvh; self.wpw = wpw; self.wideQrs = wideQrs
        }
        var anySecondaryRepol: Bool { lbbb || rbbb || paced || lvh || wpw || wideQrs }
    }

    public struct QrsT: Equatable { public let angle: Int; public let key: String; public let highRisk: Bool }

    public static func qrsTAngle(_ q: Double?, _ t: Double?, _ m: Modifiers) -> QrsT? {
        guard let q = q, let t = t else { return nil }
        let angle = Int(jsRound(angularDiff(q, t)))
        let key: String
        if m.anySecondaryRepol { key = "secondary_repolarization" }
        else if angle < 45 { key = "normal" }
        else if angle <= 90 { key = "borderline" }
        else { key = "abnormal" }
        return QrsT(angle: angle, key: key, highRisk: !m.anySecondaryRepol && angle >= 100)
    }

    /// JS Math.round semantics (halves round toward +∞) for exact parity.
    static func jsRound(_ x: Double) -> Double { (x + 0.5).rounded(.down) }

    // MARK: P-R-T parsing

    public struct Parsed { public var p: Double?; public var qrs: Double?; public var t: Double?; public var warnings: [String] }
    public enum ParseError: String, Error { case empty, unparseable, qrs_missing, out_of_range }

    static let tokenPattern = try! NSRegularExpression(
        pattern: "(-?\\d{1,3}(?:\\.\\d+)?|\\*{1,3}|-{2,3}|n/?a)", options: [.caseInsensitive])
    static let namedPattern = try! NSRegularExpression(
        pattern: "\\b(P|QRS|R|T)\\b\\s*(?:axis)?\\s*[:=]?\\s*(-?\\d{1,3}(?:\\.\\d+)?|\\*{1,3}|-{2,3})",
        options: [.caseInsensitive])

    static func tokens(_ s: String) -> [String] {
        let ns = s as NSString
        return tokenPattern.matches(in: s, range: NSRange(location: 0, length: ns.length))
            .map { ns.substring(with: $0.range) }
    }

    static func tokenValue(_ tok: String) -> Double? {
        guard let f = tok.first, f == "-" || f.isNumber else { return nil }
        return Double(tok) // "---" -> nil
    }

    public static func parsePRT(_ text: String) -> Result<Parsed, ParseError> {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return .failure(.empty) }
        let s = text.replacingOccurrences(of: "\u{2212}", with: "-")
                    .replacingOccurrences(of: "\u{2013}", with: "-")
                    .replacingOccurrences(of: "\u{2014}", with: "-")
        var warnings: [String] = []
        var p: Double?, qrs: Double?, t: Double?

        func fromTokens(_ toks: [String]) -> Bool {
            if toks.count >= 3 {
                p = tokenValue(toks[0]); qrs = tokenValue(toks[1]); t = tokenValue(toks[2]); return true
            } else if toks.count == 2 {
                p = nil; qrs = tokenValue(toks[0]); t = tokenValue(toks[1])
                warnings.append("p_assumed_absent"); return true
            }
            return false
        }

        if let r = s.lowercased().range(of: "axes", options: .backwards) {
            let offset = s.lowercased().distance(from: s.lowercased().startIndex, to: r.upperBound)
            let tail = String(s.dropFirst(offset))
            if !fromTokens(tokens(tail)) { return .failure(.unparseable) }
        } else {
            let ns = s as NSString
            var named: [String: Double?] = [:]
            for m in namedPattern.matches(in: s, range: NSRange(location: 0, length: ns.length)) {
                var k = ns.substring(with: m.range(at: 1)).uppercased()
                if k == "R" { k = "QRS" }
                if named[k] == nil { named[k] = .some(tokenValue(ns.substring(with: m.range(at: 2)))) }
            }
            if let q = named["QRS"] {
                qrs = q
                p = named["P"] ?? nil
                t = named["T"] ?? nil
            } else if !fromTokens(tokens(s)) {
                return .failure(.unparseable)
            }
        }
        guard let q = qrs else { return .failure(.qrs_missing) }
        for v in [p, q, t].compactMap({ $0 }) where v < -360 || v > 360 { return .failure(.out_of_range) }
        return .success(Parsed(p: p.map(normalize), qrs: normalize(q), t: t.map(normalize), warnings: warnings))
    }

    // MARK: Polarity solver (quadrant / three-lead / isoelectric)

    public enum Polarity: String { case pos, neg, iso }
    public struct Arc: Equatable { public let from: Int; public let to: Int; public let width: Int; public let mid: Double }
    public struct PolaritySolution { public let status: String; public let arcs: [Arc] }

    public static func solvePolarities(_ pol: [String: Polarity]) -> PolaritySolution {
        let keys = leadOrder.filter { pol[$0] != nil }
        if keys.isEmpty { return .init(status: "no_input", arcs: []) }
        var hits: [Int] = []
        for d in -179...180 {
            var ok = true
            for k in keys {
                let c = cos(rad(Double(d) - leads[k]!.angle))
                switch pol[k]! {
                case .pos: if !(c > 1e-9) { ok = false }
                case .neg: if !(c < -1e-9) { ok = false }
                case .iso: if abs(c) > 1e-9 { ok = false }
                }
                if !ok { break }
            }
            if ok { hits.append(d) }
        }
        if hits.isEmpty { return .init(status: "inconsistent", arcs: []) }
        var raw: [(Int, Int)] = []
        var start = hits[0], prev = hits[0]
        for h in hits.dropFirst() {
            if h != prev + 1 { raw.append((start, prev)); start = h }
            prev = h
        }
        raw.append((start, prev))
        if raw.count > 1, raw.first!.0 == -179, raw.last!.1 == 180 {
            let last = raw.removeLast()
            raw[0] = (last.0, raw[0].1)
        }
        let arcs = raw.map { (from, to) -> Arc in
            let width = to >= from ? to - from : to + 360 - from
            return Arc(from: from, to: to, width: width, mid: normalize(Double(from) + Double(width) / 2))
        }
        return .init(status: arcs.count == 1 ? "resolved" : "ambiguous", arcs: arcs)
    }

    // MARK: Amplitude solver (precise)

    public struct AmplitudeSolution { public let status: String; public let axis: Int?; public let warnings: [String] }

    public static func solveAmplitudes(_ amps: [String: Double]) -> AmplitudeSolution {
        let keys = leadOrder.filter { amps[$0] != nil && amps[$0]!.isFinite }
        if keys.count < 2 { return .init(status: "need_two_leads", axis: nil, warnings: []) }
        var sxx = 0.0, sxy = 0.0, syy = 0.0, bx = 0.0, by = 0.0
        for k in keys {
            let l = leads[k]!
            let ux = l.gain * cos(rad(l.angle)), uy = l.gain * sin(rad(l.angle))
            let v = amps[k]!
            sxx += ux * ux; sxy += ux * uy; syy += uy * uy; bx += ux * v; by += uy * v
        }
        let det = sxx * syy - sxy * sxy
        let x = (syy * bx - sxy * by) / det
        let y = (sxx * by - sxy * bx) / det
        var warnings: [String] = []
        if ["I", "II", "III"].allSatisfy(keys.contains),
           abs(amps["I"]! + amps["III"]! - amps["II"]!) > 1 { warnings.append("einthoven_mismatch") }
        if ["aVR", "aVL", "aVF"].allSatisfy(keys.contains),
           abs(amps["aVR"]! + amps["aVL"]! + amps["aVF"]!) > 1 { warnings.append("goldberger_mismatch") }
        if hypot(x, y) < 0.25 { return .init(status: "indeterminate", axis: nil, warnings: warnings) }
        let axis = Int(jsRound(normalize(deg(atan2(y, x)))))
        return .init(status: "resolved", axis: axis, warnings: warnings)
    }

    // MARK: Interpret

    public enum Input {
        case prtText(String)
        case prtValues(p: Double?, qrs: Double?, t: Double?)
        case polarities([String: Polarity])
        case amplitudes([String: Double])
    }

    public struct AxisResult {
        public var status = "ok"
        public var error: String? = nil
        public var qrsAxis: Double? = nil
        public var qrsEstimate: Int? = nil
        public var qrsRange: [Int]? = nil
        public var qrsClass: Classification? = nil
        public var pAxis: Double? = nil
        public var pClass: Classification? = nil
        public var tAxis: Double? = nil
        public var tClass: Classification? = nil
        public var qrsT: QrsT? = nil
        public var flags: [String] = []
        public var warnings: [String] = []
        public var differential: String? = nil
    }

    static func flagsFor(p: Double?, qrs: Double?, pClass: Classification?, qrsClass: Classification?,
                         m: Modifiers, ageDays: Double?) -> [String] {
        var flags: [String] = []
        if let p = p, let q = qrs, abs(normalize(p)) > 90, abs(normalize(q)) > 90 {
            flags.append("limb_lead_reversal_vs_dextrocardia")
        }
        if let c = qrsClass, c.population == "adult" {
            let confounder = m.lbbb || m.paced || m.wideQrs
            if c.key == "lad_marked" && !confounder { flags.append("lafb_checklist") }
            if c.key == "rad" && !confounder { flags.append("lpfb_checklist") }
        }
        if let c = qrsClass, c.population == "peds", let age = ageDays, age < 365,
           let q = qrs, normalize(q) < -90 { flags.append("infant_superior_axis") }
        if m.paced { flags.append("paced_axis_caveat") }
        if pClass?.key == "absent" { flags.append("check_rhythm_no_p") }
        return flags
    }

    static func differentialKey(_ c: Classification?) -> String? {
        guard let c = c, c.population == "adult" else { return nil }
        if c.key.hasPrefix("lad") { return "lad" }
        if c.key == "rad" { return "rad" }
        if c.key == "extreme" { return "extreme" }
        return nil
    }

    public static func interpret(_ input: Input, ageDays: Double? = nil, modifiers m: Modifiers = .init()) -> AxisResult {
        var r = AxisResult()
        switch input {
        case .prtText, .prtValues:
            var p: Double?, qrs: Double?, t: Double?
            if case .prtText(let text) = input {
                switch parsePRT(text) {
                case .failure(let e): r.status = "error"; r.error = e.rawValue; return r
                case .success(let parsed): p = parsed.p; qrs = parsed.qrs; t = parsed.t; r.warnings += parsed.warnings
                }
            } else if case .prtValues(let pp, let qq, let tt) = input { p = pp; qrs = qq; t = tt }
            guard let q0 = qrs else { r.status = "error"; r.error = "qrs_missing"; return r }
            let q = normalize(q0)
            let pn = p.map(normalize), tn = t.map(normalize)
            r.qrsAxis = q; r.qrsClass = classifyQrs(q, ageDays: ageDays)
            r.pAxis = pn; r.pClass = classifyP(pn)
            r.tAxis = tn; r.tClass = classifyT(tn)
            r.qrsT = qrsTAngle(q, tn, m)
            if r.qrsT?.highRisk == true { r.flags.append("qrs_t_angle_high_risk") }
            r.flags += flagsFor(p: pn, qrs: q, pClass: r.pClass, qrsClass: r.qrsClass, m: m, ageDays: ageDays)

        case .polarities(let pol):
            let sol = solvePolarities(pol)
            guard sol.status == "resolved", let arc = sol.arcs.first else { r.status = sol.status; return r }
            var cats: [String] = []
            for i in 0...arc.width {
                let k = classifyQrs(normalize(Double(arc.from + i)), ageDays: ageDays).key
                if !cats.contains(k) { cats.append(k) }
            }
            r.qrsAxis = arc.width == 0 ? Double(arc.from) : nil
            r.qrsEstimate = Int(jsRound(arc.mid))
            r.qrsRange = [arc.from, arc.to]
            r.qrsClass = cats.count == 1 ? classifyQrs(arc.mid, ageDays: ageDays)
                                         : Classification(key: "spans", severity: "borderline", keys: cats)
            if cats.count > 1 && pol["II"] == nil && cats.contains("normal") && cats.contains(where: { $0.hasPrefix("lad") }) {
                r.warnings.append("add_lead_II")
            } else if cats.count > 1 {
                r.warnings.append("add_leads_or_use_precise")
            }
            if cats.count == 1 {
                r.flags += flagsFor(p: nil, qrs: arc.mid, pClass: nil, qrsClass: r.qrsClass, m: m, ageDays: ageDays)
            }

        case .amplitudes(let amps):
            let sol = solveAmplitudes(amps)
            r.warnings += sol.warnings
            guard sol.status == "resolved", let axis = sol.axis else { r.status = sol.status; return r }
            r.qrsAxis = Double(axis); r.qrsClass = classifyQrs(Double(axis), ageDays: ageDays)
            r.flags += flagsFor(p: nil, qrs: Double(axis), pClass: nil, qrsClass: r.qrsClass, m: m, ageDays: ageDays)
        }
        r.differential = differentialKey(r.qrsClass)
        return r
    }
}
