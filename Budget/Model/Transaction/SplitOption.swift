//
//  SplitOption.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2023-12-23.
//

import Foundation
import SwiftUI

enum SplitOption: Int16, CaseIterable, Codable {
    case standard = 0
    case meEverything = 2
    case ownItems = 3
    
    func description() -> LocalizedStringKey {
        switch self {
        case .standard:
            return "standard"
        case .meEverything:
            return "meEverything"
        case .ownItems:
            return "ownItems"
        }
    }
}

