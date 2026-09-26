import XCTest
@testable import Kairos

/// Runs the shared golden vectors (tools/fixtures/axis-golden-vectors.json)
/// against the Swift axis engine. tools/test.mjs runs the same file against
/// web/src/lib/axisEngine.js, so the two engines cannot drift apart.
final class AxisEngineParityTests: XCTestCase {
    func testGoldenVectors() throws {
        let url = try XCTUnwrap(Bundle(for: Self.self).url(forResource: "axis-golden-vectors", withExtension: "json"))
        let root = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String: Any])
        let cases = try XCTUnwrap(root["cases"] as? [[String: Any]])
        XCTAssertGreaterThanOrEqual(cases.count, 46)
        func num(_ v: Any?) -> Double? { (v as? NSNumber)?.doubleValue }

        for c in cases {
            let name = c["name"] as? String ?? "?"
            let inp = c["input"] as? [String: Any] ?? [:]
            let e = c["expect"] as? [String: Any] ?? [:]
            var m = AxisEngine.Modifiers()
            if let mods = inp["modifiers"] as? [String: Bool] {
                m = .init(lbbb: mods["lbbb"] ?? false, rbbb: mods["rbbb"] ?? false, paced: mods["paced"] ?? false,
                          lvh: mods["lvh"] ?? false, wpw: mods["wpw"] ?? false, wideQrs: mods["wideQrs"] ?? false)
            }
            let input: AxisEngine.Input
            switch inp["mode"] as? String {
            case "prt":
                let prt = inp["prt"] as? [String: Any] ?? [:]
                if let t = prt["text"] as? String { input = .prtText(t) }
                else { input = .prtValues(p: num(prt["p"]), qrs: num(prt["qrs"]), t: num(prt["t"])) }
            case "polarity":
                let raw = inp["polarities"] as? [String: String] ?? [:]
                input = .polarities(raw.compactMapValues { AxisEngine.Polarity(rawValue: $0) })
            default:
                input = .amplitudes((inp["amplitudes"] as? [String: Any] ?? [:]).compactMapValues { num($0) })
            }
            let r = AxisEngine.interpret(input, ageDays: num(inp["ageDays"]), modifiers: m)

            if let v = e["status"] as? String { XCTAssertEqual(r.status, v, name) }
            if let v = e["error"] as? String { XCTAssertEqual(r.error, v, name) }
            if let v = num(e["qrsAxis"]) { XCTAssertEqual(r.qrsAxis, v, name) }
            if let v = e["qrsKey"] as? String { XCTAssertEqual(r.qrsClass?.key, v, name) }
            if let v = num(e["pAxis"]) { XCTAssertEqual(r.pAxis, v, name) }
            if let v = e["pKey"] as? String { XCTAssertEqual(r.pClass?.key, v, name) }
            if let v = num(e["tAxis"]) { XCTAssertEqual(r.tAxis, v, name) }
            if let v = e["tKey"] as? String { XCTAssertEqual(r.tClass?.key, v, name) }
            if let v = num(e["qrsTAngle"]) { XCTAssertEqual(r.qrsT.map { Double($0.angle) }, v, name) }
            if let v = e["qrsTKey"] as? String { XCTAssertEqual(r.qrsT?.key, v, name) }
            if let v = e["range"] as? [Int] { XCTAssertEqual(r.qrsRange, v, name) }
            if e.keys.contains("differential") { XCTAssertEqual(r.differential, e["differential"] as? String, name) }
            if let v = e["flagsExact"] as? [String] { XCTAssertEqual(r.flags.sorted(), v.sorted(), name) }
            for f in e["flagsInclude"] as? [String] ?? [] { XCTAssertTrue(r.flags.contains(f), "\(name): missing flag \(f)") }
            for f in e["flagsExclude"] as? [String] ?? [] { XCTAssertFalse(r.flags.contains(f), "\(name): unexpected flag \(f)") }
            for w in e["warningsInclude"] as? [String] ?? [] { XCTAssertTrue(r.warnings.contains(w), "\(name): missing warning \(w)") }
            for w in e["warningsExclude"] as? [String] ?? [] { XCTAssertFalse(r.warnings.contains(w), "\(name): unexpected warning \(w)") }
        }
    }
}

/// The shipped module must decode into the tool's content model — a content edit
/// that breaks a key would otherwise leave the tool silently without its copy.
final class AxisToolContentTests: XCTestCase {
    func testBundledModuleDecodes() throws {
        let url = try XCTUnwrap(ContentAssets.bundledURL("modules/calculators/cardiovascular/ekg-axis-interpreter.json"))
        let calc = try JSONDecoder().decode(Calculator.self, from: Data(contentsOf: url))
        XCTAssertEqual(calc.engine, .builtin)
        let c = try XCTUnwrap(calc.axisContent)
        XCTAssertEqual(c.modes.first?.id, "prt", "Machine (P-R-T) must be the first tab")
        XCTAssertEqual(c.modes.first { $0.default == true }?.id, "prt", "Machine (P-R-T) must be the default")
        // every key the engine can emit has copy
        for k in ["normal", "lad_borderline", "lad_marked", "rad", "extreme", "normal_for_age", "rightward_for_age", "leftward_for_age", "spans"] {
            XCTAssertNotNil(c.qrsCategories[k], k)
        }
        for k in ["limb_lead_reversal_vs_dextrocardia", "qrs_t_angle_high_risk", "lafb_checklist", "lpfb_checklist",
                  "infant_superior_axis", "paced_axis_caveat", "check_rhythm_no_p"] {
            XCTAssertNotNil(c.flags[k], k)
        }
        for k in ["lad", "rad", "extreme"] { XCTAssertNotNil(c.differentials[k], k) }
        for k in ["empty", "unparseable", "qrs_missing", "out_of_range"] { XCTAssertNotNil(c.statusMessages.errors[k], k) }
        XCTAssertNotNil(c.checklists["lafb"]); XCTAssertNotNil(c.checklists["lpfb"])
        XCTAssertEqual(calc.meta.lastReviewed, "2026-09-26")
    }
}
