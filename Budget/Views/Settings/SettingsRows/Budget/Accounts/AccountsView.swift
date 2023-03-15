//
//  AccountsView.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2023-03-14.
//

import SwiftUI

struct AccountsView: View {
    @Environment(\.presentationMode) private var presentationMode: Binding<PresentationMode>

    @EnvironmentObject private var errorHandling: ErrorHandling
    @EnvironmentObject private var userViewModel: UserViewModel

    var body: some View {
        Form {
            let accounts = self.userViewModel.getAccounts()
            if accounts.count < 1 {
                Text("noBudgetAccounts")
            } else {
                ForEach(AccountType.allCases, id: \.self) { type in
                    Section {
                        ForEach(self.userViewModel.getAccounts(type: type)) { account in
                            NavigationLink {
                                AccountView(account: account)
                            } label: {
                                Text(account.name)
                            }
                        }
                        .onDelete(perform: self.deleteBudgetAccounts)
                    } header: {
                        Text(type.description())
                    }
                }
            }
        }
        .navigationTitle("budgetAccounts")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                EditButton()
            }
            ToolbarItem {
                NavigationLink {
                    AccountView(add: true)
                } label: {
                    Label("Add Item", systemImage: "plus")
                }
            }
        }
    }

    private func deleteBudgetAccounts(offsets: IndexSet) {
        withAnimation {
            offsets.map { self.userViewModel.getAccounts()[$0] }.forEach { account in
                self.userViewModel.deleteBudgetAccount(account: account) { error in
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

struct AccountsView_Previews: PreviewProvider {
    static var previews: some View {
        AccountsView()
    }
}
