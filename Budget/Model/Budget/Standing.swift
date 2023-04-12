//
//  Standing.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2023-03-18.
//

import Foundation
import FirebaseFirestoreSwift

struct Standing: Codable {
    @DocumentID var documentId: String?
    var userIds: [String]
    var amounts: [String: Double]
    
    init(userIds: [String], amounts: [String: Double]) {
        self.userIds = userIds
        self.amounts = amounts
    }
    
    init(userId1: String, userId2: String, amount1: Double = 0, amount2: Double = 0) {
        self.userIds = [userId1, userId2]
        self.amounts = [userId1: amount1, userId2: amount2]
    }
    
    static func getDummyStanding() -> Standing {
        return Standing(userIds: [], amounts: .init())
    }
    
    func getStanding(myId: String) -> Double {
        for id in self.userIds {
            if id != myId {
                return (self.amounts[myId] ?? 0) - (self.amounts[id] ?? 0)
            }
        }
        return 0
    }
}
