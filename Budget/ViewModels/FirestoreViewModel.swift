//
//  FirestoreViewModel.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2022-04-20.
//

import Foundation
import Firebase

class FirestoreViewModel: ObservableObject {
    @Published var phone: [String: String] = [:]
    
    let db = Firestore.firestore()
    
    init() {
        if let user = Auth.auth().currentUser {
            self.setPhoneDict(user: user) { error in
                if let error = error {
                    print("Error when initializing FirestoreViewModel: \(error.localizedDescription)")
                    return
                }
                
                // Success
                print("Successfully set phone dictionary at init in FirestoreViewModel")
            }
        } else {
            let info = "Found nil when extracting user in init in FirestoreViewModel"
            print("Error when initializing FirestoreViewModel: \(info)")
        }
    }
    
    func getUserFromUID(uid: String, completion: @escaping ([String: Any]?, Error?) -> Void) {
        db.collection("Users").document(uid).getDocument { snapshot, error in
            if let error = error {
                print("Error getting document: \(error)")
                completion(nil, error)
                return
            }
            guard let snapshot = snapshot else {
                let info = "Found nil when extracting snapshot in getUserFromEmail in FireStoreViewModel"
                print(info)
                completion(nil, ApplicationError.unexpectedNil(info))
                return
            }
            guard snapshot.exists else {
                completion(nil, FirestoreError.documentNotExist)
                return
            }
            
            completion(snapshot.data(), nil)
        }
    }
    
    func getUserFromEmail(email: String, completion: @escaping ([String: Any]?, Error?) -> Void) {
        db.collection("Users").whereField("email", isEqualTo: email.lowercased()).getDocuments() { snapshot, error in
            if let error = error {
                print("Error getting documents: \(error)")
                completion(nil, error)
                return
            }
            guard let snapshot = snapshot else {
                let info = "Found nil when extracting snapshot in getUserFromEmail in FireStoreViewModel"
                print(info)
                completion(nil, ApplicationError.unexpectedNil(info))
                return
            }
            guard !snapshot.documents.isEmpty, snapshot.documents[0].exists else {
                completion(nil, UserError.noUserWithEmail)
                return
            }
            
            completion(snapshot.documents[0].data(), nil)
        }
    }
    
    func setUser(user: User?, completion: @escaping (Error?) -> Void) {
        guard let user = user else {
            completion(AccountError.notSignedIn)
            return
        }
        
        let userData: [String: Any] = [
            "name": user.displayName ?? "",
            "email": user.email ?? "",
            "uid": user.uid
        ]
        db.collection("Users").document(user.uid).setData(userData, merge: true) { error in
            if let error = error {
                completion(error)
                return
            }
            
            // Success
            completion(nil)
        }
    }
    
    func setPhoneDict(user: User, completion: @escaping (Error?) -> Void) {
        self.getUserFromUID(uid: user.uid) { userDict, error in
            if let error = error {
                completion(error)
                return
            }
            
            // Success
            guard let userDict = userDict else {
                let info = "Found nil when extracting user in getPhone in FirestoreViewModel"
                print(info)
                completion(ApplicationError.unexpectedNil(info))
                return
            }
            guard let phone = userDict["phone"] as? String else {
                let info = "Found nil when extracting phone in getPhone in FirestoreViewModel"
                print(info)
                completion(ApplicationError.unexpectedNil(info))
                return
            }
            self.phone[user.uid] = phone
            completion(nil)
        }
    }
    
    func updatePhone(with phoneText: String, user: User, completion: @escaping (Error?) -> Void) {
        let userData: [String: Any] = [
            "name": user.displayName ?? "",
            "phone": phoneText,
            "email": user.email ?? "",
            "uid": user.uid
        ]
        db.collection("Users").document(user.uid).setData(userData, merge: true) { error in
            if let error = error {
                completion(error)
                return
            }
            
            // Success
            completion(nil)
            self.phone[user.uid] = phoneText
        }
    }
}
