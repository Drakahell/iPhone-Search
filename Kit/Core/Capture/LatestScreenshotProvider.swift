import Photos
import UIKit

/// Достаёт самый свежий скриншот из медиатеки.
public struct LatestScreenshotProvider {
    public enum Failure: LocalizedError {
        case accessDenied, notFound

        public var errorDescription: String? {
            switch self {
            case .accessDenied: "Нет доступа к фото. Разрешите его в Настройках."
            case .notFound: "Скриншоты не найдены."
            }
        }
    }

    private static let lastOpenedKey = "capture.lastOpenedScreenshotID"

    public init() {}

    public static var isAuthorized: Bool {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        return status == .authorized || status == .limited
    }

    /// Ручной запуск: при необходимости спрашивает разрешение.
    public func fetch() async throws -> UIImage {
        let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        guard status == .authorized || status == .limited else { throw Failure.accessDenied }
        guard let asset = Self.latestScreenshotAsset() else { throw Failure.notFound }
        Self.markOpened(asset)
        return try await Self.image(for: asset)
    }

    /// Автозапуск: скриншот не старше `maxAge`, который ещё не открывали.
    /// Разрешение НЕ запрашивает — работает, только если доступ уже выдан.
    public func fetchRecentIfAuthorized(maxAge: TimeInterval = 60) async -> UIImage? {
        guard Self.isAuthorized,
              let asset = Self.latestScreenshotAsset(),
              let created = asset.creationDate,
              Date().timeIntervalSince(created) <= maxAge,
              AppGroup.defaults.string(forKey: Self.lastOpenedKey) != asset.localIdentifier
        else { return nil }
        Self.markOpened(asset)
        return try? await Self.image(for: asset)
    }

    // MARK: - Внутреннее

    private static func markOpened(_ asset: PHAsset) {
        AppGroup.defaults.set(asset.localIdentifier, forKey: lastOpenedKey)
    }

    private static func latestScreenshotAsset() -> PHAsset? {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        options.predicate = NSPredicate(
            format: "(mediaSubtypes & %d) != 0",
            PHAssetMediaSubtype.photoScreenshot.rawValue
        )
        options.fetchLimit = 1
        return PHAsset.fetchAssets(with: .image, options: options).firstObject
    }

    private static func image(for asset: PHAsset) async throws -> UIImage {
        try await withCheckedThrowingContinuation { continuation in
            let request = PHImageRequestOptions()
            request.deliveryMode = .highQualityFormat
            request.isNetworkAccessAllowed = true
            PHImageManager.default().requestImage(
                for: asset,
                targetSize: PHImageManagerMaximumSize,
                contentMode: .default,
                options: request
            ) { image, _ in
                if let image { continuation.resume(returning: image) }
                else { continuation.resume(throwing: Failure.notFound) }
            }
        }
    }
}
