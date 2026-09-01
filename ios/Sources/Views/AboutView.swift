import SwiftUI

// Settings -> App Information -> "About Kairos". Literal static copy from
// README_Build_Package.md (Tier 5). Not content-as-data — it never needs a
// refresh mechanism, so it lives in the app shell.

struct AboutView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text("About Kairos").font(.largeTitle.bold())

                Text("Pronounced *KY-ros*, rhyming with “sky” — not “Kay-ros.”")

                Text("Kairos is the ancient Greek term for the critical or opportune moment: the point at which decisive action must be taken, distinct from *chronos* (ordinary, chronological time). In Hippocratic medicine, *kairos* described the precise moment when intervention could change a patient’s course — the same idea this app is named for.")

                Text("Kairos brings together the calculators, procedure guides, drug-dosing tools, and reference material you need across the ED, ICU, and OR into one companion tool — alongside AnesCalc and CRISIS, not in place of either.")

                Text("Why Kairos exists").font(.title3.bold()).padding(.top, 6)

                Text("Most of what’s genuinely useful at the bedside is scattered across a dozen or more single-purpose apps — one for suture technique, another for peds resuscitation dosing, another for a handful of calculators. Finding the right one costs time. Kairos puts that content in one place, organized around how a shift actually runs across the ED, ICU, and OR — not around which developer happened to build which tool first.")

                Text("Kairos v0.1.0").font(.footnote).foregroundStyle(.secondary).padding(.top, 8)
            }
            .padding()
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }
}
