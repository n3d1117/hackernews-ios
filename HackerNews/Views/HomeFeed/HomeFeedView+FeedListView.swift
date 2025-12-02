import Observation
import SwiftUI

extension HomeFeedView {
    struct FeedListView: View {
        @Bindable var viewModel: StoryFeedViewModel
        let namespace: Namespace.ID?

        var body: some View {
            LazyVStack(spacing: 14) {
                ForEach(viewModel.stories) { story in
                    StoryCard(
                        story: story,
                        namespace: namespace,
                        showCommentCount: viewModel.category != .jobs
                    )
                    .onAppear {
                        Task {
                            await viewModel.loadMoreIfNeeded(for: story)
                        }
                    }
                }
                if isPaging {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
            }
        }

        private var isPaging: Bool {
            viewModel.isLoading && !viewModel.stories.isEmpty
        }
    }
}
