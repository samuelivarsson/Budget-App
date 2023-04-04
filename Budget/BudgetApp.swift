//
//  BudgetApp.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2022-04-13.
//

import Firebase
import FirebaseMessaging
import SwiftUI
import UserNotifications

@main
struct BudgetApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
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

class AppDelegate: NSObject, UIApplicationDelegate {
    let gcmMessageIDKey = "gcm.message_id"
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        // Setting up Cloud Messaging
        Messaging.messaging().delegate = self

        // Setting up Notifications
        UNUserNotificationCenter.current().delegate = self

        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(
            options: authOptions,
            completionHandler: { _, _ in }
        )

        application.registerForRemoteNotifications()

        return true
    }
    
    func application(_ application: UIApplication,
                     didReceiveRemoteNotification userInfo: [AnyHashable: Any]) async
      -> UIBackgroundFetchResult {
      // If you are receiving a notification message while your app is in the background,
      // this callback will not be fired till the user taps on the notification launching the application.
      // TODO: Handle data of notification

      // With swizzling disabled you must let Messaging know about the message, for Analytics
      // Messaging.messaging().appDidReceiveMessage(userInfo)

      // Print message ID.
      if let messageID = userInfo[gcmMessageIDKey] {
        print("Message ID: \(messageID)")
      }

      // Print full message.
      print(userInfo)

      return UIBackgroundFetchResult.newData
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }
}

// Cloud Messaging
extension AppDelegate: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        // Store token in Firestore for sending Notifications from server in future
        guard let currentUser = Auth.auth().currentUser else {
            let info = "Found nil when extracting currentUser in messaging in AppDelegate"
            print(ApplicationError.unexpectedNil(info).localizedDescription)
            return
        }
        
        let db = Firestore.firestore()
        db.collection("Users").document(currentUser.uid).setData(["deviceToken": fcmToken ?? ""], merge: true) { error in
            if let error = error {
                print(error.localizedDescription)
                return
            }
            
            // Success
            print("Successfully set deviceToken in messaging in AppDelegate")
        }
    }
}

// User Notifications
extension AppDelegate: UNUserNotificationCenterDelegate {
    // Receive displayed notifications for iOS 10 devices.
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        let userInfo = notification.request.content.userInfo

        // With swizzling disabled you must let Messaging know about the message, for Analytics
        // Messaging.messaging().appDidReceiveMessage(userInfo)

        // ...

        // Print full message.
        print(userInfo)

        // Change this to your preferred presentation option
        return [[.banner, .badge, .sound]]
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        let userInfo = response.notification.request.content.userInfo

        // ...

        // With swizzling disabled you must let Messaging know about the message, for Analytics
        // Messaging.messaging().appDidReceiveMessage(userInfo)

        // Print full message.
        print(userInfo)
    }
}
