//
//  FirestoreViewModel.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2022-04-20.
//

import Firebase
import FirebaseAuth
import Foundation

class FirestoreViewModel: ObservableObject {
    @Published var phone: [String: String] = [:]
    
    let db = Firestore.firestore()
    
    init() {
        if let user = Auth.auth().currentUser {
            setPhoneDict(user: user) { error in
                if let error = error {
                    print("Error when initializing FirestoreViewModel: \(error.localizedDescription)")
                    return
                }
                
                // Success
                print("Successfully set phone dictionary at init in FirestoreViewModel")
            }
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
        db.collection("Users").whereField("email", isEqualTo: email.lowercased()).getDocuments { snapshot, error in
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
    
    func setUser(user: Firebase.User?, completion: @escaping (Error?) -> Void) {
        guard let user = user else {
            completion(AccountError.notSignedIn)
            return
        }
        
        db.collection("Users").document(user.uid).getDocument { snapshot, error in
            if let error = error {
                completion(error)
                return
            }
            
            let documentReference = self.db.collection("Users").document(user.uid)
            
            if snapshot!.exists {
                let userData: [String: Any] = [
                    "name": user.displayName ?? "",
                    "email": user.email ?? "",
                    "id": user.uid
                ]
                documentReference.setData(userData, merge: true) { error in
                    if let error = error {
                        completion(error)
                        return
                    }
                    
                    // Success
                    print("id: \(user.uid)")
                    completion(nil)
                }
            } else {
                let userData = User.getDummyUser(id: user.uid, name: user.displayName ?? "", email: user.email ?? "")
                do {
                    try documentReference.setData(from: userData) { error in
                        if let error = error {
                            completion(error)
                            return
                        }
                        
                        // Success
                        documentReference.updateData(["keywordsForLookup": userData.keywordsForLookup]) { error in
                            if let error = error {
                                completion(error)
                                return
                            }
                            
                            // Success
                            completion(nil)
                        }
                    }
                } catch {
                    completion(error)
                }
            }
        }
    }
    
    private func defaultTransactionCategories() -> [TransactionCategory] {
        let food = TransactionCategory(
            name: "food",
            type: .expense
        )

        let fika = TransactionCategory(
            name: "fika",
            type: .expense
        )

        let transportation = TransactionCategory(
            name: "transportation",
            type: .expense
        )

        let other = TransactionCategory(
            name: "other",
            type: .expense
        )

        let savingsAccountPurchase = TransactionCategory(
            name: "savingsAccountPurchase",
            type: .expense
        )
        
        let groceries = TransactionCategory(
            name: "groceries",
            type: .expense
        )

        let extraSaving = TransactionCategory(
            name: "extraSaving",
            type: .saving
        )
        
        let savingsAccount = TransactionCategory(
            name: "savingsAccount",
            type: .income
        )
        
        let swish = TransactionCategory(
            name: "swish",
            type: .income
        )

        let buffer = TransactionCategory(
            name: "buffer",
            type: .income
        )

        return [
            food,
            fika,
            transportation,
            other,
            savingsAccountPurchase,
            groceries,
            extraSaving,
            savingsAccount,
            swish,
            buffer
        ]
    }

    func setPhoneDict(user: Firebase.User?, completion: @escaping (Error?) -> Void) {
        guard let user = user else {
            completion(AccountError.notSignedIn)
            return
        }
        
        getUserFromUID(uid: user.uid) { userDict, error in
            if let error = error {
                completion(error)
                return
            }
            
            // Success
            guard let userDict = userDict else {
                let info = "Found nil when extracting user in setPhoneDict in FirestoreViewModel"
                print(info)
                completion(ApplicationError.unexpectedNil(info))
                return
            }
            
            guard let phone = userDict["phone"] as? String else {
                let info = "Found nil when extracting phone in setPhoneDict in FirestoreViewModel"
                print(info)
                completion(ApplicationError.unexpectedNil(info))
                return
            }
            self.phone[user.uid] = phone
            completion(nil)
        }
    }
    
    func updatePhone(with phoneText: String, user: Firebase.User?, completion: @escaping (Error?) -> Void) {
        guard let user = user else {
            let info = "Found nil when extracting user in updatePhone in FirestoreViewModel"
            print(info)
            completion(ApplicationError.unexpectedNil(info))
            return
        }

        let userData: [String: Any] = ["phone": phoneText]
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
