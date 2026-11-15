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
            // Снимок мог оставить Share Extension / другая команда.
            if phase == .active { router.consumePendingCapture() }
        }
    }
}
