//
//  TransactionNotificationView.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2022-11-08.
//

import SwiftUI

struct TransactionNotificationView: View {
    private let notification: Notification
    
    private let titleSize: Font = .headline
    private let bodySize: Font = .subheadline
    private let timeSinceSize: Font = .footnote
    
    init(notification: Notification) {
        self.notification = notification
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("transaction")
                    .font(self.titleSize)
                Spacer()
                Text(Utility.getTimePassed(since: notification.date))
                    .foregroundColor(.secondary)
                    .font(self.timeSinceSize)
            }
            
            Spacer()
            
            Text("\(self.notification.fromName) " + NSLocalizedString("hasAddedYouToTransaction", comment: ""))
                .font(self.bodySize)
            
            Spacer()
        }
    }
}

