//
//  User.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2022-05-11.
//

import Firebase
import FirebaseFirestoreSwift
import Foundation
import SwiftUI

struct User: Identifiable, Hashable, Named, Codable {
    var id: String 
    @DocumentID var documentId: String?
    var name: String
    var email: String
    var phone: String
    var budget: Budget = Budget.getDummyBudget()
    var friends: [Friend] = []
    var customFriends: [CustomFriend] = []
    var quickBalanceAccounts: [QuickBalanceAccount] = []
    var deviceToken: String = ""
    var lastSaveDate: Date = Date.now
    var keywordsForLookup: [String] {
        [self.name.generateStringSequence(), self.name.split(separator: " ").map { String($0).generateStringSequence() }.flatMap { $0 }].flatMap { $0 }
    }
    var role: UserRole
    
    enum CodingKeys: String, CodingKey {
        case id
        case documentId
        case name
        case email
        case phone
        case budget
        case friends
        case customFriends
        case quickBalanceAccounts
        case deviceToken
        case lastSaveDate
        case role
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        _documentId = try container.decode(DocumentID<String>.self, forKey: .documentId)
        name = try container.decode(String.self, forKey: .name)
        email = try container.decode(String.self, forKey: .email)
        phone = try container.decode(String.self, forKey: .phone)
        budget = try container.decode(Budget.self, forKey: .budget)
        friends = try container.decode([Friend].self, forKey: .friends)
        customFriends = try container.decode([CustomFriend].self, forKey: .customFriends)
        quickBalanceAccounts = try container.decode([QuickBalanceAccount].self, forKey: .quickBalanceAccounts)
        deviceToken = try container.decode(String.self, forKey: .deviceToken)
        lastSaveDate = try container.decode(Date.self, forKey: .lastSaveDate)
        
        if let userRoleInt = try? container.decode(Int16.self, forKey: .role), let userRole = UserRole(rawValue: userRoleInt) {
            self.role = userRole
        } else {
            role = .user // Default value or other error handling
        }
    }
    
    init(id: String, documentId: String? = nil, name: String, email: String, phone: String, role: UserRole = .user) {
        self.id = id
        self.documentId = documentId
        self.role = role
        self.name = name
        self.email = email
        self.phone = phone
    }
    
    static func getDummyUser(id: String = "", name: String = "", email: String = "") -> User {
        return User(id: id, name: name, email: email, phone: "")
    }
}
