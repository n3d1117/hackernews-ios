// Centralizes long-lived dependencies for the app lifecycle.
struct AppDependencies {
    let api: HackerNewsAPI
    let bookmarksStore: BookmarksStore
    let seenStoriesStore: SeenStoriesStore
    let coordinator: DeepLinkCoordinator

    init(
        api: HackerNewsAPI,
        bookmarksStore: BookmarksStore,
        seenStoriesStore: SeenStoriesStore,
        coordinator: DeepLinkCoordinator? = nil
    ) {
        self.api = api
        self.bookmarksStore = bookmarksStore
        self.seenStoriesStore = seenStoriesStore
        self.coordinator = coordinator ?? DeepLinkCoordinator(api: api)
    }

    static var live: AppDependencies {
        AppDependencies(
            api: HackerNewsAPI(),
            bookmarksStore: BookmarksStore(),
            seenStoriesStore: SeenStoriesStore()
        )
    }
}
