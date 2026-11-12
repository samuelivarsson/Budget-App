//
//  Budget.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2023-03-04.
//

import Foundation

struct Budget: Identifiable, Codable, Hashable {
    var id: String = UUID().uuidString
    var monthStartsOn: Int = 25
    var accounts: [Account]
    var income: Double
    var savingsPercentage: Double
    var savingAmounts: [String: Double] = .init()
    var transactionCategories: [TransactionCategory]
    var transactionCategoryThatUsesRest: String
    var overheads: [Overhead]

    static func getDummyBudget() -> Budget {
        return Budget(accounts: [], income: 0, savingsPercentage: 50, transactionCategories: [], transactionCategoryThatUsesRest: "", overheads: [])
    }
    
    func getAccount(id: String) -> Account {
        let errorAccount = Account(name: "Error", type: .transaction)
        return self.accounts.first { $0.id == id } ?? errorAccount
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
    
    func getOverheadsAmount(monthsBack: Int = 0) -> Double {
        var overheadsAmount: Double = 0
        self.overheads.forEach { overheadsAmount += $0.getShareOfAmount(monthStartsOn: self.monthStartsOn, monthsBack: monthsBack) }
        return overheadsAmount
    }
    
    func getFixedCeilings(accountId: String, type: TransactionType = .expense) -> Double {
        var total: Double = 0
        for transactionCategory in self.transactionCategories {
            // Continue if it's not the correct type, if it doesn't use a ceiling or if it uses a custom ceiling
            if transactionCategory.type != type || !transactionCategory.ceiling || transactionCategory.customCeiling {
                continue
            }
            // Continue if it's the category that uses rest
            if transactionCategory.id == self.transactionCategoryThatUsesRest {
                continue
            }
            // Continue if the category does not use the account
            if transactionCategory.takesFromAccount != accountId {
                continue
            }
            total += transactionCategory.getRealAmount(budget: self)
        }
        return total
    }
    
    /// Savings are a share of what is left after fixed costs. Fixed-amount categories are spending estimates, so they are paid from what remains after saving and do not lower the savings.
    func getSavings() -> Double {
        let mainTransactionAccount = self.getAccount(id: self.getMainAccountId(type: .transaction))
        let rawValue = self.savingsPercentage * 0.01 * (mainTransactionAccount.baseAmount + self.income - self.getOverheadsAmount())
        return round(rawValue / 100) * 100
    }
    
    func getRemaining(accountId: String, monthsBack: Int = 0) -> Double {
        let account = self.getAccount(id: accountId)
        if account.type == .transaction && account.main {
            return account.baseAmount + self.income - self.getOverheadsAmount(monthsBack: monthsBack) - self.getSavings() - self.getFixedCeilings(accountId: account.id)
        } else {
            return account.baseAmount
        }
    }
    
    func getTemporaryOverheadExtras(accountId: String) -> Double {
        let account = self.getAccount(id: accountId)
        if account.type != .overhead {
            return 0
        }
        
        var total: Double = 0
        for overhead in overheads {
            total += overhead.getTemporaryBalanceOnAccount(monthStartsOn: self.monthStartsOn)
        }
        return total
    }
    
    func getSavingAmounts() -> Double {
        var total: Double = 0
        for savingAmount in self.savingAmounts.values {
            total += savingAmount
        }
        return total
    }
    
    func getRemainingSavingAmount() -> Double {
        return self.getSavings() - self.getSavingAmounts()
    }
    
    func getSavingAmount(accountId: String) -> Double {
        let account = self.getAccount(id: accountId)
        if account.main && account.type == .saving {
            return self.getRemainingSavingAmount()
        }
        return self.savingAmounts[accountId] ?? 0
    }
    
    func getBalance(accountId: String, spent: Double, incomes: Double, monthsBack: Int = 0) -> Double {
        let remaining = self.getRemaining(accountId: accountId, monthsBack: monthsBack)
        let fixedCeilings = self.getFixedCeilings(accountId: accountId)
        let savingsAmount = self.getSavingAmount(accountId: accountId)
        let temporaryOverheadExtras = self.getTemporaryOverheadExtras(accountId: accountId)
        return remaining + fixedCeilings - spent + incomes + savingsAmount + temporaryOverheadExtras
    }
    
    func getCustomCeilings(accountId: String, type: TransactionType = .expense, exceptFor: TransactionCategory? = nil) -> Double {
        var total: Double = 0
        for transactionCategory in self.transactionCategories {
            // Continue if it's not the correct type, if it doesn't use a ceiling or if it does not use a custom ceiling
            if transactionCategory.type != type || !transactionCategory.ceiling || !transactionCategory.customCeiling {
                continue
            }
            // Continue if it's the category that uses rest
            if transactionCategory.id == self.transactionCategoryThatUsesRest {
                continue
            }
            // Continue if the category does not use the account
            if transactionCategory.takesFromAccount != accountId {
                continue
            }
            // Continue if it's the category that should be skipped
            if transactionCategory.id == exceptFor?.id ?? "" {
                continue
            }
            total += transactionCategory.getRealAmount(budget: self)
        }
        return total
    }
    
    func getRestOfRemaining(accountId: String) -> Double {
        return self.getRemaining(accountId: accountId) - self.getCustomCeilings(accountId: accountId)
    }
    
    /// Returns true if all transaction category amounts sums up to less than the remaining money. Is used to check that there is money left for the category that uses the rest.
    /// The check runs on a copy where `updated` replaces the stored category, so an edited category's old amount is not counted next to its new one.
    func transactionCategoriesAreLowerThanRemaining(updated: TransactionCategory) -> Bool {
        var budget = self
        if let index = budget.transactionCategories.firstIndex(where: { $0.id == updated.id }) {
            budget.transactionCategories[index] = updated
        } else {
            budget.transactionCategories.append(updated)
        }
        return budget.categoriesFitWithinRemaining(accountId: updated.takesFromAccount)
    }

    /// Returns true if, with the given savings percentage, the main transaction account still has room for every transaction category, so the category that uses the rest does not go negative.
    func savingsPercentageLeavesRoomForCategories(_ percentage: Double) -> Bool {
        var budget = self
        budget.savingsPercentage = percentage
        return budget.categoriesFitWithinRemaining(accountId: budget.getMainAccountId(type: .transaction))
    }

    private func categoriesFitWithinRemaining(accountId: String) -> Bool {
        let account = self.getAccount(id: accountId)
        // getRemaining already subtracts the fixed-amount categories on the main transaction account.
        let fixedCeilings = account.type == .transaction && account.main ? 0 : self.getFixedCeilings(accountId: accountId)
        let remaining = self.getRemaining(accountId: accountId)
        return remaining >= 0 && fixedCeilings + self.getCustomCeilings(accountId: accountId) <= remaining
    }
}
