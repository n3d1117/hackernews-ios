// Centralizes long-lived dependencies for the app lifecycle.
struct AppDependencies {
    let api: HackerNewsAPI
    let bookmarksStore: BookmarksStore
    let seenStoriesStore: SeenStoriesStore
    let summaryStore: SummaryStore
    let summaryService: any SummaryService
    let coordinator: DeepLinkCoordinator

    init(
        api: HackerNewsAPI,
        bookmarksStore: BookmarksStore,
        seenStoriesStore: SeenStoriesStore,
        summaryStore: SummaryStore,
        summaryService: any SummaryService,
        coordinator: DeepLinkCoordinator? = nil
    ) {
        self.api = api
        self.bookmarksStore = bookmarksStore
        self.seenStoriesStore = seenStoriesStore
        self.summaryStore = summaryStore
        self.summaryService = summaryService
        self.coordinator = coordinator ?? DeepLinkCoordinator(api: api)
    }

    static var live: AppDependencies {
        AppDependencies(
            api: HackerNewsAPI(),
            bookmarksStore: BookmarksStore(),
            seenStoriesStore: SeenStoriesStore(),
            summaryStore: SummaryStore(),
            summaryService: SummaryServiceFactory.make()
        )
    }
}
