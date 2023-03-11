//
//  NotificationView.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2022-11-07.
//

import SwiftUI

struct NotificationView: View {
    @EnvironmentObject private var errorHandling: ErrorHandling
    @EnvironmentObject private var userViewModel: UserViewModel
    @EnvironmentObject private var notificationsViewModel: NotificationsViewModel
    @EnvironmentObject private var friendsViewModel: FriendsViewModel
    
    private let notification: Notification
    
    @State private var uiImage: UIImage?
    private let failImage = Image(systemName: "person.circle")
    
    private let notificationHeight: CGFloat = 100
    private let pictureSize: CGFloat = 90
    private let titleSize: Font = .headline
    private let nameSize: Font = .subheadline
    private let timeSinceSize: Font = .footnote
    
    init(notification: Notification) {
        self.notification = notification
    }
    
    var body: some View {
        HStack(spacing: 15) {
            ProfilePicture(uiImage: self.uiImage, failImage: self.failImage)
                .frame(width: self.pictureSize, height: self.pictureSize)
                .clipShape(Circle())
                .onLoad {
                    self.friendsViewModel.getPicture(uid: self.notification.from) { uiImage, error in
                        if let error = error {
                            self.errorHandling.handle(error: error)
                            return
                        }
                        
                        // Success
                        self.uiImage = uiImage
                    }
                }
            
            switch self.notification.type {
            case .friendRequest:
                FriendRequestView(notification: self.notification)
                
            case .friendRequestAccepted:
                FriendRequestView(notification: self.notification)
                
            case .friendRequestDenied:
                FriendRequestView(notification: self.notification)
                
            case .transaction:
                TransactionNotificationView(notification: self.notification)
            }
        }
        .frame(height: self.notificationHeight)
        .buttonStyle(BorderlessButtonStyle())
    }
}
