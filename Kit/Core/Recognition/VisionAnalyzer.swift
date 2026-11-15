import UIKit
import Vision

struct AnalysisFeatures: OptionSet {
    let rawValue: Int
    static let text = AnalysisFeatures(rawValue: 1 << 0)
    static let barcodes = AnalysisFeatures(rawValue: 1 << 1)
    static let all: AnalysisFeatures = [.text, .barcodes]
}

protocol ImageAnalyzing {
    func analyze(_ image: UIImage, features: AnalysisFeatures) async throws -> RecognitionResult
}

/// Распознавание на устройстве: OCR и штрихкоды (Vision).
struct VisionAnalyzer: ImageAnalyzing {
    var languages: [String] = ["ru-RU", "en-US"]

    func analyze(_ image: UIImage, features: AnalysisFeatures = .all) async throws -> RecognitionResult {
        guard let cgImage = image.normalizedOrientation().cgImage else { return .empty }
        let languages = self.languages

        return try await Task.detached(priority: .userInitiated) {
            var requests: [VNRequest] = []

            let textRequest = VNRecognizeTextRequest()
            textRequest.recognitionLevel = .accurate
            textRequest.usesLanguageCorrection = true
            textRequest.recognitionLanguages = languages
            if features.contains(.text) { requests.append(textRequest) }

            let barcodeRequest = VNDetectBarcodesRequest()
            if features.contains(.barcodes) { requests.append(barcodeRequest) }

            try VNImageRequestHandler(cgImage: cgImage).perform(requests)
            try Task.checkCancellation()

            let texts: [RecognizedText] = (textRequest.results ?? []).compactMap { observation in
                guard let candidate = observation.topCandidates(1).first else { return nil }
                return RecognizedText(string: candidate.string, normalizedBox: observation.boundingBox.visionToTopLeft)
            }
            let codes: [RecognizedCode] = (barcodeRequest.results ?? []).compactMap { observation in
                guard let payload = observation.payloadStringValue else { return nil }
                return RecognizedCode(payload: payload, symbology: observation.symbology.rawValue)
            }
            return RecognitionResult(texts: texts, codes: codes)
        }.value
    }
}

extension CGRect {
    /// Vision отдаёт координаты с началом в левом нижнем углу — переворачиваем.
    var visionToTopLeft: CGRect {
        CGRect(x: minX, y: 1 - maxY, width: width, height: height)
    }
}
