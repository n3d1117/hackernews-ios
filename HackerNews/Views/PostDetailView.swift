import SwiftUI
import MarkdownUI

private let commentSpacing: CGFloat = 18
private let highlightOpacity: CGFloat = 0.14
private let scrollTopAnchorID = "postDetailTopAnchor"

struct PostDetailView: View {
    @Environment(\.bookmarksStore) private var bookmarks
    let story: Story
    let commentID: Int?
    private let api = HackerNewsAPI()

    @State private var storyContent: String?
    @State private var comments: [Comment] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var didScrollToAnchor = false

    var body: some View {
        ZStack {
            SoftMeshBackground(
                seed: story.id,
                overlayTopOpacity: 0.98,
                overlayBottomOpacity: 0.96,
                intensity: 0.18
            )

            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {

                        header
                            .id(scrollTopAnchorID)

                        WaveSeparator()
                            .frame(height: 16)
                            .padding(.top, 4)
                        
                        Text("Comments")
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(.primary.opacity(0.94))
                            .padding(.bottom, 4)

                        if isLoading {
                            loadingCommentsView
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
                        } else if comments.isEmpty {
                            emptyCommentsView
                        } else {
                            commentsList(proxy)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 16)
                }
                .navigationTitle("Post")
                .navigationBarTitleDisplayMode(.inline)
                .legacyBackButtonTitleHidden()
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            bookmarks.toggle(story)
                        } label: {
                            Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                                .symbolRenderingMode(.hierarchical)
                        }
                        .accessibilityLabel(isBookmarked ? "Remove bookmark" : "Add bookmark")
                    }
                }
                .taskOnce {
                    await loadComments()
                }
                .onChange(of: comments) {
                    scrollToAnchorIfNeeded(proxy)
                }
            }
        }
    }

    @ViewBuilder private var header: some View {
        if let url = story.url {
            Link(destination: url) {
                headerCardWithContextMenu
            }
            .buttonStyle(.plain)
        } else {
            headerCardWithContextMenu
        }
    }

    private var headerCard: some View {
        StoryHeaderView(story: story, content: story.content ?? storyContent)
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(cardBackground)
            .overlay(cardStroke)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(alignment: .bottomTrailing) {
                if story.url != nil {
                    readButton
                        .padding(.trailing, 16)
                        .padding(.bottom, 14)
                        .offset(y: -2)
                }
            }
    }

    private var headerCardWithContextMenu: some View {
        headerCard
            .contextMenu {
                StoryContextMenu(story: story)
            }
    }

    @MainActor
    private func loadComments() async {
        guard !isLoading else { return }
        didScrollToAnchor = false
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }

        do {
            let thread = try await api.storyThread(id: story.id)
            storyContent = thread.story.content
            comments = thread.comments
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
            try? await Task.sleep(for: .milliseconds(500))
            withAnimation(.easeInOut(duration: 0.4)) {
                proxy.scrollTo(targetID, anchor: .top)
            }
        }
    }

    private func scrollToTop(_ proxy: ScrollViewProxy) {
        withAnimation(.easeInOut(duration: 0.35)) {
            proxy.scrollTo(scrollTopAnchorID, anchor: .top)
        }
    }

    private func containsComment(withID id: Int, in comments: [Comment]) -> Bool {
        for comment in comments {
            if comment.id == id { return true }
            if containsComment(withID: id, in: comment.children) { return true }
        }
        return false
    }

    @ViewBuilder
    private func commentsList(_ proxy: ScrollViewProxy) -> some View {
        VStack(alignment: .leading, spacing: commentSpacing) {
            ForEach(Array(comments.enumerated()), id: \.element.id) { index, comment in
                if index > 0 {
                    Divider()
                        .padding(.vertical, 2)
                }
                CommentView(
                    comment: comment,
                    depth: 0,
                    highlightID: commentID,
                    storyID: story.id,
                    parentID: nil,
                    proxy: proxy,
                    scrollToTop: { scrollToTop(proxy) }
                )
            }
        }
        .markdownTheme(.minimalGitHub)
    }

    private var emptyCommentsView: some View {
        VStack {
            Spacer(minLength: 0)
            VStack(spacing: 8) {
                Image(systemName: "text.bubble")
                    .font(.system(size: 25, weight: .semibold))
                    .foregroundStyle(.secondary)
                Text("No comments yet")
                    .font(.title2.weight(.semibold))
                Text("Check back later for discussion.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 220)
            }
            .padding(.horizontal, 24)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, minHeight: 360)
    }

    private var meshHue: Double {
        Double(abs(story.id % 360)) / 360.0
    }

    private var meshTint: Color {
        Color(hue: meshHue, saturation: 0.2, brightness: 0.94)
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        Color(.systemBackground).opacity(0.4),
                        meshTint.opacity(0.14)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(.ultraThinMaterial.opacity(0.55))
            )
    }

    private var cardStroke: some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
    }

    private var readButton: some View {
        HStack(spacing: 5) {
            Text("Read")
                .tracking(0.6)
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
        }
        .textCase(.uppercase)
        .font(.caption2.weight(.semibold))
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            Capsule(style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.08),
                            meshTint.opacity(0.18)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    Capsule(style: .continuous)
                        .fill(.ultraThinMaterial.opacity(0.65))
                )
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: 0.8)
        )
        .shadow(color: .black.opacity(0.08), radius: 5, y: 3)
        .foregroundStyle(.primary.opacity(0.72))
    }

    private var loadingCommentsView: some View {
        VStack {
            Spacer(minLength: 0)
            ProgressView("Loading comments...")
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, minHeight: 360)
    }

    private var isBookmarked: Bool {
        bookmarks.isBookmarked(story)
    }
}

private struct WaveSeparator: View {
    var amplitude: CGFloat = 3.5
    var wavelength: CGFloat = 68

    var body: some View {
        Canvas { context, size in
            guard size.width > 0 else { return }
            let midY = size.height / 2
            var path = Path()
            path.move(to: .init(x: 0, y: midY))

            stride(from: 0, through: size.width, by: 1).forEach { x in
                let sine = sin((x / wavelength) * .pi * 2)
                let y = midY + (sine * amplitude)
                path.addLine(to: .init(x: x, y: y))
            }

            let gradient = Gradient(stops: [
                .init(color: .secondary.opacity(0), location: -0.08),
                .init(color: .secondary.opacity(0.32), location: 0.1),
                .init(color: .secondary.opacity(0.45), location: 0.5),
                .init(color: .secondary.opacity(0.32), location: 0.9),
                .init(color: .secondary.opacity(0), location: 1.08)
            ])

            context.stroke(
                path,
                with: .linearGradient(
                    gradient,
                    startPoint: .init(x: 0, y: midY),
                    endPoint: .init(x: size.width, y: midY)
                ),
                style: StrokeStyle(lineWidth: 1.6, lineCap: .round, lineJoin: .round)
            )
        }
    }
}

private struct CommentView: View {
    let comment: Comment
    let depth: Int
    let highlightID: Int?
    let storyID: Int
    let parentID: Int?
    let proxy: ScrollViewProxy
    let scrollToTop: () -> Void
    @State private var isCollapsed = false
    @State private var isHighlightVisible = false
    @State private var hasFlashedHighlight = false

    var body: some View {
        VStack(alignment: .leading, spacing: commentSpacing) {
            commentBlock

            if !isCollapsed, !comment.children.isEmpty {
                VStack(alignment: .leading, spacing: commentSpacing) {
                    ForEach(comment.children) { child in
                        CommentView(
                            comment: child,
                            depth: min(10, depth + 1),
                            highlightID: highlightID,
                            storyID: storyID,
                            parentID: comment.id,
                            proxy: proxy,
                            scrollToTop: scrollToTop
                        )
                    }
                }
            }
        }
        .id(comment.id)
        .padding(.leading, depth == 0 ? 0 : 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .onTapGesture {
            toggleCollapse()
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
            styledAuthor(author)
            + separatorText
            + relativeTimeText(time)
        case let (author?, nil):
            styledAuthor(author)
        case let (nil, time?):
            relativeTimeText(time)
        default:
            nil
        }
    }

    private func styledAuthor(_ author: String) -> Text {
        Text(author)
            .foregroundStyle(.secondary)
    }

    private var separatorText: Text {
        Text(" \u{00b7} ")
            .foregroundStyle(.tertiary)
    }

    private func relativeTimeText(_ date: Date) -> Text {
        Text(date, format: .relative(presentation: .numeric, unitsStyle: .narrow))
            .foregroundStyle(.tertiary)
    }

    private var timestamp: Date? {
        comment.time.map { Date(timeIntervalSince1970: $0) }
    }

    private var isHighlighted: Bool {
        highlightID == comment.id
    }

    private var copyableText: String? {
        guard let text = comment.content?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty else { return nil }
        return text
    }

    private var commentURLString: String {
        "https://news.ycombinator.com/item?id=\(storyID)#\(comment.id)"
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
                        .font(.footnote.weight(.semibold))
                }
            }

            if !isCollapsed, let content = comment.content {
                Markdown(content)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .markdownTextStyle {
                        ForegroundColor(.primary.opacity(0.85))
                    }
            }
        }
        .padding(bgPadding)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(isHighlightVisible ? Color.yellow.opacity(highlightOpacity) : .clear)
        )
        .animation(.easeInOut(duration: 0.3), value: isHighlightVisible)
        .padding(.top, -bgPadding.top)
        .padding(.leading, -bgPadding.leading)
        .padding(.bottom, -bgPadding.bottom)
        .padding(.trailing, -bgPadding.trailing)
        .contextMenu {
            Button {
                copyText()
            } label: {
                Label("Copy text", systemImage: "doc.on.doc")
            }
            .disabled(copyableText == nil)

            if let parentID {
                Button {
                    scrollTo(parentID)
                } label: {
                    Label("Parent", systemImage: "arrow.uturn.up")
                }
            }

            Button {
                scrollToTop()
            } label: {
                Label("Context", systemImage: "arrow.up.to.line")
            }

            Button {
                copyCommentLink()
            } label: {
                Label("Copy link", systemImage: "link")
            }
        }
    }

    private func copyText() {
        guard let copyableText else { return }
        UIPasteboard.general.string = copyableText
    }

    private func copyCommentLink() {
        UIPasteboard.general.string = commentURLString
    }

    private func scrollTo(_ id: Int) {
        withAnimation(.easeInOut(duration: 0.35)) {
            proxy.scrollTo(id, anchor: .top)
        }
    }

    private func toggleCollapse() {
        withAnimation(.easeInOut(duration: 0.25)) {
            isCollapsed.toggle()
        }
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
