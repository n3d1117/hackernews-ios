import SwiftUI
import Routing

enum AppRoute: Routable {
    case post(Story, commentID: Int? = nil)

    var id: String {
        switch self {
        case let .post(story, commentID):
            return "post-\(story.id)-\(commentID ?? 0)"
        }
    }

    @ViewBuilder
    var destination: some View {
        switch self {
        case let .post(story, commentID):
            PostDetailView(story: story, commentID: commentID)
                .environment(\.openURL, DeepLinkCoordinator.shared.openURLAction)
                .onOpenURL { url in
                    _ = DeepLinkCoordinator.shared.open(url)
                }
        }
    }
}

extension EnvironmentValues {
    @Entry var router: Router<AppRoute> = Router()
}
