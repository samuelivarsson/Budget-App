//
//  TransactionCategory.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2022-10-01.
//

import Foundation
import Firebase

struct TransactionCategory: Identifiable, Codable, Hashable {
    var id = UUID().uuidString
    var name: String
    var type: TransactionType
    var takesFromAccount: String = ""
    var givesToAccount: String = ""
    var ceiling: Bool = true
    var ceilingAmount: Double = 0
    var customCeiling: Bool = false
    var customCeilingPercentage: Double = 0
    
    static func getDummyCategory() -> TransactionCategory {
        return TransactionCategory(name: "", type: .expense)
    }
    
    func getCustomAmount(budget: Budget) -> Double {
        return self.customCeilingPercentage * 0.01 * budget.getRemaining(accountId: self.takesFromAccount)
    }

    func getRealAmount(budget: Budget, useRest: Bool = false) -> Double {
        if budget.transactionCategoryThatUsesRest == self.id || useRest {
            return budget.getRestOfRemaining(accountId: self.takesFromAccount)
        } else if self.customCeiling {
            return self.getCustomAmount(budget: budget)
        } else {
            return self.ceilingAmount
        }
    }
}
