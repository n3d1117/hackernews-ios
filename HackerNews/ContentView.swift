//
//  ContentView.swift
//  HackerNews
//
//  Created by ned on 17/10/25.
//

import SwiftUI

struct ContentView: View {
    @Environment(\.cardNamespace) private var cardNamespace
    @Environment(\.openURL) private var openURL
    
    @State private var feed = StoryFeedModel()
    @State private var pasteError: String?

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
                content
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
            }
            .refreshable {
                await feed.refresh()
            }
            if feed.isLoading && feed.stories.isEmpty {
                ProgressView("Loading stories...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            }
            if let errorMessage = feed.errorMessage, feed.stories.isEmpty {
                errorState(message: errorMessage)
            }
        }
        .navigationTitle("Hacker News")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
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
            await feed.loadInitial()
        }
    }

    private var topBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Top stories")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
    }

    @ViewBuilder
    private var content: some View {
        LazyVStack(spacing: 14) {
            ForEach(feed.stories) { story in
                StoryCard(story: story, namespace: cardNamespace)
                    .onAppear {
                        Task {
                            await feed.loadMoreIfNeeded(for: story)
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
        feed.isLoading && !feed.stories.isEmpty
    }

    @ViewBuilder
    private func errorState(message: String) -> some View {
        VStack(spacing: 12) {
            Text("Could not load stories")
                .font(.title2.weight(.semibold))
            Text(message)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button {
                Task { await feed.refresh() }
            } label: {
                retryButton
            }
            .buttonStyle(.plain)
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }

    private var retryButton: some View {
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

    private func pasteLink() {
        guard let clipboard = UIPasteboard.general.string?.trimmingCharacters(in: .whitespacesAndNewlines), !clipboard.isEmpty else {
            pasteError = "Clipboard is empty."
            return
        }

        guard let url = normalizedURL(from: clipboard) else {
            pasteError = "Paste a valid Hacker News link."
            return
        }

        openURL(url)
    }

    private func normalizedURL(from string: String) -> URL? {
        if let id = Int(string) {
            return URL(string: "hn://\(id)")
        }
        
        if let url = URL(string: string), HackerNewsLinkParser.storyLink(from: url) != nil {
            return url
        }
        
        if !string.contains("://"),
           let url = URL(string: "https://\(string)"),
           HackerNewsLinkParser.storyLink(from: url) != nil {
            return url
        }
        
        return nil
    }
}

struct StoryCard: View {
    @Environment(\.openURL) private var openURL
    @Environment(\.bookmarksStore) private var bookmarks
    let story: Story
    var namespace: Namespace.ID?
    var accentColor: Color = .orange
    var useZoom = true

    var body: some View {
        NavigationLink(value: AppRoute.post(story, useZoom: useZoom)) {
            header
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .foregroundStyle(.primary)
                .background(cardBackground)
                .overlay(cardStroke)
        }
        .buttonStyle(.plain)
        .contextMenu {
            StoryContextMenu(story: story)
        }
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        Color(.systemBackground).opacity(0.4),
                        accentColor.opacity(0.08)
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

    @ViewBuilder
    private var header: some View {
        if let namespace {
            StoryHeaderView(story: story, showContent: false)
                .matchedTransitionSource(id: story.id, in: namespace)
        } else {
            StoryHeaderView(story: story, showContent: false)
        }
    }
}

#Preview {
    ContentView()
}
