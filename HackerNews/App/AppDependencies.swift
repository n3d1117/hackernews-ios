// Centralizes long-lived dependencies for the app lifecycle.
struct AppDependencies {
    let api: HackerNewsAPI
    let bookmarksStore: BookmarksStore
    let seenStoriesStore: SeenStoriesStore
    let coordinator: DeepLinkCoordinator

    init() {
        self.api = HackerNewsAPI()
        self.bookmarksStore = BookmarksStore()
        self.seenStoriesStore = SeenStoriesStore()
        self.coordinator = DeepLinkCoordinator(api: api)
    }
}
