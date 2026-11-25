import XCTest
import NEECore
@testable import Kairos

/// The app ships the NEE kit's nee-logic.json byte for byte and, as linked
/// into the app, passes all 30 kit vignettes (same rules as run-vignettes.js).
/// Also: the UTICalc link card decodes with its link and attribution.
final class NEEBundleTests: XCTestCase {
    static let repo: URL = {
        var u = URL(fileURLWithPath: #filePath)
        for _ in 0..<3 { u.deleteLastPathComponent() } // file, Tests, ios
        return u
    }()

    private func bundled() throws -> Data {
        try Data(contentsOf: XCTUnwrap(Bundle.main.url(forResource: "nee-logic", withExtension: "json")))
    }

    func testBundledLogicIsByteIdenticalToKit() throws {
        XCTAssertEqual(try bundled(), try Data(contentsOf: Self.repo.appendingPathComponent("Resources/NEE/nee-logic.json")))
    }

    func testThirtyVignettes() throws {
        let logic = try NEELogic.load(from: bundled())
        let suite = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(contentsOf: Self.repo.appendingPathComponent("Resources/NEE/nee-vignettes.json"))) as? [String: Any])
        let tol = try XCTUnwrap((suite["tolerance"] as? NSNumber)?.doubleValue)
        let list = try XCTUnwrap(suite["vignettes"] as? [[String: Any]])
        func close(_ a: Double?, _ b: Any?) -> Bool {
            let e = (b as? NSNumber)?.doubleValue
            if a == nil || e == nil { return a == nil && e == nil }
            return abs(a! - e!) <= tol
        }
        var passed = 0
        for v in list {
            let raw = v["input"] as? [String: Any] ?? [:]
            var input = NEEInput(formulaId: raw["formulaId"] as? String, weightKg: (raw["weightKg"] as? NSNumber)?.doubleValue, neSalt: raw["neSalt"] as? String)
            for r in raw["infusions"] as? [[String: Any]] ?? [] {
                input.infusions.append(NEEInfusion(agent: r["agent"] as? String ?? "", dose: (r["dose"] as? NSNumber)?.doubleValue ?? .nan, unit: r["unit"] as? String ?? ""))
            }
            let r = computeNEE(logic: logic, input: input)
            let e = v["expect"] as? [String: Any] ?? [:]
            var ok = r.status == e["status"] as? String
            if e["status"] as? String == "ok" {
                ok = ok && close(r.neeMcgKgMin, e["nee_mcg_kg_min"]) && close(r.neeMcgMin, e["nee_mcg_min"]) && close(r.adjunctMcgKgMin, e["adjunct_mcg_kg_min"])
                    && Set(r.warnings.map(\.code)) == Set(e["warnings"] as? [String] ?? []) && Set(r.info.map(\.code)) == Set(e["info"] as? [String] ?? [])
                if let f = e["formula"] as? String { ok = ok && r.formula == f }
            } else {
                ok = ok && Set(r.errors.map(\.code)) == Set(e["errors"] as? [String] ?? [])
            }
            XCTAssertTrue(ok, "\(v["id"] ?? "?")")
            if ok { passed += 1 }
        }
        XCTAssertEqual(passed, 30)
    }

    func testModuleStubsDecode() throws {
        let nee = try JSONDecoder().decode(Calculator.self, from: Data(contentsOf: XCTUnwrap(ContentAssets.bundledURL("modules/calculators/icu-critical-care/nee-calculator.json"))))
        XCTAssertEqual(nee.tool, "nee")
        let card = try JSONDecoder().decode(ReferenceDoc.self, from: Data(contentsOf: XCTUnwrap(ContentAssets.bundledURL("modules/peds-module/peds-uticalc-link.json"))))
        XCTAssertEqual(card.link?.url, "https://uticalc.pitt.edu/")
        XCTAssertNotNil(card.attribution)
        XCTAssertNotNil(card.badge)
    }
}
