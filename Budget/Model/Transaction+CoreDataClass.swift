//
//  Transaction+CoreDataClass.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2022-04-14.
//
//

import Foundation
import CoreData

@objc(Transaction)
public class Transaction: NSManagedObject {
    func getImageName() -> String {
        switch type {
        case .expense:
            return "minus.circle.fill"
        case .income:
            return "plus.circle.fill"
        case .saving:
            return "circle.circle"
        }
    }
}
