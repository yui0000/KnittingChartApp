import CoreGraphics

/// ドキュメント座標系とビュー座標系の変換ユーティリティ。
///
/// - ドキュメント座標: 画像の左上原点、画像ポイント単位
/// - ビュー座標: UIScrollView の bounds 左上原点、スクリーンポイント単位
struct CoordinateTransform: Equatable, Sendable {
    /// スクロールビューの現在のズームスケール
    var zoomScale: CGFloat
    /// スクロールビューのコンテンツオフセット
    var contentOffset: CGPoint

    init(zoomScale: CGFloat = 1.0, contentOffset: CGPoint = .zero) {
        self.zoomScale = zoomScale
        self.contentOffset = contentOffset
    }

    // MARK: - Point

    /// ドキュメント座標 → ビュー座標
    func documentToView(_ point: CGPoint) -> CGPoint {
        CGPoint(
            x: point.x * zoomScale - contentOffset.x,
            y: point.y * zoomScale - contentOffset.y
        )
    }

    /// ビュー座標 → ドキュメント座標
    func viewToDocument(_ point: CGPoint) -> CGPoint {
        CGPoint(
            x: (point.x + contentOffset.x) / zoomScale,
            y: (point.y + contentOffset.y) / zoomScale
        )
    }

    // MARK: - Rect

    /// ドキュメント座標の Rect → ビュー座標の Rect
    func documentToView(_ rect: CGRect) -> CGRect {
        CGRect(
            origin: documentToView(rect.origin),
            size: CGSize(
                width: rect.width * zoomScale,
                height: rect.height * zoomScale
            )
        )
    }

    // MARK: - Y only

    /// ドキュメント Y → ビュー Y
    func documentToViewY(_ y: CGFloat) -> CGFloat {
        y * zoomScale - contentOffset.y
    }

    /// ビュー Y → ドキュメント Y
    func viewToDocumentY(_ y: CGFloat) -> CGFloat {
        (y + contentOffset.y) / zoomScale
    }
}
