import Foundation

// Port of Resources/TraumaActivation/trauma-engine-reference.js. Pure; no UI,
// no storage. Every criterion, threshold, tier and string comes from the
// profile JSON.

public enum TraumaEngineError: Error, Equatable { case unknownOperator(String) }

/// Three-valued expression evaluation: a number, a Bool, or nil (unknown).
public enum EvalValue: Equatable { case number(Double), bool(Bool) }

public func traumaEv(_ node: JSONValue?, _ vitals: [String: Double]) throws -> EvalValue? {
    guard let node else { return nil }
    switch node {
    case .number(let n): return .number(n)
    case .object(let o):
        if let v = o["var"] {
            guard let name = v.string, let x = vitals[name], x.isFinite else { return nil }
            return .number(x)
        }
        guard let (op, rawArgs) = o.first else { throw TraumaEngineError.unknownOperator("") }
        let args = rawArgs.array ?? []
        func vals() throws -> [EvalValue?] { try args.map { try traumaEv($0, vitals) } }
        func num(_ v: EvalValue?) -> Double? { if case .number(let n) = v { return n }; return nil }
        switch op {
        case "lt", "lte", "gt", "gte":
            let v = try vals()
            guard v.count >= 2, let a = num(v[0]), let b = num(v[1]) else { return nil }
            switch op {
            case "lt": return .bool(a < b)
            case "lte": return .bool(a <= b)
            case "gt": return .bool(a > b)
            default: return .bool(a >= b)
            }
        case "add":
            let v = try vals(); let n = v.map(num)
            return n.contains(where: { $0 == nil }) ? nil : .number(n.reduce(0) { $0 + $1! })
        case "mul":
            let v = try vals(); let n = v.map(num)
            return n.contains(where: { $0 == nil }) ? nil : .number(n.reduce(1) { $0 * $1! })
        case "div":
            let v = try vals()
            guard v.count >= 2, let a = num(v[0]), let b = num(v[1]), b != 0 else { return nil }
            return .number(a / b)
        case "and":
            let v = try vals()
            if v.contains(.bool(false)) { return .bool(false) }
            return v.contains(where: { $0 == nil }) ? nil : .bool(true)
        case "or":
            let v = try vals()
            if v.contains(.bool(true)) { return .bool(true) }
            return v.contains(where: { $0 == nil }) ? nil : .bool(false)
        default:
            throw TraumaEngineError.unknownOperator(op)
        }
    default:
        // Strings, bools, null; arrays have no operator.
        if case .array = node { throw TraumaEngineError.unknownOperator("0") }
        return nil
    }
}

public struct TraumaInput: Equatable {
    public var checked: [String]
    public var vitals: [String: Double]
    public init(checked: [String] = [], vitals: [String: Double] = [:]) { self.checked = checked; self.vitals = vitals }
}

public struct TraumaMet: Equatable { public let id: String; public let tier: String; public let source: String }
public struct TraumaText: Equatable { public let id: String; public let text: String }
public struct TraumaError: Equatable { public let code: String; public let vital: String?; public let text: String }

public struct TraumaResult: Equatable {
    public let status: String
    public let errors: [TraumaError]
    public let tier: String?
    public let met: [TraumaMet]
    public let compoundHints: [TraumaText]
    public let notes: [TraumaText]
    public let advisories: [TraumaText]
    public let teamResponse: [String]?
    public let responseTime: String?
}

public func traumaEvaluate(profile: JSONValue, input: TraumaInput) throws -> TraumaResult {
    let checked = Set(input.checked)
    let vitals = input.vitals
    var errors: [TraumaError] = []
    let criteria = profile["criteria"]?.array ?? []

    for def in profile["vitals"]?.array ?? [] {
        guard let id = def["id"]?.string, let v = vitals[id] else { continue }
        let lo = def["min"]?.number ?? -.infinity, hi = def["max"]?.number ?? .infinity
        if !v.isFinite || v < lo || v > hi {
            let label = def["label"]?.string ?? id
            errors.append(TraumaError(code: "vital_out_of_range", vital: id,
                                      text: "\(label) must be between \(jsNumberString(lo)) and \(jsNumberString(hi))."))
        }
    }
    let ids = Set(criteria.compactMap { $0["id"]?.string })
    for id in input.checked where !ids.contains(id) {
        errors.append(TraumaError(code: "unknown_criterion", vital: nil, text: "Unknown criterion \(id)."))
    }
    if !errors.isEmpty {
        return TraumaResult(status: "error", errors: errors, tier: nil, met: [], compoundHints: [], notes: [], advisories: [], teamResponse: nil, responseTime: nil)
    }

    var met: [TraumaMet] = []
    var isMet = Set<String>()
    // Pass 1: ordinary and discretion criteria.
    for c in criteria {
        guard let id = c["id"]?.string, let tier = c["tier"]?.string else { continue }
        let kind = c["kind"]?.string
        if kind == "criterion" {
            if checked.contains(id) { met.append(TraumaMet(id: id, tier: tier, source: "checked")); isMet.insert(id) }
            else if let auto = c["auto"], auto.truthy, try traumaEv(auto["rule"], vitals) == .bool(true) {
                met.append(TraumaMet(id: id, tier: tier, source: "auto")); isMet.insert(id)
            }
        } else if kind == "discretion", checked.contains(id) {
            met.append(TraumaMet(id: id, tier: tier, source: "discretion")); isMet.insert(id)
        }
    }
    // Pass 2: compound criteria. "Any criterion of tier X" counts only kind == "criterion".
    var hints: [TraumaText] = []
    for c in criteria where c["kind"]?.string == "compound" {
        guard let id = c["id"]?.string, let tier = c["tier"]?.string else { continue }
        let comp = c["compound"]
        let baseAuto = comp?["base_auto"]
        var base = checked.contains(id)
        if !base, baseAuto?.truthy ?? false { base = try traumaEv(baseAuto, vitals) == .bool(true) }
        if !base { continue }
        let reqTier = comp?["requires_any_criterion_of_tier"]?.string
        let satisfied = criteria.contains { o in
            o["kind"]?.string == "criterion" && o["tier"]?.string == reqTier && (o["id"]?.string).map(isMet.contains) == true
        }
        if satisfied { met.append(TraumaMet(id: id, tier: tier, source: "compound")); isMet.insert(id) }
        else { hints.append(TraumaText(id: id, text: comp?["unmet_hint"]?.string ?? "")) }
    }

    let tiers = profile["tiers"]?.array ?? []
    var rank: [String: Double] = [:]
    for t in tiers { if let id = t["id"]?.string { rank[id] = t["rank"]?.number ?? 0 } }
    var tier: String?
    for m in met where tier == nil || (rank[m.tier] ?? -.infinity) > (rank[tier!] ?? -.infinity) { tier = m.tier }
    let tierDef = tiers.first { $0["id"]?.string == tier && tier != nil }

    let notes = criteria.compactMap { c -> TraumaText? in
        guard let id = c["id"]?.string, isMet.contains(id), let n = c["note"], n.truthy else { return nil }
        return TraumaText(id: id, text: n.string ?? "")
    }
    let advisories = criteria.compactMap { c -> TraumaText? in
        guard c["kind"]?.string == "advisory", let tier, c["show_when_result_tier"]?.string == tier,
              let id = c["id"]?.string else { return nil }
        return TraumaText(id: id, text: c["text"]?.string ?? "")
    }
    return TraumaResult(status: "ok", errors: errors, tier: tier, met: met, compoundHints: hints, notes: notes, advisories: advisories,
                        teamResponse: tierDef?["team_response"]?.array?.compactMap(\.string),
                        responseTime: tierDef?["response_time"]?.string)
}
