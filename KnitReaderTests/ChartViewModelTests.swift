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
}
