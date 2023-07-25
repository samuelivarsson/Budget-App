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
    var userNames: [String: String]
    var phoneNumbers: [String: String]
    
    init(userIds: [String], amounts: [String: Double], userNames: [String: String], phoneNumbers: [String: String]) {
        self.userIds = userIds
        self.amounts = amounts
        self.userNames = userNames
        self.phoneNumbers = phoneNumbers
    }
    
    init(userId1: String, userId2: String, amount1: Double = 0, amount2: Double = 0, userName1: String, userName2: String, phoneNumber1: String, phoneNumber2: String) {
        self.userIds = [userId1, userId2]
        self.amounts = [userId1: amount1, userId2: amount2]
        self.userNames = [userId1: userName1, userId2: userName2]
        self.phoneNumbers = [userId1: phoneNumber1, userId2: phoneNumber2]
    }
    
    static func getDummyStanding() -> Standing {
        return Standing(userIds: [], amounts: .init(), userNames: .init(), phoneNumbers: .init())
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
