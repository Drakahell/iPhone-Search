import SwiftUI

/// Рамка выделения с перетаскиваемыми уголками.
struct SelectionEditor: View {
    let rect: CGRect
    let onChange: (CGRect) -> Void
    let onEnd: () -> Void

    @State private var dragStartRect: CGRect?

    private let handleSize: CGFloat = 52

    var body: some View {
        ZStack {
            CornerBrackets(rect: rect)
                .stroke(.white, style: StrokeStyle(lineWidth: Theme.Stroke.bracket, lineCap: .round))
                .shadow(color: .black.opacity(0.4), radius: 6)

            ForEach(SelectionCorner.allCases, id: \.self) { corner in
                let point = corner.point(in: rect)
                Color.clear
                    .frame(width: handleSize, height: handleSize)
                    .contentShape(Rectangle())
                    .position(point)
                    .gesture(resizeGesture(for: corner))
                    .accessibilityHidden(true)
            }
        }
    }

    private func resizeGesture(for corner: SelectionCorner) -> some Gesture {
        DragGesture(minimumDistance: 1)
            .onChanged { value in
                if dragStartRect == nil {
                    dragStartRect = rect
                    Haptics.shared.handleGrabbed()
                }
                let base = dragStartRect ?? rect
                onChange(corner.resize(base, by: value.translation, minSide: LassoGeometry.minimumRegionSide))
            }
            .onEnded { _ in
                dragStartRect = nil
                onEnd()
            }
    }
}
