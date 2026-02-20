import Foundation

/// インメモリの Stub リポジトリ。テスト・プレビュー用。
final class StubChartRepository: ChartRepository, @unchecked Sendable {
    private var storage: [UUID: DocumentProgressDTO] = [:]

    func loadProgress(for documentID: UUID) async throws -> DocumentProgressDTO? {
        storage[documentID]
    }

    func saveProgress(_ progress: DocumentProgressDTO) async throws {
        storage[progress.documentID] = progress
    }

    func findProgress(byFileURL fileURLString: String) async throws -> DocumentProgressDTO? {
        storage.values.first { $0.fileURLString == fileURLString }
    }
}
