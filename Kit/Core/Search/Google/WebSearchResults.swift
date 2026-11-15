import Foundation

/// Страница из выдачи Google, на которой найдено изображение.
public struct WebPage: Identifiable, Hashable, Sendable {
    public var id: String { url.absoluteString }
    public let title: String
    public let url: URL
    public let imageURL: URL?

    public init(title: String, url: URL, imageURL: URL?) {
        self.title = title
        self.url = url
        self.imageURL = imageURL
    }
}

/// Результат обратного поиска по изображению.
public struct WebSearchResults: Sendable {
    /// «Лучшая догадка» Google о том, что на картинке.
    public var bestGuess: String?
    /// Распознанные сущности (бренды, места, объекты).
    public var entities: [String]
    public var pages: [WebPage]
    public var similarImages: [URL]

    public static let empty = WebSearchResults(bestGuess: nil, entities: [], pages: [], similarImages: [])

    public var isEmpty: Bool {
        bestGuess == nil && entities.isEmpty && pages.isEmpty && similarImages.isEmpty
    }
}

/// Последние результаты в памяти — чтобы App Intents могли найти страницу по id.
public actor WebResultCache {
    public static let shared = WebResultCache()
    private var pages: [String: WebPage] = [:]

    public func store(_ newPages: [WebPage]) {
        for page in newPages { pages[page.id] = page }
    }

    public func page(id: String) -> WebPage? { pages[id] }
}

/// Обычный текстовый поиск Google.
public enum GoogleWebSearch {
    public static func url(for query: String, languageCode: String? = nil) -> URL? {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        var components = URLComponents(string: "https://www.google.com/search")!
        components.queryItems = [URLQueryItem(name: "q", value: trimmed)]
        let language = languageCode ?? Locale.current.language.languageCode?.identifier
        if let language { components.queryItems?.append(URLQueryItem(name: "hl", value: language)) }
        return components.url
    }
}
