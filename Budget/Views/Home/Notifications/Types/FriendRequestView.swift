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
    private let bodySize: Font
    
    init(notification: Notification, bodySize: Font) {
        self.notification = notification
        self.bodySize = bodySize
    }
    
    var body: some View {
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
                        .padding(5)
                        .foregroundColor(.primary)
                        .minimumScaleFactor(0.1)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, maxHeight: self.buttonHeight)
                .background(Color.accentColor)
                .cornerRadius(self.cornerRadius)
                    
                Button {
                    self.denyFriendRequest()
                } label: {
                    Text("deny")
                        .padding(5)
                        .foregroundColor(.primary)
                        .minimumScaleFactor(0.1)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, minHeight: self.buttonHeight)
                .background(Color.secondary)
                .cornerRadius(self.cornerRadius)
            }.frame(maxWidth: .infinity)
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
            let myName = self.userViewModel.user.name
            
            guard let friend = self.userViewModel.getFriendFromId(id: self.notification.from) else {
                print("Could not find friend in acceptFriendRequest in FriendRequestView, might be custom friend")
                return
            }
            self.notificationsViewModel.acceptFriendRequest(notification: self.notification, friend: friend, myName: myName) { error in
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
            guard let friend = self.userViewModel.getFriendFromId(id: self.notification.from) else {
                print("Could not find friend in denyFriendRequest in FriendRequestView, might be custom friend")
                return
            }
            self.notificationsViewModel.denyFriendRequest(notification: self.notification, friend: friend) { error in
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
