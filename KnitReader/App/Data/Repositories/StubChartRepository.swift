import Foundation

/// インメモリの Stub リポジトリ。MVP では永続化せずメモリ上で保持する。
final class StubChartRepository: ChartRepository, @unchecked Sendable {
    private var storage: [UUID: DocumentProgressDTO] = [:]

    func loadProgress(for documentID: UUID) async throws -> DocumentProgressDTO? {
        storage[documentID]
    }

    func saveProgress(_ progress: DocumentProgressDTO) async throws {
        storage[progress.documentID] = progress
    }
}
