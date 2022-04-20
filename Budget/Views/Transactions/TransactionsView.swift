//
//  TransactionsView.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2022-04-12.
//

import SwiftUI

struct TransactionsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var errorHandling: ErrorHandling

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Transaction.date, ascending: true)],
        animation: .default)
    private var transactions: FetchedResults<Transaction>
    
    var body: some View {
        NavigationView {
            Form {
                ForEach(transactions) { transaction in
                    Section {
                        NavigationLink {
                            TransactionView(transaction: transaction)
                        } label: {
                            let amount = Utility.doubleToLocalCurrency(value: transaction.amount)
                            Label(
                                "\(amount), \(transaction.desc!) : \(transaction.category!)",
                                systemImage: transaction.getImageName()
                            )
                        }
                        .frame(minHeight: 50)
                        .padding()
                    }
                }
                .onDelete(perform: deleteTransactions)
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
    
    private func deleteTransactions(offsets: IndexSet) {
        withAnimation {
            offsets.map { transactions[$0] }.forEach(viewContext.delete)

            do {
                try viewContext.save()
            } catch {
                errorHandling.handle(error: error)
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
