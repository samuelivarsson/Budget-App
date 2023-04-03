//
//  ReminderNotificationView.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2023-04-03.
//

import SwiftUI

struct ReminderNotificationView: View {
    private let notification: Notification

    private let bodySize: Font

    init(notification: Notification, bodySize: Font) {
        self.notification = notification
        self.bodySize = bodySize
    }

    var body: some View {
        Text("youHaveBeenRemindedToSwish")
            .font(self.bodySize)
            .minimumScaleFactor(0.5)
            .lineLimit(2)
    }
}

// struct ReminderNotificationView_Previews: PreviewProvider {
//    static var previews: some View {
//        ReminderNotificationView()
//    }
// }
