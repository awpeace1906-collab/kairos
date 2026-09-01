import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var content: ContentStore
    @State private var query = ""
    @State private var sectionFilter: String? = nil

    private var results: [SearchEntry] {
        content.searchIndex.search(query, section: sectionFilter)
    }

    var body: some View {
        List {
            Section {
                VStack(spacing: 2) {
                    Text("Kairos").font(.system(size: 34, weight: .semibold))
                    Text("the critical moment").font(.callout).italic().foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .listRowSeparator(.hidden)
            }

            if query.isEmpty {
                emptyStateTOC
                sectionTiles
            } else {
                searchResults
            }
        }
        .listStyle(.insetGrouped)
        .searchable(text: $query, prompt: "Search all sections — e.g. “chest pain”, “gbs”")
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink(value: Route.about) {
                    Image(systemName: "info.circle")
                }
            }
        }
        .safeAreaInset(edge: .top) {
            if !query.isEmpty { filterChips }
        }
    }

    // MARK: search results, grouped by section

    private var searchResults: some View {
        ForEach(groupedBySection(results), id: \.0) { section, items in
            Section(section.uppercased()) {
                ForEach(items) { entry in
                    NavigationLink(value: Route.content(entry.route)) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(entry.title)
                            Text(entry.category).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .overlay {
            if results.isEmpty { ContentUnavailableViewCompat(text: "No matches for “\(query)”.") }
        }
    }

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                chip("All", isOn: sectionFilter == nil) { sectionFilter = nil }
                ForEach(content.sections) { s in
                    chip(s.title, isOn: sectionFilter == s.title) { sectionFilter = s.title }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 6)
        }
        .background(.bar)
    }

    private func chip(_ label: String, isOn: Bool, tap: @escaping () -> Void) -> some View {
        Button(action: tap) {
            Text(label).font(.caption).padding(.horizontal, 12).padding(.vertical, 5)
                .background(isOn ? Color.accentColor : Color(.secondarySystemBackground),
                           in: Capsule())
                .foregroundStyle(isOn ? .white : .primary)
        }
        .buttonStyle(.plain)
    }

    // MARK: empty-state Section -> Category -> Item tree

    private var emptyStateTOC: some View {
        ForEach(content.searchIndex.toc(sections: content.sections)) { toc in
            Section {
                DisclosureGroup {
                    ForEach(toc.categories) { cat in
                        DisclosureGroup {
                            ForEach(cat.items) { item in
                                NavigationLink(item.title, value: Route.content(item.route))
                            }
                        } label: {
                            Text("\(cat.title) (\(cat.items.count))").font(.subheadline)
                        }
                    }
                } label: {
                    Label("\(toc.title) (\(toc.count))", systemImage: Theme.sectionSymbol(toc.id))
                        .font(.headline)
                }
            }
        }
    }

    private var sectionTiles: some View {
        Section("Jump to a section") {
            ForEach(content.sections) { s in
                NavigationLink(value: Route.section(s.id)) {
                    HStack {
                        Image(systemName: Theme.sectionSymbol(s.id))
                            .foregroundStyle(Theme.sectionColor(s.id))
                            .frame(width: 28)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(s.title)
                            Text(s.coreQuestion).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }

    private func groupedBySection(_ entries: [SearchEntry]) -> [(String, [SearchEntry])] {
        var order: [String] = []
        var map: [String: [SearchEntry]] = [:]
        for e in entries {
            if map[e.section] == nil { order.append(e.section) }
            map[e.section, default: []].append(e)
        }
        return order.map { ($0, map[$0]!) }
    }
}

/// Minimal stand-in so this compiles on iOS 16 (ContentUnavailableView is iOS 17+).
struct ContentUnavailableViewCompat: View {
    let text: String
    var body: some View {
        Text(text).foregroundStyle(.secondary).frame(maxWidth: .infinity, alignment: .center).padding()
    }
}
