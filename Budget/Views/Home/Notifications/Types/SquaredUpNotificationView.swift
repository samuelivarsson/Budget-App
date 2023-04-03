//
//  SquaredUpNotificationView.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2023-04-03.
//

import SwiftUI

struct SquaredUpNotificationView: View {
    private let notification: Notification

    private let bodySize: Font

    init(notification: Notification, bodySize: Font) {
        self.notification = notification
        self.bodySize = bodySize
    }

    var body: some View {
        Text("youAreNowEven")
            .font(self.bodySize)
            .minimumScaleFactor(0.5)
            .lineLimit(1)
    }
}

// struct SquaredUpNotificationView_Previews: PreviewProvider {
//    static var previews: some View {
//        SquaredUpNotificationView()
//    }
// }
