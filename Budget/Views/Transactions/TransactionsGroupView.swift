//
//  TransactionsGroupView.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2022-05-05.
//

import SwiftUI
import FirebaseAuth

struct TransactionsGroupView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var errorHandling: ErrorHandling
    @EnvironmentObject private var transactionsViewModel: TransactionsViewModel
    @EnvironmentObject private var userViewModel: UserViewModel
    
    @State private var showChildren: Bool = false
    
    private var from: Date
    private var to: Date
    
    init(level: Int, monthStartsOn: Int, showChildren: Bool) {
        let (from, to) = Utility.getBudgetPeriod(monthsBack: level, monthStartsOn: monthStartsOn)
        self.from = from
        self.to = to
        self._showChildren = State(initialValue: showChildren)
    }
    
    var body: some View {
        Section {
            if showChildren {
                ForEach(transactionsViewModel.transactions.filter({ $0.date >= from && $0.date <= to })) { transaction in
                    Section {
                        NavigationLink {
                            TransactionView(transaction: transaction, myId: self.userViewModel.user?.id ?? "")
                        } label: {
                            let amount = Utility.doubleToLocalCurrency(value: transaction.totalAmount)
                            Label(
                                "\(amount), \(transaction.desc) : \(transaction.category.name)\nCreator: \(transaction.creator)",
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
            offsets.map { self.transactionsViewModel.transactions[$0] }.forEach { transaction in
                transaction.delete { error in
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
