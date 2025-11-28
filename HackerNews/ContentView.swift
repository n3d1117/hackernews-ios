//
//  ContentView.swift
//  HackerNews
//
//  Created by ned on 17/10/25.
//

import SwiftUI
import Routing

struct ContentView: View {
    @Environment(\.router) private var router
    
    private let api = HackerNewsAPI()
    
    @State private var stories: [Story] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    @Namespace private var namespace

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
        }
        .tint(.orange)
        .navigationTitle("Hacker News")
        .navigationBarTitleDisplayMode(.inline)
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

    private var content: some View {
        Group {
            if isLoading && stories.isEmpty {
                VStack(spacing: 12) {
                    ProgressView("Loading stories...")
                        .frame(maxWidth: .infinity)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            } else if let errorMessage, stories.isEmpty {
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
                LazyVStack(spacing: 14) {
                    ForEach(stories) { story in
                        StoryCard(story: story, namespace: namespace)
                    }
                }
            }
        }
    }

    @MainActor
    private func loadStories() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            stories = try await api.frontPageStories()
            errorMessage = nil
        } catch {
            stories = []
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    private func refresh() async {
        await loadStories()
    }
}

private struct StoryCard: View {
    let story: Story
    let namespace: Namespace.ID

    var body: some View {
        NavigationLink {
            AppRoute.post(story)
                .destination
                .navigationTransition(.zoom(sourceID: story.id, in: namespace))
        } label: {
            StoryHeaderView(story: story, showContent: false)
                .matchedTransitionSource(id: story.id, in: namespace)
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
}

#Preview {
    ContentView()
}
