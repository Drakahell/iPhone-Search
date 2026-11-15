import UIKit

/// Откуда пришёл снимок экрана.
public enum CaptureSource: String {
    case shortcut       // App Intent из «Команд» / Action Button / Back Tap
    case shareSheet     // Share Extension
    case photoLibrary   // Последний скриншот или выбор из фото
    case deepLink
}

/// «Замороженный» экран, поверх которого рисуется оверлей.
public struct Capture: Identifiable {
    public let id = UUID()
    public let image: UIImage
    public let source: CaptureSource
    public let date = Date()

    public init(image: UIImage, source: CaptureSource) {
        self.image = image.normalizedOrientation()
        self.source = source
    }
}
