//
//  TransactionEnums.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2022-04-13.
//

import Foundation
import SwiftUI

@objc
public enum TransactionType: Int16, CaseIterable {
    case expense
    case income
    case saving
    
    func description() -> LocalizedStringKey {
        switch self {
        case .expense:
            return "expense"
        case .income:
            return "income"
        case .saving:
            return "saving"
        }
    }
}