//
//  NotificationsView.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2022-04-19.
//

import SwiftUI
import Firebase

struct NotificationsView: View {
    @EnvironmentObject private var errorHandling: ErrorHandling
    @EnvironmentObject private var notificationsViewModel: NotificationsViewModel
    
    var body: some View {
        VStack {
            if self.notificationsViewModel.notifications.count < 1 {
                Text("youHaveNoNotifications")
            } else {
                Form {
                    ForEach(self.notificationsViewModel.notifications) { notification in
                        NotificationView(notification: notification)
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
}

struct NotificationsView_Previews: PreviewProvider {
    static var previews: some View {
        NotificationsView()
    }
}
