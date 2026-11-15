import Foundation

/// Строка текста, найденная Vision. Координаты нормализованы (0…1, начало — левый верхний угол).
struct RecognizedText: Identifiable, Hashable {
    let id = UUID()
    let string: String
    let normalizedBox: CGRect
}

/// QR / штрихкод.
struct RecognizedCode: Identifiable, Hashable {
    let id = UUID()
    let payload: String
    let symbology: String

    var url: URL? {
        guard let url = URL(string: payload), url.scheme?.hasPrefix("http") == true else { return nil }
        return url
    }
}

struct RecognitionResult {
    var texts: [RecognizedText] = []
    var codes: [RecognizedCode] = []

    static let empty = RecognitionResult()

    var fullText: String { texts.map(\.string).joined(separator: "\n") }
    var hasText: Bool { !texts.isEmpty }
}
