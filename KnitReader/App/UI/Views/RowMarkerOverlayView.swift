import SwiftUI

/// 行マーカーをドキュメント座標からビュー座標に投影して描画するオーバーレイ。
///
/// Canvas を使い、大量のマーカーも効率的に描画する。
/// `allowsHitTesting(false)` でタッチを下層の ScrollView に透過させる。
struct RowMarkerOverlayView: View {
    let markers: [RowMarker]
    let currentRowIndex: Int
    let transform: CoordinateTransform
    let viewportSize: CGSize
    let documentWidth: CGFloat

    var body: some View {
        Canvas { context, size in
            for (index, marker) in markers.enumerated() {
                let viewY = transform.documentToViewY(marker.yPosition)

                // ビューポート外のマーカーはスキップ
                guard viewY > -50 && viewY < size.height + 50 else { continue }

                let lineStart = CGPoint(x: 0, y: viewY)
                let lineEnd = CGPoint(x: size.width, y: viewY)

                var path = Path()
                path.move(to: lineStart)
                path.addLine(to: lineEnd)

                let color: Color
                let lineWidth: CGFloat
                if index == currentRowIndex {
                    color = .blue
                    lineWidth = 2
                } else if marker.isChecked {
                    color = .green.opacity(0.5)
                    lineWidth = 1
                } else {
                    color = .gray.opacity(0.3)
                    lineWidth = 1
                }

                context.stroke(path, with: .color(color), lineWidth: lineWidth)
            }
        }
        .allowsHitTesting(false)
    }
}
