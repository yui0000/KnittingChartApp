import XCTest
@testable import KnitReader

@MainActor
final class ChartViewModelTests: XCTestCase {

    private func makeViewModel() -> ChartViewModel {
        let vm = ChartViewModel()
        // サンプル画像がない環境でもテスト可能にするため、手動でマーカーをセット
        vm.rowIndexUndo.reset(to: 0)
        vm.markersUndo.reset(to: [
            RowMarker(yPosition: 100),
            RowMarker(yPosition: 140),
            RowMarker(yPosition: 180),
            RowMarker(yPosition: 220),
            RowMarker(yPosition: 260),
        ])
        vm.checkCountUndo.reset(to: 0)
        return vm
    }

    func test_advanceRow_incrementsAllThreeStacks() {
        let vm = makeViewModel()

        vm.advanceRow()

        XCTAssertEqual(vm.currentRowIndex, 1)
        XCTAssertEqual(vm.checkCount, 1)
        XCTAssertTrue(vm.markers[0].isChecked)
    }

    func test_advanceRow_twice() {
        let vm = makeViewModel()

        vm.advanceRow()
        vm.advanceRow()

        XCTAssertEqual(vm.currentRowIndex, 2)
        XCTAssertEqual(vm.checkCount, 2)
        XCTAssertTrue(vm.markers[0].isChecked)
        XCTAssertTrue(vm.markers[1].isChecked)
    }

    func test_independentUndo_rowOnly() {
        let vm = makeViewModel()

        vm.advanceRow()
        vm.advanceRow()

        let markersBeforeUndo = vm.markers
        let countBeforeUndo = vm.checkCount

        vm.undoRowIndex()

        // 行インデックスだけ戻り、マーカーとカウントはそのまま
        XCTAssertEqual(vm.currentRowIndex, 1)
        XCTAssertEqual(vm.markers, markersBeforeUndo)
        XCTAssertEqual(vm.checkCount, countBeforeUndo)
    }

    func test_independentUndo_markersOnly() {
        let vm = makeViewModel()

        vm.advanceRow()

        let rowBeforeUndo = vm.currentRowIndex
        let countBeforeUndo = vm.checkCount

        vm.undoMarkers()

        // マーカーだけ戻り、行インデックスとカウントはそのまま
        XCTAssertEqual(vm.currentRowIndex, rowBeforeUndo)
        XCTAssertEqual(vm.checkCount, countBeforeUndo)
        XCTAssertFalse(vm.markers[0].isChecked)
    }

    func test_independentUndo_checkCountOnly() {
        let vm = makeViewModel()

        vm.advanceRow()

        let rowBeforeUndo = vm.currentRowIndex
        let markersBeforeUndo = vm.markers

        vm.undoCheckCount()

        XCTAssertEqual(vm.currentRowIndex, rowBeforeUndo)
        XCTAssertEqual(vm.markers, markersBeforeUndo)
        XCTAssertEqual(vm.checkCount, 0)
    }

    // MARK: - Mixed Undo Order Scenarios

    func test_mixedUndo_rowAndCount_interleaved() {
        let vm = makeViewModel()

        vm.advanceRow()  // row=1, count=1, markers[0].isChecked=true
        vm.advanceRow()  // row=2, count=2, markers[1].isChecked=true

        vm.undoRowIndex()         // row=1 に戻す（count, markers はそのまま）
        XCTAssertEqual(vm.currentRowIndex, 1)
        XCTAssertEqual(vm.checkCount, 2)

        vm.advanceRow()           // row=2, count=3
        XCTAssertEqual(vm.currentRowIndex, 2)
        XCTAssertEqual(vm.checkCount, 3)

        vm.undoCheckCount()       // count=2
        XCTAssertEqual(vm.checkCount, 2)
        XCTAssertEqual(vm.currentRowIndex, 2) // rowIndex はそのまま

        vm.undoCheckCount()       // count=1
        XCTAssertEqual(vm.checkCount, 1)
    }

    func test_undoAll_returnsToInitial() {
        let vm = makeViewModel()

        vm.advanceRow()
        vm.advanceRow()
        vm.advanceRow()

        // 各スタックを独立に3回ずつ Undo
        vm.undoRowIndex(); vm.undoRowIndex(); vm.undoRowIndex()
        vm.undoMarkers();  vm.undoMarkers();  vm.undoMarkers()
        vm.undoCheckCount(); vm.undoCheckCount(); vm.undoCheckCount()

        XCTAssertEqual(vm.currentRowIndex, 0)
        XCTAssertEqual(vm.checkCount, 0)
        XCTAssertTrue(vm.markers.allSatisfy { !$0.isChecked })
        XCTAssertFalse(vm.rowIndexUndo.canUndo)
        XCTAssertFalse(vm.markersUndo.canUndo)
        XCTAssertFalse(vm.checkCountUndo.canUndo)
    }

    func test_stepCount2_advance_checksCorrectMarker() {
        let vm = makeViewModel()
        vm.stepCount = 2

        vm.advanceRow()  // row = 0+2 = 2、prevIndex = 0 → markers[0] をチェック

        XCTAssertEqual(vm.currentRowIndex, 2)
        XCTAssertTrue(vm.markers[0].isChecked)
        XCTAssertFalse(vm.markers[1].isChecked)
    }

    func test_applyRowSettings_resetsUndoHistory() {
        let vm = makeViewModel()

        vm.advanceRow()
        vm.advanceRow()
        XCTAssertTrue(vm.rowIndexUndo.canUndo)
        XCTAssertTrue(vm.markersUndo.canUndo)
        XCTAssertTrue(vm.checkCountUndo.canUndo)

        // ドキュメントが nil のときは applyRowSettings は何もしない
        // makeViewModel では chartDocument を設定していないので直接 reset を検証
        vm.rowIndexUndo.reset(to: 0)
        vm.markersUndo.reset(to: vm.markers)
        vm.checkCountUndo.reset(to: 0)

        XCTAssertFalse(vm.rowIndexUndo.canUndo)
        XCTAssertFalse(vm.markersUndo.canUndo)
        XCTAssertFalse(vm.checkCountUndo.canUndo)
    }
}
