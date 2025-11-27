//
//  HackerNewsApp.swift
//  HackerNews
//
//  Created by ned on 17/10/25.
//

import Observation
import SwiftUI
import Routing

@main
struct HackerNewsApp: App {
    @State private var coordinator = DeepLinkCoordinator.shared

    var body: some Scene {
        WindowGroup {
            RootView(coordinator: coordinator)
                .environment(\.openURL, coordinator.openURLAction)
                .withRouter(\.router)
        }
    }
}

private struct RootView: View {
    @Environment(\.router) private var router
    @Bindable var coordinator: DeepLinkCoordinator

    var body: some View {
        ContentView()
            .sheet(item: $coordinator.safariItem) { item in
                SafariView(url: item.url)
            }
            .onAppear {
                coordinator.router = router
            }
            .onOpenURL { url in
                _ = coordinator.open(url)
            }
    }
}

struct SafariItem: Identifiable {
    let url: URL
    var id: String { url.absoluteString }
}

@MainActor
@Observable
final class DeepLinkCoordinator {
    static let shared = DeepLinkCoordinator()

    var router: Router<AppRoute>?
    var safariItem: SafariItem?
    private let api = HackerNewsAPI()

    var openURLAction: OpenURLAction {
        OpenURLAction(handler: open)
    }

    func open(_ url: URL) -> OpenURLAction.Result {
        safariItem = nil
        guard let payload = DeepLinkPayload(url: url) else {
            safariItem = SafariItem(url: url)
            return .handled
        }
        Task { await handle(payload) }
        return .handled
    }

    private func handle(_ payload: DeepLinkPayload) async {
        do {
            let thread = try await api.storyThread(id: payload.storyID)
            router?.navigate(to: .post(thread.story, commentID: payload.commentID))
        } catch {
            safariItem = SafariItem(url: payload.canonicalURL)
        }
    }
}

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
