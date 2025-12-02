import Foundation
import Observation
import SwiftUI

// Persists and exposes bookmarked stories.
@MainActor
@Observable
final class BookmarksStore {
    @ObservationIgnored private let persistence: BookmarkPersistenceActor

    var stories: [Story] = []

    init(defaults: UserDefaults = .standard) {
        self.persistence = BookmarkPersistenceActor(defaults: defaults)
        stories = deduplicate(persistence.initialRecords.map(\.story))
    }

    // Indicates if a story is already bookmarked.
    func isBookmarked(_ story: Story) -> Bool {
        stories.contains { $0.id == story.id }
    }

    // Convenience to toggle synchronously by spawning a Task.
    func toggleAsync(_ story: Story) {
        Task { await toggle(story) }
    }

    // Adds or removes a bookmark in a single call.
    func toggle(_ story: Story) async {
        if isBookmarked(story) {
            await remove(story)
        } else {
            await add(story)
        }
    }

    // Inserts a story at the top of the bookmark list.
    private func add(_ story: Story) async {
        stories.removeAll { $0.id == story.id }
        stories.insert(story, at: 0)
        await persist()
    }

    // Removes a bookmarked story.
    private func remove(_ story: Story) async {
        stories.removeAll { $0.id == story.id }
        await persist()
    }

    // Writes bookmarks to disk.
    private func persist() async {
        let records = stories.map(BookmarkRecord.init)
        await persistence.persist(records: records)
    }

    private func deduplicate(_ items: [Story]) -> [Story] {
        var unique: [Story] = []
        var seen = Set<Int>()
        for story in items {
            guard !seen.contains(story.id) else { continue }
            seen.insert(story.id)
            unique.append(story)
        }
        return unique
    }

    struct BookmarkRecord: Codable {
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

    private actor BookmarkPersistenceActor {
        nonisolated let initialRecords: [BookmarkRecord]
        private let defaults: UserDefaults
        private let storageKey = "bookmarked_stories"
        private let decoder = JSONDecoder()
        private let encoder = JSONEncoder()

        init(defaults: UserDefaults = .standard) {
            self.defaults = defaults
            if let data = defaults.data(forKey: storageKey),
               let records = try? decoder.decode([BookmarkRecord].self, from: data) {
                self.initialRecords = records
            } else {
                self.initialRecords = []
            }
        }

        func persist(records: [BookmarkRecord]) {
            guard let data = try? encoder.encode(records) else { return }
            defaults.set(data, forKey: storageKey)
        }
    }
}
