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

    @State private var showSendReminderAlert: Bool = false
    
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
                        let amount = self.transactionsViewModel.getStanding(friendId: friend.id, myUid: self.userViewModel.user.id)
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
                    // TODO - Only see favourite friends in standing
                    // TODO - Fix so you can favourite a friend
                    // TODO - Add See All button to show all standing between your friends
                    // TODO - Fix so the standing decrease after swish
                } header: {
                    Text("standings")
                }
            }
            .redacted(when: !self.transactionsViewModel.firstLoadFinished)
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
                    // Todo - Send reminder
                }
            } message: {
                Text("doYouWantToRemind")
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
            redacted(reason: .placeholder)
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
