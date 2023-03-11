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

    var body: some View {
        NavigationView {
            Form {
                let user = self.userViewModel.getUser(errorHandling: self.errorHandling)
                let budget = user.budget
                Section {
                    HStack {
                        Text("income")
                        Spacer()
//                        let income = "\(budget.income)"
//                        Text(income)
                    }
                }

                Section {
                    ForEach(budget.transactionCategoryAmounts) { transactionCategoryAmount in
                        HStack {
                            let name = NSLocalizedString(transactionCategoryAmount.categoryName, comment: "")
                            Text(name)
                            
                            let spent = self.transactionsViewModel.getSpent(user: user, transactionCategoryAmount: transactionCategoryAmount)
                            var amount = transactionCategoryAmount.getRealAmount(budget: budget)

                            ProgressView(value: spent, total: amount)
                                .padding()
                        }
                    }
                }
            }
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

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
