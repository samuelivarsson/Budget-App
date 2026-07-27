//
//  TransactionsView.swift
//  Budget
//
//  v2 — iOS 26 styled. Solid cards, system colors, ScrollView + LazyVStack.
//

import SwiftUI

struct TransactionsView: View {
    @EnvironmentObject private var errorHandling: ErrorHandling
    @EnvironmentObject private var userViewModel: UserViewModel
    @EnvironmentObject private var transactionsViewModel: TransactionsViewModel
    @EnvironmentObject private var standingsViewModel: StandingsViewModel
    @EnvironmentObject private var tabRouter: TabRouter

    @State private var level: Int = 2
    @State private var openPeriods: Set<Int> = [0]
    @State private var filter: TxFilter = .all
    @State private var transactionFromUrl: Transaction?
    @State private var urlSchemeNavigation = false

    private var user: User { userViewModel.user }
    private var monthStartsOn: Int { user.budget.monthStartsOn }
    private var budget: Budget { user.budget }
    private var mainAccountId: String { budget.getMainAccountId(type: .transaction) }

    // MARK: Period helpers

    private func period(_ level: Int) -> (Date, Date) {
        Utility.getBudgetPeriod(monthsBack: level, monthStartsOn: monthStartsOn)
    }
    private func rangeText(_ level: Int) -> String {
        let (from, to) = period(level)
        let f = DateFormatter()
        f.locale = Locale(identifier: Locale.preferredLanguages.first ?? "sv")
        f.dateFormat = "d MMM yyyy"
        let lastDay = Calendar.current.date(byAdding: .day, value: -1, to: to) ?? to
        return "\(f.string(from: from)) – \(f.string(from: lastDay))"
    }
    private func transactions(_ level: Int) -> [Transaction] {
        let (from, to) = period(level)
        return transactionsViewModel.getTransactions(from: from, to: to)
    }
    private func filtered(_ level: Int) -> [Transaction] {
        transactions(level).filter { filter.matches($0.type) }
    }
    private func monthName(_ level: Int) -> String {
        // The month we're currently in for level 0, one month back per level.
        let date = Calendar.current.date(byAdding: .month, value: -level, to: Date()) ?? Date()
        let f = DateFormatter()
        f.locale = Locale(identifier: Locale.preferredLanguages.first ?? "sv")
        f.dateFormat = "LLLL"
        return f.string(from: date).capitalized
    }
    private func dayLabel(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: Locale.preferredLanguages.first ?? "sv")
        f.dateFormat = "EEEE d MMMM"
        return f.string(from: date)
    }

    // MARK: Summary math

    private var expenseCategories: [TransactionCategory] { userViewModel.getTransactionCategoriesSorted(type: .expense) }
    private var mainCats: [TransactionCategory] { expenseCategories.filter { $0.takesFromAccount == mainAccountId } }
    private var sepCats: [TransactionCategory] { expenseCategories.filter { $0.takesFromAccount != mainAccountId } }
    /// Sums my share of ONLY expense-type ("Utgifter") transactions, split into
    /// main-account vs separate-account categories (by the user's effective category).
    private func split(_ txs: [Transaction]) -> (main: Double, separate: Double) {
        var main = 0.0, separate = 0.0
        for tx in txs where tx.type == .expense {
            let cat = tx.categoryForUser(userId: user.id, budget: budget)
            let share = tx.getShare(userId: user.id)
            if mainCats.contains(where: { $0.id == cat.id }) { main += share }
            else if sepCats.contains(where: { $0.id == cat.id }) { separate += share }
        }
        return (main, separate)
    }
    private var currentSplit: (main: Double, separate: Double) { split(transactions(0)) }
    private var savingsPart: Double { currentSplit.separate }   // expenses drawing from separate accounts
    private var mainSpent: Double { currentSplit.main }          // main-account expenses only
    private var mainTak: Double { mainCats.reduce(0) { $0 + $1.getRealAmount(budget: budget) } }

    private var daysElapsed: Int {
        let (from, to) = period(0)
        let end = min(Date(), to)
        return max(1, Calendar.current.dateComponents([.day], from: from, to: end).day ?? 1)
    }
    /// Previous period's expenses up to the same number of days into the cycle.
    private var prevSplit: (main: Double, separate: Double) {
        let from1 = period(1).0
        let prevEnd = Calendar.current.date(byAdding: .day, value: daysElapsed, to: from1) ?? from1
        return split(transactionsViewModel.getTransactions(from: from1, to: prevEnd))
    }
    private func deltaPct(_ current: Double, _ previous: Double) -> Int? {
        guard previous > 0 else { return nil }
        return Int(((current - previous) / previous * 100).rounded())
    }
    private var avgPerDay: Double { mainSpent / Double(daysElapsed) }
    private var forecast: Double { avgPerDay * 30 }
    private var forecastState: BudgetBarState { BudgetBarState.classify(spent: forecast, ceiling: mainTak) }
    private var forecastRatio: Double { forecastState == .over ? 1 : (mainTak <= 0 ? 0 : min(forecast / mainTak, 1)) }

    private func money(_ v: Double) -> String { Utility.doubleToLocalCurrency(value: v) }
    private func moneyNoDec(_ v: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.locale = Locale.current
        f.maximumFractionDigits = 0
        f.minimumFractionDigits = 0
        return f.string(from: v.rounded() as NSNumber) ?? "\(Int(v.rounded()))"
    }
    private var mainAccountName: String { budget.getAccount(id: mainAccountId).name }

    private func savingsDeltaText(_ delta: Int?) -> Text {
        guard let delta = delta else { return Text("") }
        return Text("  \(delta <= 0 ? "−" : "+")\(abs(delta)) %").foregroundColor(delta <= 0 ? .green : .red).fontWeight(.bold)
    }

    // MARK: Body

    private func clearRow<V: View>(_ insets: EdgeInsets, @ViewBuilder _ content: () -> V) -> some View {
        content()
            .listRowInsets(insets).listRowSeparator(.hidden).listRowBackground(Color.clear)
    }

    var body: some View {
        NavigationStack {
            List {
                clearRow(EdgeInsets(top: 6, leading: 20, bottom: 0, trailing: 20)) { summaryRow }
                clearRow(EdgeInsets(top: 12, leading: 20, bottom: 0, trailing: 20)) { IOSFilterBar(selection: $filter) }

                let curr = filtered(0)
                clearRow(EdgeInsets(top: 4, leading: 20, bottom: 0, trailing: 20)) {
                    IOSPeriodHead(range: rangeText(0), count: curr.count, isOpen: openPeriods.contains(0)) { toggle(0) }
                }
                if openPeriods.contains(0) {
                    if curr.isEmpty {
                        clearRow(EdgeInsets(top: 4, leading: 26, bottom: 4, trailing: 20)) {
                            Text("noTransactionsThisPeriod").font(.footnote).foregroundColor(.secondary)
                        }
                    } else {
                        dayGroups(curr)
                    }
                }

                ForEach(1 ..< level, id: \.self) { lvl in
                    clearRow(EdgeInsets(top: 4, leading: 20, bottom: 0, trailing: 20)) {
                        IOSPeriodHead(range: rangeText(lvl), count: filtered(lvl).count, isOpen: openPeriods.contains(lvl)) { toggle(lvl) }
                    }
                    if openPeriods.contains(lvl) {
                        dayGroups(filtered(lvl))
                    }
                }

                clearRow(EdgeInsets(top: 16, leading: 20, bottom: 90, trailing: 20)) { loadMoreButton }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Color.iosBG.ignoresSafeArea())
            .overlay(alignment: .bottomTrailing) { addFab }
            .navigationTitle("transactions")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { EditButton().disabled(user.id.isEmpty) }
            }
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
                    TransactionView(transaction: transaction, user: user, action: .add, fromUrl: true)
                }
            }
        }
    }

    // MARK: Summary

    private var summaryRow: some View {
        HStack(alignment: .top, spacing: 10) {
            let prev = prevSplit
            VStack(alignment: .leading, spacing: 3) {
                Text(String(format: "spentInMonth".localizeString(), monthName(0)))
                    .font(.system(size: 11, weight: .semibold)).foregroundColor(.secondary)
                Text(money(mainSpent)).font(.system(size: 17.5, weight: .bold)).monospacedDigit()
                if let delta = deltaPct(mainSpent, prev.main) {
                    (Text(delta <= 0 ? "−\(abs(delta)) %" : "+\(delta) %").foregroundColor(delta <= 0 ? .green : .red).fontWeight(.bold)
                     + Text(" " + String(format: "vsLastMonthSameDay".localizeString(), monthName(1))).foregroundColor(.secondary))
                        .font(.system(size: 10.5, weight: .medium))
                }
                (Text("savings".localizeString() + " ").foregroundColor(.secondary)
                 + Text(money(savingsPart)).foregroundColor(.primary).fontWeight(.bold)
                 + savingsDeltaText(deltaPct(savingsPart, prev.separate)))
                    .font(.system(size: 10.5)).monospacedDigit()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(13).iosCard(22)

            VStack(alignment: .leading, spacing: 3) {
                Text(String(format: "avgPerDay".localizeString(), mainAccountName))
                    .font(.system(size: 11, weight: .semibold)).foregroundColor(.secondary).lineLimit(1)
                Text(money(avgPerDay)).font(.system(size: 17.5, weight: .bold)).monospacedDigit()
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.primary.opacity(0.12))
                    Rectangle().fill(forecastState.tint).scaleEffect(x: forecastRatio, y: 1, anchor: .leading)
                }
                .frame(height: 5).clipShape(Capsule()).padding(.vertical, 5)
                (Text("forecast".localizeString() + " ~").foregroundColor(.secondary)
                 + Text(moneyNoDec(forecast)).foregroundColor(.primary).fontWeight(.bold)
                 + Text(" / \(moneyNoDec(mainTak))").foregroundColor(.secondary))
                    .font(.system(size: 10.5)).monospacedDigit()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(13).iosCard(22)
        }
        .fixedSize(horizontal: false, vertical: true)
        .padding(.top, 14)
    }

    // MARK: Day groups

    @ViewBuilder
    private func dayGroups(_ txs: [Transaction]) -> some View {
        ForEach(groupTransactionsByDay(txs), id: \.day) { group in
            clearRow(EdgeInsets(top: 14, leading: 26, bottom: 8, trailing: 20)) {
                Text(dayLabel(group.day)).textCase(.uppercase)
                    .font(.system(size: 11, weight: .bold)).kerning(0.7).foregroundColor(.secondary)
            }
            ForEach(group.items, id: \.id) { transaction in
                txRow(transaction)
                    .listRowInsets(EdgeInsets(top: 4.5, leading: 20, bottom: 4.5, trailing: 20))
                    .listRowSeparator(.hidden).listRowBackground(Color.clear)
            }
            .onDelete { offsets in deleteTransactions(offsets, in: group.items) }
        }
    }

    // NavigationLink lives in the background so the List row shows no disclosure
    // chevron; swipe-to-delete still comes from `.onDelete` on the ForEach.
    private func txRow(_ transaction: Transaction) -> some View {
        IOSTxCard(transaction: transaction, userId: user.id)
            .background(
                NavigationLink {
                    TransactionView(transaction: transaction, user: user,
                                    action: Utility.getTransactionAction(transaction: transaction, userId: user.id, role: user.role))
                } label: { EmptyView() }
                .opacity(0)
            )
    }

    private var addFab: some View {
        NavigationLink {
            TransactionView(action: .add, firstCategory: userViewModel.getFirstTransactionCategory(type: .expense))
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 24, weight: .semibold)).foregroundColor(.white)
                .frame(width: 58, height: 58)
                .background(Color.accentColor, in: Circle())
                .shadow(color: Color.accentColor.opacity(0.45), radius: 10, y: 5)
        }
        .disabled(user.id.isEmpty)
        .padding(.trailing, 20).padding(.bottom, 20)
    }

    private var loadMoreButton: some View {
        Button {
            level += 5
            transactionsViewModel.fetchData(monthStartsOn: monthStartsOn, monthsBack: level + 4) { error in
                if let error = error { errorHandling.handle(error: error); level -= 5 }
            }
        } label: {
            Text("loadMore")
                .font(.system(size: 15, weight: .semibold)).foregroundColor(.accentColor)
                .frame(maxWidth: .infinity).frame(height: 44)
                .background(Color.iosCardFill, in: Capsule())
                .overlay(Capsule().strokeBorder(Color.primary.opacity(0.06), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    // MARK: Actions

    private func toggle(_ lvl: Int) {
        withAnimation { if openPeriods.contains(lvl) { openPeriods.remove(lvl) } else { openPeriods.insert(lvl) } }
    }

    private func deleteTransactions(_ offsets: IndexSet, in items: [Transaction]) {
        offsets.map { items[$0] }.forEach { deleteTransaction($0) }
    }

    private func deleteTransaction(_ transaction: Transaction) {
        if transaction.creatorId != user.id {
            errorHandling.handle(error: InputError.deleteTransactionCreatedBySomeoneElse); return
        }
        withAnimation {
            transaction.delete { error in
                if let error = error { errorHandling.handle(error: error); return }
                standingsViewModel.setStandings(transaction: transaction, myUserName: user.name, myPhoneNumber: user.phone,
                                                friends: userViewModel.friends, customFriends: user.customFriends, delete: true) { error in
                    if let error = error { errorHandling.handle(error: error) }
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
            transactionFromUrl?.participants = [Participant(userId: user.id, userName: user.name)] + participantsIds.map { Participant(userId: $0, userName: userViewModel.getName(friendId: $0) ?? "ERROR GETTING NAME") }
            if categoryId != "" { transactionFromUrl?.category = userViewModel.getTransactionCategory(id: categoryId) }
            if payerId != "" { transactionFromUrl?.payerId = payerId }
            urlSchemeNavigation.toggle()
        }
    }
}

struct TransactionsView_Previews: PreviewProvider {
    static var previews: some View { TransactionsView() }
}
