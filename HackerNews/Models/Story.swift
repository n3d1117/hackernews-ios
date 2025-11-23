import Foundation
import Playgrounds

struct Story: Identifiable, Decodable, Equatable, Hashable {
    let id: Int
    let title: String
    let url: URL?
    let author: String?
    let points: Int?
    let commentsCount: Int?
    let time: TimeInterval?
    let type: String?

    private enum CodingKeys: String, CodingKey {
        case id
        case title
        case url
        case author = "user"
        case points
        case commentsCount = "comments_count"
        case time
        case type
    }

    init(id: Int, title: String, url: URL?, author: String?, points: Int?, commentsCount: Int?, time: TimeInterval?, type: String?) {
        self.id = id
        self.title = title
        self.url = url
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
    let children: [Comment]
}

struct StoryThread: Equatable {
    let story: Story
    let comments: [Comment]
}
