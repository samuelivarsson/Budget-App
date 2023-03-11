//
//  FriendRequestView.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2022-11-07.
//

import SwiftUI

struct FriendRequestView: View {
    @EnvironmentObject private var errorHandling: ErrorHandling
    @EnvironmentObject private var userViewModel: UserViewModel
    @EnvironmentObject private var notificationsViewModel: NotificationsViewModel
    @EnvironmentObject private var friendsViewModel: FriendsViewModel
    
    private let notification: Notification
    
    private let cornerRadius: CGFloat = 5
    private let buttonHeight: CGFloat = 33
    private let titleSize: Font = .headline
    private let nameSize: Font = .subheadline
    private let bodySize: Font = .subheadline
    private let timeSinceSize: Font = .footnote
    
    init(notification: Notification) {
        self.notification = notification
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("friendRequest")
                    .font(self.titleSize)
                Spacer()
                Text(Utility.getTimePassed(since: notification.date))
                    .foregroundColor(.secondary)
                    .font(self.timeSinceSize)
            }
            
            Spacer()
            
            Text(self.notification.fromName)
                .font(self.nameSize)
            
            Spacer()
            
            switch self.notification.type {
            case .friendRequestAccepted:
                Text("friendRequestAccepted")
                    .font(self.bodySize)
                
            case .friendRequestDenied:
                Text("friendRequestAccepted")
                    .font(self.bodySize)
                
            default:
                HStack(spacing: 5) {
                    Button {
                        self.acceptFriendRequest()
                    } label: {
                        Text("accept")
                            .foregroundColor(.primary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: self.buttonHeight)
                    .background(Color.accentColor)
                    .cornerRadius(self.cornerRadius)
                    
                    Button {
                        self.denyFriendRequest()
                    } label: {
                        Text("deny")
                            .foregroundColor(.primary)
                    }
                    .frame(maxWidth: .infinity, minHeight: self.buttonHeight)
                    .background(Color.secondary)
                    .cornerRadius(self.cornerRadius)
                }.frame(maxWidth: .infinity)
            }
        }
    }
    
    private func markAsRead() {
        self.notificationsViewModel.setNotificationAsRead(notification: self.notification) { error in
            if let error = error {
                self.errorHandling.handle(error: error)
                return
            }
            
            // Success
        }
    }
    
    private func acceptFriendRequest() {
        self.userViewModel.acceptFriendRequest(notification: self.notification) { error in
            if let error = error {
                self.errorHandling.handle(error: error)
                return
            }
            
            // Success
            guard let myName = self.userViewModel.user?.name else {
                let info = "Found nil when extracting myName in acceptFriendRequest in NotificationsView"
                print(info)
                self.errorHandling.handle(error: ApplicationError.unexpectedNil(info))
                return
            }
            
            self.notificationsViewModel.acceptFriendRequest(notification: self.notification, myName: myName) { error in
                if let error = error {
                    self.errorHandling.handle(error: error)
                    return
                }
                
                // Success
                self.markAsRead()
            }
        }
    }
    
    private func denyFriendRequest() {
        self.userViewModel.denyFriendRequest(notification: self.notification) { error in
            if let error = error {
                self.errorHandling.handle(error: error)
                return
            }
            
            // Success
            self.notificationsViewModel.denyFriendRequest(notification: self.notification) { error in
                if let error = error {
                    self.errorHandling.handle(error: error)
                    return
                }
                
                // Success
                self.markAsRead()
            }
        }
    }
}
