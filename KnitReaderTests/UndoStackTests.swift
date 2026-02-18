import XCTest
@testable import KnitReader

final class UndoStackTests: XCTestCase {

    func test_initialState() {
        let stack = UndoStack<Int>(initial: 0)
        XCTAssertEqual(stack.current, 0)
        XCTAssertFalse(stack.canUndo)
    }

    func test_pushAndUndo() {
        let stack = UndoStack<Int>(initial: 0)
        stack.push(1)
        stack.push(2)
        XCTAssertEqual(stack.current, 2)
        XCTAssertTrue(stack.canUndo)

        stack.undo()
        XCTAssertEqual(stack.current, 1)

        stack.undo()
        XCTAssertEqual(stack.current, 0)

        XCTAssertFalse(stack.canUndo)
        XCTAssertFalse(stack.undo())
    }

    func test_maxDepth() {
        let stack = UndoStack<Int>(initial: 0, maxDepth: 3)
        stack.push(1)
        stack.push(2)
        stack.push(3)
        stack.push(4) // 0 が除外される
        XCTAssertEqual(stack.current, 4)

        stack.undo() // -> 3
        stack.undo() // -> 2
        stack.undo() // -> 1
        XCTAssertEqual(stack.current, 1)
        XCTAssertFalse(stack.canUndo) // 0 は除外済み
    }

    func test_reset() {
        let stack = UndoStack<Int>(initial: 0)
        stack.push(1)
        stack.push(2)
        stack.reset(to: 10)
        XCTAssertEqual(stack.current, 10)
        XCTAssertFalse(stack.canUndo)
    }

    func test_independence() {
        let stackA = UndoStack<Int>(initial: 0)
        let stackB = UndoStack<String>(initial: "a")
        stackA.push(1)
        stackB.push("b")
        stackA.undo()
        // stackB は影響を受けない
        XCTAssertEqual(stackA.current, 0)
        XCTAssertEqual(stackB.current, "b")
    }
}
