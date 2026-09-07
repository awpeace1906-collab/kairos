import Foundation

// One flat index, substring match, ranked title > tags > keywords
// (Search_TOC_Design_Spec.md). Per-section search = same index, pre-filtered.

struct SearchIndex {
    let entries: [SearchEntry]

    func search(_ query: String, section: String? = nil, setting: String? = nil) -> [SearchEntry] {
        let q = query.trimmingCharacters(in: .whitespaces).lowercased()
        guard !q.isEmpty else { return [] }
        let pool = section.map { s in entries.filter { $0.section == s } } ?? entries
        return pool
            .compactMap { e -> (SearchEntry, Int)? in
                let r = Self.rank(e, q)
                return r > 0 ? (e, r) : nil
            }
            // match quality, then the care-setting lens, then title
            .sorted { a, b in
                if a.1 != b.1 { return a.1 > b.1 }
                let ea = careEmphasisRank(a.0, setting), eb = careEmphasisRank(b.0, setting)
                if ea != eb { return ea < eb }
                return a.0.title < b.0.title
            }
            .map(\.0)
    }

    private static func rank(_ e: SearchEntry, _ q: String) -> Int {
        let title = e.title.lowercased()
        if title == q { return 100 }
        if title.hasPrefix(q) { return 80 }
        if title.contains(q) { return 60 }
        if (e.tags ?? []).contains(where: { $0.lowercased().contains(q) }) { return 40 }
        if (e.keywords ?? []).contains(where: { $0.lowercased().contains(q) }) { return 20 }
        if e.category.lowercased().contains(q) { return 10 }
        return 0
    }

    // Section -> Category -> Item tree for the empty-state TOC.
    struct TOCSection: Identifiable { let id: String; let title: String; let count: Int; let categories: [TOCCategory] }
    struct TOCCategory: Identifiable { let id: String; let title: String; let items: [SearchEntry] }

    func toc(sections: [AppSection], setting: String? = nil) -> [TOCSection] {
        sections.map { section in
            let inSection = entries.filter { $0.section == section.title }
            let cats = section.categories.compactMap { cat -> TOCCategory? in
                let items = inSection.filter { $0.category == cat.title }.sorted { a, b in
                    let ea = careEmphasisRank(a, setting), eb = careEmphasisRank(b, setting)
                    return ea != eb ? ea < eb : a.title < b.title
                }
                return items.isEmpty ? nil : TOCCategory(id: cat.id, title: cat.title, items: items)
            }
            return TOCSection(id: section.id, title: section.title, count: inSection.count, categories: cats)
        }
    }
}
