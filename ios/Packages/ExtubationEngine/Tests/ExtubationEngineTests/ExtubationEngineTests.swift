import XCTest
@testable import ExtubationEngine

/// Runs every vignette in Resources/Extubation/extubation-vignettes.json against
/// the Swift engine, comparing each `expect` field. Reads the kit files from
/// the repo (no copy kept here). Run with `swift test` in this package.
final class ExtubationEngineTests: XCTestCase {

    /// <repo>/Resources/Extubation, found relative to this file.
    static let kitDir: URL = {
        var u = URL(fileURLWithPath: #filePath)
        for _ in 0..<6 { u.deleteLastPathComponent() } // file, ExtubationEngineTests, Tests, ExtubationEngine, Packages, ios
        return u.appendingPathComponent("Resources/Extubation")
    }()

    static func kitData(_ name: String) throws -> Data {
        try Data(contentsOf: kitDir.appendingPathComponent(name))
    }

    private var logic: ExtubationLogic!

    override func setUpWithError() throws {
        logic = try ExtubationLogic.load(from: Self.kitData("extubation-logic.json"))
    }

    func testVignettes() throws {
        let raw = try JSONSerialization.jsonObject(with: Self.kitData("extubation-vignettes.json")) as! [String: Any]
        XCTAssertEqual(raw["logicVersion"] as? String, logic.version, "vignettes are for a different logic version")
        let list = raw["vignettes"] as! [[String: Any]]
        XCTAssertEqual(list.count, 9)
        for v in list {
            let vid = v["id"] as! String
            let expect = v["expect"] as! [String: Any]
            let r = try extubationEvaluate(logic: logic, answers: Self.answers(v["answers"] as! [String: Any]))
            for (key, value) in expect {
                switch key {
                case "outcome":      XCTAssertEqual(r.outcome, value as? String, vid)
                case "chip":         XCTAssertEqual(r.chip, value as? String, vid)
                case "why":          XCTAssertEqual(r.why, value as? [String], vid)
                case "alerts":       XCTAssertEqual(r.alerts.map(\.id), value as? [String], vid)
                case "screensShown": XCTAssertEqual(r.screensShown, value as? [String], vid)
                case "riskCount":    XCTAssertEqual(r.riskCount, value as? Int, vid)
                default:             XCTFail("\(vid): untested expect field \(key)")
                }
            }
        }
    }

    /// Alert order must follow the JSON text, not JSONDecoder's key order.
    func testAlertOrderMatchesJSONText() throws {
        XCTAssertEqual(logic.alerts.entries.map(\.id),
                       ["ALERT_OR_SOFT_GATE", "ALERT_ICU_AIRWAY", "ALERT_CUFF_FAILED", "ALERT_CUFF_NOT_DONE", "ALERT_POSTEXT_FAILURE"])
    }

    func testKeyOrderScannerHandlesEscapesAndNesting() throws {
        let json = #"{"a": {"x": [1, {"y": "}"}]}, "alerts": {"Z\"1": {"k": "á"}, "B": [], "C": "]"}}"#
        XCTAssertEqual(try JSONKeyOrder.keys(ofObjectAt: ["alerts"], in: Data(json.utf8)), [#"Z"1"#, "B", "C"])
    }

    func testUIHelpers() throws {
        let airway = try XCTUnwrap(logic.alerts["ALERT_ICU_AIRWAY"])
        XCTAssertEqual(extubationAlertOwnerScreenId(airway), "icu_airway")
        XCTAssertNil(extubationAlertOwnerScreenId(try XCTUnwrap(logic.alerts["ALERT_POSTEXT_FAILURE"])))
        var a = ExtubationAnswers()
        a.setting = "icu"
        a.checklists["icu_airway"] = ["secr"]
        XCTAssertEqual(extubationAlertItemIds(logic: logic, answers: a, alertId: "ALERT_ICU_AIRWAY"), ["cough", "mental"])
        a.checklists["or_gate"] = ["tofr", "spont", "hemo"]
        XCTAssertEqual(extubationAlertItemIds(logic: logic, answers: a, alertId: "ALERT_OR_SOFT_GATE"), ["temp", "analg"])
    }

    /// Local-only: the repo copy of the kit matches the owner's kit folder
    /// (../Resources/Extubation beside the Kairos repo). Skipped where absent (CI).
    func testRepoKitMatchesOwnerKit() throws {
        let owner = Self.kitDir.deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent().appendingPathComponent("Resources/Extubation")
        guard FileManager.default.fileExists(atPath: owner.path) else { throw XCTSkip("owner kit folder not present") }
        for name in ["extubation-logic.json", "extubation-vignettes.json", "extubation-engine-reference.js", "extubation-decision-protocol.html"] {
            XCTAssertEqual(try Data(contentsOf: owner.appendingPathComponent(name)), try Self.kitData(name), "\(name) differs from the owner kit")
        }
    }

    static func answers(_ raw: [String: Any]) -> ExtubationAnswers {
        var a = ExtubationAnswers()
        for (key, value) in raw {
            if key == "setting", let s = value as? String { a.setting = s }
            else if let arr = value as? [String] { a.checklists[key] = Set(arr) }
            else if let s = value as? String { a.choices[key] = s }
            else if let d = value as? [String: String] { a.textFields[key] = d }
        }
        return a
    }
}
