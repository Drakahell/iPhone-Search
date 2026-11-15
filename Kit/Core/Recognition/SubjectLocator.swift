import UIKit
import Vision

/// «Тап по объекту»: находит границы объекта под пальцем через маску переднего плана (iOS 17+).
/// На симуляторе запрос не поддерживается — вернётся nil, сработает фолбэк.
struct SubjectLocator {
    func subjectRect(in image: UIImage, at normalizedPoint: CGPoint) async -> CGRect? {
        guard let cgImage = image.cgImage else { return nil }

        return await Task.detached(priority: .userInitiated) { () -> CGRect? in
            let request = VNGenerateForegroundInstanceMaskRequest()
            do { try VNImageRequestHandler(cgImage: cgImage).perform([request]) } catch { return nil }
            guard let observation = request.results?.first else { return nil }

            let mask = observation.instanceMask
            CVPixelBufferLockBaseAddress(mask, .readOnly)
            defer { CVPixelBufferUnlockBaseAddress(mask, .readOnly) }

            let width = CVPixelBufferGetWidth(mask)
            let height = CVPixelBufferGetHeight(mask)
            let rowBytes = CVPixelBufferGetBytesPerRow(mask)
            guard let base = CVPixelBufferGetBaseAddress(mask)?.assumingMemoryBound(to: UInt8.self) else { return nil }

            let px = min(width - 1, max(0, Int(normalizedPoint.x * CGFloat(width))))
            let py = min(height - 1, max(0, Int(normalizedPoint.y * CGFloat(height))))
            let label = base[py * rowBytes + px]
            guard label != 0 else { return nil }   // 0 = фон

            var minX = width, minY = height, maxX = -1, maxY = -1
            for y in 0..<height {
                let row = base + y * rowBytes
                for x in 0..<width where row[x] == label {
                    minX = min(minX, x); maxX = max(maxX, x)
                    minY = min(minY, y); maxY = max(maxY, y)
                }
            }
            guard maxX >= minX, maxY >= minY else { return nil }

            return CGRect(
                x: CGFloat(minX) / CGFloat(width),
                y: CGFloat(minY) / CGFloat(height),
                width: CGFloat(maxX - minX + 1) / CGFloat(width),
                height: CGFloat(maxY - minY + 1) / CGFloat(height)
            )
        }.value
    }
}
