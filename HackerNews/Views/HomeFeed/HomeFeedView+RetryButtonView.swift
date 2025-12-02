import SwiftUI

extension HomeFeedView {
    struct RetryButtonView: View {
        var body: some View {
            HStack(spacing: 5) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 11, weight: .semibold))
                Text("Retry")
                    .tracking(0.6)
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
                                Color.orange.opacity(0.18)
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
}
