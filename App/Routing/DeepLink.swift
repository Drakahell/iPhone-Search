import CircleSearchKit
import Foundation

/// circlesearch://capture — открыть снимок из App Group
/// circlesearch://latest  — открыть последний скриншот из медиатеки
enum DeepLink {
    case pendingCapture
    case latestScreenshot

    init?(url: URL) {
        guard url.scheme == "circlesearch" else { return nil }
        switch url.host() {
        case "capture": self = .pendingCapture
        case "latest": self = .latestScreenshot
        default: return nil
        }
    }

    @MainActor
    func handle(with router: CaptureRouter) {
        switch self {
        case .pendingCapture:
            router.consumePendingCapture()
        case .latestScreenshot:
            Task {
                if let image = try? await LatestScreenshotProvider().fetch() {
                    router.present(image, source: .deepLink)
                }
            }
        }
    }
}
