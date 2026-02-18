import SwiftUI

/// メイン画面。編み図ビューア + オーバーレイ + ツールバーを構成する。
struct ContentView: View {
    @StateObject private var viewModel = ChartViewModel()
    @State private var showDocumentPicker = false

    var body: some View {
        NavigationStack {
            ZStack {
                if let image = viewModel.chartImage {
                    chartViewerWithOverlay(image: image)
                } else {
                    emptyState
                }
            }
            .toolbar { toolbarContent }
            .sheet(isPresented: $showDocumentPicker) {
                DocumentPickerView { url in
                    viewModel.loadFromURL(url)
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
    private func chartViewerWithOverlay(image: UIImage) -> some View {
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

        ToolbarItem(placement: .topBarTrailing) {
            Button {
                showDocumentPicker = true
            } label: {
                Image(systemName: "folder.badge.plus")
            }
        }
    }
}
