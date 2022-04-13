//
//  Transaction+CoreDataProperties.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2022-04-13.
//
//

import Foundation
import CoreData


extension Transaction {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Transaction> {
        return NSFetchRequest<Transaction>(entityName: "Transaction")
    }

    @NSManaged public var type: TransactionType
    @NSManaged public var date: Date?
    @NSManaged public var amount: Double
    @NSManaged public var info: String?
    @NSManaged public var category: TransactionCategory
    @NSManaged public var id: UUID?

}

extension Transaction : Identifiable {

}
