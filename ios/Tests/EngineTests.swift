import XCTest
@testable import Kairos

/// Mirrors tools/test.mjs — the Swift engine ports are line-for-line copies of the
/// web modules, so the same cases run here against Expression / CalculatorEngine /
/// WeightZones.
final class EngineTests: XCTestCase {

    private let decoder = JSONDecoder()
    private func decode<T: Decodable>(_ type: T.Type, _ json: String) throws -> T {
        try decoder.decode(T.self, from: Data(json.utf8))
    }

    // MARK: - Expression

    func testExpressionPrecedenceAndPow() throws {
        XCTAssertEqual(try Expression.evaluate("2+3*4", scope: [:]), 14, accuracy: 1e-9)
        XCTAssertEqual(try Expression.evaluate("(2+3)*4", scope: [:]), 20, accuracy: 1e-9)
        XCTAssertEqual(try Expression.evaluate("2^3^2", scope: [:]), 512, accuracy: 1e-9)   // right-assoc
        XCTAssertEqual(try Expression.evaluate("-5 + 3", scope: [:]), -2, accuracy: 1e-9)
    }

    func testExpressionFunctionsAndVars() throws {
        XCTAssertEqual(try Expression.evaluate("150 * 2 ^ (-(8-4)/4)", scope: [:]), 75, accuracy: 1e-9)
        XCTAssertEqual(try Expression.evaluate("cbrt(27)", scope: [:]), 3, accuracy: 1e-9)
        XCTAssertEqual(try Expression.evaluate("min(3,5,1)", scope: [:]), 1, accuracy: 1e-9)
        XCTAssertEqual(try Expression.evaluate("qt / sqrt(60 / hr)", scope: ["qt": 400, "hr": 80]),
                       400 / (0.75.squareRoot()), accuracy: 1e-6)
        // Holliday-Segar 4-2-1 piecewise
        let hs = "4 * min(weight, 10) + 2 * max(0, min(weight - 10, 10)) + 1 * max(0, weight - 20)"
        XCTAssertEqual(try Expression.evaluate(hs, scope: ["weight": 8]), 32, accuracy: 1e-9)
        XCTAssertEqual(try Expression.evaluate(hs, scope: ["weight": 15]), 50, accuracy: 1e-9)
        XCTAssertEqual(try Expression.evaluate(hs, scope: ["weight": 25]), 65, accuracy: 1e-9)
    }

    func testExpressionThrows() {
        XCTAssertThrowsError(try Expression.evaluate("foo + 1", scope: [:]))
        XCTAssertThrowsError(try Expression.evaluate("frobnicate(2)", scope: [:]))
        XCTAssertThrowsError(try Expression.evaluate("2 + +", scope: [:]))
    }

    // MARK: - CalculatorEngine

    private let additiveFixture = """
    {
      "id":"t-additive","section":"Calculators","category":"Test","title":"T","contentType":"calculator",
      "content_version":1,"engine":"additive","purpose":"a test calculator purpose",
      "items":[
        {"key":"a","label":"A","options":[{"label":"no","points":0},{"label":"yes","points":2}]},
        {"key":"b","label":"B","options":[{"label":"lo","points":0},{"label":"mid","points":1},{"label":"hi","points":2}]}
      ],
      "interpretation":[
        {"min":0,"max":1,"label":"Low","severity":"low"},
        {"min":2,"max":4,"label":"High","severity":"high"}
      ]
    }
    """

    func testAdditiveEngine() throws {
        let calc = try decode(Calculator.self, additiveFixture)

        let full = CalculatorEngine.run(calc, itemChoices: ["a": 1, "b": 2], inputs: [:])
        XCTAssertEqual(full.score, 4)
        XCTAssertFalse(full.incomplete)
        XCTAssertEqual(full.bands.first?.label, "High")

        let zero = CalculatorEngine.run(calc, itemChoices: ["a": 0, "b": 0], inputs: [:])
        XCTAssertEqual(zero.score, 0)
        XCTAssertEqual(zero.bands.first?.label, "Low")

        let partial = CalculatorEngine.run(calc, itemChoices: ["a": 1], inputs: [:])
        XCTAssertTrue(partial.incomplete)
        XCTAssertTrue(partial.bands.isEmpty)
    }

    private let formulaFixture = """
    {
      "id":"t-formula","section":"Calculators","category":"Test","title":"T","contentType":"calculator",
      "content_version":1,"engine":"formula","purpose":"a test formula purpose",
      "inputs":[{"key":"qt","label":"QT","type":"number"},{"key":"hr","label":"HR","type":"number"}],
      "formulas":[
        {"key":"bazett","label":"Bazett","expression":"qt / sqrt(60 / hr)","unit":"ms","precision":0},
        {"key":"fridericia","label":"Fridericia","expression":"qt / cbrt(60 / hr)","unit":"ms","precision":0}
      ],
      "interpretation":[{"forKey":"bazett","min":440,"max":499,"label":"Borderline","severity":"moderate"}]
    }
    """

    func testFormulaEngine() throws {
        let calc = try decode(Calculator.self, formulaFixture)
        let r = CalculatorEngine.run(calc, itemChoices: [:], inputs: ["qt": "400", "hr": "80"])
        let bazett = r.formulaValues.first { $0.key == "bazett" }
        let frid = r.formulaValues.first { $0.key == "fridericia" }
        XCTAssertEqual(bazett?.value, 462)
        XCTAssertEqual(frid?.value, 440)
        XCTAssertEqual(r.bandsByKey["bazett"]?.first?.label, "Borderline")

        let empty = CalculatorEngine.run(calc, itemChoices: [:], inputs: [:])
        XCTAssertTrue(empty.formulaValues.isEmpty)
    }

    func testExternalEngineIsIncomplete() throws {
        let json = """
        {"id":"t-ext","section":"Calculators","category":"Test","title":"T","contentType":"calculator",
         "content_version":1,"engine":"external","purpose":"an external calculator purpose",
         "interpretation":[{"label":"see build note"}]}
        """
        let calc = try decode(Calculator.self, json)
        XCTAssertTrue(CalculatorEngine.run(calc, itemChoices: [:], inputs: [:]).incomplete)
    }

    // MARK: - WeightZones

    private let zonesFixture = """
    {
      "scheme":"test","disclaimer":"test disclaimer",
      "ageEstimate":{"note":"n","formulas":[
        {"ageBandLabel":"1-5y","minMonths":12,"maxMonths":72,"expression":"(2 * ageYears) + 8"}
      ]},
      "zones":[
        {"zone":1,"color":"Teal","weight_min":3,"weight_max":5,"equipment":{}},
        {"zone":4,"color":"Violet","weight_min":12,"weight_max":14,"equipment":{}},
        {"zone":5,"color":"Amber","weight_min":15,"weight_max":18,"equipment":{}},
        {"zone":9,"color":"Charcoal","weight_min":37,"weight_max":50,"equipment":{}}
      ]
    }
    """

    func testZoneGapHandling() throws {
        let cfg = try decode(WeightZonesConfig.self, zonesFixture)
        XCTAssertEqual(WeightZones.zone(for: 14.3, in: cfg)?.zone, 4)   // gap → lower zone
        XCTAssertEqual(WeightZones.zone(for: 2, in: cfg)?.zone, 1)      // clamp low
        XCTAssertEqual(WeightZones.zone(for: 100, in: cfg)?.zone, 9)    // clamp high
        XCTAssertEqual(WeightZones.zone(for: 15, in: cfg)?.zone, 5)     // exact boundary
        XCTAssertNil(WeightZones.zone(for: .nan, in: cfg))
    }

    func testEstimateWeight() throws {
        let cfg = try decode(WeightZonesConfig.self, zonesFixture)
        let est = WeightZones.estimateWeight(ageYears: 2, in: cfg)
        XCTAssertEqual(est?.weightKg, 12)
        XCTAssertEqual(est?.estimated, true)
    }

    func testDoseClamps() throws {
        let atropine = try decode(DrugCard.Rule.self, #"{"perKg":0.02,"unit":"mg","minDose":0.1,"maxDose":0.5}"#)
        let lo = WeightZones.dose(from: atropine, weightKg: 3)
        XCTAssertEqual(lo?.amount, 0.1)
        XCTAssertEqual(lo?.floored, true)
        let hi = WeightZones.dose(from: atropine, weightKg: 30)
        XCTAssertEqual(hi?.amount, 0.5)
        XCTAssertEqual(hi?.capped, true)

        let epi = try decode(DrugCard.Rule.self,
            #"{"perKg":0.01,"unit":"mg","maxDose":1,"concentration":"0.1 mg/mL","mlPerUnit":10}"#)
        let d = WeightZones.dose(from: epi, weightKg: 14.3)
        XCTAssertEqual(d?.amount ?? 0, 0.143, accuracy: 1e-6)
        XCTAssertEqual(d?.volumeMl ?? 0, 1.43, accuracy: 1e-6)
        XCTAssertEqual(d?.capped, false)

        let range = try decode(DrugCard.Rule.self, #"{"perKg":0.1,"perKgHigh":0.2,"unit":"mg"}"#)
        let r = WeightZones.dose(from: range, weightKg: 20)
        XCTAssertEqual(r?.amount, 2)
        XCTAssertEqual(r?.amountHigh, 4)
    }

    // MARK: - SearchIndex

    func testSearchRanking() {
        let entries = [
            SearchEntry(itemID: "a", title: "HEART Score", section: "Calculators", category: "Cardiovascular", tags: ["chest pain"], keywords: nil, contentType: .calculator, route: "/a"),
            SearchEntry(itemID: "b", title: "Glasgow-Blatchford", section: "Calculators", category: "GI", tags: nil, keywords: ["gbs"], contentType: .calculator, route: "/b"),
            SearchEntry(itemID: "c", title: "Wells PE", section: "Calculators", category: "Pulmonary", tags: ["chest pain"], keywords: nil, contentType: .calculator, route: "/c"),
        ]
        let idx = SearchIndex(entries: entries)
        XCTAssertEqual(idx.search("heart score").first?.itemID, "a")
        XCTAssertEqual(idx.search("gbs").first?.itemID, "b")
        XCTAssertEqual(idx.search("chest pain").count, 2)
        XCTAssertEqual(idx.search("").count, 0)
        XCTAssertEqual(idx.search("chest pain", section: "Calculators").count, 2)
    }
}
