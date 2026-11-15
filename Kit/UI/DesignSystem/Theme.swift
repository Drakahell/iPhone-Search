import SwiftUI

/// Все визуальные константы проекта. Меняете стиль — меняете здесь.
enum Theme {
    // MARK: Цвета
    static let blue = Color(red: 0.259, green: 0.522, blue: 0.957)
    static let red = Color(red: 0.918, green: 0.263, blue: 0.208)
    static let yellow = Color(red: 0.984, green: 0.737, blue: 0.020)
    static let green = Color(red: 0.204, green: 0.659, blue: 0.325)

    /// Палитра свечения краёв и штриха (замкнутая — для AngularGradient).
    static let glowColors: [Color] = [blue, red, yellow, green, blue]

    static var strokeGradient: LinearGradient {
        LinearGradient(colors: glowColors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    static let textHighlight = blue.opacity(0.32)

    // MARK: Размеры
    enum Radius {
        static let display: CGFloat = 55      // примерный радиус скругления экрана iPhone
        static let selection: CGFloat = 22
        static let thumbnail: CGFloat = 10
    }

    enum Stroke {
        static let core: CGFloat = 5
        static let glow: CGFloat = 18
        static let bracket: CGFloat = 4.5
    }

    // MARK: Затемнение
    enum Dim {
        static let idle: Double = 0.15
        static let selected: Double = 0.5
    }
}
