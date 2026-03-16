//
//  TransactionsView.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2022-04-12.
//

import SwiftUI

struct TransactionsView: View {
    @Environment(\.colorScheme) var colorScheme
    
    @EnvironmentObject private var errorHandling: ErrorHandling
    @EnvironmentObject private var userViewModel: UserViewModel
    @EnvironmentObject private var transactionsViewModel: TransactionsViewModel
    @EnvironmentObject private var tabRouter: TabRouter

    @State private var level: Int = 2
    
    @State private var transactionFromUrl: Transaction?
    
    @State private var urlSchemeNavigation = false
    

    var body: some View {
        NavigationStack {
            Form {
                TransactionsGroupView(level: 0, monthStartsOn: self.userViewModel.user.budget.monthStartsOn, showChildren: true)
                
                ForEach(1 ..< self.level, id: \.self) {
                    TransactionsGroupView(level: $0, monthStartsOn: self.userViewModel.user.budget.monthStartsOn, showChildren: false)
                }
                
                Section {
                    Button {
                        self.level += 5
                        self.transactionsViewModel.fetchData(monthStartsOn: self.userViewModel.user.budget.monthStartsOn, monthsBack: self.level + 4) { error in
                            if let error = error {
                                self.errorHandling.handle(error: error)
                                self.level -= 5
                                return
                            }
                            
                            // Success
                        }
                    } label: {
                        HStack {
                            Spacer()
                            Text("loadMore")
                            Spacer()
                        }
                    }
                    .listRowBackground(colorScheme == .dark ? Color.background : Color.secondaryBackground)
                }
            }
            .navigationTitle("transactions")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                        .disabled(self.userViewModel.user.id.count == 0)
                }
                ToolbarItem {
                    NavigationLink {
                        TransactionView(action: .add, firstCategory: self.userViewModel.getFirstTransactionCategory(type: .expense))
                    } label: {
                        Label("Add Item", systemImage: "plus")
                    }
                    .disabled(self.userViewModel.user.id.count == 0)
                }
            }
            .onLoad {
                if let url = self.tabRouter.appStartFromUrl {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.handleUrlOpen(url: url)
                        self.tabRouter.appStartFromUrl = nil
                    }
                }
            }
            .onOpenURL { url in
                if (url.absoluteString.contains("transactionFromUrl")) {
                    handleUrlOpen(url: url)
                }
            }
            .navigationDestination(isPresented: self.$urlSchemeNavigation) {
                if let transaction = self.transactionFromUrl {
                    TransactionView(transaction: transaction, user: self.userViewModel.user, action: .add, fromUrl: true)
                }
            }
        }
    }
    
    private func handleUrlOpen(url: URL) {
        let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: true)
        if let queryItems = urlComponents?.queryItems {
            var amount: Double? = nil
            var description = ""
            var categoryId = ""
            var participantsIds: [String] = []
            var payerId = ""
            for queryItem in queryItems {
                if let value = queryItem.value {
                    if queryItem.name == "sourceApplication" && value != "transactionFromUrl" {
                        return
                    } else if queryItem.name == "description" && !value.isEmpty {
                        description = value
                    } else if queryItem.name == "amount" && !value.isEmpty {
                        amount = Double(value.replacingOccurrences(of: ",", with: "."))
                    } else if queryItem.name == "categoryId" && !value.isEmpty {
                        categoryId = value
                    } else if queryItem.name == "participants" && !value.isEmpty {
                        participantsIds = value.split(separator: ",").map { String($0) }
                    } else if queryItem.name == "payerId" && !value.isEmpty {
                        payerId = value
                    }
                }
            }
            
            self.transactionFromUrl = Transaction.getDummyTransaction(category: self.userViewModel.getFirstTransactionCategory(type: .expense))
            self.transactionFromUrl?.totalAmount = amount ?? 0
            self.transactionFromUrl?.desc = description
            self.transactionFromUrl?.participants = [Participant(userId: self.userViewModel.user.id, userName: self.userViewModel.user.name)] + participantsIds.map { Participant(userId: $0, userName: self.userViewModel.getName(friendId: $0) ?? "ERROR GETTING NAME") }
            if categoryId != "" {
                self.transactionFromUrl?.category = self.userViewModel.getTransactionCategory(id: categoryId)
            }
            if payerId != "" {
                self.transactionFromUrl?.payerId = payerId
            }
            self.urlSchemeNavigation.toggle()
        }
    }

}

struct TransactionsView_Previews: PreviewProvider {
    static var previews: some View {
        TransactionsView()
    }
}
