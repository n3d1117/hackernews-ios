import Observation
import Routing
import SwiftUI

// Represents a pending Safari handoff for non-HN links.
struct SafariItem: Identifiable {
    let url: URL
    var id: String { url.absoluteString }
}

// Handles deep links and forwards navigation to the router.
@MainActor
@Observable
final class DeepLinkCoordinator {
    @ObservationIgnored private let api: any StoryThreadService
    @ObservationIgnored private var activeTask: Task<Void, Never>?
    @ObservationIgnored private var activeToken: UUID?

    var router: Router<AppRoute>?
    var safariItem: SafariItem?
    var isLoading = false

    init(api: any StoryThreadService) {
        self.api = api
    }

    // Binds the coordinator to the current router instance.
    func attach(router: Router<AppRoute>) {
        self.router = router
    }

    // Provides an OpenURLAction that funnels through the coordinator.
    var openURLAction: OpenURLAction {
        OpenURLAction(handler: open)
    }

    // Handles incoming URLs and dispatches app navigation.
    func open(_ url: URL) -> OpenURLAction.Result {
        safariItem = nil
        activeTask?.cancel()
        activeTask = nil
        activeToken = nil
        guard let payload = DeepLinkPayload(url: url) else {
            isLoading = false
            safariItem = SafariItem(url: url)
            return .handled
        }
        isLoading = true
        let token = UUID()
        activeToken = token
        activeTask = Task { [weak self] in
            await self?.handle(payload, token: token)
        }
        return .handled
    }

    // Resolves a deep link payload into a navigation action or Safari fallback.
    private func handle(_ payload: DeepLinkPayload, token: UUID) async {
        defer { finish(token: token) }
        do {
            let thread = try await api.storyThread(id: payload.storyID)
            guard !Task.isCancelled, token == activeToken else { return }
            router?.navigate(to: .post(thread.story, commentID: payload.commentID))
        } catch {
            guard !Task.isCancelled, token == activeToken else { return }
            safariItem = SafariItem(url: payload.canonicalURL)
        }
    }

    private func finish(token: UUID) {
        guard token == activeToken else { return }
        isLoading = false
        activeTask = nil
    }
}

// Parses and stores the actionable parts of a deep link.
struct DeepLinkPayload: Equatable, Sendable {
    let storyID: Int
    let commentID: Int?
    let canonicalURL: URL

    init?(url: URL) {
        guard let link = HackerNewsLinkParser.storyLink(from: url) else { return nil }
        storyID = link.storyID
        commentID = link.commentID
        canonicalURL = Self.canonicalURL(from: url, link: link)
    }

    private static func canonicalURL(from url: URL, link: HackerNewsLinkParser.StoryLink) -> URL {
        var canonical = url
        if canonical.scheme == nil {
            canonical = URL(string: "https://news.ycombinator.com/item?id=\(link.storyID)")!
        }
        if let commentID = link.commentID {
            var components = URLComponents(url: canonical, resolvingAgainstBaseURL: false)
            components?.fragment = "\(commentID)"
            canonical = components?.url ?? canonical
        }
        return canonical
    }
}
