//
//  NotificationsView.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2022-04-19.
//

import Firebase
import SwiftUI

struct NotificationsView: View {
    @Environment(\.colorScheme) var colorScheme
    
    @EnvironmentObject private var errorHandling: ErrorHandling
    @EnvironmentObject private var notificationsViewModel: NotificationsViewModel
    
    private let dotSize: CGFloat = 8
    
    var body: some View {
        VStack {
            if self.notificationsViewModel.notifications.count < 1 {
                Text("youHaveNoNotifications")
            } else {
                Form {
                    ForEach(self.notificationsViewModel.notifications) { notification in
                        ZStack {
                            HStack {
                                Spacer()
                                VStack {
                                    Spacer()
                                            
                                    if notification.read {
                                        Button {
                                            self.unReadNotification(notification: notification)
                                        } label: {
                                            Image(systemName: "eye.slash")
                                        }
                                    } else {
                                        Button {
                                            self.readNotification(notification: notification)
                                        } label: {
                                            Image(systemName: "eye")
                                        }
                                    }
                                            
                                    Spacer()
                                }
                            }
                            HStack {
                                Circle()
                                    .fill(notification.read ? Color.clear : Color.accentColor)
                                    .frame(width: self.dotSize, height: self.dotSize, alignment: .leading)
                                    .offset(x: -self.dotSize/2)
                                
                                NotificationView(notification: notification)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("notifications")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem {
                Button {
                    self.markAllAsRead()
                } label: {
                    Text("readAll")
                }
            }
        }
    }
    
    private func markAllAsRead() {
        self.notificationsViewModel.setAllNotificationsAsRead { error in
            if let error = error {
                self.errorHandling.handle(error: error)
                return
            }
            
            // Success
            print("Successfully marked all notifications as read")
        }
    }
    
    private func readNotification(notification: Notification) {
        self.notificationsViewModel.setNotificationAsRead(notification: notification) { error in
            if let error = error {
                self.errorHandling.handle(error: error)
                return
            }
            
            // Success
        }
    }
    
    private func unReadNotification(notification: Notification) {
        self.notificationsViewModel.setNotificationAsUnRead(notification: notification) { error in
            if let error = error {
                self.errorHandling.handle(error: error)
                return
            }
            
            // Success
        }
    }
}

struct NotificationsView_Previews: PreviewProvider {
    static var previews: some View {
        NotificationsView()
    }
}

struct MyButtonStyle: ButtonStyle {
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .background(configuration.isPressed ? Color.red : Color.blue)
    }
}
