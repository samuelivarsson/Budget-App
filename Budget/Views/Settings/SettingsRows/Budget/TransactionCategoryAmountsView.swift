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
            Section {
                Picker("category", selection: self.$userViewModel.user.budget.transactionCategoryThatUsesRest) {
                    ForEach(self.userViewModel.user.budget.transactionCategoryAmounts) { transactionCategoryAmount in
                        Text(transactionCategoryAmount.categoryName.localizeString()).tag(transactionCategoryAmount.categoryId)
                    }
                }
                .onChange(of: self.userViewModel.user.budget.transactionCategoryThatUsesRest) { _ in
                    self.userViewModel.setUserData { error in
                        if let error = error {
                            self.errorHandling.handle(error: error)
                            return
                        }
                        
                        // Success
                    }
                }
            } header: {
                Text("categoryThatUsesRest")
            }

            Section {
                HStack {
                    Text("remaining")
                    Spacer()
                    Text(Utility.doubleToLocalCurrency(value: self.userViewModel.user.budget.getRemaining()))
                }

                let sortedTGA = self.userViewModel.user.budget.transactionCategoryAmounts.sorted { $0.categoryName < $1.categoryName }
                let filteredTGA = sortedTGA.filter { self.userViewModel.getTransactionCategory(id: $0.categoryId).type == .expense }
                ForEach(filteredTGA) { transactionCategoryAmount in
                    NavigationLink {
                        TransactionCategoryAmountView(transactionCategoryAmount: transactionCategoryAmount)
                    } label: {
                        HStack(spacing: 0) {
                            Text(LocalizedStringKey(transactionCategoryAmount.categoryName))
                            Text(": ")
                            let amountText = Utility.doubleToLocalCurrency(value: transactionCategoryAmount.getRealAmount(budget: self.userViewModel.user.budget))
                            Text(amountText)
                        }
                    }
                }.onDelete(perform: { indexSet in
                    self.deleteTransactionCategoryAmount(offsets: indexSet, transactionCategoryAmounts: filteredTGA)
                })
            } header: {
                Text("expenses")
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
