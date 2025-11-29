//
//  ContentView.swift
//  HackerNews
//
//  Created by ned on 17/10/25.
//

import SwiftUI
import UIKit

struct ContentView: View {
    @Environment(\.cardNamespace) private var cardNamespace
    @Environment(\.openURL) private var openURL

    private let api = HackerNewsAPI()
    
    @State private var stories: [Story] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
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
                await refresh()
            }
            if isLoading && stories.isEmpty {
                ProgressView("Loading stories...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            }
        }
        .navigationTitle("Hacker News")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
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
            await loadStories()
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
        if let errorMessage, stories.isEmpty {
            VStack(spacing: 12) {
                Text("Could not load stories")
                    .font(.headline)
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                Button("Retry") {
                    Task { await loadStories() }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        } else {
            VStack(spacing: 14) {
                ForEach(stories) { story in
                    StoryCard(story: story, namespace: cardNamespace)
                }
            }
        }
    }

    @MainActor
    private func loadStories() async {
        guard !isLoading else { return }
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }

        do {
            stories = try await api.frontPageStories()
        } catch {
            stories = []
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    private func refresh() async {
        await loadStories()
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

        _ = openURL(url)
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

private struct StoryCard: View {
    let story: Story
    let namespace: Namespace.ID?

    var body: some View {
        NavigationLink(value: AppRoute.post(story, useZoom: true)) {
            header
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .foregroundStyle(.primary)
                .background(cardBackground)
                .overlay(cardStroke)
        }
        .buttonStyle(.plain)
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        Color(.systemBackground).opacity(0.4),
                        Color.orange.opacity(0.08)
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
