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
    private let labelSize: Font = .system(size: 10)

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
                    HStack(spacing: 5) {
                        Text("category")
                            .frame(width: 75, alignment: .leading)
                            .font(self.textSize.bold())
                        Spacer()
                        Text("spent")
                            .frame(width: 75, alignment: .trailing)
                            .font(self.labelSize.bold())
                            .minimumScaleFactor(0.1)
                            .lineLimit(1)
                        Spacer()
                        Text("remaining")
                            .font(self.labelSize.bold())
                            .scaledToFit()
                            .minimumScaleFactor(0.1)
                            .lineLimit(1)
                        Spacer()
                        Text("ceiling")
                            .frame(width: 75, alignment: .leading)
                            .font(self.labelSize.bold())
                            .minimumScaleFactor(0.1)
                            .lineLimit(1)
                    }
                    let transactionCategories = self.userViewModel.getTransactionCategoriesSorted(type: .expense)
                    ForEach(transactionCategories) { transactionCategory in
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

                            VStack(spacing: 5) {
                                Text(Utility.doubleToLocalCurrency(value: amount - spent))
                                    .font(self.textSize)
                                    .scaledToFit()
                                    .minimumScaleFactor(0.1)
                                    .lineLimit(1)
                                CustomProgressView(value: min(spent, amount), total: amount)
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
            .redacted(when: !Utility.firstLoadFinished)
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
    
    struct CustomProgressView: View {
        var value: Double
        var total: Double
        
        var body: some View {
            let progress = value == 0 || total == 0 ? 0 : CGFloat(min(max(value/total, 0), 1))
            let startColor = Color.green
            let endColor: Color
            
            switch progress {
            case 0..<0.5:
                endColor = startColor.interpolate(to: .yellow, fraction: progress * 2)
            default:
                endColor = .yellow.interpolate(to: .orange, fraction: (progress - 0.5) * 2)
            }
            
            let newTotal = total == 0 ? 0.000001 : total
            return ProgressView(value: value, total: newTotal)
                .tint(value < newTotal ? endColor : Color.red)
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
                        let difference = round(quickBalance*100) - round(balance*100) == 0 ? 0 : quickBalance - balance
                        Text(Utility.doubleToLocalCurrency(value: difference))
                            .font(.caption)
                    }

                    HStack {
                        Text("latestUpdate")
                            .font(.caption2)
                        Spacer()
                        Text(self.lastUpdate)
                            .onChange(of: self.lastUpdate) { _ in
                                self.animate = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    self.animate = false
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
