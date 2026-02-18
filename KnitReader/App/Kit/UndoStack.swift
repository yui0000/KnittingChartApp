import Foundation

/// 汎用の独立 Undo スタック。
///
/// 各関心事（行インデックス、マーカー、チェックカウント）ごとに
/// 独立したインスタンスを持つことで、Undo 操作の干渉を防ぐ。
final class UndoStack<State: Equatable>: ObservableObject {
    @Published private(set) var current: State
    private var undoHistory: [State] = []
    private let maxDepth: Int

    init(initial: State, maxDepth: Int = 50) {
        self.current = initial
        self.maxDepth = maxDepth
    }

    /// 現在の状態を履歴に積み、新しい状態を適用する。
    func push(_ newState: State) {
        undoHistory.append(current)
        if undoHistory.count > maxDepth {
            undoHistory.removeFirst()
        }
        current = newState
    }

    /// 直前の状態に戻す。成功時は true を返す。
    @discardableResult
    func undo() -> Bool {
        guard let previous = undoHistory.popLast() else { return false }
        current = previous
        return true
    }

    /// Undo 可能かどうか
    var canUndo: Bool { !undoHistory.isEmpty }

    /// 新しい初期状態でリセットし、履歴をクリアする。
    func reset(to state: State) {
        current = state
        undoHistory.removeAll()
    }
}
