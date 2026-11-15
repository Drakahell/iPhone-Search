import SwiftUI

/// Светящийся след пальца: размытое гало + градиентное ядро + белая сердцевина.
struct StrokeTrail: View {
    let points: [CGPoint]

    var body: some View {
        let path = PathSmoothing.smoothPath(points)

        ZStack {
            path.stroke(Theme.strokeGradient, style: style(Theme.Stroke.glow))
                .blur(radius: 12)
                .opacity(0.75)
            path.stroke(Theme.strokeGradient, style: style(Theme.Stroke.core))
            path.stroke(.white.opacity(0.9), style: style(1.6))
        }
        .compositingGroup()
        .allowsHitTesting(false)
    }

    private func style(_ width: CGFloat) -> StrokeStyle {
        StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round)
    }
}
