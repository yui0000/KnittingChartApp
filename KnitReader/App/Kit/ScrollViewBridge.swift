import SwiftUI
import UIKit

/// UIScrollView + UIImageView をラップする UIViewRepresentable。
///
/// ピンチズーム・パンを UIKit で処理し、zoomScale / contentOffset を
/// Binding で SwiftUI に返す。オーバーレイは SwiftUI 側で描画する。
struct ScrollViewBridge: UIViewRepresentable {
    let image: UIImage
    @Binding var zoomScale: CGFloat
    @Binding var contentOffset: CGPoint
    @Binding var viewportSize: CGSize

    private static let imageViewTag = 1001

    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.delegate = context.coordinator
        scrollView.minimumZoomScale = 0.25
        scrollView.maximumZoomScale = 5.0
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.bouncesZoom = true

        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        imageView.tag = Self.imageViewTag
        scrollView.addSubview(imageView)

        imageView.frame = CGRect(origin: .zero, size: image.size)
        scrollView.contentSize = image.size

        return scrollView
    }

    func updateUIView(_ scrollView: UIScrollView, context: Context) {
        guard let imageView = scrollView.viewWithTag(Self.imageViewTag) as? UIImageView else { return }

        if imageView.image !== image {
            imageView.image = image
            imageView.frame = CGRect(origin: .zero, size: image.size)
            scrollView.contentSize = image.size
        }

        // 初回レイアウト時にフィットさせる
        if !context.coordinator.hasSetInitialZoom && scrollView.bounds.size != .zero {
            let widthScale = scrollView.bounds.width / image.size.width
            let heightScale = scrollView.bounds.height / image.size.height
            let fitScale = min(widthScale, heightScale)
            scrollView.minimumZoomScale = min(fitScale, 0.25)
            scrollView.zoomScale = fitScale
            context.coordinator.hasSetInitialZoom = true
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    final class Coordinator: NSObject, UIScrollViewDelegate {
        var parent: ScrollViewBridge
        var hasSetInitialZoom = false

        init(parent: ScrollViewBridge) {
            self.parent = parent
        }

        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            scrollView.viewWithTag(ScrollViewBridge.imageViewTag)
        }

        func scrollViewDidZoom(_ scrollView: UIScrollView) {
            parent.zoomScale = scrollView.zoomScale
            parent.contentOffset = scrollView.contentOffset
        }

        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            parent.contentOffset = scrollView.contentOffset
            parent.viewportSize = scrollView.bounds.size
        }
    }
}
