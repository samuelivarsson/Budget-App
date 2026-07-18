import XCTest
@testable import Budget

final class RedesignLogicTests: XCTestCase {

    func testBarStateOver() {
        XCTAssertEqual(BudgetBarState.classify(spent: 3357, ceiling: 1200), .over)
    }
    func testBarStateWarnAtHalf() {
        XCTAssertEqual(BudgetBarState.classify(spent: 200, ceiling: 400), .warn)
        XCTAssertEqual(BudgetBarState.classify(spent: 242.5, ceiling: 400), .warn)
    }
    func testBarStateNormal() {
        XCTAssertEqual(BudgetBarState.classify(spent: 100, ceiling: 400), .normal)
        XCTAssertEqual(BudgetBarState.classify(spent: 0, ceiling: 12500), .normal)
    }
    func testBarStateZeroCeiling() {
        XCTAssertEqual(BudgetBarState.classify(spent: 10, ceiling: 0), .over)
        XCTAssertEqual(BudgetBarState.classify(spent: 0, ceiling: 0), .normal)
    }
    func testCategoryIndexFixed() {
        XCTAssertEqual(CategoryPalette.index(for: "Mat"), 3)
        XCTAssertEqual(CategoryPalette.index(for: "Sparkonto köp"), 0)
    }
    func testCategoryIndexStableForUnknown() {
        let a = CategoryPalette.index(for: "Godis")
        let b = CategoryPalette.index(for: "Godis")
        XCTAssertEqual(a, b)
        XCTAssertTrue((0..<8).contains(a))
    }
}
