//
//  PushNotification.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2023-04-04.
//

import Foundation
import OAuth2

struct PushNotification {
    static func getAccessToken(completion: @escaping (Token?, Error?) -> Void) {
        if let url = Bundle.main.url(forResource: "budget-5cc74-firebase-adminsdk-v95r1-4f8acf0ca8", withExtension: "json") {
            let scopes: [String] = ["https://www.googleapis.com/auth/firebase.messaging"]
            let googleCredentials = OAuth2.ServiceAccountTokenProvider(credentialsURL: url, scopes: scopes)
            try? googleCredentials?.withToken(completion)
        }
    }
    
    static func sendNotifications(index: Int = 0, notifications: [Notification], friends: [User], completion: @escaping (Error?) -> Void) {
        if notifications.isEmpty {
            completion(nil)
            return
        }
        
        guard index < notifications.count else {
            // We've processed all the notifications
            completion(nil)
            return
        }
        
        getAccessToken { token, error in
            if let error = error {
                print(error)
                completion(error)
                return
            }
            
            guard let token = token else {
                let info = "Found nil when extracting token in sendNotification in PushNotification"
                completion(ApplicationError.unexpectedNil(info))
                return
            }
            
            guard let accessToken = token.AccessToken else {
                let info = "Found nil when extracting accessToken in sendNotification in PushNotification"
                completion(ApplicationError.unexpectedNil(info))
                return
            }
            
            guard let url = URL(string: "https://fcm.googleapis.com/v1/projects/budget-5cc74/messages:send") else {
                let info = "Found nil when extracting url in sendNotification in PushNotification"
                completion(ApplicationError.unexpectedNil(info))
                return
            }
            
            
            
            let friendId: String = notifications[index].type == .friendRequestDenied ? notifications[index].from : notifications[index].to
            guard let friend = self.getFriendFromId(id: friendId, friends: friends) else {
                print("Friend could not be found in sendNotifications in PushNotifications, might be a custom friend")
                self.sendNotifications(index: index + 1, notifications: notifications, friends: friends, completion: completion)
                return
            }
            
            if friend.deviceToken.isEmpty {
                self.sendNotifications(index: index + 1, notifications: notifications, friends: friends, completion: completion)
                return
            }
            
            var body: String = ""
            switch notifications[index].type {
            case .friendRequest:
                body = "\(notifications[index].fromName) " + "hasSentYouAFriendRequest".localizeString()
            case .friendRequestAccepted:
                body = "\(notifications[index].fromName) " + "hasAcceptedYourFriendRequest".localizeString()
            case .friendRequestDenied:
                body = "\(notifications[index].fromName) " + "hasDeniedYourFriendRequest".localizeString()
            case .transaction:
                body = "\(notifications[index].fromName) " + "hasAddedYouToTheTransaction".localizeString() + " \(notifications[index].desc)"
            case .transactionEdit:
                body = "\(notifications[index].fromName) " + "hasEditedTheTransaction".localizeString() + " \(notifications[index].desc)"
            case .squaredUp:
                body = "youAreNowEvenWith".localizeString() + " \(notifications[index].fromName)"
            case .swishReminder:
                body = "\(notifications[index].fromName) " + "hasSentYouAReminder".localizeString()
            }
            let json: [String: Any] = [
                "message": [
                    "token": friend.deviceToken,
                    "notification": [
                        "title": "Budget",
                        "body": body
                    ]
                ]
            ]
            
            // URL Request
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            
            // Converting JSON dict to JSON
            request.httpBody = try? JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted])
            // Setting content type
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            // Setting authorization
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            
            // URL Session
            let session = URLSession(configuration: .default)
            
            session.dataTask(with: request) { data, response, error in
                if let error = error {
                    completion(error)
                    return
                }
                
                guard let response = response as? HTTPURLResponse else {
                    let info = "Found nil when extracting response in sendNotification in PushNotification"
                    completion(ApplicationError.unexpectedNil(info))
                    return
                }
                
                guard response.statusCode >= 200, response.statusCode < 300 else {
                    completion(HTTPError.badCode(response))
                    return
                }
                
                // Success
                self.sendNotifications(index: index + 1, notifications: notifications, friends: friends, completion: completion)
            }.resume()
        }
    }
    
    static func sendNotification(notification: Notification, friend: User, completion: @escaping (Error?) -> Void) {
        self.sendNotifications(notifications: [notification], friends: [friend], completion: completion)
    }
    
    static func getFriendFromId(id: String, friends: [User]) -> User? {
        for friend in friends {
            if friend.id == id {
                return friend
            }
        }
        return nil
    }
}
