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
    @EnvironmentObject private var transactionsViewModel: TransactionsViewModel
    @EnvironmentObject private var standingsViewModel: StandingsViewModel
    @EnvironmentObject private var notificationsViewModel: NotificationsViewModel
    
    @State private var transaction: Transaction
    @State private var totalAmountString: String = ""
    
    @State private var selection: Int?
    
    @State private var hasWritten: [String] = .init()

    @State private var applyLoading: Bool = false
    @FocusState var isInputActive: Bool
    
    private var oldTransaction: Transaction? = nil
    
    private var action: TransactionAction
    
    init(action: TransactionAction, firstCategory: TransactionCategory) {
        self.action = action
        self._transaction = State(initialValue: Transaction.getDummyTransaction(category: firstCategory))
    }
    
    init(transaction: Transaction, user: User, action: TransactionAction) {
        var newTransaction = transaction
        if !transaction.isMyCategory(user: user) {
            var changed = false
            for category in user.budget.transactionCategories {
                if !changed && category.name == transaction.category.name {
                    newTransaction.category = category
                    changed = true
                }
            }
            
            if !changed {
                newTransaction.category = user.budget.transactionCategories.first ?? TransactionCategory.getDummyCategory()
            }
        }
        
        self._transaction = State(initialValue: newTransaction)
        self._totalAmountString = State(initialValue: Utility.currencyFormatterNoSymbol.string(from: transaction.totalAmount as NSNumber) ?? "")
        self.action = action
        self.oldTransaction = transaction
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
            
            Section(self.participantText) {
                ParticipantsView(
                    totalAmount: self.$transaction.totalAmount,
                    splitOption: self.$transaction.splitOption,
                    participants: self.$transaction.participants,
                    payer: self.$transaction.payerId,
                    hasWritten: self.$hasWritten,
                    action: self.action)
            }
            
            Section {
                if self.action == .add {
                    Button {
                        if !self.applyLoading {
                            self.addTransaction()
                        }
                    } label: {
                        HStack {
                            Spacer()
                            if self.applyLoading {
                                ProgressView()
                            } else {
                                Text("add")
                            }
                            Spacer()
                        }
                    }
                } else if self.action == .edit {
                    Button {
                        if !self.applyLoading {
                            self.editTransaction()
                        }
                    } label: {
                        HStack {
                            Spacer()
                            if self.applyLoading {
                                ProgressView()
                            } else {
                                Text("apply")
                            }
                            Spacer()
                        }
                    }
                }
            } footer: {
                VStack {
                    if self.action != .add {
                        if self.transaction.creatorId == self.userViewModel.user.id {
                            Text("transactionCreatedByYou")
                        } else {
                            Text("transactionCreatedBy".localizeString() + " " + self.transaction.creatorName)
                        }
                    }
                }
            }
        }
        .navigationTitle(self.titleText)
        .navigationBarTitleDisplayMode(.inline)
        .onLoad {
            if self.userViewModel.user.id.count == 0 {
                self.presentationMode.wrappedValue.dismiss()
                return
            }
            let user = self.userViewModel.user
            if self.transaction.participants.count < 1 {
                self.transaction.participants = [Participant(userId: user.id, userName: user.name)]
            }
            if self.transaction.payerId == "" {
                self.transaction.payerId = self.transaction.participants[0].userId
            }
        }
        .onChange(of: self.transaction.totalAmount) { newValue in
            DispatchQueue.main.async {
                if let errorString = Utility.setAmountPerParticipant(splitOption: self.transaction.splitOption, participants: self.$transaction.participants, totalAmount: self.transaction.totalAmount, hasWritten: self.hasWritten, myUserId: self.userViewModel.user.id) {
                    self.errorHandling.handle(error: ApplicationError.unexpectedNil(errorString))
                }
            }
        }
        .onChange(of: self.transaction.type) { newValue in
            self.transaction.category = self.getFirstCategory(type: newValue)
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
        Group {
            if self.action == .view {
                HStack {
                    Text("type")
                    Spacer()
                    Text(self.transaction.type.description())
                }
            } else {
                Picker("type", selection: self.$transaction.type) {
                    ForEach(TransactionType.allCases, id: \.self) { type in
                        Text(type.description()).tag(type)
                    }
                }
                .pickerStyle(.segmented)
            }
        }
    }
    
    private func getFirstCategory(type: TransactionType) -> TransactionCategory {
        return self.userViewModel.getTransactionCategoriesSorted(type: type).first ?? TransactionCategory.getDummyCategory()
    }
    
    private var categoryView: some View {
        Group {
            if self.action == .view {
                HStack {
                    Text("category")
                    Spacer()
                    Text(self.transaction.category.name)
                }
            } else {
                HStack(spacing: 30) {
                    Picker("category", selection: self.$transaction.category) {
                        ForEach(self.userViewModel.getTransactionCategoriesSorted(type: self.transaction.type), id: \.self) { category in
                            Text(LocalizedStringKey(category.name)).tag(category)
                        }
                    }
                    .pickerStyle(.menu)
                    .onLoad {
                        if self.action == .add {
                            self.transaction.category = self.userViewModel.getFirstTransactionCategory(type: self.transaction.type)
                        }
                    }
                }
            }
        }
    }
    
    private var descriptionView: some View {
        Group {
            if self.action == .view {
                HStack {
                    Text("description")
                    Spacer()
                    Text(self.transaction.desc)
                }
            } else {
                HStack(spacing: 30) {
                    Text("description")
                    TextField("shortDescription", text: self.$transaction.desc, onEditingChanged: { isEditing in
                        self.selection = isEditing ? 0 : nil
                    })
                    .multilineTextAlignment(.trailing)
                    .focused(self.$isInputActive)
                    .toolbar {
                        if self.selection == 0 {
                            ToolbarItemGroup(placement: .keyboard) {
                                Spacer()
                                    
                                Button("Done") {
                                    self.isInputActive = false
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    private var amountView: some View {
        Group {
            if self.action == .view {
                HStack {
                    Text("amount")
                    Spacer()
                    Text(Utility.doubleToLocalCurrency(value: self.transaction.totalAmount))
                }
            } else {
                HStack(spacing: 5) {
                    Text("amount")
                    TextField(Utility.currencyFormatterNoSymbol.string(from: 0.0) ?? "0", text: self.$totalAmountString, onEditingChanged: { isEditing in
                        self.selection = isEditing ? 1 : nil
                        if !isEditing {
                            let expression = self.totalAmountString
                                .replacingOccurrences(of: ",", with: ".")
                                .replacingOccurrences(of: "÷", with: "/")
                                .replacingOccurrences(of: "×", with: "*")
                            if let doubleAmount = try? expression.evaluate() {
                                DispatchQueue.main.async {
                                    self.transaction.totalAmount = Utility.doubleToTwoDecimals(value: doubleAmount)
                                    self.totalAmountString = Utility.currencyFormatterNoSymbolNoZeroSymbol.string(
                                        from: self.transaction.totalAmount as NSNumber) ?? "-999"
                                }
                            }
                        }
                    })
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .focused(self.$isInputActive)
                    .toolbar {
                        if self.selection == 1 {
                            ToolbarItemGroup(placement: .keyboard) {
                                CalculatorToolbarView(amountString: self.$totalAmountString)
                                    
                                Spacer()
                                    
                                Button("Done") {
                                    self.isInputActive = false
                                }
                            }
                        }
                    }
                    Text(Utility.currencyFormatter.currencySymbol)
                }
            }
        }
    }
    
    private var datePicker: some View {
        DatePicker("date", selection: self.$transaction.date)
            .disabled(self.action == .view)
            .onLoad {
                if self.action == .add {
                    self.transaction.date = Date()
                }
            }
    }
    
    private func addParticipantIds() {
        self.transaction.participantIds = .init()
        for participant in self.transaction.participants {
            self.transaction.participantIds.append(participant.userId)
        }
    }
    
    private func allAmountsToTwoDecimals() {
        self.transaction.totalAmount = Utility.doubleToTwoDecimals(value: self.transaction.totalAmount)
        for i in 0..<self.transaction.participants.count {
            self.transaction.participants[i].amount = Utility.doubleToTwoDecimals(value: self.transaction.participants[i].amount)
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
            self.allAmountsToTwoDecimals()
            
            let totalAmount = Utility.doubleToTwoDecimals(value: self.transaction.participants.reduce(0) { result, participant in
                result + participant.amount
            })
            guard self.transaction.totalAmount == totalAmount else {
                self.errorHandling.handle(error: InputError.totalAmountMisMatch)
                print(self.transaction.totalAmount)
                print(totalAmount)
                return
            }
            guard self.transaction.participants.allSatisfy({$0.amount >= 0}) else {
                self.errorHandling.handle(error: InputError.participantNegativeAmount)
                return
            }
            guard self.transaction.participants.allSatisfy({$0.amount <= self.transaction.totalAmount}) else {
                self.errorHandling.handle(error: InputError.participantAmountLargerThanTotal)
                return
            }
            
            let creatorId = user.isAnonymous ? "createdByGuest" : user.uid
            let creatorName = user.isAnonymous ? "createdByGuest" : self.userViewModel.user.name
            self.transaction.creatorId = creatorId
            self.transaction.creatorName = creatorName
            self.transaction.payerName = self.transaction.getPayerName()
            self.addParticipantIds()
            self.applyLoading = true
            self.standingsViewModel.setStandings(transaction: self.transaction, myUserName: self.userViewModel.user.name, myPhoneNumber: self.userViewModel.user.phone, friends: self.userViewModel.friends, customFriends: self.userViewModel.user.customFriends) { error in
                if let error = error {
                    self.errorHandling.handle(error: error)
                    self.applyLoading = false
                    return
                }
                
                // Success
                self.transactionsViewModel.addTransaction(transaction: self.transaction) { error in
                    if let error = error {
                        self.errorHandling.handle(error: error)
                        self.applyLoading = false
                        return
                    }
                    
                    // Succes
                    self.notificationsViewModel.sendTransactionNotifications(me: self.userViewModel.user, transaction: self.transaction, friends: self.userViewModel.friends) { error in
                        self.applyLoading = false
                        if let error = error {
                            self.errorHandling.handle(error: error)
                            return
                        }
                        
                        // Success
                        DispatchQueue.main.async {
                            self.presentationMode.wrappedValue.dismiss()
                        }
                    }
                }
            }
        }
    }
    
    private func editTransaction() {
        withAnimation {
            if self.action == .view {
                return
            }
            self.allAmountsToTwoDecimals()
            
            let totalAmount = Utility.doubleToTwoDecimals(value: self.transaction.participants.reduce(0) { result, participant in
                result + participant.amount
            })
            guard self.transaction.totalAmount == totalAmount else {
                self.errorHandling.handle(error: InputError.totalAmountMisMatch)
                return
            }
            guard self.transaction.participants.allSatisfy({$0.amount >= 0}) else {
                self.errorHandling.handle(error: InputError.participantNegativeAmount)
                return
            }
            guard self.transaction.participants.allSatisfy({$0.amount <= self.transaction.totalAmount}) else {
                self.errorHandling.handle(error: InputError.participantAmountLargerThanTotal)
                return
            }
            
            self.transaction.payerName = self.transaction.getPayerName()
            self.addParticipantIds()
            
            guard let oldTransaction = self.oldTransaction else {
                let info = "Found nil when extracting oldTransaction in editTransaction in TransactionView"
                self.errorHandling.handle(error: ApplicationError.unexpectedNil(info))
                return
            }
            
            self.applyLoading = true
            self.transactionsViewModel.editTransaction(transaction: self.transaction) { error in
                if let error = error {
                    self.errorHandling.handle(error: error)
                    self.applyLoading = false
                    return
                }
                    
                // Success
                self.standingsViewModel.setStandings(transaction: oldTransaction, myUserName: self.userViewModel.user.name, myPhoneNumber: self.userViewModel.user.phone, friends: self.userViewModel.friends, customFriends: self.userViewModel.user.customFriends, delete: true) { error in
                    if let error = error {
                        self.errorHandling.handle(error: error)
                        self.applyLoading = false
                        return
                    }
                        
                    // Succes
                    self.standingsViewModel.setStandings(transaction: self.transaction, myUserName: self.userViewModel.user.name, myPhoneNumber: self.userViewModel.user.phone, friends: self.userViewModel.friends, customFriends: self.userViewModel.user.customFriends) { error in
                        self.applyLoading = false
                        if let error = error {
                            self.errorHandling.handle(error: error)
                            self.applyLoading = false
                            return
                        }
                            
                        // Success
                        DispatchQueue.main.async {
                            self.presentationMode.wrappedValue.dismiss()
                        }
                        self.notificationsViewModel.sendTransactionNotifications(me: self.userViewModel.user, transaction: self.transaction, friends: self.userViewModel.friends, edit: true) { error in
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
}

// struct TransactionView_Previews: PreviewProvider {
//    static var previews: some View {
//        TransactionView()
//            .environmentObject(AuthViewModel())
//    }
// }
