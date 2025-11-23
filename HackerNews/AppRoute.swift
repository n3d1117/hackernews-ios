import SwiftUI
import Routing

enum AppRoute: Routable {
    case post(Story)

    var id: String {
        switch self {
        case let .post(story):
            return "post-\(story.id)"
        }
    }

    @ViewBuilder
    var destination: some View {
        switch self {
        case let .post(story):
            PostDetailView(story: story)
        }
    }
}

extension EnvironmentValues {
    @Entry var router: Router<AppRoute> = Router()
}
