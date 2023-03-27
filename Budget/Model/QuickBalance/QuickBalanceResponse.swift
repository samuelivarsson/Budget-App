//
//  QuickBalanceResponse.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2023-03-23.
//

import Foundation

struct QuickBalanceResponse: Codable {
    let balance: String
    let balanceWithoutDecimals: String
    let currency: String
    let remindersExists: Bool
    let numberOfReminders: Int
    let balanceForCustomer: Bool
    let expirationDate: String
    let expirationMessage: String
    let name: String

    init(balance: String, balanceWithoutDecimals: String, currency: String, remindersExists: Bool, numberOfReminders: Int, balanceForCustomer: Bool, expirationDate: String, expirationMessage: String, name: String) {
        self.balance = balance
        self.balanceWithoutDecimals = balanceWithoutDecimals
        self.currency = currency
        self.remindersExists = remindersExists
        self.numberOfReminders = numberOfReminders
        self.balanceForCustomer = balanceForCustomer
        self.expirationDate = expirationDate
        self.expirationMessage = expirationMessage
        self.name = name
    }
    
    init(data: [String: Any]) {
        self.balance = data["balance"] as? String ?? ""
        self.balanceWithoutDecimals = data["balanceWithoutDecimals"] as? String ?? ""
        self.currency = data["currency"] as? String ?? ""
        self.remindersExists = data["remindersExists"] as? Bool ?? false
        self.numberOfReminders = data["numberOfReminders"] as? Int ?? 0
        self.balanceForCustomer = data["balanceForCustomer"] as? Bool ?? false
        self.expirationDate = data["expirationDate"] as? String ?? ""
        self.expirationMessage = data["expirationMessage"] as? String ?? ""
        self.name = data["name"] as? String ?? ""
    }
    
    static func getDummyBalance() -> QuickBalanceResponse {
        return QuickBalanceResponse(balance: "", balanceWithoutDecimals: "", currency: "", remindersExists: false, numberOfReminders: 0, balanceForCustomer: false, expirationDate: "", expirationMessage: "", name: "")
    }
}
