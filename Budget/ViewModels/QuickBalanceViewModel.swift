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
    let lastUpdatePrefix: String = "LastUpdate:"
    
    func getQuickBalance(budgetAccountId: String) -> Double {
        return self.userDefaults.double(forKey: self.quickBalancePrefix + budgetAccountId)
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
            let balance = Utility.convertToDouble(quickBalanceResponse.balance) ?? 0
            self.userDefaults.setValue(balance, forKey: self.quickBalancePrefix + quickBalanceAccounts[index].budgetAccountId)
            let dateString = Utility.dateToString(date: Date.now, size: .short)
            self.userDefaults.setValue(dateString, forKey: self.lastUpdatePrefix + quickBalanceAccounts[index].budgetAccountId)
            print("Successfully set quickBalance for \(quickBalanceAccounts[index].name) in fetchQuickBalanceFromApi in QuickBalanceViewModel")
            
            // Fetch next quick balance
            self.fetchQuickBalanceFromApi(index: index + 1, quickBalanceAccounts: quickBalanceAccounts, completion: completion)
        }
    }
    
    func fetchQuickBalanceFromApi(quickBalanceAccount: QuickBalanceAccount, completion: @escaping (Error?) -> Void) {
        self.fetchQuickBalanceFromApi(quickBalanceAccounts: [quickBalanceAccount], completion: completion)
    }
}
