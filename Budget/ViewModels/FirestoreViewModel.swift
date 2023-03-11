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
                    return
                }
            } else {
                let userData: User = User(
                    id: user.uid,
                    name: user.displayName ?? "",
                    email: user.email ?? "",
                    phone: "",
                    budget: Budget(accounts: [], income: 0, savingsPercentage: 0.5, transactionCategoryAmounts: [], overheads: [], overheadAccount: Account(name: "Overheads", type: .overhead)),
                    friends: [],
                    customFriends: [],
                    transactionCategories: self.defaultTransactionCategories()
                )
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
            type: .expense,
            useSavingsAccount: false,
            useBuffer: false
        )

        let fika = TransactionCategory(
            name: "fika",
            type: .expense,
            useSavingsAccount: false,
            useBuffer: false
        )

        let transportation = TransactionCategory(
            name: "transportation",
            type: .expense,
            useSavingsAccount: false,
            useBuffer: false
        )

        let other = TransactionCategory(
            name: "other",
            type: .expense,
            useSavingsAccount: false,
            useBuffer: false
        )

        let savingsAccountPurchase = TransactionCategory(
            name: "savingsAccountPurchase",
            type: .expense,
            useSavingsAccount: true,
            useBuffer: false
        )
        
        let groceries = TransactionCategory(
            name: "groceries",
            type: .expense,
            useSavingsAccount: false,
            useBuffer: false
        )

        let extraSaving = TransactionCategory(
            name: "extraSaving",
            type: .saving,
            useSavingsAccount: false,
            useBuffer: false
        )
        
        let savingsAccount = TransactionCategory(
            name: "savingsAccount",
            type: .income,
            useSavingsAccount: true,
            useBuffer: false
        )
        
        let swish = TransactionCategory(
            name: "swish",
            type: .income,
            useSavingsAccount: false,
            useBuffer: false
        )

        let buffer = TransactionCategory(
            name: "buffer",
            type: .income,
            useSavingsAccount: false,
            useBuffer: true
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
        
        self.getUserFromUID(uid: user.uid) { userDict, error in
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
