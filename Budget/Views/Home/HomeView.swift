//
//  HomeView.swift
//  Budget
//

import Combine
import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var errorHandling: ErrorHandling
    @EnvironmentObject private var userViewModel: UserViewModel
    @EnvironmentObject private var notificationsViewModel: NotificationsViewModel
    @EnvironmentObject private var transactionsViewModel: TransactionsViewModel
    @EnvironmentObject private var quickBalanceViewModel: QuickBalanceViewModel

    private var monthEyebrow: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: Locale.preferredLanguages.first ?? "sv")
        f.dateFormat = "LLLL yyyy"
        return f.string(from: Date()).capitalized
    }

    private var expenseCategories: [TransactionCategory] {
        userViewModel.getTransactionCategoriesSorted(type: .expense)
    }

    private var mainTransactionAccountId: String {
        userViewModel.user.budget.getMainAccountId(type: .transaction)
    }

    /// Only categories that draw from the main transaction account count toward
    /// the hero totals (Spenderat / Budgettak / Kvar) — excludes e.g. Sparkonto
    /// and Resor categories that take from other accounts.
    private var mainExpenseCategories: [TransactionCategory] {
        expenseCategories.filter { $0.takesFromAccount == mainTransactionAccountId }
    }

    private func spent(_ c: TransactionCategory) -> Double {
        transactionsViewModel.getSpent(user: userViewModel.user, transactionCategory: c)
    }
    private func ceiling(_ c: TransactionCategory) -> Double {
        c.getRealAmount(budget: userViewModel.user.budget)
    }

    private var summary: HomeSummary {
        HomeSummary(income: userViewModel.user.budget.income,
                    rows: mainExpenseCategories.map { (spent($0), ceiling($0)) })
    }

    private var accountsTotal: Double {
        userViewModel.getAccountsSorted().reduce(0) { total, account in
            let s = transactionsViewModel.getSpent(user: userViewModel.user, accountId: account.id)
            let i = transactionsViewModel.getIncomes(user: userViewModel.user, accountId: account.id)
            return total + userViewModel.getBalance(accountId: account.id, spent: s, incomes: i)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 26) {
                    ScreenHeader(eyebrow: monthEyebrow, title: "home".localizeString()) {
                        NavigationLink { NotificationsView() } label: {
                            Image(systemName: "bell")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.appMuted)
                                .frame(width: 42, height: 42)
                                .background(Color.appCard)
                                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.appLine))
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                .myBadge(count: notificationsViewModel.getNumberOfUnreadNotifications())
                        }
                    }

                    HeroCard(label: "budgetRemaining".localizeString(),
                             summary: summary,
                             incomeLabel: "income".localizeString(),
                             spentLabel: "spent".localizeString(),
                             ceilingLabel: "ceiling".localizeString())

                    accountsSection
                    expensesSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 40)
            }
            .background(Color.appBackground.ignoresSafeArea())
            .navigationBarHidden(true)
        }
        // Redact while the user is still loading. `user.id.isEmpty` is an
        // observable signal (the codebase's convention for "not loaded yet"),
        // so the view reliably un-redacts once data arrives — unlike the
        // non-observable `Utility.firstLoadFinished` static.
        .redacted(when: userViewModel.user.id.isEmpty)
    }

    private var accountsSection: some View {
        VStack(spacing: 10) {
            SectionHeader("accounts".localizeString(),
                          trailing: "total".localizeString() + " " + Utility.doubleToLocalCurrency(value: accountsTotal))
            ForEach(userViewModel.getAccountsSorted()) { account in
                let s = transactionsViewModel.getSpent(user: userViewModel.user, accountId: account.id)
                let i = transactionsViewModel.getIncomes(user: userViewModel.user, accountId: account.id)
                let balance = userViewModel.getBalance(accountId: account.id, spent: s, incomes: i)
                if let qba = userViewModel.getQuickBalanceAccount(budgetAccountId: account.id) {
                    HomeQuickBalanceRow(account: account, balance: balance,
                                        quickBalanceAccount: qba,
                                        updatedLabel: "updated".localizeString())
                } else {
                    AccountRow(name: account.name, meta: nil, amount: balance, deviation: nil, onTap: nil)
                }
            }
        }
    }

    private var expensesSection: some View {
        let rows = expenseCategories
            .map { (cat: $0, spent: spent($0), ceiling: ceiling($0)) }
            .sorted { a, b in
                let ra = a.ceiling <= 0 ? Double.greatestFiniteMagnitude : a.spent / a.ceiling
                let rb = b.ceiling <= 0 ? Double.greatestFiniteMagnitude : b.spent / b.ceiling
                return ra > rb
            }
        let within = rows.filter { $0.spent <= $0.ceiling }.count
        return VStack(spacing: 10) {
            SectionHeader("expenses".localizeString(),
                          trailing: String(format: "withinCeiling".localizeString(), within, rows.count))
            AppCard(padding: 0) {
                VStack(spacing: 0) {
                    ForEach(Array(rows.enumerated()), id: \.element.cat.id) { idx, row in
                        if idx > 0 { Divider().overlay(Color.appLine) }
                        BudgetRow(name: row.cat.name.localizeString(),
                                  spent: row.spent, ceiling: row.ceiling,
                                  remainingLabel: "remainingShort".localizeString(),
                                  overLabel: "overCeilingBy".localizeString())
                    }
                }
            }
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View { HomeView() }
}
