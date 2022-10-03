//
//  Transaction+CoreDataClass.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2022-04-14.
//
//

import Foundation
import CoreData

@objc(Transaction2)
public class Transaction2: NSManagedObject {
    func getImageName() -> String {
        switch type {
        case .expense:
            return "arrow.down.square.fill"
        case .income:
            return "arrow.up.square.fill"
        case .saving:
            return "circle.circle"
        }
    }
}
