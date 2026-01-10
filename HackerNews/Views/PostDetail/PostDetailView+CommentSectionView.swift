import Observation
import SwiftUI
import MarkdownUI

extension PostDetailView {
    static let commentSpacing: CGFloat = 18

    struct CommentSectionView: View {
        @Bindable var viewModel: PostDetailViewModel
        let storyID: Int
        let highlightID: Int?
        let proxy: ScrollViewProxy
        let scrollToTop: () -> Void

        var body: some View {
            Group {
                switch state {
                case .loading:
                    loadingCommentsView
                case let .error(message):
                    errorView(message: message)
                case .empty:
                    emptyCommentsView
                case .loaded:
                    commentsList
                }
            }
            .markdownTheme(.minimalGitHub)
        }

        private var state: CommentState {
            if viewModel.isLoading {
                return .loading
            }
            if let errorMessage = viewModel.errorMessage {
                return .error(errorMessage)
            }
            if viewModel.comments.isEmpty {
                return .empty
            }
            return .loaded
        }

        private var commentsList: some View {
            LazyVStack(alignment: .leading, spacing: PostDetailView.commentSpacing) {
                ForEach(Array(viewModel.comments.enumerated()), id: \.element.id) { index, comment in
                    if index > 0 {
                        Divider()
                            .padding(.vertical, 2)
                    }
                    CommentNodeView(
                        comment: comment,
                        depth: 0,
                        highlightID: highlightID,
                        storyID: storyID,
                        parentID: nil,
                        proxy: proxy,
                        scrollToTop: scrollToTop
                    )
                }
            }
        }

        private var emptyCommentsView: some View {
            VStack {
                Spacer(minLength: 0)
                VStack(spacing: 8) {
                    Image(systemName: "text.bubble")
                        .font(.system(size: 25, weight: .semibold))
                        .foregroundStyle(.secondary)
                    Text("No comments yet")
                        .font(.title2.weight(.semibold))
                    Text("Check back later for discussion.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 220)
                }
                .padding(.horizontal, 24)
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, minHeight: 360)
        }

        private var loadingCommentsView: some View {
            VStack {
                Spacer(minLength: 0)
                ProgressView("Loading comments...")
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, minHeight: 360)
        }

        private func errorView(message: String) -> some View {
            VStack(spacing: 8) {
                Text("Could not load comments")
                    .font(.headline)
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                Button("Retry") {
                    Task { await viewModel.loadComments() }
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }

    private enum CommentState {
        case loading
        case error(String)
        case empty
        case loaded
    }
}
