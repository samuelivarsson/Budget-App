//
//  QuickBalanceErrorResponse.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2023-03-26.
//

import Foundation

struct QuickBalanceErrorResponse: Codable {
    var errorMessages: QuickBalanceErrorMessage
    
    init(data: [String: Any]) {
        self.errorMessages = QuickBalanceErrorMessage(data: data["errorMessages"] as? [String: Any] ?? .init())
    }
    
    struct QuickBalanceErrorMessage: Codable {
        var generals: QuickBalanceErrorMessageGeneral
        
        init(data: [String: Any]) {
            let generalsData = data["general"] as? [[String: Any]] ?? .init()
            self.generals = QuickBalanceErrorMessageGeneral(data: generalsData.first ?? .init())
        }
        
        struct QuickBalanceErrorMessageGeneral: Codable {
            var code: String
            var message: String
            
            init(data: [String: Any]) {
                self.code = data["code"] as? String ?? ""
                self.message = data["message"] as? String ?? ""
            }
        }
    }
}
