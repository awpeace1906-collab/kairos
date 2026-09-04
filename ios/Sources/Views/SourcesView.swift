import SwiftUI

// Settings -> "Sources". The complete bibliography for every piece of material
// in the app, aggregated from each module's sources[] by tools/build-sources-index.mjs.
// Pass 1 renders the raw citation strings, grouped and de-duplicated; a structured
// citation registry replaces the free text later.

struct SourcesView: View {
    @EnvironmentObject private var content: ContentStore
    @State private var query = ""

    private var items: [SourceItem] { content.sourcesIndex?.items ?? [] }
    private var groupOrder: [String] { content.sourcesIndex?.groupOrder ?? [] }

    private var filtered: [SourceItem] {
        guard !query.isEmpty else { return items }
        let q = query.lowercased()
        return items.filter { $0.text.lowercased().contains(q) || $0.usedBy.contains { $0.title.lowercased().contains(q) } }
    }

    var body: some View {
        List {
            Section {
                Text("Every primary source behind the material in Kairos — \(items.count) references across the calculators, guides, drug cards, and reference library. Each page also lists its own sources at the bottom.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
            ForEach(groupOrder, id: \.self) { group in
                let gi = filtered.filter { $0.group == group }
                if !gi.isEmpty {
                    Section(group) {
                        ForEach(gi) { item in
                            VStack(alignment: .leading, spacing: 3) {
                                Text(item.text).font(.callout)
                                Text("Cited in: " + item.usedBy.map(\.title).joined(separator: ", "))
                                    .font(.caption2).foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
            }
            Section {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Listing a source here does not guarantee the linked page's content is current — check each page's own \u{201c}Last verified\u{201d} date. See About \u{203a} Medical & legal disclaimer for the full disclaimer.")
                    Text("Generated from content/sources-index.json · citations are being migrated to a structured registry.")
                }
                .font(.caption2).foregroundStyle(.secondary)
            }
        }
        .listStyle(.insetGrouped)
        .searchable(text: $query, prompt: "Filter sources")
        .navigationTitle("Sources")
        .navigationBarTitleDisplayMode(.inline)
    }
}
