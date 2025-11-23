import SwiftUI
import MarkdownUI

private let commentSpacing: CGFloat = 16

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
    @State private var isCollapsed = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let metaText {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.right")
                        .imageScale(.small)
                        .foregroundStyle(.secondary)
                        .frame(width: 10, alignment: .center)
                        .rotationEffect(.degrees(isCollapsed ? 0 : 90))

                    metaText
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 8)
            }

            if !isCollapsed {
                VStack(alignment: .leading, spacing: 0) {
                    if let content = comment.content {
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
                .transition(.opacity)
            }
        }
        .padding(.leading, CGFloat(depth) * 6)
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.25)) {
                isCollapsed.toggle()
            }
        }
    }

    private var metaText: Text? {
        switch (comment.author, timestamp) {
        case let (author?, time?):
            Text(author)
            + Text(" \u{00b7} ")
            + Text(time, format: .relative(presentation: .numeric, unitsStyle: .narrow))
        case let (author?, nil):
            Text(author)
        case let (nil, time?):
            Text(time, format: .relative(presentation: .numeric, unitsStyle: .narrow))
        default:
            nil
        }
    }

    private var timestamp: Date? {
        comment.time.map { Date(timeIntervalSince1970: $0) }
    }
}
