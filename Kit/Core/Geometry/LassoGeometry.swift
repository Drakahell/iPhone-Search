import CoreGraphics

/// Результат жеста пользователя на оверлее.
enum StrokeKind: Equatable {
    case tap(CGPoint)       // короткое касание → выделяем объект / строку текста
    case region(CGRect)     // обвод, каракули, подчёркивание → bounding box
}

/// Чистая геометрия без UI — легко тестируется.
enum LassoGeometry {
    static let tapThreshold: CGFloat = 10
    static let minimumRegionSide: CGFloat = 48

    static func pathLength(_ points: [CGPoint]) -> CGFloat {
        zip(points, points.dropFirst()).reduce(0) { sum, pair in
            sum + hypot(pair.1.x - pair.0.x, pair.1.y - pair.0.y)
        }
    }

    static func boundingRect(of points: [CGPoint]) -> CGRect {
        guard let first = points.first else { return .null }
        var minX = first.x, maxX = first.x, minY = first.y, maxY = first.y
        for p in points.dropFirst() {
            minX = min(minX, p.x); maxX = max(maxX, p.x)
            minY = min(minY, p.y); maxY = max(maxY, p.y)
        }
        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }

    /// Любая «рисующая» форма (круг, зигзаг, линия под текстом) приводится к прямоугольнику,
    /// как в Circle to Search.
    static func classify(_ points: [CGPoint]) -> StrokeKind? {
        guard let first = points.first else { return nil }
        let rect = boundingRect(of: points)
        if pathLength(points) < tapThreshold, max(rect.width, rect.height) < tapThreshold {
            return .tap(first)
        }
        return .region(rect.expanded(toMinimumSide: minimumRegionSide))
    }

    /// Где рисуется изображение при `.aspectRatio(contentMode: .fit)`.
    static func aspectFitRect(for size: CGSize, in container: CGRect) -> CGRect {
        guard size.width > 0, size.height > 0 else { return container }
        let scale = min(container.width / size.width, container.height / size.height)
        let fitted = CGSize(width: size.width * scale, height: size.height * scale)
        return CGRect(
            x: container.midX - fitted.width / 2,
            y: container.midY - fitted.height / 2,
            width: fitted.width,
            height: fitted.height
        )
    }

    // MARK: - Нормализация (вью ↔ 0…1)

    static func normalize(_ point: CGPoint, in frame: CGRect) -> CGPoint {
        CGPoint(x: (point.x - frame.minX) / frame.width, y: (point.y - frame.minY) / frame.height)
    }

    static func normalize(_ rect: CGRect, in frame: CGRect) -> CGRect {
        CGRect(
            x: (rect.minX - frame.minX) / frame.width,
            y: (rect.minY - frame.minY) / frame.height,
            width: rect.width / frame.width,
            height: rect.height / frame.height
        )
    }

    static func denormalize(_ rect: CGRect, in frame: CGRect) -> CGRect {
        CGRect(
            x: frame.minX + rect.minX * frame.width,
            y: frame.minY + rect.minY * frame.height,
            width: rect.width * frame.width,
            height: rect.height * frame.height
        )
    }
}

extension CGRect {
    static let unit = CGRect(x: 0, y: 0, width: 1, height: 1)

    func expanded(toMinimumSide side: CGFloat) -> CGRect {
        insetBy(dx: -max(0, (side - width) / 2), dy: -max(0, (side - height) / 2))
    }

    func clampedToUnit() -> CGRect {
        let r = intersection(.unit)
        return r.isNull ? .unit : r
    }

    var center: CGPoint { CGPoint(x: midX, y: midY) }
}
