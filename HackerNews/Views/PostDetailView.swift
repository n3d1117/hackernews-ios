import SwiftUI
import MarkdownUI

private let commentSpacing: CGFloat = 18
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
                            WaveSeparator()
                                .frame(height: 16)
                                .padding(.top, 4)
                            
                            Text("Comments")
                                .font(.title2.weight(.semibold))
                                .foregroundStyle(.primary.opacity(0.94))
                                .padding(.bottom, 4)
                            
                            VStack(alignment: .leading, spacing: commentSpacing) {
                                ForEach(Array(comments.enumerated()), id: \.element.id) { index, comment in
                                    if index > 0 {
                                        Divider()
                                            .padding(.vertical, 2)
                                    }
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
    }

    @ViewBuilder private var header: some View {
        if let url = story.url {
            Link(destination: url) {
                headerCard
            }
            .buttonStyle(.plain)
        } else {
            headerCard
        }
    }

    private var headerCard: some View {
        StoryHeaderView(story: story, content: story.content ?? storyContent)
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(cardBackground)
            .overlay(cardStroke)
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
        .padding(.leading, depth == 0 ? 0 : 14)
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
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.secondary.opacity(0.9))
                }
            }

            if !isCollapsed, let content = comment.content {
                Markdown(content)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .markdownTextStyle {
                        ForegroundColor(.primary.opacity(0.85))
                    }
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
