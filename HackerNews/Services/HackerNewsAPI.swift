import Foundation

// Fetches front page slices for different story categories.
protocol FrontPageService {
    func frontPageStories(category: StoryFeedCategory, limit: Int, page: Int) async throws -> [Story]
}

extension FrontPageService {
    func frontPageStories(category: StoryFeedCategory, page: Int) async throws -> [Story] {
        try await frontPageStories(category: category, limit: 30, page: page)
    }

    func frontPageStories(page: Int) async throws -> [Story] {
        try await frontPageStories(category: .top, page: page)
    }
}

// Fetches story threads with full comment trees.
protocol StoryThreadService {
    func storyThread(id: Int) async throws -> StoryThread
}

// Concrete Hacker News API implementation.
struct HackerNewsAPI: FrontPageService, StoryThreadService {
    private let http: HTTPService
    private let baseURL = URL(string: "https://example.backend")!
    private let headers = ["example-key": "example-value"]
    private let markdown = MarkdownService()

    init(http: HTTPService = .init()) {
        self.http = http
    }

    // Returns a page of front page stories for the given category.
    func frontPageStories(category: StoryFeedCategory = .top, limit: Int = 30, page: Int = 1) async throws -> [Story] {
        var components = URLComponents(url: baseURL.appending(path: category.path), resolvingAgainstBaseURL: false)
        components?.queryItems = [URLQueryItem(name: "page", value: "\(page)")]
        let url = components?.url ?? baseURL.appending(path: category.path)
        let items: [FeedStory] = try await http.get(url, headers: headers)
        var stories: [Story] = []
        stories.reserveCapacity(min(limit, items.count))

        for item in items.prefix(limit) {
            let content = await markdown.convert(item.content)
            stories.append(
                Story(
                    id: item.id,
                    title: item.title,
                    url: item.url,
                    imageURL: item.imageURL,
                    domain: item.domain,
                    content: content,
                    author: item.user,
                    points: item.points,
                    commentsCount: item.commentsCount,
                    time: item.time,
                    type: item.type
                )
            )
        }

        return stories
    }

    // Returns the full story thread including comments for an item ID.
    func storyThread(id: Int) async throws -> StoryThread {
        let item: FeedItem = try await http.get(baseURL.appending(path: "item/\(id)"), headers: headers)
        let comments = await mapComments(item.comments)
        let content = await markdown.convert(item.content)
        let story = Story(
            id: item.id,
            title: item.title,
            url: item.url,
            imageURL: item.imageURL,
            domain: item.domain,
            content: content,
            author: item.user,
            points: item.points,
            commentsCount: item.commentsCount,
            time: item.time,
            type: item.type
        )
        return StoryThread(story: story, comments: comments)
    }

    // Recursively maps API comments into domain models while pruning empties.
    private func mapComments(_ comments: [FeedComment]) async -> [Comment] {
        var mapped: [Comment] = []
        mapped.reserveCapacity(comments.count)
        for comment in comments {
            let children = await mapComments(comment.comments)
            let content = await markdown.convert(comment.content)
            let node = Comment(
                id: comment.id,
                author: comment.user,
                content: content,
                time: comment.time,
                children: children
            )
            if let pruned = node.pruned() {
                mapped.append(pruned)
            }
        }
        return mapped
    }
}

private struct FeedStory: Decodable {
    let id: Int
    let title: String
    let points: Int?
    let user: String?
    let time: TimeInterval?
    let commentsCount: Int?
    let type: String?
    let imageURL: URL?
    let url: URL?
    let domain: String?
    let content: String?

    private enum CodingKeys: String, CodingKey {
        case id
        case title
        case points
        case user
        case time
        case commentsCount = "comments_count"
        case type
        case imageURL = "image_url"
        case url
        case domain
        case content
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        points = try container.decodeIfPresent(Int.self, forKey: .points)
        user = try container.decodeIfPresent(String.self, forKey: .user)
        time = try container.decodeIfPresent(TimeInterval.self, forKey: .time)
        commentsCount = try container.decodeIfPresent(Int.self, forKey: .commentsCount)
        type = try container.decodeIfPresent(String.self, forKey: .type)
        imageURL = try container.decodeLossyURL(forKey: .imageURL)
        url = try container.decodeLossyURL(forKey: .url)
        domain = try container.decodeIfPresent(String.self, forKey: .domain)
        content = try container.decodeIfPresent(String.self, forKey: .content)
    }
}

private struct FeedItem: Decodable {
    let id: Int
    let title: String
    let points: Int?
    let user: String?
    let time: TimeInterval?
    let type: String?
    let url: URL?
    let imageURL: URL?
    let domain: String?
    let commentsCount: Int?
    let content: String?
    let comments: [FeedComment]

    private enum CodingKeys: String, CodingKey {
        case id
        case title
        case points
        case user
        case time
        case type
        case url
        case imageURL = "image_url"
        case domain
        case commentsCount = "comments_count"
        case content
        case comments
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        points = try container.decodeIfPresent(Int.self, forKey: .points)
        user = try container.decodeIfPresent(String.self, forKey: .user)
        time = try container.decodeIfPresent(TimeInterval.self, forKey: .time)
        type = try container.decodeIfPresent(String.self, forKey: .type)
        url = try container.decodeLossyURL(forKey: .url)
        imageURL = try container.decodeLossyURL(forKey: .imageURL)
        domain = try container.decodeIfPresent(String.self, forKey: .domain)
        commentsCount = try container.decodeIfPresent(Int.self, forKey: .commentsCount)
        content = try container.decodeIfPresent(String.self, forKey: .content)
        comments = try container.decodeIfPresent([FeedComment].self, forKey: .comments) ?? []
    }
}

private struct FeedComment: Decodable {
    let id: Int
    let level: Int?
    let user: String?
    let time: TimeInterval?
    let content: String?
    let comments: [FeedComment]

    private enum CodingKeys: String, CodingKey {
        case id
        case level
        case user
        case time
        case content
        case comments
    }
}
