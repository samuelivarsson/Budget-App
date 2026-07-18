import XCTest
// No `import Budget`: the BudgetTests target compiles the app's model/logic
// sources directly (same convention as OverheadTests), so symbols resolve
// locally. Importing the module would create duplicate `Standing`/`Transaction`
// types, and `Budget.` can't disambiguate because `struct Budget` shadows the
// module name.

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

    func testGetTotalIOwe() {
        let me = "me"
        let vm = StandingsViewModel()
        // I owe A 100 (my standing -100), B is +40 (not owed),
        // I owe C 55 (my standing -55). Total owed = 155.
        vm.standings = [
            Standing(userId1: me, userId2: "A", amount1: 0, amount2: 100,
                     userName1: "Me", userName2: "A", phoneNumber1: "", phoneNumber2: ""),
            Standing(userId1: me, userId2: "B", amount1: 40, amount2: 0,
                     userName1: "Me", userName2: "B", phoneNumber1: "", phoneNumber2: ""),
            Standing(userId1: me, userId2: "C", amount1: 0, amount2: 55,
                     userName1: "Me", userName2: "C", phoneNumber1: "", phoneNumber2: ""),
        ]
        XCTAssertEqual(vm.getTotalIOwe(myId: me), 155, accuracy: 0.0001)
    }

    func testGetTotalIOweZeroWhenNoneOwed() {
        let me = "me"
        let vm = StandingsViewModel()
        vm.standings = [
            Standing(userId1: me, userId2: "A", amount1: 30, amount2: 0,
                     userName1: "Me", userName2: "A", phoneNumber1: "", phoneNumber2: ""),
        ]
        XCTAssertEqual(vm.getTotalIOwe(myId: me), 0, accuracy: 0.0001)
    }
}
