import CircleSearchKit
import SwiftUI
import UIKit
import UniformTypeIdentifiers

/// «Поделиться → Обвести и найти» прямо из редактора скриншота.
/// Оверлей показывается внутри расширения — без перехода в приложение.
final class ShareViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        Task { await start() }
    }

    @MainActor
    private func start() async {
        let providers = (extensionContext?.inputItems as? [NSExtensionItem] ?? [])
            .flatMap { $0.attachments ?? [] }
        guard let provider = providers.first(where: { $0.hasItemConformingToTypeIdentifier(UTType.image.identifier) }),
              let image = try? await Self.loadImage(from: provider)
        else { return finish() }

        let overlay = OverlayScreen(capture: Capture(image: image, source: .shareSheet)) { [weak self] in
            self?.finish()
        }
        let host = UIHostingController(rootView: overlay)
        addChild(host)
        host.view.frame = view.bounds
        host.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(host.view)
        host.didMove(toParent: self)
    }

    private static func loadImage(from provider: NSItemProvider) async throws -> UIImage {
        try await withCheckedThrowingContinuation { continuation in
            provider.loadDataRepresentation(forTypeIdentifier: UTType.image.identifier) { data, error in
                if let data, let image = UIImage(data: data) {
                    continuation.resume(returning: image)
                } else {
                    continuation.resume(throwing: error ?? CocoaError(.fileReadCorruptFile))
                }
            }
        }
    }

    private func finish() {
        extensionContext?.completeRequest(returningItems: nil)
    }
}
