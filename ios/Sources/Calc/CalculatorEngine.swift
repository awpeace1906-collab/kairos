import Foundation

// Interprets a Calculator. Pure. Mirrors web/src/lib/calcEngine.js.

struct CalcResult {
    struct FormulaValue: Identifiable { var id: String { key }; let key, label: String; let unit: String?; let value: Double }
    var engine: Calculator.Engine
    var score: Double = 0
    var answered: Int = 0
    var totalItems: Int = 0
    var incomplete: Bool = true
    var bands: [Calculator.Band] = []          // additive: matched band(s)
    var formulaValues: [FormulaValue] = []
    var bandsByKey: [String: [Calculator.Band]] = [:]
    var buildNote: String?
}

enum CalculatorEngine {

    /// - Parameters:
    ///   - itemChoices: item.key -> chosen option index
    ///   - inputs: input.key -> raw string value
    static func run(_ calc: Calculator, itemChoices: [String: Int], inputs: [String: String]) -> CalcResult {
        switch calc.engine {
        case .additive:       return additive(calc, itemChoices)
        case .formula:        return formula(calc, inputs)
        case .classification: return CalcResult(engine: .classification, incomplete: false, bands: calc.interpretation)
        case .external:       return CalcResult(engine: .external, incomplete: true, bands: calc.interpretation, buildNote: calc.buildNote)
        }
    }

    private static func additive(_ calc: Calculator, _ choices: [String: Int]) -> CalcResult {
        var r = CalcResult(engine: .additive)
        let items = calc.items ?? []
        r.totalItems = items.count
        for item in items {
            guard let idx = choices[item.key], item.options.indices.contains(idx) else { continue }
            r.score += item.options[idx].points
            r.answered += 1
        }
        r.incomplete = r.answered < items.count
        if !r.incomplete {
            r.bands = calc.interpretation.filter { b in
                guard let lo = b.min else { return true }
                return r.score >= lo && r.score <= (b.max ?? .greatestFiniteMagnitude)
            }
        }
        return r
    }

    private static func formula(_ calc: Calculator, _ inputs: [String: String]) -> CalcResult {
        var r = CalcResult(engine: .formula)
        var scope: [String: Double] = [:]
        for inp in calc.inputs ?? [] {
            if let raw = inputs[inp.key], let v = Double(raw) { scope[inp.key] = v }
        }
        for f in calc.formulas ?? [] {
            guard let value = try? Expression.evaluate(f.expression, scope: scope), value.isFinite else { continue }
            let rounded = round(value, f.precision ?? 2)
            r.formulaValues.append(.init(key: f.key, label: f.label, unit: f.unit, value: rounded))
            r.bandsByKey[f.key] = calc.interpretation.filter { b in
                b.forKey == f.key
                    && rounded >= (b.min ?? -.greatestFiniteMagnitude)
                    && rounded <= (b.max ?? .greatestFiniteMagnitude)
            }
        }
        r.incomplete = r.formulaValues.count < (calc.formulas?.count ?? 0)
        return r
    }

    private static func round(_ n: Double, _ p: Int) -> Double {
        let f = pow(10.0, Double(p))
        return (n * f).rounded() / f
    }
}
