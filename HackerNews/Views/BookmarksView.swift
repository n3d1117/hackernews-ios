import SwiftUI

struct BookmarksView: View {
    @Environment(\.cardNamespace) private var cardNamespace
    @Environment(\.bookmarksStore) private var bookmarks

    var body: some View {
        ZStack {
            SoftMeshBackground(
                seed: 7,
                baseHue: 0.58,
                overlayTopOpacity: 0.98,
                overlayBottomOpacity: 0.92,
                intensity: 0.22
            )
            ScrollView {
                content
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
            }
            if bookmarks.stories.isEmpty {
                emptyState
            }
        }
        .navigationTitle("Bookmarks")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private var content: some View {
        VStack(spacing: 14) {
            ForEach(bookmarks.stories) { story in
                StoryCard(story: story, namespace: cardNamespace, accentColor: .blue)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "bookmark")
                .font(.system(size: 25, weight: .semibold))
                .foregroundStyle(.secondary)
            Text("No bookmarks yet")
                .font(.title2.weight(.semibold))
            Text("Save posts from their detail page to keep them here.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 200)
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }
}
