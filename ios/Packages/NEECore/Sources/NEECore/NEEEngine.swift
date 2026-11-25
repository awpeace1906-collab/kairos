import Foundation

// NEE engine — a port of Resources/NEE/nee-engine-reference.js. Pure: no UI,
// no storage. Input and output mirror the JS shape field for field. Factors are
// fractions computed in Double; nothing is rounded here (display only).
// JS twin: web/src/lib/neeEngine.js.

public struct NEEInfusion: Equatable {
    public var agent: String
    /// Not finite (e.g. .nan) marks a value that is not a number.
    public var dose: Double
    public var unit: String
    public init(agent: String, dose: Double, unit: String) { self.agent = agent; self.dose = dose; self.unit = unit }
}

public struct NEEInput: Equatable {
    public var formulaId: String?
    public var weightKg: Double?
    public var neSalt: String?
    public var infusions: [NEEInfusion]
    public init(formulaId: String? = nil, weightKg: Double? = nil, neSalt: String? = nil, infusions: [NEEInfusion] = []) {
        self.formulaId = formulaId; self.weightKg = weightKg; self.neSalt = neSalt; self.infusions = infusions
    }
}

public struct NEEMessage: Equatable {
    public let code: String
    public let agent: String?
    public let unit: String?
    public let text: String
}

public struct NEEBreakdownRow: Equatable {
    public let agent: String
    public let doseEntered: Double
    public let unitEntered: String
    public let doseCanonical: Double
    public let canonicalUnit: String
    public let factor: Double?
    public let contribution: Double
    public let counted: Bool
    public let adjunct: Bool
}

public struct NEEResult: Equatable {
    public let status: String          // "ok" | "error"
    public let formula: String
    public let errors: [NEEMessage]
    public let warnings: [NEEMessage]
    public let info: [NEEMessage]
    public let neeMcgKgMin: Double?
    public let neeMcgMin: Double?
    public let adjunctMcgKgMin: Double?
    public let breakdown: [NEEBreakdownRow]
}

func fill(_ template: String, _ vars: [String: String]) -> String {
    var out = template
    for (k, v) in vars { out = out.replacingOccurrences(of: "{\(k)}", with: v) }
    return out
}

/// JS `String(number)` for the unit/agent placeholders is only ever applied to
/// strings here, so plain interpolation matches.
public func computeNEE(logic: NEELogic, input: NEEInput) -> NEEResult {
    var errors: [NEEMessage] = []
    var warnings: [NEEMessage] = []
    var info: [NEEMessage] = []
    let msg = logic.messages

    let formula = logic.formula(input.formulaId)!
    let saltId = input.neSalt ?? logic.norepinephrineSalt.defaultId
    let salt = logic.norepinephrineSalt.options.first { $0.id == saltId }

    let weight = input.weightKg
    if let w = weight {
        if !w.isFinite || w < logic.weight.minInclusive || w > logic.weight.maxInclusive {
            errors.append(NEEMessage(code: "weight_out_of_range", agent: nil, unit: nil, text: msg["error_weight_out_of_range"] ?? ""))
        }
    }

    var seen = Set<String>()
    var rows: [(inf: NEEInfusion, agent: NEELogic.Agent, unitDef: NEELogic.Agent.InputUnit)] = []
    for inf in input.infusions {
        let agent = logic.agent(inf.agent)
        let label = agent?.label ?? inf.agent
        if seen.contains(inf.agent) {
            errors.append(NEEMessage(code: "duplicate_agent", agent: inf.agent, unit: nil, text: fill(msg["error_duplicate_agent"] ?? "", ["agent": label])))
            continue
        }
        seen.insert(inf.agent)
        if !inf.dose.isFinite {
            errors.append(NEEMessage(code: "non_numeric_dose", agent: inf.agent, unit: nil, text: fill(msg["error_non_numeric_dose"] ?? "", ["agent": label])))
            continue
        }
        if inf.dose < 0 {
            errors.append(NEEMessage(code: "negative_dose", agent: inf.agent, unit: nil, text: fill(msg["error_negative_dose"] ?? "", ["agent": label])))
            continue
        }
        if inf.dose == 0 { continue } // zero_dose: ignore_row
        guard let agent, let unitDef = agent.inputUnits.first(where: { $0.unit == inf.unit }) else {
            errors.append(NEEMessage(code: "unknown_unit", agent: inf.agent, unit: inf.unit, text: fill(msg["error_unknown_unit"] ?? "", ["agent": label, "unit": inf.unit])))
            continue
        }
        if unitDef.perWeight && weight == nil {
            errors.append(NEEMessage(code: "weight_required", agent: inf.agent, unit: inf.unit, text: fill(msg["error_weight_required"] ?? "", ["agent": label, "unit": inf.unit])))
            continue
        }
        rows.append((inf, agent, unitDef))
    }

    if !errors.isEmpty {
        return NEEResult(status: "error", formula: formula.id, errors: errors, warnings: warnings, info: info,
                         neeMcgKgMin: nil, neeMcgMin: nil, adjunctMcgKgMin: nil, breakdown: [])
    }

    var breakdown: [NEEBreakdownRow] = []
    var total = 0.0
    var adjunctTotal: Double?
    for (inf, agent, unitDef) in rows {
        var canonical = inf.dose * unitDef.multiply.value
        if unitDef.perWeight, let w = weight { canonical = canonical / w }
        if agent.id == logic.norepinephrineSalt.appliesToAgent, let salt { canonical = canonical * salt.factorToBase.value }
        guard let f = formula.factors[agent.id] else {
            warnings.append(NEEMessage(code: "agent_not_in_formula", agent: agent.id, unit: nil,
                                       text: fill(msg["warning_agent_not_in_formula"] ?? "", ["agent": agent.label, "formula": formula.label])))
            breakdown.append(NEEBreakdownRow(agent: agent.id, doseEntered: inf.dose, unitEntered: inf.unit, doseCanonical: canonical,
                                             canonicalUnit: agent.canonicalUnit, factor: nil, contribution: 0, counted: false, adjunct: agent.isAdjunct))
            continue
        }
        let factor = f.factor.value
        let contribution = canonical * factor
        if agent.isAdjunct {
            // rules.adjunct_role: computed with the formula's factor, shown separately, never added.
            adjunctTotal = (adjunctTotal ?? 0) + contribution
            breakdown.append(NEEBreakdownRow(agent: agent.id, doseEntered: inf.dose, unitEntered: inf.unit, doseCanonical: canonical,
                                             canonicalUnit: agent.canonicalUnit, factor: factor, contribution: contribution, counted: false, adjunct: true))
            continue
        }
        total += contribution
        breakdown.append(NEEBreakdownRow(agent: agent.id, doseEntered: inf.dose, unitEntered: inf.unit, doseCanonical: canonical,
                                         canonicalUnit: agent.canonicalUnit, factor: factor, contribution: contribution, counted: true, adjunct: false))
    }

    if rows.isEmpty {
        info.append(NEEMessage(code: "no_inputs", agent: nil, unit: nil, text: msg["info_no_inputs"] ?? ""))
    }

    // Canonical doses actually entered (norepinephrine already converted to base); adjuncts excluded.
    var canonicalByAgent: [String: Double] = [:]
    for b in breakdown where !b.adjunct { canonicalByAgent[b.agent] = b.doseCanonical }
    for note in logic.contextNotes where note.type == "info" {
        guard let conds = note.showWhenAll else { continue }
        let show = conds.allSatisfy { c in
            let d = c.agent.flatMap { canonicalByAgent[$0] }
            if c.adjunctEstimatePresent == true { return adjunctTotal != nil }
            if c.absent == true { return d == nil }
            if let gte = c.canonicalDoseGte { return d.map { $0 >= gte.value } ?? false }
            return false
        }
        if show { info.append(NEEMessage(code: note.id, agent: nil, unit: nil, text: note.text)) }
    }

    return NEEResult(status: "ok", formula: formula.id, errors: errors, warnings: warnings, info: info,
                     neeMcgKgMin: total, neeMcgMin: weight.map { total * $0 }, adjunctMcgKgMin: adjunctTotal, breakdown: breakdown)
}

/// Sources for the screen, per ui.sources_rule: the selected formula's
/// citation, then the citation of every note shown, each once, in order.
public func neeSourceIds(logic: NEELogic, formulaId: String?, shownNoteIds: [String]) -> [String] {
    var ids: [String] = []
    if let f = logic.formula(formulaId) { ids.append(f.citationId) }
    for nid in shownNoteIds { if let n = logic.note(nid), !ids.contains(n.citationId) { ids.append(n.citationId) } }
    return ids
}
