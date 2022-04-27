//
//  Persistence.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2022-04-13.
//

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        for i in 0..<10 {
            let newTransaction = Transaction(context: viewContext)
            newTransaction.id = UUID()
            newTransaction.type = .expense
            newTransaction.date = Date()
            newTransaction.amount = 24.2
            newTransaction.desc = "Test"
            newTransaction.category = "fika"
            
            let newFriend = Friend(context: viewContext)
            newFriend.id = UUID()
            newFriend.name = "Friend \(i)"
            newFriend.phone = "070123010\(i)"
        }
        do {
            try viewContext.save()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "Budget")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                 /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                ErrorHandling().handle(error: error)
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}
