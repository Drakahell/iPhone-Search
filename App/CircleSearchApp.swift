import CircleSearchKit
import SwiftUI

@main
struct CircleSearchApp: App {
    @StateObject private var router = CaptureRouter.shared
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(router)
                .onOpenURL { url in
                    DeepLink(url: url)?.handle(with: router)
                }
        }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            // Снимок мог оставить Share Extension / другая команда.
            router.consumePendingCapture()
            openRecentScreenshotIfNeeded()
        }
    }

    /// «Сделал скриншот → открыл приложение» — и поиск начинается сам.
    private func openRecentScreenshotIfNeeded() {
        guard AppSettings.autoOpenRecentScreenshot, router.activeCapture == nil else { return }
        Task {
            guard let image = await LatestScreenshotProvider().fetchRecentIfAuthorized(),
                  router.activeCapture == nil
            else { return }
            router.present(image, source: .photoLibrary)
        }
    }
}
