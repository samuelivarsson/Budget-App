//
//  QuickBalanceSubscriptionResponse.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2023-03-25.
//

import Foundation

struct QuickBalanceSubscriptionResponse: Codable {
    var subscriptionId: String
    
    init(data: [String: Any]) {
        self.subscriptionId = data["subscriptionId"] as? String ?? ""
    }
}
