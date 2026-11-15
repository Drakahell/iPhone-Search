import SwiftUI

/// Переливающееся свечение по краям экрана при активации оверлея.
/// `intensity` 0…1: 1 — вспышка при открытии, ~0.35 — спокойное состояние, ~0.8 — идёт поиск.
struct EdgeGlow: View {
    var intensity: Double
    var cornerRadius: CGFloat = Theme.Radius.display

    var body: some View {
        TimelineView(.animation(paused: intensity == 0)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            let period = AnimationTokens.glowRotationPeriod
            let angle = Angle.degrees(t.truncatingRemainder(dividingBy: period) / period * 360)
            let gradient = AngularGradient(colors: Theme.glowColors, center: .center, angle: angle)
            let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)

            ZStack {
                // Широкий мягкий ореол
                shape
                    .strokeBorder(gradient, lineWidth: 10 + 16 * intensity)
                    .blur(radius: 22)
                // Тонкая яркая кромка
                shape
                    .strokeBorder(gradient, lineWidth: 2.5)
                    .blur(radius: 1)
            }
            .opacity(intensity)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
