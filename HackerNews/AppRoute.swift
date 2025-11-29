import SwiftUI
import Routing

enum AppRoute: Routable {
    case post(Story, commentID: Int? = nil, useZoom: Bool = false)

    var id: String {
        switch self {
        case let .post(story, commentID, _):
            return "post-\(story.id)-\(commentID ?? 0)"
        }
    }

    @ViewBuilder
    var destination: some View {
        switch self {
        case let .post(story, commentID, useZoom):
            PostRouteView(story: story, commentID: commentID, useZoom: useZoom)
        }
    }
}

extension EnvironmentValues {
    @Entry var router: Router<AppRoute> = Router()
}

private struct PostRouteView: View {
    let story: Story
    let commentID: Int?
    let useZoom: Bool
    @Environment(\.cardNamespace) private var cardNamespace

    @ViewBuilder
    var body: some View {
        let destination = PostDetailView(story: story, commentID: commentID)
            .environment(\.openURL, DeepLinkCoordinator.shared.openURLAction)

        if useZoom, let cardNamespace {
            destination
                .navigationTransition(.zoom(sourceID: story.id, in: cardNamespace))
        } else {
            destination
        }
    }
}

private struct CardNamespaceKey: EnvironmentKey {
    static let defaultValue: Namespace.ID? = nil
}

extension EnvironmentValues {
    var cardNamespace: Namespace.ID? {
        get { self[CardNamespaceKey.self] }
        set { self[CardNamespaceKey.self] = newValue }
    }
}
