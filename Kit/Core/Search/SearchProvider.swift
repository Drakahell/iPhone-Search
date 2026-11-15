import Foundation

enum SearchError: LocalizedError {
    case imageEncodingFailed
    case emptyQuery

    var errorDescription: String? {
        switch self {
        case .imageEncodingFailed: "Не удалось подготовить изображение."
        case .emptyQuery: "Пустой запрос."
        }
    }
}

/// Поисковый движок превращает запрос в URLRequest, который открывается в WKWebView.
/// Чтобы добавить новый движок — реализуйте протокол и зарегистрируйте его в `SearchEngine`.
protocol SearchProvider {
    func request(for query: SearchQuery) throws -> URLRequest
}

enum SearchEngine: String, CaseIterable, Identifiable {
    case googleLens

    var id: String { rawValue }

    var title: String {
        switch self {
        case .googleLens: "Google Lens"
        }
    }

    func makeProvider(languageCode: String) -> SearchProvider {
        switch self {
        case .googleLens: GoogleLensProvider(languageCode: languageCode)
        }
    }
}

/// Фасад для фичей: выбирает движок из настроек.
struct SearchCoordinator {
    var languageCode: String = Locale.current.language.languageCode?.identifier ?? "en"

    func request(for query: SearchQuery) throws -> URLRequest {
        try AppSettings.searchEngine.makeProvider(languageCode: languageCode).request(for: query)
    }
}
