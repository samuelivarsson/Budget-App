//
//  NotificationsView.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2022-04-19.
//

import SwiftUI
import Firebase

enum NotificationType {
    case transaction
    case friendRequest
}

struct UserNotification {
    let user: String
    let type: NotificationType
}

struct NotificationsView: View {
    private var notifications: [UserNotification]?
    
    var body: some View {
        List {
            
        }
        .navigationTitle("notifications")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem {
                Button {
                    markAllAsRead()
                } label: {
                    Text("readAll")
                }
            }
        }
    }
    
    private func markAllAsRead() {
        
    }
}

struct NotificationsView_Previews: PreviewProvider {
    static var previews: some View {
        NotificationsView()
    }
}
