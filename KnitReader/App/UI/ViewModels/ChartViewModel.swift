import SwiftUI
import Combine

/// 編み図ビューアの中央 ViewModel。
///
/// 3つの独立 Undo スタック（行インデックス / マーカー / チェックカウント）を管理し、
/// 座標変換パラメータを ScrollViewBridge から受け取る。
@MainActor
final class ChartViewModel: ObservableObject {
    // MARK: - Document State

    @Published var chartDocument: ChartDocument?
    @Published var chartImage: UIImage?

    // MARK: - Scroll / Zoom State（ScrollViewBridge から Binding で更新）

    @Published var zoomScale: CGFloat = 1.0
    @Published var contentOffset: CGPoint = .zero
    @Published var viewportSize: CGSize = .zero

    // MARK: - Row Configuration

    @Published var startY: CGFloat = 100
    @Published var rowHeight: CGFloat = 40
    @Published var stepCount: Int = 1

    // MARK: - Independent Undo Stacks

    let rowIndexUndo = UndoStack<Int>(initial: 0)
    let markersUndo = UndoStack<[RowMarker]>(initial: [])
    let checkCountUndo = UndoStack<Int>(initial: 0)

    // MARK: - Computed

    var transform: CoordinateTransform {
        CoordinateTransform(zoomScale: zoomScale, contentOffset: contentOffset)
    }

    var currentRowIndex: Int { rowIndexUndo.current }
    var markers: [RowMarker] { markersUndo.current }
    var checkCount: Int { checkCountUndo.current }

    // MARK: - Load Actions

    /// Bundle 内のサンプル画像を読み込む。
    func loadBundledSample() {
        guard let img = UIImage(named: "sample_chart") else { return }
        let doc = ChartDocument(
            id: UUID(),
            title: "Sample Chart",
            documentSize: img.size,
            source: .bundled(name: "sample_chart")
        )
        chartDocument = doc
        chartImage = img
        seedDummyMarkers(documentHeight: img.size.height)
    }

    /// ファイル URL から画像を読み込む（ドキュメントピッカー用）。
    func loadFromURL(_ url: URL) {
        guard url.startAccessingSecurityScopedResource() else { return }
        defer { url.stopAccessingSecurityScopedResource() }
        guard let data = try? Data(contentsOf: url),
              let img = UIImage(data: data) else { return }
        let doc = ChartDocument(
            id: UUID(),
            title: url.lastPathComponent,
            documentSize: img.size,
            source: .fileURL(url)
        )
        chartDocument = doc
        chartImage = img
        seedDummyMarkers(documentHeight: img.size.height)
    }

    // MARK: - Row Actions

    /// 現在行を stepCount 分進める。行インデックス・マーカー・チェックカウントをそれぞれ更新。
    func advanceRow() {
        let newIndex = currentRowIndex + stepCount
        rowIndexUndo.push(newIndex)

        var updatedMarkers = markers
        let prevIndex = newIndex - stepCount
        if prevIndex >= 0 && prevIndex < updatedMarkers.count {
            updatedMarkers[prevIndex].isChecked = true
        }
        markersUndo.push(updatedMarkers)

        checkCountUndo.push(checkCount + 1)
    }

    // MARK: - Independent Undo

    func undoRowIndex() { rowIndexUndo.undo() }
    func undoMarkers() { markersUndo.undo() }
    func undoCheckCount() { checkCountUndo.undo() }

    // MARK: - Private

    private func seedDummyMarkers(documentHeight: CGFloat) {
        var markers: [RowMarker] = []
        var y = startY
        while y < documentHeight {
            markers.append(RowMarker(yPosition: y))
            y += rowHeight
        }
        markersUndo.reset(to: markers)
        rowIndexUndo.reset(to: 0)
        checkCountUndo.reset(to: 0)
    }
}
