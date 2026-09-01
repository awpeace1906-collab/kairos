import SwiftUI

// Tier 6 UI requirements:
//  - inline "x in a circle" clear on every entry field (clears just that field)
//  - a keyboard-collapse control (the "Done" toolbar button)
// The screen-level "Clear fields" button lives on each multi-field screen.

struct ClearableField: View {
    let label: String
    let unit: String?
    var keyboard: UIKeyboardType = .decimalPad
    @Binding var text: String
    @FocusState private var focused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 2) {
                Text(label)
                if let unit { Text("(\(unit))").foregroundStyle(.secondary) }
            }
            .font(.subheadline)

            HStack {
                TextField("", text: $text)
                    .keyboardType(keyboard)
                    .focused($focused)
                    .toolbar {
                        ToolbarItemGroup(placement: .keyboard) {
                            Spacer()
                            Button("Done") { focused = false }
                        }
                    }
                if !text.isEmpty {
                    Button {
                        text = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityLabel("Clear \(label)")
                    .buttonStyle(.plain)
                }
            }
            .padding(10)
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 10))
        }
    }
}

struct ClearFieldsButton: View {
    var action: () -> Void
    var body: some View {
        Button(role: .destructive, action: action) {
            Label("Clear fields", systemImage: "eraser")
        }
        .buttonStyle(.bordered)
    }
}

struct LastVerified: View {
    let meta: RecordMeta
    var body: some View {
        if let reviewed = meta.lastReviewed, let date = Self.month(reviewed) {
            HStack(spacing: 6) {
                Text("Last verified \(date)")
                Text("·")
                Link("Flag as outdated",
                     destination: URL(string: "mailto:content@kairos.example?subject=Kairos%20content%20flag:%20\(meta.id)%20(v\(meta.contentVersion))")!)
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
    }
    private static func month(_ iso: String) -> String? {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"
        guard let d = f.date(from: iso) else { return nil }
        f.dateFormat = "MMM yyyy"
        return f.string(from: d)
    }
}
