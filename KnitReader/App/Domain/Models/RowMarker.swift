import Foundation
import CoreGraphics

/// ドキュメント座標系における水平行マーカー。
struct RowMarker: Identifiable, Equatable, Sendable {
    let id: UUID
    /// ドキュメント座標系での Y 位置（ドキュメント上端からのポイント数）
    var yPosition: CGFloat
    /// この行が完了済みかどうか
    var isChecked: Bool

    init(id: UUID = UUID(), yPosition: CGFloat, isChecked: Bool = false) {
        self.id = id
        self.yPosition = yPosition
        self.isChecked = isChecked
    }
}
