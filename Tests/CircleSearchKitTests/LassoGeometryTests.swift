@testable import CircleSearchKit
import XCTest

final class LassoGeometryTests: XCTestCase {
    func testShortGestureIsTap() {
        let points = [CGPoint(x: 100, y: 100), CGPoint(x: 102, y: 101)]
        XCTAssertEqual(LassoGeometry.classify(points), .tap(CGPoint(x: 100, y: 100)))
    }

    func testCircleProducesBoundingRegion() {
        let points = (0..<36).map { i -> CGPoint in
            let a = Double(i) / 36 * 2 * .pi
            return CGPoint(x: 200 + 50 * cos(a), y: 300 + 50 * sin(a))
        }
        guard case .region(let rect) = LassoGeometry.classify(points) else { return XCTFail("ожидался region") }
        XCTAssertEqual(rect.midX, 200, accuracy: 1)
        XCTAssertEqual(rect.midY, 300, accuracy: 1)
        XCTAssertEqual(rect.width, 100, accuracy: 2)
    }

    func testHorizontalUnderlineGetsMinimumHeight() {
        let points = stride(from: 0, through: 200, by: 10).map { CGPoint(x: CGFloat($0), y: 50) }
        guard case .region(let rect) = LassoGeometry.classify(points) else { return XCTFail() }
        XCTAssertEqual(rect.height, LassoGeometry.minimumRegionSide, accuracy: 0.01)
    }

    func testNormalizeRoundTrip() {
        let frame = CGRect(x: 0, y: 20, width: 390, height: 844)
        let rect = CGRect(x: 40, y: 120, width: 100, height: 60)
        let back = LassoGeometry.denormalize(LassoGeometry.normalize(rect, in: frame), in: frame)
        XCTAssertEqual(back.origin.x, rect.origin.x, accuracy: 0.001)
        XCTAssertEqual(back.size.height, rect.size.height, accuracy: 0.001)
    }

    func testAspectFitCentersImage() {
        let fit = LassoGeometry.aspectFitRect(
            for: CGSize(width: 100, height: 200),
            in: CGRect(x: 0, y: 0, width: 300, height: 300)
        )
        XCTAssertEqual(fit, CGRect(x: 75, y: 0, width: 150, height: 300))
    }

    func testCornerResizeKeepsOppositeCornerAndMinimumSize() {
        let rect = CGRect(x: 100, y: 100, width: 100, height: 100)
        let resized = SelectionCorner.topLeft.resize(rect, by: CGSize(width: 500, height: 500), minSide: 48)
        XCTAssertEqual(resized.maxX, 200)
        XCTAssertEqual(resized.maxY, 200)
        XCTAssertEqual(resized.width, 48)
    }

    func testVisionRectFlip() {
        let flipped = CGRect(x: 0.1, y: 0.7, width: 0.2, height: 0.1).visionToTopLeft
        XCTAssertEqual(flipped.minY, 0.2, accuracy: 0.0001)
    }
}
