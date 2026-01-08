import Observation
import Foundation

// Drives post detail loading and comment anchor tracking.
@MainActor
@Observable
final class PostDetailViewModel {
    let story: Story
    let commentID: Int?
    @ObservationIgnored private let service: any StoryThreadService

    var storyContent: String?
    var comments: [Comment] = []
    var isLoading = false
    var errorMessage: String?
    var summary: String?
    var isSummarizing = false

    init(story: Story, commentID: Int?, service: any StoryThreadService) {
        self.story = story
        self.commentID = commentID
        self.service = service
    }

    // Loads the story thread and comment tree.
    func loadComments() async {
        guard !isLoading else { return }
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }

        do {
            let thread = try await service.storyThread(id: story.id)
            storyContent = thread.story.content
            comments = thread.comments
        } catch {
            comments = []
            errorMessage = error.localizedDescription
        }
    }

    // Loads a cached summary if one exists.
    func loadCachedSummary(from store: SummaryStore) {
        if let cached = store.summary(for: story.id) {
            summary = cached
        }
    }

    // Summarizes the story content via the provided service.
    func summarize(using store: SummaryStore, service: any SummaryService) async {
        guard !isSummarizing else { return }
        if let cached = store.summary(for: story.id) {
            summary = cached
            return
        }
        guard let url = story.url else { return }
        guard service.isAvailable else { return }
        isSummarizing = true
        defer { isSummarizing = false }

        if let generated = await service.summarize(url: url, title: story.title) {
            summary = generated
            await store.save(generated, for: story.id)
        }
    }

    // Checks whether a comment exists anywhere in the tree.
    func containsComment(withID id: Int, in comments: [Comment]? = nil) -> Bool {
        let list = comments ?? self.comments
        for comment in list {
            if comment.id == id { return true }
            if containsComment(withID: id, in: comment.children) { return true }
        }
        return false
    }
}
