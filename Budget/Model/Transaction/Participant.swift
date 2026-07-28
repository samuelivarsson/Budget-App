//
//  Participant.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2022-12-21.
//

import Foundation

struct Participant: Identifiable, Codable, Equatable {
    var id: String = UUID().uuidString
    var amount: Double = 0
    var userId: String
    var userName: String
    /// This participant's own category for the transaction. `nil` for older
    /// entries and for participants who haven't overridden the creator's choice;
    /// in that case the creator's category (resolved by name) is used as default.
    var category: TransactionCategory? = nil
    /// Amount this participant bought only for themselves (the "Egna köp" split).
    /// Deducted from the total before the rest is split equally. `nil` = 0 (older entries).
    var ownAmount: Double? = nil

    // Equatable is synthesized over ALL fields (including `category` and
    // `ownAmount`). A previous hand-written `==` compared only `id` + `amount`,
    // which made SwiftUI's field-by-field view diffing treat a category-only
    // change as "no change" — so an edited category didn't refresh the list row
    // or the picker until the app was restarted (a full refetch).
}
