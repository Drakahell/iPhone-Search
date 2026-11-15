import AppIntents
import CircleSearchKit
import Foundation

/// Один результат Google, который iOS показывает в системной выдаче Visual Intelligence.
struct WebResultEntity: AppEntity {
    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Результат Google"
    static let defaultQuery = WebResultEntityQuery()

    /// id — сам URL: сущность восстанавливается даже после перезапуска процесса.
    var id: String { url.absoluteString }
    let title: String
    let subtitle: String
    let url: URL
    let imageURL: URL?
    let symbol: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(title)",
            subtitle: "\(subtitle)",
            image: imageURL.map { DisplayRepresentation.Image(url: $0) }
                ?? DisplayRepresentation.Image(systemName: symbol)
        )
    }

    init(page: WebPage) {
        title = page.title
        subtitle = page.url.host() ?? ""
        url = page.url
        imageURL = page.imageURL
        symbol = "globe"
    }

    init(url: URL, title: String, subtitle: String, symbol: String) {
        self.url = url
        self.title = title
        self.subtitle = subtitle
        self.imageURL = nil
        self.symbol = symbol
    }

    /// «Искать «…» в Google».
    static func textSearch(_ query: String) -> WebResultEntity? {
        guard let url = GoogleWebSearch.url(for: query) else { return nil }
        return WebResultEntity(url: url, title: query.capitalized, subtitle: "Искать в Google", symbol: "magnifyingglass")
    }
}

struct WebResultEntityQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [WebResultEntity] {
        var result: [WebResultEntity] = []
        for id in identifiers {
            if let page = await WebResultCache.shared.page(id: id) {
                result.append(WebResultEntity(page: page))
            } else if let url = URL(string: id) {
                result.append(WebResultEntity(url: url, title: url.host() ?? id, subtitle: "", symbol: "globe"))
            }
        }
        return result
    }
}
