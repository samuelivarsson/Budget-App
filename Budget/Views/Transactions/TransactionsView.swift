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
    
    @State private var level: Int = 2
    
    var body: some View {
        NavigationView {
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
        }
    }
}

struct TransactionsView_Previews: PreviewProvider {
    static var previews: some View {
        TransactionsView()
    }
}
