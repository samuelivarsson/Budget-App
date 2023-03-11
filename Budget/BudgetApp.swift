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
    @StateObject var authViewModel = AuthViewModel()
    @StateObject var fsViewModel = FirestoreViewModel()
    @StateObject var friendsViewModel = FriendsViewModel()
    @StateObject var storageViewModel = StorageViewModel()
    @StateObject var userViewModel = UserViewModel()
    @StateObject var transactionsViewModel = TransactionsViewModel()
    @StateObject var notificationsViewModel = NotificationsViewModel()

    init() {
        setUpFirebase()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .withErrorHandling()
                .environmentObject(authViewModel)
                .environmentObject(fsViewModel)
                .environmentObject(friendsViewModel)
                .environmentObject(storageViewModel)
                .environmentObject(userViewModel)
                .environmentObject(transactionsViewModel)
                .environmentObject(notificationsViewModel)
        }
    }
}

extension BudgetApp {
    private func setUpFirebase() {
        FirebaseApp.configure()
    }
}
