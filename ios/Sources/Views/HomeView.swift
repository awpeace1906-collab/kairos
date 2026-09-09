import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var content: ContentStore
    @AppStorage("kairos.careSetting") private var careSetting = ""
    @AppStorage("kairos.pedsLens") private var pedsLens = false
    @AppStorage(Pins.key) private var pinsRaw = ""
    @State private var query = ""

    private var pins: [PinnedShortcut] {
        content.resolvePins(Pins.ids(raw: pinsRaw, curated: content.curatedPinIds))
    }
    @State private var sectionFilter: String? = nil

    private var lens: String? { careSetting.isEmpty ? nil : careSetting }

    private var results: [SearchEntry] {
        let hits = content.searchIndex.search(query, section: sectionFilter, setting: lens)
        guard pedsLens else { return hits }
        return hits.enumerated()
            .sorted { ($0.element.isPeds ? 0 : 1, $0.offset) < ($1.element.isPeds ? 0 : 1, $1.offset) }
            .map(\.element)
    }

    var body: some View {
        List {
            Section {
                HStack(spacing: 9) {
                    Text("Kairos").font(Theme.display(27))
                    RoundedRectangle(cornerRadius: 2).fill(Theme.accent).frame(width: 8, height: 8)
                    Text("the critical moment")
                        .font(Theme.mono(12)).tracking(0.4).foregroundStyle(.secondary)
                    Spacer()
                }
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 6, leading: 20, bottom: 10, trailing: 20))
            }

            Toggle("Peds lens", isOn: $pedsLens)
                .font(Theme.subheadline)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 0, leading: 20, bottom: 6, trailing: 20))

            if query.isEmpty {
                if !pins.isEmpty { pinnedShortcuts }
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
                NavigationLink(value: Route.sources) {
                    Image(systemName: "text.book.closed")
                }
                .accessibilityLabel("Sources")
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink(value: Route.about) {
                    Image(systemName: "info.circle")
                }
                .accessibilityLabel("About")
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
                            Text(entry.category).font(Theme.caption).foregroundStyle(.secondary)
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
            Text(label).font(Theme.caption).padding(.horizontal, 12).padding(.vertical, 5)
                .background(isOn ? Color.accentColor : Color(.secondarySystemBackground),
                           in: Capsule())
                .foregroundStyle(isOn ? .white : .primary)
        }
        .buttonStyle(.plain)
    }

    // MARK: pinned shortcuts (config/pinned.json)

    private var pinnedShortcuts: some View {
        Section {
            ForEach(pins) { p in
                NavigationLink(value: Route.content(p.route)) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(p.label).font(Theme.semibold(16, relativeTo: .body))
                        Text(p.blurb).font(Theme.mono(12)).foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 3)
                }
                .listRowBackground(Theme.accent.opacity(0.08))
            }
        } header: {
            Text("Pinned").font(Theme.mono(11)).tracking(1).textCase(.uppercase)
        }
    }

    // MARK: the one list of sections, with the core-question descriptions

    private var sectionTiles: some View {
        Section {
            ForEach(content.sections) { s in
                NavigationLink(value: Route.section(s.id)) {
                    HStack(spacing: 13) {
                        RoundedRectangle(cornerRadius: 5)
                            .fill(Theme.sectionColor(s.id))
                            .frame(width: 20, height: 20)
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(alignment: .firstTextBaseline) {
                                Text(s.title).font(Theme.semibold(16, relativeTo: .body))
                                Spacer()
                                Text("\(sectionCount(s.title))")
                                    .font(Theme.mono(12)).foregroundStyle(.secondary)
                            }
                            Text(s.coreQuestion).font(Theme.caption).foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .listRowBackground(Theme.sectionColor(s.id).opacity(0.06))
                .accessibilityIdentifier("section-tile-\(s.id)")
            }
        } header: {
            Text("Browse").font(Theme.mono(11)).tracking(1).textCase(.uppercase)
        }
    }

    private func sectionCount(_ title: String) -> Int {
        content.searchIndex.entries.lazy.filter { $0.section == title }.count
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
