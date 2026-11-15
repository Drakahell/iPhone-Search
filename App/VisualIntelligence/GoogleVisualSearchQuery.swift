import AppIntents
import CircleSearchKit
import CoreImage
import UIKit

// Модуль VisualIntelligence есть только в SDK для реального iPhone —
// в сборке для симулятора этот файл просто исключается.
#if canImport(VisualIntelligence)
import VisualIntelligence

/// Интеграция с системным Visual Intelligence (iOS 26+).
///
/// Пользователь делает скриншот (или жмёт Action Button / Camera Control),
/// обводит область пальцем («Выделить для поиска»), и iOS запрашивает у нас результаты.
/// Весь UI — системный, поверх текущего приложения: наше приложение
/// НЕ открывается, а работает в фоне только ради этого запроса.
@available(iOS 26.0, *)
struct GoogleVisualSearchQuery: IntentValueQuery {
    func values(for input: SemanticContentDescriptor) async throws -> [WebResultEntity] {
        var entities: [WebResultEntity] = []

        if let pixelBuffer = input.pixelBuffer,
           let client = GoogleVisionClient.configured(),
           let image = Self.image(from: pixelBuffer),
           let results = try? await client.webDetection(image: image)
        {
            await WebResultCache.shared.store(results.pages)
            if let guess = results.bestGuess, let entity = WebResultEntity.textSearch(guess) {
                entities.append(entity)
            }
            entities += results.pages.prefix(15).map(WebResultEntity.init(page:))
        }

        // Без ключа или при ошибке сети — текстовый поиск по меткам, которые уже распознала система.
        if entities.isEmpty {
            entities = input.labels.prefix(5).compactMap(WebResultEntity.textSearch)
        }
        return entities
    }

    private static func image(from buffer: CVReadOnlyPixelBuffer) -> UIImage? {
        buffer.withUnsafeBuffer { pixelBuffer in
            let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
            guard let cgImage = CIContext().createCGImage(ciImage, from: ciImage.extent) else { return nil }
            return UIImage(cgImage: cgImage)
        }
    }
}
#endif
