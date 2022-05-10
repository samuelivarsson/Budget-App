//
//  Transaction+CoreDataProperties.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2022-04-14.
//
//

import Foundation
import CoreData


extension Transaction {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Transaction> {
        return NSFetchRequest<Transaction>(entityName: "Transaction")
    }

    @NSManaged public var amount: Double
    @NSManaged public var category: String?
    @NSManaged public var date: Date?
    @NSManaged public var id: UUID?
    @NSManaged public var desc: String?
    @NSManaged public var creator: String?
    @NSManaged public var type: TransactionType

}

extension Transaction : Identifiable {

}
