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
                    IncomeView(income: self.userViewModel.user.budget.income)
                } label: {
                    Label("income", systemImage: "bag.badge.plus")
                }
                
                NavigationLink {
                    TransactionCategoryAmountsView()
                } label: {
                    Label("transactionCategoryAmounts", systemImage: "arrow.left.arrow.right")
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
