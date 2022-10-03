//
//  SetCategoriesView.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2022-04-14.
//

import SwiftUI

struct TransactionCategoriesView: View {
    @EnvironmentObject private var errorHandling: ErrorHandling
    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var userViewModel: UserViewModel
    
    var body: some View {
        Form {
            if var user = self.userViewModel.user {
                if var transactionCategories = user.transactionCategories {
                    ForEach(TransactionType.allCases, id: \.self) { type in
                        Section {
                            var sortedTG = transactionCategories.filter({$0.type == type}).sorted(by: {$0.name.lowercased() < $1.name.lowercased()})
                            ForEach(sortedTG) { transactionCategory in
                                NavigationLink {
                                    TransactionCategoryView(transactionCategory: transactionCategory)
                                } label: {
                                    Text(LocalizedStringKey(transactionCategory.name))
                                }
                            }.onDelete(perform: { indexSet in
                                self.deleteTransactionCategory(offsets: indexSet, transactionCategories: sortedTG)
                            })
                        } header: {
                            Text(type.description())
                        }
                    }
                } else {
                    Text("noCategoriesFound")
                }
            } else {
                Text("No user found!")
            }
        }
        .navigationTitle("transactionCategories")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                EditButton()
            }
            ToolbarItem {
                NavigationLink {
                    TransactionCategoryView(add: true)
                } label: {
                    Label("Add Item", systemImage: "plus")
                }
            }
        }
    }
    
    private func deleteTransactionCategory(offsets: IndexSet, transactionCategories: [TransactionCategory]) {
        withAnimation {
            offsets.map { transactionCategories[$0] }.forEach { transactionCategory in
                self.userViewModel.deleteTransactionCategory(transactionCategory: transactionCategory) { error in
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

struct TransactionCategoriesView_Previews: PreviewProvider {
    static var previews: some View {
        TransactionCategoriesView()
    }
}
