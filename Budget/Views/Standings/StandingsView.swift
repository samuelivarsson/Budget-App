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
                self.notificationsViewModel.sendReminder(me: self.userViewModel.user, friendId: swishFriendId) { error in
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
                    self.notificationsViewModel.sendSquaredUpNotification(me: self.userViewModel.user, friendId: swishFriendId) { error in
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

    private func getStandings(friends: [any Named], customFriends: Bool = false) -> some View {
        ForEach(friends, id: \.id) { friend in
            let amount = self.standingsViewModel.getStandingAmount(myId: self.userViewModel.user.id, friendId: friend.id)
            Button {
                if amount < 0 {
                    AppOpener.openSwish(amount: amount, friend: friend)
                } else if amount > 0 {
                    if customFriends {
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
