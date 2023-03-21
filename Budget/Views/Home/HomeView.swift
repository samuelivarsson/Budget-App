//
//  HomeView.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2022-04-12.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var errorHandling: ErrorHandling
    @EnvironmentObject private var userViewModel: UserViewModel
    @EnvironmentObject private var notificationsViewModel: NotificationsViewModel
    @EnvironmentObject private var transactionsViewModel: TransactionsViewModel
    @EnvironmentObject private var standingsViewModel: StandingsViewModel

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
                        HStack {
                            Text(account.name)
                            Spacer()
                            let spent = self.transactionsViewModel.getSpent(user: self.userViewModel.user, accountId: account.id)
                            let incomes = self.transactionsViewModel.getIncomes(user: self.userViewModel.user, accountId: account.id)
                            let balance = self.userViewModel.getBalance(accountId: account.id, spent: spent, incomes: incomes)
                            Text(Utility.doubleToLocalCurrency(value: balance))
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

                // TODO: - New section for other people's cateogires (if same name as yours -> use yours)
                // TODO: - Add standings to own Tab
            }
            .redacted(when: !self.standingsViewModel.firstLoadFinished)
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
}

extension View {
    @ViewBuilder
    func redacted(when condition: Bool) -> some View {
        if !condition {
            unredacted()
        } else {
            self.redacted(reason: .placeholder)
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
