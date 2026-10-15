import XCTest
import ExtubationEngine
@testable import Kairos

/// The app ships the kit's extubation-logic.json byte for byte, it loads with
/// alerts in JSON order, and the engine as linked into the app passes every
/// vignette. (The package's own `swift test` runs the same vignettes.)
final class ExtubationBundleTests: XCTestCase {
    /// <repo>/Resources/Extubation, found relative to this file.
    static let kitDir: URL = {
        var u = URL(fileURLWithPath: #filePath)
        for _ in 0..<3 { u.deleteLastPathComponent() } // file, Tests, ios
        return u.appendingPathComponent("Resources/Extubation")
    }()

    private func bundledLogicData() throws -> Data {
        try Data(contentsOf: XCTUnwrap(Bundle.main.url(forResource: "extubation-logic", withExtension: "json")))
    }

    func testBundledLogicIsByteIdenticalToKit() throws {
        let kit = try Data(contentsOf: Self.kitDir.appendingPathComponent("extubation-logic.json"))
        XCTAssertEqual(try bundledLogicData(), kit, "the app bundle's extubation-logic.json differs from Resources/Extubation")
    }

    func testVignettesAgainstBundledLogic() throws {
        let logic = try ExtubationLogic.load(from: bundledLogicData())
        let raw = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(contentsOf: Self.kitDir.appendingPathComponent("extubation-vignettes.json"))) as? [String: Any])
        let list = try XCTUnwrap(raw["vignettes"] as? [[String: Any]])
        XCTAssertEqual(list.count, 9)
        for v in list {
            let vid = v["id"] as? String ?? "?"
            var a = ExtubationAnswers()
            for (key, value) in v["answers"] as? [String: Any] ?? [:] {
                if key == "setting", let s = value as? String { a.setting = s }
                else if let arr = value as? [String] { a.checklists[key] = Set(arr) }
                else if let s = value as? String { a.choices[key] = s }
                else if let d = value as? [String: String] { a.textFields[key] = d }
            }
            let r = try extubationEvaluate(logic: logic, answers: a)
            let e = v["expect"] as? [String: Any] ?? [:]
            if let x = e["outcome"] as? String { XCTAssertEqual(r.outcome, x, vid) }
            if let x = e["chip"] as? String { XCTAssertEqual(r.chip, x, vid) }
            if let x = e["why"] as? [String] { XCTAssertEqual(r.why, x, vid) }
            if let x = e["alerts"] as? [String] { XCTAssertEqual(r.alerts.map(\.id), x, vid) }
            if let x = e["screensShown"] as? [String] { XCTAssertEqual(r.screensShown, x, vid) }
            if let x = e["riskCount"] as? Int { XCTAssertEqual(r.riskCount, x, vid) }
        }
    }

    /// The navigation stub decodes even though it has no purpose/interpretation.
    func testModuleStubDecodes() throws {
        let url = try XCTUnwrap(ContentAssets.bundledURL("modules/calculators/anesthesia-airway-or/extubation-decision-tool.json"))
        let calc = try JSONDecoder().decode(Calculator.self, from: Data(contentsOf: url))
        XCTAssertEqual(calc.engine, .builtin)
        XCTAssertEqual(calc.tool, "extubation")
    }
}
