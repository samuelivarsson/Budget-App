//
//  SavingsAccountHistory.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2023-03-22.
//

import Foundation

struct AccountHistory: Codable {
    var accountId: String
    var accountName: String
    var balance: Double
    var saveDate: Date
    var userId: String
}
