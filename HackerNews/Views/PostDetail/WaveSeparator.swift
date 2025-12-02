import SwiftUI

// Draws a subtle wave used to separate header from comments.
struct WaveSeparator: View {
    var amplitude: CGFloat = 3.5
    var wavelength: CGFloat = 68

    var body: some View {
        Canvas { context, size in
            guard size.width > 0 else { return }
            let midY = size.height / 2
            var path = Path()
            path.move(to: .init(x: 0, y: midY))

            stride(from: 0, through: size.width, by: 1).forEach { x in
                let sine = sin((x / wavelength) * .pi * 2)
                let y = midY + (sine * amplitude)
                path.addLine(to: .init(x: x, y: y))
            }

            let gradient = Gradient(stops: [
                .init(color: .secondary.opacity(0), location: -0.08),
                .init(color: .secondary.opacity(0.32), location: 0.1),
                .init(color: .secondary.opacity(0.45), location: 0.5),
                .init(color: .secondary.opacity(0.32), location: 0.9),
                .init(color: .secondary.opacity(0), location: 1.08)
            ])

            context.stroke(
                path,
                with: .linearGradient(
                    gradient,
                    startPoint: .init(x: 0, y: midY),
                    endPoint: .init(x: size.width, y: midY)
                ),
                style: StrokeStyle(lineWidth: 1.6, lineCap: .round, lineJoin: .round)
            )
        }
    }
}
