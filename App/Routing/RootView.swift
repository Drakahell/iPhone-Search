import CircleSearchKit
import SwiftUI

struct RootView: View {
    @EnvironmentObject private var router: CaptureRouter

    var body: some View {
        HomeScreen { image, source in
            router.present(image, source: source)
        }
        .fullScreenCover(item: $router.activeCapture) { capture in
            OverlayScreen(capture: capture) { router.dismiss() }
        }
        .sheet(isPresented: Binding(
            get: { router.openedPage != nil },
            set: { if !$0 { router.openedPage = nil } }
        )) {
            if let url = router.openedPage {
                SafariView(url: url).ignoresSafeArea()
            }
        }
    }
}
