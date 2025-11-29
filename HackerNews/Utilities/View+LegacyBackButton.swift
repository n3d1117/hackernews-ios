import SwiftUI

extension View {
    @ViewBuilder
    func legacyBackButtonTitleHidden() -> some View {
        if #unavailable(iOS 26) {
            toolbarRole(.editor)
        } else {
            self
        }
    }
}
