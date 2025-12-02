import SwiftUI
import MarkdownUI
import UIKit

private let highlightOpacity: CGFloat = 0.14

// Renders a single comment and its nested children.
struct CommentNodeView: View {
    let comment: Comment
    let depth: Int
    let highlightID: Int?
    let storyID: Int
    let parentID: Int?
    let proxy: ScrollViewProxy
    let scrollToTop: () -> Void
    @State private var isCollapsed = false
    @State private var isHighlightVisible = false
    @State private var hasFlashedHighlight = false

    var body: some View {
        VStack(alignment: .leading, spacing: commentSpacing) {
            commentBlock

            if !isCollapsed, !comment.children.isEmpty {
                VStack(alignment: .leading, spacing: commentSpacing) {
                    ForEach(comment.children) { child in
                        CommentNodeView(
                            comment: child,
                            depth: min(10, depth + 1),
                            highlightID: highlightID,
                            storyID: storyID,
                            parentID: comment.id,
                            proxy: proxy,
                            scrollToTop: scrollToTop
                        )
                    }
                }
            }
        }
        .id(comment.id)
        .padding(.leading, depth == 0 ? 0 : 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .onTapGesture {
            toggleCollapse()
        }
        .onAppear {
            flashHighlightIfNeeded()
        }
        .onChange(of: isHighlighted) { _, _ in
            flashHighlightIfNeeded()
        }
    }

    private var metaText: Text? {
        switch (comment.author, timestamp) {
        case let (author?, time?):
            styledAuthor(author) + separatorText + relativeTimeText(time)
        case let (author?, nil):
            styledAuthor(author)
        case let (nil, time?):
            relativeTimeText(time)
        default:
            nil
        }
    }

    private func styledAuthor(_ author: String) -> Text {
        Text(author)
            .foregroundStyle(.secondary)
    }

    private var separatorText: Text {
        Text(" \u{00b7} ")
            .foregroundStyle(.tertiary)
    }

    private func relativeTimeText(_ date: Date) -> Text {
        Text(date, format: .relative(presentation: .numeric, unitsStyle: .narrow))
            .foregroundStyle(.tertiary)
    }

    private var timestamp: Date? {
        comment.time.map { Date(timeIntervalSince1970: $0) }
    }

    private var isHighlighted: Bool {
        highlightID == comment.id
    }

    private var copyableText: String? {
        guard let text = comment.content?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty else { return nil }
        return text
    }

    private var commentURLString: String {
        "https://news.ycombinator.com/item?id=\(storyID)#\(comment.id)"
    }

    private var commentBlock: some View {
        let bgPadding = EdgeInsets(top: 8, leading: 10, bottom: 8, trailing: 10)

        return VStack(alignment: .leading, spacing: 8) {
            if let metaText {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.right")
                        .imageScale(.small)
                        .foregroundStyle(.secondary)
                        .frame(width: 10, alignment: .center)
                        .rotationEffect(.degrees(isCollapsed ? 0 : 90))

                    metaText
                        .font(.footnote.weight(.semibold))
                }
            }

            if !isCollapsed, let content = comment.content {
                Markdown(content)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .markdownTextStyle {
                        ForegroundColor(.primary.opacity(0.85))
                    }
            }
        }
        .padding(bgPadding)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(isHighlightVisible ? Color.yellow.opacity(highlightOpacity) : .clear)
        )
        .animation(.easeInOut(duration: 0.3), value: isHighlightVisible)
        .padding(.top, -bgPadding.top)
        .padding(.leading, -bgPadding.leading)
        .padding(.bottom, -bgPadding.bottom)
        .padding(.trailing, -bgPadding.trailing)
        .contextMenu {
            Button {
                copyText()
            } label: {
                Label("Copy text", systemImage: "doc.on.doc")
            }
            .disabled(copyableText == nil)

            if let parentID {
                Button {
                    scrollTo(parentID)
                } label: {
                    Label("Parent", systemImage: "arrow.uturn.up")
                }
            }

            Button {
                scrollToTop()
            } label: {
                Label("Context", systemImage: "arrow.up.to.line")
            }

            Button {
                copyCommentLink()
            } label: {
                Label("Copy link", systemImage: "link")
            }
        }
    }

    // Copies the comment body to the clipboard.
    private func copyText() {
        guard let copyableText else { return }
        UIPasteboard.general.string = copyableText
    }

    // Copies the canonical HN link for the comment.
    private func copyCommentLink() {
        UIPasteboard.general.string = commentURLString
    }

    // Scrolls to a specific comment ID.
    private func scrollTo(_ id: Int) {
        withAnimation(.easeInOut(duration: 0.35)) {
            proxy.scrollTo(id, anchor: .top)
        }
    }

    // Toggles the expanded/collapsed state.
    private func toggleCollapse() {
        withAnimation(.easeInOut(duration: 0.25)) {
            isCollapsed.toggle()
        }
    }

    // Briefly flashes a highlight for linked comments.
    private func flashHighlightIfNeeded() {
        guard isHighlighted, !hasFlashedHighlight else { return }
        hasFlashedHighlight = true
        isHighlightVisible = true
        Task {
            try? await Task.sleep(for: .milliseconds(2000))
            await MainActor.run {
                isHighlightVisible = false
            }
        }
    }
}
