import SwiftUI

struct TaskOnceModifier: ViewModifier {
    @State private var hasRun = false
    let action: @Sendable () async -> Void

    func body(content: Content) -> some View {
        content
            .task {
                if !hasRun {
                    hasRun = true
                    await action()
                }
            }
    }
}

extension View {
    func taskOnce(action: @Sendable @escaping () async -> Void) -> some View {
        modifier(TaskOnceModifier(action: action))
    }
}
