import SwiftUI

// Reusable background + stroke style for cards.
struct SoftCardStyle: ViewModifier {
    let accent: Color
    var cornerRadius: CGFloat = 18

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(.systemBackground).opacity(0.4),
                                accent.opacity(0.12)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(.ultraThinMaterial.opacity(0.55))
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
            )
    }
}

extension View {
    func softCardStyle(accent: Color, cornerRadius: CGFloat = 18) -> some View {
        modifier(SoftCardStyle(accent: accent, cornerRadius: cornerRadius))
    }
}
