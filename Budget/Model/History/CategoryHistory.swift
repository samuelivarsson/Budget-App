//
//  CategoryHistory.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2023-03-22.
//

import Foundation
import FirebaseFirestoreSwift

struct CategoryHistory: Codable {
    var categoryId: String
    var categoryName: String
    var totalAmount: Double
    var saveDate: Date
    var userId: String
    /// The category's type at save time. Optional for backward-compatibility with
    /// documents saved before this field existed (decodes to nil, then we fall
    /// back to looking the category up by id in the current budget).
    var categoryType: TransactionType? = nil
}
