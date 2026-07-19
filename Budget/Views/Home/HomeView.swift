//
//  HomeView.swift
//  Budget
//
//  v3 — iOS 26 "liquid glass" design (system materials + semantic colors).
//

import Combine
import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var errorHandling: ErrorHandling
    @EnvironmentObject private var userViewModel: UserViewModel
    @EnvironmentObject private var notificationsViewModel: NotificationsViewModel
    @EnvironmentObject private var transactionsViewModel: TransactionsViewModel
    @EnvironmentObject private var quickBalanceViewModel: QuickBalanceViewModel

    // MARK: Derived data

    private var budget: Budget { userViewModel.user.budget }
    private var mainAccountId: String { budget.getMainAccountId(type: .transaction) }
    private var mainAccount: Account { budget.getAccount(id: mainAccountId) }

    private var expenseCategories: [TransactionCategory] {
        userViewModel.getTransactionCategoriesSorted(type: .expense)
    }
    private var mainExpenseCategories: [TransactionCategory] {
        expenseCategories.filter { $0.takesFromAccount == mainAccountId }
    }
    private var separateExpenseCategories: [TransactionCategory] {
        expenseCategories.filter { $0.takesFromAccount != mainAccountId }
    }

    private func spent(_ c: TransactionCategory) -> Double {
        transactionsViewModel.getSpent(user: userViewModel.user, transactionCategory: c)
    }
    private func ceiling(_ c: TransactionCategory) -> Double {
        c.getRealAmount(budget: budget)
    }

    private var spenderat: Double { mainExpenseCategories.reduce(0) { $0 + spent($1) } }
    private var tak: Double { mainExpenseCategories.reduce(0) { $0 + ceiling($1) } }
    private var kvar: Double { tak - spenderat }
    private var overCount: Int { mainExpenseCategories.filter { spent($0) > ceiling($0) }.count }
    private var heroState: BudgetBarState { BudgetBarState.classify(spent: spenderat, ceiling: tak) }
    private var heroRatio: Double { heroState == .over ? 1 : (tak <= 0 ? 0 : min(max(spenderat / tak, 0), 1)) }

    private var accountsTotal: Double {
        userViewModel.getAccountsSorted().reduce(0) { total, account in
            let s = transactionsViewModel.getSpent(user: userViewModel.user, accountId: account.id)
            let i = transactionsViewModel.getIncomes(user: userViewModel.user, accountId: account.id)
            return total + userViewModel.getBalance(accountId: account.id, spent: s, incomes: i)
        }
    }

    private func money(_ v: Double) -> String { Utility.doubleToLocalCurrency(value: v) }

    private var monthName: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: Locale.preferredLanguages.first ?? "sv")
        f.dateFormat = "LLLL"
        return f.string(from: Date()).capitalized
    }
    private var dateSub: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: Locale.preferredLanguages.first ?? "sv")
        f.dateFormat = "EEEE d MMMM"
        let s = f.string(from: Date())
        return s.prefix(1).uppercased() + s.dropFirst()
    }

    // MARK: Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    navRow
                    Text(dateSub).font(.system(size: 14, weight: .medium)).foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 2).padding(.top, 2).padding(.bottom, 16)

                    heroCard
                    IOSSectionHead(title: "accounts", trailing: "\("total".localizeString()) \(money(accountsTotal))")
                    accountsCard
                    IOSSectionHead(title: "expenses", trailing: monthName)
                    expensesCard
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 120)
            }
            .background(backgroundView)
            .navigationBarHidden(true)
        }
        .redacted(when: userViewModel.user.id.isEmpty)
    }

    private var backgroundView: some View {
        Color(.systemBackground).ignoresSafeArea()
    }

    private var navRow: some View {
        HStack {
            Text("home").font(.system(size: 34, weight: .bold)).foregroundColor(.primary)
            Spacer()
            NavigationLink { NotificationsView() } label: {
                Image(systemName: "bell")
                    .font(.system(size: 18, weight: .medium)).foregroundColor(.primary)
                    .frame(width: 42, height: 42)
                    .background(Color(.secondarySystemBackground), in: Circle())
                    .overlay(Circle().strokeBorder(Color.primary.opacity(0.06), lineWidth: 1))
                    .myBadge(count: notificationsViewModel.getNumberOfUnreadNotifications())
            }
        }
        .padding(.top, 4)
    }

    // MARK: Hero

    private var heroCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("\("monthlyBudget".localizeString()) · \(mainAccount.name)")
                    Spacer()
                    Text(monthName)
                }
                .font(.system(size: 12, weight: .semibold)).textCase(.uppercase).kerning(0.5)
                .foregroundColor(.secondary)

                FlowLayout(spacing: 10) {
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text(money(kvar))
                            .font(.system(size: 29, weight: .bold)).monospacedDigit()
                            .foregroundColor(kvar < 0 ? .red : .primary)
                            .fixedSize()
                        Text(kvar < 0 ? "overBudget" : "budgetLeftTag")
                            .font(.system(size: 12.5, weight: .semibold)).foregroundColor(.secondary)
                            .fixedSize()
                    }
                    heroChip
                }
                .padding(.top, 7)

                VStack(spacing: 6) {
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.primary.opacity(0.12))
                        Rectangle().fill(heroState.tint).scaleEffect(x: heroRatio, y: 1, anchor: .leading)
                    }
                    .frame(height: 9)
                    .clipShape(Capsule())
                    HStack {
                        Text("\("spent".localizeString()) \(money(spenderat))")
                        Spacer()
                        Text("\("ceiling".localizeString()) \(money(tak))")
                    }
                    .font(.system(size: 11.5, weight: .semibold)).foregroundColor(.secondary).monospacedDigit()
                }
                .padding(.top, 11)

                Divider().overlay(Color.primary.opacity(0.06)).padding(.top, 11)

                HStack {
                    footStat("income", money(budget.income))
                    Spacer()
                    footStat("totalBalance", money(accountsTotal))
                }
                .padding(.top, 10)
            }
            .padding(16)
        }
    }

    private var heroChip: some View {
        let over = overCount > 0
        let text = over ? String(format: "categoriesOverCeiling".localizeString(), overCount)
                        : "allWithinCeiling".localizeString()
        return Text(text)
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(over ? .red : .secondary)
            .padding(.horizontal, 10).padding(.vertical, 5)
            .background(over ? Color.red.opacity(0.14) : Color.primary.opacity(0.10))
            .clipShape(Capsule())
            .fixedSize()
    }

    private func footStat(_ labelKey: String, _ value: String) -> some View {
        (Text(LocalizedStringKey(labelKey)).foregroundColor(.secondary)
         + Text(" ") + Text(value).foregroundColor(.primary).fontWeight(.bold))
            .font(.system(size: 12.5, weight: .medium)).monospacedDigit()
    }

    // MARK: Accounts

    private var accountsCard: some View {
        GlassCard {
            VStack(spacing: 0) {
                let all = userViewModel.getAccountsSorted()
                let mains = all.filter { $0.main && $0.type == .transaction }
                let accounts = mains + all.filter { !($0.main && $0.type == .transaction) }
                ForEach(Array(accounts.enumerated()), id: \.element.id) { idx, account in
                    if idx > 0 {
                        Divider().overlay(Color.primary.opacity(0.06)).padding(.leading, 64)
                    }
                    accountRow(account)
                }
            }
        }
    }

    @ViewBuilder
    private func accountRow(_ account: Account) -> some View {
        let s = transactionsViewModel.getSpent(user: userViewModel.user, accountId: account.id)
        let i = transactionsViewModel.getIncomes(user: userViewModel.user, accountId: account.id)
        let balance = userViewModel.getBalance(accountId: account.id, spent: s, incomes: i)
        let isMain = account.main && account.type == .transaction
        if let qba = userViewModel.getQuickBalanceAccount(budgetAccountId: account.id) {
            IOSQuickBalanceRow(account: account, balance: balance, isMain: isMain, quickBalanceAccount: qba)
        } else {
            IOSAccountRow(account: account, balance: balance, isMain: isMain)
        }
    }

    // MARK: Expenses

    private var expensesCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 12) {
                    BudgetRing(progress: heroRatio, color: heroState.tint,
                               label: "\(tak <= 0 ? 0 : Int((spenderat / tak * 100).rounded()))%")
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(money(spenderat)) \("of".localizeString()) \(money(tak)) · \(mainAccount.name)")
                            .font(.system(size: 14.5, weight: .semibold)).monospacedDigit()
                        Text(String(format: "categoriesOverOfTotal".localizeString(), overCount, mainExpenseCategories.count))
                            .font(.system(size: 12.5)).foregroundColor(.secondary)
                    }
                    Spacer(minLength: 0)
                }
                .padding(.vertical, 14)
                Divider().overlay(Color.primary.opacity(0.06))

                IOSGroupLabel(title: mainAccount.name, dotColor: AccountVisuals.dotColor(for: mainAccount))
                ForEach(Array(mainExpenseCategories.enumerated()), id: \.element.id) { idx, cat in
                    IOSBudgetRow(name: cat.name, spent: spent(cat), ceiling: ceiling(cat), showsTopDivider: idx > 0)
                }

                if !separateExpenseCategories.isEmpty {
                    IOSGroupLabel(title: "separateAccounts", topBorder: true)
                    ForEach(Array(separateExpenseCategories.enumerated()), id: \.element.id) { idx, cat in
                        IOSBudgetRow(name: cat.name, spent: spent(cat), ceiling: ceiling(cat),
                                     dotColor: AccountVisuals.dotColor(for: budget.getAccount(id: cat.takesFromAccount)),
                                     showsTopDivider: idx > 0)
                    }
                }
            }
            .padding(.horizontal, 16).padding(.bottom, 10)
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View { HomeView() }
}
