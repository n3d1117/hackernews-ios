import SwiftUI
import Routing

// Application entry point that wires shared dependencies into the environment.
@main
struct HackerNewsApp: App {
    @State private var dependencies = AppDependencies()
    @Namespace private var cardNamespace

    var body: some Scene {
        WindowGroup {
            AppRootView(
                coordinator: dependencies.coordinator,
                api: dependencies.api
            )
            .withRouter(\.router)
            .environment(\.openURL, dependencies.coordinator.openURLAction)
            .environment(\.cardNamespace, cardNamespace)
            .environment(\.bookmarksStore, dependencies.bookmarksStore)
            .environment(\.seenStoriesStore, dependencies.seenStoriesStore)
            .environment(\.storyService, dependencies.api)
            .overlay(alignment: .center) {
                if dependencies.coordinator.isLoading {
                    loadingOverlay
                        .transition(.opacity.combined(with: .scale(scale: 0.98)))
                        .allowsHitTesting(false)
                }
            }
            .animation(.easeInOut(duration: 0.2), value: dependencies.coordinator.isLoading)
            .allowsHitTesting(!dependencies.coordinator.isLoading)
            .legacyOrangeTint()
        }
    }

    // Small overlay shown when deep-linking work is in progress.
    private var loadingOverlay: some View {
        ProgressView("Loading story...")
            .font(.callout.weight(.semibold))
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.12), lineWidth: 0.8)
            )
            .shadow(color: .black.opacity(0.12), radius: 16, y: 8)
    }
}
