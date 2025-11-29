import Foundation
import Testing
@testable import HackerNews

@MainActor
struct BookmarksStoreTests {
    @Test func savesAndLoadsBookmark() {
        let (store, defaults, suite) = makeStore()
        let story = sampleStory(id: 1)

        store.toggle(story)

        let restored = BookmarksStore(defaults: defaults)
        #expect(restored.isBookmarked(story))
        #expect(restored.stories.first?.title == story.title)
        #expect(restored.stories.first?.content == nil)

        defaults.removePersistentDomain(forName: suite)
    }

    @Test func removesBookmark() {
        let (store, defaults, suite) = makeStore()
        let story = sampleStory(id: 2)

        store.toggle(story) // add
        store.toggle(story) // remove

        let restored = BookmarksStore(defaults: defaults)
        #expect(restored.isBookmarked(story) == false)
        #expect(restored.stories.isEmpty)

        defaults.removePersistentDomain(forName: suite)
    }

    private func makeStore() -> (BookmarksStore, UserDefaults, String) {
        let suite = "BookmarksStoreTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        return (BookmarksStore(defaults: defaults), defaults, suite)
    }

    private func sampleStory(id: Int) -> Story {
        Story(
            id: id,
            title: "Example \(id)",
            url: URL(string: "https://example.com/\(id)"),
            domain: "example.com",
            content: "body",
            author: "author",
            points: 10,
            commentsCount: 2,
            time: 1700000000,
            type: "story"
        )
    }
}
