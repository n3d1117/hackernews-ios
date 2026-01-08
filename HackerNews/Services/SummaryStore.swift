import Foundation
import Observation

@MainActor
@Observable
final class SummaryStore {
    @ObservationIgnored private let persistence: Persistence

    private(set) var summaries: [Int: String]

    init(defaults: UserDefaults = .standard) {
        persistence = Persistence(defaults: defaults)
        summaries = persistence.initialSummaries
    }

    func summary(for storyID: Int) -> String? {
        summaries[storyID]
    }

    func save(_ summary: String, for storyID: Int) async {
        summaries[storyID] = summary
        await persistence.persist(summaries: summaries)
    }

    private actor Persistence {
        nonisolated let initialSummaries: [Int: String]
        private let defaults: UserDefaults
        private let storageKey = "story_summaries"
        private let decoder = JSONDecoder()
        private let encoder = JSONEncoder()

        init(defaults: UserDefaults = .standard) {
            self.defaults = defaults
            if let data = defaults.data(forKey: storageKey),
               let cached = try? decoder.decode([Int: String].self, from: data) {
                initialSummaries = cached
            } else {
                initialSummaries = [:]
            }
        }

        func persist(summaries: [Int: String]) {
            guard let data = try? encoder.encode(summaries) else { return }
            defaults.set(data, forKey: storageKey)
        }
    }
}
