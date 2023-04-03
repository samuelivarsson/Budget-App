//
//  BudgetApp.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2022-04-13.
//

import SwiftUI
import Firebase
import FirebaseMessaging
import UserNotifications

@main
struct BudgetApp: App {
    @StateObject var authViewModel = AuthViewModel()
    @StateObject var fsViewModel = FirestoreViewModel()
    @StateObject var friendsViewModel = FriendsViewModel()
    @StateObject var storageViewModel = StorageViewModel()
    @StateObject var userViewModel = UserViewModel()
    @StateObject var transactionsViewModel = TransactionsViewModel()
    @StateObject var notificationsViewModel = NotificationsViewModel()
    @StateObject var standingsViewModel = StandingsViewModel()
    @StateObject var historyViewModel = HistoryViewModel()
    @StateObject var quickBalanceViewModel = QuickBalanceViewModel()

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
                .environmentObject(standingsViewModel)
                .environmentObject(historyViewModel)
                .environmentObject(quickBalanceViewModel)
        }
    }
}

extension BudgetApp {
    private func setUpFirebase() {
        FirebaseApp.configure()
    }
}
