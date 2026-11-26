import PDFKit
import XCTest
import TraumaCore
@testable import Kairos

/// Local Protocols (trauma activation) acceptance tests.
/// The BUMCT fixtures live in Resources/TraumaActivation/profiles/, which is
/// git-ignored (personal_only); tests that need them skip where it is absent.
@MainActor
final class LocalProtocolsTests: XCTestCase {
    static let kitDir: URL = {
        var u = URL(fileURLWithPath: #filePath)
        for _ in 0..<3 { u.deleteLastPathComponent() } // file, Tests, ios
        return u.appendingPathComponent("Resources/TraumaActivation")
    }()
    static func kit(_ name: String) throws -> JSONValue { try JSONValue.parse(Data(contentsOf: kitDir.appendingPathComponent(name))) }
    static func fixtureURL(_ name: String) throws -> URL {
        let u = kitDir.appendingPathComponent("profiles/\(name)")
        guard FileManager.default.fileExists(atPath: u.path) else { throw XCTSkip("profiles/ fixture not present (git-ignored; local only)") }
        return u
    }
    static func fixtureProfile() throws -> JSONValue { try JSONValue.parse(Data(contentsOf: fixtureURL("bumct-2026-02-23.json"))) }

    private func tempStore() -> LocalProtocolStore {
        LocalProtocolStore(root: FileManager.default.temporaryDirectory.appendingPathComponent("lp-\(UUID().uuidString)"))
    }

    // MARK: - Build exclusion

    func testNoProfileIsBundledAndTemplatesAre() throws {
        let app = Bundle.main.bundleURL
        XCTAssertNotNil(Bundle.main.url(forResource: "rule-templates", withExtension: "json"), "rule-templates.json should be bundled")
        let e = FileManager.default.enumerator(at: app, includingPropertiesForKeys: nil)!
        var offenders: [String] = []
        for case let u as URL in e {
            let p = u.path.lowercased()
            if p.contains("traumaactivation/profiles") || p.contains("test-fixture") || u.lastPathComponent.lowercased().hasPrefix("bumct") {
                offenders.append(u.lastPathComponent)
            } else if u.pathExtension == "json", let s = try? String(contentsOf: u, encoding: .utf8),
                      s.range(of: #""distribution"\s*:\s*"personal_only""#, options: .regularExpression) != nil {
                offenders.append(u.lastPathComponent)
            }
        }
        XCTAssertEqual(offenders, [], "a profile is in the app bundle")
    }

    // MARK: - Storage

    func testStorageProtectionAndBackupExclusion() throws {
        let store = tempStore()
        XCTAssertEqual(try? store.add(Self.fixtureProfile()).get().isEmpty, false)
        let lib = store.root.appendingPathComponent("library.json")
        XCTAssertTrue(FileManager.default.fileExists(atPath: lib.path))
        let attrs = try FileManager.default.attributesOfItem(atPath: lib.path)
        if let prot = attrs[.protectionKey] as? FileProtectionType { XCTAssertEqual(prot, .complete) }
        let excluded = try store.root.resourceValues(forKeys: [.isExcludedFromBackupKey]).isExcludedFromBackup
        XCTAssertEqual(excluded, true, "excluded from backup unless the user opts in")
    }

    func testImportForcesPersonalOnlyAndKeepsEveryVersion() throws {
        let store = tempStore()
        var p = try Self.fixtureProfile().object!
        p["distribution"] = .string("public")
        _ = try store.add(.object(p))                                 // forced to personal_only, so it validates
        XCTAssertEqual(store.library.entries.first?.profile["distribution"]?.string, "personal_only")
        var newer = p; newer["source_revision_date"] = .string("2027-01-15")
        _ = try store.add(.object(newer))
        var other = p; other["institution"] = .string("Another Hospital"); other["profile_id"] = .string("other")
        _ = try store.add(.object(other))
        XCTAssertEqual(store.library.entries.count, 3)
        XCTAssertEqual(store.groups.count, 2)
        let bumct = try XCTUnwrap(store.groups.first { $0.institution.hasPrefix("Banner") })
        XCTAssertEqual(bumct.versions.count, 2)
        XCTAssertEqual(bumct.versions.first?.sourceRevisionDate, "2027-01-15")       // newest is current
        XCTAssertTrue(store.isCurrent(bumct.currentProfileId))
        XCTAssertFalse(store.isCurrent(bumct.versions[1].profileId))                // older is superseded
        XCTAssertEqual(store.library.default_profile_id, store.library.entries[0].profileId) // first import is default
        try store.delete(store.library.entries[0].profileId)
        XCTAssertNotNil(store.library.default_profile_id)                            // default reassigned
    }

    // MARK: - Evaluator through the app's linked engine

    func testKitVignettesThroughApp() throws {
        let profile = try Self.fixtureProfile()
        let passed = try Self.runVignettes(profile: profile, idMap: { $0 })
        XCTAssertEqual(passed, 27)
    }

    /// Runs T01–T27 against `profile`, translating fixture criterion ids with `idMap`.
    static func runVignettes(profile: JSONValue, idMap: (String) -> String) throws -> Int {
        let suite = try kit("trauma-vignettes.json")
        func set(_ v: JSONValue?) -> [String] { (v?.array?.compactMap(\.string) ?? []).map(idMap).sorted() }
        var pass = 0
        for v in suite["vignettes"]?.array ?? [] {
            var vitals: [String: Double] = [:]
            for (k, x) in v["input"]?["vitals"]?.object ?? [:] { if let n = x.number { vitals[k] = n } }
            let checked = (v["input"]?["checked"]?.array?.compactMap(\.string) ?? []).map(idMap)
            let r = try traumaEvaluate(profile: profile, input: TraumaInput(checked: checked, vitals: vitals))
            let e = v["expect"]
            var ok = r.status == e?["status"]?.string
            if e?["status"]?.string == "ok" {
                ok = ok && r.tier == e?["tier"]?.string
                if let m = e?["met_ids"], !m.isNull { ok = ok && r.met.map(\.id).sorted() == set(m) }
                ok = ok && r.compoundHints.map(\.id).sorted() == set(e?["compound_hints"])
                    && r.advisories.map(\.id).sorted() == set(e?["advisories"]) && r.notes.map(\.id).sorted() == set(e?["notes"])
            } else {
                ok = ok && r.errors.map(\.code).sorted() == (e?["errors"]?.array?.compactMap(\.string) ?? []).sorted()
            }
            XCTAssertTrue(ok, "\(v["id"]?.string ?? "?") \(r)")
            if ok { pass += 1 }
        }
        return pass
    }

    // MARK: - PDF paths

    func testTextPDFUsesEmbeddedText() async throws {
        let doc = try ImportPipeline.openPDF(Self.fixtureURL("bumct-card-TEXT-TEST-FIXTURE.pdf"))
        var lines: [ImportPipeline.Line] = []
        for p in 0..<doc.pageCount {
            let r = try await ImportPipeline.extract(page: doc.page(at: p)!, index: p, sourceIndex: 0)
            print("text PDF page \(p + 1): \(r.path.rawValue), \(r.lines.count) lines")
            XCTAssertEqual(r.path, .textLayer, "page \(p + 1)")
            lines += r.lines
        }
        let recall = Self.recall(lines.map(\.text), against: try Self.fixtureProfile())
        print("text PDF recall: \(recall.found)/\(recall.total)")
        XCTAssertGreaterThanOrEqual(Double(recall.found) / Double(recall.total), 0.9)
    }

    func testScannedPDFUsesOCR() async throws {
        let doc = try ImportPipeline.openPDF(Self.fixtureURL("bumct-card-SCANNED-TEST-FIXTURE.pdf"))
        var lines: [ImportPipeline.Line] = []
        for p in 0..<doc.pageCount {
            let r = try await ImportPipeline.extract(page: doc.page(at: p)!, index: p, sourceIndex: 0)
            print("scanned PDF page \(p + 1): \(r.path.rawValue), \(r.lines.count) lines")
            XCTAssertEqual(r.path, .ocr, "page \(p + 1)")
            lines += r.lines
        }
        let recall = Self.recall(lines.map(\.text), against: try Self.fixtureProfile())
        print("scanned PDF recall: \(recall.found)/\(recall.total)")
        XCTAssertGreaterThanOrEqual(Double(recall.found) / Double(recall.total), 0.8)
    }

    func testPhotoOCRRecall() async throws {
        let img = try XCTUnwrap(UIImage(contentsOfFile: Self.fixtureURL("bumct-card-photo-TEST-FIXTURE.jpg").path))
        let r = try await ImportPipeline.recognize(image: img, sourceIndex: 0)
        let recall = Self.recall(r.lines.map(\.text), against: try Self.fixtureProfile())
        print("photo OCR: \(r.lines.count) lines, recall \(recall.found)/\(recall.total); missed: \(recall.missed)")
        XCTAssertGreaterThanOrEqual(Double(recall.found) / Double(recall.total), 0.8)
    }

    // MARK: - Photo import against the answer key

    /// The review step is a person's work, so it is scripted here from the
    /// fixture (the answer key): each criterion line is matched to the OCR
    /// output, corrected to the card text as a reviewer would, given its
    /// fixture role/tier/kind/template, and the draft goes through the same
    /// save gate, assembly and validation as the app. The resulting profile
    /// must evaluate T01–T27 the same as the fixture.
    func testPhotoImportMatchesFixtureAfterReview() async throws {
        let img = try XCTUnwrap(UIImage(contentsOfFile: Self.fixtureURL("bumct-card-photo-TEST-FIXTURE.jpg").path))
        let ocr = try await ImportPipeline.recognize(image: img, sourceIndex: 0)
        try await assertReviewedImportMatches(ocrLines: ocr.lines, createdVia: "photo_import")
    }

    func testScannedPDFImportMatchesFixtureAfterReview() async throws {
        let doc = try ImportPipeline.openPDF(Self.fixtureURL("bumct-card-SCANNED-TEST-FIXTURE.pdf"))
        var lines: [ImportPipeline.Line] = []
        for p in 0..<doc.pageCount { lines += try await ImportPipeline.extract(page: doc.page(at: p)!, index: p, sourceIndex: 0).lines }
        try await assertReviewedImportMatches(ocrLines: lines, createdVia: "pdf_import")
    }

    func testTextPDFImportMatchesFixtureAfterReview() async throws {
        let doc = try ImportPipeline.openPDF(Self.fixtureURL("bumct-card-TEXT-TEST-FIXTURE.pdf"))
        var lines: [ImportPipeline.Line] = []
        for p in 0..<doc.pageCount { lines += try await ImportPipeline.extract(page: doc.page(at: p)!, index: p, sourceIndex: 0).lines }
        try await assertReviewedImportMatches(ocrLines: lines, createdVia: "pdf_import")
    }

    private func assertReviewedImportMatches(ocrLines: [ImportPipeline.Line], createdVia: String) async throws {
        let fx = try Self.fixtureProfile()
        let templates = try Self.kit("rule-templates.json")
        var d = ImportDraft()
        d.institution = fx["institution"]?.string ?? ""
        d.title = fx["title"]?.string ?? ""
        d.revisionDate = fx["source_revision_date"]?.string ?? ""
        d.bannerText = fx["banner_text"]?.string ?? ""
        d.tiers = (fx["tiers"]?.array ?? []).map { .init(id: $0["id"]!.string!, label: $0["label"]!.string!, color: $0["color"]!.string!, rank: Int($0["rank"]!.number!)) }
        d.vitals = (fx["vitals"]?.array ?? []).map { .init(id: $0["id"]!.string!, label: $0["label"]!.string!, unit: $0["unit"]?.string ?? "",
                                                          min: $0["min"]!.number!, max: $0["max"]!.number!, decimals: Int($0["decimals"]?.number ?? 0)) }
        func ref(_ v: JSONValue?) -> ImportDraft.TemplateRef? {
            guard let v, v.truthy, let id = v["id"]?.string else { return nil }
            return .init(id: id, params: v["params"]?.object ?? [:])
        }
        var idMap: [String: String] = [:]
        var counters: [String: Int] = [:]
        var n = 0
        func line(_ text: String, role: String, tier: String?) -> ImportDraft.ReviewLine {
            n += 1
            let match = Self.bestMatch(text, in: ocrLines)
            return .init(id: "L\(n)", text: text, sourceIndex: 0, page: match?.page, box: match?.box ?? .zero, path: match?.path ?? .ocr,
                         role: role, tier: tier, group: nil, confirmed: true, doubleChecked: needsDoubleCheck(text))
        }
        for c in fx["criteria"]?.array ?? [] {
            let tier = c["tier"]!.string!
            var l = line(c["text"]!.string!, role: "criterion", tier: tier)
            l.group = c["group"]?.string
            l.kind = c["kind"]?.string
            l.auto = ref(c["auto"]?["template"])
            if let comp = c["compound"] {
                l.compoundBaseText = comp["base_text"]?.string
                l.compoundRequiresTier = comp["requires_any_criterion_of_tier"]?.string
                l.compoundHint = comp["unmet_hint"]?.string
                l.compoundBase = ref(comp["base_template"])
            }
            l.advisoryTier = c["show_when_result_tier"]?.string
            d.lines.append(l)
            counters[tier, default: 0] += 1
            idMap[c["id"]!.string!] = "\(tier).\(counters[tier]!)"
            if let note = c["note"]?.string { d.lines.append(line(note, role: "note", tier: tier)) }
        }
        for t in fx["tiers"]?.array ?? [] {
            for member in t["team_response"]?.array?.compactMap(\.string) ?? [] { d.lines.append(line(member, role: "team_response", tier: t["id"]?.string)) }
            if let rt = t["response_time"]?.string { d.lines.append(line(rt, role: "response_time", tier: t["id"]?.string)) }
        }
        XCTAssertTrue(d.saveGate.ok, "\(d.saveGate.blocking.map(\.code))")
        let built = try d.buildProfile(templates: templates, createdVia: createdVia)
        XCTAssertEqual(validateProfile(built, templates: templates), [], "built profile must validate")
        XCTAssertEqual(built["tiers"]?.array?.map { $0["team_response"] }, fx["tiers"]?.array?.map { $0["team_response"] })
        let passed = try Self.runVignettes(profile: built, idMap: { idMap[$0] ?? $0 })
        XCTAssertEqual(passed, 27)
    }

    // MARK: - Text matching helpers

    static func norm(_ s: String) -> [String] {
        s.lowercased().replacingOccurrences(of: "[^a-z0-9<>≤≥]+", with: " ", options: .regularExpression)
            .split(separator: " ").map(String.init)
    }

    /// Best OCR line for the opening words of `text` (token overlap).
    static func bestMatch(_ text: String, in lines: [ImportPipeline.Line]) -> ImportPipeline.Line? {
        let want = Array(norm(text).prefix(5))
        guard !want.isEmpty else { return nil }
        var best: (Double, ImportPipeline.Line)?
        for l in lines {
            let have = Set(norm(l.text))
            let score = Double(want.filter(have.contains).count) / Double(want.count)
            if score > (best?.0 ?? 0) { best = (score, l) }
        }
        return (best?.0 ?? 0) >= 0.6 ? best?.1 : nil
    }

    /// How many fixture criteria have their opening words in the recognized text.
    static func recall(_ texts: [String], against fx: JSONValue) -> (found: Int, total: Int, missed: [String]) {
        let pseudo = texts.enumerated().map { ImportPipeline.Line(text: $0.element, box: .zero, sourceIndex: 0, page: nil, path: .ocr) }
        // Wrapped criteria span lines, so also try each line joined with the next.
        let joined = zip(pseudo, pseudo.dropFirst()).map { ImportPipeline.Line(text: $0.text + " " + $1.text, box: .zero, sourceIndex: 0, page: nil, path: .ocr) }
        var missed: [String] = []
        let crit = fx["criteria"]?.array?.compactMap { $0["text"]?.string } ?? []
        for t in crit where bestMatch(t, in: pseudo + joined) == nil { missed.append(t) }
        return (crit.count - missed.count, crit.count, missed)
    }
}
