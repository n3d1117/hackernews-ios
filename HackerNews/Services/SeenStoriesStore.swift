import Foundation
import Observation
import SwiftUI

// Tracks which stories have already been opened.
@MainActor
@Observable
final class SeenStoriesStore {
    @ObservationIgnored private let persistence: SeenStoriesPersistenceActor

    private var ids: Set<Int>

    init(defaults: UserDefaults = .standard) {
        self.persistence = SeenStoriesPersistenceActor(defaults: defaults)
        ids = persistence.initialIDs
    }

    // Indicates whether a story was read before.
    func isSeen(_ story: Story) -> Bool {
        ids.contains(story.id)
    }

    // Convenience to call markSeen from synchronous contexts.
    func markSeenAsync(_ story: Story) {
        Task { await markSeen(story) }
    }

    // Marks a story as seen and persists it.
    func markSeen(_ story: Story) async {
        guard !ids.contains(story.id) else { return }
        ids.insert(story.id)
        await persistence.persist(ids: ids)
    }

    private actor SeenStoriesPersistenceActor {
        nonisolated let initialIDs: Set<Int>
        private let defaults: UserDefaults
        private let storageKey = "seen_stories"

        init(defaults: UserDefaults = .standard) {
            self.defaults = defaults
            initialIDs = Set(defaults.array(forKey: storageKey) as? [Int] ?? [])
        }

        func persist(ids: Set<Int>) {
            defaults.set(Array(ids), forKey: storageKey)
        }
    }
}
