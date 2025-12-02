import SwiftUI
import UIKit

struct StoryContextMenu: View {
    @Environment(\.openURL) private var openURL
    @Environment(\.bookmarksStore) private var bookmarks
    @Environment(\.seenStoriesStore) private var seenStories
    let story: Story
    var includeBookmark: Bool = true

    var body: some View {
        if includeBookmark {
            Button {
                bookmarks.toggle(story)
            } label: {
                Label(bookmarkTitle, systemImage: bookmarkIcon)
            }
        }

        Button {
            seenStories.markSeen(story)
            openURL(safariURL)
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
