import SwiftUI

/// 行マーカーをドキュメント座標からビュー座標に投影して描画するオーバーレイ。
///
/// Canvas を使い、大量のマーカーも効率的に描画する。
/// `allowsHitTesting(false)` でタッチを下層の ScrollView に透過させる。
///
/// ## 色弱対応
/// 色だけでなく線幅・線スタイルで状態を区別する。
/// - 現在行: 太い実線（lineWidth 3）、アクセントカラー
/// - チェック済み: 細い実線（lineWidth 1.5）、セカンダリカラー
/// - 未チェック: ダッシュ線（lineWidth 1）、薄いグレー
struct RowMarkerOverlayView: View {
    let markers: [RowMarker]
    let currentRowIndex: Int
    let transform: CoordinateTransform
    let viewportSize: CGSize
    let documentWidth: CGFloat

    // システムカラーを使うことで Dark Mode / 高コントラスト / 色盲フィルタに自動対応
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Canvas { context, size in
            for (index, marker) in markers.enumerated() {
                let viewY = transform.documentToViewY(marker.yPosition)

                guard viewY > -50 && viewY < size.height + 50 else { continue }

                let lineStart = CGPoint(x: 0, y: viewY)
                let lineEnd = CGPoint(x: size.width, y: viewY)

                var path = Path()
                path.move(to: lineStart)
                path.addLine(to: lineEnd)

                if index == currentRowIndex {
                    // 現在行: 太い実線 + アクセントカラー
                    context.stroke(
                        path,
                        with: .color(.accentColor),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                } else if marker.isChecked {
                    // チェック済み: 細い実線 + セカンダリ（色弱でも線幅で区別可能）
                    context.stroke(
                        path,
                        with: .color(.secondary.opacity(0.6)),
                        style: StrokeStyle(lineWidth: 1.5)
                    )
                } else {
                    // 未チェック: ダッシュ線 + 薄いグレー（形状で区別）
                    context.stroke(
                        path,
                        with: .color(.secondary.opacity(0.25)),
                        style: StrokeStyle(lineWidth: 1, dash: [4, 4])
                    )
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
