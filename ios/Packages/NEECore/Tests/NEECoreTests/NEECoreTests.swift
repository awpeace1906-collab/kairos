import XCTest
@testable import NEECore

/// Runs Resources/NEE/nee-vignettes.json against the Swift engine with the
/// same comparison rules as the kit's run-vignettes.js (absolute tolerance
/// from the file; codes compared as sets). Reads the kit from the repo.
final class NEECoreTests: XCTestCase {
    static let kitDir: URL = {
        var u = URL(fileURLWithPath: #filePath)
        for _ in 0..<6 { u.deleteLastPathComponent() } // file, NEECoreTests, Tests, NEECore, Packages, ios
        return u.appendingPathComponent("Resources/NEE")
    }()
    static func kitData(_ name: String) throws -> Data { try Data(contentsOf: kitDir.appendingPathComponent(name)) }

    static func input(_ raw: [String: Any]) -> NEEInput {
        var i = NEEInput()
        i.formulaId = raw["formulaId"] as? String
        i.weightKg = (raw["weightKg"] as? NSNumber)?.doubleValue
        i.neSalt = raw["neSalt"] as? String
        for r in raw["infusions"] as? [[String: Any]] ?? [] {
            let dose = (r["dose"] as? NSNumber)?.doubleValue ?? .nan
            i.infusions.append(NEEInfusion(agent: r["agent"] as? String ?? "", dose: dose, unit: r["unit"] as? String ?? ""))
        }
        return i
    }

    /// Asserts every vignette; returns the number that passed.
    @discardableResult
    static func runVignettes(logic: NEELogic, suiteData: Data, file: StaticString = #filePath, line: UInt = #line) throws -> Int {
        let suite = try XCTUnwrap(JSONSerialization.jsonObject(with: suiteData) as? [String: Any])
        XCTAssertEqual(suite["logic_version"] as? String, logic.logicVersion, "vignettes are for a different logic version", file: file, line: line)
        let tol = try XCTUnwrap((suite["tolerance"] as? NSNumber)?.doubleValue)
        let list = try XCTUnwrap(suite["vignettes"] as? [[String: Any]])
        func close(_ a: Double?, _ b: Any?) -> Bool {
            let e = (b as? NSNumber)?.doubleValue
            if a == nil || e == nil { return a == nil && e == nil }
            return abs(a! - e!) <= tol
        }
        var passed = 0
        for v in list {
            let id = v["id"] as? String ?? "?"
            let e = try XCTUnwrap(v["expect"] as? [String: Any])
            let r = computeNEE(logic: logic, input: input(try XCTUnwrap(v["input"] as? [String: Any])))
            var ok = r.status == e["status"] as? String
            if e["status"] as? String == "ok" {
                ok = ok && close(r.neeMcgKgMin, e["nee_mcg_kg_min"]) && close(r.neeMcgMin, e["nee_mcg_min"])
                    && close(r.adjunctMcgKgMin, e["adjunct_mcg_kg_min"])
                    && Set(r.warnings.map(\.code)) == Set(e["warnings"] as? [String] ?? [])
                    && Set(r.info.map(\.code)) == Set(e["info"] as? [String] ?? [])
                if let f = e["formula"] as? String { ok = ok && r.formula == f }
            } else {
                ok = ok && Set(r.errors.map(\.code)) == Set(e["errors"] as? [String] ?? [])
            }
            XCTAssertTrue(ok, "\(id) failed: \(r)", file: file, line: line)
            if ok { passed += 1 }
        }
        return passed
    }

    func testAllVignettes() throws {
        let logic = try NEELogic.load(from: Self.kitData("nee-logic.json"))
        let passed = try Self.runVignettes(logic: logic, suiteData: Self.kitData("nee-vignettes.json"))
        XCTAssertEqual(passed, 30)
    }

    /// Acceptance item: a factor changed in the JSON changes the result with no
    /// code change. Kotani phenylephrine 6/100 -> 12/100 doubles V06's NEE.
    func testFactorChangeInJSONChangesResult() throws {
        var text = try XCTUnwrap(String(data: Self.kitData("nee-logic.json"), encoding: .utf8))
        let before = try NEELogic.load(from: Data(text.utf8))
        let input = NEEInput(formulaId: "kotani_2023", weightKg: 70, infusions: [NEEInfusion(agent: "phenylephrine", dose: 100, unit: "mcg/min")])
        let a = try XCTUnwrap(computeNEE(logic: before, input: input).neeMcgKgMin)
        let marker = "\"phenylephrine\": {\n          \"factor\": {\n            \"num\": 6,"
        XCTAssertTrue(text.contains(marker), "Kotani phenylephrine factor not found where expected")
        text = text.replacingOccurrences(of: marker, with: marker.replacingOccurrences(of: "\"num\": 6,", with: "\"num\": 12,"))
        let b = try XCTUnwrap(computeNEE(logic: NEELogic.load(from: Data(text.utf8)), input: input).neeMcgKgMin)
        XCTAssertEqual(b, a * 2, accuracy: 1e-12)
    }

    func testSourcesRule() throws {
        let logic = try NEELogic.load(from: Self.kitData("nee-logic.json"))
        XCTAssertEqual(neeSourceIds(logic: logic, formulaId: "goradia_2021", shownNoteIds: ["salt_note", "disclaimer"]),
                       ["goradia_2021", "salt_sources", "kotani_2023"])
    }

    /// Local only: the repo kit matches the owner's kit folder beside the repo.
    func testRepoKitMatchesOwnerKit() throws {
        let owner = Self.kitDir.deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent().appendingPathComponent("Resources/NEE")
        guard FileManager.default.fileExists(atPath: owner.path) else { throw XCTSkip("owner kit folder not present") }
        for name in ["nee-logic.json", "nee-vignettes.json", "nee-engine-reference.js", "run-vignettes.js", "CODE-INSTRUCTIONS.md", "SOURCES-AND-VERIFICATION.md"] {
            XCTAssertEqual(try Data(contentsOf: owner.appendingPathComponent(name)), try Self.kitData(name), name)
        }
    }
}
