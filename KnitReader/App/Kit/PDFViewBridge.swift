import SwiftUI
import PDFKit

/// PDFView を UIViewRepresentable でラップするブリッジ。
///
/// ScrollViewBridge と対称なインターフェースを持つ。
/// - `scaleFactor` / `contentOffset` / `viewportSize` / `pageHeight` を Binding で SwiftUI に返す。
/// - PDFView 内部の UIScrollView にデリゲートを差し込んでオフセットを取得。
/// - 1ページ目（index: 0）のみ対応。
struct PDFViewBridge: UIViewRepresentable {
    let document: PDFDocument
    @Binding var scaleFactor: CGFloat
    @Binding var contentOffset: CGPoint
    @Binding var viewportSize: CGSize
    @Binding var pageHeight: CGFloat

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = document
        pdfView.displayMode = .singlePage
        pdfView.displayDirection = .vertical
        pdfView.autoScales = true
        pdfView.usePageViewController(false, withViewOptions: nil)
        pdfView.delegate = context.coordinator

        // 内部 UIScrollView を取得してスクロール/ズームを監視する
        if let sv = pdfView.subviews.compactMap({ $0 as? UIScrollView }).first {
            sv.delegate = context.coordinator
            context.coordinator.internalScrollView = sv
        }

        // 初回ページ高さを設定
        if let page = document.page(at: 0) {
            let bounds = page.bounds(for: .mediaBox)
            context.coordinator.parent.pageHeight = bounds.height
        }

        return pdfView
    }

    func updateUIView(_ pdfView: PDFView, context: Context) {
        // ドキュメントが切り替わった場合のみ再設定
        if pdfView.document !== document {
            pdfView.document = document
            if let page = document.page(at: 0) {
                pageHeight = page.bounds(for: .mediaBox).height
            }
            context.coordinator.hasSetInitialScale = false
        }

        // 内部 scrollView の再取得（makeUIView 時に取れなかった場合の保険）
        if context.coordinator.internalScrollView == nil {
            if let sv = pdfView.subviews.compactMap({ $0 as? UIScrollView }).first {
                sv.delegate = context.coordinator
                context.coordinator.internalScrollView = sv
            }
        }

        // autoScales 適用後の scaleFactor を初回にキャプチャ
        if !context.coordinator.hasSetInitialScale, pdfView.bounds.size != .zero {
            context.coordinator.hasSetInitialScale = true
            DispatchQueue.main.async {
                self.scaleFactor = pdfView.scaleFactor
                if let sv = context.coordinator.internalScrollView {
                    self.contentOffset = sv.contentOffset
                    self.viewportSize = sv.bounds.size
                }
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    // MARK: - Coordinator

    final class Coordinator: NSObject, PDFViewDelegate, UIScrollViewDelegate {
        var parent: PDFViewBridge
        var hasSetInitialScale = false
        weak var internalScrollView: UIScrollView?

        init(parent: PDFViewBridge) {
            self.parent = parent
        }

        // MARK: PDFViewDelegate

        func pdfViewPageChanged(_ sender: PDFView) {
            guard let page = sender.currentPage else { return }
            parent.pageHeight = page.bounds(for: .mediaBox).height
        }

        // MARK: UIScrollViewDelegate

        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            parent.contentOffset = scrollView.contentOffset
            parent.viewportSize = scrollView.bounds.size
        }

        func scrollViewDidZoom(_ scrollView: UIScrollView) {
            // PDFView.scaleFactor を superview 連鎖で取得
            // （UIScrollView.zoomScale は PDFKit の scaleFactor と異なる）
            var view: UIView? = scrollView.superview
            while let v = view {
                if let pdfView = v as? PDFView {
                    parent.scaleFactor = pdfView.scaleFactor
                    break
                }
                view = v.superview
            }
            parent.contentOffset = scrollView.contentOffset
        }
    }
}
