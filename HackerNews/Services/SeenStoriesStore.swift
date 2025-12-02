import Foundation
import Observation
import SwiftUI

// Tracks which stories have already been opened.
@MainActor
@Observable
final class SeenStoriesStore {
    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let storageKey = "seen_stories"

    private var ids: Set<Int>

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        ids = Set(defaults.array(forKey: storageKey) as? [Int] ?? [])
    }

    // Indicates whether a story was read before.
    func isSeen(_ story: Story) -> Bool {
        ids.contains(story.id)
    }

    // Marks a story as seen and persists it.
    func markSeen(_ story: Story) {
        guard !ids.contains(story.id) else { return }
        ids.insert(story.id)
        defaults.set(Array(ids), forKey: storageKey)
    }
}
