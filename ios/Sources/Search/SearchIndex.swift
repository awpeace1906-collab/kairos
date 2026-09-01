import Foundation

// One flat index, substring match, ranked title > tags > keywords
// (Search_TOC_Design_Spec.md). Per-section search = same index, pre-filtered.

struct SearchIndex {
    let entries: [SearchEntry]

    func search(_ query: String, section: String? = nil) -> [SearchEntry] {
        let q = query.trimmingCharacters(in: .whitespaces).lowercased()
        guard !q.isEmpty else { return [] }
        let pool = section.map { s in entries.filter { $0.section == s } } ?? entries
        return pool
            .compactMap { e -> (SearchEntry, Int)? in
                let r = Self.rank(e, q)
                return r > 0 ? (e, r) : nil
            }
            .sorted { $0.1 != $1.1 ? $0.1 > $1.1 : $0.0.title < $1.0.title }
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

    func toc(sections: [AppSection]) -> [TOCSection] {
        sections.map { section in
            let inSection = entries.filter { $0.section == section.title }
            let cats = section.categories.compactMap { cat -> TOCCategory? in
                let items = inSection.filter { $0.category == cat.title }.sorted { $0.title < $1.title }
                return items.isEmpty ? nil : TOCCategory(id: cat.id, title: cat.title, items: items)
            }
            return TOCSection(id: section.id, title: section.title, count: inSection.count, categories: cats)
        }
    }
}
