import XCTest
@testable import KnitReader

final class CoordinateTransformTests: XCTestCase {

    func test_roundTrip_atZoomOne() {
        let t = CoordinateTransform(zoomScale: 1.0, contentOffset: .zero)
        let original = CGPoint(x: 150, y: 300)
        let viewPt = t.documentToView(original)
        let back = t.viewToDocument(viewPt)
        XCTAssertEqual(original.x, back.x, accuracy: 0.001)
        XCTAssertEqual(original.y, back.y, accuracy: 0.001)
    }

    func test_roundTrip_withZoomAndOffset() {
        let t = CoordinateTransform(zoomScale: 2.5, contentOffset: CGPoint(x: 100, y: 200))
        let original = CGPoint(x: 300, y: 400)
        let viewPt = t.documentToView(original)
        let back = t.viewToDocument(viewPt)
        XCTAssertEqual(original.x, back.x, accuracy: 0.001)
        XCTAssertEqual(original.y, back.y, accuracy: 0.001)
    }

    func test_documentToView_correctValues() {
        let t = CoordinateTransform(zoomScale: 2.0, contentOffset: CGPoint(x: 50, y: 100))
        // doc (100, 200) -> view (100*2 - 50, 200*2 - 100) = (150, 300)
        let result = t.documentToView(CGPoint(x: 100, y: 200))
        XCTAssertEqual(result.x, 150, accuracy: 0.001)
        XCTAssertEqual(result.y, 300, accuracy: 0.001)
    }

    func test_yConversion_roundTrip() {
        let t = CoordinateTransform(zoomScale: 3.0, contentOffset: CGPoint(x: 0, y: 75))
        let docY: CGFloat = 250
        let viewY = t.documentToViewY(docY)
        let backY = t.viewToDocumentY(viewY)
        XCTAssertEqual(docY, backY, accuracy: 0.001)
    }

    func test_rectConversion() {
        let t = CoordinateTransform(zoomScale: 2.0, contentOffset: CGPoint(x: 10, y: 20))
        let docRect = CGRect(x: 50, y: 100, width: 200, height: 300)
        let viewRect = t.documentToView(docRect)
        XCTAssertEqual(viewRect.origin.x, 50 * 2 - 10, accuracy: 0.001)
        XCTAssertEqual(viewRect.origin.y, 100 * 2 - 20, accuracy: 0.001)
        XCTAssertEqual(viewRect.width, 200 * 2, accuracy: 0.001)
        XCTAssertEqual(viewRect.height, 300 * 2, accuracy: 0.001)
    }
}
