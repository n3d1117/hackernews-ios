import SwiftUI

extension HomeFeedView {
    struct CategorySelector: View {
        let selection: Binding<StoryFeedCategory>

        var body: some View {
            Menu {
                Picker("Feed", selection: selection) {
                    ForEach(StoryFeedCategory.allCases) { category in
                        Label(category.title, systemImage: category.icon)
                            .tag(category)
                    }
                }
            } label: {
                Image(systemName: "line.3.horizontal.decrease")
                    .font(.headline.weight(.semibold))
            }
        }
    }
}
