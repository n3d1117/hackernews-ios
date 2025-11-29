import Foundation

struct HackerNewsAPI {
    private let http: HTTPService
    private let baseURL = URL(string: "https://example.backend")!
    private let headers = ["example-key": "example-value"]
    private let markdown = MarkdownService()

    init(http: HTTPService = .init()) {
        self.http = http
    }

    func frontPageStories(limit: Int = 30) async throws -> [Story] {
        let items: [FeedStory] = try await http.get(baseURL.appending(path: "news"), headers: headers)
        var stories: [Story] = []
        stories.reserveCapacity(min(limit, items.count))

        for item in items.prefix(limit) {
            let content = await markdown.convert(item.content)
            stories.append(
                Story(
                    id: item.id,
                    title: item.title,
                    url: item.url.flatMap(URL.init(string:)),
                    imageURL: item.imageURL.flatMap(URL.init(string:)),
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

    func storyThread(id: Int) async throws -> StoryThread {
        let item: FeedItem = try await http.get(baseURL.appending(path: "item/\(id)"), headers: headers)
        let comments = await mapComments(item.comments)
        let content = await markdown.convert(item.content)
        let story = Story(
            id: item.id,
            title: item.title,
            url: item.url.flatMap(URL.init(string:)),
            imageURL: item.imageURL.flatMap(URL.init(string:)),
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
    let imageURL: String?
    let url: String?
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
}

private struct FeedItem: Decodable {
    let id: Int
    let title: String
    let points: Int?
    let user: String?
    let time: TimeInterval?
    let type: String?
    let url: String?
    let imageURL: String?
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
