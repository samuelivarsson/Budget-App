//
//  StandingsView.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2023-03-20.
//  v2 — iOS 26 redesign: summary cards, filter, grouped balance rows with
//  per-row settle/remind/regulate actions. Action logic unchanged.
//

import SwiftUI

struct StandingsView: View {
    @EnvironmentObject private var errorHandling: ErrorHandling
    @EnvironmentObject private var userViewModel: UserViewModel
    @EnvironmentObject private var standingsViewModel: StandingsViewModel
    @EnvironmentObject private var notificationsViewModel: NotificationsViewModel
    @EnvironmentObject private var transactionsViewModel: TransactionsViewModel

    @State private var showSendReminderAlert: Bool = false
    @State private var showDidSwishGoThrough: Bool = false
    @State private var showDidFriendSwish: Bool = false
    @State private var swishFriendId: String? = nil
    @State private var amountSwished: Double? = nil

    @State private var filter: StandingFilter = .all
    @State private var expandedGroups: Set<String> = []
    private let collapseLimit = 4

    private var myId: String { userViewModel.user.id }
    private func money(_ v: Double) -> String { Utility.doubleToLocalCurrency(value: v) }
    private func amount(_ friendId: String) -> Double {
        standingsViewModel.getStandingAmount(myId: myId, friendId: friendId)
    }
    private func hasBalance(_ friendId: String) -> Bool { round(amount(friendId) * 100) != 0 }

    // MARK: Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    summaryRow
                    IOSStandingFilterBar(selection: $filter,
                                         toSettleCount: standingsViewModel.toSettleCount(myId: myId))
                        .padding(.top, 14).padding(.bottom, 2)
                    sections
                }
                .padding(.horizontal, 20)
                .padding(.top, 4)
                .padding(.bottom, 120)
            }
            .background(Color.iosBG.ignoresSafeArea())
            .navigationTitle("standings")
        }
        .redacted(when: myId.isEmpty || !standingsViewModel.hasLoaded)
        .alert("sendReminder?", isPresented: self.$showSendReminderAlert) {
            Button("send", role: .destructive) {
                guard let swishFriendId = swishFriendId else {
                    let info = "Found nil when extracting swishFriendId in sendReminder in StandingsView"
                    self.errorHandling.handle(error: ApplicationError.unexpectedNil(info))
                    return
                }
                guard let friend = self.userViewModel.getFriendFromId(id: swishFriendId) else {
                    print("Could not find friend in sendReminder in StandingsView, might be custom friend")
                    return
                }
                self.notificationsViewModel.sendReminder(me: self.userViewModel.user, friend: friend) { error in
                    if let error = error {
                        self.errorHandling.handle(error: error)
                        return
                    }

                    // Success
                    print("Successfully sent reminder to user with id: \(swishFriendId)")
                    self.swishFriendId = nil
                }
            }
        } message: {
            Text("doYouWantToRemind")
        }
        .alert("didSwishGoThrough?", isPresented: self.$showDidSwishGoThrough) {
            Button("yes", role: .destructive) {
                // TODO: - Send notification that you swished
                guard let swishFriendId = self.swishFriendId else {
                    let info = "Found nil when extracting swishFriendId in alert in StandingsView"
                    self.errorHandling.handle(error: ApplicationError.unexpectedNil(info))
                    return
                }

                guard let amountSwished = self.amountSwished else {
                    let info = "Found nil when extracting amountSwished in alert in StandingsView"
                    self.errorHandling.handle(error: ApplicationError.unexpectedNil(info))
                    return
                }

                self.standingsViewModel.squareUpAfterOutgoingSwish(myId: self.userViewModel.user.id, friendId: swishFriendId, amount: amountSwished) { error in
                    self.amountSwished = nil

                    if let error = error {
                        self.errorHandling.handle(error: error)
                        return
                    }

                    // Success
                    print("Successfully squared up standings between you and user with id: \(swishFriendId)")
                    guard let friend = self.userViewModel.getFriendFromId(id: swishFriendId) else {
                        print("Could not find friend in didSwishGoThrough in StandingsView, might be custom friend")
                        return
                    }
                    self.notificationsViewModel.sendSquaredUpNotification(me: self.userViewModel.user, friend: friend) { error in
                        if let error = error {
                            self.errorHandling.handle(error: error)
                            return
                        }

                        // Success
                        print("Successfully sent square up notification to user with id: \(swishFriendId)")
                        self.swishFriendId = nil
                    }
                }
            }
        } message: {
            Text("")
        }
        .alert("didFriendSwish?", isPresented: self.$showDidFriendSwish) {
            Button("yes", role: .destructive) {
                guard let swishFriendId = self.swishFriendId else {
                    let info = "Found nil when extracting swishFriendId in alert in HomeView"
                    self.errorHandling.handle(error: ApplicationError.unexpectedNil(info))
                    return
                }
                self.standingsViewModel.squareUpAfterIncomingSwish(myId: self.userViewModel.user.id, friendId: swishFriendId) { error in
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

    // MARK: Summary

    private var summaryRow: some View {
        HStack(spacing: 10) {
            IOSStandingSummary(
                title: "youOwe",
                value: money(standingsViewModel.getTotalIOwe(myId: myId)),
                subtitle: friendCountText(standingsViewModel.oweCount(myId: myId)),
                color: StandingColors.owe
            )
            IOSStandingSummary(
                title: "youGetBack",
                value: money(standingsViewModel.getTotalOwedToMe(myId: myId)),
                subtitle: friendCountText(standingsViewModel.owedToMeCount(myId: myId)),
                color: StandingColors.get
            )
        }
    }

    private func friendCountText(_ count: Int) -> String {
        let word = (count == 1 ? "friend" : "friends").localizeString().lowercased()
        return "\(count) \(word)"
    }

    // MARK: Sections

    @ViewBuilder
    private var sections: some View {
        let favourites = filtered(userViewModel.getFavouritesSorted())
        if !favourites.isEmpty {
            sectionLabel("favourites")
            standingCard(members: favourites, groupKey: "__fav")
        }

        ForEach(userViewModel.getFriendGroupsSorted(), id: \.self) { group in
            let members = filtered(groupMembers(group))
            if !members.isEmpty {
                sectionLabel("\(displayGroup(group)) · \(members.count) \("friends".localizeString().lowercased())")
                standingCard(members: members, groupKey: group)
            }
        }

        let temporary = filtered(getTemporaryFriends())
        if !temporary.isEmpty {
            sectionLabel("temporaryFriends".localizeString())
            standingCard(members: temporary, groupKey: "__temp")
        }
    }

    private func sectionLabel(_ title: String) -> some View {
        HStack {
            Text(LocalizedStringKey(title))
                .font(.system(size: 11, weight: .bold)).kerning(0.7)
                .textCase(.uppercase).foregroundColor(.secondary)
            Spacer()
        }
        .padding(.horizontal, 6).padding(.top, 20).padding(.bottom, 8)
    }

    /// Builds one card of standing rows, sorting rows with a balance to the top
    /// and collapsing long groups behind a "Visa fler" button.
    @ViewBuilder
    private func standingCard(members: [any Named], groupKey: String) -> some View {
        let sorted = members.sorted { hasBalance($0.id) && !hasBalance($1.id) }
        let expanded = filter == .toSettle || expandedGroups.contains(groupKey)
        let shown = expanded ? sorted : Array(sorted.prefix(collapseLimit))
        let showMore = !expanded && sorted.count > collapseLimit

        IOSStandingCard(
            count: shown.count,
            showMore: showMore,
            moreCount: sorted.count - collapseLimit,
            onShowMore: { expandedGroups.insert(groupKey) }
        ) { i in
            let friend = shown[i]
            IOSStandingRow(
                name: friend.name,
                id: friend.id,
                amount: amount(friend.id),
                isCustom: !(friend is User),
                money: money,
                onAction: { performAction(friend: friend) }
            )
        }
    }

    // MARK: Row action (unchanged behaviour)

    private func performAction(friend: any Named) {
        let amount = self.amount(friend.id)
        if amount < 0 {
            // Gör upp — open Swish to pay the friend.
            let info = transactionsViewModel.getSwishInfo(myId: myId, standing: amount, friendId: friend.id)
            AppOpener.openSwish(amount: amount, friend: friend, info: info)
        } else if amount > 0 {
            self.swishFriendId = friend.id
            if friend is User {
                self.showSendReminderAlert = true   // Påminn
            } else {
                self.showDidFriendSwish = true       // Reglera
            }
        }
    }

    // MARK: Data helpers

    private func filtered(_ members: [any Named]) -> [any Named] {
        guard filter == .toSettle else { return members }
        return members.filter { hasBalance($0.id) }
    }

    private func groupMembers(_ group: String) -> [any Named] {
        userViewModel.getAllNonFavouriteFriendsSorted().filter {
            userViewModel.getFriendGroup(friendId: $0.id) == group
        }
    }

    private func displayGroup(_ group: String) -> String {
        group.isEmpty ? "noGroup".localizeString() : group
    }

    private func getTemporaryFriends() -> [CustomFriend] {
        var temporaryFriends: [CustomFriend] = .init()
        for standing in self.standingsViewModel.standings {
            for userId in standing.userIds {
                if userId != self.userViewModel.user.id && !self.userViewModel.isFriend(uid: userId) {
                    guard let name = standing.userNames[userId] else {
                        let info = "Found nil when extracting name in getTemporaryFriends in StandingsView"
                        self.errorHandling.handle(error: ApplicationError.unexpectedNil(info))
                        return .init()
                    }
                    guard let phone = standing.phoneNumbers[userId] else {
                        let info = "Found nil when extracting phone in getTemporaryFriends in StandingsView"
                        self.errorHandling.handle(error: ApplicationError.unexpectedNil(info))
                        return .init()
                    }
                    let customFriend = CustomFriend(id: userId, name: name, phone: phone)
                    temporaryFriends.append(customFriend)
                }
            }
        }
        return temporaryFriends
    }

    private func handleUrlOpen(url: URL) {
        let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: true)
        if let queryItems = urlComponents?.queryItems {
            var userId = ""
            for queryItem in queryItems {
                if let value = queryItem.value {
                    if queryItem.name == "sourceApplication" && value != "swish" {
                        return
                    } else if queryItem.name == "userId" && !value.isEmpty {
                        userId = value
                    } else if queryItem.name == "amount" && !value.isEmpty {
                        self.amountSwished = Double(value)
                    }
                }
            }
            self.swishFriendId = userId
            self.showDidSwishGoThrough = true
        }
    }
}

struct StandingsView_Previews: PreviewProvider {
    static var previews: some View {
        StandingsView()
    }
}
