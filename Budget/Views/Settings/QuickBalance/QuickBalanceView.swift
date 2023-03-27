//
//  QuickBalanceView.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2022-04-13.
//

import SwiftUI

struct QuickBalanceView: View {
    @EnvironmentObject private var errorHandling: ErrorHandling
    @EnvironmentObject private var userViewModel: UserViewModel

    var body: some View {
        Form {
            Section {
                ForEach(self.userViewModel.getQuickBalanceAccounts(), id: \.subscriptionId) { account in
                    NavigationLink {
                        QuickBalanceAccountView(quickBalanceAccount: account)
                    } label: {
                        Text(account.name)
                    }
                }
                .onDelete(perform: self.deleteAccount)
            } header: {
                Text("accounts")
            }
        }
        .navigationTitle("quickBalance")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                EditButton()
            }
            ToolbarItem {
                NavigationLink {
                    QuickBalanceAccountView(add: true)
                } label: {
                    Label("Add Item", systemImage: "plus")
                }
            }
        }
    }

    private func deleteAccount(offsets: IndexSet) {
        withAnimation {
            offsets.map { self.userViewModel.getQuickBalanceAccounts()[$0] }.forEach { account in
                self.userViewModel.deleteQuickBalanceAccount(account: account) { error in
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

struct QuickBalanceView_Previews: PreviewProvider {
    static var previews: some View {
        QuickBalanceView()
    }
}
