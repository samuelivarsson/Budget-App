//
//  NotificationsView.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2022-04-19.
//

import SwiftUI
import Firebase

enum NotificationType {
    case transaction
    case friendRequest
}

struct UserNotification {
    let user: String
    let type: NotificationType
}

struct TestUser: Identifiable, Hashable {
    let id = UUID()
    let name: String?
    let phone: String?
}

struct NotificationsView: View {
    private var notifications: [UserNotification]?
    
//    let db = Firestore.firestore()
    @State private var tests: [TestUser] = []
    
    var body: some View {
        List(tests, id: \.self) { test in
            Text(test.name ?? "what")
        }
        .onAppear {
//            db.collection("Users").getDocuments() { querySnapshot, err in
//                if let err = err {
//                    print("Error getting documents: \(err)")
//                    tests = [TestUser(name: "error", phone: "000")]
//                } else {
//                    for document in querySnapshot!.documents {
//                        print("\(document.documentID) => \(document.data())")
//                    }
//                }
//            }
        }
        .navigationTitle("notifications")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem {
                Button {
                    markAllAsRead()
                } label: {
                    Text("readAll")
                }
            }
        }
    }
    
//    private func test() {
//        db.collection("users").getDocuments() { querySnapshot, err in
//            if let err = err {
//                print("Error getting documents: \(err)")
//                self._tests = []
//            } else {
//                for document in querySnapshot!.documents {
//                    print("\(document.documentID) => \(document.data())")
//                }
//                self._tests = []
//            }
//        }
//    }
    
    private func markAllAsRead() {
        
    }
}

struct NotificationsView_Previews: PreviewProvider {
    static var previews: some View {
        NotificationsView()
    }
}
