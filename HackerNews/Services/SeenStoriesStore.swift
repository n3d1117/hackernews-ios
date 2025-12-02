import Foundation
import Observation
import SwiftUI

@MainActor
@Observable
final class SeenStoriesStore {
    static let shared = SeenStoriesStore()

    private let defaults: UserDefaults
    private let storageKey = "seen_stories"

    private var ids: Set<Int>

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        ids = Set(defaults.array(forKey: storageKey) as? [Int] ?? [])
    }

    func isSeen(_ story: Story) -> Bool {
        ids.contains(story.id)
    }

    func markSeen(_ story: Story) {
        guard !ids.contains(story.id) else { return }
        ids.insert(story.id)
        defaults.set(Array(ids), forKey: storageKey)
    }
}

private struct SeenStoriesStoreKey: EnvironmentKey {
    static let defaultValue: SeenStoriesStore = .shared
}

extension EnvironmentValues {
    @Entry var seenStoriesStore: SeenStoriesStore = .shared
}
