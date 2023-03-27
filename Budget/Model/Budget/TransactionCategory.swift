//
//  TransactionCategory.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2022-10-01.
//

import Firebase
import Foundation

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
        var rawValue: Double = 0
        if budget.transactionCategoryThatUsesRest == self.id || useRest {
            return budget.getRestOfRemaining(accountId: self.takesFromAccount)
        } else if self.customCeiling {
            rawValue = self.getCustomAmount(budget: budget)
        } else {
            rawValue = self.ceilingAmount
        }
        return round(rawValue / 100) * 100
    }
    
    private func isMine(budget: Budget) -> Bool {
        for myCategory in budget.transactionCategories {
            if myCategory.id == self.id {
                return true
            }
        }
        return false
    }
    
    func isNotMineButSameName(sameNameAs transactionCategory: TransactionCategory, budget: Budget) -> Bool {
        return transactionCategory.name == self.name && !self.isMine(budget: budget)
    }
}
