import AppIntents
import CircleSearchKit
import UIKit

/// Главный «триггер» оверлея на iOS.
/// Команда: «Сделать снимок экрана» → «Обвести и найти» → назначить на Action Button / Back Tap.
struct CircleToSearchIntent: AppIntent {
    static let title: LocalizedStringResource = "Обвести и найти"
    static let description = IntentDescription(
        "Открывает оверлей поиска поверх изображения. Используйте после действия «Сделать снимок экрана»."
    )
    static let openAppWhenRun = true

    @Parameter(
        title: "Изображение",
        supportedTypeIdentifiers: ["public.image"],
        inputConnectionBehavior: .connectToPreviousIntentResult
    )
    var image: IntentFile

    static var parameterSummary: some ParameterSummary {
        Summary("Обвести и найти на \(\.$image)")
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        guard let uiImage = UIImage(data: image.data) else { throw CircleSearchIntentError.unreadableImage }
        CaptureRouter.shared.present(uiImage, source: .shortcut)
        return .result()
    }
}

/// Вариант без параметров: берёт последний скриншот из медиатеки.
struct SearchLatestScreenshotIntent: AppIntent {
    static let title: LocalizedStringResource = "Найти на последнем скриншоте"
    static let openAppWhenRun = true

    @MainActor
    func perform() async throws -> some IntentResult {
        let image = try await LatestScreenshotProvider().fetch()
        CaptureRouter.shared.present(image, source: .photoLibrary)
        return .result()
    }
}

enum CircleSearchIntentError: Error, CustomLocalizedStringResourceConvertible {
    case unreadableImage

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .unreadableImage: "Не удалось прочитать изображение"
        }
    }
}
