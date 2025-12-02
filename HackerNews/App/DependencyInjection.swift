import SwiftUI

// Applies core dependencies into the environment.
extension View {
    func injectAppDependencies(_ dependencies: AppDependencies) -> some View {
        self
            .environment(\.dependencies, dependencies)
            .environment(\.bookmarksStore, dependencies.bookmarksStore)
            .environment(\.seenStoriesStore, dependencies.seenStoriesStore)
            .environment(\.storyService, dependencies.api)
            .environment(\.openURL, dependencies.coordinator.openURLAction)
    }
}
