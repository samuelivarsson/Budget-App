//
//  BudgetView.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2023-03-04.
//

import SwiftUI

struct BudgetView: View {
    @EnvironmentObject private var errorHandling: ErrorHandling
    @EnvironmentObject private var userViewModel: UserViewModel
    
    var body: some View {
        Form {
            Section {
                NavigationLink {
                    AccountsView()
                } label: {
                    Label("accounts", systemImage: "creditcard.and.123")
                }
                
                NavigationLink {
                    IncomeView(income: self.userViewModel.user.budget.income)
                } label: {
                    Label("income", systemImage: "bag.badge.plus")
                }
                
                NavigationLink {
                    TransactionCategoriesView()
                } label: {
                    Label("transactionCategories", systemImage: "arrow.left.arrow.right")
                }
                
                NavigationLink {
                    OverheadsView()
                } label: {
                    Label("overheads", systemImage: "list.bullet")
                }
                
                NavigationLink {
                    SavingsView(savingsPercentage: self.userViewModel.user.budget.savingsPercentage)
                } label: {
                    Label("savings", systemImage: "percent")
                }
            }
        }
        .navigationTitle("budget")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct BudgetView_Previews: PreviewProvider {
    static var previews: some View {
        BudgetView()
    }
}
