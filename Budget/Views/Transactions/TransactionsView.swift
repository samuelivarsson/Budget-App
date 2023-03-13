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
    
    @State private var groupDates: [(Date, Date)] = []
    @State private var level: Int = 1
    
    var body: some View {
        NavigationView {
            Form {
                TransactionsGroupView(level: 0, monthStartsOn: self.userViewModel.user.monthStartsOn, showChildren: true)
                
                ForEach(1 ..< level, id: \.self) {
                    TransactionsGroupView(level: $0, monthStartsOn: self.userViewModel.user.monthStartsOn, showChildren: false)
                }
                Button {
                    self.transactionsViewModel.fetchAllData { error in
                        if let error = error {
                            self.errorHandling.handle(error: error)
                            return
                        }
                        
                        // Success
                        level += 5
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
            .navigationTitle("transactions")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem {
                    NavigationLink {
                        TransactionView(action: .add)
                    } label: {
                        Label("Add Item", systemImage: "plus")
                    }
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
