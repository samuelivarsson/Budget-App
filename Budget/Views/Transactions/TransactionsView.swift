//
//  TransactionsView.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2022-04-12.
//

import SwiftUI

struct TransactionsView: View {
    @Environment(\.colorScheme) var colorScheme
    
    @AppStorage("monthStartsOn") var monthStartsOn = 25
    @State private var groupDates: [(Date, Date)] = []
    @State private var level: Int = 1
    
    var body: some View {
        // TODO - Only show transactions from the logged in user
        NavigationView {
            Form {
                TransactionsGroupView(level: 0, monthStartsOn: monthStartsOn, showChildren: true)
                
                ForEach(1..<level, id: \.self) {
                    TransactionsGroupView(level: $0, monthStartsOn: monthStartsOn, showChildren: false)
                }
                Button {
                    level += 5
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
                        TransactionView(add: true)
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
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
