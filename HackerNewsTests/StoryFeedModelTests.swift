import Foundation
import Testing
@testable import HackerNews

@MainActor
struct StoryFeedModelTests {
    @Test func appendsNextPageWithoutDuplicates() async {
        let stub = StubFrontPageService(pages: [
            [story(id: 1), story(id: 2)],
            [story(id: 2), story(id: 3)]
        ])
        let feed = StoryFeedModel(api: stub, prefetchThreshold: 1)

        await feed.loadInitial()
        #expect(feed.stories.map(\.id) == [1, 2])

        await feed.loadMoreIfNeeded(for: feed.stories.last!)
        #expect(feed.stories.map(\.id) == [1, 2, 3])
    }

    @Test func stopsWhenPageIsEmpty() async {
        let stub = StubFrontPageService(pages: [
            [story(id: 10)],
            []
        ])
        let feed = StoryFeedModel(api: stub, prefetchThreshold: 1)

        await feed.loadInitial()
        await feed.loadMoreIfNeeded(for: feed.stories.last!)

        #expect(feed.hasMorePages == false)
        #expect(feed.stories.map(\.id) == [10])
    }

    @Test func prefetchesNearTail() async {
        let stub = StubFrontPageService(pages: [
            [story(id: 1), story(id: 2), story(id: 3), story(id: 4)],
            [story(id: 5)]
        ])
        let feed = StoryFeedModel(api: stub, prefetchThreshold: 2)

        await feed.loadInitial()
        await feed.loadMoreIfNeeded(for: feed.stories[2])

        #expect(feed.stories.map(\.id) == [1, 2, 3, 4, 5])
    }

    @Test func switchesCategoryAndReloads() async {
        let stub = StubFrontPageService(pagesByCategory: [
            .top: [[story(id: 1)], [story(id: 2)]],
            .new: [[story(id: 10)], [story(id: 11)]]
        ])
        let feed = StoryFeedModel(api: stub, prefetchThreshold: 1)

        await feed.loadInitial()
        #expect(feed.stories.map(\.id) == [1])

        await feed.selectCategory(.new)
        #expect(feed.category == .new)
        #expect(feed.stories.map(\.id) == [10])

        await feed.loadMoreIfNeeded(for: feed.stories.last!)
        #expect(feed.stories.map(\.id) == [10, 11])
    }

    private func story(id: Int) -> Story {
        Story(
            id: id,
            title: "Story \(id)",
            url: nil,
            domain: "example.com",
            content: nil,
            author: "user\(id)",
            points: id,
            commentsCount: id * 2,
            time: nil,
            type: "story"
        )
    }
}

private actor StubFrontPageService: FrontPageService {
    private let pagesByCategory: [StoryFeedCategory: [[Story]]]

    init(pages: [[Story]]) {
        pagesByCategory = [.top: pages]
    }

    init(pagesByCategory: [StoryFeedCategory: [[Story]]]) {
        self.pagesByCategory = pagesByCategory
    }

    func frontPageStories(category: StoryFeedCategory, limit: Int, page: Int) async throws -> [Story] {
        let pages = pagesByCategory[category] ?? []
        guard pages.indices.contains(page - 1) else { return [] }
        return pages[page - 1]
    }
}
