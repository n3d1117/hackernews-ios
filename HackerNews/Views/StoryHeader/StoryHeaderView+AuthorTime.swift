import SwiftUI

extension StoryHeaderView {
    struct StoryHeaderAuthorTime: View, Equatable {
        let text: Text?

        var body: some View {
            if let text {
                ViewThatFits {
                    text
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary.opacity(0.92))
                    VStack(alignment: .leading, spacing: 2) {
                        text
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary.opacity(0.92))
                    }
                }
            }
        }
    }
}
