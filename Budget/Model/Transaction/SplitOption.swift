//
//  SplitOption.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2023-12-23.
//

import Foundation
import SwiftUI

enum SplitOption: Int16, CaseIterable, Codable {
    case splitEvenly = 1
    case meSmallShare
    case meEverything
    case percentage
    case manual = 0
    
    func description() -> LocalizedStringKey {
        switch self {
        case .splitEvenly:
            return "splitEvenly"
        case .meSmallShare:
            return "meSmallShare"
        case .meEverything:
            return "meEverything"
        case .percentage:
            return "percentage"
        case .manual:
            return "manual"
        }
    }
}

