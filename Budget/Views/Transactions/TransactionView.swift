//
//  TransactionView.swift
//  Budget
//
//  v2 — iOS 26 styled. Native navigation bar (so the interactive swipe-back
//  gesture works), solid cards, pinned CTA via safeAreaInset.
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
    @State private var hasWritten: [String] = .init()
    @State private var applyLoading: Bool = false
    @State private var showFriendPicker: Bool = false
    @State private var keyboardUp: Bool = false
    @FocusState private var focus: AddTxField?

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

    private var navTitle: LocalizedStringKey {
        action == .add ? "newTransaction" : (action == .edit ? "editTransaction" : "details")
    }
    private func getFirstCategory(type: TransactionType) -> TransactionCategory {
        userViewModel.getTransactionCategoriesSorted(type: type).first ?? TransactionCategory.getDummyCategory()
    }
    private func firstName(_ name: String) -> String { name.split(separator: " ").first.map(String.init) ?? name }
    private func money(_ v: Double) -> String { Utility.doubleToLocalCurrency(value: v) }

    // MARK: - Body

    // Ordered focusable fields, top to bottom, for prev/next navigation.
    private var focusOrder: [AddTxField] {
        guard action != .view else { return [] }
        var order: [AddTxField] = [.amount, .description]
        for p in transaction.participants {
            if transaction.splitOption == .ownItems {
                order.append(.own(p.userId))
            } else if transaction.splitOption != .meEverything && transaction.splitOption != .heSheEverything {
                order.append(.share(p.userId))
            }
        }
        return order
    }
    private func moveFocus(_ delta: Int) {
        guard let current = focus, let idx = focusOrder.firstIndex(of: current) else { return }
        let next = idx + delta
        guard focusOrder.indices.contains(next) else { return }
        focus = focusOrder[next]
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 0) {
                    if action != .view {
                        IOSTypeSegment(selection: $transaction.type).padding(.bottom, 16)
                    }
                    amountCard
                    sectionLabel("details"); detailsCard
                    sectionLabel("participants"); participantsCard
                    sectionLabel("splitting"); splittingCard
                    creatorFooter
                }
                .padding(.horizontal, 20).padding(.top, 8).padding(.bottom, 24)
            }
            .onChange(of: focus) { newValue in
                guard let field = newValue else { return }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    withAnimation(.easeInOut(duration: 0.2)) { proxy.scrollTo(field, anchor: .center) }
                }
            }
        }
        .background(Color.iosBG.ignoresSafeArea())
        .navigationTitle(navTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .safeAreaInset(edge: .bottom) {
            // Hidden while typing so it doesn't collide with the keyboard toolbar.
            if action != .view && !keyboardUp { ctaBar }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
            keyboardUp = true
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            keyboardUp = false
        }
        .sheet(isPresented: $showFriendPicker) {
            IOSFriendSheet(participants: $transaction.participants)
        }
        .onLoad {
            if userViewModel.user.id.count == 0 { presentationMode.wrappedValue.dismiss(); return }
            let user = userViewModel.user
            if transaction.participants.count < 1 {
                transaction.participants = [Participant(userId: user.id, userName: user.name)]
            }
            if transaction.payerId == "" { transaction.payerId = transaction.participants[0].userId }
            if fromUrl {
                DispatchQueue.main.async {
                    if let errorString = Utility.setAmountPerParticipant(splitOption: transaction.splitOption, participants: $transaction.participants, totalAmount: transaction.totalAmount, hasWritten: hasWritten, myUserId: userViewModel.user.id) {
                        errorHandling.handle(error: ApplicationError.unexpectedNil(errorString))
                    }
                }
            }
        }
        .onChange(of: transaction.totalAmount) { _ in
            DispatchQueue.main.async {
                if let errorString = Utility.setAmountPerParticipant(splitOption: transaction.splitOption, participants: $transaction.participants, totalAmount: transaction.totalAmount, hasWritten: hasWritten, myUserId: userViewModel.user.id) {
                    errorHandling.handle(error: ApplicationError.unexpectedNil(errorString))
                }
            }
        }
        .onChange(of: transaction.type) { newValue in
            transaction.category = getFirstCategory(type: newValue)
        }
    }

    private func sectionLabel(_ key: String) -> some View {
        HStack {
            Text(LocalizedStringKey(key)).font(.system(size: 11, weight: .bold)).kerning(0.7)
                .textCase(.uppercase).foregroundColor(.secondary)
            Spacer()
        }
        .padding(.top, 18).padding(.bottom, 8).padding(.horizontal, 6)
    }

    // MARK: - Amount

    private var amountCard: some View {
        VStack(spacing: 6) {
            Text("amount").font(.system(size: 12, weight: .semibold)).kerning(0.5).textCase(.uppercase)
                .foregroundColor(.secondary)
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                if action == .view {
                    Text(Utility.currencyFormatterNoSymbolNoZeroSymbol.string(from: transaction.totalAmount as NSNumber) ?? "0")
                        .font(.system(size: 44, weight: .bold)).monospacedDigit().foregroundColor(.primary)
                } else {
                    TextField(Utility.currencyFormatterNoSymbol.string(from: 0.0) ?? "0", text: $totalAmountString, onEditingChanged: { isEditing in
                        if !isEditing {
                            let expression = totalAmountString
                                .components(separatedBy: .whitespaces).joined()
                                .replacingOccurrences(of: ",", with: ".")
                                .replacingOccurrences(of: "÷", with: "/")
                                .replacingOccurrences(of: "×", with: "*")
                            if let doubleAmount = try? expression.evaluate() {
                                DispatchQueue.main.async {
                                    transaction.totalAmount = Utility.doubleToTwoDecimals(value: doubleAmount)
                                    totalAmountString = Utility.currencyFormatterNoSymbolNoZeroSymbol.string(from: transaction.totalAmount as NSNumber) ?? "-999"
                                }
                            }
                        }
                    })
                    .keyboardType(.decimalPad).multilineTextAlignment(.center)
                    .font(.system(size: 44, weight: .bold)).monospacedDigit()
                    .foregroundColor(.primary).tint(.accentColor)
                    .fixedSize()
                    .focused($focus, equals: .amount)
                    .toolbar {
                        if focus == .amount {
                            ToolbarItemGroup(placement: .keyboard) {
                                chevrons(.amount)
                                CalculatorToolbarView(amountString: $totalAmountString)
                                Spacer()
                                Button("done".localizeString()) { focus = nil }
                            }
                        }
                    }
                }
                Text(Utility.currencyFormatter.currencySymbol)
                    .font(.system(size: 24, weight: .semibold)).foregroundColor(.secondary)
            }
            HStack(spacing: 10) {
                HStack(spacing: 6) {
                    Image(systemName: "calendar").font(.system(size: 13)).foregroundColor(.secondary)
                    DatePicker("", selection: $transaction.date, displayedComponents: .date)
                        .labelsHidden().disabled(action == .view)
                }
                HStack(spacing: 6) {
                    Image(systemName: "clock").font(.system(size: 13)).foregroundColor(.secondary)
                    DatePicker("", selection: $transaction.date, displayedComponents: .hourAndMinute)
                        .labelsHidden().disabled(action == .view)
                }
            }
            .padding(.top, 8)
            .onLoad { if action == .add { transaction.date = Date() } }
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .iosCard(26)
        .id(AddTxField.amount)
    }

    @ViewBuilder
    private func chevrons(_ field: AddTxField) -> some View {
        let idx = focusOrder.firstIndex(of: field) ?? 0
        Button { moveFocus(-1) } label: { Image(systemName: "chevron.up") }.disabled(idx <= 0)
        Button { moveFocus(1) } label: { Image(systemName: "chevron.down") }.disabled(idx >= focusOrder.count - 1)
    }

    // MARK: - Details

    private var detailsCard: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                Text("category").font(.system(size: 15.5, weight: .semibold)).foregroundColor(.primary)
                    .padding(.top, 13)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(userViewModel.getTransactionCategoriesSorted(type: transaction.type), id: \.self) { category in
                            let active = transaction.category.id == category.id
                            Button { if action != .view { transaction.category = category } } label: {
                                HStack(spacing: 6) {
                                    Circle().fill(Color.forCategory(category.name)).frame(width: 7, height: 7)
                                    Text(LocalizedStringKey(category.name)).font(.system(size: 13, weight: .semibold))
                                }
                                .foregroundColor(active ? Color.iosBG : .secondary)
                                .padding(.horizontal, 13).padding(.vertical, 8)
                                .background(active ? Color.primary : Color.primary.opacity(0.08))
                                .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 12)
                }
                .onLoad { if action == .add && !fromUrl { transaction.category = userViewModel.getFirstTransactionCategory(type: transaction.type) } }
            }
            Divider().overlay(Color.iosBorder)
            HStack {
                Text("description").font(.system(size: 15.5, weight: .semibold)).foregroundColor(.primary)
                Spacer()
                if action == .view {
                    Text(transaction.desc).font(.system(size: 15.5)).foregroundColor(.secondary)
                } else {
                    TextField("shortDescription", text: $transaction.desc)
                        .multilineTextAlignment(.trailing).font(.system(size: 15.5)).foregroundColor(.primary)
                        .focused($focus, equals: .description)
                        .toolbar {
                            if focus == .description {
                                ToolbarItemGroup(placement: .keyboard) {
                                    chevrons(.description)
                                    Spacer()
                                    Button("done".localizeString()) { focus = nil }
                                }
                            }
                        }
                }
            }
            .padding(.vertical, 13)
            .contentShape(Rectangle())
            .onTapGesture { if action != .view { focus = .description } }
        }
        .padding(.horizontal, 16)
        .iosCard(26)
        .id(AddTxField.description)
    }

    // MARK: - Participants (favorites + all friends)

    private var participantsCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 5) {
                Image(systemName: "star.fill").font(.system(size: 10))
                Text("favourites").font(.system(size: 11, weight: .bold)).kerning(0.5).textCase(.uppercase)
            }
            .foregroundColor(.secondary).padding(.top, 13)

            let favs = userViewModel.getFavouritesSorted()
            if favs.isEmpty {
                Text("noFavourites").font(.system(size: 13)).foregroundColor(.secondary).padding(.vertical, 10)
            } else {
                FlowLayout(spacing: 8) {
                    ForEach(favs, id: \.id) { friend in
                        let on = transaction.participants.contains { $0.userId == friend.id }
                        Button {
                            if action == .view { return }
                            if on { transaction.participants.removeAll { $0.userId == friend.id }; if transaction.payerId == friend.id { transaction.payerId = userViewModel.user.id } }
                            else { transaction.participants.append(Participant(userId: friend.id, userName: friend.name)) }
                        } label: {
                            HStack(spacing: 7) {
                                IOSPersonAvatar(name: friend.name, id: friend.id, size: 26)
                                Text(firstName(friend.name)).font(.system(size: 13.5, weight: .semibold))
                                if on { Image(systemName: "checkmark").font(.system(size: 10, weight: .bold)) }
                            }
                            .foregroundColor(on ? .accentColor : .secondary)
                            .padding(.leading, 6).padding(.trailing, 12).padding(.vertical, 6)
                            .background(on ? Color.accentColor.opacity(0.14) : Color.primary.opacity(0.08))
                            .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 10)
            }

            if action != .view {
                Divider().overlay(Color.iosBorder)
                Button { showFriendPicker = true } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "person.2.fill").font(.system(size: 13)).foregroundColor(.secondary)
                            .frame(width: 30, height: 30).background(Color.primary.opacity(0.08)).clipShape(Circle())
                        Text("allFriends").font(.system(size: 15, weight: .semibold)).foregroundColor(.primary)
                        Spacer()
                        let count = transaction.participants.filter { $0.userId != userViewModel.user.id }.count
                        Text(String(format: "selectedCount".localizeString(), count)).font(.system(size: 13, weight: .semibold)).foregroundColor(.accentColor)
                        Image(systemName: "chevron.right").font(.system(size: 13, weight: .semibold)).foregroundColor(.secondary)
                    }
                    .padding(.vertical, 13)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .iosCard(26)
    }

    // MARK: - Splitting (payer + distribution + breakdown)

    private var splittingCard: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                Text("payer").font(.system(size: 15.5, weight: .semibold)).foregroundColor(.primary).padding(.top, 13)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
                        ForEach(transaction.participants, id: \.userId) { participant in
                            let sel = transaction.payerId == participant.userId
                            let isYou = participant.userId == userViewModel.user.id
                            VStack(spacing: 6) {
                                ZStack(alignment: .bottomTrailing) {
                                    IOSPersonAvatar(name: participant.userName, id: participant.userId, isYou: isYou, size: 48)
                                        .overlay(Circle().stroke(Color.accentColor, lineWidth: sel ? 2.5 : 0).padding(-4))
                                        .opacity(sel ? 1 : 0.55)
                                    if sel {
                                        Image(systemName: "checkmark").font(.system(size: 10, weight: .bold)).foregroundColor(.white)
                                            .frame(width: 19, height: 19).background(Color.accentColor).clipShape(Circle())
                                            .overlay(Circle().strokeBorder(Color.iosBG, lineWidth: 2))
                                            .offset(x: 3, y: 3)
                                    }
                                }
                                Text(isYou ? "you".localizeString() : firstName(participant.userName))
                                    .font(.system(size: 11.5, weight: .semibold)).foregroundColor(sel ? .primary : .secondary)
                                    .lineLimit(1)
                            }
                            .frame(minWidth: 52)
                            .contentShape(Rectangle())
                            .onTapGesture { if action != .view { transaction.payerId = participant.userId } }
                        }
                    }
                    .padding(.vertical, 12).padding(.horizontal, 6)
                }
            }

            Divider().overlay(Color.iosBorder)

            HStack(spacing: 8) {
                Text("distribution").font(.system(size: 15.5, weight: .semibold)).foregroundColor(.primary)
                Spacer(minLength: 8)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(SplitOption.allCases, id: \.self) { option in
                            if option != .heSheEverything || transaction.participants.count == 2 {
                                let active = transaction.splitOption == option
                                Button { if action != .view { transaction.splitOption = option } } label: {
                                    Text(option.description()).font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(active ? Color.iosBG : .secondary)
                                        .padding(.horizontal, 13).padding(.vertical, 7)
                                        .background(active ? Color.primary : Color.primary.opacity(0.08))
                                        .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
            .padding(.vertical, 11)

            if transaction.splitOption == .ownItems {
                let rest = transaction.totalAmount - transaction.participants.reduce(0) { $0 + ($1.ownAmount ?? 0) }
                Text(String(format: "ownItemsNote".localizeString(), money(rest)))
                    .font(.system(size: 12)).foregroundColor(.secondary).monospacedDigit()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, 8)
            }

            Divider().overlay(Color.iosBorder)

            VStack(spacing: 0) {
                ForEach(Array($transaction.participants.enumerated()), id: \.element.id) { index, $participant in
                    IOSShareRow(participant: $participant, splitOption: $transaction.splitOption,
                                participants: $transaction.participants, totalAmount: $transaction.totalAmount,
                                hasWritten: $hasWritten, action: action, showsTopDivider: index > 0,
                                focus: $focus, order: focusOrder, onMove: moveFocus)
                        .id(transaction.splitOption == .ownItems ? AddTxField.own(participant.userId) : AddTxField.share(participant.userId))
                }
            }
            .padding(.bottom, 4)
        }
        .padding(.horizontal, 16)
        .iosCard(26)
        .onChange(of: transaction.participants.count) { newValue in
            DispatchQueue.main.async {
                if newValue > 2 && transaction.splitOption == .heSheEverything { transaction.splitOption = .standard }
                if let errorString = Utility.setAmountPerParticipant(splitOption: transaction.splitOption, participants: $transaction.participants, totalAmount: transaction.totalAmount, hasWritten: hasWritten, myUserId: userViewModel.user.id) {
                    errorHandling.handle(error: ApplicationError.unexpectedNil(errorString))
                }
            }
        }
        .onChange(of: transaction.splitOption) { newValue in
            DispatchQueue.main.async {
                if newValue == .meEverything {
                    hasWritten = []
                    if let notMe = transaction.participants.first(where: { $0.userId != userViewModel.user.id }) { transaction.payerId = notMe.userId }
                }
                if let errorString = Utility.setAmountPerParticipant(splitOption: transaction.splitOption, participants: $transaction.participants, totalAmount: transaction.totalAmount, hasWritten: hasWritten, myUserId: userViewModel.user.id) {
                    errorHandling.handle(error: ApplicationError.unexpectedNil(errorString))
                }
            }
        }
    }

    // MARK: - CTA & footer

    private var ctaText: String {
        if action != .add { return "apply".localizeString() }
        let typeKey = transaction.type == .expense ? "expense" : (transaction.type == .income ? "income" : "saving")
        return "\("add".localizeString()) \(typeKey.localizeString().lowercased()) · \(money(transaction.totalAmount))"
    }

    private var ctaBar: some View {
        Button {
            if !applyLoading { if action == .add { addTransaction() } else { editTransaction() } }
        } label: {
            HStack(spacing: 8) {
                if applyLoading {
                    ProgressView().tint(.white)
                } else {
                    if action == .add { Image(systemName: "plus").font(.system(size: 18, weight: .bold)) }
                    Text(ctaText).font(.system(size: 16.5, weight: .bold)).monospacedDigit()
                }
            }
            .frame(maxWidth: .infinity).frame(height: 54)
            .foregroundColor(.white)
            .background(Color.accentColor)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 16).padding(.top, 8).padding(.bottom, 4)
    }

    @ViewBuilder
    private var creatorFooter: some View {
        if action != .add {
            VStack {
                if transaction.creatorId == userViewModel.user.id {
                    Text("transactionCreatedByYou")
                } else {
                    Text("transactionCreatedBy".localizeString() + " " + transaction.creatorName)
                }
            }
            .font(.footnote).foregroundColor(.secondary).frame(maxWidth: .infinity).padding(.top, 16)
        }
    }

    // MARK: - Logic (unchanged)

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
