//
//  customFriend.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2022-10-06.
//

import Foundation

struct CustomFriend: Identifiable, Codable, Hashable, Named {
    var id: String = UUID().uuidString
    var name: String
    var phone: String
    var group: String = ""
    var favourite: Bool = false
}
