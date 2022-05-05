//
//  TransactionsGroupView.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2022-05-05.
//

import SwiftUI

struct TransactionsGroupView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var errorHandling: ErrorHandling
    
    @FetchRequest private var transactions: FetchedResults<Transaction>
    
    @State private var showChildren: Bool = false
    
    private var from: Date
    private var to: Date
    
    init(level: Int, monthStartsOn: Int, showChildren: Bool) {
        let (from, to) = Utility.getBudgetPeriod(monthsBack: level, monthStartsOn: monthStartsOn)
        self.from = from
        self.to = to
        self._showChildren = State(initialValue: showChildren)
        
        self._transactions = FetchRequest(
            sortDescriptors: [NSSortDescriptor(key: "date", ascending: false)],
            predicate: NSPredicate(
                format: "(date >= %@) AND (date <= %@)",
                from as CVarArg,
                to as CVarArg
            ),
            animation: .default
        )
    }
    
    var body: some View {
        Section {
            if showChildren {
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
                        .frame(height: 50)
                        .padding()
                    }
                    .transition(.asymmetric(insertion: .fadeAndSlide, removal: .fadeAndSlide))
                }
                .onDelete(perform: deleteTransactions)
            }
        } header: {
            HStack {
                Label {
                    HStack {
                        Text(from, style: .date)
                        Text("-")
                        Text(to, style: .date)
                    }
                } icon: {
                    Image(systemName: self.showChildren ? "chevron.down" : "chevron.right")
                        .frame(width: 15, height: 15)
                }
            }
            .transaction { transaction in
                transaction.animation = nil
            }
            .onTapGesture {
                withAnimation {
                    self.showChildren.toggle()
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
