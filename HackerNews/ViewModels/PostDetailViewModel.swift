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
    var didScrollToAnchor = false

    init(story: Story, commentID: Int?, service: any StoryThreadService) {
        self.story = story
        self.commentID = commentID
        self.service = service
    }

    // Loads the story thread and comment tree.
    func loadComments() async {
        guard !isLoading else { return }
        didScrollToAnchor = false
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

    // Returns the anchor comment ID when it is present and not yet visited.
    func anchorTarget() -> Int? {
        guard !didScrollToAnchor, let targetID = commentID else { return nil }
        guard containsComment(withID: targetID, in: comments) else { return nil }
        didScrollToAnchor = true
        return targetID
    }

    // Checks whether a comment exists anywhere in the tree.
    private func containsComment(withID id: Int, in comments: [Comment]) -> Bool {
        for comment in comments {
            if comment.id == id { return true }
            if containsComment(withID: id, in: comment.children) { return true }
        }
        return false
    }
}
