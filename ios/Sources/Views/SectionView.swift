import SwiftUI

// A single section: its own search field (the flat index, pre-filtered) + a
// Category -> Item list. Modules whose `crossListIn` names this section appear
// here too, flagged. The Peds lens floats peds/neonate rows to the top.

struct SectionView: View {
    let sectionID: String
    @EnvironmentObject private var content: ContentStore
    @AppStorage("kairos.careSetting") private var careSetting = ""
    @AppStorage("kairos.pedsLens") private var pedsLens = false
    @State private var query = ""

    private var lens: String? { careSetting.isEmpty ? nil : careSetting }
    private var section: AppSection? { content.sections.first { $0.id == sectionID } }

    var body: some View {
        Group {
            if let section {
                let hasPeds = content.searchIndex.entries.contains { $0.appears(inSection: section.title) && $0.isPeds }
                List {
                    Text(section.coreQuestion)
                        .font(Theme.subheadline).foregroundStyle(.secondary)
                        .listRowSeparator(.hidden)

                    if hasPeds {
                        Toggle("Peds lens", isOn: $pedsLens)
                            .font(Theme.subheadline)
                            .listRowSeparator(.hidden)
                    }

                    ForEach(categories(section), id: \.title) { cat in
                        Section("\(cat.title) (\(cat.items.count))") {
                            ForEach(cat.items) { item in
                                NavigationLink(value: Route.content(item.route)) {
                                    HStack {
                                        Text(item.title)
                                        if item.section != section.title {
                                            Spacer()
                                            Text("peds")
                                                .font(Theme.caption2)
                                                .foregroundStyle(Theme.sectionColor("peds-module"))
                                        }
                                    }
                                }
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
        let all = content.searchIndex.entries
        let pool: [SearchEntry] = query.isEmpty
            ? all.filter { $0.appears(inSection: section.title) }
            : content.searchIndex.search(query, setting: lens).filter { $0.appears(inSection: section.title) }
        return section.categories.compactMap { cat in
            let items = pool
                .filter { $0.category(inSection: section.title) == cat.title }
                .sorted { a, b in
                    if pedsLens, a.isPeds != b.isPeds { return a.isPeds && !b.isPeds }
                    let ea = careEmphasisRank(a, lens), eb = careEmphasisRank(b, lens)
                    return ea != eb ? ea < eb : a.title < b.title
                }
            return items.isEmpty ? nil : SearchIndex.TOCCategory(id: cat.id, title: cat.title, items: items)
        }
    }
}
