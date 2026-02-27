import SwiftUI

/// 行設定モード時に表示するインタラクティブな黄色線オーバーレイ。
///
/// - ドラッグで始点 Y（startY）を調整する。
/// - ピンチで行幅（rowHeight）を調整する。
/// - 画像・PDF 両座標系に対応（CoordinateTransform 経由）。
struct RowSettingsOverlayView: View {
    @Binding var startY: CGFloat
    @Binding var rowHeight: CGFloat
    let transform: CoordinateTransform

    @GestureState private var dragDelta: CGFloat = 0
    @GestureState private var pinchScale: CGFloat = 1.0

    /// ドラッグ中の始点ビュー座標 Y
    private var currentViewY: CGFloat {
        transform.documentToViewY(startY) + dragDelta
    }

    /// ビュー座標での行幅（ピンチスケール込み、最小 8pt）
    private var rowHeightInView: CGFloat {
        max(8, rowHeight * pinchScale * transform.zoomScale)
    }

    /// ビュー座標での行間方向
    /// - 画像モード: 下向き（+）
    /// - PDF モード: 上向き（−）※ PDF は Y 上向きのため
    private var stepInView: CGFloat {
        transform.pageHeight > 0 ? -rowHeightInView : rowHeightInView
    }

    var body: some View {
        Canvas { context, size in
            let y0 = currentViewY
            let step = stepInView
            let yellow = GraphicsContext.Shading.color(.yellow)
            let lineStyle = StrokeStyle(lineWidth: 1.5)

            // 最初の行帯をハイライト
            let bandH = abs(step)
            let bandY = min(y0, y0 + step)
            if bandH > 0 && bandY < size.height && bandY + bandH > 0 {
                let rect = CGRect(x: 0, y: bandY, width: size.width, height: bandH)
                context.fill(Path(rect), with: .color(.yellow.opacity(0.25)))
            }

            // 始点から順方向に行線を描画
            var y = y0
            var count = 0
            while count < 200 && y >= -1 && y <= size.height + 1 {
                var path = Path()
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
                context.stroke(path, with: yellow, style: lineStyle)
                y += step
                count += 1
            }

            // 始点から逆方向に行線を描画（画面上方に見切れた行を表示）
            y = y0 - step
            count = 0
            while count < 200 && y >= -1 && y <= size.height + 1 {
                var path = Path()
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
                context.stroke(path, with: yellow, style: lineStyle)
                y -= step
                count += 1
            }
        }
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .updating($dragDelta) { value, state, _ in
                    state = value.translation.height
                }
                .onEnded { value in
                    let baseViewY = transform.documentToViewY(startY)
                    let newViewY = baseViewY + value.translation.height
                    startY = max(0, transform.viewToDocumentY(newViewY))
                }
        )
        .simultaneousGesture(
            MagnifyGesture()
                .updating($pinchScale) { value, state, _ in
                    state = value.magnification
                }
                .onEnded { value in
                    rowHeight = max(1, rowHeight * value.magnification)
                }
        )
    }
}
