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
    private let bodySize: Font = .system(size: 11)
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
            
            VStack(alignment: .leading) {
                Text(self.getTitle())
                    .font(self.titleSize)
            
                Spacer()
            
                Text(self.notification.fromName)
                    .font(self.nameSize)
            
                Spacer()
                
                switch self.notification.type {
                case .friendRequest:
                    FriendRequestView(notification: self.notification, bodySize: self.bodySize)
                
                case .friendRequestAccepted:
                    FriendRequestView(notification: self.notification, bodySize: self.bodySize)
                
                case .friendRequestDenied:
                    FriendRequestView(notification: self.notification, bodySize: self.bodySize)
                
                case .transaction:
                    TransactionNotificationView(notification: self.notification, bodySize: self.bodySize)
                
                case .transactionEdit:
                    TransactionNotificationView(notification: self.notification, bodySize: self.bodySize)
                
                case .squaredUp:
                    SquaredUpNotificationView(notification: self.notification, bodySize: self.bodySize)
                
                case .swishReminder:
                    ReminderNotificationView(notification: self.notification, bodySize: self.bodySize)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                Text(Utility.getTimePassed(since: self.notification.date))
                    .foregroundColor(.secondary)
                    .font(self.timeSinceSize)
                Spacer()
            }
        }
        .frame(height: self.notificationHeight)
        .buttonStyle(BorderlessButtonStyle())
    }
    
    private func getTitle() -> LocalizedStringKey {
        switch self.notification.type {
        case .friendRequest:
            return "friendRequest"
        case .friendRequestAccepted:
            return "friendRequest"
        case .friendRequestDenied:
            return "friendRequest"
        case .transaction:
            return "transaction"
        case .transactionEdit:
            return "transaction"
        case .swishReminder:
            return "reminder"
        case .squaredUp:
            return "standings"
        }
    }
}
