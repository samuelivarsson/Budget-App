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
    @State private var showFriendPicker: Bool = false
    @FocusState var isInputActive: Bool
    
    private var oldTransaction: Transaction? = nil
    
    private var action: TransactionAction
    private var fromUrl: Bool = false
    
    init(action: TransactionAction, firstCategory: TransactionCategory) {
        self.action = action
        self._transaction = State(initialValue: Transaction.getDummyTransaction(category: firstCategory))
    }
    
    init(transaction: Transaction, user: User, action: TransactionAction, fromUrl: Bool = false) {
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
        self.fromUrl = fromUrl
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                self.topBar

                if self.action != .view {
                    SegmentedTypePicker(selection: self.$transaction.type)
                        .padding(.top, 6).padding(.bottom, 18)
                } else {
                    Spacer().frame(height: 8)
                }

                self.amountHero
                self.detailsCard

                self.sectionLabel("participants")
                self.participantsCard

                self.sectionLabel("payer")
                self.payerCard

                self.sectionLabel("splitOption")
                self.splitCard

                if self.action != .view {
                    self.primaryButton
                }
                self.creatorFooter
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
        .background(Color.appBackground.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: self.$showFriendPicker) {
            FriendPickerSheet(participants: self.$transaction.participants)
        }
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
            if self.fromUrl {
                DispatchQueue.main.async {
                    if let errorString = Utility.setAmountPerParticipant(splitOption: self.transaction.splitOption, participants: self.$transaction.participants, totalAmount: self.transaction.totalAmount, hasWritten: self.hasWritten, myUserId: self.userViewModel.user.id) {
                        self.errorHandling.handle(error: ApplicationError.unexpectedNil(errorString))
                    }
                }
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

    private func getFirstCategory(type: TransactionType) -> TransactionCategory {
        return self.userViewModel.getTransactionCategoriesSorted(type: type).first ?? TransactionCategory.getDummyCategory()
    }

    private func firstName(_ name: String) -> String {
        name.split(separator: " ").first.map(String.init) ?? name
    }

    // MARK: - Top bar

    private var topBar: some View {
        ZStack {
            Text(self.titleText).font(.system(size: 17, weight: .bold)).foregroundColor(.appInk)
            HStack {
                Button { self.presentationMode.wrappedValue.dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold)).foregroundColor(.appInk)
                        .frame(width: 40, height: 40)
                        .background(Color.appCard)
                        .overlay(RoundedRectangle(cornerRadius: 13).stroke(Color.appLine))
                        .clipShape(RoundedRectangle(cornerRadius: 13))
                }
                Spacer()
            }
        }
        .padding(.top, 8).padding(.bottom, 14)
    }

    private func sectionLabel(_ key: String) -> some View {
        HStack {
            Text(LocalizedStringKey(key)).font(.system(size: 12, weight: .bold)).kerning(0.8)
                .foregroundColor(.appMuted)
            Spacer()
        }
        .padding(.top, 14).padding(.bottom, 8).padding(.horizontal, 4)
    }

    // MARK: - Amount hero

    private var amountHero: some View {
        VStack(spacing: 6) {
            Text("amount".localizeString().uppercased())
                .font(.system(size: 12, weight: .semibold)).kerning(1)
                .foregroundColor(.white.opacity(0.72))
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                if self.action == .view {
                    Text(Utility.currencyFormatterNoSymbolNoZeroSymbol.string(from: self.transaction.totalAmount as NSNumber) ?? "0")
                        .font(.mono(40)).foregroundColor(.white)
                } else {
                    TextField(Utility.currencyFormatterNoSymbol.string(from: 0.0) ?? "0", text: self.$totalAmountString, onEditingChanged: { isEditing in
                        self.selection = isEditing ? 1 : nil
                        if !isEditing {
                            let expression = self.totalAmountString
                                .components(separatedBy: .whitespaces).joined() // strip thousands separators (incl. non-breaking spaces)
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
                    .multilineTextAlignment(.center)
                    .font(.mono(40)).foregroundColor(.white).tint(.white)
                    .fixedSize()
                    .focused(self.$isInputActive)
                    .toolbar {
                        if self.selection == 1 {
                            ToolbarItemGroup(placement: .keyboard) {
                                CalculatorToolbarView(amountString: self.$totalAmountString)
                                Spacer()
                                Button("done".localizeString()) { self.isInputActive = false }
                            }
                        }
                    }
                }
                Text(Utility.currencyFormatter.currencySymbol)
                    .font(.system(size: 22, weight: .medium)).foregroundColor(.white.opacity(0.72))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(LinearGradient(colors: [.heroTop, .heroBottom], startPoint: .topLeading, endPoint: .bottomTrailing))
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .shadow(color: .black.opacity(0.12), radius: 16, y: 8)
        .padding(.bottom, 16)
    }

    // MARK: - Details card (category, description, date)

    private var detailsCard: some View {
        AppCard(padding: 0) {
            VStack(spacing: 0) {
                categoryRow
                Divider().overlay(Color.appLine)
                descriptionRow
                Divider().overlay(Color.appLine)
                dateRow
            }
        }
    }

    private var categoryRow: some View {
        HStack {
            Text("category").font(.system(size: 15)).foregroundColor(.appInk)
            Spacer()
            Menu {
                ForEach(self.userViewModel.getTransactionCategoriesSorted(type: self.transaction.type), id: \.self) { category in
                    Button { self.transaction.category = category } label: { Text(LocalizedStringKey(category.name)) }
                }
            } label: {
                HStack(spacing: 7) {
                    Circle().fill(Color.forCategory(self.transaction.category.name)).frame(width: 9, height: 9)
                    Text(LocalizedStringKey(self.transaction.category.name))
                    if self.action != .view {
                        Image(systemName: "chevron.up.chevron.down").font(.system(size: 12, weight: .semibold)).opacity(0.8)
                    }
                }
                .font(.system(size: 15, weight: .semibold)).foregroundColor(.appPineInk)
            }
            .disabled(self.action == .view)
        }
        .padding(.horizontal, 16).padding(.vertical, 15)
        .onLoad {
            if self.action == .add && !self.fromUrl {
                self.transaction.category = self.userViewModel.getFirstTransactionCategory(type: self.transaction.type)
            }
        }
    }

    private var descriptionRow: some View {
        HStack {
            Text("description").font(.system(size: 15)).foregroundColor(.appInk)
            Spacer()
            if self.action == .view {
                Text(self.transaction.desc).font(.system(size: 15)).foregroundColor(.appMuted)
            } else {
                TextField("shortDescription", text: self.$transaction.desc, onEditingChanged: { isEditing in
                    self.selection = isEditing ? 0 : nil
                })
                .multilineTextAlignment(.trailing)
                .font(.system(size: 15)).foregroundColor(.appInk)
                .focused(self.$isInputActive)
                .toolbar {
                    if self.selection == 0 {
                        ToolbarItemGroup(placement: .keyboard) {
                            Spacer()
                            Button("done".localizeString()) { self.isInputActive = false }
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 15)
    }

    private var dateRow: some View {
        HStack {
            Text("date").font(.system(size: 15)).foregroundColor(.appInk)
            Spacer()
            DatePicker("", selection: self.$transaction.date, displayedComponents: [.date, .hourAndMinute])
                .labelsHidden()
                .disabled(self.action == .view)
        }
        .padding(.horizontal, 16).padding(.vertical, 9)
        .onLoad {
            if self.action == .add { self.transaction.date = Date() }
        }
    }

    // MARK: - Participants

    private var participantsCard: some View {
        AppCard(padding: 0) {
            VStack(alignment: .leading, spacing: 0) {
                FlowLayout(spacing: 8) {
                    youChip
                    ForEach(self.transaction.participants.filter { $0.userId != self.userViewModel.user.id }, id: \.userId) { participant in
                        participantChip(participant)
                    }
                    if self.action != .view {
                        Button { self.showFriendPicker = true } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "plus").font(.system(size: 12, weight: .bold))
                                Text("add").font(.system(size: 13.5, weight: .semibold))
                            }
                            .foregroundColor(.appPineInk)
                            .padding(.horizontal, 12).padding(.vertical, 6)
                            .overlay(Capsule().stroke(style: StrokeStyle(lineWidth: 1, dash: [4])).foregroundColor(.appPine))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(14)

                let favs = self.userViewModel.getFavouritesSorted(exceptFor: self.transaction.participants)
                if self.action != .view && !favs.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("favourites").font(.system(size: 12)).foregroundColor(.appMuted)
                        FlowLayout(spacing: 8) {
                            ForEach(favs, id: \.id) { friend in
                                Button {
                                    self.transaction.participants.append(Participant(userId: friend.id, userName: friend.name))
                                } label: {
                                    HStack(spacing: 7) {
                                        Image(systemName: "plus").font(.system(size: 11, weight: .bold)).foregroundColor(.appPineInk)
                                        PersonAvatar(name: friend.name, id: friend.id, size: 24)
                                        Text(firstName(friend.name)).font(.system(size: 13, weight: .semibold)).foregroundColor(.appInk)
                                    }
                                    .padding(.leading, 5).padding(.trailing, 12).padding(.vertical, 5)
                                    .background(Color.appCard2)
                                    .overlay(Capsule().stroke(Color.appLine))
                                    .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.horizontal, 16).padding(.bottom, 14)
                }
            }
        }
    }

    private var youChip: some View {
        HStack(spacing: 7) {
            PersonAvatar(name: "you".localizeString(), id: self.userViewModel.user.id, isYou: true, size: 24)
            Text("you").font(.system(size: 13.5, weight: .semibold))
        }
        .foregroundColor(.appPineInk)
        .padding(.leading, 5).padding(.trailing, 12).padding(.vertical, 5)
        .background(Color.appPineSoft).clipShape(Capsule())
    }

    private func participantChip(_ participant: Participant) -> some View {
        HStack(spacing: 7) {
            PersonAvatar(name: participant.userName, id: participant.userId, size: 24)
            Text(firstName(participant.userName)).font(.system(size: 13.5, weight: .semibold)).foregroundColor(.appInk)
            if self.action != .view {
                Button {
                    self.transaction.participants.removeAll { $0.userId == participant.userId }
                    if self.transaction.payerId == participant.userId {
                        self.transaction.payerId = self.userViewModel.user.id
                    }
                } label: {
                    Image(systemName: "xmark").font(.system(size: 9, weight: .bold)).foregroundColor(.appMuted)
                        .frame(width: 18, height: 18).background(Color.appTrack).clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.leading, 5).padding(.trailing, self.action != .view ? 5 : 12).padding(.vertical, 5)
        .background(Color.appChipBg)
        .overlay(Capsule().stroke(Color.appLine))
        .clipShape(Capsule())
    }

    // MARK: - Payer

    private var payerCard: some View {
        AppCard(padding: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(self.transaction.participants, id: \.userId) { participant in
                        let selected = self.transaction.payerId == participant.userId
                        VStack(spacing: 6) {
                            PersonAvatar(name: participant.userName, id: participant.userId,
                                         isYou: participant.userId == self.userViewModel.user.id, size: 46)
                                .overlay(
                                    Circle().stroke(Color.appPine, lineWidth: selected ? 2.5 : 0)
                                        .padding(-4)
                                )
                            Text(participant.userId == self.userViewModel.user.id ? "you".localizeString() : firstName(participant.userName))
                                .font(.system(size: 11.5, weight: .semibold))
                                .foregroundColor(selected ? .appInk : .appMuted)
                                .lineLimit(1)
                        }
                        .frame(minWidth: 52)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if self.action != .view { self.transaction.payerId = participant.userId }
                        }
                    }
                }
                .padding(14)
            }
        }
    }

    // MARK: - Split

    private var splitCard: some View {
        AppCard(padding: 0) {
            VStack(spacing: 0) {
                HStack {
                    Text("distribution").font(.system(size: 15)).foregroundColor(.appInk)
                    Spacer()
                    Menu {
                        ForEach(SplitOption.allCases, id: \.self) { option in
                            if option != .heSheEverything || self.transaction.participants.count == 2 {
                                Button { self.transaction.splitOption = option } label: { Text(option.description()) }
                            }
                        }
                    } label: {
                        HStack(spacing: 7) {
                            Text(self.transaction.splitOption.description())
                            if self.action != .view {
                                Image(systemName: "chevron.up.chevron.down").font(.system(size: 12, weight: .semibold)).opacity(0.8)
                            }
                        }
                        .font(.system(size: 15, weight: .semibold)).foregroundColor(.appPineInk)
                    }
                    .disabled(self.action == .view)
                }
                .padding(.horizontal, 16).padding(.vertical, 15)

                Divider().overlay(Color.appLine)

                VStack(spacing: 0) {
                    ForEach(Array(self.$transaction.participants.enumerated()), id: \.element.id) { index, $participant in
                        if index > 0 { Divider().overlay(Color.appLine.opacity(0.6)) }
                        SplitAmountRow(participant: $participant,
                                       splitOption: self.$transaction.splitOption,
                                       participants: self.$transaction.participants,
                                       totalAmount: self.$transaction.totalAmount,
                                       hasWritten: self.$hasWritten,
                                       action: self.action)
                    }
                }
                .padding(.horizontal, 16).padding(.bottom, 4)
            }
        }
        .onChange(of: self.transaction.participants.count) { newValue in
            DispatchQueue.main.async {
                if newValue > 2 && self.transaction.splitOption == .heSheEverything {
                    self.transaction.splitOption = .standard
                }
                if let errorString = Utility.setAmountPerParticipant(splitOption: self.transaction.splitOption, participants: self.$transaction.participants, totalAmount: self.transaction.totalAmount, hasWritten: self.hasWritten, myUserId: self.userViewModel.user.id) {
                    self.errorHandling.handle(error: ApplicationError.unexpectedNil(errorString))
                }
            }
        }
        .onChange(of: self.transaction.splitOption) { newValue in
            DispatchQueue.main.async {
                if newValue == .meEverything {
                    self.hasWritten = []
                    if let notMe = self.transaction.participants.first(where: { $0.userId != self.userViewModel.user.id }) {
                        self.transaction.payerId = notMe.userId
                    }
                }
                if let errorString = Utility.setAmountPerParticipant(splitOption: self.transaction.splitOption, participants: self.$transaction.participants, totalAmount: self.transaction.totalAmount, hasWritten: self.hasWritten, myUserId: self.userViewModel.user.id) {
                    self.errorHandling.handle(error: ApplicationError.unexpectedNil(errorString))
                }
            }
        }
    }

    // MARK: - Primary button & footer

    private var primaryButton: some View {
        Button {
            if !self.applyLoading {
                if self.action == .add { self.addTransaction() } else { self.editTransaction() }
            }
        } label: {
            HStack {
                Spacer()
                if self.applyLoading {
                    ProgressView().tint(.white)
                } else {
                    Text(self.action == .add ? "addTransaction" : "apply")
                        .font(.system(size: 16, weight: .bold))
                }
                Spacer()
            }
            .padding(16)
            .foregroundColor(.white)
            .background(Color.appPine)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .padding(.top, 20)
    }

    @ViewBuilder
    private var creatorFooter: some View {
        if self.action != .add {
            VStack {
                if self.transaction.creatorId == self.userViewModel.user.id {
                    Text("transactionCreatedByYou")
                } else {
                    Text("transactionCreatedBy".localizeString() + " " + self.transaction.creatorName)
                }
            }
            .font(.footnote).foregroundColor(.appMuted)
            .frame(maxWidth: .infinity)
            .padding(.top, 14)
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
