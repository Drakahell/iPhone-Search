import UIKit

/// «Почтовый ящик» для одного снимка: расширение кладёт изображение,
/// приложение забирает его при открытии (`circlesearch://capture`).
public final class SharedCaptureStore {
    public static let shared = SharedCaptureStore()

    private let fileURL = AppGroup.containerURL.appendingPathComponent("pending-capture.png")

    public var hasPendingCapture: Bool {
        FileManager.default.fileExists(atPath: fileURL.path)
    }

    public func save(_ image: UIImage) throws {
        guard let data = image.pngData() else { throw CocoaError(.fileWriteUnknown) }
        try data.write(to: fileURL, options: .atomic)
    }

    /// Возвращает изображение и удаляет его из хранилища.
    public func consume() -> UIImage? {
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        try? FileManager.default.removeItem(at: fileURL)
        return UIImage(data: data)
    }
}
