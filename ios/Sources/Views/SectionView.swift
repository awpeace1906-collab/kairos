import SwiftUI

// A single section: its own search field (the flat index, pre-filtered) + a
// Category -> Item list. Same index, same matching — just section-scoped.

struct SectionView: View {
    let sectionID: String
    @EnvironmentObject private var content: ContentStore
    @AppStorage("kairos.careSetting") private var careSetting = ""
    @State private var query = ""

    private var lens: String? { careSetting.isEmpty ? nil : careSetting }

    private var section: AppSection? { content.sections.first { $0.id == sectionID } }

    var body: some View {
        Group {
            if let section {
                List {
                    Text(section.coreQuestion)
                        .font(Theme.subheadline).foregroundStyle(.secondary)
                        .listRowSeparator(.hidden)

                    ForEach(categories(section), id: \.title) { cat in
                        Section("\(cat.title) (\(cat.items.count))") {
                            ForEach(cat.items) { item in
                                NavigationLink(item.title, value: Route.content(item.route))
                                    .accessibilityIdentifier("row-\(item.itemID)")
                            }
                        }
                    }
                }
                .navigationTitle(section.title)
                .searchable(text: $query, prompt: "Search \(section.title)…")
                .tint(Theme.sectionColor(sectionID))
            } else {
                Text("Unknown section").foregroundStyle(.secondary)
            }
        }
    }

    private func categories(_ section: AppSection) -> [SearchIndex.TOCCategory] {
        let pool: [SearchEntry] = query.isEmpty
            ? content.searchIndex.entries.filter { $0.section == section.title }
            : content.searchIndex.search(query, section: section.title, setting: lens)
        return section.categories.compactMap { cat in
            let items = pool.filter { $0.category == cat.title }.sorted { a, b in
                let ea = careEmphasisRank(a, lens), eb = careEmphasisRank(b, lens)
                return ea != eb ? ea < eb : a.title < b.title
            }
            return items.isEmpty ? nil : SearchIndex.TOCCategory(id: cat.id, title: cat.title, items: items)
        }
    }
}
