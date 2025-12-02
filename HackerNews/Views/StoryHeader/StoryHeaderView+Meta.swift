import SwiftUI

extension StoryHeaderView {
    struct StoryHeaderMeta: View, Equatable {
        let domainText: String?
        let faviconURL: URL?

        var body: some View {
            HStack(spacing: 8) {
                faviconView

                if let domainText {
                    Text(domainText.uppercased())
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }
        }

        private var faviconView: some View {
            AsyncImage(url: faviconURL) { phase in
                switch phase {
                case let .success(image):
                    image
                        .resizable()
                        .scaledToFill()
                default:
                    Image(systemName: "globe")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary.opacity(0.78))
                }
            }
            .frame(width: 14, height: 14)
            .clipShape(Circle())
        }
    }
}
