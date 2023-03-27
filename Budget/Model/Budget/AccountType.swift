//
//  AccountType.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2023-03-04.
//

import Foundation
import SwiftUI

enum AccountType: Int16, CaseIterable, Codable {
    case transaction
    case saving
    case overhead
    
    func description() -> LocalizedStringKey {
        switch self {
        case .transaction:
            return "transaction"
        case .saving:
            return "saving"
        case .overhead:
            return "overhead"
        }
    }
}
