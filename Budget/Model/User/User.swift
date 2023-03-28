//
//  User.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2022-05-11.
//

import Firebase
import FirebaseFirestoreSwift
import Foundation

struct User: Identifiable, Codable, Hashable, Named {
    var id: String
    @DocumentID var documentId: String?
    var name: String
    var email: String
    var phone: String
    var budget: Budget = Budget.getDummyBudget()
    var friends: [Friend]
    var customFriends: [CustomFriend] = []
    var quickBalanceAccounts: [QuickBalanceAccount] = []
    var lastSaveDate: Date = Date.now
    var keywordsForLookup: [String] {
        [self.name.generateStringSequence(), self.name.split(separator: " ").map { String($0).generateStringSequence() }.flatMap { $0 }].flatMap { $0 }
    }
    
    static func getDummyUser(id: String = "", name: String = "", email: String = "") -> User {
        return User(id: id, name: name, email: email, phone: "", budget: Budget.getDummyBudget(), friends: [], customFriends: [])
    }
}
