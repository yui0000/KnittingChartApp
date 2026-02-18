import Foundation
import SwiftData

/// 編み図の進捗を永続化する SwiftData モデル。
/// Step 1 では定義のみ。ModelContainer の注入・保存呼び出しは Step 6 で実装。
@Model
final class DocumentProgress {
    @Attribute(.unique) var documentID: UUID
    var currentRowIndex: Int
    var markerYPositions: [Double]
    var markerCheckedFlags: [Bool]
    var checkCount: Int
    var lastModified: Date

    init(
        documentID: UUID,
        currentRowIndex: Int = 0,
        markerYPositions: [Double] = [],
        markerCheckedFlags: [Bool] = [],
        checkCount: Int = 0,
        lastModified: Date = .now
    ) {
        self.documentID = documentID
        self.currentRowIndex = currentRowIndex
        self.markerYPositions = markerYPositions
        self.markerCheckedFlags = markerCheckedFlags
        self.checkCount = checkCount
        self.lastModified = lastModified
    }
}
