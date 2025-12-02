import SwiftUI

extension View {
    @ViewBuilder
    func navigationSubtitleIfAvailable(_ subtitle: String) -> some View {
        if #available(iOS 26, *) {
            navigationSubtitle(subtitle)
        } else {
            self
        }
    }
}
