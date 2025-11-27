import SwiftUI
import MarkdownUI

private let commentSpacing: CGFloat = 16
private let highlightOpacity: CGFloat = 0.14

struct PostDetailView: View {
    let story: Story
    let commentID: Int?
    private let api = HackerNewsAPI()

    @State private var storyContent: String?
    @State private var comments: [Comment] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var didScrollToAnchor = false

    var body: some View {
        ScrollViewReader { proxy in
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
                                CommentView(comment: comment, depth: 0, highlightID: commentID)
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
            .taskOnce {
                await loadComments()
            }
            .onChange(of: comments) {
                scrollToAnchorIfNeeded(proxy)
            }
        }
    }

    @ViewBuilder private var header: some View {
        if let url = story.url {
            Link(destination: url) {
                StoryHeaderView(story: story, content: story.content ?? storyContent)
            }
            .buttonStyle(.plain)
        } else {
            StoryHeaderView(story: story, content: story.content ?? storyContent)
        }
    }

    @MainActor
    private func loadComments() async {
        guard !isLoading else { return }
        didScrollToAnchor = false
        isLoading = true
        defer { isLoading = false }

        do {
            let thread = try await api.storyThread(id: story.id)
            storyContent = thread.story.content
            comments = thread.comments
            errorMessage = nil
        } catch {
            comments = []
            errorMessage = error.localizedDescription
        }
    }

    private func scrollToAnchorIfNeeded(_ proxy: ScrollViewProxy) {
        guard !didScrollToAnchor, let targetID = commentID else { return }
        guard containsComment(withID: targetID, in: comments) else { return }
        didScrollToAnchor = true
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(150))
            withAnimation(.easeInOut(duration: 0.4)) {
                proxy.scrollTo(targetID, anchor: .top)
            }
        }
    }

    private func containsComment(withID id: Int, in comments: [Comment]) -> Bool {
        for comment in comments {
            if comment.id == id { return true }
            if containsComment(withID: id, in: comment.children) { return true }
        }
        return false
    }
}

private struct CommentView: View {
    let comment: Comment
    let depth: Int
    let highlightID: Int?
    @State private var isCollapsed = false
    @State private var isHighlightVisible = false
    @State private var hasFlashedHighlight = false

    var body: some View {
        VStack(alignment: .leading, spacing: commentSpacing) {
            commentBlock

            if !isCollapsed, !comment.children.isEmpty {
                VStack(alignment: .leading, spacing: commentSpacing) {
                    ForEach(comment.children) { child in
                        CommentView(comment: child, depth: min(10, depth + 1), highlightID: highlightID)
                    }
                }
            }
        }
        .id(comment.id)
        .padding(.leading, depth == 0 ? 0 : 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.25)) {
                isCollapsed.toggle()
            }
        }
        .onAppear {
            flashHighlightIfNeeded()
        }
        .onChange(of: isHighlighted) { _, _ in
            flashHighlightIfNeeded()
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

    private var isHighlighted: Bool {
        highlightID == comment.id
    }

    private var commentBlock: some View {
        let bgPadding = EdgeInsets(top: 8, leading: 10, bottom: 8, trailing: 10)

        return VStack(alignment: .leading, spacing: 8) {
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
            }

            if !isCollapsed, let content = comment.content {
                Markdown(content)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
            }
        }
        .padding(bgPadding)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isHighlightVisible ? Color.yellow.opacity(highlightOpacity) : .clear)
        )
        .animation(.easeInOut(duration: 0.3), value: isHighlightVisible)
        .padding(.top, -bgPadding.top)
        .padding(.leading, -bgPadding.leading)
        .padding(.bottom, -bgPadding.bottom)
        .padding(.trailing, -bgPadding.trailing)
    }

    private func flashHighlightIfNeeded() {
        guard isHighlighted, !hasFlashedHighlight else { return }
        hasFlashedHighlight = true
        isHighlightVisible = true
        Task {
            try? await Task.sleep(for: .milliseconds(2000))
            await MainActor.run {
                isHighlightVisible = false
            }
        }
    }
}
