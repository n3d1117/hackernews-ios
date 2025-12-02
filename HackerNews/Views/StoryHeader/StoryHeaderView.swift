import SwiftUI
import MarkdownUI

// Shows a story title, metadata, and optional content.
struct StoryHeaderView: View {
    let story: Story
    var content: String?
    var showContent = true
    var showImage = false
    var showCommentCount = true
    var isSeen = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if showImage, let imageURL = story.imageURL {
                headerImage(url: imageURL)
            }

            StoryHeaderMeta(domainText: domainText, faviconURL: faviconURL)

            Text(story.title)
                .font(.title3.weight(.semibold))
                .foregroundStyle(isSeen ? .secondary : .primary)
                .multilineTextAlignment(.leading)

            if showContent, let content = trimmedContent {
                Markdown(content)
                    .textSelection(.enabled)
                    .markdownTheme(.minimalGitHub)
            }

            StoryHeaderAuthorTime(text: authorTimeText)

            if let statsText {
                statsText
                    .font(.footnote)
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var domainText: String? {
        story.domain ?? story.url?.host ?? "news.ycombinator.com"
    }

    private var faviconURL: URL? {
        guard let host = domainText?
            .replacingOccurrences(of: "https://", with: "")
            .replacingOccurrences(of: "http://", with: "")
            .split(separator: "/")
            .first
            .map(String.init) else { return nil }

        return URL(string: "https://icons.duckduckgo.com/ip3/\(host).ico")
    }

    private var authorTimeText: Text? {
        dotSeparated([
            story.author.map(Text.init),
            storyDate.map { Text($0, format: .relative(presentation: .numeric, unitsStyle: .narrow)) }
        ].compactMap { $0 })
    }

    private var statsText: Text? {
        dotSeparated([
            story.points.map { Text(quantified($0, singular: "point")) },
            showCommentCount ? story.commentsCount.map { Text(quantified($0, singular: "comment")) } : nil
        ].compactMap { $0 })
    }

    private var storyDate: Date? {
        story.time.map { Date(timeIntervalSince1970: $0) }
    }

    private var trimmedContent: String? {
        guard let content else { return nil }
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private func dotSeparated(_ parts: [Text]) -> Text? {
        guard var text = parts.first else { return nil }
        for part in parts.dropFirst() {
            text = text + Text(" \u{00b7} ") + part
        }
        return text
    }

    private func quantified(_ value: Int, singular: String, plural: String? = nil) -> String {
        let pluralized = plural ?? singular + "s"
        return "\(value) \(value == 1 ? singular : pluralized)"
    }

    private func headerImage(url: URL) -> some View {
        AsyncImage(url: url, transaction: .init(animation: .easeInOut(duration: 0.18))) { phase in
            switch phase {
            case let .success(image):
                image
                    .resizable()
                    .scaledToFill()
            default:
                LinearGradient(
                    colors: [
                        .secondary.opacity(0.14),
                        .secondary.opacity(0.08)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 190)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        }
    }
}
