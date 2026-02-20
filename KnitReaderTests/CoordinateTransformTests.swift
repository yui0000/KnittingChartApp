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

    // MARK: - PDF Mode Tests (pageHeight > 0)

    func test_pdf_roundTrip_atZoomOne() {
        let t = CoordinateTransform(zoomScale: 1.0, contentOffset: .zero, pageHeight: 800)
        let original = CGPoint(x: 150, y: 300)
        let viewPt = t.documentToView(original)
        let back = t.viewToDocument(viewPt)
        XCTAssertEqual(original.x, back.x, accuracy: 0.001)
        XCTAssertEqual(original.y, back.y, accuracy: 0.001)
    }

    func test_pdf_roundTrip_withZoomAndOffset() {
        let t = CoordinateTransform(
            zoomScale: 2.5,
            contentOffset: CGPoint(x: 100, y: 200),
            pageHeight: 1000
        )
        let original = CGPoint(x: 300, y: 400)
        let viewPt = t.documentToView(original)
        let back = t.viewToDocument(viewPt)
        XCTAssertEqual(original.x, back.x, accuracy: 0.001)
        XCTAssertEqual(original.y, back.y, accuracy: 0.001)
    }

    func test_pdf_documentToView_correctValues() {
        // pageHeight=1000, zoomScale=2.0, offset=(50,100)
        // docY=200 → contentY=1000-200=800 → viewY=800*2-100=1500
        let t = CoordinateTransform(
            zoomScale: 2.0,
            contentOffset: CGPoint(x: 50, y: 100),
            pageHeight: 1000
        )
        let result = t.documentToView(CGPoint(x: 100, y: 200))
        XCTAssertEqual(result.x, 150,  accuracy: 0.001)  // 100*2 - 50 = 150
        XCTAssertEqual(result.y, 1500, accuracy: 0.001)  // (1000-200)*2 - 100 = 1500
    }

    func test_pdf_yConversion_roundTrip() {
        let t = CoordinateTransform(
            zoomScale: 3.0,
            contentOffset: CGPoint(x: 0, y: 75),
            pageHeight: 800
        )
        let docY: CGFloat = 250
        let viewY = t.documentToViewY(docY)
        let backY = t.viewToDocumentY(viewY)
        XCTAssertEqual(docY, backY, accuracy: 0.001)
    }

    func test_pdf_yIsFlipped_comparedToImage() {
        // PDF モードでは docY が大きい（ページ上部）ほど viewY が小さくなる
        let pageH: CGFloat = 800
        let imageT = CoordinateTransform(zoomScale: 1.0, contentOffset: .zero, pageHeight: 0)
        let pdfT   = CoordinateTransform(zoomScale: 1.0, contentOffset: .zero, pageHeight: pageH)
        // 画像モード: docY が増えるほど viewY も増える
        XCTAssertLessThan(imageT.documentToViewY(300), imageT.documentToViewY(500))
        // PDF モード: docY が増えるほど viewY は減る（上方向）
        XCTAssertGreaterThan(pdfT.documentToViewY(300), pdfT.documentToViewY(500))
    }
}
