//
//  TransactionEnums.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2022-04-13.
//

import Foundation
import SwiftUI

public enum TransactionType: Int16, CaseIterable, Codable {
    case expense = 0
    case income = 1
    // Historically named "saving"; now a generic transfer (money that both leaves
    // one account and enters another). Raw value kept at 2 for DB compatibility.
    case transfer = 2

    func description() -> LocalizedStringKey {
        switch self {
        case .expense:
            return "expense"
        case .income:
            return "income"
        case .transfer:
            return "transfer"
        }
    }
}
