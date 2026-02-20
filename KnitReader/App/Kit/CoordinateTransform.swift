import CoreGraphics

/// ドキュメント座標系とビュー座標系の変換ユーティリティ。
///
/// - ドキュメント座標（画像モード `pageHeight == 0`）: 左上原点、Y下向き、画像ポイント単位
/// - ドキュメント座標（PDFモード `pageHeight > 0`）: 左下原点、Y上向き、PDFポイント単位
/// - ビュー座標: UIScrollView の bounds 左上原点、スクリーンポイント単位
struct CoordinateTransform: Equatable, Sendable {
    /// スクロールビューの現在のズームスケール
    var zoomScale: CGFloat
    /// スクロールビューのコンテンツオフセット
    var contentOffset: CGPoint
    /// PDF ページ高さ（ポイント）。0 のとき画像モード（Y反転なし）、> 0 のとき PDF モード（Y反転あり）
    var pageHeight: CGFloat

    init(
        zoomScale: CGFloat = 1.0,
        contentOffset: CGPoint = .zero,
        pageHeight: CGFloat = 0
    ) {
        self.zoomScale = zoomScale
        self.contentOffset = contentOffset
        self.pageHeight = pageHeight
    }

    // MARK: - Internal Y Helpers

    /// ドキュメント Y → コンテンツ上の Y（左上原点）
    private func docYToContentY(_ y: CGFloat) -> CGFloat {
        pageHeight > 0 ? (pageHeight - y) : y
    }

    /// コンテンツ上の Y（左上原点）→ ドキュメント Y
    private func contentYToDocY(_ y: CGFloat) -> CGFloat {
        pageHeight > 0 ? (pageHeight - y) : y
    }

    // MARK: - Point

    /// ドキュメント座標 → ビュー座標
    func documentToView(_ point: CGPoint) -> CGPoint {
        CGPoint(
            x: point.x * zoomScale - contentOffset.x,
            y: docYToContentY(point.y) * zoomScale - contentOffset.y
        )
    }

    /// ビュー座標 → ドキュメント座標
    func viewToDocument(_ point: CGPoint) -> CGPoint {
        CGPoint(
            x: (point.x + contentOffset.x) / zoomScale,
            y: contentYToDocY((point.y + contentOffset.y) / zoomScale)
        )
    }

    // MARK: - Rect

    /// ドキュメント座標の Rect → ビュー座標の Rect
    func documentToView(_ rect: CGRect) -> CGRect {
        if pageHeight > 0 {
            // PDF モード: Y 反転があるため docRect.maxY がビュー上の minY になる
            let origin = documentToView(CGPoint(x: rect.minX, y: rect.maxY))
            return CGRect(
                origin: origin,
                size: CGSize(width: rect.width * zoomScale, height: rect.height * zoomScale)
            )
        } else {
            // 画像モード: 既存の動作を維持
            return CGRect(
                origin: documentToView(rect.origin),
                size: CGSize(width: rect.width * zoomScale, height: rect.height * zoomScale)
            )
        }
    }

    // MARK: - Y only

    /// ドキュメント Y → ビュー Y
    func documentToViewY(_ y: CGFloat) -> CGFloat {
        docYToContentY(y) * zoomScale - contentOffset.y
    }

    /// ビュー Y → ドキュメント Y
    func viewToDocumentY(_ y: CGFloat) -> CGFloat {
        contentYToDocY((y + contentOffset.y) / zoomScale)
    }
}
