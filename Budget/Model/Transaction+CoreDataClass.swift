//
//  Transaction+CoreDataClass.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2022-04-13.
//
//

import Foundation
import CoreData

@objc(Transaction)
public class Transaction: NSManagedObject {
    func getImageName() -> String {
        return self.type == .income ? "arrow.right" : "arrow.left"
    }
}
