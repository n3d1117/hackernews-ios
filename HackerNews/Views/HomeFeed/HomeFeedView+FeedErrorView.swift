import SwiftUI

extension HomeFeedView {
    struct FeedErrorView: View {
        let message: String
        let onRetry: () -> Void

        var body: some View {
            VStack(spacing: 12) {
                Text("Could not load stories")
                    .font(.title2.weight(.semibold))
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                Button(action: onRetry) {
                    RetryButtonView()
                }
                .buttonStyle(.plain)
                .padding(.top, 8)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
    }
}
