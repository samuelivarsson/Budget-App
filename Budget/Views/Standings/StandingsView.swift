//
//  StandingsView.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2023-03-20.
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

    var body: some View {
        NavigationView {
            Form {
                let favouriteFriends = self.userViewModel.getFriendsSorted(favourites: true)
                if favouriteFriends.count > 0 {
                    Section {
                        self.getStandings(friends: favouriteFriends)
                    } header: {
                        Text("favourites")
                    }
                }

                let otherFriends = self.userViewModel.getFriendsSorted(favourites: false)
                if otherFriends.count > 0 {
                    Section {
                        self.getStandings(friends: otherFriends)
                    } header: {
                        Text("otherFriends")
                    }
                }

                let customFriends = self.userViewModel.getCustomFriendsSorted()
                if customFriends.count > 0 {
                    Section {
                        self.getStandings(friends: customFriends, customFriends: true)
                    } header: {
                        Text("customFriends")
                    }
                }

                let temporaryFriends = self.getTemporaryFriends()
                if temporaryFriends.count > 0 && self.isShowingTemporaryFriends(temporaryFriends: temporaryFriends) {
                    Section {
                        self.getStandings(friends: temporaryFriends, temporary: true)
                    } header: {
                        Text("temporaryFriends")
                    }
                }
            }
            .navigationTitle("standings")
        }
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

    private func getStandings(friends: [any Named], customFriends: Bool = false, temporary: Bool = false) -> some View {
        ForEach(friends, id: \.id) { friend in
            let amount = self.standingsViewModel.getStandingAmount(myId: self.userViewModel.user.id, friendId: friend.id)
            if !(round(amount * 100) == 0 && temporary) {
                Button {
                    if amount < 0 {
                        let info = self.transactionsViewModel.getSwishInfo(myId: self.userViewModel.user.id, standing: amount, friendId: friend.id)
                        AppOpener.openSwish(amount: amount, friend: friend, info: info)
                    } else if amount > 0 {
                        if customFriends || temporary {
                            self.swishFriendId = friend.id
                            self.showDidFriendSwish = true
                        } else {
                            self.swishFriendId = friend.id
                            self.showSendReminderAlert = true
                        }
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
        }
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
    
    private func isShowingTemporaryFriends(temporaryFriends: [CustomFriend]) -> Bool {
        for temporaryFriend in temporaryFriends {
            let amount = self.standingsViewModel.getStandingAmount(myId: self.userViewModel.user.id, friendId: temporaryFriend.id)
            if round(amount * 100) != 0 {
                return true
            }
        }
        return false
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
