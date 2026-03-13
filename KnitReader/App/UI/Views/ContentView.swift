import SwiftUI
import PDFKit
import PencilKit
import PhotosUI
import SwiftData

/// メイン画面。編み図ビューア + オーバーレイ + ツールバーを構成する。
struct ContentView: View {
    @StateObject private var viewModel = ChartViewModel()
    @State private var showDocumentPicker = false
    @State private var showPhotosPicker = false
    @State private var showSourceOptions = false
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    /// 0: 通常, 1: 行の開始と幅を設定, 2: 行の終了を設定
    @State private var rowSettingsStep = 0
    @State private var showHelp = false
    // 行設定モード開始時の値を保存（キャンセル時に復元）
    @State private var savedStartY: CGFloat = 0
    @State private var savedEndY: CGFloat = 0
    @State private var savedRowHeight: CGFloat = 0

    private var isRowSettingsMode: Bool { rowSettingsStep > 0 }
    @State private var showResetOptions = false

    private func enterRowSettings() {
        savedStartY = viewModel.startY
        savedEndY = viewModel.endY
        savedRowHeight = viewModel.rowHeight
        viewModel.prepareForRowSettings()
        rowSettingsStep = 1
    }

    private func cancelRowSettings() {
        viewModel.startY = savedStartY
        viewModel.endY = savedEndY
        viewModel.rowHeight = savedRowHeight
        rowSettingsStep = 0
    }
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        NavigationStack {
            ZStack {
                chartContent
            }
            .toolbar { toolbarContent }
            .sheet(isPresented: $showDocumentPicker) {
                DocumentPickerView { url in
                    if url.pathExtension.lowercased() == "pdf" {
                        viewModel.loadPDFFromURL(url)
                    } else {
                        viewModel.loadFromURL(url)
                    }
                }
            }
            .sheet(isPresented: $showHelp) {
                HelpView()
            }
            .alert(
                "読み込みエラー",
                isPresented: Binding(
                    get: { viewModel.loadError != nil },
                    set: { if !$0 { viewModel.loadError = nil } }
                )
            ) {
                Button("OK", role: .cancel) { viewModel.loadError = nil }
            } message: {
                Text(viewModel.loadError ?? "")
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .photosPicker(isPresented: $showPhotosPicker, selection: $selectedPhotoItem, matching: .images)
            .onChange(of: selectedPhotoItem) { _, item in
                guard let item else { return }
                Task {
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let img = UIImage(data: data) {
                        await MainActor.run {
                            viewModel.loadFromImage(img)
                        }
                    }
                    await MainActor.run { selectedPhotoItem = nil }
                }
            }
        }
        .task {
            viewModel.configure(
                repository: SwiftDataChartRepository(modelContext: modelContext)
            )
            viewModel.loadBundledSample()
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private var chartContent: some View {
        if let pdfDoc = viewModel.pdfDocument {
            pdfViewerWithOverlay(pdfDocument: pdfDoc)
        } else if let image = viewModel.chartImage {
            imageViewerWithOverlay(image: image)
        } else {
            emptyState
        }
    }

    @ViewBuilder
    private func imageViewerWithOverlay(image: UIImage) -> some View {
        ZStack {
            ScrollViewBridge(
                image: image,
                zoomScale: $viewModel.zoomScale,
                contentOffset: $viewModel.contentOffset,
                viewportSize: $viewModel.viewportSize
            )

            if !isRowSettingsMode {
                RowMarkerOverlayView(
                    markers: viewModel.markers,
                    currentRowIndex: viewModel.currentRowIndex,
                    transform: viewModel.transform,
                    viewportSize: viewModel.viewportSize,
                    documentWidth: viewModel.chartDocument?.documentSize.width ?? 0,
                    rowHeight: viewModel.rowHeight,
                    onToggleMarker: { viewModel.toggleMarker(at: $0) }
                )
            }

            if rowSettingsStep > 0 {
                RowSettingsOverlayView(
                    startY: $viewModel.startY,
                    rowHeight: $viewModel.rowHeight,
                    endY: $viewModel.endY,
                    transform: viewModel.transform,
                    isEndStep: rowSettingsStep == 2
                )
            }

            PencilCanvasBridge(
                drawingData: $viewModel.drawingData,
                isPencilMode: viewModel.isPencilMode
            )
            .allowsHitTesting(viewModel.isPencilMode)
        }
        .ignoresSafeArea(edges: .bottom)
    }

    @ViewBuilder
    private func pdfViewerWithOverlay(pdfDocument: PDFDocument) -> some View {
        ZStack {
            PDFViewBridge(
                document: pdfDocument,
                scaleFactor: $viewModel.zoomScale,
                contentOffset: $viewModel.contentOffset,
                viewportSize: $viewModel.viewportSize,
                pageHeight: $viewModel.pageHeight
            )

            if !isRowSettingsMode {
                RowMarkerOverlayView(
                    markers: viewModel.markers,
                    currentRowIndex: viewModel.currentRowIndex,
                    transform: viewModel.transform,
                    viewportSize: viewModel.viewportSize,
                    documentWidth: viewModel.chartDocument?.documentSize.width ?? 0,
                    rowHeight: viewModel.rowHeight,
                    onToggleMarker: { viewModel.toggleMarker(at: $0) }
                )
            }

            if rowSettingsStep > 0 {
                RowSettingsOverlayView(
                    startY: $viewModel.startY,
                    rowHeight: $viewModel.rowHeight,
                    endY: $viewModel.endY,
                    transform: viewModel.transform,
                    isEndStep: rowSettingsStep == 2
                )
            }

            PencilCanvasBridge(
                drawingData: $viewModel.drawingData,
                isPencilMode: viewModel.isPencilMode
            )
            .allowsHitTesting(viewModel.isPencilMode)
        }
        .ignoresSafeArea(edges: .bottom)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.image")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("編み図を読み込んでください")
                .foregroundStyle(.secondary)
            Button("ファイルから読み込む") {
                showDocumentPicker = true
            }
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            HStack(spacing: 24) {
                Text("行 \(viewModel.markers.count - viewModel.currentRowIndex) / \(viewModel.markers.count)")
                    .font(.callout)
                    .monospacedDigit()
                    .accessibilityLabel("現在 \(viewModel.markers.count - viewModel.currentRowIndex) 行目、全 \(viewModel.markers.count) 行")
                Text("\(viewModel.checkCount)")
                    .font(.title3)
                    .monospacedDigit()
                    .accessibilityLabel("チェック数 \(viewModel.checkCount)")
            }
        }

        ToolbarItemGroup(placement: .bottomBar) {
            // 手書きモードトグル
            Button {
                viewModel.isPencilMode.toggle()
            } label: {
                Image(systemName: "pencil.tip")
                    .foregroundStyle(viewModel.isPencilMode ? Color.accentColor : Color.primary)
            }
            .disabled(isRowSettingsMode)
            .accessibilityLabel(viewModel.isPencilMode ? "手書きモードをオフにする" : "手書きモードをオンにする")

            Spacer()

            // - ボタン（1行戻る）
            Button {
                viewModel.decrementCheckCount()
            } label: {
                Image(systemName: "minus.circle.fill")
                    .font(.title2)
            }
            .disabled(viewModel.checkCount == 0 || isRowSettingsMode)
            .accessibilityLabel("カウントを減らす")
            .accessibilityHint("カウントを1減らします")

             // + ボタン（行を進める）
             Button {
                 viewModel.advanceRow()
             } label: {
                 Image(systemName: "plus.circle.fill")
                     .font(.title2)
             }
             .disabled(isRowSettingsMode)
             .accessibilityLabel("次の行に進む")
             .accessibilityHint("現在行をチェック済みにして次の行へ進みます")

            Spacer()

            // 行・チェックリセット
            Button {
                showResetOptions = true
            } label: {
                Image(systemName: "arrow.counterclockwise.circle")
            }
            .disabled(viewModel.markers.isEmpty || isRowSettingsMode)
            .accessibilityLabel("リセット")
            .confirmationDialog("リセットの種類を選択", isPresented: $showResetOptions, titleVisibility: .visible) {
                Button("すべて", role: .destructive) {
                    viewModel.resetRowsAndChecks()
                }
                Button("行位置のみ") {
                    viewModel.resetRowsOnly()
                }
                Button("手書きメモ") {
                    viewModel.clearDrawing()
                }
                Button("キャンセル", role: .cancel) { }
            } message: {
                Text("「すべて」はカウント・チェック・行を初期化します。「行位置のみ」はカウントを保持してチェックと行を初期化します。「手書きメモ」は手書きメモを消去します。")
            }
        }

        ToolbarItem(placement: .topBarLeading) {
            if rowSettingsStep == 1 {
                HStack(spacing: 16) {
                    Button("キャンセル") {
                        cancelRowSettings()
                    }
                    .foregroundStyle(.secondary)
                    Button("次へ") {
                        rowSettingsStep = 2
                    }
                    .fontWeight(.semibold)
                    .accessibilityLabel("終了位置の設定へ進む")
                }
            } else if rowSettingsStep == 2 {
                HStack(spacing: 16) {
                    Button("キャンセル") {
                        cancelRowSettings()
                    }
                    .foregroundStyle(.secondary)
                    Button("完了") {
                        viewModel.applyRowSettings()
                        rowSettingsStep = 0
                    }
                    .fontWeight(.semibold)
                    .accessibilityLabel("行設定を確定する")
                }
            } else {
                Button {
                    enterRowSettings()
                } label: {
                    Image(systemName: "slider.horizontal.3")
                }
                .disabled(viewModel.chartDocument == nil || viewModel.isPencilMode)
                .accessibilityLabel("行の設定")
            }
        }

        ToolbarItem(placement: .topBarTrailing) {
            if viewModel.isPencilMode {
                Button("完了") {
                    viewModel.isPencilMode = false
                }
                .fontWeight(.semibold)
                .accessibilityLabel("手書きモードを終了する")
            } else {
                HStack {
                    Button {
                        showHelp = true
                    } label: {
                        Image(systemName: "questionmark.circle")
                    }
                    .accessibilityLabel("ヘルプ")

                    Button {
                        showSourceOptions = true
                    } label: {
                        Image(systemName: "folder.badge.plus")
                    }
                    .accessibilityLabel("ファイルを開く")
                    .confirmationDialog("読み込み元を選択", isPresented: $showSourceOptions) {
                        Button("ファイルから") { showDocumentPicker = true }
                        Button("写真から") { showPhotosPicker = true }
                        Button("キャンセル", role: .cancel) { }
                    }
                }
            }
        }
    }
}
