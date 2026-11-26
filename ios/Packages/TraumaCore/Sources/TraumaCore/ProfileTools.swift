import Foundation

// Port of Resources/TraumaActivation/profile-tools-reference.js: template
// expansion, profile validation, the double-check rule, the import save gate,
// and the profile library. No clinical content lives here.

private let OPS: Set<String> = ["lt", "lte", "gt", "gte", "add", "mul", "div", "and", "or"]

public struct ProfileToolError: Error, Equatable { public let code: String }

private func substitute(_ node: JSONValue, _ params: [String: JSONValue]) throws -> JSONValue {
    switch node {
    case .string(let s):
        guard let r = s.range(of: #"^\{(\w+)\}$"#, options: .regularExpression) else { return node }
        let key = String(s[r].dropFirst().dropLast())
        guard let v = params[key] else { throw ProfileToolError(code: "template_param_missing") }
        return v
    case .array(let a): return .array(try a.map { try substitute($0, params) })
    case .object(let o): return .object(try o.mapValues { try substitute($0, params) })
    default: return node
    }
}

/// expandTemplate(templates, ref): the rule expression for a template reference.
public func expandTemplate(_ templates: JSONValue, _ ref: JSONValue) throws -> JSONValue {
    guard let t = templates["templates"]?.array?.first(where: { $0["id"] == ref["id"] }) else {
        throw ProfileToolError(code: "template_unknown")
    }
    let params = ref["params"]?.object ?? [:]
    for p in t["params"]?.array ?? [] {
        guard let pid = p["id"]?.string else { continue }
        guard let v = params[pid] else { throw ProfileToolError(code: "template_param_missing") }
        switch p["type"]?.string {
        case "number": if !(v.number.map { $0.isFinite } ?? false) { throw ProfileToolError(code: "template_param_invalid") }
        case "vital_id": if v.string == nil { throw ProfileToolError(code: "template_param_invalid") }
        default: break
        }
    }
    return try substitute(t["rule"] ?? .null, params)
}

/// The template's `plain` sentence with the user's parameters filled in, for
/// confirmation on screen. Vital ids are shown via `vitalLabel`.
public func fillPlain(_ template: JSONValue, params: [String: JSONValue], vitalLabel: (String) -> String) -> String {
    var s = template["plain"]?.string ?? ""
    for p in template["params"]?.array ?? [] {
        guard let pid = p["id"]?.string, let v = params[pid] else { continue }
        let text: String
        switch v {
        case .number(let n): text = jsNumberString(n)
        case .string(let id): text = p["type"]?.string == "vital_id" ? vitalLabel(id) : id
        default: text = ""
        }
        s = s.replacingOccurrences(of: "{\(pid)}", with: text)
    }
    return s
}

private func varsIn(_ node: JSONValue, _ acc: inout [String]) {
    switch node {
    case .array(let a): for n in a { varsIn(n, &acc) }
    case .object(let o):
        if let v = o["var"] { acc.append(v.string ?? "") }
        else { for (k, v) in o { if !OPS.contains(k) { acc.append("__badop:\(k)") }; varsIn(v, &acc) } }
    default: break
    }
}

private func checkRule(_ rule: JSONValue?, _ templateRef: JSONValue?, _ at: String, _ vitalIds: Set<String>,
                       _ templates: JSONValue, _ errors: inout [ValidationIssue]) {
    var vars: [String] = []
    varsIn(rule ?? .null, &vars)
    for v in vars {
        if v.hasPrefix("__badop:") { errors.append(ValidationIssue(code: "rule_unknown_operator", at: at)) }
        else if !vitalIds.contains(v) { errors.append(ValidationIssue(code: "rule_unknown_vital", at: at)) }
    }
    guard let templateRef, templateRef.truthy else { return }
    do {
        if let t = templates["templates"]?.array?.first(where: { $0["id"] == templateRef["id"] }) {
            for p in t["params"]?.array ?? [] where p["type"]?.string == "vital_id" {
                let pid = p["id"]?.string ?? ""
                if !(templateRef["params"]?[pid]?.string.map(vitalIds.contains) ?? false) {
                    throw ProfileToolError(code: "template_param_invalid")
                }
            }
        }
        let expanded = try expandTemplate(templates, templateRef)
        if expanded != (rule ?? .null) { errors.append(ValidationIssue(code: "template_mismatch", at: at)) }
    } catch let e as ProfileToolError {
        errors.append(ValidationIssue(code: e.code, at: at))
    } catch {
        errors.append(ValidationIssue(code: "template_error", at: at))
    }
}

public struct ValidationIssue: Equatable { public let code: String; public let at: String }

/// validateProfile errors, as an Error for callers that need one.
public struct ValidationFailure: Error, Equatable { public let issues: [ValidationIssue]; public init(_ issues: [ValidationIssue]) { self.issues = issues } }

/// validateProfile(profile, templates): empty means valid.
public func validateProfile(_ profile: JSONValue, templates: JSONValue) -> [ValidationIssue] {
    var errors: [ValidationIssue] = []
    for k in ["institution", "title", "source_revision_date", "distribution"] where !profile[k].truthy {
        errors.append(ValidationIssue(code: "missing_metadata", at: k))
    }
    if profile["distribution"].truthy, profile["distribution"]?.string != "personal_only" {
        errors.append(ValidationIssue(code: "distribution_not_personal", at: "distribution"))
    }
    if profile["source_revision_date"].truthy,
       !(profile["source_revision_date"]?.string?.range(of: #"^\d{4}-\d{2}-\d{2}$"#, options: .regularExpression) != nil) {
        errors.append(ValidationIssue(code: "bad_revision_date", at: "source_revision_date"))
    }

    var tierIds = Set<String>(), ranks = Set<String>()
    for t in profile["tiers"]?.array ?? [] {
        let id = t["id"]?.string ?? ""
        let rank = (try? String(data: (t["rank"] ?? .null).data(pretty: false), encoding: .utf8)) ?? ""
        if tierIds.contains(id) { errors.append(ValidationIssue(code: "duplicate_tier_id", at: id)) }
        if ranks.contains(rank) { errors.append(ValidationIssue(code: "duplicate_tier_rank", at: id)) }
        tierIds.insert(id); ranks.insert(rank)
    }
    if tierIds.isEmpty { errors.append(ValidationIssue(code: "no_tiers", at: "tiers")) }

    let vitalIds = Set((profile["vitals"]?.array ?? []).compactMap { $0["id"]?.string })
    var critIds = Set<String>()
    for c in profile["criteria"]?.array ?? [] {
        let id = c["id"]?.string ?? ""
        if critIds.contains(id) { errors.append(ValidationIssue(code: "duplicate_criterion_id", at: id)) }
        critIds.insert(id)
        if !tierIds.contains(c["tier"]?.string ?? "\u{0}") { errors.append(ValidationIssue(code: "unknown_tier", at: id)) }
        let kind = c["kind"]?.string ?? ""
        if !["criterion", "discretion", "compound", "advisory"].contains(kind) { errors.append(ValidationIssue(code: "unknown_kind", at: id)) }
        if let auto = c["auto"], auto.truthy { checkRule(auto["rule"], auto["template"], id, vitalIds, templates, &errors) }
        if kind == "compound" {
            let comp = c["compound"]
            if !(comp.truthy) || !tierIds.contains(comp?["requires_any_criterion_of_tier"]?.string ?? "\u{0}") {
                errors.append(ValidationIssue(code: "compound_unknown_tier", at: id))
            } else if let base = comp?["base_auto"], base.truthy {
                checkRule(base, comp?["base_template"], id, vitalIds, templates, &errors)
            }
        }
        if kind == "advisory", !tierIds.contains(c["show_when_result_tier"]?.string ?? "\u{0}") {
            errors.append(ValidationIssue(code: "advisory_unknown_tier", at: id))
        }
    }
    return errors
}

/// Lines with digits or comparison symbols are where OCR errors are most
/// dangerous ("≤" read as "<", "29" read as "20"); they need a second confirmation.
public func needsDoubleCheck(_ text: String) -> Bool {
    text.range(of: "[0-9<>≤≥=%]", options: .regularExpression) != nil
}

public struct DraftLine: Codable, Equatable {
    public var id: String
    public var text: String
    public var role: String?
    public var confirmed: Bool?
    public var double_checked: Bool?
    public init(id: String, text: String, role: String? = nil, confirmed: Bool? = nil, double_checked: Bool? = nil) {
        self.id = id; self.text = text; self.role = role; self.confirmed = confirmed; self.double_checked = double_checked
    }
}

public struct SaveGate: Equatable {
    public let ok: Bool
    public let blocking: [(code: String, line: String?)]
    public static func == (a: SaveGate, b: SaveGate) -> Bool {
        a.ok == b.ok && a.blocking.map(\.code) == b.blocking.map(\.code) && a.blocking.map(\.line) == b.blocking.map(\.line)
    }
}

/// canSaveDraft(draft): institution and revision date entered, every line
/// assigned and confirmed, every numeric line double-checked.
public func canSaveDraft(institution: String?, sourceRevisionDate: String?, lines: [DraftLine]) -> SaveGate {
    var blocking: [(code: String, line: String?)] = []
    if (institution ?? "").isEmpty { blocking.append(("missing_institution", nil)) }
    if (sourceRevisionDate ?? "").isEmpty { blocking.append(("missing_revision_date", nil)) }
    for l in lines {
        if l.role == "ignore" { continue }
        guard let role = l.role, !role.isEmpty else { blocking.append(("unassigned_line", l.id)); continue }
        if !(l.confirmed ?? false) { blocking.append(("unconfirmed_line", l.id)) }
        else if needsDoubleCheck(l.text) && !(l.double_checked ?? false) { blocking.append(("needs_double_check", l.id)) }
    }
    return SaveGate(ok: blocking.isEmpty, blocking: blocking)
}

// MARK: - Profile library (many facilities, many revisions; nothing is overwritten)

public struct LibraryEntry: Codable, Equatable {
    public var profile: JSONValue
    public var added_at: String
    public init(profile: JSONValue, added_at: String) { self.profile = profile; self.added_at = added_at }
    public var profileId: String { profile["profile_id"]?.string ?? "" }
}

public struct ProfileLibrary: Codable, Equatable {
    public var entries: [LibraryEntry] = []
    public var default_profile_id: String?
    public init() {}
}

private func instKey(_ s: String?) -> String { (s ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }

/// addToLibrary: never overwrites; a repeated profile_id gets -2, -3, …
public func addToLibrary(_ library: ProfileLibrary, profile: JSONValue, addedAt: String) -> (library: ProfileLibrary, id: String) {
    var lib = library
    let ids = Set(lib.entries.map(\.profileId))
    let base = profile["profile_id"]?.string ?? ""
    var id = base, n = 2
    while ids.contains(id) { id = "\(base)-\(n)"; n += 1 }
    var p = profile.object ?? [:]
    p["profile_id"] = .string(id)
    lib.entries.append(LibraryEntry(profile: .object(p), added_at: addedAt))
    if lib.default_profile_id == nil || lib.default_profile_id == "" { lib.default_profile_id = id }
    return (lib, id)
}

public func removeFromLibrary(_ library: ProfileLibrary, profileId: String) -> ProfileLibrary {
    var lib = library
    lib.entries = library.entries.filter { $0.profileId != profileId }
    if lib.default_profile_id == profileId { lib.default_profile_id = lib.entries.first?.profileId }
    return lib
}

public struct InstitutionGroup: Equatable {
    public let institution: String
    public let currentProfileId: String
    public let versions: [(profileId: String, sourceRevisionDate: String, addedAt: String)]
    public static func == (a: InstitutionGroup, b: InstitutionGroup) -> Bool {
        a.institution == b.institution && a.currentProfileId == b.currentProfileId && a.versions.map(\.profileId) == b.versions.map(\.profileId)
    }
}

/// Grouped by institution (case- and whitespace-insensitive). Newest
/// source_revision_date is current; ties go to the most recently added.
public func listByInstitution(_ library: ProfileLibrary) -> [InstitutionGroup] {
    var order: [String] = []
    var groups: [String: (institution: String, versions: [LibraryEntry])] = [:]
    for e in library.entries {
        let k = instKey(e.profile["institution"]?.string)
        if groups[k] == nil { groups[k] = (e.profile["institution"]?.string ?? "", []); order.append(k) }
        groups[k]!.versions.append(e)
    }
    func date(_ e: LibraryEntry) -> String { e.profile["source_revision_date"]?.string ?? "" }
    return order.map { k -> InstitutionGroup in
        let g = groups[k]!
        let v = g.versions.sorted { a, b in date(a) != date(b) ? date(a) > date(b) : a.added_at > b.added_at }
        return InstitutionGroup(institution: g.institution, currentProfileId: v[0].profileId,
                                versions: v.map { ($0.profileId, date($0), $0.added_at) })
    }
    .sorted { instKey($0.institution).localizedCompare(instKey($1.institution)) == .orderedAscending }
}
