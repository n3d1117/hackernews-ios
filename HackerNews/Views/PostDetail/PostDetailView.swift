import SwiftUI
import MarkdownUI

private let scrollTopAnchorID = "postDetailTopAnchor"

// Displays a story with its comment thread and deep-link scrolling.
struct PostDetailView: View {
    @Environment(\.bookmarksStore) private var bookmarks
    @Environment(\.seenStoriesStore) private var seenStories
    @Environment(\.summaryStore) private var summaries
    @Environment(\.summaryService) private var summaryService

    @State private var viewModel: PostDetailViewModel
    @State private var didScrollToAnchor = false
    @State private var didRequestSummary = false

    init(story: Story, commentID: Int?, service: any StoryThreadService) {
        _viewModel = State(initialValue: PostDetailViewModel(story: story, commentID: commentID, service: service))
    }

    var body: some View {
        ZStack {
            SoftMeshBackground(
                seed: viewModel.story.id,
                baseHue: meshHue,
                overlayTopOpacity: 0.96,
                overlayBottomOpacity: 0.9,
                intensity: 0.22
            )

            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        PostHeaderCard(
                            story: viewModel.story,
                            content: viewModel.story.content ?? viewModel.storyContent,
                            meshTint: meshTint,
                            showSummarize: canSummarize && viewModel.summary == nil,
                            isSummarizing: viewModel.isSummarizing,
                            onSummarize: canSummarize ? { startSummarize() } : nil
                        )
                        .id(scrollTopAnchorID)

                        if viewModel.isSummarizing || viewModel.summary != nil {
                            summaryCard
                        }

                        WaveSeparator()
                            .frame(height: 16)
                            .padding(.top, 4)

                        Text("Comments")
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(.primary.opacity(0.94))
                            .padding(.bottom, 4)

                        CommentSectionView(
                            viewModel: viewModel,
                            storyID: viewModel.story.id,
                            highlightID: viewModel.commentID,
                            proxy: proxy,
                            scrollToTop: { scrollToTop(proxy) }
                        )
                    }
                    .animation(.spring(response: 0.28, dampingFraction: 0.88), value: shouldAnimateSummary)
                    .padding(.horizontal)
                    .padding(.top, 16)
                }
                .navigationTitle("Post")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        bookmarkButton
                    }
                    ToolbarSpacer(.fixed, placement: .topBarTrailing)
                    ToolbarItem(placement: .topBarTrailing) {
                        contextMenuButton
                    }
                }
                .taskOnce {
                    await viewModel.loadCachedSummary(from: summaries)
                    await seenStories.markSeen(viewModel.story)
                    await viewModel.loadComments()
                }
                .onChange(of: viewModel.comments) {
                    scrollToAnchorIfNeeded(proxy)
                }
                .onChange(of: viewModel.isLoading) {
                    if viewModel.isLoading {
                        didScrollToAnchor = false
                    }
                }
            }
        }
    }

    // Scrolls to the highlighted comment when it becomes available.
    private func scrollToAnchorIfNeeded(_ proxy: ScrollViewProxy) {
        guard !didScrollToAnchor, let targetID = viewModel.commentID else { return }
        guard viewModel.containsComment(withID: targetID) else { return }
        didScrollToAnchor = true
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(500))
            withAnimation(.easeInOut(duration: 0.4)) {
                proxy.scrollTo(targetID, anchor: .top)
            }
        }
    }

    // Scrolls back to the post header.
    private func scrollToTop(_ proxy: ScrollViewProxy) {
        withAnimation(.easeInOut(duration: 0.35)) {
            proxy.scrollTo(scrollTopAnchorID, anchor: .top)
        }
    }

    private var meshTint: Color {
        Color(hue: meshHue, saturation: 0.25, brightness: 0.94)
    }

    private var meshHue: Double {
        Double(abs(viewModel.story.id % 360)) / 360.0
    }

    private var bookmarkButton: some View {
        Button {
            bookmarks.toggleAsync(viewModel.story)
        } label: {
            Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                .symbolRenderingMode(.hierarchical)
        }
        .accessibilityLabel(isBookmarked ? "Remove bookmark" : "Add bookmark")
    }

    private var contextMenuButton: some View {
        Menu {
            StoryContextMenu(story: viewModel.story, includeBookmark: false)
        } label: {
            Image(systemName: "ellipsis")
                .symbolRenderingMode(.hierarchical)
        }
        .accessibilityLabel("More actions")
    }

    private var isBookmarked: Bool {
        bookmarks.isBookmarked(viewModel.story)
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "apple.intelligence")
                    .symbolRenderingMode(.multicolor)
                Text("AI-generated summary")
                    .textCase(.uppercase)
                    .font(.caption2.weight(.bold))
                Spacer()
            }

            if let summary = viewModel.summary {
                Text(summary)
                    .font(.callout)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundStyle(.primary.opacity(0.9))
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        ProgressView()
                            .controlSize(.mini)
                        Text("Generating...")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            Color(.secondarySystemBackground)
                .opacity(0.85)
                .cornerRadius(16)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    LinearGradient(
                        colors: [.purple.opacity(0.8), .purple.opacity(0.4)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        )
        .shadow(color: .purple.opacity(0.2), radius: 10, x: 0, y: 6)
        .cornerRadius(16)
        .contentShape(Rectangle())
        .transition(.move(edge: .top).combined(with: .opacity))
        .animation(.spring(response: 0.28, dampingFraction: 0.88), value: viewModel.isSummarizing || viewModel.summary != nil)
    }

    private var canSummarize: Bool {
        guard viewModel.story.url != nil else { return false }
        guard summaryService.isAvailable else { return false }
        return true
    }

    private var shouldAnimateSummary: Bool {
        didRequestSummary && (viewModel.isSummarizing || viewModel.summary != nil)
    }

    private func startSummarize() {
        Task {
            didRequestSummary = true
            await viewModel.summarize(using: summaries, service: summaryService)
        }
    }
}
