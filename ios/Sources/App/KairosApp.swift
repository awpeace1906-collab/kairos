import SwiftUI

@main
struct KairosApp: App {
    @StateObject private var content = ContentStore()
    @StateObject private var sessionStore = SessionStore()
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("kairos.onboarding.seen") private var onboardingSeen = false
    @State private var showOnboarding = false

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(content)
                .environmentObject(sessionStore)
                .task {
                    content.load()
                    showOnboarding = !onboardingSeen
                }
                .onChange(of: scenePhase) { sessionStore.scenePhaseChanged($0) }
                .sheet(isPresented: $showOnboarding) {
                    OnboardingView {
                        onboardingSeen = true
                        showOnboarding = false
                    }
                }
        }
    }
}

enum Route: Hashable {
    case section(String)   // section id
    case content(String)   // search-index route
    case about
}

struct RootView: View {
    @EnvironmentObject private var content: ContentStore
    @State private var path: [Route] = []

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if let err = content.loadError {
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle").font(.largeTitle)
                        Text("Content didn't load").font(.headline)
                        Text(err).font(.footnote).foregroundStyle(.secondary)
                            .multilineTextAlignment(.center).padding()
                    }
                } else if content.sections.isEmpty {
                    ProgressView("Loading Kairos…")
                } else {
                    HomeView()
                }
            }
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .section(let id):    SectionView(sectionID: id)
                case .content(let r):     ContentDetailView(route: r)
                case .about:              AboutView()
                }
            }
        }
    }
}

struct OnboardingView: View {
    var onDone: () -> Void
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            Text("Kairos").font(.system(size: 40, weight: .semibold))
            Text("pronounced *KY-ros* (rhymes with “sky”)").font(.callout).foregroundStyle(.secondary)
            Text("Greek for “the critical moment” — the point where decisive action changes the outcome. That’s the moment this app is built for.")
                .multilineTextAlignment(.center).padding(.horizontal, 32)
            Spacer()
            Button("Get started", action: onDone)
                .buttonStyle(.borderedProminent)
            Text("Full “About” is in Settings.").font(.footnote).foregroundStyle(.secondary)
        }
        .padding()
        .presentationDetents([.medium])
    }
}
