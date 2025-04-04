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
            if self.userViewModel.getTransactionCategoriesSorted().count < 1 {
                Text("noTransactionCategories")
            } else {
                Section {
                    Picker("category", selection: self.$userViewModel.user.budget.transactionCategoryThatUsesRest) {
                        Text("none").tag("")
                        ForEach(self.userViewModel.getTransactionCategoriesSorted(type: .expense)) { transactionCategory in
                            Text(transactionCategory.name.localizeString()).tag(transactionCategory.id)
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
                } footer: {
                    Text("categoryThatUsesRestOfMainTransactionAccount")
                }

                ForEach(TransactionType.allCases, id: \.self) { type in
                    Section {
                        ForEach(self.userViewModel.getTransactionCategoriesSorted(type: type)) { transactionCategory in
                            NavigationLink {
                                TransactionCategoryView(transactionCategory: transactionCategory)
                            } label: {
                                Text(LocalizedStringKey(transactionCategory.name))
                            }
                        }
                        .onDelete { indexSet in
                            self.deleteTransactionCategory(offsets: indexSet, type: type)
                        }
                    } header: {
                        Text(type.description())
                    }
                }
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

    private func deleteTransactionCategory(offsets: IndexSet, type: TransactionType) {
        withAnimation {
            offsets.map { self.userViewModel.getTransactionCategoriesSorted(type: type)[$0] }.forEach { transactionCategory in
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
