import CoreGraphics

/// Угол рамки выделения, за который можно тянуть.
enum SelectionCorner: CaseIterable {
    case topLeft, topRight, bottomLeft, bottomRight

    func point(in rect: CGRect) -> CGPoint {
        switch self {
        case .topLeft: CGPoint(x: rect.minX, y: rect.minY)
        case .topRight: CGPoint(x: rect.maxX, y: rect.minY)
        case .bottomLeft: CGPoint(x: rect.minX, y: rect.maxY)
        case .bottomRight: CGPoint(x: rect.maxX, y: rect.maxY)
        }
    }

    /// Новый прямоугольник после перетаскивания угла; противоположный угол остаётся на месте.
    func resize(_ rect: CGRect, by translation: CGSize, minSide: CGFloat) -> CGRect {
        var minX = rect.minX, maxX = rect.maxX, minY = rect.minY, maxY = rect.maxY

        switch self {
        case .topLeft:
            minX = min(rect.minX + translation.width, maxX - minSide)
            minY = min(rect.minY + translation.height, maxY - minSide)
        case .topRight:
            maxX = max(rect.maxX + translation.width, minX + minSide)
            minY = min(rect.minY + translation.height, maxY - minSide)
        case .bottomLeft:
            minX = min(rect.minX + translation.width, maxX - minSide)
            maxY = max(rect.maxY + translation.height, minY + minSide)
        case .bottomRight:
            maxX = max(rect.maxX + translation.width, minX + minSide)
            maxY = max(rect.maxY + translation.height, minY + minSide)
        }
        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }
}
