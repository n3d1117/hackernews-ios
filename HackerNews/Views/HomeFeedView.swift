import Observation
import SwiftUI
import UIKit

// Shows the main Hacker News feed with categories and pagination.
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
                await viewModel.refresh()
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
        .navigationSubtitleIfAvailable(categorySubtitle)
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

    private var categorySubtitle: String {
        switch viewModel.category {
        case .top:
            "Top Stories"
        case .new:
            "New Stories"
        case .show:
            "Show HN"
        case .ask:
            "Ask HN"
        case .jobs:
            "Jobs"
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

    // Attempts to open a link from the clipboard.
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

// Feed content list with infinite scroll trigger.
private struct FeedListView: View {
    @Bindable var viewModel: StoryFeedViewModel
    let namespace: Namespace.ID?

    var body: some View {
        LazyVStack(spacing: 14) {
            ForEach(viewModel.stories) { story in
                StoryCard(
                    story: story,
                    namespace: namespace,
                    showCommentCount: viewModel.category != .jobs
                )
                .onAppear {
                    Task {
                        await viewModel.loadMoreIfNeeded(for: story)
                    }
                }
            }
            if isPaging {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
        }
    }

    private var isPaging: Bool {
        viewModel.isLoading && !viewModel.stories.isEmpty
    }
}

// Error placeholder with retry action.
private struct FeedErrorView: View {
    let message: String
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Text("Could not load stories")
                .font(.title2.weight(.semibold))
            Text(message)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button(action: onRetry) {
                RetryButtonView()
            }
            .buttonStyle(.plain)
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }
}

private struct RetryButtonView: View {
    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: "arrow.clockwise")
                .font(.system(size: 11, weight: .semibold))
            Text("Retry")
                .tracking(0.6)
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
                            Color.orange.opacity(0.18)
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
}

private extension View {
    @ViewBuilder
    func navigationSubtitleIfAvailable(_ subtitle: String) -> some View {
        if #available(iOS 26, *) {
            navigationSubtitle(subtitle)
        } else {
            self
        }
    }
}

// Menu for selecting a feed category.
private struct CategorySelector: View {
    let selection: Binding<StoryFeedCategory>

    var body: some View {
        Menu {
            Picker("Feed", selection: selection) {
                ForEach(StoryFeedCategory.allCases) { category in
                    Label(category.title, systemImage: category.icon)
                        .tag(category)
                }
            }
        } label: {
            Image(systemName: "line.3.horizontal.decrease")
                .font(.headline.weight(.semibold))
        }
    }
}

// Card summarizing a story in the feed.
struct StoryCard: View {
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
}
