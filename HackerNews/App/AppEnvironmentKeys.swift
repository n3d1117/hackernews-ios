import Routing
import SwiftUI

// Shared router entry for the Routing package.
extension EnvironmentValues {
    @Entry var router: Router<AppRoute> = Router()
}

// Namespace used for matched zoom transitions.
extension EnvironmentValues {
    @Entry var cardNamespace: Namespace.ID? = nil
}

// Bookmark store scoped to the current scene.
extension EnvironmentValues {
    @Entry var bookmarksStore: BookmarksStore = BookmarksStore()
}

// Seen stories store scoped to the current scene.
extension EnvironmentValues {
    @Entry var seenStoriesStore: SeenStoriesStore = SeenStoriesStore()
}

// Story service used for loading full threads.
extension EnvironmentValues {
    @Entry var storyService: any StoryThreadService = HackerNewsAPI()
}
