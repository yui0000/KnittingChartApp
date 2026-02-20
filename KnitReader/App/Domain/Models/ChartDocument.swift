import Foundation
import CoreGraphics

/// 読み込まれた編み図ドキュメントを表す値型。
struct ChartDocument: Equatable, Sendable {
    let id: UUID
    let title: String
    /// ドキュメント座標系での固有サイズ（ポイント）
    let documentSize: CGSize
    let source: Source

    enum Source: Equatable, Sendable {
        case bundled(name: String)
        case fileURL(URL)
        case pdfURL(URL)
    }

    var isPDF: Bool {
        if case .pdfURL = source { return true }
        return false
    }
}
