import Foundation

/// 編み図の進捗データの読み書きプロトコル。
/// Data 層で Stub / SwiftData 実装を提供する。
protocol ChartRepository: Sendable {
    func loadProgress(for documentID: UUID) async throws -> DocumentProgressDTO?
    func saveProgress(_ progress: DocumentProgressDTO) async throws
}

/// Domain 層の DTO。SwiftData に依存しない。
struct DocumentProgressDTO: Equatable, Sendable {
    let documentID: UUID
    var currentRowIndex: Int
    var markers: [RowMarker]
    var checkCount: Int
}
