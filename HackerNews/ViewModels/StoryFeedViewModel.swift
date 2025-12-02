import Foundation
import Observation

// Drives the front page feed with paging and category changes.
@MainActor
@Observable
final class StoryFeedViewModel {
    @ObservationIgnored private let api: any FrontPageService
    @ObservationIgnored private let prefetchThreshold: Int
    @ObservationIgnored private var loadTask: Task<Void, Never>?

    var category: StoryFeedCategory = .top
    var stories: [Story] = []
    var loadedIDs: Set<Int> = []
    var isLoading = false
    var hasMorePages = true
    var currentPage = 0
    var errorMessage: String?

    init(api: any FrontPageService, prefetchThreshold: Int = 3) {
        self.api = api
        self.prefetchThreshold = max(prefetchThreshold, 1)
    }

    // Loads initial feed data if nothing is present.
    func loadInitial() async {
        guard stories.isEmpty else { return }
        await refresh()
    }

    // Switches feed category and refreshes the list.
    func selectCategory(_ category: StoryFeedCategory) async {
        guard self.category != category else { return }
        self.category = category
        await refresh()
    }

    // Resets pagination state and fetches the first page.
    func refresh(isUserInitiated: Bool = false) async {
        await waitForInFlight()
        let clock = ContinuousClock()
        let start = clock.now
        await loadPage(1)
        if isUserInitiated {
            let elapsed = start.duration(to: clock.now)
            let remaining = .milliseconds(500) - elapsed
            if remaining > .zero {
                try? await Task.sleep(for: remaining)
            }
        }
    }

    // Prefetches the next page when the user nears the bottom.
    func loadMoreIfNeeded(for story: Story) async {
        guard shouldPrefetch(for: story) else { return }
        await loadPage(currentPage + 1)
    }

    // Fetches a specific page of stories.
    private func loadPage(_ page: Int) async {
        guard loadTask == nil else { return }
        guard page == 1 || hasMorePages else { return }

        let showLoading = stories.isEmpty || page > 1
        let task = Task { [weak self] in
            guard let self else { return }
            if showLoading {
                self.isLoading = true
            }
            defer {
                if showLoading {
                    self.isLoading = false
                }
                self.loadTask = nil
            }

            do {
                let fetched = try await self.api.frontPageStories(category: self.category, page: page)
                self.handleFetched(fetched, page: page)
            } catch {
                if page == 1 {
                    self.errorMessage = error.localizedDescription
                }
                self.hasMorePages = false
            }
        }
        loadTask = task
        await task.value
    }

    // Deduplicates and inserts freshly fetched stories.
    private func handleFetched(_ newStories: [Story], page: Int) {
        guard !newStories.isEmpty else {
            hasMorePages = false
            return
        }

        if page == 1 {
            stories = newStories
            loadedIDs = Set(newStories.map(\.id))
        } else {
            let fresh = newStories.filter { !loadedIDs.contains($0.id) }
            guard !fresh.isEmpty else {
                hasMorePages = false
                return
            }
            stories.append(contentsOf: fresh)
            loadedIDs.formUnion(fresh.map(\.id))
        }
        currentPage = page
        hasMorePages = true
        errorMessage = nil
    }

    // Checks if the next page should be triggered for a given story.
    private func shouldPrefetch(for story: Story) -> Bool {
        guard hasMorePages, loadTask == nil else { return false }
        guard let index = stories.firstIndex(where: { $0.id == story.id }) else { return false }
        let triggerIndex = max(stories.count - prefetchThreshold, 0)
        return index >= triggerIndex
    }

    // Waits for any in-flight work to finish before continuing.
    private func waitForInFlight() async {
        guard let task = loadTask else { return }
        await task.value
    }
}
