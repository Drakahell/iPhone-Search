import UIKit

enum ImageCropper {
    /// Вырезает фрагмент. `normalizedRect` — 0…1, начало в левом верхнем углу.
    static func crop(_ image: UIImage, normalizedRect: CGRect) -> UIImage? {
        guard let cg = image.normalizedOrientation().cgImage else { return nil }
        let w = CGFloat(cg.width), h = CGFloat(cg.height)
        let pixelRect = CGRect(
            x: normalizedRect.minX * w,
            y: normalizedRect.minY * h,
            width: normalizedRect.width * w,
            height: normalizedRect.height * h
        )
        .integral
        .intersection(CGRect(x: 0, y: 0, width: w, height: h))

        guard !pixelRect.isEmpty, let cropped = cg.cropping(to: pixelRect) else { return nil }
        return UIImage(cgImage: cropped, scale: image.scale, orientation: .up)
    }
}

extension UIImage {
    /// Приводит ориентацию к `.up`, чтобы координаты Vision и CGImage совпадали.
    func normalizedOrientation() -> UIImage {
        guard imageOrientation != .up else { return self }
        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        return UIGraphicsImageRenderer(size: size, format: format).image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }

    func downscaled(maxPixelSide: CGFloat) -> UIImage {
        let pixelSize = CGSize(width: size.width * scale, height: size.height * scale)
        let longest = max(pixelSize.width, pixelSize.height)
        guard longest > maxPixelSide else { return self }
        let factor = maxPixelSide / longest
        let target = CGSize(width: pixelSize.width * factor, height: pixelSize.height * factor)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: target, format: format).image { _ in
            draw(in: CGRect(origin: .zero, size: target))
        }
    }

    /// JPEG разумного размера для загрузки в поисковый сервис.
    func uploadJPEG(maxPixelSide: CGFloat = 1600, quality: CGFloat = 0.85) -> Data? {
        downscaled(maxPixelSide: maxPixelSide).jpegData(compressionQuality: quality)
    }
}
