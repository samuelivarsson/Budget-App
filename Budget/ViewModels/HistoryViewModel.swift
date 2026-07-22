//
//  HistoryViewModel.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2023-03-22.
//

import Firebase
import Foundation

class HistoryViewModel: ObservableObject {
    @Published var accountHistories: [AccountHistory] = .init()
    @Published var categoryHistories: [CategoryHistory] = .init()
    @Published var monthlySummaries: [MonthlySummary] = .init()
    /// True once the first fetch of histories has completed.
    @Published var hasLoaded: Bool = false

    private var db = Firestore.firestore()

    var accountListener: ListenerRegistration?
    var categoryListener: ListenerRegistration?
    var summaryListener: ListenerRegistration?
    
    func fetchData(completion: @escaping (Error?) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {
            let info = "Found nil when extracting uid in fetchData in TransactionsViewModel"
            completion(ApplicationError.unexpectedNil(info))
            return
        }
        // Remove old listener
        Utility.removeListener(listener: self.accountListener)
        
        var hasCalledCompletion = false
        
        // Add new listener
        self.accountListener = self.db.collection("AccountHistories").whereField("userId", isEqualTo: uid).order(by: "saveDate", descending: true).addSnapshotListener { querySnapshot, error in
            guard let documents = querySnapshot?.documents else {
                print("Error fetching documents: \(error!)")
                completion(error!)
                return
            }
                
            do {
                let data: [AccountHistory] = try documents.map { snapshot in
                    try snapshot.data(as: AccountHistory.self)
                }
                    
                // Success
                self.accountHistories = data
                print("Successfully set account histories in fetchData in HistoryViewModel")
                // Remove old listener
                Utility.removeListener(listener: self.categoryListener)
                // Add new listener
                self.categoryListener = self.db.collection("CategoryHistories").whereField("userId", isEqualTo: uid).addSnapshotListener { querySnapshot, error in
                    guard let documents = querySnapshot?.documents else {
                        print("Error fetching documents: \(error!)")
                        completion(error!)
                        return
                    }
                
                    do {
                        let data: [CategoryHistory] = try documents.map { snapshot in
                            try snapshot.data(as: CategoryHistory.self)
                        }
                    
                        // Success
                        self.categoryHistories = data
                        print("Successfully set category histories in fetchData in HistoryViewModel")

                        // Remove old listener
                        Utility.removeListener(listener: self.summaryListener)
                        // Add new listener for the monthly summaries
                        self.summaryListener = self.db.collection("MonthlySummaries").whereField("userId", isEqualTo: uid).addSnapshotListener { querySnapshot, error in
                            guard let documents = querySnapshot?.documents else {
                                print("Error fetching documents: \(error!)")
                                completion(error!)
                                return
                            }

                            do {
                                let data: [MonthlySummary] = try documents.map { snapshot in
                                    try snapshot.data(as: MonthlySummary.self)
                                }

                                // Success
                                self.monthlySummaries = data
                                self.hasLoaded = true
                                self.addListeners()
                                print("Successfully set monthly summaries in fetchData in HistoryViewModel")
                                if (!hasCalledCompletion) {
                                    hasCalledCompletion = true
                                    completion(nil)
                                }
                                return
                            } catch {
                                print("Something went wrong when fetching monthly summaries: \(error)")
                                completion(error)
                            }
                        }
                        return
                    } catch {
                        print("Something went wrong when fetching transactions documents: \(error)")
                        completion(error)
                    }
                }
            } catch {
                print("Something went wrong when fetching transactions documents: \(error)")
                completion(error)
            }
        }
    }
    
    func addListeners() {
        if let accountListener = self.accountListener {
            Utility.listeners.append(accountListener)
        }
        if let categoryListener = self.categoryListener {
            Utility.listeners.append(categoryListener)
        }
        if let summaryListener = self.summaryListener {
            Utility.listeners.append(summaryListener)
        }
    }
    
    func addHistories(accountHistories: [AccountHistory], categoryHistories: [CategoryHistory], monthlySummary: MonthlySummary? = nil, completion: @escaping (Error?) -> Void) {
        let batch = self.db.batch()

        for accountHistory in accountHistories {
            let docRef = self.db.collection("AccountHistories").document()
            do {
                try batch.setData(from: accountHistory, forDocument: docRef)
            } catch {
                completion(error)
                return
            }
        }

        for categoryHistory in categoryHistories {
            let docRef = self.db.collection("CategoryHistories").document()
            do {
                try batch.setData(from: categoryHistory, forDocument: docRef)
            } catch {
                completion(error)
                return
            }
        }

        if let monthlySummary = monthlySummary {
            let docRef = self.db.collection("MonthlySummaries").document()
            do {
                try batch.setData(from: monthlySummary, forDocument: docRef)
            } catch {
                completion(error)
                return
            }
        }

        batch.commit(completion: completion)
    }
    
    func getPreviousAccountBalance(accountId: String) -> Double {
        guard let savingsAccountHistory = self.accountHistories.first(where: { $0.accountId == accountId }) else {
            return 0
        }
        return savingsAccountHistory.balance
    }
    
    func getCategoryAverage(categoryId: String) -> Double {
        if self.categoryHistories.count < 1 {
            return 0
        }
        let categoryHistory = self.categoryHistories.filter { $0.categoryId == categoryId }
        var total: Double = 0
        for history in categoryHistory {
            total += history.totalAmount
        }
        return total / Double(categoryHistory.count)
    }
    // TODO: - Add warning when deleting transaction category with history

    // MARK: - History aggregation (redesigned History view)

    /// The saveDate cutoff for a period, anchored to budget-month boundaries
    /// (`monthStartsOn`) rather than the calendar. `nil` means "no lower bound"
    /// (.all), or "handled live in the view" (.month).
    private func cutoff(for period: HistoryPeriod, monthStartsOn: Int) -> Date? {
        switch period {
        case .month: return nil
        case .threeMonths: return Utility.getBudgetPeriod(monthsBack: 3, monthStartsOn: monthStartsOn).0
        case .year: return Utility.getBudgetPeriod(monthsBack: 12, monthStartsOn: monthStartsOn).0
        case .all: return nil
        }
    }

    /// Saved category histories within a period (past/completed months only).
    private func savedCategoryHistories(period: HistoryPeriod, monthStartsOn: Int) -> [CategoryHistory] {
        guard let cutoff = self.cutoff(for: period, monthStartsOn: monthStartsOn) else { return self.categoryHistories }
        return self.categoryHistories.filter { $0.saveDate >= cutoff }
    }

    /// Saved monthly summaries within a period.
    private func summaries(in period: HistoryPeriod, monthStartsOn: Int) -> [MonthlySummary] {
        guard let cutoff = self.cutoff(for: period, monthStartsOn: monthStartsOn) else { return self.monthlySummaries }
        return self.monthlySummaries.filter { $0.saveDate >= cutoff }
    }

    /// The distinct months (keyed by save day) that have any saved history in a period.
    private func monthKeys(period: HistoryPeriod, monthStartsOn: Int) -> (keys: Set<Date>, summaries: [Date: MonthlySummary]) {
        let cal = Calendar.current
        var keys = Set<Date>()
        for history in self.savedCategoryHistories(period: period, monthStartsOn: monthStartsOn) {
            keys.insert(cal.startOfDay(for: history.saveDate))
        }
        var byMonth: [Date: MonthlySummary] = [:]
        for summary in self.summaries(in: period, monthStartsOn: monthStartsOn) {
            let key = cal.startOfDay(for: summary.saveDate)
            byMonth[key] = summary
            keys.insert(key)
        }
        return (keys, byMonth)
    }

    /// The planned budget figures (income / fixed costs / scheduled saving) summed
    /// over a period. Months that have a saved MonthlySummary use its stored values;
    /// months from before this feature existed estimate from today's config and are
    /// counted in `estimatedMonths` so the UI can flag it.
    func plannedTotals(period: HistoryPeriod, budget: Budget)
        -> (income: Double, fixedCosts: Double, scheduledSavings: Double, estimatedMonths: Int, monthCount: Int) {
        let (keys, summaryByMonth) = self.monthKeys(period: period, monthStartsOn: budget.monthStartsOn)
        let currentIncome = budget.income
        let currentFixed = budget.getOverheadsAmount()
        let currentScheduled = budget.getSavings()
        var income = 0.0, fixed = 0.0, scheduled = 0.0, estimated = 0
        for key in keys {
            if let summary = summaryByMonth[key] {
                income += summary.income
                fixed += summary.fixedCosts
                scheduled += summary.scheduledSavings
            } else {
                income += currentIncome
                fixed += currentFixed
                scheduled += currentScheduled
                estimated += 1
            }
        }
        return (income, fixed, scheduled, estimated, keys.count)
    }

    func configuredIncomeTotal(period: HistoryPeriod, budget: Budget) -> Double {
        self.plannedTotals(period: period, budget: budget).income
    }

    func scheduledSavingsTotal(period: HistoryPeriod, budget: Budget) -> Double {
        self.plannedTotals(period: period, budget: budget).scheduledSavings
    }

    func fixedCostsTotal(period: HistoryPeriod, budget: Budget) -> Double {
        self.plannedTotals(period: period, budget: budget).fixedCosts
    }

    /// Whether any month in the period had to estimate its planned figures.
    func hasEstimatedMonths(period: HistoryPeriod, budget: Budget) -> Bool {
        self.plannedTotals(period: period, budget: budget).estimatedMonths > 0
    }

    private func resolvedCategory(_ history: CategoryHistory, budget: Budget) -> TransactionCategory? {
        budget.transactionCategories.first { $0.id == history.categoryId }
    }

    /// The effective money flow of a saved history row: the current category's
    /// structural flow if it still exists, else the stored declared type.
    private func resolvedFlow(_ history: CategoryHistory, budget: Budget) -> TransactionType {
        if let category = self.resolvedCategory(history, budget: budget) { return category.moneyFlow }
        return history.categoryType ?? .expense
    }

    private func savingsAccountIds(_ budget: Budget) -> Set<String> {
        Set(budget.accounts.filter { $0.type == .saving }.map { $0.id })
    }

    /// True if the history's category moves money into or out of a savings account
    /// — i.e. it's savings activity (counted in Sparat), not operational (Net).
    private func touchesSavings(_ history: CategoryHistory, budget: Budget) -> Bool {
        guard let category = self.resolvedCategory(history, budget: budget) else { return false }
        let ids = self.savingsAccountIds(budget)
        return ids.contains(category.takesFromAccount) || ids.contains(category.givesToAccount)
    }

    /// Per-category totals for an effective FLOW over a saved period, largest first.
    func categoryStats(period: HistoryPeriod, type flow: TransactionType, budget: Budget) -> [CategoryStat] {
        var names: [String: String] = [:]
        var totals: [String: Double] = [:]
        for history in self.savedCategoryHistories(period: period, monthStartsOn: budget.monthStartsOn) {
            guard self.resolvedFlow(history, budget: budget) == flow else { continue }
            totals[history.categoryId, default: 0] += history.totalAmount
            names[history.categoryId] = history.categoryName
        }
        return totals.compactMap { id, total -> CategoryStat? in
            guard abs(total) > 0.005 else { return nil }
            return CategoryStat(id: id, name: names[id] ?? "", type: flow, total: total)
        }
        .sorted { $0.total > $1.total }
    }

    /// Netto over a period = planned income + operational income − fixed − scheduled
    /// − operational expenses. "Operational" excludes anything touching a savings
    /// account (those are savings activity, see `savingsStats`). Planned figures come
    /// from `plannedTotals` (stored where available, estimated otherwise → `estimated`).
    func netStats(period: HistoryPeriod, budget: Budget) -> (net: Double, income: Double, expenses: Double, estimated: Bool) {
        let histories = self.savedCategoryHistories(period: period, monthStartsOn: budget.monthStartsOn)
        let planned = self.plannedTotals(period: period, budget: budget)

        var opIncome = 0.0, expenses = 0.0
        for history in histories {
            if self.touchesSavings(history, budget: budget) { continue }
            switch self.resolvedFlow(history, budget: budget) {
            case .income: opIncome += history.totalAmount
            case .expense: expenses += history.totalAmount
            case .transfer: break   // internal movement, not part of Net
            }
        }
        // `income` = configured/planned income + operational income transactions.
        let income = planned.income + opIncome
        let net = income - planned.fixedCosts - planned.scheduledSavings - expenses
        return (net, income, expenses, planned.estimatedMonths > 0)
    }

    /// Deposits into / withdrawals from savings accounts over a saved period.
    /// Pass `accountId` to restrict to a single savings account.
    func savingsStats(period: HistoryPeriod, budget: Budget, accountId: String? = nil) -> (deposits: Double, withdrawals: Double) {
        let ids: Set<String> = accountId.map { [$0] } ?? self.savingsAccountIds(budget)
        var deposits = 0.0, withdrawals = 0.0
        for history in self.savedCategoryHistories(period: period, monthStartsOn: budget.monthStartsOn) {
            guard let category = self.resolvedCategory(history, budget: budget) else { continue }
            if ids.contains(category.givesToAccount) { deposits += history.totalAmount }
            if ids.contains(category.takesFromAccount) { withdrawals += history.totalAmount }
        }
        return (deposits, withdrawals)
    }

    /// Number of budget months spanned by a saved period (for scaling per-month
    /// config figures like the main account's scheduled saving).
    func monthCount(period: HistoryPeriod, budget: Budget) -> Int {
        max(1, self.plannedTotals(period: period, budget: budget).monthCount)
    }
}
