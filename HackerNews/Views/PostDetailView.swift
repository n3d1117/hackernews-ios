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
        .taskOnce {
            await loadComments()
        }
    }

    private var header: some View {
        Group {
            if let url = story.url {
                Link(destination: url) {
                    headerContent
                }
                .buttonStyle(.plain)
            } else {
                headerContent
            }
        }
    }

    private var headerContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let domainText {
                Text(domainText.uppercased())
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            Text(story.title)
                .font(.title3.weight(.semibold))
                .multilineTextAlignment(.leading)

            if let authorTimeText {
                authorTimeText
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if let statsText {
                statsText
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var domainText: String? {
        story.domain ?? story.url?.host ?? "news.ycombinator.com"
    }

    private var authorTimeText: Text? {
        dotSeparated([
            story.author.map(Text.init),
            storyDate.map { Text($0, format: .relative(presentation: .numeric, unitsStyle: .narrow)) }
        ].compactMap { $0 })
    }

    private var statsText: Text? {
        dotSeparated([
            story.points.map { Text(quantified($0, singular: "point")) },
            story.commentsCount.map { Text(quantified($0, singular: "comment")) }
        ].compactMap { $0 })
    }

    private var storyDate: Date? {
        story.time.map { Date(timeIntervalSince1970: $0) }
    }

    private func dotSeparated(_ parts: [Text]) -> Text? {
        guard var text = parts.first else { return nil }
        for part in parts.dropFirst() {
            text = text + Text(" \u{00b7} ") + part
        }
        return text
    }

    private func quantified(_ value: Int, singular: String, plural: String? = nil) -> String {
        let pluralized = plural ?? singular + "s"
        return "\(value) \(value == 1 ? singular : pluralized)"
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
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    if !comment.children.isEmpty {
                        VStack(alignment: .leading, spacing: commentSpacing) {
                            ForEach(comment.children) { child in
                                CommentView(comment: child, depth: min(10, depth + 1))
                            }
                        }
                        .padding(.top, commentSpacing)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .transition(.opacity)
            }
        }
        .padding(.leading, depth == 0 ? 0 : 12)
        .frame(maxWidth: .infinity, alignment: .leading)
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
