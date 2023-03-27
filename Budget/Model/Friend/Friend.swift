//
//  Friend.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2022-10-24.
//

import Foundation
import Firebase
import FirebaseFirestoreSwift

struct Friend: Identifiable, Codable, Hashable {
    var id = UUID().uuidString
    var documentReference: DocumentReference
    var favourite: Bool = false
    var status: FriendStatus = .requested
}
