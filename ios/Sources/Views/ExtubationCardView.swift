import SwiftUI
import UniformTypeIdentifiers
import ExtubationEngine

/// The extubation handoff card, in the order of logic.cardLayout, rendered to
/// a one-page PDF in memory and shared through the share sheet. Black on white
/// for printing. No patient identifiers: the label box is left blank for a
/// handwritten label. Every word comes from the logic JSON except the app name.
struct ExtubationCardView: View {
    let logic: ExtubationLogic
    let result: ExtubationResult
    let trackTitle: String
    let rescue: [RescueLine]
    let date: Date

    private static let appName = "Kairos"

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // header section (cardLayout)
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text(Self.appName).bold()
                Text(logic.ui.card.header)
                Text(trackTitle)
                Spacer()
                Text(date.formatted(date: .abbreviated, time: .shortened))
            }
            .font(.system(size: 11))
            Divider().overlay(Color.black)
            // patient label box (cardLayout)
            Text(logic.ui.card.patientLabel)
                .font(.system(size: 9))
                .padding(6)
                .frame(maxWidth: .infinity, minHeight: 80, alignment: .topLeading)
                .overlay(Rectangle().stroke(Color.black, lineWidth: 1.5))
            Text(result.chip).font(.system(size: 11, weight: .semibold, design: .monospaced))
            Text(result.title).font(.system(size: 16, weight: .semibold))
            Text(result.recommendation).font(.system(size: 11))
            ForEach(result.alerts, id: \.id) { a in
                Text(a.text).font(.system(size: 11))
                    .padding(.leading, 8)
                    .overlay(alignment: .leading) { Rectangle().fill(Color.black).frame(width: a.level == "red" ? 3 : 1.5) }
            }
            if !result.why.isEmpty {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(result.why, id: \.self) { w in Text("• \(w)").font(.system(size: 11)) }
                }
            }
            if !rescue.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(rescue) { p in
                        VStack(alignment: .leading, spacing: 0) {
                            Text(p.label).font(.system(size: 9))
                            Text(p.value).font(.system(size: 11))
                        }
                    }
                }
            }
            // references section (cardLayout)
            Text(result.sources.compactMap { logic.sources[$0]?.short }.joined(separator: " · "))
                .font(.system(size: 10, weight: .semibold))
            VStack(alignment: .leading, spacing: 2) {
                ForEach(Array(result.sources.enumerated()), id: \.offset) { i, k in
                    Text("\(i + 1). \(logic.sources[k]?.full ?? k)").font(.system(size: 9))
                }
            }
            Divider().overlay(Color.black)
            Text(logic.ui.disclaimer).font(.system(size: 9))
        }
        .foregroundStyle(Color.black)
        .padding(36)
        .frame(width: 612, alignment: .topLeading)
        .background(Color.white)
        .environment(\.colorScheme, .light)
    }
}

/// One rescue-plan answer under its field label (both from the JSON / the user).
struct RescueLine: Identifiable { let id: String; let label: String; let value: String }

/// PDF data shared through ShareLink. Built in memory; the app writes no file.
struct HandoffCardPDF: Transferable {
    let data: Data

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .pdf) { $0.data }
    }

    /// One US-letter-wide page, at least letter height, content at the top.
    @MainActor static func render(_ card: ExtubationCardView) -> Data? {
        let renderer = ImageRenderer(content: card)
        let out = NSMutableData()
        var ok = false
        renderer.render { size, draw in
            var box = CGRect(x: 0, y: 0, width: 612, height: max(size.height, 792))
            guard let consumer = CGDataConsumer(data: out as CFMutableData),
                  let ctx = CGContext(consumer: consumer, mediaBox: &box, nil) else { return }
            ctx.beginPDFPage(nil)
            ctx.translateBy(x: 0, y: box.height - size.height)
            draw(ctx)
            ctx.endPDFPage()
            ctx.closePDF()
            ok = true
        }
        return ok ? out as Data : nil
    }
}
