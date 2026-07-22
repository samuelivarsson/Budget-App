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

    func testHomeSummaryAggregates() {
        let s = HomeSummary(income: 36628, rows: [
            (spent: 3357, ceiling: 1200),   // over
            (spent: 242.5, ceiling: 400),   // within
            (spent: 0, ceiling: 12500),     // within
        ])
        XCTAssertEqual(s.spent, 3599.5, accuracy: 0.001)
        XCTAssertEqual(s.ceiling, 14100, accuracy: 0.001)
        XCTAssertEqual(s.remaining, 14100 - 3599.5, accuracy: 0.001)
        XCTAssertEqual(s.withinTakCount, 2)
        XCTAssertEqual(s.totalCount, 3)
    }
    func testHomeSummaryProgressClamped() {
        let s = HomeSummary(income: 0, rows: [(spent: 5000, ceiling: 1000)])
        XCTAssertEqual(s.progress, 1, accuracy: 0.001)
        let z = HomeSummary(income: 0, rows: [(spent: 0, ceiling: 0)])
        XCTAssertEqual(z.progress, 0, accuracy: 0.001)
    }

    private func tx(_ desc: String, _ amount: Double, _ date: Date,
                    type: TransactionType = .expense, myShare: Double = 0,
                    me: String = "me") -> Transaction {
        Transaction(totalAmount: amount,
                    category: TransactionCategory(name: "Mat", type: .expense),
                    date: date, desc: desc, creatorId: me, creatorName: "Me",
                    payerId: me, payerName: "Me",
                    participants: [Participant(amount: myShare, userId: me, userName: "Me")],
                    type: type)
    }

    func testDayRelativity() {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Europe/Stockholm")!
        let now = cal.date(from: DateComponents(year: 2026, month: 7, day: 18, hour: 20))!
        let yst = cal.date(from: DateComponents(year: 2026, month: 7, day: 17, hour: 9))!
        let old = cal.date(from: DateComponents(year: 2026, month: 7, day: 10, hour: 9))!
        XCTAssertEqual(dayRelativity(now, now: now, calendar: cal), .today)
        XCTAssertEqual(dayRelativity(yst, now: now, calendar: cal), .yesterday)
        XCTAssertEqual(dayRelativity(old, now: now, calendar: cal), .other)
    }

    func testGroupTransactionsByDay() {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Europe/Stockholm")!
        let d18a = cal.date(from: DateComponents(year: 2026, month: 7, day: 18, hour: 9))!
        let d18b = cal.date(from: DateComponents(year: 2026, month: 7, day: 18, hour: 20))!
        let d17 = cal.date(from: DateComponents(year: 2026, month: 7, day: 17, hour: 9))!
        let groups = groupTransactionsByDay([tx("a", 1, d18a), tx("c", 1, d17), tx("b", 1, d18b)], calendar: cal)
        XCTAssertEqual(groups.count, 2)
        XCTAssertEqual(groups[0].items.count, 2)         // the 18th, newest day first
        XCTAssertEqual(groups[0].items.first?.desc, "b") // newest item first
        XCTAssertEqual(groups[1].items.first?.desc, "c")
    }

    func testSumMyShareExpensesOnly() {
        let now = Date()
        let list = [tx("x", 200, now, type: .expense, myShare: 129),
                    tx("y", 100, now, type: .income,  myShare: 100),
                    tx("z", 130, now, type: .expense, myShare: 65)]
        XCTAssertEqual(sumMyShare(list, userId: "me"), 194, accuracy: 0.0001)
    }

    // MARK: - categoryForUser

    private func budget(_ categories: [TransactionCategory], rest: String = "") -> Budget {
        Budget(accounts: [], income: 0, savingsPercentage: 50,
               transactionCategories: categories, transactionCategoryThatUsesRest: rest, overheads: [])
    }
    private func foreignTx(category: TransactionCategory) -> Transaction {
        Transaction(totalAmount: 100, category: category, date: Date(), desc: "",
                    creatorId: "friend", creatorName: "Friend", payerId: "friend", payerName: "Friend",
                    participants: [Participant(amount: 50, userId: "me", userName: "Me")], type: category.type)
    }

    /// "Övrigt" must match even when the friend's copy uses a different Unicode
    /// form for "Ö" (precomposed U+00D6 vs "O" + combining diaeresis U+0308).
    func testCategoryForUserMatchesOvrigtAcrossUnicodeForms() {
        let mine = TransactionCategory(id: "mine-ovrigt", name: "\u{00D6}vrigt", type: .expense)
        let b = budget([TransactionCategory(id: "mat", name: "Mat", type: .expense), mine])
        let friend = TransactionCategory(id: "friend-ovrigt", name: "O\u{0308}vrigt", type: .expense)
        XCTAssertEqual(foreignTx(category: friend).categoryForUser(userId: "me", budget: b).id, "mine-ovrigt")
    }

    /// A name shared by two types must resolve to the SAME type. A friend's income
    /// "Övrigt" must map to my income "Övrigt", not my expense "Övrigt".
    func testCategoryForUserMatchesSameTypeWhenNameSharedAcrossTypes() {
        let expenseOvrigt = TransactionCategory(id: "exp-ovrigt", name: "Övrigt", type: .expense)
        let incomeOvrigt = TransactionCategory(id: "inc-ovrigt", name: "Övrigt", type: .income)
        // Expense one first in the array, so a name-only match would wrongly pick it.
        let b = budget([expenseOvrigt, incomeOvrigt])
        let friendIncome = TransactionCategory(id: "friend-inc", name: "Övrigt", type: .income)
        XCTAssertEqual(foreignTx(category: friendIncome).categoryForUser(userId: "me", budget: b).id, "inc-ovrigt")
    }

    func testCategoryForUserFallsBackToUsesRest() {
        let rest = TransactionCategory(id: "rest", name: "Rest", type: .expense)
        let b = budget([TransactionCategory(id: "mat", name: "Mat", type: .expense), rest], rest: "rest")
        let unknown = TransactionCategory(id: "x", name: "Nonexistent", type: .expense)
        XCTAssertEqual(foreignTx(category: unknown).categoryForUser(userId: "me", budget: b).id, "rest")
    }

    func testCategoryForUserFallsBackToFirstOfTypeWhenNoRest() {
        let b = budget([TransactionCategory(id: "mat", name: "Mat", type: .expense),
                        TransactionCategory(id: "lon", name: "Lön", type: .income)])
        let unknown = TransactionCategory(id: "x", name: "Nonexistent", type: .income)
        // No name/id match and no "uses rest" → first category of the SAME type.
        XCTAssertEqual(foreignTx(category: unknown).categoryForUser(userId: "me", budget: b).id, "lon")
    }

    // MARK: - MoneyFlow classifier

    func testMoneyFlowFromStructure() {
        // gives only → income
        XCTAssertEqual(TransactionCategory(name: "in", type: .expense, givesToAccount: "a").moneyFlow, .income)
        // takes only → expense
        XCTAssertEqual(TransactionCategory(name: "ex", type: .income, takesFromAccount: "a").moneyFlow, .expense)
        // both → transfer, even when declared income (legacy Påfyllning)
        XCTAssertEqual(TransactionCategory(name: "pf", type: .income, takesFromAccount: "s", givesToAccount: "a").moneyFlow, .transfer)
        // neither configured → falls back to declared type
        XCTAssertEqual(TransactionCategory(name: "x", type: .transfer).moneyFlow, .transfer)
    }

}
