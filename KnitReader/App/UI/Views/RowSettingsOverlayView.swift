import SwiftUI

/// 行設定モード時に表示するインタラクティブな黄色線オーバーレイ。
///
/// - Step 1 (`isEndStep == false`): ドラッグで始点Y（startY）、ピンチで行幅（rowHeight）を調整。
/// - Step 2 (`isEndStep == true`): ドラッグで終了Y（endY）を調整。終了ラインをオレンジで表示。
/// - 画像・PDF 両座標系に対応（CoordinateTransform 経由）。
struct RowSettingsOverlayView: View {
    @Binding var startY: CGFloat
    @Binding var rowHeight: CGFloat
    @Binding var endY: CGFloat
    let transform: CoordinateTransform
    let isEndStep: Bool

    @GestureState private var dragDelta: CGFloat = 0
    @GestureState private var pinchScale: CGFloat = 1.0

    /// ビュー座標での行幅（Step 1: ピンチスケール込み、Step 2: 固定）
    private var rowHeightInView: CGFloat {
        let scale = isEndStep ? CGFloat(1.0) : pinchScale
        return max(8, rowHeight * scale * transform.zoomScale)
    }

    /// 行間方向（画像: 下向き +、PDF: 上向き −）
    private var stepInView: CGFloat {
        transform.pageHeight > 0 ? -rowHeightInView : rowHeightInView
    }

    var body: some View {
        ZStack(alignment: .top) {
            Canvas { context, size in
                drawOverlay(context: &context, size: size)
            }
            .contentShape(Rectangle())
            .gesture(dragGesture)
            .simultaneousGesture(pinchGesture)

            instructionLabel
        }
    }

    // MARK: - Canvas Drawing

    private func drawOverlay(context: inout GraphicsContext, size: CGSize) {
        let yellow = GraphicsContext.Shading.color(.yellow)
        let lineStyle = StrokeStyle(lineWidth: 1.5)

        // Step 1: startY がドラッグで動く / Step 2: startY 固定
        let originY: CGFloat = transform.documentToViewY(startY) + (isEndStep ? 0 : dragDelta)
        let step = stepInView

        // Step 1 のみ最初の行帯をハイライト
        if !isEndStep {
            let bandH = abs(step)
            let bandY = min(originY, originY + step)
            if bandH > 0 && bandY < size.height && bandY + bandH > 0 {
                context.fill(
                    Path(CGRect(x: 0, y: bandY, width: size.width, height: bandH)),
                    with: .color(.yellow.opacity(0.25))
                )
            }
        }

        // 始点から順方向に行線を描画
        var y = originY
        var count = 0
        while count < 200 && y >= -1 && y <= size.height + 1 {
            strokeLine(context: &context, y: y, size: size, shading: yellow, style: lineStyle)
            y += step
            count += 1
        }

        // 始点から逆方向に行線を描画
        y = originY - step
        count = 0
        while count < 200 && y >= -1 && y <= size.height + 1 {
            strokeLine(context: &context, y: y, size: size, shading: yellow, style: lineStyle)
            y -= step
            count += 1
        }

        // Step 2: 終了ラインをオレンジで強調表示
        if isEndStep {
            let endViewY = transform.documentToViewY(endY) + dragDelta
            strokeLine(
                context: &context, y: endViewY, size: size,
                shading: .color(.orange),
                style: StrokeStyle(lineWidth: 2.5)
            )
        }
    }

    private func strokeLine(
        context: inout GraphicsContext, y: CGFloat, size: CGSize,
        shading: GraphicsContext.Shading, style: StrokeStyle
    ) {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: y))
        path.addLine(to: CGPoint(x: size.width, y: y))
        context.stroke(path, with: shading, style: style)
    }

    // MARK: - Gestures

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .updating($dragDelta) { value, state, _ in
                state = value.translation.height
            }
            .onEnded { value in
                if isEndStep {
                    let baseViewY = transform.documentToViewY(endY)
                    let newViewY = baseViewY + value.translation.height
                    endY = max(startY + rowHeight, transform.viewToDocumentY(newViewY))
                } else {
                    let baseViewY = transform.documentToViewY(startY)
                    let newViewY = baseViewY + value.translation.height
                    startY = max(0, transform.viewToDocumentY(newViewY))
                }
            }
    }

    private var pinchGesture: some Gesture {
        MagnifyGesture()
            .updating($pinchScale) { value, state, _ in
                state = value.magnification
            }
            .onEnded { value in
                if !isEndStep {
                    rowHeight = max(1, rowHeight * value.magnification)
                }
            }
    }

    // MARK: - Instruction Label

    private var instructionLabel: some View {
        Text(isEndStep ? "行の終了を設定してください" : "行の開始と幅を設定してください")
            .font(.headline)
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(.black.opacity(0.6))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .padding(.top, 16)
    }
}
