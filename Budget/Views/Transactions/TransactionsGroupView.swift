//
//  TransactionsGroupView.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2022-05-05.
//

import FirebaseAuth
import SwiftUI

struct TransactionsGroupView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var errorHandling: ErrorHandling
    @EnvironmentObject private var transactionsViewModel: TransactionsViewModel
    @EnvironmentObject private var userViewModel: UserViewModel
    @EnvironmentObject private var standingsViewModel: StandingsViewModel
    
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
            if self.showChildren {
                let transactions = self.transactionsViewModel.getTransactions(from: self.from, to: self.to)
                if self.userViewModel.user.id.count == 0 {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                }
                else if transactions.count < 1 {
                    Text("noTransactionsThisPeriod")
                        .font(.footnote)
                } else {
                    ForEach(transactions, id:\.id) { transaction in
                        NavigationLink {
                            TransactionView(transaction: transaction, myId: self.userViewModel.user.id)
                        } label: {
                            VStack(alignment: .leading) {
                                HStack {
                                    Image(systemName: transaction.getImageName())
                                        .foregroundColor(transaction.getImageColor())
                                    
                                    VStack(alignment: .leading, spacing: 5) {
                                        Text(transaction.desc)
                                            .bold()
                                        let dateText = Utility.dateToStringNoTime(date: transaction.date)
                                        Text(dateText)
                                            .font(.footnote)
                                        Text(transaction.category.name)
                                            .font(.caption)
                                    }
                                    
                                    Spacer()
                                    
                                    VStack(alignment: .trailing, spacing: 5) {
                                        Text(Utility.doubleToLocalCurrency(value: transaction.getShare(userId: self.userViewModel.user.id)))
                                            .bold()
                                        Text(Utility.doubleToLocalCurrency(value: transaction.totalAmount))
                                            .font(.footnote)
                                        Spacer()
                                    }
                                }
                                
                                Spacer()
                                
                                HStack {
                                    let firstText = "you".localizeString()
                                    let secondText = " " + "and".localizeString().lowercased() + " \(transaction.participants.count - 1) "
                                    let friendText = (transaction.participants.count > 2 ? "friends".localizeString() : "friend".localizeString()).lowercased()
                                    if transaction.participants.count > 1 {
                                        Text(firstText + secondText + friendText)
                                            .font(.footnote)
                                            .bold()
                                    } else {
                                        Text(firstText)
                                            .font(.footnote)
                                            .bold()
                                    }
                                    
                                    Spacer()
                                    
                                    if transaction.payerId == self.userViewModel.user.id {
                                        Text("youPaid")
                                            .font(.footnote)
                                            .bold()
                                    } else {
                                        Text(transaction.payerName.split(separator: " ")[0] + " " + "paid".localizeString().lowercased())
                                            .font(.footnote)
                                            .bold()
                                    }
                                }
                            }
                            .padding(.trailing, 5)
                        }
                        .frame(height: 80)
                        .transition(.asymmetric(insertion: .fadeAndSlide, removal: .fadeAndSlide))
                    }
                    .onDelete(perform: deleteTransactions)
                }
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
            offsets.map { self.transactionsViewModel.getTransactions(from: self.from, to: self.to)[$0] }.forEach { transaction in
                if transaction.creatorId != self.userViewModel.user.id {
                    // TODO: - Send notification asking for the transaction to be deleted
                    self.errorHandling.handle(error: InputError.deleteTransactionCreatedBySomeoneElse)
                    return
                }
                transaction.delete { error in
                    if let error = error {
                        self.errorHandling.handle(error: error)
                        return
                    }
                    
                    // Success
                    self.standingsViewModel.setStandings(transaction: transaction, delete: true) { error in
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
}
