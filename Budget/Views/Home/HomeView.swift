//
//  HomeView.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2022-04-12.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var errorHandling: ErrorHandling
    @EnvironmentObject private var userViewModel: UserViewModel
    @EnvironmentObject private var notificationsViewModel: NotificationsViewModel
    @EnvironmentObject private var transactionsViewModel: TransactionsViewModel
    @EnvironmentObject private var standingsViewModel: StandingsViewModel

    @State private var showSendReminderAlert: Bool = false
    @State private var showDidSwishGoThrough: Bool = false
    @State private var swishFriendId: String? = nil

    private let textSize: Font = .footnote

    var body: some View {
        NavigationView {
            Form {
                let user = self.userViewModel.user
                Section {
                    HStack {
                        Text("income")
                        Spacer()
                        Text(Utility.doubleToLocalCurrency(value: user.budget.income))
                    }
                } header: {
                    Text("incomes")
                }

                Section {
                    ForEach(self.userViewModel.getAccountsSorted()) { account in
                        HStack {
                            Text(account.name)
                            Spacer()
                            Text(Utility.doubleToLocalCurrency(value: self.userViewModel.getBalance(accountId: account.id, spent: self.transactionsViewModel.getSpent(user: self.userViewModel.user, accountId: account.id))))
                        }
                    }
                } header: {
                    Text("accounts")
                }

                Section {
                    ForEach(self.userViewModel.getTransactionCategoriesSorted(type: .expense)) { transactionCategory in
                        HStack(spacing: 5) {
                            Text(transactionCategory.name.localizeString())
                                .frame(width: 75, alignment: .leading)
                                .font(self.textSize.bold())

                            Spacer()

                            let spent = self.transactionsViewModel.getSpent(user: user, transactionCategory: transactionCategory)
                            Text(Utility.doubleToLocalCurrency(value: spent))
                                .frame(width: 75, alignment: .trailing)
                                .lineLimit(1)
                                .font(self.textSize)

                            Spacer()

                            let amount = transactionCategory.getRealAmount(budget: user.budget)

                            ProgressView(value: min(spent, amount), total: amount)
                                .tint(spent < amount ? Color.green : Color.red)

                            Spacer()

                            Text(Utility.doubleToLocalCurrency(value: amount))
                                .frame(width: 75, alignment: .leading)
                                .lineLimit(1)
                                .font(self.textSize)
                        }
                    }
                } header: {
                    Text("expenses")
                }

                Section {
                    ForEach(self.userViewModel.getFriendsSorted()) { friend in
                        let standing = self.standingsViewModel.getStanding(userId1: self.userViewModel.user.id, userId2: friend.id)
                        let amount = standing?.getStanding(myId: self.userViewModel.user.id) ?? 0
                        Button {
                            if amount < 0 {
                                if let url = URL(string: Utility.getSwishUrl(amount: amount, friend: friend)) {
                                    UIApplication.shared.open(url)
                                }
                            } else if amount > 0 {
                                self.showSendReminderAlert = true
                            }
                        } label: {
                            HStack {
                                Text(friend.name)
                                    .foregroundColor(.primary)
                                Spacer()
                                Text(Utility.doubleToLocalCurrency(value: amount))
                                    .foregroundColor(amount < 0 ? Color.red : Color.green)
                            }
                        }
                    }
                    // TODO: - Only see favourite friends in standing
                    // TODO: - Fix so you can favourite a friend
                    // TODO: - Add See All button to show all standing between your friends
                    // TODO: - Fix so the standing decrease after swish
                } header: {
                    Text("standings")
                }
            }
            .redacted(when: !self.standingsViewModel.firstLoadFinished)
            .navigationTitle("home")
            .toolbar {
                ToolbarItem {
                    NavigationLink {
                        NotificationsView()
                    } label: {
                        Image(systemName: "bell")
                            .foregroundColor(.primary)
                            .myBadge(count: self.notificationsViewModel.getNumberOfUnreadNotifications())
                    }
                }
            }
            .alert("sendReminder?", isPresented: self.$showSendReminderAlert) {
                Button("send", role: .destructive) {
                    // TODO: - Send a reminder
                }
            } message: {
                Text("doYouWantToRemind")
            }
            .alert("didSwishGoThrough?", isPresented: self.$showDidSwishGoThrough) {
                Button("yes", role: .destructive) {
                    // TODO: - Send notification that you swished
                    guard let swishFriendId = self.swishFriendId else {
                        let info = "Found nil when extracting swishFriendId in alert in HomeView"
                        self.errorHandling.handle(error: ApplicationError.unexpectedNil(info))
                        return
                    }
                    self.standingsViewModel.squareUp(myId: self.userViewModel.user.id, friendId: swishFriendId) { error in
                        if let error = error {
                            self.errorHandling.handle(error: error)
                            return
                        }

                        // Success
                        print("Successfully squared up standings between you and user with id: \(swishFriendId)")
                        self.swishFriendId = nil
                    }
                }
            } message: {
                Text("")
            }
            .onOpenURL { url in
                self.handleUrlOpen(url: url)
            }
        }
    }

    private func handleUrlOpen(url: URL) {
        let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: true)
        if let queryItems = urlComponents?.queryItems {
            for queryItem in queryItems {
                if let value = queryItem.value {
                    if queryItem.name == "userId" && !value.isEmpty {
                        self.swishFriendId = value
                        self.showDidSwishGoThrough = true
                    }
                }
            }
        }
    }
}

extension View {
    @ViewBuilder
    func redacted(when condition: Bool) -> some View {
        if !condition {
            unredacted()
        } else {
            self.redacted(reason: .placeholder)
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
