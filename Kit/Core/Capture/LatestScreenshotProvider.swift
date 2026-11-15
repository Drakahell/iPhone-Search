import Photos
import UIKit

/// Достаёт самый свежий скриншот из медиатеки.
/// Используется сценарием «сделал скриншот → нажал Action Button».
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

    public init() {}

    public func fetch() async throws -> UIImage {
        let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        guard status == .authorized || status == .limited else { throw Failure.accessDenied }

        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        options.predicate = NSPredicate(
            format: "(mediaSubtypes & %d) != 0",
            PHAssetMediaSubtype.photoScreenshot.rawValue
        )
        options.fetchLimit = 1

        guard let asset = PHAsset.fetchAssets(with: .image, options: options).firstObject else {
            throw Failure.notFound
        }

        return try await withCheckedThrowingContinuation { continuation in
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
