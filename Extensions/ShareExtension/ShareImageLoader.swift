import UIKit
import UniformTypeIdentifiers

/// Достаёт изображение из того, чем поделились. Разные приложения отдают его по-разному:
/// редактор скриншотов — объектом UIImage, «Фото» — файлом, браузеры — данными.
enum ShareImageLoader {
    enum Failure: LocalizedError {
        case noImage
        case unsupported(String)

        var errorDescription: String? {
            switch self {
            case .noImage: "В том, чем вы поделились, нет изображения."
            case .unsupported(let kind): "Неподдерживаемый формат изображения (\(kind))."
            }
        }
    }

    static func loadFirstImage(from context: NSExtensionContext?) async throws -> UIImage {
        let providers = (context?.inputItems as? [NSExtensionItem] ?? []).flatMap { $0.attachments ?? [] }
        guard let provider = providers.first(where: { $0.hasItemConformingToTypeIdentifier(UTType.image.identifier) })
        else { throw Failure.noImage }

        // 1. Объект UIImage — так отдаёт редактор скриншотов.
        if provider.canLoadObject(ofClass: UIImage.self), let image = try? await loadObject(from: provider) {
            return image
        }
        // 2. Файл, данные или UIImage через loadItem.
        return try await loadItem(from: provider)
    }

    /// Уменьшает изображение до разрешения экрана — этого хватает для поиска и экономит память.
    static func fitForExtension(_ image: UIImage, maxPixelSide: CGFloat = 2600) -> UIImage {
        let pixelW = image.size.width * image.scale
        let pixelH = image.size.height * image.scale
        let longest = max(pixelW, pixelH)
        guard longest > maxPixelSide else { return image }
        let factor = maxPixelSide / longest
        let target = CGSize(width: (pixelW * factor).rounded(), height: (pixelH * factor).rounded())
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: target, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: target))
        }
    }

    private static func loadObject(from provider: NSItemProvider) async throws -> UIImage {
        try await withCheckedThrowingContinuation { continuation in
            _ = provider.loadObject(ofClass: UIImage.self) { object, error in
                if let image = object as? UIImage {
                    continuation.resume(returning: image)
                } else {
                    continuation.resume(throwing: error ?? Failure.noImage)
                }
            }
        }
    }

    private static func loadItem(from provider: NSItemProvider) async throws -> UIImage {
        try await withCheckedThrowingContinuation { continuation in
            provider.loadItem(forTypeIdentifier: UTType.image.identifier, options: nil) { item, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                switch item {
                case let image as UIImage:
                    continuation.resume(returning: image)
                case let url as URL:
                    if let data = try? Data(contentsOf: url), let image = UIImage(data: data) {
                        continuation.resume(returning: image)
                    } else {
                        continuation.resume(throwing: Failure.unsupported("файл"))
                    }
                case let data as Data:
                    if let image = UIImage(data: data) {
                        continuation.resume(returning: image)
                    } else {
                        continuation.resume(throwing: Failure.unsupported("данные"))
                    }
                default:
                    continuation.resume(throwing: Failure.unsupported(String(describing: type(of: item))))
                }
            }
        }
    }
}
