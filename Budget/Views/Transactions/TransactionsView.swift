//
//  TransactionsView.swift
//  Budget
//

import SwiftUI

struct TransactionsView: View {
    @Environment(\.colorScheme) var colorScheme

    @EnvironmentObject private var errorHandling: ErrorHandling
    @EnvironmentObject private var userViewModel: UserViewModel
    @EnvironmentObject private var transactionsViewModel: TransactionsViewModel
    @EnvironmentObject private var standingsViewModel: StandingsViewModel
    @EnvironmentObject private var tabRouter: TabRouter

    @State private var level: Int = 2
    @State private var openPeriods: Set<Int> = [0]
    @State private var transactionFromUrl: Transaction?
    @State private var urlSchemeNavigation = false

    private var monthStartsOn: Int { userViewModel.user.budget.monthStartsOn }

    private func period(_ level: Int) -> (Date, Date) {
        Utility.getBudgetPeriod(monthsBack: level, monthStartsOn: monthStartsOn)
    }
    private func rangeText(_ level: Int) -> String {
        let (from, to) = period(level)
        let f = DateFormatter()
        f.locale = Locale(identifier: Locale.preferredLanguages.first ?? "sv")
        f.dateFormat = "d MMM yyyy"
        // "to" is exclusive; show the last included day
        let lastDay = Calendar.current.date(byAdding: .day, value: -1, to: to) ?? to
        return "\(f.string(from: from)) – \(f.string(from: lastDay))"
    }
    private func transactions(_ level: Int) -> [Transaction] {
        let (from, to) = period(level)
        return transactionsViewModel.getTransactions(from: from, to: to)
    }

    private func dayHeader(_ date: Date) -> String {
        switch dayRelativity(date, now: Date()) {
        case .today: return "today".localizeString()
        case .yesterday: return "yesterday".localizeString()
        case .other:
            let f = DateFormatter()
            f.locale = Locale(identifier: Locale.preferredLanguages.first ?? "sv")
            f.dateFormat = "EEEE d MMM"
            return f.string(from: date).capitalized
        }
    }

    var body: some View {
        NavigationStack {
            List {
                headerBlock
                    .listRowInsets(EdgeInsets(top: 8, leading: 20, bottom: 8, trailing: 20))
                    .listRowSeparator(.hidden).listRowBackground(Color.clear)

                // Current period, expanded with day groups
                if openPeriods.contains(0) {
                    let groups = groupTransactionsByDay(transactions(0))
                    if groups.isEmpty {
                        Text("noTransactionsThisPeriod".localizeString())
                            .font(.footnote).foregroundColor(.appMuted)
                            .listRowInsets(EdgeInsets(top: 4, leading: 24, bottom: 4, trailing: 20))
                            .listRowSeparator(.hidden).listRowBackground(Color.clear)
                    }
                    ForEach(groups, id: \.day) { group in
                        Text(dayHeader(group.day).uppercased())
                            .font(.system(size: 12, weight: .bold)).kerning(0.8)
                            .foregroundColor(.appMuted)
                            .listRowInsets(EdgeInsets(top: 20, leading: 24, bottom: 8, trailing: 20))
                            .listRowSeparator(.hidden).listRowBackground(Color.clear)
                        ForEach(group.items, id: \.id) { transaction in
                            transactionLink(transaction)
                                .listRowInsets(EdgeInsets(top: 5, leading: 20, bottom: 5, trailing: 20))
                                .listRowSeparator(.hidden).listRowBackground(Color.clear)
                        }
                        .onDelete { offsets in deleteTransactions(offsets, in: group.items) }
                    }
                }

                // Earlier periods (collapsed selectors)
                ForEach(1 ..< level, id: \.self) { lvl in
                    PeriodSelector(range: rangeText(lvl),
                                   count: openPeriods.contains(lvl) ? "\(transactions(lvl).count) st" : nil,
                                   isOpen: openPeriods.contains(lvl)) {
                        toggle(lvl)
                    }
                    .listRowInsets(EdgeInsets(top: 5, leading: 20, bottom: 5, trailing: 20))
                    .listRowSeparator(.hidden).listRowBackground(Color.clear)

                    if openPeriods.contains(lvl) {
                        ForEach(transactions(lvl), id: \.id) { transaction in
                            transactionLink(transaction)
                                .listRowInsets(EdgeInsets(top: 5, leading: 20, bottom: 5, trailing: 20))
                                .listRowSeparator(.hidden).listRowBackground(Color.clear)
                        }
                    }
                }

                loadMoreButton
                    .listRowInsets(EdgeInsets(top: 10, leading: 20, bottom: 40, trailing: 20))
                    .listRowSeparator(.hidden).listRowBackground(Color.clear)
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Color.appBackground.ignoresSafeArea())
            .navigationBarHidden(true)
            .onLoad {
                if let url = tabRouter.appStartFromUrl {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        handleUrlOpen(url: url); tabRouter.appStartFromUrl = nil
                    }
                }
            }
            .onOpenURL { url in
                if url.absoluteString.contains("transactionFromUrl") { handleUrlOpen(url: url) }
            }
            .navigationDestination(isPresented: $urlSchemeNavigation) {
                if let transaction = transactionFromUrl {
                    TransactionView(transaction: transaction, user: userViewModel.user, action: .add, fromUrl: true)
                }
            }
        }
    }

    private var headerBlock: some View {
        VStack(spacing: 12) {
            ScreenHeader(eyebrow: "expensesAndSharing".localizeString(),
                         title: "transactions".localizeString()) {
                HStack(spacing: 8) {
                    EditButton()
                        .font(.system(size: 14, weight: .semibold))
                        .tint(.appInk)
                        .padding(.horizontal, 16).frame(height: 42)
                        .background(Color.appCard)
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.appLine))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .disabled(userViewModel.user.id.isEmpty)
                    NavigationLink {
                        TransactionView(action: .add,
                                        firstCategory: userViewModel.getFirstTransactionCategory(type: .expense))
                    } label: {
                        Image(systemName: "plus").font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white).frame(width: 42, height: 42)
                            .background(Color.appPine).clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(userViewModel.user.id.isEmpty)
                }
            }
            PeriodSelector(range: rangeText(0), count: "\(transactions(0).count) st",
                           isOpen: openPeriods.contains(0)) { toggle(0) }
            PeriodSummary(shareLabel: "yourShare".localizeString(),
                          shareValue: sumMyShare(transactions(0), userId: userViewModel.user.id),
                          oweLabel: "youOwe".localizeString(),
                          oweValue: standingsViewModel.getTotalIOwe(myId: userViewModel.user.id))
        }
    }

    private func transactionLink(_ transaction: Transaction) -> some View {
        // NavigationLink lives in the background so the List row is not itself a
        // NavigationLink and therefore shows no trailing disclosure chevron.
        TransactionCard(transaction: transaction, userId: userViewModel.user.id)
            .background(
                NavigationLink {
                    TransactionView(transaction: transaction, user: userViewModel.user,
                                    action: Utility.getTransactionAction(transaction: transaction,
                                        userId: userViewModel.user.id, role: userViewModel.user.role))
                } label: { EmptyView() }
                .opacity(0)
            )
    }

    private var loadMoreButton: some View {
        Button {
            level += 5
            transactionsViewModel.fetchData(monthStartsOn: monthStartsOn, monthsBack: level + 4) { error in
                if let error = error { errorHandling.handle(error: error); level -= 5 }
            }
        } label: {
            Text("loadMore".localizeString())
                .font(.system(size: 14, weight: .semibold)).foregroundColor(.appPine)
                .frame(maxWidth: .infinity).padding(13)
                .overlay(RoundedRectangle(cornerRadius: 14)
                    .stroke(style: StrokeStyle(lineWidth: 1, dash: [5])).foregroundColor(.appLine))
        }.buttonStyle(.plain)
    }

    private func toggle(_ lvl: Int) {
        withAnimation { if openPeriods.contains(lvl) { openPeriods.remove(lvl) } else { openPeriods.insert(lvl) } }
    }

    private func deleteTransactions(_ offsets: IndexSet, in items: [Transaction]) {
        withAnimation {
            offsets.map { items[$0] }.forEach { transaction in
                if transaction.creatorId != userViewModel.user.id {
                    errorHandling.handle(error: InputError.deleteTransactionCreatedBySomeoneElse); return
                }
                transaction.delete { error in
                    if let error = error { errorHandling.handle(error: error); return }
                    standingsViewModel.setStandings(transaction: transaction,
                        myUserName: userViewModel.user.name, myPhoneNumber: userViewModel.user.phone,
                        friends: userViewModel.friends, customFriends: userViewModel.user.customFriends,
                        delete: true) { error in
                        if let error = error { errorHandling.handle(error: error) }
                    }
                }
            }
        }
    }

    private func handleUrlOpen(url: URL) {
        let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: true)
        if let queryItems = urlComponents?.queryItems {
            var amount: Double? = nil
            var description = ""
            var categoryId = ""
            var participantsIds: [String] = []
            var payerId = ""
            for queryItem in queryItems {
                if let value = queryItem.value {
                    if queryItem.name == "sourceApplication" && value != "transactionFromUrl" { return }
                    else if queryItem.name == "description" && !value.isEmpty { description = value }
                    else if queryItem.name == "amount" && !value.isEmpty { amount = Double(value.replacingOccurrences(of: ",", with: ".")) }
                    else if queryItem.name == "categoryId" && !value.isEmpty { categoryId = value }
                    else if queryItem.name == "participants" && !value.isEmpty { participantsIds = value.split(separator: ",").map { String($0) } }
                    else if queryItem.name == "payerId" && !value.isEmpty { payerId = value }
                }
            }
            transactionFromUrl = Transaction.getDummyTransaction(category: userViewModel.getFirstTransactionCategory(type: .expense))
            transactionFromUrl?.totalAmount = amount ?? 0
            transactionFromUrl?.desc = description
            transactionFromUrl?.participants = [Participant(userId: userViewModel.user.id, userName: userViewModel.user.name)] + participantsIds.map { Participant(userId: $0, userName: userViewModel.getName(friendId: $0) ?? "ERROR GETTING NAME") }
            if categoryId != "" { transactionFromUrl?.category = userViewModel.getTransactionCategory(id: categoryId) }
            if payerId != "" { transactionFromUrl?.payerId = payerId }
            urlSchemeNavigation.toggle()
        }
    }
}

struct TransactionsView_Previews: PreviewProvider {
    static var previews: some View { TransactionsView() }
}
