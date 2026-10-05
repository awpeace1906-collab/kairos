import XCTest
@testable import Kairos

/// Runs the shared golden vectors (tools/fixtures/acid-base-golden-vectors.json)
/// against the Swift acid-base engine. tools/test.mjs runs the same file against
/// web/src/lib/acidBaseEngine.js, so the two engines cannot drift apart.
final class AcidBaseParityTests: XCTestCase {
    func testGoldenVectors() throws {
        let url = try XCTUnwrap(Bundle(for: Self.self).url(forResource: "acid-base-golden-vectors", withExtension: "json"))
        let root = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String: Any])
        let cases = try XCTUnwrap(root["cases"] as? [[String: Any]])
        XCTAssertGreaterThanOrEqual(cases.count, 32)
        func num(_ v: Any?) -> Double? { (v as? NSNumber)?.doubleValue }

        for c in cases {
            let name = c["name"] as? String ?? "?"
            let i = c["input"] as? [String: Any] ?? [:]
            let e = c["expect"] as? [String: Any] ?? [:]
            let input = AcidBaseEngine.Input(
                ph: num(i["ph"]), paco2: num(i["paco2"]), hco3: num(i["hco3"]),
                na: num(i["na"]), cl: num(i["cl"]), albumin: num(i["albumin"]),
                chronicity: AcidBaseEngine.Chronicity(rawValue: i["chronicity"] as? String ?? "") ?? .unknown,
                sample: AcidBaseEngine.Sample(rawValue: i["sample"] as? String ?? "") ?? .arterial)
            let r = AcidBaseEngine.interpret(input)
            let comp = r.compensation

            if let v = e["status"] as? String { XCTAssertEqual(r.status, v, name) }
            if let v = e["error"] as? String { XCTAssertEqual(r.error, v, name) }
            if let v = e["phStatus"] as? String { XCTAssertEqual(r.phStatus, v, name) }
            if let v = e["sample"] as? String { XCTAssertEqual(r.sample, v, name) }
            if let v = num(e["estPh"]) { XCTAssertEqual(r.estimatedArterial?.ph, v, name) }
            if let v = num(e["estPaco2"]) { XCTAssertEqual(r.estimatedArterial?.paco2, v, name) }
            if let v = num(e["estHco3"]) { XCTAssertEqual(r.estimatedArterial?.hco3, v, name) }
            if let v = e["primary"] as? String { XCTAssertEqual(r.primary, v, name) }
            if e["compensation"] is NSNull { XCTAssertNil(comp, name) }
            if let v = e["compRule"] as? String { XCTAssertEqual(comp?.rule, v, name) }
            if let v = e["compKey"] as? String { XCTAssertEqual(comp?.key, v, name) }
            if let v = num(e["expectedCenter"]) { XCTAssertEqual(comp?.expected?.center, v, name) }
            if let v = num(e["expectedLo"]) { XCTAssertEqual(comp?.expected?.lo, v, name) }
            if let v = num(e["expectedHi"]) { XCTAssertEqual(comp?.expected?.hi, v, name) }
            if let v = num(e["acuteCenter"]) { XCTAssertEqual(comp?.acute?.center, v, name) }
            if let v = num(e["chronicCenter"]) { XCTAssertEqual(comp?.chronic?.center, v, name) }
            if let v = num(e["hhCalculated"]) { XCTAssertEqual(r.calculatedPh, v, name) }
            if let v = num(e["agValue"]) { XCTAssertEqual(r.ag?.value, v, name) }
            if let v = num(e["agCorrected"]) { XCTAssertEqual(r.ag?.corrected, v, name) }
            if let v = num(e["agUsed"]) { XCTAssertEqual(r.ag?.used, v, name) }
            if let v = e["agKey"] as? String { XCTAssertEqual(r.ag?.key, v, name) }
            if let v = num(e["deltaRatio"]) { XCTAssertEqual(r.deltaRatio?.value, v, name) }
            if let v = e["deltaKey"] as? String { XCTAssertEqual(r.deltaRatio?.key, v, name) }
            if let v = e["disordersExact"] as? [String] { XCTAssertEqual(r.disorders.sorted(), v.sorted(), name) }
            if let v = e["differentialsExact"] as? [String] { XCTAssertEqual(r.differentials.sorted(), v.sorted(), name) }
            if let v = e["flagsExact"] as? [String] { XCTAssertEqual(r.flags.sorted(), v.sorted(), name) }
            for f in e["flagsInclude"] as? [String] ?? [] { XCTAssertTrue(r.flags.contains(f), "\(name): missing flag \(f)") }
            for f in e["flagsExclude"] as? [String] ?? [] { XCTAssertFalse(r.flags.contains(f), "\(name): unexpected flag \(f)") }
        }
    }

    /// The shipped module decodes, and every key the engine emits for the
    /// golden vectors has copy (mirrors the JS check in tools/test.mjs).
    func testBundledModuleHasCopyForEveryKey() throws {
        let url = try XCTUnwrap(ContentAssets.bundledURL("modules/calculators/gi-renal-metabolic/acid-base-analyzer.json"))
        let calc = try JSONDecoder().decode(Calculator.self, from: Data(contentsOf: url))
        XCTAssertEqual(calc.engine, .builtin)
        XCTAssertEqual(calc.tool, "acid-base")
        let c = try XCTUnwrap(calc.acidBaseContent)
        let vurl = try XCTUnwrap(Bundle(for: Self.self).url(forResource: "acid-base-golden-vectors", withExtension: "json"))
        let root = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(contentsOf: vurl)) as? [String: Any])
        func num(_ v: Any?) -> Double? { (v as? NSNumber)?.doubleValue }
        for case let v as [String: Any] in root["cases"] as? [Any] ?? [] {
            let i = v["input"] as? [String: Any] ?? [:]
            let r = AcidBaseEngine.interpret(.init(ph: num(i["ph"]), paco2: num(i["paco2"]), hco3: num(i["hco3"]),
                                                   na: num(i["na"]), cl: num(i["cl"]), albumin: num(i["albumin"]),
                                                   chronicity: .init(rawValue: i["chronicity"] as? String ?? "") ?? .unknown,
                                                   sample: .init(rawValue: i["sample"] as? String ?? "") ?? .arterial))
            if let e = r.error { XCTAssertNotNil(c.statusMessages.errors[e], e) }
            guard r.status == "ok" else { continue }
            XCTAssertNotNil(c.primary[r.primary ?? ""], "primary \(r.primary ?? "")")
            if let comp = r.compensation {
                XCTAssertNotNil(c.compensation[comp.key], "compensation \(comp.key)")
                XCTAssertNotNil(c.compensationRules[comp.rule], "rule \(comp.rule)")
            }
            if let d = r.deltaRatio { XCTAssertNotNil(c.deltaRatio.bands[d.key], "delta \(d.key)") }
            for f in r.flags { XCTAssertNotNil(c.flags[f], "flag \(f)") }
            for d in r.differentials { XCTAssertNotNil(c.differentials[d], "differential \(d)") }
        }
        XCTAssertEqual(calc.meta.lastReviewed, "2026-10-05")
    }
}
