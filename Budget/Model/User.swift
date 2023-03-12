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
    var budget: Budget = Budget.getDefault()
    var friends: [Friend]
    var customFriends: [CustomFriend] = []
    var transactionCategories: [TransactionCategory] = []
    var keywordsForLookup: [String] {
        [self.name.generateStringSequence(), self.name.split(separator: " ").map { String($0).generateStringSequence() }.flatMap { $0 }].flatMap { $0 }
    }
    
    static func getDefault() -> User {
        return User(id: "", documentId: "", name: "", email: "", phone: "", budget: Budget.getDefault(), friends: [], customFriends: [], transactionCategories: [])
    }
}

extension String {
    func generateStringSequence() -> [String] {
        /// E.g) "S", "Sa", "Sam" etc.
        guard self.count > 0 else { return [] }
        var sequences: [String] = []
        for i in 1 ... self.count {
            sequences.append(String(self.prefix(i)))
        }
        return sequences
    }
}
