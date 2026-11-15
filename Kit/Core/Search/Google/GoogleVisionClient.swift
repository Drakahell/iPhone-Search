import UIKit

/// Официальный Google Cloud Vision API, функция Web Detection —
/// обратный поиск изображения по индексу Google: страницы с этой картинкой,
/// похожие изображения, «лучшая догадка» и сущности.
///
/// Результаты приходят структурированно, поэтому показываются нативно
/// (в шторке оверлея и в системном Visual Intelligence), без WebView.
public struct GoogleVisionClient {
    public enum Failure: LocalizedError {
        case server(code: Int, message: String)
        case invalidResponse

        public var errorDescription: String? {
            switch self {
            case .server(403, let message): "Доступ запрещён: проверьте ключ и включён ли Cloud Vision API. \(message)"
            case .server(_, let message): "Ошибка Google: \(message)"
            case .invalidResponse: "Неожиданный ответ сервера."
            }
        }
    }

    private static let endpoint = URL(string: "https://vision.googleapis.com/v1/images:annotate")!

    private let apiKey: String
    private let session: URLSession

    public init(apiKey: String, session: URLSession = .shared) {
        self.apiKey = apiKey
        self.session = session
    }

    /// Клиент с ключом из Keychain; `nil`, если ключ не задан в настройках.
    public static func configured() -> GoogleVisionClient? {
        guard let key = GoogleAPIKeyStore.load(), !key.isEmpty else { return nil }
        return GoogleVisionClient(apiKey: key)
    }

    public func webDetection(image: UIImage, maxResults: Int = 12) async throws -> WebSearchResults {
        // 1024 px достаточно для поиска и заметно ускоряет загрузку.
        guard let jpeg = image.uploadJPEG(maxPixelSide: 1024, quality: 0.8) else {
            throw SearchError.imageEncodingFailed
        }
        return try await webDetection(jpeg: jpeg, maxResults: maxResults)
    }

    public func webDetection(jpeg: Data, maxResults: Int = 12) async throws -> WebSearchResults {
        var request = URLRequest(url: Self.endpoint)
        request.httpMethod = "POST"
        request.timeoutInterval = 20
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        // Ключ — в заголовке, не в URL.
        request.setValue(apiKey, forHTTPHeaderField: "X-Goog-Api-Key")
        // Позволяет ограничить ключ в Google Cloud только вашими bundle ID.
        if let bundleID = Bundle.main.bundleIdentifier {
            request.setValue(bundleID, forHTTPHeaderField: "X-Ios-Bundle-Identifier")
        }

        let body = AnnotateRequest(requests: [
            .init(
                image: .init(content: jpeg.base64EncodedString()),
                features: [.init(type: "WEB_DETECTION", maxResults: maxResults)],
                imageContext: .init(webDetectionParams: .init(includeGeoResults: true))
            ),
        ])
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await session.data(for: request)
        return try Self.parse(data, statusCode: (response as? HTTPURLResponse)?.statusCode ?? 0)
    }

    // MARK: - Разбор ответа (internal — покрыт тестами)

    static func parse(_ data: Data, statusCode: Int) throws -> WebSearchResults {
        guard let decoded = try? JSONDecoder().decode(AnnotateResponse.self, from: data) else {
            throw Failure.invalidResponse
        }
        if let error = decoded.error ?? decoded.responses?.first?.error {
            throw Failure.server(code: error.code ?? statusCode, message: error.message ?? "")
        }
        guard (200..<300).contains(statusCode) else {
            throw Failure.server(code: statusCode, message: HTTPURLResponse.localizedString(forStatusCode: statusCode))
        }
        guard let web = decoded.responses?.first?.webDetection else { return .empty }

        let pages: [WebPage] = (web.pagesWithMatchingImages ?? []).compactMap { page in
            guard let url = URL(string: page.url) else { return nil }
            let image = (page.fullMatchingImages ?? page.partialMatchingImages ?? []).first.flatMap { URL(string: $0.url) }
            let title = page.pageTitle.map(stripHTML).flatMap { $0.isEmpty ? nil : $0 } ?? url.host() ?? page.url
            return WebPage(title: title, url: url, imageURL: image)
        }

        var seen = Set<String>()
        let entities = (web.webEntities ?? [])
            .filter { ($0.score ?? 0) > 0.3 }
            .compactMap(\.description)
            .filter { !$0.isEmpty && seen.insert($0.lowercased()).inserted }

        return WebSearchResults(
            bestGuess: web.bestGuessLabels?.first?.label,
            entities: entities,
            pages: pages,
            similarImages: (web.visuallySimilarImages ?? []).compactMap { URL(string: $0.url) }
        )
    }

    /// Google иногда возвращает заголовки с `<b>` и HTML-сущностями.
    private static func stripHTML(_ string: String) -> String {
        string
            .replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#39;", with: "'")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - DTO

private struct AnnotateRequest: Encodable {
    let requests: [Item]

    struct Item: Encodable {
        let image: Image
        let features: [Feature]
        let imageContext: Context
    }
    struct Image: Encodable { let content: String }
    struct Feature: Encodable { let type: String; let maxResults: Int }
    struct Context: Encodable { let webDetectionParams: Params }
    struct Params: Encodable { let includeGeoResults: Bool }
}

private struct AnnotateResponse: Decodable {
    let responses: [Response]?
    let error: APIError?

    struct Response: Decodable {
        let webDetection: WebDetection?
        let error: APIError?
    }
    struct APIError: Decodable {
        let code: Int?
        let message: String?
    }
    struct WebDetection: Decodable {
        let webEntities: [Entity]?
        let pagesWithMatchingImages: [Page]?
        let visuallySimilarImages: [ImageRef]?
        let bestGuessLabels: [Label]?
    }
    struct Entity: Decodable {
        let description: String?
        let score: Double?
    }
    struct Page: Decodable {
        let url: String
        let pageTitle: String?
        let fullMatchingImages: [ImageRef]?
        let partialMatchingImages: [ImageRef]?
    }
    struct ImageRef: Decodable { let url: String }
    struct Label: Decodable { let label: String }
}
