//
//  QuickBalanceAccountsResponse.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2023-03-25.
//

import Foundation

struct QuickBalanceAccountsResponse: Codable, Hashable {
    var accounts: [QuickBalanceAccountResponse]
    
    init(data: [String: Any]) {
        var quickBalanceAccounts: [QuickBalanceAccountResponse] = .init()
        let accounts = data["accounts"] as? [[String: Any]] ?? .init()
        for account in accounts {
            quickBalanceAccounts.append(QuickBalanceAccountResponse(data: account))
        }
        self.accounts = quickBalanceAccounts
    }
    
    static func getDummyResponse() -> QuickBalanceAccountsResponse {
        QuickBalanceAccountsResponse(data: ["accounts": [] as [Any]])
    }
    
    struct QuickBalanceAccountResponse: Codable, Hashable {
        var name: String
        var quickBalanceSubscription: QuickBalanceSubscription
        
        init(data: [String: Any]) {
            self.name = data["name"] as? String ?? ""
            self.quickBalanceSubscription = QuickBalanceSubscription(data: data["quickbalanceSubscription"] as? [String: Any] ?? .init())
        }
        
        static func getDummyResponse() -> QuickBalanceAccountResponse {
            QuickBalanceAccountResponse(data: ["name": "", "quickbalanceSubscription": QuickBalanceSubscription.getDummySubscription()])
        }
        
        struct QuickBalanceSubscription: Codable, Hashable {
            var active: Bool
            var id: String
            
            init(data: [String: Any]) {
                let active = data["active"] as? Int ?? 0
                self.active = active == 1
                self.id = data["id"] as? String ?? ""
            }
            
            static func getDummySubscription() -> QuickBalanceSubscription {
                QuickBalanceSubscription(data: ["active": 0, "id": ""])
            }
        }
    }
}
