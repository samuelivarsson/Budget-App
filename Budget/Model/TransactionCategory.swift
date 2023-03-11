//
//  TransactionCategory.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2022-10-01.
//

import Foundation
import Firebase

struct TransactionCategory: Identifiable, Codable, Hashable {
    var id = UUID().uuidString
    var name: String
    var type: TransactionType
    var useSavingsAccount: Bool
    var useBuffer: Bool
}
