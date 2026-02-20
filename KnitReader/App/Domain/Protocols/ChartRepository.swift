import Foundation

/// 編み図の進捗データの読み書きプロトコル。
/// Data 層で Stub / SwiftData 実装を提供する。
protocol ChartRepository: Sendable {
    func loadProgress(for documentID: UUID) async throws -> DocumentProgressDTO?
    func saveProgress(_ progress: DocumentProgressDTO) async throws
    /// ファイル URL 文字列で既存の進捗を検索する（1:1 紐付け用）
    func findProgress(byFileURL fileURLString: String) async throws -> DocumentProgressDTO?
}

/// Domain 層の DTO。SwiftData に依存しない。
struct DocumentProgressDTO: Equatable, Sendable {
    let documentID: UUID
    var currentRowIndex: Int
    var markers: [RowMarker]
    var checkCount: Int
    /// セキュアブックマークデータ（ファイル移動追跡用）
    var bookmarkData: Data?
    /// PencilKit 手書きデータ
    var drawingData: Data?
    /// ファイルの絶対 URL 文字列（バンドルサンプルは nil）
    var fileURLString: String?
}
