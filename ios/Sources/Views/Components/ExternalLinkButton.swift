import Network
import SwiftUI

/// External-tool button for link cards (reference.schema.json `link`). Opens the
/// URL in the system browser via openURL, never in an embedded web view. While
/// the device is offline the card's offlineText replaces the button.
struct ExternalLinkButton: View {
    let link: ReferenceDoc.ExternalLink
    @StateObject private var network = NetworkStatus()
    @Environment(\.openURL) private var openURL

    var body: some View {
        Group {
            if network.isOnline, let url = URL(string: link.url) {
                Button { openURL(url) } label: {
                    Label(link.label, systemImage: "arrow.up.right.square")
                        .font(Theme.headline)
                        .padding(.horizontal, 6).padding(.vertical, 4)
                }
                .buttonStyle(.borderedProminent).tint(Theme.accent)
                .accessibilityIdentifier("external-link")
            } else {
                Text(link.offlineText).font(Theme.callout)
                    .modifier(BandStyle(severity: nil))
                    .accessibilityIdentifier("external-link-offline")
            }
        }
    }
}

/// Current reachability, from NWPathMonitor. One per visible button.
@MainActor
final class NetworkStatus: ObservableObject {
    @Published private(set) var isOnline = true
    private let monitor = NWPathMonitor()

    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            let online = path.status == .satisfied
            Task { @MainActor in self?.isOnline = online }
        }
        monitor.start(queue: DispatchQueue(label: "kairos.network-status"))
    }

    deinit { monitor.cancel() }
}
