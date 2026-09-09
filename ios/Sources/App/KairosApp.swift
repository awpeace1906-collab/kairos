import SwiftUI
import CoreText
import UIKit

@main
struct KairosApp: App {
    @StateObject private var content = ContentStore()
    @StateObject private var sessionStore = SessionStore()
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("kairos.onboarding.seen") private var onboardingSeen = false
    @State private var showOnboarding = false

    init() {
        Self.registerBundledFonts()
        Self.applyNavBarType()
    }

    /// Put the navigation-bar title in IBM Plex Sans SemiBold so the nav chrome
    /// matches the in-content type (SwiftUI's .navigationTitle otherwise stays SF).
    private static func applyNavBarType() {
        guard let inline = UIFont(name: "IBMPlexSans-SmBld", size: 17),
              let large = UIFont(name: "IBMPlexSans-SmBld", size: 34) else { return }
        let a = UINavigationBarAppearance()
        a.configureWithDefaultBackground()
        a.titleTextAttributes[.font] = inline
        a.largeTitleTextAttributes[.font] = large
        UINavigationBar.appearance().standardAppearance = a
        UINavigationBar.appearance().scrollEdgeAppearance = a
        UINavigationBar.appearance().compactAppearance = a
    }

    /// IBM Plex Sans + Mono ship as TTFs under Sources/Fonts/. Registering them
    /// at process start (rather than via UIAppFonts) keeps project.yml's
    /// generated Info.plist untouched.
    private static func registerBundledFonts() {
        let faces = [
            "IBMPlexSans-Regular", "IBMPlexSans-Medium", "IBMPlexSans-SemiBold", "IBMPlexSans-Bold",
            "IBMPlexMono-Regular", "IBMPlexMono-Medium", "IBMPlexMono-SemiBold",
        ]
        for name in faces {
            guard let url = Bundle.main.url(forResource: name, withExtension: "ttf") else { continue }
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }

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
    case sources
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
                        Text("Content didn't load").font(Theme.headline)
                        Text(err).font(Theme.footnote).foregroundStyle(.secondary)
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
                case .sources:            SourcesView()
                }
            }
        }
        // Body copy in IBM Plex Sans; views that need SF for a system control
        // set their own .font() and win the cascade.
        .font(Theme.sans(17))
    }
}

struct OnboardingView: View {
    var onDone: () -> Void
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            Text("Kairos").font(Theme.display(40, relativeTo: .largeTitle))
            Text("pronounced *KY-ros* (rhymes with “sky”)").font(Theme.callout).foregroundStyle(.secondary)
            Text("Greek for “the critical moment” — the point where decisive action changes the outcome. That’s the moment this app is built for.")
                .multilineTextAlignment(.center).padding(.horizontal, 32)
            Spacer()
            Button("Get started", action: onDone)
                .buttonStyle(.borderedProminent)
            Text("Full “About” is in Settings.").font(Theme.footnote).foregroundStyle(.secondary)
        }
        .padding()
        .presentationDetents([.medium])
    }
}
