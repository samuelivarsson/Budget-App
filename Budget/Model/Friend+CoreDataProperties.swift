//
//  Friend+CoreDataProperties.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2022-04-20.
//
//

import Foundation
import CoreData


extension Friend {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Friend> {
        return NSFetchRequest<Friend>(entityName: "Friend")
    }

    @NSManaged public var email: String?
    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var phone: String?
    @NSManaged public var uid: String?
    @NSManaged public var custom: Bool
    @NSManaged public var creator: String?

}

extension Friend : Identifiable {

}
