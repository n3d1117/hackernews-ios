import SwiftUI
import MarkdownUI

private let commentSpacing: CGFloat = 12

struct PostDetailView: View {
    let story: Story
    private let api = HackerNewsAPI()

    @State private var comments: [Comment] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header

                if isLoading {
                    ProgressView("Loading comments...")
                        .frame(maxWidth: .infinity, alignment: .center)
                } else if let errorMessage {
                    VStack(spacing: 8) {
                        Text("Could not load comments")
                            .font(.headline)
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                        Button("Retry") {
                            Task { await loadComments() }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                } else {
                    VStack(alignment: .leading, spacing: commentSpacing) {
                        ForEach(comments) { comment in
                            CommentView(comment: comment, depth: 0)
                        }
                    }
                    .markdownTheme(.minimalGitHub)
                }
            }
            .padding(.horizontal)
            .padding(.top, 16)
        }
        .navigationTitle("Post")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadComments()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(story.title)
                .font(.title3.bold())
            if let url = story.url {
                Link(destination: url) {
                    Text(url.absoluteString)
                        .font(.subheadline)
                        .foregroundStyle(.blue)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
            }
        }
    }

    @MainActor
    private func loadComments() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            let thread = try await api.storyThread(id: story.id)
            comments = thread.comments
            errorMessage = nil
        } catch {
            comments = []
            errorMessage = error.localizedDescription
        }
    }
}

private struct CommentView: View {
    let comment: Comment
    let depth: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let author = comment.author {
                HStack(spacing: 5) {
                    Image(systemName: "person.crop.circle.fill")
                        .foregroundStyle(.secondary)
                        .imageScale(.small)
                    Text(author)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                .padding(.bottom, 6)
            }
            
            if let content = comment.content, content != "[deleted]" {
                Markdown(content)
            }
            
            if !comment.children.isEmpty {
                VStack(alignment: .leading, spacing: commentSpacing) {
                    ForEach(comment.children) { child in
                        CommentView(comment: child, depth: depth + 1)
                    }
                }
                .padding(.top, commentSpacing)
                .padding(.leading, 12)
            }
        }
        .padding(.leading, CGFloat(depth) * 8)
    }
}
