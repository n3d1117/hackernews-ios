import SwiftUI

private let scrollTopAnchorID = "postDetailTopAnchor"

// Displays a story with its comment thread and deep-link scrolling.
struct PostDetailView: View {
    @Environment(\.bookmarksStore) private var bookmarks
    @Environment(\.seenStoriesStore) private var seenStories

    @State private var viewModel: PostDetailViewModel
    @State private var didScrollToAnchor = false

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
                            meshTint: meshTint
                        )
                        .id(scrollTopAnchorID)

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
                    .padding(.horizontal)
                    .padding(.top, 16)
                }
                .navigationTitle("Post")
                .navigationBarTitleDisplayMode(.inline)
                .legacyBackButtonTitleHidden()
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        bookmarkButton
                    }
                    if #available(iOS 26.0, *) {
                        ToolbarSpacer(.fixed, placement: .topBarTrailing)
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        contextMenuButton
                    }
                }
                .taskOnce {
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
}
