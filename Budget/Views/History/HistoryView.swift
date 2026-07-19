//
//  HistoryView.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2022-04-12.
//  v2 — iOS 26 redesign: period selector, Netto/Sparat summary cards, and
//  category/account breakdowns as proportional bars.
//

import SwiftUI

struct HistoryView: View {
    @EnvironmentObject private var errorHandling: ErrorHandling
    @EnvironmentObject private var userViewModel: UserViewModel
    @EnvironmentObject private var transactionsViewModel: TransactionsViewModel
    @EnvironmentObject private var historyViewModel: HistoryViewModel

    @State private var showingInfo: Bool = false
    @State private var period: HistoryPeriod = .all
    @State private var expandedFixed: Bool = false
    private let collapseLimit = 4

    private var budget: Budget { userViewModel.user.budget }
    private func money(_ v: Double) -> String { Utility.doubleToLocalCurrency(value: v) }
    private func percentString(_ frac: Double) -> String { "\(Int((frac * 100).rounded())) %" }

    // MARK: Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    IOSHistoryPeriodBar(selection: $period)
                        .padding(.top, 4).padding(.bottom, 2)
                    summaryRow.padding(.top, 12)
                    if hasEstimatedMonths { estimateHint }

                    categorySection(.expense)
                    fixedCostsSection
                    categorySection(.income)
                    categorySection(.saving)

                    accountSection(.transaction, key: "transaction")
                    accountSection(.saving, key: "saving")
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 120)
            }
            .background(Color.iosBG.ignoresSafeArea())
            .navigationTitle("history")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { self.showingInfo = true } label: {
                        Image(systemName: "info.circle").foregroundColor(.primary)
                    }
                }
            }
            .alert("info", isPresented: self.$showingInfo) {
                Button { self.showingInfo = false } label: { Text("ok") }
            } message: {
                Text("averageSpent")
            }
        }
        .redacted(when: userViewModel.user.id.isEmpty || !transactionsViewModel.hasLoaded
                  || (period != .month && !historyViewModel.hasLoaded))
    }

    // MARK: Summary cards

    private var summaryRow: some View {
        let netInfo = self.netInfo()
        let saved = self.categoryStats(.saving).reduce(0) { $0 + $1.total }
        return HStack(spacing: 10) {
            IOSHistorySummary(
                title: "net",
                value: money(netInfo.net),
                valueColor: netInfo.net < 0 ? HistoryColors.negative : .primary,
                subtitleLabel: netInfo.purchases > 0.005 ? "savingsAccountPurchases" : nil,
                subtitleValue: netInfo.purchases > 0.005 ? money(netInfo.purchases) : nil
            )
            IOSHistorySummary(
                title: "saved",
                value: money(saved),
                valueColor: HistoryColors.transfer,
                subtitlePlain: "depositedToSavings"
            )
        }
    }

    // MARK: Category sections

    @ViewBuilder
    private func categorySection(_ type: TransactionType) -> some View {
        let stats = self.categoryStats(type)
        if !stats.isEmpty {
            let sectionTotal = stats.reduce(0) { $0 + $1.total }
            let maxTotal = stats.map { abs($0.total) }.max() ?? 1
            IOSStatSectionHead(title: sectionTitle(type), dotColor: HistoryColors.dot(for: type), total: money(sectionTotal))
            IOSStatCard {
                ForEach(Array(stats.enumerated()), id: \.element.id) { i, stat in
                    if i > 0 { Divider().overlay(Color.iosBorder) }
                    IOSStatRow(
                        name: stat.name,
                        amount: money(stat.total),
                        color: Color.forCategory(stat.name),
                        fraction: maxTotal == 0 ? 0 : abs(stat.total) / maxTotal,
                        percent: sectionTotal == 0 ? nil : percentString(stat.total / sectionTotal)
                    )
                }
            }
        }
    }

    // MARK: Fixed costs (its own collapsible group of individual overheads)

    @ViewBuilder
    private var fixedCostsSection: some View {
        // Individual overhead amounts were never saved per month — only the monthly
        // total — so scale today's overheads to the period's fixed-cost total so the
        // rows still sum correctly (and match the estimated Netto).
        let monthlyTotal = budget.getOverheadsAmount()
        let periodTotal = fixedCostsPeriodTotal()
        let scale = (period == .month || monthlyTotal == 0) ? 1 : periodTotal / monthlyTotal
        let rows = budget.overheads
            .map { (name: $0.name, amount: $0.getShareOfAmount(monthStartsOn: budget.monthStartsOn) * scale) }
            .filter { abs($0.amount) > 0.005 }
            .sorted { $0.amount > $1.amount }
        if !rows.isEmpty {
            let total = rows.reduce(0) { $0 + $1.amount }
            let maxAmount = rows.map { abs($0.amount) }.max() ?? 1
            let shown = expandedFixed ? rows : Array(rows.prefix(collapseLimit))
            IOSStatSectionHead(title: "overheads", dotColor: HistoryColors.expense, total: money(total))
            IOSStatCard {
                ForEach(Array(shown.enumerated()), id: \.offset) { i, row in
                    if i > 0 { Divider().overlay(Color.iosBorder) }
                    IOSStatRow(
                        name: row.name,
                        amount: money(row.amount),
                        color: Color.forCategory(row.name),
                        fraction: maxAmount == 0 ? 0 : abs(row.amount) / maxAmount
                    )
                }
                if !expandedFixed && rows.count > collapseLimit {
                    Divider().overlay(Color.iosBorder)
                    Button { withAnimation { expandedFixed = true } } label: {
                        HStack(spacing: 6) {
                            Text(String(format: "showMoreCount".localizeString(), rows.count - collapseLimit))
                            Image(systemName: "chevron.down").font(.system(size: 12, weight: .bold))
                        }
                        .font(.system(size: 13.5, weight: .semibold)).foregroundColor(.accentColor)
                        .frame(maxWidth: .infinity).padding(.vertical, 12)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func sectionTitle(_ type: TransactionType) -> String {
        switch type {
        case .expense: return "expenses"
        case .income:  return "incomes"
        case .saving:  return "savings"
        }
    }

    // MARK: Account sections (current balances, point-in-time)

    @ViewBuilder
    private func accountSection(_ type: AccountType, key: String) -> some View {
        let accounts = userViewModel.getAccountsSorted(type: type)
        if !accounts.isEmpty {
            let rows: [(account: Account, balance: Double)] = accounts.map { account in
                let spent = transactionsViewModel.getSpent(user: userViewModel.user, accountId: account.id)
                let incomes = transactionsViewModel.getIncomes(user: userViewModel.user, accountId: account.id)
                return (account, userViewModel.getBalance(accountId: account.id, spent: spent, incomes: incomes))
            }
            let maxBalance = rows.map { abs($0.balance) }.max() ?? 1
            IOSStatSectionHead(title: "\("accounts".localizeString()) · \(key.localizeString())")
            IOSStatCard {
                ForEach(Array(rows.enumerated()), id: \.element.account.id) { i, row in
                    if i > 0 { Divider().overlay(Color.iosBorder) }
                    IOSStatRow(
                        name: row.account.name,
                        amount: money(row.balance),
                        color: AccountVisuals.visual(for: row.account, isMain: row.account.main).colors.first ?? .accentColor,
                        fraction: maxBalance == 0 ? 0 : abs(row.balance) / maxBalance
                    )
                }
            }
        }
    }

    // MARK: Data assembly (live for "this month", saved history otherwise)

    private func categoryStats(_ type: TransactionType) -> [CategoryStat] {
        var stats: [CategoryStat]
        if period == .month {
            stats = userViewModel.getTransactionCategoriesSorted(type: type).compactMap { category in
                let total = transactionsViewModel.getSpent(user: userViewModel.user, transactionCategory: category, monthsBack: 0)
                guard abs(total) > 0.005 else { return nil }
                return CategoryStat(id: category.id, name: category.name, type: type, total: total)
            }
        } else {
            stats = historyViewModel.categoryStats(period: period, type: type, budget: budget)
        }

        // The income / fixed costs / saving you configure in settings are not
        // transactions, but are part of what came in / went out / was set aside —
        // include each as a row in its section.
        if type == .income {
            let configured = configuredIncome()
            if configured > 0.005 {
                stats.append(CategoryStat(id: "__configuredIncome", name: "monthlyIncome".localizeString(), type: .income, total: configured))
            }
        } else if type == .saving {
            let scheduled = scheduledSavings()
            if scheduled > 0.005 {
                stats.append(CategoryStat(id: "__scheduledSaving", name: "scheduledSaving".localizeString(), type: .saving, total: scheduled))
            }
        }

        return stats.sorted { $0.total > $1.total }
    }

    private func configuredIncome() -> Double {
        period == .month ? budget.income : historyViewModel.configuredIncomeTotal(period: period, budget: budget)
    }

    private func scheduledSavings() -> Double {
        period == .month ? budget.getSavings() : historyViewModel.scheduledSavingsTotal(period: period, budget: budget)
    }

    private func fixedCostsPeriodTotal() -> Double {
        period == .month ? budget.getOverheadsAmount() : historyViewModel.fixedCostsTotal(period: period, budget: budget)
    }

    private var hasEstimatedMonths: Bool {
        period != .month && historyViewModel.hasEstimatedMonths(period: period, budget: budget)
    }

    private func netInfo() -> (net: Double, purchases: Double, estimatedFixed: Bool) {
        if period == .month {
            let incomeTransactions = userViewModel.getTransactionCategoriesSorted(type: .income)
                .reduce(0) { $0 + transactionsViewModel.getSpent(user: userViewModel.user, transactionCategory: $1, monthsBack: 0) }
            let income = budget.income + incomeTransactions
            let fixed = budget.getOverheadsAmount()
            let scheduled = budget.getSavings()
            // Transaction expenses only — `fixed` is subtracted separately below.
            let expenses = userViewModel.getTransactionCategoriesSorted(type: .expense)
                .reduce(0) { $0 + transactionsViewModel.getSpent(user: userViewModel.user, transactionCategory: $1, monthsBack: 0) }
            let savingAccountIds = Set(budget.accounts.filter { $0.type == .saving }.map { $0.id })
            let purchases = userViewModel.getTransactionCategoriesSorted(type: .expense)
                .filter { savingAccountIds.contains($0.takesFromAccount) }
                .reduce(0) { $0 + transactionsViewModel.getSpent(user: userViewModel.user, transactionCategory: $1, monthsBack: 0) }
            return (income - fixed - scheduled - expenses, purchases, false)
        }
        let stats = historyViewModel.netStats(period: period, budget: budget)
        return (stats.net, stats.savingsAccountPurchases, stats.estimated)
    }

    private var estimateHint: some View {
        HStack(spacing: 6) {
            Image(systemName: "info.circle").font(.system(size: 11))
            Text("estimatedNote").font(.system(size: 11.5))
        }
        .foregroundColor(.secondary)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 6).padding(.top, 8)
    }
}

struct HistoryView_Previews: PreviewProvider {
    static var previews: some View {
        HistoryView()
    }
}
