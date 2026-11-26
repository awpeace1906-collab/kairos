import Foundation
import TraumaCore

/// A photo/PDF import in progress. Saved locally (draft.json, complete file
/// protection) so a long card can be finished later. Holds only what the user
/// confirms from their own card: no patient data, nothing inferred.
struct ImportDraft: Codable, Equatable {
    struct Tier: Codable, Equatable, Identifiable { var id: String; var label: String; var color: String; var rank: Int }
    struct Vital: Codable, Equatable, Identifiable { var id: String; var label: String; var unit: String; var min: Double; var max: Double; var decimals: Int }
    struct TemplateRef: Codable, Equatable { var id: String; var params: [String: JSONValue] }

    struct ReviewLine: Codable, Equatable, Identifiable {
        var id: String
        var text: String
        var sourceIndex: Int
        var page: Int?
        var box: CGRect
        var path: ImportPipeline.Path
        // Review
        var role: String?            // criterion | tier_header | group_header | team_response | response_time | note | metadata | ignore
        var tier: String?
        var group: String?
        var confirmed = false
        var doubleChecked = false
        // Criterion details (kind and rules)
        var kind: String?            // criterion | discretion | compound | advisory
        var auto: TemplateRef?
        var compoundBaseText: String?
        var compoundBase: TemplateRef?
        var compoundRequiresTier: String?
        var compoundHint: String?
        var advisoryTier: String?
    }

    var institution = ""
    var title = ""
    var revisionDate = ""          // yyyy-MM-dd
    var bannerText = ""
    var keepSources = false
    var sourceFiles: [String] = [] // file names under drafts/sources
    var pathLog: [String] = []     // "source 1 page 2: text_layer"
    var tiers: [Tier] = []
    var vitals: [Vital] = []
    var lines: [ReviewLine] = []
    var step = 0

    var draftLines: [DraftLine] {
        lines.map { DraftLine(id: $0.id, text: $0.text, role: $0.role, confirmed: $0.confirmed, double_checked: $0.doubleChecked) }
    }
    var saveGate: SaveGate { canSaveDraft(institution: institution, sourceRevisionDate: revisionDate, lines: draftLines) }

    // MARK: - Editing helpers

    /// Merge line i with the next (wrapped text). The merged line must be re-confirmed.
    mutating func merge(_ i: Int) {
        guard lines.indices.contains(i + 1) else { return }
        let next = lines.remove(at: i + 1)
        lines[i].text = lines[i].text + " " + next.text
        lines[i].box = lines[i].box.union(next.box)
        lines[i].confirmed = false; lines[i].doubleChecked = false
    }

    /// Split line i at newlines the user typed into its text.
    mutating func split(_ i: Int) {
        let parts = lines[i].text.split(separator: "\n").map { String($0).trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        guard parts.count > 1 else { return }
        let base = lines[i]
        lines.remove(at: i)
        for (k, p) in parts.enumerated() {
            var l = base; l.id = "\(base.id).\(k + 1)"; l.text = p; l.confirmed = false; l.doubleChecked = false
            lines.insert(l, at: i + k)
        }
    }

    // MARK: - Assembly

    enum AssemblyError: LocalizedError, Equatable {
        case gate([String]), template(String, String), missingKind(String), missingTier(String)
        var errorDescription: String? {
            switch self {
            case .gate(let c): return "Not ready to save: \(c.joined(separator: ", "))."
            case .template(let line, let code): return "Line \(line): auto-rule problem (\(code))."
            case .missingKind(let line): return "Line \(line): choose a kind."
            case .missingTier(let line): return "Line \(line): choose a tier."
            }
        }
    }

    /// Builds the profile JSON from the reviewed draft. Every string is a line
    /// the user confirmed or a value they typed; rules come only from templates.
    func buildProfile(templates: JSONValue, createdVia: String) throws -> JSONValue {
        let gate = saveGate
        guard gate.ok else { throw AssemblyError.gate(gate.blocking.map(\.code)) }

        var team: [String: [JSONValue]] = [:]
        var responseTime: [String: String] = [:]
        var currentGroup: [String: String] = [:]
        var criteria: [JSONValue] = []
        var counters: [String: Int] = [:]
        var lastCriterionIndex: Int?

        func vitalLabel(_ id: String) -> String { vitals.first { $0.id == id }?.label ?? id }
        func expand(_ ref: TemplateRef, line: String) throws -> (rule: JSONValue, ref: JSONValue, label: String) {
            let refJSON = JSONValue.object(["id": .string(ref.id), "params": .object(ref.params)])
            do {
                let rule = try expandTemplate(templates, refJSON)
                let t = templates["templates"]?.array?.first { $0["id"]?.string == ref.id } ?? .null
                return (rule, refJSON, fillPlain(t, params: ref.params, vitalLabel: vitalLabel))
            } catch let e as ProfileToolError { throw AssemblyError.template(line, e.code) }
        }

        for l in lines {
            switch l.role {
            case "group_header":
                if let t = l.tier { currentGroup[t] = l.text } else { for t in tiers { currentGroup[t.id] = l.text } }
            case "team_response":
                guard let t = l.tier else { throw AssemblyError.missingTier(l.id) }
                team[t, default: []].append(.string(l.text))
            case "response_time":
                guard let t = l.tier else { throw AssemblyError.missingTier(l.id) }
                responseTime[t] = responseTime[t].map { $0 + " " + l.text } ?? l.text
            case "note":
                if let i = lastCriterionIndex, var o = criteria[i].object {
                    o["note"] = .string((o["note"]?.string).map { $0 + " " + l.text } ?? l.text)
                    criteria[i] = .object(o)
                }
            case "criterion":
                guard let t = l.tier else { throw AssemblyError.missingTier(l.id) }
                guard let kind = l.kind else { throw AssemblyError.missingKind(l.id) }
                counters[t, default: 0] += 1
                let group = l.group ?? currentGroup[t] ?? ""
                var c: [String: JSONValue] = [
                    "id": .string("\(t).\(counters[t]!)"), "tier": .string(t), "section": .string(group), "group": .string(group),
                    "text": .string(l.text), "kind": .string(kind),
                ]
                switch kind {
                case "criterion":
                    if let ref = l.auto {
                        let x = try expand(ref, line: l.id)
                        c["auto"] = .object(["rule": x.rule, "label": .string(x.label), "template": x.ref])
                    }
                case "compound":
                    var comp: [String: JSONValue] = [
                        "base_text": .string(l.compoundBaseText ?? l.text),
                        "base_auto": .null,
                        "requires_any_criterion_of_tier": .string(l.compoundRequiresTier ?? ""),
                        "unmet_hint": .string(l.compoundHint ?? ""),
                    ]
                    if let ref = l.compoundBase {
                        let x = try expand(ref, line: l.id)
                        comp["base_auto"] = x.rule; comp["base_template"] = x.ref
                    }
                    c["compound"] = .object(comp)
                case "advisory":
                    c["show_when_result_tier"] = .string(l.advisoryTier ?? t)
                default: break
                }
                criteria.append(.object(c))
                lastCriterionIndex = criteria.count - 1
            default:
                continue // tier_header, metadata, ignore
            }
        }

        let tierJSON: [JSONValue] = tiers.map { t in
            var o: [String: JSONValue] = ["id": .string(t.id), "label": .string(t.label), "rank": .number(Double(t.rank)),
                                          "color": .string(t.color), "team_response": .array(team[t.id] ?? [])]
            o["response_time"] = responseTime[t.id].map { .string($0) } ?? .null
            return .object(o)
        }
        let slug = institution.lowercased().replacingOccurrences(of: "[^a-z0-9]+", with: "-", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet(charactersIn: "-"))
        var p: [String: JSONValue] = [
            "schema_version": .string("1.0"), "profile_version": .string("1.1.0"),
            "profile_id": .string("\(slug.isEmpty ? "profile" : slug)-\(revisionDate)"),
            "institution": .string(institution), "title": .string(title.isEmpty ? institution : title),
            "source_revision_date": .string(revisionDate), "distribution": .string("personal_only"),
            "tiers": .array(tierJSON),
            "vitals": .array(vitals.map { v in .object(["id": .string(v.id), "label": .string(v.label), "unit": .string(v.unit),
                                                         "min": .number(v.min), "max": .number(v.max), "decimals": .number(Double(v.decimals))]) }),
            "criteria": .array(criteria), "created_via": .string(createdVia),
        ]
        if !bannerText.trimmingCharacters(in: .whitespaces).isEmpty { p["banner_text"] = .string(bannerText) }
        return .object(p)
    }
}

/// Draft persistence (protected, in the store's folder) plus its source images.
extension LocalProtocolStore {
    var draftSourcesDir: URL { root.appendingPathComponent("draft-sources", isDirectory: true) }

    func saveDraft(_ d: ImportDraft) {
        let e = JSONEncoder()
        if let data = try? e.encode(d) { try? write(data, to: draftURL) }
    }
    func loadDraft() -> ImportDraft? {
        guard let data = try? Data(contentsOf: draftURL) else { return nil }
        return try? JSONDecoder().decode(ImportDraft.self, from: data)
    }
    func discardDraft() {
        try? FileManager.default.removeItem(at: draftURL)
        try? FileManager.default.removeItem(at: draftSourcesDir)
    }
}
