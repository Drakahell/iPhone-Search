import SwiftUI

/// Единая точка входа для показа оверлея — из App Intent, deep link, Home-экрана.
@MainActor
public final class CaptureRouter: ObservableObject {
    public static let shared = CaptureRouter()

    @Published public var activeCapture: Capture?
    /// Страница, открытая из результата Visual Intelligence.
    @Published public var openedPage: URL?

    public init() {}

    /// Показываем оверлей без анимации презентации — экран должен выглядеть «замороженным».
    public func present(_ image: UIImage, source: CaptureSource) {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            activeCapture = Capture(image: image, source: source)
        }
    }

    public func dismiss() {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) { activeCapture = nil }
    }

    /// Забрать снимок, оставленный расширением в App Group.
    public func consumePendingCapture() {
        guard let image = SharedCaptureStore.shared.consume() else { return }
        present(image, source: .deepLink)
    }
}
