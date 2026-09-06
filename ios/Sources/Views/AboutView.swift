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

                Text("The mark").font(.title3.bold()).padding(.top, 6)

                Text("The Kairos icon is a broken ring — not a closed circle. A closed circle would read as completeness or ordinary clock-time; leaving it open at one point is the whole idea. This isn’t *chronos*, time as an unbroken loop, but *kairos* — the one place in that loop where the boundary gives way and something can happen.")

                Text("**The ring** is the passage of ordinary time — the routine of a shift: steady, circular, mostly unremarkable. It’s amber rather than a cooler colour because this is lived, active time, not a countdown.")

                Text("**The gap** is the subject of the icon. Not damage, not an error — a deliberate opening. In the myth, Kairos is bald but for a single forelock: graspable only in the instant he is in front of you, gone the moment he has passed. The gap is that idea drawn geometrically — a window that exists, briefly, and then doesn’t.")

                Text("**The coral spike bridging the gap** is the decisive act: the intervention, the diagnosis made in time, the dose given at the right second. It sits inside the opening, not floating apart — the mark only resolves as a completed circuit, action fused to opportunity. Warm red against the amber gives it urgency without becoming an alarm; this is a reference tool, not a crash-cart siren.")

                Text("**The bright dot at the tip** is the point of contact — a struck match, a closed switch. It is the one high-saturation element in the mark, so the eye lands there first: that point is the moment the name refers to.")

                Text("At a glance it reads simply as a spark breaking through a ring — a moment of ignition. If you know the Greek, there is a second layer underneath.")

                Text("Medical & legal disclaimer").font(.title3.bold()).padding(.top, 6)

                Text("Kairos is a clinical reference and calculation aid for licensed healthcare professionals. It is provided for informational and educational purposes only and does not constitute medical advice. It does not replace clinical judgment, your institution's protocols, a medication's package insert / prescribing information, or consultation with a qualified clinician or pharmacist. Independently verify every dose, threshold, and recommendation — especially in high-acuity, pediatric, renal/hepatic-impairment, or pregnancy contexts — before acting on it. Content is checked against the sources listed on each page as of its last-verified date, but medicine changes; a citation does not guarantee the information is current. The authors and maintainers of Kairos assume no liability for clinical outcomes resulting from its use.")
                    .font(.footnote).foregroundStyle(.secondary)

                Text("Kairos v0.1.0").font(.footnote).foregroundStyle(.secondary).padding(.top, 8)
            }
            .padding()
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }
}
