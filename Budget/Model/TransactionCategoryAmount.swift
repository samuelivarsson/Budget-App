//
//  TransactionCategoryAmount.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2023-03-04.
//

import Foundation

struct TransactionCategoryAmount: Identifiable, Codable, Hashable {
    var id: String = UUID().uuidString
    var categoryId: String
    var categoryName: String
    var amount: Double
    var custom: Bool = false
    var customPercentage: Double = 0
    
    func getCustomAmount(budget: Budget) -> Double {
        return self.customPercentage * 0.01 * budget.getRemaining()
    }
    
    func getRealAmount(budget: Budget) -> Double {
        if self.custom {
            return self.getCustomAmount(budget: budget)
        } else {
            return self.amount
        }
    }
}
