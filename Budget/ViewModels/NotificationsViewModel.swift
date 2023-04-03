//
//  NotificationsViewModel.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2022-10-24.
//

import Firebase
import FirebaseFirestore
import Foundation

class NotificationsViewModel: ObservableObject {
    @Published var notifications: [Notification] = .init()
    
    private var db = Firestore.firestore()
    
    var listener: ListenerRegistration?
    
    func fetchData(completion: @escaping (Error?) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {
            let info = "Found nil when extracting uid in fetchData in NotificationsViewModel"
            print(info)
            completion(ApplicationError.unexpectedNil(info))
            return
        }
        
        // Remove old listener
        Utility.removeListener(listener: self.listener)
        // Add new listener
        self.listener = self.db.collection("Notifications").whereField("to", isEqualTo: uid).order(by: "date", descending: true).addSnapshotListener { querySnapshot, error in
            if let error = error {
                completion(error)
                return
            }
            guard let documents = querySnapshot?.documents else {
                completion(FirestoreError.documentNotExist)
                return
            }
            
            // Succes
            self.notifications = documents.compactMap { queryDocumentSnapshot in
                do {
                    return try queryDocumentSnapshot.data(as: Notification.self)
                } catch {
                    print("Error in do block in fetchData in NotificationsViewModel")
                    return nil
                }
            }
            self.addListener()
            print("Successfully set notifications in NotificationsViewModel")
            completion(nil)
        }
    }
    
    func addListener() {
        if let listener = self.listener {
            Utility.listeners.append(listener)
        }
    }
    
    func getNumberOfUnreadNotifications() -> Int {
        return self.notifications.filter { !$0.read }.count
    }
    
    func setNotificationAsRead(notification: Notification, completion: @escaping (Error?) -> Void) {
        guard let notificationId = notification.documentId else {
            let info = "Found nil when extracting notificationId in setNotificationAsRead in NotificationsViewModel"
            completion(ApplicationError.unexpectedNil(info))
            return
        }
        
        self.db.collection("Notifications").document(notificationId).updateData(["read": true]) { error in
            if let error = error {
                completion(error)
                return
            }
            
            // Success
            print("Successfully set notification as read")
            completion(nil)
        }
    }
    
    func setNotificationAsUnRead(notification: Notification, completion: @escaping (Error?) -> Void) {
        guard let notificationId = notification.documentId else {
            let info = "Found nil when extracting notificationId in setNotificationAsUnRead in NotificationsViewModel"
            completion(ApplicationError.unexpectedNil(info))
            return
        }
        
        self.db.collection("Notifications").document(notificationId).updateData(["read": false]) { error in
            if let error = error {
                completion(error)
                return
            }
            
            // Success
            print("Successfully set notification as unread")
            completion(nil)
        }
    }
    
    func setAllNotificationsAsRead(completion: @escaping (Error?) -> Void) {
        let batch = self.db.batch()
        
        let unReadNotifications = self.notifications.filter { !$0.read }
        for notification in unReadNotifications {
            guard let notificationId = notification.documentId else {
                let info = "Found nil when extracting notificationId in setAllNotificationsAsRead in NotificationsViewModel"
                print(info)
                completion(ApplicationError.unexpectedNil(info))
                return
            }
            let notificationRef = self.db.collection("Notifications").document(notificationId)
            batch.updateData(["read": true], forDocument: notificationRef)
        }
        batch.commit { error in
            if let error = error {
                completion(error)
                return
            }
            
            // Success
            completion(nil)
        }
    }
    
    func sendFriendRequest(from: User, to: String, completion: @escaping (Error?) -> Void) {
        let notification = Notification(type: .friendRequest, from: from.id, fromName: from.name, to: to)
        
        do {
            let _ = try self.db.collection("Notifications").addDocument(from: notification) { error in
                if let error = error {
                    completion(error)
                    return
                }
                
                // Success
                completion(nil)
                print("Notification sent in NotificationsViewModel")
            }
        } catch {
            print("Error in do block in sendFriendRequest in NotificationsViewModel")
            completion(error)
        }
    }
    
    func acceptFriendRequest(notification: Notification, myName: String, completion: @escaping (Error?) -> Void) {
        guard let notificationId = notification.documentId else {
            let info = "Found nil when extracting notificationId in acceptFriendRequest in NotificationsViewModel"
            print(info)
            completion(ApplicationError.unexpectedNil(info))
            return
        }
        
        let data: [String: Any] = ["read": true, "type": NotificationType.friendRequestAccepted.rawValue]
        self.db.collection("Notifications").document(notificationId).updateData(data) { error in
            if let error = error {
                completion(error)
                return
            }
            
            // Success
            print("Successfully accepted friend request in NotificationsViewModel")
            let newNotification = Notification(type: .friendRequestAccepted, from: notification.to, fromName: myName, to: notification.from)
            do {
                try self.db.collection("Notifications").addDocument(from: newNotification) { error in
                    if let error = error {
                        completion(error)
                        return
                    }
                    
                    // Success
                    completion(nil)
                    print("Successfully sent accepted notice in NotificationsViewModel")
                }
            } catch {
                print("Error in do block in acceptFriendRequest in NotificationsViewModel")
                completion(error)
            }
        }
    }
    
    func denyFriendRequest(notification: Notification, completion: @escaping (Error?) -> Void) {
        guard let notificationId = notification.documentId else {
            let info = "Found nil when extracting notificationId in acceptFriendRequest in NotificationsViewModel"
            print(info)
            completion(ApplicationError.unexpectedNil(info))
            return
        }
        
        let data: [String: Any] = ["read": true, "type": NotificationType.friendRequestDenied.rawValue]
        self.db.collection("Notifications").document(notificationId).updateData(data) { error in
            if let error = error {
                completion(error)
                return
            }
            
            // Success
            print("Successfully denied friend request in NotificationsViewModel")
            completion(nil)
        }
    }
    
    func cancelFriendRequest(friendId to: String, completion: @escaping (Error?) -> Void) {
        guard let from = Auth.auth().currentUser?.uid else {
            let info = "Found nil when extracting uid in fetchData in NotificationsViewModel"
            print(info)
            completion(ApplicationError.unexpectedNil(info))
            return
        }
        self.db.collection("Notifications").whereField("from", isEqualTo: from).getDocuments { snapshot, error in
            if let error = error {
                completion(error)
                return
            }
            
            // Success
            guard let documents = snapshot?.documents else {
                let info = "Found nil when extracting documents in cancelFriendRequest in NotificationsViewModel"
                print(info)
                completion(ApplicationError.unexpectedNil(info))
                return
            }
            
            let notifications = documents.compactMap { queryDocumentSnapshot in
                try? queryDocumentSnapshot.data(as: Notification.self)
            }
            
            let notification = notifications.first { $0.from == from && $0.to == to && $0.type == .friendRequest }
            guard let notification = notification else {
                let info = "Found nil when extracting notification in cancelFriendRequest in NotificationsViewModel"
                print(info)
                completion(ApplicationError.unexpectedNil(info))
                return
            }
            guard let docId = notification.documentId else {
                let info = "Found nil when extracting docId in cancelFriendRequest in NotificationsViewModel"
                print(info)
                completion(ApplicationError.unexpectedNil(info))
                return
            }

            self.db.collection("Notifications").document(docId).delete(completion: completion)
        }
    }
    
    func hasUserSentRequest(uid: String) -> (Notification?, Bool) {
        for notification in self.notifications {
            if notification.type == .friendRequest && notification.from == uid {
                return (notification, true)
            }
        }
        return (nil, false)
    }
    
    func sendTransactionNotifications(me: User, transaction: Transaction, edit: Bool = false, completion: @escaping (Error?) -> Void) {
        let batch = self.db.batch()
        for participant in transaction.participants {
            if participant.userId == me.id {
                continue
            }
            let type: NotificationType = edit ? .transactionEdit : .transaction
            let notification = Notification(type: type, from: me.id, fromName: me.name, to: participant.userId, desc: transaction.desc)
            let document = self.db.collection("Notifications").document()
            do {
                try batch.setData(from: notification, forDocument: document)
            } catch {
                completion(error)
            }
        }
        batch.commit(completion: completion)
    }
    
    func addNotification(notification: Notification, completion: @escaping (Error?) -> Void) {
        do {
            try self.db.collection("Notifications").addDocument(from: notification, completion: completion)
        } catch {
            completion(error)
        }
    }
    
    func sendReminder(me: User, friendId: String, completion: @escaping (Error?) -> Void) {
        let notification = Notification(type: .swishReminder, from: me.id, fromName: me.name, to: friendId)
        self.addNotification(notification: notification, completion: completion)
    }
    
    func sendSquaredUpNotification(me: User, friendId: String, completion: @escaping (Error?) -> Void) {
        let notification = Notification(type: .squaredUp, from: me.id, fromName: me.name, to: friendId)
        self.addNotification(notification: notification, completion: completion)
    }
}
