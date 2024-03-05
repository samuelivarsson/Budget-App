//
//  UserRole.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2024-03-05.
//

import SwiftUI
import Foundation

enum UserRole: Int16, CaseIterable, Codable, Hashable {
    case user
    case superAdmin
}
