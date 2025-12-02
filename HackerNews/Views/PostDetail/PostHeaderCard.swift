import SwiftUI
import MarkdownUI

// Displays the story header with optional content and read button.
struct PostHeaderCard: View {
    let story: Story
    let content: String?
    let meshTint: Color

    var body: some View {
        headerLink {
            StoryHeaderView(story: story, content: content)
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .softCardStyle(accent: meshTint)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(alignment: .bottomTrailing) {
                    if story.url != nil {
                        readButton
                            .padding(.trailing, 16)
                            .padding(.bottom, 14)
                            .offset(y: -2)
                    }
                }
        }
    }

    @ViewBuilder
    private func headerLink<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        if let url = story.url {
            Link(destination: url, label: content)
                .buttonStyle(.plain)
        } else {
            content()
        }
    }

    private var readButton: some View {
        HStack(spacing: 5) {
            Text("Read")
                .tracking(0.6)
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
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
                            meshTint.opacity(0.18)
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
