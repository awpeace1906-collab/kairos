import XCTest
@testable import TraumaCore

/// Port of Resources/TraumaActivation/run-vignettes.js: 27 evaluator, 14
/// profile/import and 3 library tests, same comparison rules. The evaluator
/// and validation tests need the BUMCT fixture in profiles/, which is
/// git-ignored (personal_only), so they skip where it is absent (CI).
final class TraumaCoreTests: XCTestCase {
    static let kitDir: URL = {
        var u = URL(fileURLWithPath: #filePath)
        for _ in 0..<6 { u.deleteLastPathComponent() } // file, TraumaCoreTests, Tests, TraumaCore, Packages, ios
        return u.appendingPathComponent("Resources/TraumaActivation")
    }()
    static func kit(_ name: String) throws -> JSONValue { try JSONValue.parse(Data(contentsOf: kitDir.appendingPathComponent(name))) }
    static func fixture(_ name: String) throws -> JSONValue {
        let url = kitDir.appendingPathComponent("profiles/\(name)")
        guard FileManager.default.fileExists(atPath: url.path) else { throw XCTSkip("profiles/ fixture not present (git-ignored; local only)") }
        return try JSONValue.parse(Data(contentsOf: url))
    }
    static func sameSet(_ a: [String], _ b: JSONValue?) -> Bool { a.sorted() == (b?.array?.compactMap(\.string) ?? []).sorted() }

    /// Runs the 27 evaluator vignettes against `profileFor`; returns the number passed.
    static func runEvaluatorVignettes(profileFor: (String) throws -> JSONValue, file: StaticString = #filePath, line: UInt = #line) throws -> Int {
        let suite = try kit("trauma-vignettes.json")
        var pass = 0
        for v in suite["vignettes"]?.array ?? [] {
            let profile = try profileFor(v["profile"]?.string ?? "")
            XCTAssertEqual(profile["profile_version"], suite["profile_version"], "profile version mismatch", file: file, line: line)
            let inp = v["input"]
            var vitals: [String: Double] = [:]
            for (k, x) in inp?["vitals"]?.object ?? [:] { if let n = x.number { vitals[k] = n } }
            let r = try traumaEvaluate(profile: profile, input: TraumaInput(checked: inp?["checked"]?.array?.compactMap(\.string) ?? [], vitals: vitals))
            let e = v["expect"]
            var ok = r.status == e?["status"]?.string
            if e?["status"]?.string == "ok" {
                ok = ok && r.tier == e?["tier"]?.string
                if let ids = e?["met_ids"], !ids.isNull { ok = ok && sameSet(r.met.map(\.id), ids) }
                ok = ok && sameSet(r.compoundHints.map(\.id), e?["compound_hints"])
                    && sameSet(r.advisories.map(\.id), e?["advisories"]) && sameSet(r.notes.map(\.id), e?["notes"])
            } else {
                ok = ok && sameSet(r.errors.map(\.code), e?["errors"])
            }
            XCTAssertTrue(ok, "\(v["id"]?.string ?? "?") \(v["title"]?.string ?? ""): \(r)", file: file, line: line)
            if ok { pass += 1 }
        }
        return pass
    }

    func testEvaluatorVignettes() throws {
        XCTAssertEqual(try Self.runEvaluatorVignettes(profileFor: { try Self.fixture($0) }), 27)
    }

    static func setPath(_ root: JSONValue, _ path: [JSONValue], _ value: JSONValue) -> JSONValue {
        guard let head = path.first else { return value }
        let rest = Array(path.dropFirst())
        switch (root, head) {
        case (.object(var o), .string(let k)):
            if rest.isEmpty { if value.isNull { o.removeValue(forKey: k) } else { o[k] = value } }
            else { o[k] = setPath(o[k] ?? .null, rest, value) }
            return .object(o)
        case (.array(var a), .number(let n)):
            let i = Int(n)
            if rest.isEmpty { a[i] = value } else { a[i] = setPath(a[i], rest, value) }
            return .array(a)
        default: return root
        }
    }

    func testValidationAndDraftTests() throws {
        let templates = try Self.kit("rule-templates.json")
        let pt = try Self.kit("profile-tests.json")
        var pass = 0, total = 0
        // Draft (save-gate) tests do not need the fixture.
        for t in pt["drafts"]?.array ?? [] {
            total += 1
            let d = t["draft"]
            let lines = try JSONDecoder().decode([DraftLine].self, from: (d?["lines"] ?? .array([])).data(pretty: false))
            let r = canSaveDraft(institution: d?["institution"]?.string, sourceRevisionDate: d?["source_revision_date"]?.string, lines: lines)
            let codes = Array(Set(r.blocking.map(\.code)))
            let ok = r.ok == (t["expect_ok"] == .bool(true)) && Self.sameSet(codes, t["expect"])
            XCTAssertTrue(ok, "\(t["id"]?.string ?? "?") got ok=\(r.ok) \(codes)")
            if ok { pass += 1 }
        }
        let base = try Self.fixture(pt["base_profile"]?.string ?? "")
        for t in pt["validation"]?.array ?? [] {
            total += 1
            var prof = base
            for m in t["mutations"]?.array ?? [] {
                prof = Self.setPath(prof, m["set"]?.array ?? [], m["value"] ?? .null)
            }
            let codes = Array(Set(validateProfile(prof, templates: templates).map(\.code)))
            let ok = Self.sameSet(codes, t["expect"])
            XCTAssertTrue(ok, "\(t["id"]?.string ?? "?") got \(codes)")
            if ok { pass += 1 }
        }
        XCTAssertEqual(pass, 14)
        XCTAssertEqual(total, 14)
    }

    func testLibrary() throws {
        let pt = try Self.kit("profile-tests.json")
        var pass = 0
        for t in pt["library"]?.array ?? [] {
            var lib = ProfileLibrary()
            for s in t["steps"]?.array ?? [] {
                if let add = s["add"] { lib = addToLibrary(lib, profile: add, addedAt: s["at"]?.string ?? "").library }
                else if let rm = s["remove"]?.string { lib = removeFromLibrary(lib, profileId: rm) }
            }
            let groups: [JSONValue] = listByInstitution(lib).map { g in
                .object(["current": .string(g.currentProfileId), "versions": .array(g.versions.map { .string($0.profileId) })])
            }
            let got: JSONValue = .object(["count": .number(Double(lib.entries.count)),
                                          "default": lib.default_profile_id.map { .string($0) } ?? .null,
                                          "groups": .array(groups)])
            let ok = got == t["expect"]
            XCTAssertTrue(ok, "\(t["id"]?.string ?? "?") got \(got)")
            if ok { pass += 1 }
        }
        XCTAssertEqual(pass, 3)
    }

    func testNeedsDoubleCheckAndPlain() throws {
        XCTAssertTrue(needsDoubleCheck("SBP < 90 in adults"))
        XCTAssertFalse(needsDoubleCheck("Traumatic arrest"))
        let templates = try Self.kit("rule-templates.json")
        let t = try XCTUnwrap(templates["templates"]?.array?.first { $0["id"]?.string == "vital_outside" })
        XCTAssertEqual(fillPlain(t, params: ["vital": .string("rr"), "low": .number(10), "high": .number(29)], vitalLabel: { $0 == "rr" ? "RR" : $0 }),
                       "RR < 10 or > 29")
    }
}
