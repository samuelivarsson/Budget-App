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
                    ForEach(user.budget.transactionCategoryAmounts.sorted { $0.categoryName < $1.categoryName }) { transactionCategoryAmount in
                        HStack {
                            let name = NSLocalizedString(transactionCategoryAmount.categoryName, comment: "")
                            Text(name)
                                .frame(maxWidth: 150)
                                .multilineTextAlignment(.leading)

                            Spacer()

                            let spent = self.transactionsViewModel.getSpent(user: user, transactionCategoryAmount: transactionCategoryAmount)
                            Text(Utility.doubleToLocalCurrency(value: spent))
                                .lineLimit(1)
                                .font(self.textSize)

                            Spacer()

                            let amount = transactionCategoryAmount.getRealAmount(budget: user.budget)

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
