import SwiftUI

/// Единый источник таймингов и пружин. Подстройка «ощущения» — только здесь.
enum AnimationTokens {
    /// Штрих → рамка выделения.
    static let selectionMorph = Animation.spring(response: 0.45, dampingFraction: 0.78)
    /// Исчезновение штриха после отпускания пальца.
    static let strokeFade = Animation.easeOut(duration: 0.35)
    /// Появление/затухание свечения по краям.
    static let glowIn = Animation.easeOut(duration: 0.45)
    static let glowSettle = Animation.easeInOut(duration: 0.9)
    /// Затемнение фона.
    static let dim = Animation.easeInOut(duration: 0.25)
    /// Кнопки, подсказки, панель поиска.
    static let chrome = Animation.snappy(duration: 0.3)
    static let press = Animation.spring(response: 0.25, dampingFraction: 0.7)

    /// Период вращения градиента свечения, сек.
    static let glowRotationPeriod: Double = 4
    /// Период прохода блика сканирования, сек.
    static let scanPeriod: Double = 1.4
    /// Через сколько свечение «успокаивается» после открытия.
    static let glowSettleDelay: Duration = .milliseconds(1100)
}
