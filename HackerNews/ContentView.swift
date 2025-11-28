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
        Group {
            if isLoading {
                ProgressView("Loading stories...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let errorMessage {
                VStack(spacing: 12) {
                    Text("Could not load stories")
                        .font(.headline)
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    Button("Retry") {
                        Task {
                            await loadStories()
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(stories) { story in
                    NavigationLink {
                        AppRoute.post(story)
                            .destination
                            .navigationTransition(.zoom(sourceID: story.id, in: namespace))
                    } label: {
                        StoryRow(story: story)
                            .matchedTransitionSource(id: story.id, in: namespace)
                    }
                }
            }
        }
        .navigationTitle("Hacker News")
        .taskOnce {
            await loadStories()
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
}

private struct StoryRow: View {
    let story: Story

    var body: some View {
        StoryHeaderView(story: story, showContent: false)
            .padding(.vertical, 5)
    }
}

#Preview {
    ContentView()
}
