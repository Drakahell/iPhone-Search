import SwiftUI

/// Четыре скруглённых «уголка» рамки выделения. Анимируется по `rect` —
/// именно это даёт плавный морфинг «штрих → рамка» и ресайз за уголки.
struct CornerBrackets: Shape {
    var rect: CGRect
    var radius: CGFloat = Theme.Radius.selection
    var arm: CGFloat = 26

    var animatableData: CGRect.AnimatableData {
        get { rect.animatableData }
        set { rect.animatableData = newValue }
    }

    func path(in _: CGRect) -> Path {
        var p = Path()
        let r = max(0, min(radius, rect.width / 2, rect.height / 2))
        let a = max(0, min(arm, rect.width / 2 - r, rect.height / 2 - r))

        // ↖
        p.move(to: CGPoint(x: rect.minX, y: rect.minY + r + a))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.minY + r))
        p.addArc(center: CGPoint(x: rect.minX + r, y: rect.minY + r), radius: r,
                 startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false)
        p.addLine(to: CGPoint(x: rect.minX + r + a, y: rect.minY))
        // ↗
        p.move(to: CGPoint(x: rect.maxX - r - a, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX - r, y: rect.minY))
        p.addArc(center: CGPoint(x: rect.maxX - r, y: rect.minY + r), radius: r,
                 startAngle: .degrees(270), endAngle: .degrees(360), clockwise: false)
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + r + a))
        // ↘
        p.move(to: CGPoint(x: rect.maxX, y: rect.maxY - r - a))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - r))
        p.addArc(center: CGPoint(x: rect.maxX - r, y: rect.maxY - r), radius: r,
                 startAngle: .degrees(0), endAngle: .degrees(90), clockwise: false)
        p.addLine(to: CGPoint(x: rect.maxX - r - a, y: rect.maxY))
        // ↙
        p.move(to: CGPoint(x: rect.minX + r + a, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX + r, y: rect.maxY))
        p.addArc(center: CGPoint(x: rect.minX + r, y: rect.maxY - r), radius: r,
                 startAngle: .degrees(90), endAngle: .degrees(180), clockwise: false)
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - r - a))
        return p
    }
}

/// Затемнение всего экрана с «окном» под выделение (even-odd заливка).
struct DimmingShape: Shape {
    var cutout: CGRect
    var cornerRadius: CGFloat = Theme.Radius.selection

    var animatableData: CGRect.AnimatableData {
        get { cutout.animatableData }
        set { cutout.animatableData = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var p = Path(rect)
        if !cutout.isEmpty {
            p.addRoundedRect(
                in: cutout,
                cornerSize: CGSize(width: cornerRadius, height: cornerRadius),
                style: .continuous
            )
        }
        return p
    }
}
