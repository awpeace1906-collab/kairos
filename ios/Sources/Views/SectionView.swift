import SwiftUI

// A single section: its own search field (the flat index, pre-filtered) + a
// Category -> Item list. Same index, same matching — just section-scoped.

struct SectionView: View {
    let sectionID: String
    @EnvironmentObject private var content: ContentStore
    @State private var query = ""

    private var section: AppSection? { content.sections.first { $0.id == sectionID } }

    var body: some View {
        Group {
            if let section {
                List {
                    Text(section.coreQuestion)
                        .font(.subheadline).foregroundStyle(.secondary)
                        .listRowSeparator(.hidden)

                    ForEach(categories(section), id: \.title) { cat in
                        Section("\(cat.title) (\(cat.items.count))") {
                            ForEach(cat.items) { item in
                                NavigationLink(item.title, value: Route.content(item.route))
                            }
                        }
                    }
                }
                .navigationTitle(section.title)
                .searchable(text: $query, prompt: "Search \(section.title)…")
            } else {
                Text("Unknown section").foregroundStyle(.secondary)
            }
        }
    }

    private func categories(_ section: AppSection) -> [SearchIndex.TOCCategory] {
        let pool: [SearchEntry] = query.isEmpty
            ? content.searchIndex.entries.filter { $0.section == section.title }
            : content.searchIndex.search(query, section: section.title)
        return section.categories.compactMap { cat in
            let items = pool.filter { $0.category == cat.title }.sorted { $0.title < $1.title }
            return items.isEmpty ? nil : SearchIndex.TOCCategory(id: cat.id, title: cat.title, items: items)
        }
    }
}
