//
//  QuickBalanceViewModel.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2023-03-25.
//

import Foundation

class QuickBalanceViewModel: ObservableObject {
    let userDefaults: UserDefaults = .init(suiteName: "com.samuelivarsson.Budget") ?? .init()
    let quickBalancePrefix: String = "QuickBalance:"
    let rawQuickBalancePrefix: String = "RawQuickBalance:"
    let lastUpdatePrefix: String = "LastUpdate:"
    let currencyPrefix: String = "Currency:"
    let expirationMessagePrefix: String = "ExpirationMessage:"
    let expirationDatePrefix: String = "ExpirationDate:"
    
    func getQuickBalance(budgetAccountId: String) -> Double {
        return self.userDefaults.double(forKey: self.quickBalancePrefix + budgetAccountId)
    }
    
    func getRawQuickBalance(budgetAccountId: String) -> String {
        return self.userDefaults.string(forKey: self.rawQuickBalancePrefix + budgetAccountId) ?? "BudgetAppError404"
    }
    
    func getLastUpdate(budgetAccountId: String) -> String {
        return self.userDefaults.string(forKey: self.lastUpdatePrefix + budgetAccountId) ?? ""
    }
    
    func getCurrency(budgetAccountId: String) -> String {
        return self.userDefaults.string(forKey: self.currencyPrefix + budgetAccountId) ?? ""
    }
    
    func getExpirationMessage(budgetAccountId: String) -> String {
        return self.userDefaults.string(forKey: self.expirationMessagePrefix + budgetAccountId) ?? ""
    }
    
    func getExpirationDate(budgetAccountId: String) -> String {
        return self.userDefaults.string(forKey: self.expirationDatePrefix + budgetAccountId) ?? ""
    }
    
    func fetchQuickBalanceFromApi(index: Int = 0, quickBalanceAccounts: [QuickBalanceAccount], completion: @escaping (Error?) -> Void) {
        if quickBalanceAccounts.isEmpty {
            completion(nil)
            return
        }
        
        guard index < quickBalanceAccounts.count else {
            // We've processed all the accounts
            completion(nil)
            return
        }
        
        let budgetAccountId = quickBalanceAccounts[index].budgetAccountId
        if let lastUpdate: Date = Utility.stringToDate(string: self.getLastUpdate(budgetAccountId: budgetAccountId), style: .short, timeStyle: .medium) {
            if abs(lastUpdate.timeIntervalSinceNow) < 10 {
                completion(UserError.lessThanTenSeconds)
                return
            }
        }
        
        let dateString = Utility.dateToString(date: Date.now, style: .short, timeStyle: .medium)
        self.userDefaults.setValue(dateString, forKey: self.lastUpdatePrefix + budgetAccountId)
        
        MobileBankID.quickBalance(subscriptionId: quickBalanceAccounts[index].subscriptionId) { quickBalanceResponse, error in
            if let error = error {
                completion(error)
                return
            }
            
            guard let quickBalanceResponse = quickBalanceResponse else {
                let info = "Found nil when extracting quickBalanceResponse in fetchQuickBalanceFromApi in QuickBalanceViewModel"
                completion(ApplicationError.unexpectedNil(info))
                return
            }
            
            // Success
            self.userDefaults.setValue(quickBalanceResponse.balance, forKey: self.rawQuickBalancePrefix + budgetAccountId)
            let balance = Utility.convertToDouble(quickBalanceResponse.balance) ?? 0
            self.userDefaults.setValue(balance, forKey: self.quickBalancePrefix + budgetAccountId)
            self.userDefaults.setValue(quickBalanceResponse.currency, forKey: self.currencyPrefix + budgetAccountId)
            self.userDefaults.setValue(quickBalanceResponse.expirationMessage, forKey: self.expirationMessagePrefix + budgetAccountId)
            self.userDefaults.setValue(quickBalanceResponse.expirationDate, forKey: self.expirationDatePrefix + budgetAccountId)
            print("Successfully set quickBalance for \(quickBalanceAccounts[index].name) in fetchQuickBalanceFromApi in QuickBalanceViewModel")
            
            // Fetch next quick balance
            self.fetchQuickBalanceFromApi(index: index + 1, quickBalanceAccounts: quickBalanceAccounts, completion: completion)
        }
    }
    
    func fetchQuickBalanceFromApi(quickBalanceAccount: QuickBalanceAccount, completion: @escaping (Error?) -> Void) {
        self.fetchQuickBalanceFromApi(quickBalanceAccounts: [quickBalanceAccount], completion: completion)
    }
}
