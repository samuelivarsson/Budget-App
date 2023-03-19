//
//  Participant.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2022-12-21.
//

import Foundation

struct Participant: Identifiable, Codable {
    var id: String = UUID().uuidString
    var amount: Double = 0
    var userId: String
    var userName: String
}

extension Participant: Equatable {
    static func == (lhs: Participant, rhs: Participant) -> Bool {
        return lhs.id == rhs.id && lhs.amount == rhs.amount
    }
}
