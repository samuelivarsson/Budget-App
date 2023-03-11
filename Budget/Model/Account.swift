//
//  Account.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2023-03-04.
//

import Foundation

struct Account: Identifiable, Codable, Hashable {
    var id: String = UUID().uuidString
    var name: String
    var type: AccountType
    var main: Bool = false
}
