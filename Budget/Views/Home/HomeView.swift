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
                    ForEach(self.userViewModel.getTransactionCategoriesSorted(type: .expense)) { transactionCategory in
                        HStack {
                            Text(transactionCategory.name.localizeString())
                                .frame(maxWidth: 150)
                                .multilineTextAlignment(.leading)

                            Spacer()

                            let spent = self.transactionsViewModel.getSpent(user: user, transactionCategory: transactionCategory)
                            Text(Utility.doubleToLocalCurrency(value: spent))
                                .lineLimit(1)
                                .font(self.textSize)

                            Spacer()

                            let amount = transactionCategory.getRealAmount(budget: user.budget)

                            ProgressView(value: min(spent, amount), total: amount)
                                .padding()

                            Spacer()

                            Text(Utility.doubleToLocalCurrency(value: amount))
                                .lineLimit(1)
                                .font(self.textSize)
                        }
                    }
                } header: {
                    Text("expenses")
                }
            }
            .redacted(when: !self.transactionsViewModel.firstLoadFinished)
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
            redacted(reason: .placeholder)
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
