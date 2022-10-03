//
//  TransactionCategory+CoreDataProperties.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2022-04-15.
//
//

import Foundation
import CoreData


extension TransactionCategory2 {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<TransactionCategory2> {
        return NSFetchRequest<TransactionCategory2>(entityName: "TransactionCategory2")
    }

    @NSManaged public var name: String?
    @NSManaged public var id: UUID?
    @NSManaged public var type: TransactionType
    @NSManaged public var useSavingsAccount: Bool
    @NSManaged public var useBuffer: Bool

}

extension TransactionCategory2 : Identifiable {

}
