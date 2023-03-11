//
//  Budget.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2023-03-04.
//

import Foundation

struct Budget: Identifiable, Codable, Hashable {
    var id: String = UUID().uuidString
    var accounts: [Account]
    var income: Double
    var savingsPercentage: Double
    var transactionCategoryAmounts: [TransactionCategoryAmount]
    var overheads: [Overhead]
    var overheadAccount: Account

    static func getDefault() -> Budget {
        return Budget(accounts: [], income: 0, savingsPercentage: 0.5, transactionCategoryAmounts: [], overheads: [], overheadAccount: Account(name: "Overheads", type: .overhead))
    }
    
    func getOverheadsAmount() -> Double {
        var overheadsAmount: Double = 0
        self.overheads.forEach { overheadsAmount += $0.amount }
        return overheadsAmount
    }
    
    func getSavings() -> Double {
        return self.savingsPercentage * (self.income - self.getOverheadsAmount())
    }

    func getRemaining() -> Double {
        return self.income - self.getOverheadsAmount() - self.getSavings()
    }
}
