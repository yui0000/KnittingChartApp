import SwiftUI

/// 行マーカーをドキュメント座標からビュー座標に投影して描画するオーバーレイ。
///
/// - 半透明の黄色い水平線を各行マーカーの Y 位置に描画する。
/// - 現在行は黄色バンドでハイライト表示する。
/// - 各行左端にチェックボックスアイコンを表示し、タップで isChecked をトグルできる。
struct RowMarkerOverlayView: View {
    let markers: [RowMarker]
    let currentRowIndex: Int
    let transform: CoordinateTransform
    let viewportSize: CGSize
    let documentWidth: CGFloat
    let rowHeight: CGFloat
    var onToggleMarker: ((Int) -> Void)?

    private let checkboxHitWidth: CGFloat = 48
    private let checkboxCenterX: CGFloat = 24

    var body: some View {
        Canvas { context, size in
            drawRows(context: &context, size: size)
        } symbols: {
            Image(systemName: "checkmark.square.fill")
                .foregroundStyle(Color.yellow)
                .font(.system(size: 16, weight: .medium))
                .tag(0)
            Image(systemName: "square")
                .foregroundStyle(Color.yellow.opacity(0.6))
                .font(.system(size: 16, weight: .medium))
                .tag(1)
        }
        .allowsHitTesting(false)
        .overlay(alignment: .leading) {
            Color.clear
                .frame(width: checkboxHitWidth)
                .frame(maxHeight: .infinity)
                .contentShape(Rectangle())
                .onTapGesture(coordinateSpace: .local) { location in
                    handleCheckboxTap(at: location.y)
                }
        }
        .accessibilityHidden(true)
    }

    private func drawRows(context: inout GraphicsContext, size: CGSize) {
        let checkedSym = context.resolveSymbol(id: 0)
        let uncheckedSym = context.resolveSymbol(id: 1)
        let lineStyle = StrokeStyle(lineWidth: 1.5)
        let rowHeightInView = max(8, rowHeight * transform.zoomScale)

        // 現在行のバンドハイライト
        if currentRowIndex < markers.count {
            let y0 = transform.documentToViewY(markers[currentRowIndex].yPosition)
            let step: CGFloat = transform.pageHeight > 0 ? -rowHeightInView : rowHeightInView
            let bandY = min(y0, y0 + step)
            let bandH = abs(step)
            if bandH > 0 {
                context.fill(
                    Path(CGRect(x: 0, y: bandY, width: size.width, height: bandH)),
                    with: .color(.yellow.opacity(0.25))
                )
            }
        }

        // 各行の線とチェックボックス
        for (index, marker) in markers.enumerated() {
            let viewY = transform.documentToViewY(marker.yPosition)
            guard viewY > -50 && viewY < size.height + 50 else { continue }

            // 行線
            let opacity: Double = index == currentRowIndex ? 0.7 : 0.4
            var path = Path()
            path.move(to: CGPoint(x: 0, y: viewY))
            path.addLine(to: CGPoint(x: size.width, y: viewY))
            context.stroke(path, with: .color(.yellow.opacity(opacity)), style: lineStyle)

            // チェックボックス
            let sym = marker.isChecked ? checkedSym : uncheckedSym
            if let sym {
                context.draw(sym, at: CGPoint(x: checkboxCenterX, y: viewY), anchor: .center)
            }
        }
    }

    private func handleCheckboxTap(at y: CGFloat) {
        var closestIndex: Int?
        var minDist: CGFloat = .infinity
        for (i, marker) in markers.enumerated() {
            let viewY = transform.documentToViewY(marker.yPosition)
            let d = abs(viewY - y)
            if d < minDist {
                minDist = d
                closestIndex = i
            }
        }
        let threshold = max(20, rowHeight * transform.zoomScale / 2)
        if let idx = closestIndex, minDist <= threshold {
            onToggleMarker?(idx)
        }
    }
}
