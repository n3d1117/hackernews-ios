import SwiftUI
import UIKit

// Provides quick actions for a story card.
struct StoryContextMenu: View {
    @Environment(\.openURL) private var openURL
    @Environment(\.dependencies) private var dependencies
    @Environment(\.bookmarksStore) private var bookmarks
    @Environment(\.seenStoriesStore) private var seenStories
    let story: Story
    var includeBookmark: Bool = true

    var body: some View {
        if includeBookmark {
            Button {
                bookmarks.toggleAsync(story)
            } label: {
                Label(bookmarkTitle, systemImage: bookmarkIcon)
            }
        }

        Button {
            seenStories.markSeenAsync(story)
            openStory()
        } label: {
            Label("Open Story", systemImage: "safari")
        }

        Button {
            UIPasteboard.general.string = storyLinkString
        } label: {
            Label("Copy link", systemImage: "link")
        }

        Button {
            UIPasteboard.general.string = hnLinkString
        } label: {
            Label("Copy HN link", systemImage: "link.badge.plus")
        }
    }

    private var bookmarkTitle: String {
        bookmarks.isBookmarked(story) ? "Remove bookmark" : "Bookmark"
    }

    private var bookmarkIcon: String {
        bookmarks.isBookmarked(story) ? "bookmark.slash" : "bookmark"
    }

    private var safariURL: URL {
        story.url ?? hnURL
    }

    private func openStory() {
        let url = safariURL
        if shouldForceExternalSafari(url: url) {
            dependencies.coordinator.safariItem = SafariItem(url: url)
        } else {
            openURL(url)
        }
    }

    private func shouldForceExternalSafari(url: URL) -> Bool {
        guard let host = url.host?.lowercased() else { return false }
        let isHackerNews = host == "news.ycombinator.com" || host == "news.ycombinator.com."
        if story.url == nil {
            return true
        }
        return isHackerNews && url.path == "/item"
    }

    private var storyLinkString: String {
        story.url?.absoluteString ?? hnLinkString
    }

    private var hnLinkString: String {
        hnURL.absoluteString
    }

    private var hnURL: URL {
        URL(string: "https://news.ycombinator.com/item?id=\(story.id)")!
    }
}
