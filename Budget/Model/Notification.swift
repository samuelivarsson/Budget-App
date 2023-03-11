//
//  Notification.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2022-10-23.
//

import Foundation
import Firebase
import FirebaseFirestoreSwift

struct Notification: Identifiable, Codable, Hashable {
    @DocumentID var documentId: String? = UUID().uuidString
    var type: NotificationType
    var from: String
    var fromName: String
    var to: String
    var read: Bool
    var date: Date
    var id: String { documentId ?? "" }
    
    init(type: NotificationType, from: String, fromName: String, to: String, read: Bool = false) {
        self.type = type
        self.from = from
        self.fromName = fromName
        self.to = to
        self.read = read
        self.date = Date()
    }
    
    func equals(notification: Notification) -> Bool {
        guard let id1 = self.documentId else {
            let info = "Found nil when extracting id1 in equals in Notification"
            print(info)
            return false
        }
        guard let id2 = self.documentId else {
            let info = "Found nil when extracting id2 in equals in Notification"
            print(info)
            return false
        }
        return id1 == id2
    }
}
