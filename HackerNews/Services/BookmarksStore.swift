import Foundation
import Observation
import SwiftUI

@MainActor
@Observable
final class BookmarksStore {
    static let shared = BookmarksStore()

    private let defaults: UserDefaults
    private let storageKey = "bookmarked_stories"
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    var stories: [Story] = []

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        stories = load()
    }

    func isBookmarked(_ story: Story) -> Bool {
        stories.contains { $0.id == story.id }
    }

    func toggle(_ story: Story) {
        if isBookmarked(story) {
            remove(story)
        } else {
            add(story)
        }
    }

    private func add(_ story: Story) {
        stories.removeAll { $0.id == story.id }
        stories.insert(story, at: 0)
        persist()
    }

    private func remove(_ story: Story) {
        stories.removeAll { $0.id == story.id }
        persist()
    }

    private func persist() {
        guard let data = try? encoder.encode(stories.map(BookmarkRecord.init)) else { return }
        defaults.set(data, forKey: storageKey)
    }

    private func load() -> [Story] {
        guard let data = defaults.data(forKey: storageKey) else { return [] }
        guard let records = try? decoder.decode([BookmarkRecord].self, from: data) else { return [] }
        var unique: [Story] = []
        var seen = Set<Int>()
        for record in records {
            guard !seen.contains(record.id) else { continue }
            seen.insert(record.id)
            unique.append(record.story)
        }
        return unique
    }

    private struct BookmarkRecord: Codable {
        let id: Int
        let title: String
        let url: String?
        let domain: String?
        let author: String?
        let points: Int?
        let commentsCount: Int?
        let time: TimeInterval?
        let imageURL: String?

        init(_ story: Story) {
            id = story.id
            title = story.title
            url = story.url?.absoluteString
            domain = story.domain
            author = story.author
            points = story.points
            commentsCount = story.commentsCount
            time = story.time
            imageURL = story.imageURL?.absoluteString
        }

        var story: Story {
            Story(
                id: id,
                title: title,
                url: url.flatMap(URL.init(string:)),
                imageURL: imageURL.flatMap(URL.init(string:)),
                domain: domain,
                content: nil,
                author: author,
                points: points,
                commentsCount: commentsCount,
                time: time,
                type: nil
            )
        }
    }
}

private struct BookmarksStoreKey: EnvironmentKey {
    static let defaultValue: BookmarksStore = .shared
}

extension EnvironmentValues {
    var bookmarksStore: BookmarksStore {
        get { self[BookmarksStoreKey.self] }
        set { self[BookmarksStoreKey.self] = newValue }
    }
}
