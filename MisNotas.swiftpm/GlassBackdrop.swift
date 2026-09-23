import SwiftUI

/// Fondo de colores suaves que se mueve lentamente, para que el vidrio (Liquid Glass) tenga qué refractar.
struct GlassBackdrop: View {
    var colors: [Color] = [.indigo, .pink, .teal]
    var animated = true

    var body: some View {
        ZStack {
            Color(.systemBackground)
            if animated {
                TimelineView(.animation(minimumInterval: 1.0 / 20)) { timeline in
                    mesh(time: Float(timeline.date.timeIntervalSinceReferenceDate))
                }
            } else {
                mesh(time: 0)
            }
        }
        .ignoresSafeArea()
    }

    private func mesh(time t: Float) -> some View {
        let c = colors.isEmpty ? [Color.indigo] : colors
        let tint = { (i: Int, alpha: Double) in c[i % c.count].opacity(alpha) }
        return MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0, 0], [0.5, 0], [1, 0],
                [0, 0.5 + 0.12 * sin(t * 0.25)],
                [0.5 + 0.18 * sin(t * 0.31), 0.5 + 0.16 * cos(t * 0.27)],
                [1, 0.5 + 0.12 * cos(t * 0.22)],
                [0, 1], [0.5, 1], [1, 1]
            ],
            colors: [
                tint(0, 0.45), tint(1, 0.25), tint(2, 0.40),
                tint(1, 0.30), tint(0, 0.10), tint(2, 0.25),
                tint(2, 0.40), tint(0, 0.30), tint(1, 0.45)
            ]
        )
    }
}
