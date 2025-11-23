import Foundation
import Playgrounds

struct Story: Identifiable, Decodable, Equatable, Hashable {
    let id: Int
    let title: String
    let url: URL?
    let domain: String?
    let author: String?
    let points: Int?
    let commentsCount: Int?
    let time: TimeInterval?
    let type: String?

    private enum CodingKeys: String, CodingKey {
        case id
        case title
        case url
        case domain
        case author = "user"
        case points
        case commentsCount = "comments_count"
        case time
        case type
    }

    init(id: Int, title: String, url: URL?, domain: String? = nil, author: String?, points: Int?, commentsCount: Int?, time: TimeInterval?, type: String?) {
        self.id = id
        self.title = title
        self.url = url
        self.domain = domain
        self.author = author
        self.points = points
        self.commentsCount = commentsCount
        self.time = time
        self.type = type
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        let urlString = try container.decodeIfPresent(String.self, forKey: .url)
        url = urlString.flatMap(URL.init(string:))
        domain = try container.decodeIfPresent(String.self, forKey: .domain)
        author = try container.decodeIfPresent(String.self, forKey: .author)
        points = try container.decodeIfPresent(Int.self, forKey: .points)
        commentsCount = try container.decodeIfPresent(Int.self, forKey: .commentsCount)
        time = try container.decodeIfPresent(TimeInterval.self, forKey: .time)
        type = try container.decodeIfPresent(String.self, forKey: .type)
    }
}

struct Comment: Identifiable, Decodable, Equatable, Hashable {
    let id: Int
    let author: String?
    let content: String?
    let time: TimeInterval?
    let children: [Comment]

    init(id: Int, author: String?, content: String?, time: TimeInterval? = nil, children: [Comment]) {
        self.id = id
        self.author = author
        self.content = content
        self.time = time
        self.children = children
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case author = "user"
        case content
        case time
        case children = "comments"
    }
}

struct StoryThread: Equatable {
    let story: Story
    let comments: [Comment]
}

extension Comment {
    func pruned() -> Comment? {
        let trimmedContent = content?.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedContent = (trimmedContent?.isEmpty ?? true) ? nil : trimmedContent
        let prunedChildren = children.compactMap { $0.pruned() }
        let hasContent = normalizedContent != nil
        guard hasContent || !prunedChildren.isEmpty else { return nil }
        return Comment(
            id: id,
            author: author,
            content: normalizedContent,
            time: time,
            children: prunedChildren
        )
    }
}
