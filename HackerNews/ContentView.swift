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
                    Button {
                        router.navigate(to: .post(story))
                    } label: {
                        StoryRow(story: story)
                    }
                }
                .listStyle(.plain)
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
        VStack(alignment: .leading, spacing: 4) {
            Text(story.title)
                .font(.headline)
            if let url = story.url {
                Link(destination: url) {
                    Text(url.host ?? url.absoluteString)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    ContentView()
}
