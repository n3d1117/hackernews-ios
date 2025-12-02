import Foundation

// Parses Hacker News URLs and extracts story metadata.
enum HackerNewsLinkParser {
    struct StoryLink {
        let storyID: Int
        let commentID: Int?
    }

    // Normalizes arbitrary strings into Hacker News URLs when possible.
    static func normalizedURL(from string: String) -> URL? {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        if let id = Int(trimmed) {
            return URL(string: "hn://\(id)")
        }

        if let url = URL(string: trimmed), storyLink(from: url) != nil {
            return url
        }

        if !trimmed.contains("://"),
           let url = URL(string: "https://\(trimmed)"),
           storyLink(from: url) != nil {
            return url
        }

        return nil
    }

    // Returns a parsed story/comment link if the URL is supported.
    static func storyLink(from url: URL) -> StoryLink? {
        guard isHackerNewsHost(url) else { return nil }
        guard let storyID = extractStoryID(from: url) else { return nil }
        let commentID = anchorID(from: url.fragment)
        return StoryLink(storyID: storyID, commentID: commentID)
    }

    // Extracts just the story ID for convenience.
    static func storyID(from url: URL) -> Int? {
        storyLink(from: url)?.storyID
    }

    // Pulls the story ID from various URL formats.
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

    // Pulls the comment anchor from the fragment.
    private static func anchorID(from fragment: String?) -> Int? {
        fragment.flatMap(Int.init)
    }

    // Detects whether the URL targets Hacker News.
    private static func isHackerNewsHost(_ url: URL) -> Bool {
        if url.scheme?.lowercased() == "hn" { return true }
        guard let host = url.host?.lowercased() else {
            return url.scheme == nil
        }
        return host == "news.ycombinator.com" || host == "www.news.ycombinator.com"
    }
}
