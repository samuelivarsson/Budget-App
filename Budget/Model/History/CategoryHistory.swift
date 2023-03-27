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
}
