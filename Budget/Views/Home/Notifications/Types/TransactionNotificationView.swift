//
//  TransactionNotificationView.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2022-11-08.
//

import SwiftUI

struct TransactionNotificationView: View {
    private let notification: Notification

    private let bodySize: Font

    init(notification: Notification, bodySize: Font) {
        self.notification = notification
        self.bodySize = bodySize
    }

    var body: some View {
        if self.notification.type == .transaction {
            Text("\("youHaveBeenAddedToTransaction".localizeString()) **\(self.notification.desc)**")
                .font(self.bodySize)
                .minimumScaleFactor(0.5)
                .lineLimit(2)
        } else {
            Text("\("editedTheTransaction".localizeString()) **\(self.notification.desc)**")
                .font(self.bodySize)
                .minimumScaleFactor(0.5)
                .lineLimit(2)
        }
    }
}
