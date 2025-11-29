import SwiftUI
import MarkdownUI

struct StoryHeaderView: View {
    let story: Story
    var content: String?
    var showContent = true

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                faviconView

                if let domainText {
                    Text(domainText.uppercased())
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }

            Text(story.title)
                .font(.title3.weight(.semibold))
                .multilineTextAlignment(.leading)

            if showContent, let content = trimmedContent {
                Markdown(content)
                    .textSelection(.enabled)
                    .markdownTheme(.minimalGitHub)
            }

            if let authorTimeText {
                authorTimeText
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary.opacity(0.92))
            }

            if let statsText {
                statsText
                    .font(.footnote)
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var faviconView: some View {
        AsyncImage(url: faviconURL, transaction: .init(animation: .easeInOut(duration: 0.12))) { phase in
            switch phase {
            case let .success(image):
                image
                    .resizable()
                    .scaledToFill()
            default:
                Image(systemName: "globe")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary.opacity(0.78))
            }
        }
        .frame(width: 14, height: 14)
        .clipShape(Circle())
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
            story.commentsCount.map { Text(quantified($0, singular: "comment")) }
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
}
