//
//  HistoryView.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2022-04-12.
//

import SwiftUI

struct HistoryView: View {
    @EnvironmentObject private var errorHandling: ErrorHandling
    @EnvironmentObject private var userViewModel: UserViewModel
    @EnvironmentObject private var transactionsViewModel: TransactionsViewModel
    @EnvironmentObject private var historyViewModel: HistoryViewModel

    @State private var showingInfo: Bool = false

    var body: some View {
        NavigationView {
            Form {
                ForEach(TransactionType.allCases, id: \.self) { type in
                    Section {
                        ForEach(self.userViewModel.getTransactionCategoriesSorted(type: type)) { category in
                            HStack {
                                Text(category.name)
                                Spacer()
                                Text(Utility.doubleToLocalCurrency(value: self.historyViewModel.getCategoryAverage(categoryId: category.id)))
                            }
                        }
                    } header: {
                        HStack {
                            Text("transactionCategories")
                            Text("-")
                            Text(type.description())
                        }
                    }
                }

                ForEach(AccountType.allCases, id: \.self) { type in
                    if type != .overhead {
                        Section {
                            ForEach(self.userViewModel.getAccountsSorted(type: type)) { account in
                                HStack {
                                    Text(account.name)
                                    Spacer()
                                    Text(Utility.doubleToLocalCurrency(value: self.historyViewModel.getPreviousAccountBalance(accountId: account.id)))
                                }
                            }
                        } header: {
                            HStack {
                                Text("accounts")
                                Text("-")
                                Text(type.description())
                            }
                        }
                    }
                }
            }
            .navigationTitle("history")
            .navigationBarItems(trailing:
                Button {
                    self.showingInfo = true
                } label: {
                    Image(systemName: "info.circle")
                }
                .alert("info", isPresented: self.$showingInfo) {
                    Button {
                        self.showingInfo = false
                    } label: {
                        Text("ok")
                    }
                } message: {
                    Text("averageSpent")
                }
            )
        }
    }
}

struct HistoryView_Previews: PreviewProvider {
    static var previews: some View {
        HistoryView()
    }
}
