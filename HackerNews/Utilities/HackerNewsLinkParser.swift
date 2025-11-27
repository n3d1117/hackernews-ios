import Foundation

enum HackerNewsLinkParser {
    struct StoryLink {
        let storyID: Int
        let commentID: Int?
    }

    static func storyLink(from url: URL) -> StoryLink? {
        guard isHackerNewsHost(url) else { return nil }
        guard let storyID = extractStoryID(from: url) else { return nil }
        let commentID = anchorID(from: url.fragment)
        return StoryLink(storyID: storyID, commentID: commentID)
    }

    static func storyID(from url: URL) -> Int? {
        storyLink(from: url)?.storyID
    }

    private static func extractStoryID(from url: URL) -> Int? {
        if url.scheme?.lowercased() == "hn" {
            if let host = url.host, let id = Int(host) {
                return id
            }
            if let id = Int(url.lastPathComponent) {
                return id
            }
        }

        if url.path == "/item" || url.path == "item" {
            let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            let idString = components?.queryItems?.first(where: { $0.name == "id" })?.value
            return idString.flatMap(Int.init)
        }

        if url.path.hasPrefix("/item/") || url.path.hasPrefix("item/") {
            return Int(url.lastPathComponent)
        }

        return nil
    }

    private static func anchorID(from fragment: String?) -> Int? {
        fragment.flatMap(Int.init)
    }

    private static func isHackerNewsHost(_ url: URL) -> Bool {
        if url.scheme?.lowercased() == "hn" { return true }
        guard let host = url.host?.lowercased() else {
            return url.scheme == nil
        }
        return host == "news.ycombinator.com" || host == "www.news.ycombinator.com"
    }
}
