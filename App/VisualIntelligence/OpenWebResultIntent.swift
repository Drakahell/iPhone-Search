import AppIntents
import CircleSearchKit

/// Вызывается, когда пользователь сам нажимает на результат в Visual Intelligence.
/// Только в этот момент открывается наше приложение (страница во встроенном Safari).
struct OpenWebResultIntent: OpenIntent {
    static let title: LocalizedStringResource = "Открыть результат Google"

    @Parameter(title: "Результат")
    var target: WebResultEntity

    @MainActor
    func perform() async throws -> some IntentResult {
        CaptureRouter.shared.openedPage = target.url
        return .result()
    }
}
