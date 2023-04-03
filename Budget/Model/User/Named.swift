//
//  Named.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2022-12-20.
//

import Foundation

protocol Named: Identifiable {
    var id: String { get }
    var name: String { get }
    var phone: String { get }
}
