//
//  NotificationType.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2022-10-23.
//

import Foundation

enum NotificationType: Int16, Codable {
    case friendRequest
    case transaction
    case friendRequestAccepted
    case friendRequestDenied
    case transactionEdit
    case squaredUp
    case swishReminder
}
