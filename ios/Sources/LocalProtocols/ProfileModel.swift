import Foundation
import SwiftUI
import TraumaCore

/// Read-only typed view of a profile's JSON for the screens. The engine works
/// on the raw JSON (TraumaCore); this only pulls out what the UI lays out.
/// Every string shown comes from the profile.
struct ProfileModel {
    let raw: JSONValue

    struct Tier: Identifiable { let id: String; let label: String; let rank: Double; let color: String
        let teamResponse: [String]; let responseTime: String? }
    struct Vital: Identifiable { let id: String; let label: String; let unit: String; let min: Double; let max: Double; let decimals: Int }
    struct Criterion: Identifiable {
        let id: String; let tier: String; let section: String; let group: String; let text: String; let kind: String
        let autoLabel: String?; let compoundBaseText: String?; let note: String?
    }

    var profileId: String { raw["profile_id"]?.string ?? "" }
    var institution: String { raw["institution"]?.string ?? "" }
    var title: String { raw["title"]?.string ?? "" }
    var revisionDate: String { raw["source_revision_date"]?.string ?? "" }
    var bannerText: String? { raw["banner_text"]?.string }
    var appliesTo: String? { raw["applies_to_text"]?.string }

    var tiers: [Tier] {
        (raw["tiers"]?.array ?? []).compactMap { t in
            guard let id = t["id"]?.string else { return nil }
            return Tier(id: id, label: t["label"]?.string ?? id, rank: t["rank"]?.number ?? 0, color: t["color"]?.string ?? "#888888",
                        teamResponse: t["team_response"]?.array?.compactMap(\.string) ?? [], responseTime: t["response_time"]?.string)
        }.sorted { $0.rank > $1.rank }
    }
    func tier(_ id: String?) -> Tier? { tiers.first { $0.id == id } }

    var vitals: [Vital] {
        (raw["vitals"]?.array ?? []).compactMap { v in
            guard let id = v["id"]?.string else { return nil }
            return Vital(id: id, label: v["label"]?.string ?? id, unit: v["unit"]?.string ?? "",
                         min: v["min"]?.number ?? 0, max: v["max"]?.number ?? 0, decimals: Int(v["decimals"]?.number ?? 0))
        }
    }

    var criteria: [Criterion] {
        (raw["criteria"]?.array ?? []).compactMap { c in
            guard let id = c["id"]?.string else { return nil }
            return Criterion(id: id, tier: c["tier"]?.string ?? "", section: c["section"]?.string ?? "", group: c["group"]?.string ?? "",
                             text: c["text"]?.string ?? "", kind: c["kind"]?.string ?? "",
                             autoLabel: c["auto"]?["label"]?.string, compoundBaseText: c["compound"]?["base_text"]?.string,
                             note: c["note"]?.string)
        }
    }

    /// Criteria (not advisories) grouped tier → section → group, tiers by rank (highest first),
    /// sections and groups in profile order.
    var grouped: [(tier: Tier, sections: [(section: String, groups: [(group: String, items: [Criterion])])])] {
        tiers.map { t in
            let inTier = criteria.filter { $0.tier == t.id && $0.kind != "advisory" }
            var sectionOrder: [String] = []
            for c in inTier where !sectionOrder.contains(c.section) { sectionOrder.append(c.section) }
            let sections = sectionOrder.map { s -> (section: String, groups: [(group: String, items: [Criterion])]) in
                let inSection = inTier.filter { $0.section == s }
                var groupOrder: [String] = []
                for c in inSection where !groupOrder.contains(c.group) { groupOrder.append(c.group) }
                return (s, groupOrder.map { g in (g, inSection.filter { $0.group == g }) })
            }
            return (t, sections)
        }
    }

    func criteriaCount(tier id: String) -> Int { criteria.filter { $0.tier == id && $0.kind != "advisory" }.count }

    /// "revised N months ago" from source_revision_date.
    var revisedAgo: String? {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; f.locale = Locale(identifier: "en_US_POSIX")
        guard let d = f.date(from: revisionDate) else { return nil }
        let months = Calendar.current.dateComponents([.month], from: d, to: Date()).month ?? 0
        switch months {
        case ..<1: return "revised this month"
        case 1: return "revised 1 month ago"
        default: return "revised \(months) months ago"
        }
    }
}

extension Color {
    /// Readable text on a tier color.
    static func onTier(_ hex: String) -> Color {
        var s = hex; if s.hasPrefix("#") { s.removeFirst() }
        guard s.count == 6, let v = UInt32(s, radix: 16) else { return .white }
        let r = Double((v >> 16) & 0xFF), g = Double((v >> 8) & 0xFF), b = Double(v & 0xFF)
        return (0.299 * r + 0.587 * g + 0.114 * b) > 160 ? .black : .white
    }
}
