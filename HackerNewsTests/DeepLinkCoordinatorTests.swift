import Foundation
import Routing
import Testing
@testable import HackerNews

@MainActor
struct DeepLinkCoordinatorTests {
    @Test func clearsLoadingAndKeepsSafariNilOnSuccess() async {
        let router = Router<AppRoute>()
        let service = StubStoryThreadService(result: .success(.fixture(id: 123)))
        let coordinator = DeepLinkCoordinator(api: service)
        coordinator.attach(router: router)

        _ = coordinator.open(URL(string: "https://news.ycombinator.com/item?id=123")!)
        try? await Task.sleep(for: .milliseconds(50))

        #expect(coordinator.isLoading == false)
        #expect(coordinator.safariItem == nil)
    }

    @Test func fallsBackToSafariOnFailure() async {
        let router = Router<AppRoute>()
        let service = StubStoryThreadService(result: .failure(FakeError()))
        let coordinator = DeepLinkCoordinator(api: service)
        coordinator.attach(router: router)

        let url = URL(string: "https://news.ycombinator.com/item?id=42")!
        _ = coordinator.open(url)
        try? await Task.sleep(for: .milliseconds(50))

        #expect(coordinator.safariItem?.url == url)
        #expect(coordinator.isLoading == false)
    }

    @Test func ignoresNonHNLinks() async {
        let router = Router<AppRoute>()
        let service = StubStoryThreadService(result: .failure(FakeError()))
        let coordinator = DeepLinkCoordinator(api: service)
        coordinator.attach(router: router)

        let url = URL(string: "https://example.com")!
        _ = coordinator.open(url)
        try? await Task.sleep(for: .milliseconds(50))

        #expect(coordinator.safariItem?.url == url)
    }

    @Test func appRouteIdsAreStable() {
        let story = Story(
            id: 77,
            title: "Test",
            url: nil,
            imageURL: nil,
            domain: nil,
            content: nil,
            author: nil,
            points: nil,
            commentsCount: nil,
            time: nil,
            type: nil
        )
        #expect(AppRoute.bookmarks.id == "bookmarks")
        #expect(AppRoute.post(story, commentID: 1, useZoom: true).id == "post-77-1")
    }
}

private struct FakeError: Error {}

private actor StubStoryThreadService: StoryThreadService {
    let result: Result<StoryThread, Error>

    init(result: Result<StoryThread, Error>) {
        self.result = result
    }

    func storyThread(id: Int) async throws -> StoryThread {
        switch result {
        case let .success(thread):
            return thread
        case let .failure(error):
            throw error
        }
    }
}

private extension StoryThread {
    static func fixture(id: Int) -> StoryThread {
        StoryThread(
            story: Story(
                id: id,
                title: "Example",
                url: nil,
                imageURL: nil,
                domain: nil,
                content: nil,
                author: nil,
                points: nil,
                commentsCount: nil,
                time: nil,
                type: nil
            ),
            comments: []
        )
    }
}
