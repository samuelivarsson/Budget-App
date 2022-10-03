//
//  User.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2022-05-11.
//

import Foundation
import Firebase
import FirebaseFirestoreSwift

struct User: Identifiable, Codable {
    @DocumentID var id: String? = UUID().uuidString
    var name: String
    var email: String
    var phone: String
    var friends: [DocumentReference]
    var transactionCategories: [TransactionCategory]?
    var uid: String
}
