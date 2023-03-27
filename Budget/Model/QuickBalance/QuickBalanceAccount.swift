//
//  QuickBalanceAccount.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2023-03-24.
//

import Foundation

struct QuickBalanceAccount: Codable, Hashable {
    var name: String
    var subscriptionId: String
    var budgetAccountId: String
    
    static func getDummyAccount() -> QuickBalanceAccount {
        return QuickBalanceAccount(name: "", subscriptionId: "", budgetAccountId: "")
    }
}
