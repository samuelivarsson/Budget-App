//
//  TransactionCategoryAmountsView.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2023-03-04.
//

import SwiftUI

struct TransactionCategoryAmountsView: View {
    @EnvironmentObject private var userViewModel: UserViewModel
    @EnvironmentObject private var errorHandling: ErrorHandling

    var body: some View {
        Form {
            if let user = self.userViewModel.user {
                ForEach(TransactionType.allCases, id: \.self) { type in
                    Section {
                        let sortedTGA = user.budget.transactionCategoryAmounts.sorted { $0.categoryName < $1.categoryName }
                        let filteredTGA = sortedTGA.filter { self.userViewModel.getTransactionCategory(id: $0.categoryId).type == type }
                        ForEach(filteredTGA) { transactionCategoryAmount in
                            NavigationLink {
                                TransactionCategoryAmountView(transactionCategoryAmount: transactionCategoryAmount)
                            } label: {
                                HStack(spacing: 0) {
                                    Text(LocalizedStringKey(transactionCategoryAmount.categoryName))
                                    Text(": ")
                                    let amountText = Utility.doubleToLocalCurrency(value: transactionCategoryAmount.getRealAmount(budget: user.budget))
                                    Text(amountText)
                                }
                            }
                        }.onDelete(perform: { indexSet in
                            self.deleteTransactionCategoryAmount(offsets: indexSet, transactionCategoryAmounts: filteredTGA)
                        })
                    } header: {
                        Text(type.description())
                    }
                }
            }
        }
        .navigationTitle("transactionCategoryAmounts")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                EditButton()
            }
            ToolbarItem {
                NavigationLink {
                    TransactionCategoryAmountView(add: true)
                } label: {
                    Label("Add Item", systemImage: "plus")
                }
            }
        }
    }

    private func deleteTransactionCategoryAmount(offsets: IndexSet, transactionCategoryAmounts: [TransactionCategoryAmount]) {
        withAnimation {
            offsets.map { transactionCategoryAmounts[$0] }.forEach { transactionCategoryAmount in
                self.userViewModel.deleteTransactionCategoryAmount(transactionCategoryAmount: transactionCategoryAmount) { error in
                    if let error = error {
                        self.errorHandling.handle(error: error)
                        return
                    }

                    // Success
                }
            }
        }
    }
}

struct TransactionCategoryAmountsView_Previews: PreviewProvider {
    static var previews: some View {
        TransactionCategoryAmountsView()
    }
}
