import UIKit

/// Google Lens через веб-загрузку изображения.
///
/// ⚠️ У Lens нет публичного API: используется тот же endpoint, что и у веб-версии
/// (multipart-поле `encoded_image`). Если Google его изменит — правка нужна только здесь.
struct GoogleLensProvider: SearchProvider {
    var languageCode: String

    private static let uploadURL = URL(string: "https://lens.google.com/v3/upload")!

    func request(for query: SearchQuery) throws -> URLRequest {
        switch query {
        case .text(let text):
            return try textSearch(text)
        case .image(let image):
            return try upload(image, text: nil)
        case .imageAndText(let image, let text):
            return try upload(image, text: text)
        }
    }

    private func upload(_ image: UIImage, text: String?) throws -> URLRequest {
        guard let jpeg = image.uploadJPEG() else { throw SearchError.imageEncodingFailed }

        var components = URLComponents(url: Self.uploadURL, resolvingAgainstBaseURL: false)!
        var items = [
            URLQueryItem(name: "hl", value: languageCode),
            URLQueryItem(name: "st", value: String(Int(Date().timeIntervalSince1970 * 1000))),
        ]
        // Мультипоиск «картинка + текст» — best effort, веб-версия Lens принимает уточнение в `q`.
        if let text, !text.trimmingCharacters(in: .whitespaces).isEmpty {
            items.append(URLQueryItem(name: "q", value: text))
        }
        components.queryItems = items

        var form = MultipartFormData()
        form.addFile(name: "encoded_image", filename: "image.jpg", mimeType: "image/jpeg", data: jpeg)

        var request = URLRequest(url: components.url!)
        request.httpMethod = "POST"
        request.setValue(form.contentType, forHTTPHeaderField: "Content-Type")
        request.httpBody = form.finalized()
        return request
    }

    private func textSearch(_ text: String) throws -> URLRequest {
        guard let url = GoogleWebSearch.url(for: text, languageCode: languageCode) else { throw SearchError.emptyQuery }
        return URLRequest(url: url)
    }
}
