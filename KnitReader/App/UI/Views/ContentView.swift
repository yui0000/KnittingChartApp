import SwiftUI
import PDFKit
import PencilKit

/// メイン画面。編み図ビューア + オーバーレイ + ツールバーを構成する。
struct ContentView: View {
    @StateObject private var viewModel = ChartViewModel()
    @State private var showDocumentPicker = false
    @State private var showRowSettings = false

    var body: some View {
        NavigationStack {
            ZStack {
                chartContent
            }
            .toolbar { toolbarContent }
            .sheet(isPresented: $showRowSettings) {
                RowSettingsView(
                    startY: $viewModel.startY,
                    rowHeight: $viewModel.rowHeight,
                    stepCount: $viewModel.stepCount
                ) {
                    viewModel.applyRowSettings()
                    showRowSettings = false
                }
            }
            .sheet(isPresented: $showDocumentPicker) {
                DocumentPickerView { url in
                    if url.pathExtension.lowercased() == "pdf" {
                        viewModel.loadPDFFromURL(url)
                    } else {
                        viewModel.loadFromURL(url)
                    }
                }
            }
            .navigationTitle("KnitReader")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
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

            Spacer()

            // チェックカウント
            Text("\(viewModel.checkCount)")
                .font(.caption)
                .monospacedDigit()

            Spacer()

            // 手書きモードトグル
            Button {
                viewModel.isPencilMode.toggle()
            } label: {
                Image(systemName: "pencil.tip")
                    .foregroundStyle(viewModel.isPencilMode ? Color.blue : Color.primary)
            }

            // 手書きクリア
            Button {
                viewModel.clearDrawing()
            } label: {
                Image(systemName: "trash")
            }
            .disabled(viewModel.drawingData == nil)

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

            // + ボタン（行を進める）
            Button {
                viewModel.advanceRow()
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
            }
        }

        ToolbarItem(placement: .topBarLeading) {
            Button {
                showRowSettings = true
            } label: {
                Image(systemName: "slider.horizontal.3")
            }
            .disabled(viewModel.chartDocument == nil)
        }

        ToolbarItem(placement: .topBarTrailing) {
            Button {
                showDocumentPicker = true
            } label: {
                Image(systemName: "folder.badge.plus")
            }
        }
    }
}
