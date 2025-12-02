import Routing
import SwiftUI

// Supported navigation routes for the app.
enum AppRoute: Routable {
    case bookmarks
    case post(Story, commentID: Int? = nil, useZoom: Bool = false)

    var id: String {
        switch self {
        case .bookmarks:
            return "bookmarks"
        case let .post(story, commentID, _):
            return "post-\(story.id)-\(commentID ?? 0)"
        }
    }

    @ViewBuilder
    var destination: some View {
        switch self {
        case .bookmarks:
            BookmarksDestination()
        case let .post(story, commentID, useZoom):
            PostRouteDestination(story: story, commentID: commentID, useZoom: useZoom)
        }
    }
}

private struct BookmarksDestination: View {
    var body: some View {
        BookmarksView()
    }
}

private struct PostRouteDestination: View {
    let story: Story
    let commentID: Int?
    let useZoom: Bool
    @Environment(\.cardNamespace) private var cardNamespace
    @Environment(\.storyService) private var storyService

    @ViewBuilder
    var body: some View {
        let destination = PostDetailView(
            story: story,
            commentID: commentID,
            service: storyService
        )

        if useZoom, let cardNamespace {
            destination
                .navigationTransition(.zoom(sourceID: story.id, in: cardNamespace))
        } else {
            destination
        }
    }
}
