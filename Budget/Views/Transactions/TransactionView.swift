//
//  TransactionView.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2022-04-14.
//

import Combine
import CoreData
import SwiftUI

struct TransactionView: View {
    @Environment(\.presentationMode) private var presentationMode: Binding<PresentationMode>
    
    @EnvironmentObject private var errorHandling: ErrorHandling
    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var userViewModel: UserViewModel
    @EnvironmentObject private var firestoreViewModel: FirestoreViewModel
    
    @State private var transaction: Transaction
    @FocusState var isInputActive: Bool
    
    private var action: TransactionAction
    
    init(action: TransactionAction, firstCategory: TransactionCategory) {
        self.action = action
        self._transaction = State(initialValue: Transaction.getDummyTransaction(category: firstCategory))
    }
    
    init(transaction: Transaction, myId: String) {
        self._transaction = State(initialValue: transaction)
        self.action = transaction.creatorId == myId ? .edit : .view
    }
    
    var body: some View {
        Form {
            Section {
                self.typeView
                self.categoryView
                self.descriptionView
                self.amountView
                self.datePicker
            }
            
            Section(participantText) {
                ParticipantsView(totalAmount: self.$transaction.totalAmount, splitEvenly: self.$transaction.splitEvenly, participants: self.$transaction.participants, payer: self.$transaction.payerId, isInputActive: self.$isInputActive)
            }
            
            Section {
                if self.action == .add {
                    Button("add") {
                        self.addTransaction()
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                } else if self.action == .edit {
                    Button("apply") {
                        self.editTransaction()
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            } footer: {
                if self.action != .add {
                    if self.transaction.creatorId == self.userViewModel.user.id {
                        Text("transactionCreatedByYou")
                    } else {
                        Text("transactionCreatedBy".localizeString() + " " + transaction.creatorName)
                    }
                }
            }
        }
        .navigationTitle(self.titleText)
        .navigationBarTitleDisplayMode(.inline)
        .onLoad {
            let user = self.userViewModel.user
            if self.transaction.participants.count < 1 {
                self.transaction.participants = [Participant(me: true, userId: user.id, userName: user.name)]
            }
            if self.transaction.payerId == "" {
                self.transaction.payerId = self.transaction.participants[0].id
            }
        }
    }
    
    private var titleText: LocalizedStringKey {
        if self.action == .add {
            return "addTransaction"
        } else if self.action == .edit {
            return "editTransaction"
        } else {
            return "details"
        }
    }
    
    private var participantText: LocalizedStringKey {
        if self.action == .add {
            return "addParticipants"
        } else if self.action == .edit {
            return "editParticipants"
        } else {
            return "details"
        }
    }
    
    private var typeView: some View {
        Picker("type", selection: self.$transaction.type) {
            ForEach(TransactionType.allCases, id: \.self) { type in
                Text(type.description()).tag(type)
            }
        }
        .pickerStyle(.segmented)
    }
    
    private var categoryView: some View {
        HStack(spacing: 30) {
            Picker("category", selection: self.$transaction.category) {
                ForEach(self.userViewModel.getTransactionCategoriesSorted(type: self.transaction.type), id: \.self) { category in
                    Text(LocalizedStringKey(category.name)).tag(category)
                }
            }
            .pickerStyle(.menu)
            .onLoad {
                self.transaction.category = self.userViewModel.getFirstTransactionCategory(type: self.transaction.type)
            }
        }
    }
    
    private var descriptionView: some View {
        HStack(spacing: 30) {
            Text("description")
            TextField("description", text: self.$transaction.desc, prompt: Text("shortDescription"))
                .multilineTextAlignment(.trailing)
                .focused(self.$isInputActive)
                .toolbar {
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()

                        Button("Done") {
                            self.isInputActive = false
                        }
                    }
                }
        }
    }
    
    private var amountView: some View {
        HStack(spacing: 5) {
            Text("amount")
            TextField(Utility.currencyFormatterNoSymbol.string(from: 0.0) ?? "0", value: self.$transaction.totalAmount, formatter: Utility.currencyFormatterNoSymbolNoZeroSymbol)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .focused(self.$isInputActive)
                .onChange(of: self.transaction.totalAmount) { newValue in
                    self.transaction.totalAmount = Utility.doubleToTwoDecimals(value: newValue)
                    // If splitEvenly is true, divide the total amount evenly among the participants
                    if self.transaction.splitEvenly {
                        let amountPerParticipant = Utility.doubleToTwoDecimalsFloored(value: newValue / Double(self.transaction.participants.count))
                        var val = newValue
                        for i in (0 ..< self.transaction.participants.count).reversed() {
                            self.transaction.participants[i].amount = Utility.doubleToTwoDecimals(value: i == 0 ? val : amountPerParticipant)
                            val -= amountPerParticipant
                        }
                    }
                }
            Text(Utility.currencyFormatter.currencySymbol)
        }
    }
    
    private var datePicker: some View {
        DatePicker("date", selection: self.$transaction.date)
            .onLoad {
                if self.action == .add {
                    self.transaction.date = Date()
                }
            }
    }
    
    private func addParticipantIds() {
        transaction.participantIds = .init()
        transaction.participants.forEach { participant in
            self.transaction.participantIds.append(participant.userId)
        }
    }
    
    private func addTransaction() {
        withAnimation {
            guard let user = authViewModel.auth.currentUser else {
                let info = "Found nil when extracting user in addTransaction in TransactionView"
                print(info)
                self.errorHandling.handle(error: ApplicationError.unexpectedNil(info))
                return
            }
            let totalAmount = Utility.doubleToTwoDecimals(value: self.transaction.participants.reduce(0) { result, participant in
                result + participant.amount
            })
            guard self.transaction.totalAmount == totalAmount else {
                self.errorHandling.handle(error: InputError.totalAmountMisMatch)
                print(self.transaction.totalAmount)
                print(totalAmount)
                return
            }
            
            let creatorId = user.isAnonymous ? "createdByGuest" : user.uid
            let creatorName = user.isAnonymous ? "createdByGuest" : self.userViewModel.user.name
            self.transaction.creatorId = creatorId
            self.transaction.creatorName = creatorName
            self.transaction.payerName = self.transaction.getPayerName()
            self.addParticipantIds()
            
            do {
                let _ = try self.firestoreViewModel.db.collection("Transactions").addDocument(from: self.transaction) { error in
                    if let error = error {
                        self.errorHandling.handle(error: error)
                        return
                    }
                        
                    // Success
                    self.presentationMode.wrappedValue.dismiss()
                }
            } catch {
                self.errorHandling.handle(error: error)
            }
        }
    }
    
    private func editTransaction() {
        withAnimation {
            let totalAmount = self.transaction.participants.reduce(0) { result, participant in
                result + participant.amount
            }
            guard self.transaction.totalAmount == totalAmount else {
                self.errorHandling.handle(error: InputError.totalAmountMisMatch)
                return
            }
            
            self.transaction.payerName = self.transaction.getPayerName()
            self.addParticipantIds()
            
            do {
                try self.firestoreViewModel.db.collection("Transactions").document(self.transaction.documentId ?? "").setData(from: self.transaction)
                self.presentationMode.wrappedValue.dismiss()
            } catch {
                self.errorHandling.handle(error: error)
            }
        }
    }
}

// struct TransactionView_Previews: PreviewProvider {
//    static var previews: some View {
//        TransactionView()
//            .environmentObject(AuthViewModel())
//    }
// }
