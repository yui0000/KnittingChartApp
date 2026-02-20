import Foundation
import SwiftData

/// 編み図の進捗を永続化する SwiftData モデル。
@Model
final class DocumentProgress {
    @Attribute(.unique) var documentID: UUID
    var currentRowIndex: Int
    var markerYPositions: [Double]
    var markerCheckedFlags: [Bool]
    var checkCount: Int
    var lastModified: Date
    /// セキュアブックマークデータ（ファイル移動追跡用）
    var bookmarkData: Data?
    /// PencilKit 手書きデータ（PKDrawing.dataRepresentation()）
    var drawingData: Data?
    /// ファイルの絶対 URL 文字列（1:1 紐付けの検索キー。バンドルサンプルは nil）
    var fileURLString: String?

    init(
        documentID: UUID,
        currentRowIndex: Int = 0,
        markerYPositions: [Double] = [],
        markerCheckedFlags: [Bool] = [],
        checkCount: Int = 0,
        lastModified: Date = .now,
        bookmarkData: Data? = nil,
        drawingData: Data? = nil,
        fileURLString: String? = nil
    ) {
        self.documentID = documentID
        self.currentRowIndex = currentRowIndex
        self.markerYPositions = markerYPositions
        self.markerCheckedFlags = markerCheckedFlags
        self.checkCount = checkCount
        self.lastModified = lastModified
        self.bookmarkData = bookmarkData
        self.drawingData = drawingData
        self.fileURLString = fileURLString
    }
}
