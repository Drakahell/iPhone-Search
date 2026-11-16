import CircleSearchKit
import SwiftUI
import UIKit

/// «Поделиться → Обвести и найти» прямо из редактора скриншота.
/// Оверлей показывается внутри расширения — пользователь не уходит из своего приложения.
final class ShareViewController: UIViewController {
    private let spinner = UIActivityIndicatorView(style: .large)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        spinner.color = .white
        spinner.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(spinner)
        NSLayoutConstraint.activate([
            spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
        spinner.startAnimating()
        Task { await start() }
    }

    @MainActor
    private func start() async {
        do {
            let image = try await ShareImageLoader.loadFirstImage(from: extensionContext)
            // Лимит памяти расширения ~120 МБ: большие фото уменьшаем до размера экрана.
            showOverlay(ShareImageLoader.fitForExtension(image))
        } catch {
            showError(error)
        }
    }

    private func showOverlay(_ image: UIImage) {
        spinner.stopAnimating()
        let overlay = OverlayScreen(capture: Capture(image: image, source: .shareSheet), mode: .shareExtension) { [weak self] in
            self?.finish()
        }
        let host = UIHostingController(rootView: overlay)
        host.view.backgroundColor = .black
        addChild(host)
        host.view.frame = view.bounds
        host.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(host.view)
        host.didMove(toParent: self)
    }

    /// Вместо молчаливого закрытия — понятное сообщение.
    private func showError(_ error: Error) {
        spinner.stopAnimating()
        let alert = UIAlertController(
            title: "Не удалось открыть изображение",
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Закрыть", style: .default) { [weak self] _ in self?.finish() })
        present(alert, animated: true)
    }

    private func finish() {
        extensionContext?.completeRequest(returningItems: nil)
    }
}
