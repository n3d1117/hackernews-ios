import SwiftUI

struct SoftMeshBackground: View {
    let seed: Int
    var baseHue: Double?
    var overlayTopOpacity: Double = 0.95
    var overlayBottomOpacity: Double = 0.88
    var intensity: Double = 0.3

    private var phase: Double {
        Double(abs(seed % 997))
    }

    var body: some View {
        meshLayer(at: phase)
            .overlay(overlay)
            .ignoresSafeArea()
    }

    private func meshLayer(at time: Double) -> some View {
        MeshGradient(
            width: 3,
            height: 3,
            points: points(at: time),
            colors: palette
        )
        .blur(radius: 84)
        .scaleEffect(1.14)
        .opacity(intensity)
    }

    private var overlay: some View {
        LinearGradient(colors: [
            Color(.systemBackground).opacity(overlayTopOpacity),
            Color(.systemBackground).opacity(overlayBottomOpacity)
        ], startPoint: .top, endPoint: .bottom)
        .blendMode(.screen)
    }

    private var palette: [Color] {
        let hueSeed = baseHue ?? Double(abs(seed % 360)) / 360.0
        let hues: [Double] = [
            hueSeed,
            hueSeed + 0.04,
            hueSeed - 0.05,
            hueSeed + 0.09,
            hueSeed - 0.1,
            hueSeed + 0.14,
            hueSeed - 0.16,
            hueSeed + 0.18,
            hueSeed - 0.2
        ].map { $0.truncatingRemainder(dividingBy: 1.0) }

        return hues.enumerated().map { index, hue in
            let saturation = 0.18 + Double(index) * 0.018
            let brightness = 0.92 - Double(index) * 0.012
            return Color(hue: hue, saturation: saturation, brightness: brightness).opacity(0.6)
        }
    }

    private func points(at time: Double) -> [SIMD2<Float>] {
        let base: [SIMD2<Float>] = [
            .init(0.0, 0.0), .init(0.5, 0.0), .init(1.0, 0.0),
            .init(0.0, 0.5), .init(0.5, 0.5), .init(1.0, 0.5),
            .init(0.0, 1.0), .init(0.5, 1.0), .init(1.0, 1.0)
        ]

        return base.enumerated().map { index, point in
            let speed = 0.22 + Double(index % 3) * 0.05
            let drift = 0.075 + Double(index) * 0.0028
            let angle = time * speed + Double(index) * 1.4
            let offset = SIMD2<Float>(
                Float(sin(angle) * drift),
                Float(cos(angle * 0.9) * drift)
            )
            return clamp(point + offset)
        }
    }

    private func clamp(_ point: SIMD2<Float>) -> SIMD2<Float> {
        .init(
            max(0, min(1, point.x)),
            max(0, min(1, point.y))
        )
    }
}
