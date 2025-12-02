import Observation
import SwiftUI
import UIKit
struct HomeFeedView: View {
    @Environment(\.cardNamespace) private var cardNamespace
    @Environment(\.openURL) private var openURL

    @State private var viewModel: StoryFeedViewModel
    @State private var pasteError: String?

    init(service: any FrontPageService) {
        _viewModel = State(initialValue: StoryFeedViewModel(api: service))
    }

    var body: some View {
        ZStack {
            SoftMeshBackground(
                seed: 42,
                baseHue: 0.08,
                overlayTopOpacity: 0.98,
                overlayBottomOpacity: 0.92,
                intensity: 0.22
            )
            ScrollView {
                FeedListView(viewModel: viewModel, namespace: cardNamespace)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
            }
            .refreshable {
                await viewModel.refresh(isUserInitiated: true)
            }
            if viewModel.isLoading && viewModel.stories.isEmpty {
                ProgressView("Loading stories...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            }
            if let errorMessage = viewModel.errorMessage, viewModel.stories.isEmpty {
                FeedErrorView(message: errorMessage) {
                    Task { await viewModel.refresh() }
                }
            }
        }
        .navigationTitle("Hacker News")
        .navigationSubtitleIfAvailable(viewModel.category.subtitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                CategorySelector(selection: categoryBinding)
            }
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    NavigationLink(value: AppRoute.bookmarks) {
                        Label("Bookmarks", systemImage: "bookmark")
                    }
                    Button {
                        pasteLink()
                    } label: {
                        Label("Paste link", systemImage: "doc.on.clipboard")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                }
            }
        }
        .alert("Cannot open link", isPresented: Binding(
            get: { pasteError != nil },
            set: { if !$0 { pasteError = nil } }
        )) {
            Button("OK", role: .cancel) { pasteError = nil }
        } message: {
            if let pasteError {
                Text(pasteError)
            }
        }
        .taskOnce {
            await viewModel.loadInitial()
        }
    }

    private var categoryBinding: Binding<StoryFeedCategory> {
        Binding(
            get: { viewModel.category },
            set: { category in
                Task { await viewModel.selectCategory(category) }
            }
        )
    }

    private func pasteLink() {
        guard let clipboard = UIPasteboard.general.string?.trimmingCharacters(in: .whitespacesAndNewlines), !clipboard.isEmpty else {
            pasteError = "Clipboard is empty."
            return
        }

        guard let url = HackerNewsLinkParser.normalizedURL(from: clipboard) else {
            pasteError = "Paste a valid Hacker News link."
            return
        }

        openURL(url)
    }
}

struct StoryCard: View, Equatable {
    @Environment(\.seenStoriesStore) private var seenStories
    let story: Story
    var namespace: Namespace.ID?
    var accentColor: Color = .orange
    var useZoom = true
    var showCommentCount = true

    var body: some View {
        NavigationLink(value: AppRoute.post(story, useZoom: useZoom)) {
            header
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .foregroundStyle(.primary)
                .softCardStyle(accent: accentColor)
        }
        .buttonStyle(.plain)
        .contextMenu {
            StoryContextMenu(story: story)
        }
    }

    @ViewBuilder
    private var header: some View {
        if let namespace {
            StoryHeaderView(story: story, showContent: false, showCommentCount: showCommentCount, isSeen: isSeen)
                .matchedTransitionSource(id: story.id, in: namespace)
        } else {
            StoryHeaderView(story: story, showContent: false, showCommentCount: showCommentCount, isSeen: isSeen)
        }
    }

    private var isSeen: Bool {
        seenStories.isSeen(story)
    }

    static func == (lhs: StoryCard, rhs: StoryCard) -> Bool {
        lhs.story == rhs.story
        && lhs.accentColor == rhs.accentColor
        && lhs.useZoom == rhs.useZoom
        && lhs.showCommentCount == rhs.showCommentCount
    }
}
