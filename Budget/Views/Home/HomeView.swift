//
//  HomeView.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2022-04-12.
//

import Combine
import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var errorHandling: ErrorHandling
    @EnvironmentObject private var userViewModel: UserViewModel
    @EnvironmentObject private var notificationsViewModel: NotificationsViewModel
    @EnvironmentObject private var transactionsViewModel: TransactionsViewModel
    @EnvironmentObject private var standingsViewModel: StandingsViewModel
    @EnvironmentObject private var historyViewModel: HistoryViewModel
    @EnvironmentObject private var quickBalanceViewModel: QuickBalanceViewModel

    private let textSize: Font = .footnote

    var body: some View {
        NavigationView {
            Form {
                let user = self.userViewModel.user
                Section {
                    HStack {
                        Text("income")
                        Spacer()
                        Text(Utility.doubleToLocalCurrency(value: user.budget.income))
                    }
                } header: {
                    Text("incomes")
                }

                Section {
                    ForEach(self.userViewModel.getAccountsSorted()) { account in
                        let spent = self.transactionsViewModel.getSpent(user: self.userViewModel.user, accountId: account.id)
                        let incomes = self.transactionsViewModel.getIncomes(user: self.userViewModel.user, accountId: account.id)
                        let balance = self.userViewModel.getBalance(accountId: account.id, spent: spent, incomes: incomes)
                        if let quickBalanceAccount = self.userViewModel.getQuickBalanceAccount(budgetAccountId: account.id) {
                            let quickBalance = self.quickBalanceViewModel.getQuickBalance(budgetAccountId: account.id)
                            HomeQuickBalanceView(account: account, balance: balance, quickBalanceAccount: quickBalanceAccount, quickBalance: quickBalance)
                        } else {
                            HomeBalanceView(account: account, balance: balance)
                        }
                    }
                } header: {
                    Text("accounts")
                }

                Section {
                    ForEach(self.userViewModel.getTransactionCategoriesSorted(type: .expense)) { transactionCategory in
                        HStack(spacing: 5) {
                            Text(transactionCategory.name.localizeString())
                                .frame(width: 75, alignment: .leading)
                                .font(self.textSize.bold())

                            Spacer()

                            let spent = self.transactionsViewModel.getSpent(user: user, transactionCategory: transactionCategory)
                            Text(Utility.doubleToLocalCurrency(value: spent))
                                .frame(width: 75, alignment: .trailing)
                                .font(self.textSize)
                                .scaledToFill()
                                .minimumScaleFactor(0.1)
                                .lineLimit(1)

                            Spacer()

                            let amount = transactionCategory.getRealAmount(budget: user.budget)

                            // TODO: - Gradient from green to red
                            VStack(spacing: 5) {
                                Text(Utility.doubleToLocalCurrency(value: amount - spent))
                                    .font(self.textSize)
                                    .scaledToFit()
                                    .minimumScaleFactor(0.1)
                                    .lineLimit(1)
                                ProgressView(value: min(spent, amount), total: amount)
                                    .tint(spent < amount ? Color.green : Color.red)
                            }

                            Spacer()

                            Text(Utility.doubleToLocalCurrency(value: amount))
                                .frame(width: 75, alignment: .leading)
                                .font(self.textSize)
                                .scaledToFill()
                                .minimumScaleFactor(0.1)
                                .lineLimit(1)
                        }
                    }
                } header: {
                    Text("expenses")
                }
            }
            .redacted(when: !self.historyViewModel.firstLoadFinished)
            .navigationTitle("home")
            .toolbar {
                ToolbarItem {
                    NavigationLink {
                        NotificationsView()
                    } label: {
                        Image(systemName: "bell")
                            .foregroundColor(.primary)
                            .myBadge(count: self.notificationsViewModel.getNumberOfUnreadNotifications())
                    }
                }
            }
        }
    }

    struct HomeQuickBalanceView: View {
        @EnvironmentObject private var errorHandling: ErrorHandling
        @EnvironmentObject private var userViewModel: UserViewModel
        @EnvironmentObject private var quickBalanceViewModel: QuickBalanceViewModel

        @AppStorage var quickBalance: Double
        @AppStorage var lastUpdate: String

        @State private var animate: Bool = false

        let account: Account
        let balance: Double
        let quickBalanceAccount: QuickBalanceAccount

        init(account: Account, balance: Double, quickBalanceAccount: QuickBalanceAccount, quickBalance: Double) {
            self.account = account
            self.balance = balance
            self.quickBalanceAccount = quickBalanceAccount
            self._quickBalance = AppStorage(wrappedValue: quickBalance, "QuickBalance:" + account.id)
            self._lastUpdate = AppStorage(wrappedValue: "somethingWentWrong".localizeString(), "LastUpdate:" + account.id)
        }

        var body: some View {
            ZStack {
                Button {
                    self.getQuickBalance(quickBalanceAccount: self.quickBalanceAccount)
                } label: {
                    Color.clear
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .zIndex(0)

                VStack(spacing: 5) {
                    HStack {
                        Text(account.name)
                            .bold()
                        Spacer()
                        Text(Utility.doubleToLocalCurrency(value: balance))
                            .bold()
                    }

                    HStack {
                        Text("quickBalance")
                            .font(.footnote)
                        Spacer()
                        Text(Utility.doubleToLocalCurrency(value: quickBalance))
                            .font(.footnote)
                            .scaleEffect(self.animate ? 1.3 : 1)
                            .animation(.spring(dampingFraction: 0.5), value: self.animate)
                    }

                    HStack {
                        Text("difference")
                            .font(.caption)
                        Spacer()
                        Text(Utility.doubleToLocalCurrency(value: balance - quickBalance))
                            .font(.caption)
                    }

                    HStack {
                        Text("latestUpdate")
                            .font(.caption2)
                        Spacer()
                        Text(self.lastUpdate)
                            .onChange(of: self.lastUpdate) { _ in
                                self.animate = true
                                print("Hi: \(self.animate) - \(DispatchTime.now())")
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    print("Middle: \(self.animate) - \(DispatchTime.now())")
                                    self.animate = false
                                    print("Bye: \(self.animate) - \(DispatchTime.now())")
                                }
                            }
                            .font(.caption2)
                            .scaleEffect(self.animate ? 1.3 : 1)
                            .animation(.spring(dampingFraction: 0.5), value: self.animate)
                    }
                }
                .zIndex(1)
            }
        }

        private func getQuickBalance(quickBalanceAccount: QuickBalanceAccount) {
            withAnimation {
                self.quickBalanceViewModel.fetchQuickBalanceFromApi(quickBalanceAccount: quickBalanceAccount) { error in
                    if let error = error {
                        self.errorHandling.handle(error: error)
                        return
                    }

                    // Success
                }
            }
        }
    }

    struct HomeBalanceView: View {
        let account: Account
        let balance: Double

        var body: some View {
            HStack {
                Text(account.name)
                    .bold()
                Spacer()
                Text(Utility.doubleToLocalCurrency(value: balance))
                    .bold()
            }
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
