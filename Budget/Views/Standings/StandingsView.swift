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

    @State private var showSendReminderAlert: Bool = false
    @State private var showDidSwishGoThrough: Bool = false
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
            }
            .navigationTitle("standings")
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

    private func getStandings(friends: [User]) -> some View {
        ForEach(friends) { friend in
            let standing = self.standingsViewModel.getStanding(userId1: self.userViewModel.user.id, userId2: friend.id)
            let amount = standing?.getStanding(myId: self.userViewModel.user.id) ?? 0
            Button {
                if amount < 0 {
                    if let url = Utility.getSwishUrl(amount: amount, friend: friend) {
                        print(url)
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
    }

    private func handleUrlOpen(url: URL) {
        let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: true)
        if let queryItems = urlComponents?.queryItems {
            for queryItem in queryItems {
                if let value = queryItem.value {
                    if queryItem.name == "sourceApplication" && value != "swish" {
                        return
                    }
                    if queryItem.name == "userId" && !value.isEmpty {
                        self.swishFriendId = value
                        self.showDidSwishGoThrough = true
                    }
                }
            }
        }
    }
}

struct StandingsView_Previews: PreviewProvider {
    static var previews: some View {
        StandingsView()
    }
}
