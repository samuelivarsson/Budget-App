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
    @State private var period: HistoryPeriod = .month
    @State private var expandedFixed: Bool = false
    @State private var showAverage: Bool = false
    private let collapseLimit = 4

    private var budget: Budget { userViewModel.user.budget }
    private func money(_ v: Double) -> String { Utility.doubleToLocalCurrency(value: v) }
    private func percentString(_ frac: Double) -> String { "\(Int((frac * 100).rounded())) %" }

    /// Number of months the selected period spans (1 for the live current month).
    private var monthCount: Int {
        period == .month ? 1 : max(1, historyViewModel.plannedTotals(period: period, budget: budget).monthCount)
    }
    /// Days elapsed so far in the current budget month (at least 1). Matches the
    /// Transactions view's "snitt per dag" day count so the two screens agree.
    private var daysElapsedThisMonth: Int {
        let (from, to) = Utility.getBudgetPeriod(monthStartsOn: budget.monthStartsOn)
        let end = min(Date(), to)
        return max(1, Calendar.current.dateComponents([.day], from: from, to: end).day ?? 1)
    }
    /// Divisor applied to displayed amounts in average mode: per day for the live
    /// current month (a single partial month), per month otherwise.
    private var factor: Double {
        guard showAverage else { return 1.0 }
        let divisor = period == .month ? Double(daysElapsedThisMonth) : Double(monthCount)
        return 1.0 / divisor
    }
    /// Suffix shown after averaged summary values ("/dag" this month, "/mån" otherwise).
    private var averageSuffix: String {
        (period == .month ? "perDaySuffix" : "perMonthSuffix").localizeString()
    }
    /// A money string for an averageable amount (respects the Total/Snitt toggle).
    private func avgMoney(_ v: Double) -> String { money(v * factor) }

    // MARK: Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    IOSHistoryPeriodBar(selection: $period)
                        .padding(.top, 4).padding(.bottom, 2)
                    Picker("", selection: $showAverage) {
                        Text("total").tag(false)
                        Text("average").tag(true)
                    }
                    .pickerStyle(.segmented)
                    .padding(.top, 10)
                    summaryRow.padding(.top, 12)
                    if hasEstimatedMonths { estimateHint }

                    categorySection(.expense)
                    fixedCostsSection
                    categorySection(.income)
                    categorySection(.transfer)

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
        let net = self.netInfo()
        let sparat = self.sparatInfo()
        let suffix = showAverage ? " " + averageSuffix : ""
        let hasWithdrawals = sparat.withdrawals > 0.005
        let netSubtitle = "+\(avgMoney(net.income)) / −\(avgMoney(net.expenses))"
        let sparkonto = self.mainSavingsNet()
        return HStack(spacing: 10) {
            IOSHistorySummary(
                title: "net",
                value: avgMoney(net.net) + suffix,
                valueColor: net.net < 0 ? HistoryColors.negative : .primary,
                subtitleValue: netSubtitle,
                line2Label: "savingsRate",
                line2Value: savingsRateText(net: net.net, income: net.income),
                line2ValueColor: net.net < 0 ? HistoryColors.negative : .primary
            )
            IOSHistorySummary(
                title: "saved",
                value: avgMoney(sparat.net) + suffix,
                valueColor: HistoryColors.transfer,
                subtitleLabel: hasWithdrawals ? "savingsWithdrawals" : nil,
                subtitleValue: hasWithdrawals ? avgMoney(sparat.withdrawals) : nil,
                subtitlePlain: hasWithdrawals ? nil : "depositedToSavings",
                line2Label: sparkonto.name,
                line2Value: signedAvg(sparkonto.net) + suffix,
                line2ValueColor: sparkonto.net < 0 ? HistoryColors.negative : HistoryColors.transfer
            )
        }
    }

    private func savingsRateText(net: Double, income: Double) -> String {
        guard income > 0.005 else { return "–" }
        return "\(Int((net / income * 100).rounded())) %"
    }
    private func signedAvg(_ v: Double) -> String { (v >= 0 ? "+" : "") + avgMoney(v) }

    /// Net movement of the main savings account over the period, including its
    /// scheduled saving: scheduled(main) + deposits(main) − withdrawals(main).
    private func mainSavingsNet() -> (name: String, net: Double) {
        let id = budget.getMainAccountId(type: .saving)
        guard !id.isEmpty else { return ("", 0) }
        let name = budget.getAccount(id: id).name
        if period == .month {
            let scheduled = budget.getSavingAmount(accountId: id)
            let deposits = budget.transactionCategories.filter { $0.givesToAccount == id }.reduce(0) { $0 + liveSpent($1) }
            let withdrawals = budget.transactionCategories.filter { $0.takesFromAccount == id }.reduce(0) { $0 + liveSpent($1) }
            return (name, scheduled + deposits - withdrawals)
        }
        // Saved periods: scheduled isn't stored per-account, so scale today's
        // per-account scheduled by the number of months (like other planned figures).
        let months = historyViewModel.monthCount(period: period, budget: budget)
        let scheduled = budget.getSavingAmount(accountId: id) * Double(months)
        let s = historyViewModel.savingsStats(period: period, budget: budget, accountId: id)
        return (name, scheduled + s.deposits - s.withdrawals)
    }

    // MARK: Category sections

    @ViewBuilder
    private func categorySection(_ type: TransactionType) -> some View {
        let stats = self.categoryStats(type)
        if !stats.isEmpty {
            let sectionTotal = stats.reduce(0) { $0 + $1.total }
            let maxTotal = stats.map { abs($0.total) }.max() ?? 1
            IOSStatSectionHead(title: sectionTitle(type), dotColor: HistoryColors.dot(for: type), total: avgMoney(sectionTotal))
            IOSStatCard {
                ForEach(Array(stats.enumerated()), id: \.element.id) { i, stat in
                    if i > 0 { Divider().overlay(Color.iosBorder) }
                    IOSStatRow(
                        name: stat.name,
                        amount: avgMoney(stat.total),
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
            IOSStatSectionHead(title: "overheads", dotColor: HistoryColors.expense, total: avgMoney(total))
            IOSStatCard {
                ForEach(Array(shown.enumerated()), id: \.offset) { i, row in
                    if i > 0 { Divider().overlay(Color.iosBorder) }
                    IOSStatRow(
                        name: row.name,
                        amount: avgMoney(row.amount),
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
        case .transfer:  return "transfer"
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

    /// Sections are grouped by effective FLOW (income/expense/transfer), not the
    /// declared type — so e.g. a Påfyllning (income that also draws from an account)
    /// lands under Transfer.
    private func categoryStats(_ flow: TransactionType) -> [CategoryStat] {
        var stats: [CategoryStat]
        if period == .month {
            stats = budget.transactionCategories
                .filter { $0.moneyFlow == flow }
                .compactMap { category in
                    let total = liveSpent(category)
                    guard abs(total) > 0.005 else { return nil }
                    return CategoryStat(id: category.id, name: category.name, type: flow, total: total)
                }
        } else {
            stats = historyViewModel.categoryStats(period: period, type: flow, budget: budget)
        }

        // The income / saving you configure in settings are not transactions, but
        // are part of what came in / was set aside — include each as a row.
        if flow == .income {
            let configured = configuredIncome()
            if configured > 0.005 {
                stats.append(CategoryStat(id: "__configuredIncome", name: "monthlyIncome".localizeString(), type: .income, total: configured))
            }
        } else if flow == .transfer {
            let scheduled = scheduledSavings()
            if scheduled > 0.005 {
                stats.append(CategoryStat(id: "__scheduledSaving", name: "scheduledSaving".localizeString(), type: .transfer, total: scheduled))
            }
        }

        return stats.sorted { $0.total > $1.total }
    }

    // MARK: Savings-account helpers (live month)

    private func savingsAccountIds() -> Set<String> {
        Set(budget.accounts.filter { $0.type == .saving }.map { $0.id })
    }
    private func touchesSavings(_ c: TransactionCategory) -> Bool {
        let ids = savingsAccountIds()
        return ids.contains(c.takesFromAccount) || ids.contains(c.givesToAccount)
    }
    private func liveSpent(_ c: TransactionCategory) -> Double {
        transactionsViewModel.getSpent(user: userViewModel.user, transactionCategory: c, monthsBack: 0)
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

    /// Net = planned income + operational income − fixed − scheduled − operational
    /// expenses. "Operational" excludes anything touching a savings account (that's
    /// savings activity, tracked by `sparatInfo`). Transfers are excluded too.
    private func netInfo() -> (net: Double, income: Double, expenses: Double) {
        if period == .month {
            let cats = budget.transactionCategories
            let income = budget.income + cats
                .filter { $0.moneyFlow == .income && !touchesSavings($0) }
                .reduce(0) { $0 + liveSpent($1) }
            let expenses = cats
                .filter { $0.moneyFlow == .expense && !touchesSavings($0) }
                .reduce(0) { $0 + liveSpent($1) }
            let net = income - budget.getOverheadsAmount() - budget.getSavings() - expenses
            return (net, income, expenses)
        }
        let s = historyViewModel.netStats(period: period, budget: budget)
        return (s.net, s.income, s.expenses)
    }

    /// Net change in savings accounts = scheduled + deposits − withdrawals.
    /// `withdrawals` (money drawn out of savings — Påfyllning, Sparkonto köp) is
    /// surfaced as the "Uttag" breakdown on the Sparat card.
    private func sparatInfo() -> (net: Double, withdrawals: Double) {
        let scheduled = scheduledSavings()
        if period == .month {
            let ids = savingsAccountIds()
            let cats = budget.transactionCategories
            let deposits = cats.filter { ids.contains($0.givesToAccount) }.reduce(0) { $0 + liveSpent($1) }
            let withdrawals = cats.filter { ids.contains($0.takesFromAccount) }.reduce(0) { $0 + liveSpent($1) }
            return (scheduled + deposits - withdrawals, withdrawals)
        }
        let s = historyViewModel.savingsStats(period: period, budget: budget)
        return (scheduled + s.deposits - s.withdrawals, s.withdrawals)
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
