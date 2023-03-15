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
    var transactionCategories: [TransactionCategory]
    var transactionCategoryThatUsesRest: String
    var overheads: [Overhead]

    static func getDummyBudget() -> Budget {
        return Budget(accounts: [], income: 0, savingsPercentage: 0.5, transactionCategories: [], transactionCategoryThatUsesRest: "", overheads: [])
    }
    
    func getOverheadsAmount() -> Double {
        var overheadsAmount: Double = 0
        self.overheads.forEach { overheadsAmount += $0.amount }
        return overheadsAmount
    }
    
    func getSavings() -> Double {
        return self.savingsPercentage * (self.income - self.getOverheadsAmount())
    }

    func getRemaining(accountId: String) -> Double {
        let account = self.getAccount(id: accountId)
        if account.type == .transaction && account.main {
            return account.baseAmount + self.income - self.getOverheadsAmount() - self.getSavings()
        } else {
            return account.baseAmount
        }
    }
    
    func getTransactionCategoryCeilings(accountId: String, exceptFor: TransactionCategory? = nil) -> Double {
        var total: Double = 0
        self.transactionCategories.forEach { transactionCategory in
            if self.transactionCategoryThatUsesRest != transactionCategory.id && exceptFor?.id ?? "" != transactionCategory.id && transactionCategory.takesFromAccount == accountId {
                total += transactionCategory.getRealAmount(budget: self)
            }
        }
        return total
    }
    
    func getRestOfRemaining(accountId: String) -> Double {
        return self.getRemaining(accountId: accountId) - self.getTransactionCategoryCeilings(accountId: accountId)
    }
    
    /// Returns true if all transaction category amounts sums up to less than the remaining money. Is used to check that there is money left for the category that uses the rest.
    func transactionCategoriesAreLowerThanRemaining(updated: TransactionCategory) -> Bool {
        return self.getTransactionCategoryCeilings(accountId: updated.takesFromAccount, exceptFor: updated) + updated.getRealAmount(budget: self) <= self.getRemaining(accountId: updated.takesFromAccount)
    }
    
    func getMainAccountId(type: AccountType) -> String {
        for account in self.accounts {
            if account.type == type && account.main {
                return account.id
            }
        }
        // If no main account is set, search for a non main account as fail-safe
        for account in self.accounts {
            if account.type == type {
                return account.id
            }
        }
        return ""
    }
    
    func getAccount(id: String) -> Account {
        let errorAccount = Account(name: "Error", type: .transaction)
        return self.accounts.first { $0.id == id } ?? errorAccount
    }
    
    func getBaseAmount(accountId: String) -> Double {
        return self.getAccount(id: accountId).baseAmount
    }
}
