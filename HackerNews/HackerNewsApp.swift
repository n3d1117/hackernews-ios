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
    @State private var coordinator = DeepLinkCoordinator()

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
    private let api = HackerNewsAPI()

    var body: some View {
        ContentView()
            .sheet(item: $coordinator.safariItem) { item in
                SafariView(url: item.url)
                    .ignoresSafeArea()
            }
            .onOpenURL { url in
                _ = coordinator.open(url)
            }
            .task(id: coordinator.pendingLink?.id) {
                guard let payload = coordinator.pendingLink else { return }
                await openStory(payload)
            }
    }

    private func openStory(_ payload: DeepLinkPayload) async {
        do {
            let thread = try await api.storyThread(id: payload.storyID)
            await MainActor.run {
                router.navigate(to: .post(thread.story, commentID: payload.commentID))
            }
        } catch {
            await MainActor.run {
                coordinator.safariItem = SafariItem(url: payload.canonicalURL)
            }
        }
        coordinator.pendingLink = nil
    }
}

private struct SafariItem: Identifiable {
    let url: URL
    var id: String { url.absoluteString }
}

@MainActor
@Observable
private final class DeepLinkCoordinator {
    var safariItem: SafariItem?
    var pendingLink: DeepLinkPayload?

    var openURLAction: OpenURLAction {
        OpenURLAction(handler: open)
    }

    func open(_ url: URL) -> OpenURLAction.Result {
        safariItem = nil
        pendingLink = DeepLinkPayload(url: url)
        if pendingLink == nil { safariItem = SafariItem(url: url) }
        return .handled
    }
}

private struct DeepLinkPayload: Equatable, Sendable {
    let storyID: Int
    let commentID: Int?
    let canonicalURL: URL

    var id: String {
        "story-\(storyID)-\(commentID ?? 0)"
    }

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
