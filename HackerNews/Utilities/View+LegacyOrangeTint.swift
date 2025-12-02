import SwiftUI

// Applies the legacy orange tint on iOS 18 only.
extension View {
    @ViewBuilder
    func legacyOrangeTint() -> some View {
        if #unavailable(iOS 26) {
            self.tint(.orange)
        } else {
            self
        }
    }
}
