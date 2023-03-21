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
    var monthStartsOn: Int
    var budget: Budget = Budget.getDummyBudget()
    var friends: [Friend]
    var customFriends: [CustomFriend] = []
    var keywordsForLookup: [String] {
        [self.name.generateStringSequence(), self.name.split(separator: " ").map { String($0).generateStringSequence() }.flatMap { $0 }].flatMap { $0 }
    }
    
    static func getDummyUser(id: String = "", name: String = "", email: String = "") -> User {
        return User(id: id, documentId: "", name: name, email: email, phone: "", monthStartsOn: 25, budget: Budget.getDummyBudget(), friends: [], customFriends: [])
    }
}
// TODO: - Move monthStartsOn to Budget (fix getBalance when doing this)

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
