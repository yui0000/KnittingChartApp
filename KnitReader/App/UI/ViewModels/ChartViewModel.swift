import SwiftUI
import Combine
import PDFKit

/// 編み図ビューアの中央 ViewModel。
///
/// 3つの独立 Undo スタック（行インデックス / マーカー / チェックカウント）を管理し、
/// 座標変換パラメータを ScrollViewBridge / PDFViewBridge から受け取る。
/// `configure(repository:)` 呼び出し後に AutoSave が有効になる。
@MainActor
final class ChartViewModel: ObservableObject {
    // MARK: - Document State

    @Published var chartDocument: ChartDocument?
    @Published var chartImage: UIImage?
    @Published var pdfDocument: PDFDocument?

    // MARK: - Scroll / Zoom State（Bridge から Binding で更新）

    @Published var zoomScale: CGFloat = 1.0
    @Published var contentOffset: CGPoint = .zero
    @Published var viewportSize: CGSize = .zero

    // MARK: - PDF State

    /// PDF ページ高さ（ポイント）。画像のときは 0。PDFViewBridge が更新する。
    @Published var pageHeight: CGFloat = 0

    // MARK: - Row Configuration

    @Published var startY: CGFloat = 100
    @Published var rowHeight: CGFloat = 40
    @Published var endY: CGFloat = 1000
    @Published var stepCount: Int = 1

    // MARK: - PencilKit State

    @Published var drawingData: Data? = nil
    @Published var isPencilMode: Bool = false

    // MARK: - Error State

    /// ファイル読み込み失敗時のエラーメッセージ。nil のときはエラーなし。
    @Published var loadError: String? = nil

    // MARK: - Independent Undo Stacks

    let rowIndexUndo = UndoStack<Int>(initial: 0)
    let markersUndo = UndoStack<[RowMarker]>(initial: [])
    let checkCountUndo = UndoStack<Int>(initial: 0)

    // MARK: - Repository

    private var repository: (any ChartRepository)?
    private var isRepositoryConfigured = false
    /// 現在開いているファイルのセキュアブックマークデータ
    private var currentBookmarkData: Data?
    /// 現在開いているファイルの URL 文字列（バンドルサンプルは nil）
    private var currentFileURLString: String?

    // MARK: - Computed

    var transform: CoordinateTransform {
        CoordinateTransform(
            zoomScale: zoomScale,
            contentOffset: contentOffset,
            pageHeight: pageHeight
        )
    }

    var currentRowIndex: Int { rowIndexUndo.current }
    var markers: [RowMarker] { markersUndo.current }
    var checkCount: Int { checkCountUndo.current }

    // MARK: - Configure

    /// リポジトリを一度だけ注入する（ContentView の .task から呼ぶ）。
    func configure(repository: any ChartRepository) {
        guard !isRepositoryConfigured else { return }
        self.repository = repository
        isRepositoryConfigured = true
    }

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
        pdfDocument = nil
        pageHeight = 0
        currentBookmarkData = nil
        currentFileURLString = nil
        drawingData = nil
        endY = img.size.height
        seedDummyMarkers(documentHeight: img.size.height)
    }

    /// ファイル URL から画像を読み込む（ドキュメントピッカー用）。
    func loadFromURL(_ url: URL) {
        let urlString = url.absoluteString
        guard url.startAccessingSecurityScopedResource() else {
            loadError = "ファイルへのアクセス権限がありません。"
            return
        }
        defer { url.stopAccessingSecurityScopedResource() }
        guard let data = try? Data(contentsOf: url),
              let img = UIImage(data: data) else {
            loadError = "画像を読み込めませんでした。\(url.lastPathComponent) が対応フォーマットか確認してください。"
            return
        }

        let bookmarkData = try? url.bookmarkData()

        Task {
            // 既存の進捗を検索して 1:1 紐付け
            let existing = try? await repository?.findProgress(byFileURL: urlString)
            let docID = existing?.documentID ?? UUID()
            let doc = ChartDocument(
                id: docID,
                title: url.lastPathComponent,
                documentSize: img.size,
                source: .fileURL(url)
            )
            chartDocument = doc
            chartImage = img
            pdfDocument = nil
            pageHeight = 0
            currentBookmarkData = bookmarkData
            currentFileURLString = urlString
            endY = img.size.height

            if let existing {
                restoreProgress(existing)
            } else {
                seedDummyMarkers(documentHeight: img.size.height)
                saveProgress()
            }
        }
    }

    /// PDF URL から 1 ページ目を読み込む（ドキュメントピッカー用）。
    func loadPDFFromURL(_ url: URL) {
        let urlString = url.absoluteString
        guard url.startAccessingSecurityScopedResource() else {
            loadError = "ファイルへのアクセス権限がありません。"
            return
        }
        defer { url.stopAccessingSecurityScopedResource() }
        guard let pdf = PDFDocument(url: url),
              let firstPage = pdf.page(at: 0) else {
            loadError = "PDF を読み込めませんでした。\(url.lastPathComponent) が正しい PDF ファイルか確認してください。"
            return
        }

        let pageBounds = firstPage.bounds(for: .mediaBox)
        let docSize = pageBounds.size
        let bookmarkData = try? url.bookmarkData()

        Task {
            let existing = try? await repository?.findProgress(byFileURL: urlString)
            let docID = existing?.documentID ?? UUID()
            let doc = ChartDocument(
                id: docID,
                title: url.lastPathComponent,
                documentSize: docSize,
                source: .pdfURL(url)
            )
            chartDocument = doc
            pdfDocument = pdf
            chartImage = nil
            pageHeight = docSize.height
            currentBookmarkData = bookmarkData
            currentFileURLString = urlString
            endY = docSize.height

            if let existing {
                restoreProgress(existing)
            } else {
                seedDummyMarkers(documentHeight: docSize.height)
                saveProgress()
            }
        }
    }

    // MARK: - Row Actions

    /// 現在行を 1 行進める（上方向）。現在行をチェック済みにし、チェックカウントを +1 する。
    /// マーカーは上から下（インデックス増加）の順に並ぶため、「上へ進む」はインデックスを減らす操作。
    func advanceRow() {
        let oldIndex = currentRowIndex  // push 前に確定しておく
        guard oldIndex >= 0 && oldIndex < markers.count else { return }
        objectWillChange.send()

        var updatedMarkers = markers
        updatedMarkers[oldIndex].isChecked = true
        markersUndo.push(updatedMarkers)

        // 上方向へ移動（インデックス減少）
        rowIndexUndo.push(max(0, oldIndex - 1))

        checkCountUndo.push(checkCount + 1)
        saveProgress()
    }

    /// 1行前（下方向）に戻る。チェックカウントを −1、行線を下に1行分移動し、戻った行のチェックを外す。
    /// 例外: 最上行（index 0）かつ最上行にチェックが入っている場合は行を動かさずチェックだけ外す。
    func decrementCheckCount() {
        guard checkCount > 0 else { return }
        objectWillChange.send()

        var updatedMarkers = markers

        if currentRowIndex == 0 && markers.first?.isChecked == true {
            // 一番上の行でチェック済み → 行はそのままでチェックだけ外す
            updatedMarkers[0].isChecked = false
            markersUndo.push(updatedMarkers)
            // rowIndexUndo は変更なし（index 0 のまま）
        } else {
            // 通常: 下方向へ移動（インデックス増加）して戻った行のチェックを外す
            let newIndex = min(currentRowIndex + 1, markers.count - 1)
            rowIndexUndo.push(newIndex)
            updatedMarkers[newIndex].isChecked = false
            markersUndo.push(updatedMarkers)
        }

        checkCountUndo.push(checkCount - 1)
        saveProgress()
    }

    /// 指定インデックスのマーカーの isChecked をトグルする。
    /// 行番号（currentRowIndex）は変更しない。
    func toggleMarker(at index: Int) {
        guard index >= 0 && index < markers.count else { return }
        objectWillChange.send()
        var updatedMarkers = markers
        updatedMarkers[index].isChecked.toggle()
        markersUndo.push(updatedMarkers)
        saveProgress()
    }

    // MARK: - Independent Undo

    func undoRowIndex() { objectWillChange.send(); rowIndexUndo.undo(); saveProgress() }
    func undoMarkers() { objectWillChange.send(); markersUndo.undo(); saveProgress() }
    func undoCheckCount() { objectWillChange.send(); checkCountUndo.undo(); saveProgress() }

    // MARK: - Drawing Actions

    /// 手書きメモをクリアする。
    func clearDrawing() {
        drawingData = nil
        saveProgress()
    }

    // MARK: - Settings Actions

    /// 現在の startY / rowHeight / endY でマーカーを再生成し、Undo履歴をリセットする。
    func applyRowSettings() {
        guard let doc = chartDocument else { return }
        seedDummyMarkers(documentHeight: doc.documentSize.height)
        saveProgress()
    }

    /// 行設定モード開始時に既存マーカーから startY / endY を初期化する。
    /// Image モード: startY = 最下行（最大Y）、endY = 最上行（最小Y）
    /// PDF モード:   startY = 最下行（最小PDF-Y）、endY = 最上行（最大PDF-Y）
    func prepareForRowSettings() {
        guard !markers.isEmpty else { return }
        let minY = markers.map(\.yPosition).min()!
        let maxY = markers.map(\.yPosition).max()!
        if pageHeight > 0 {
            // PDF: Y 上向き → 小さい Y = 下（knitting 開始点）
            startY = minY
            endY = maxY
        } else {
            // Image: Y 下向き → 大きい Y = 下（knitting 開始点）
            startY = maxY
            endY = minY
        }
    }

    /// 【すべて】カウント・チェック・行インデックスをすべてリセットする。
    func resetRowsAndChecks() {
        guard !markers.isEmpty else { return }
        objectWillChange.send()
        let resetMarkers = markers.map { RowMarker(yPosition: $0.yPosition, isChecked: false) }
        markersUndo.push(resetMarkers)
        rowIndexUndo.push(max(0, markers.count - 1))
        checkCountUndo.push(0)
        saveProgress()
    }

    /// 【行位置のみ】チェックと行インデックスのみリセットする。カウントは保持する。
    func resetRowsOnly() {
        guard !markers.isEmpty else { return }
        objectWillChange.send()
        let resetMarkers = markers.map { RowMarker(yPosition: $0.yPosition, isChecked: false) }
        markersUndo.push(resetMarkers)
        rowIndexUndo.push(max(0, markers.count - 1))
        saveProgress()
    }

    // MARK: - AutoSave

    private func saveProgress() {
        guard let doc = chartDocument, let repository else { return }
        let dto = DocumentProgressDTO(
            documentID: doc.id,
            currentRowIndex: currentRowIndex,
            markers: markers,
            checkCount: checkCount,
            bookmarkData: currentBookmarkData,
            drawingData: drawingData,
            fileURLString: currentFileURLString
        )
        Task {
            try? await repository.saveProgress(dto)
        }
    }

    // MARK: - Private

    private func restoreProgress(_ dto: DocumentProgressDTO) {
        markersUndo.reset(to: dto.markers)
        rowIndexUndo.reset(to: dto.currentRowIndex)
        checkCountUndo.reset(to: dto.checkCount)
        drawingData = dto.drawingData
    }

    private func seedDummyMarkers(documentHeight: CGFloat) {
        // startY と endY の大小にかかわらず min→max 方向で生成（常に昇順）
        let lo = min(startY, endY)
        let hi = min(max(startY, endY), documentHeight)
        var markers: [RowMarker] = []
        var y = lo
        while y <= hi {
            markers.append(RowMarker(yPosition: y))
            y += rowHeight
        }
        markersUndo.reset(to: markers)
        // 編み物は下（末尾）から読み始めるため、最後のインデックスを初期位置にする
        rowIndexUndo.reset(to: max(0, markers.count - 1))
        checkCountUndo.reset(to: 0)
    }
}
