import Foundation
import SwiftData

/// SwiftData を使った ChartRepository 実装。
///
/// - `loadProgress(for:)`: documentID でピンポイント検索
/// - `findProgress(byFileURL:)`: fileURLString で検索（1:1 紐付け）
/// - `saveProgress(_:)`: upsert（存在すれば更新、なければ挿入）
@MainActor
final class SwiftDataChartRepository: ChartRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - ChartRepository

    nonisolated func loadProgress(for documentID: UUID) async throws -> DocumentProgressDTO? {
        await MainActor.run {
            fetch(documentID: documentID).map(toDTO)
        }
    }

    nonisolated func saveProgress(_ progress: DocumentProgressDTO) async throws {
        await MainActor.run {
            upsert(progress)
        }
    }

    nonisolated func findProgress(byFileURL fileURLString: String) async throws -> DocumentProgressDTO? {
        await MainActor.run {
            fetchByURL(fileURLString).map(toDTO)
        }
    }

    // MARK: - Private

    private func fetch(documentID: UUID) -> DocumentProgress? {
        let id = documentID
        let descriptor = FetchDescriptor<DocumentProgress>(
            predicate: #Predicate { $0.documentID == id }
        )
        return try? modelContext.fetch(descriptor).first
    }

    private func fetchByURL(_ urlString: String) -> DocumentProgress? {
        let descriptor = FetchDescriptor<DocumentProgress>(
            predicate: #Predicate { $0.fileURLString == urlString }
        )
        return try? modelContext.fetch(descriptor).first
    }

    private func upsert(_ dto: DocumentProgressDTO) {
        let yPositions = dto.markers.map { Double($0.yPosition) }
        let checkedFlags = dto.markers.map { $0.isChecked }

        if let existing = fetch(documentID: dto.documentID) {
            // 更新
            existing.currentRowIndex = dto.currentRowIndex
            existing.markerYPositions = yPositions
            existing.markerCheckedFlags = checkedFlags
            existing.checkCount = dto.checkCount
            existing.lastModified = .now
            existing.bookmarkData = dto.bookmarkData
            existing.drawingData = dto.drawingData
            existing.fileURLString = dto.fileURLString
        } else {
            // 挿入
            let record = DocumentProgress(
                documentID: dto.documentID,
                currentRowIndex: dto.currentRowIndex,
                markerYPositions: yPositions,
                markerCheckedFlags: checkedFlags,
                checkCount: dto.checkCount,
                bookmarkData: dto.bookmarkData,
                drawingData: dto.drawingData,
                fileURLString: dto.fileURLString
            )
            modelContext.insert(record)
        }
        try? modelContext.save()
    }

    private func toDTO(_ record: DocumentProgress) -> DocumentProgressDTO {
        let markers: [RowMarker] = zip(record.markerYPositions, record.markerCheckedFlags)
            .map { RowMarker(yPosition: CGFloat($0), isChecked: $1) }
        return DocumentProgressDTO(
            documentID: record.documentID,
            currentRowIndex: record.currentRowIndex,
            markers: markers,
            checkCount: record.checkCount,
            bookmarkData: record.bookmarkData,
            drawingData: record.drawingData,
            fileURLString: record.fileURLString
        )
    }
}
