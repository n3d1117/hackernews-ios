enum StoryFeedCategory: String, CaseIterable, Identifiable, Sendable {
    case top
    case new
    case show
    case ask
    case jobs

    var id: String { rawValue }

    var title: String {
        switch self {
        case .top: "Top"
        case .new: "New"
        case .show: "Show"
        case .ask: "Ask"
        case .jobs: "Jobs"
        }
    }

    var icon: String {
        switch self {
        case .top: "chart.bar"
        case .new: "clock.arrow.circlepath"
        case .show: "sparkles"
        case .ask: "text.bubble"
        case .jobs: "briefcase"
        }
    }

    var path: String {
        switch self {
        case .top: "news"
        case .new: "newest"
        case .show: "show"
        case .ask: "ask"
        case .jobs: "jobs"
        }
    }
}
