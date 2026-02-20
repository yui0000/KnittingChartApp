import SwiftUI
import PencilKit

/// PKCanvasView を UIViewRepresentable でラップする手書きメモブリッジ。
///
/// - `drawingData`: 描画データを Binding で保持。nil のときはキャンバスをクリアする。
/// - `isPencilMode`: true のとき firstResponder を保持してタッチを捕捉。
///                   false のとき resignFirstResponder でスクロールに透過。
/// - ヒットテストの制御は呼び出し側の `.allowsHitTesting(isPencilMode)` に委ねる。
struct PencilCanvasBridge: UIViewRepresentable {
    @Binding var drawingData: Data?
    let isPencilMode: Bool

    func makeUIView(context: Context) -> PKCanvasView {
        let canvasView = PKCanvasView()
        canvasView.drawingPolicy = .anyInput
        canvasView.backgroundColor = .clear
        canvasView.isOpaque = false
        canvasView.delegate = context.coordinator

        // PKToolPicker を生成して Coordinator に保持させる
        let toolPicker = PKToolPicker()
        toolPicker.addObserver(canvasView)
        context.coordinator.toolPicker = toolPicker

        return canvasView
    }

    func updateUIView(_ canvasView: PKCanvasView, context: Context) {
        // クリア操作（drawingData == nil）のときのみキャンバスをリセット
        // それ以外は canvasViewDrawingDidChange → drawingData の一方向のみ更新し
        // updateUIView → canvasView 書き換えの無限ループを防ぐ
        if drawingData == nil {
            context.coordinator.isResettingCanvas = true
            canvasView.drawing = PKDrawing()
            context.coordinator.isResettingCanvas = false
        }

        // isPencilMode に応じて firstResponder を制御
        if isPencilMode {
            if !canvasView.isFirstResponder {
                canvasView.becomeFirstResponder()
                context.coordinator.toolPicker?.setVisible(true, forFirstResponder: canvasView)
            }
        } else {
            if canvasView.isFirstResponder {
                context.coordinator.toolPicker?.setVisible(false, forFirstResponder: canvasView)
                canvasView.resignFirstResponder()
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    // MARK: - Coordinator

    final class Coordinator: NSObject, PKCanvasViewDelegate {
        var parent: PencilCanvasBridge
        /// PKToolPicker は strong 参照で保持しないと即座に解放される
        var toolPicker: PKToolPicker?
        /// クリア操作中は canvasViewDrawingDidChange を無視するフラグ
        var isResettingCanvas = false

        init(parent: PencilCanvasBridge) {
            self.parent = parent
        }

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            guard !isResettingCanvas else { return }
            parent.drawingData = canvasView.drawing.dataRepresentation()
        }
    }
}
