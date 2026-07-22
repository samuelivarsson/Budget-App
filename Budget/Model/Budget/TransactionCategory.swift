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

    private var takesFromAnAccount: Bool { !takesFromAccount.isEmpty }
    private var givesToAnAccount: Bool { !givesToAccount.isEmpty }

    /// The effective money flow, derived from structure rather than the
    /// (historically misused) `type` field:
    ///   - gives to an account only  → income   (money in from outside)
    ///   - takes from an account only → expense (money out to outside)
    ///   - both                       → transfer (internal movement)
    /// When neither is configured, falls back to the declared `type`. This means a
    /// legacy "income" category that also draws from an account (e.g. Påfyllning)
    /// correctly reads as a transfer, with no data migration.
    var moneyFlow: TransactionType {
        if takesFromAnAccount && givesToAnAccount { return .transfer }
        if givesToAnAccount { return .income }
        if takesFromAnAccount { return .expense }
        return type
    }

    /// True if this category moves money into the given savings account (a deposit).
    func depositsInto(accountId: String) -> Bool { givesToAccount == accountId }
    /// True if this category draws money out of the given account (a withdrawal).
    func withdrawsFrom(accountId: String) -> Bool { takesFromAccount == accountId }

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
