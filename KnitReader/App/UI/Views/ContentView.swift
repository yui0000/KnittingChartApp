import SwiftUI
import PDFKit
import PencilKit
import SwiftData

/// メイン画面。編み図ビューア + オーバーレイ + ツールバーを構成する。
struct ContentView: View {
    @StateObject private var viewModel = ChartViewModel()
    @State private var showDocumentPicker = false
    @State private var isRowSettingsMode = false
    @State private var showHelp = false
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
            .navigationTitle("KnitReader")
            .navigationBarTitleDisplayMode(.inline)
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

            RowMarkerOverlayView(
                markers: viewModel.markers,
                currentRowIndex: viewModel.currentRowIndex,
                transform: viewModel.transform,
                viewportSize: viewModel.viewportSize,
                documentWidth: viewModel.chartDocument?.documentSize.width ?? 0
            )

            if isRowSettingsMode {
                RowSettingsOverlayView(
                    startY: $viewModel.startY,
                    rowHeight: $viewModel.rowHeight,
                    transform: viewModel.transform
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

            RowMarkerOverlayView(
                markers: viewModel.markers,
                currentRowIndex: viewModel.currentRowIndex,
                transform: viewModel.transform,
                viewportSize: viewModel.viewportSize,
                documentWidth: viewModel.chartDocument?.documentSize.width ?? 0
            )

            if isRowSettingsMode {
                RowSettingsOverlayView(
                    startY: $viewModel.startY,
                    rowHeight: $viewModel.rowHeight,
                    transform: viewModel.transform
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
        ToolbarItemGroup(placement: .bottomBar) {
            // 行カウンター
            Text("行 \(viewModel.currentRowIndex + 1) / \(viewModel.markers.count)")
                .font(.caption)
                .monospacedDigit()
                .accessibilityLabel("現在 \(viewModel.currentRowIndex + 1) 行目、全 \(viewModel.markers.count) 行")

            Spacer()

            // チェックカウント
            Text("\(viewModel.checkCount)")
                .font(.caption)
                .monospacedDigit()
                .accessibilityLabel("チェック数 \(viewModel.checkCount)")

            Spacer()

            // 手書きモードトグル
            Button {
                viewModel.isPencilMode.toggle()
            } label: {
                Image(systemName: "pencil.tip")
                    .foregroundStyle(viewModel.isPencilMode ? Color.accentColor : Color.primary)
            }
            .disabled(isRowSettingsMode)
            .accessibilityLabel(viewModel.isPencilMode ? "手書きモードをオフにする" : "手書きモードをオンにする")
            .keyboardShortcut("p", modifiers: .command)

            // 手書きクリア
            Button {
                viewModel.clearDrawing()
            } label: {
                Image(systemName: "trash")
            }
            .disabled(viewModel.drawingData == nil || isRowSettingsMode)
            .accessibilityLabel("手書きメモをクリア")

            Spacer()

            // Undo メニュー
            Menu {
                Button("行を戻す") {
                    viewModel.undoRowIndex()
                }
                .disabled(!viewModel.rowIndexUndo.canUndo)

                Button("マーカーを戻す") {
                    viewModel.undoMarkers()
                }
                .disabled(!viewModel.markersUndo.canUndo)

                Button("カウントを戻す") {
                    viewModel.undoCheckCount()
                }
                .disabled(!viewModel.checkCountUndo.canUndo)
            } label: {
                Image(systemName: "arrow.uturn.backward")
            }
            .accessibilityLabel("元に戻す")

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
            .keyboardShortcut(.return, modifiers: [])
        }

        ToolbarItem(placement: .topBarLeading) {
            if isRowSettingsMode {
                Button("完了") {
                    viewModel.applyRowSettings()
                    isRowSettingsMode = false
                }
                .fontWeight(.semibold)
                .accessibilityLabel("行設定を確定する")
            } else {
                Button {
                    isRowSettingsMode = true
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
                        showDocumentPicker = true
                    } label: {
                        Image(systemName: "folder.badge.plus")
                    }
                    .accessibilityLabel("ファイルを開く")
                }
            }
        }
    }
}
