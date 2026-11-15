import SwiftUI

/// Блик, пробегающий по выделенной области, пока идёт распознавание/поиск.
struct ScanShimmer: View {
    var cornerRadius: CGFloat = Theme.Radius.selection

    var body: some View {
        TimelineView(.animation) { context in
            GeometryReader { geo in
                let period = AnimationTokens.scanPeriod
                let progress = context.date.timeIntervalSinceReferenceDate
                    .truncatingRemainder(dividingBy: period) / period
                let bandWidth = max(geo.size.width * 0.6, 80)

                LinearGradient(
                    colors: [.clear, .white.opacity(0.45), Theme.blue.opacity(0.25), .clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: bandWidth)
                .rotationEffect(.degrees(12))
                .offset(x: -bandWidth + progress * (geo.size.width + bandWidth * 2))
                .frame(maxHeight: .infinity)
                .blendMode(.plusLighter)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .allowsHitTesting(false)
        .transition(.opacity)
    }
}
