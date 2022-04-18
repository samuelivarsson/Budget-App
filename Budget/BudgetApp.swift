//
//  BudgetApp.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2022-04-13.
//

import SwiftUI
import Firebase

@main
struct BudgetApp: App {
    let persistenceController = PersistenceController.shared
    @StateObject var viewModel = AuthViewModel()

    init() {
        setUpFirebase()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(viewModel)
                .withErrorHandling()
        }
    }
}

extension BudgetApp {
    private func setUpFirebase() {
        FirebaseApp.configure()
    }
}
