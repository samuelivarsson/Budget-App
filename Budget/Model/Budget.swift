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
    var transactionCategoryThatUsesRest: String
    var overheads: [Overhead]
    var overheadAccount: Account

    static func getDummyBudget() -> Budget {
        return Budget(accounts: [], income: 0, savingsPercentage: 0.5, transactionCategoryAmounts: [], transactionCategoryThatUsesRest: "", overheads: [], overheadAccount: Account(name: "Overheads", type: .overhead))
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
    
    func getCategoryAmounts(exceptFor: TransactionCategoryAmount? = nil) -> Double {
        var total: Double = 0
        self.transactionCategoryAmounts.forEach { transactionCategoryAmount in
            if self.transactionCategoryThatUsesRest != transactionCategoryAmount.categoryId && exceptFor?.categoryId ?? "" != transactionCategoryAmount.categoryId {
                total += transactionCategoryAmount.getRealAmount(budget: self)
            }
        }
        return total
    }
    
    func getRest() -> Double {
        return self.getRemaining() - self.getCategoryAmounts()
    }
    
    /// Returns true if all transaction category amounts sums up to less than the remaining money. Is used to check that there is money left for the category that uses the rest.
    func transactionCategoryAmountsAreLowerThanRemaining(updated: TransactionCategoryAmount) -> Bool {
        return self.getCategoryAmounts(exceptFor: updated) + updated.getRealAmount(budget: self) <= self.getRemaining()
    }
}
