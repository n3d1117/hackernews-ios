import Foundation
import Testing
@testable import HackerNews

@MainActor
struct SummaryTests {
    @Test func summaryStorePersistsAcrossLaunches() async {
        let (store, defaults, suite) = makeStore()

        await store.save("cached summary", for: 1)

        let restored = SummaryStore(defaults: defaults)
        #expect(restored.summary(for: 1) == "cached summary")

        defaults.removePersistentDomain(forName: suite)
    }

    @Test func usesCacheBeforeCallingService() async {
        let (store, defaults, suite) = makeStore()
        await store.save("already here", for: 42)
        let service = StubSummaryService(isAvailable: true, result: "new summary")
        let viewModel = PostDetailViewModel(story: story(id: 42), commentID: nil, service: NoopStoryThreadService())

        viewModel.loadCachedSummary(from: store)
        await viewModel.summarize(using: store, service: service)

        #expect(viewModel.summary == "already here")
        #expect(service.calls == 0)

        defaults.removePersistentDomain(forName: suite)
    }

    @Test func summarizesAndCachesWhenAvailable() async {
        let (store, defaults, suite) = makeStore()
        let service = StubSummaryService(isAvailable: true, result: "fresh summary")
        let viewModel = PostDetailViewModel(story: story(id: 7), commentID: nil, service: NoopStoryThreadService())

        await viewModel.summarize(using: store, service: service)

        #expect(viewModel.summary == "fresh summary")
        #expect(service.calls == 1)

        let restored = SummaryStore(defaults: defaults)
        #expect(restored.summary(for: 7) == "fresh summary")

        defaults.removePersistentDomain(forName: suite)
    }

    @Test func skipsWhenUnavailable() async {
        let (store, defaults, suite) = makeStore()
        let service = StubSummaryService(isAvailable: false, result: "should not run")
        let viewModel = PostDetailViewModel(story: story(id: 9), commentID: nil, service: NoopStoryThreadService())

        await viewModel.summarize(using: store, service: service)

        #expect(viewModel.summary == nil)
        #expect(service.calls == 0)

        defaults.removePersistentDomain(forName: suite)
    }

    private func makeStore() -> (SummaryStore, UserDefaults, String) {
        let suite = "SummaryTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        return (SummaryStore(defaults: defaults), defaults, suite)
    }

    private func story(id: Int) -> Story {
        Story(
            id: id,
            title: "Story \(id)",
            url: URL(string: "https://example.com/\(id)"),
            domain: "example.com",
            content: nil,
            author: "author",
            points: nil,
            commentsCount: nil,
            time: nil,
            type: "story"
        )
    }
}

private final class StubSummaryService: SummaryService {
    let isAvailable: Bool
    let result: String?
    private(set) var calls = 0

    init(isAvailable: Bool, result: String?) {
        self.isAvailable = isAvailable
        self.result = result
    }

    func summarize(url: URL, title: String?) async -> String? {
        calls += 1
        return result
    }
}

private struct NoopStoryThreadService: StoryThreadService {
    func storyThread(id: Int) async throws -> StoryThread {
        StoryThread(story: Story(id: id, title: "", url: nil, domain: nil, content: nil, author: nil, points: nil, commentsCount: nil, time: nil, type: nil), comments: [])
    }
}
