//
//  UserViewModel.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2022-05-11.
//

import Foundation
import Firebase

class UserViewModel: ObservableObject {
    @Published var user: User?
    @Published var friends: [User] = [User]()
    
    private var db = Firestore.firestore()
    
    var listener: ListenerRegistration?
    
    func fetchData(completion: @escaping (Error?) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {
            let info = "Found nil when extracting uid in fetchData in UserViewModel"
            print(info)
            completion(ApplicationError.unexpectedNil(info))
            return
        }
        self.listener = db.collection("Users").document(uid).addSnapshotListener { documentSnapshot, error in
            guard let document = documentSnapshot else {
                // If querySnapshot is nil then error is not nil
                print("Error fetching document: \(error!)")
                completion(error!)
                return
            }

            // Succes
            do {
                let data = try document.data(as: User.self)
                
                // Success
                print("Successfully set user in UserViewModel")
                self.user = data
                
                // TODO - Move this to a separate function and make the friends array to a dict
                print("data friends: \(data.friends)")
                if data.friends.count > 0 {
                    for friendReference in data.friends {
                        friendReference.getDocument { friendSnapshot, error in
                            guard let friendSnapshot = friendSnapshot else {
                                completion(error!)
                                return
                            }
                            
                            do {
                                let friend = try friendSnapshot.data(as: User.self)
                                print(friend)
                                self.friends.append(friend)
                                print("self friends2: \(self.friends)")
                                completion(nil)
                            } catch {
                                print("Something went wrong when fetching friend document: \(error)")
                                completion(error)
                            }
                        }
                    }
                } else {
                    completion(nil)
                }
            } catch {
                print("No document with id \(uid) found, error message: \(error)")
                completion(error)
            }
        }
    }
    
    func setUserData(user: User, completion: @escaping (Error?) -> (Void)) {
        do {
            try self.db.collection("Users").document(user.uid).setData(from: user, merge: true) { error in
                if let error = error {
                    completion(error)
                    return
                }
                
                // Success
                completion(nil)
            }
        } catch {
            completion(error)
        }
    }
    
    func addTransactionCategory(newTG: TransactionCategory, completion: @escaping (Error?) -> (Void)) {
        guard var user = self.user else {
            let info = "Found nil when extracting user in addTransactionCategory in UserViewModel"
            completion(ApplicationError.unexpectedNil(info))
            return
        }
        
        user.transactionCategories = (user.transactionCategories ?? []) + [newTG]
        
        setUserData(user: user, completion: completion)
    }
    
    func editTransactionCategory(oldTG: TransactionCategory, newTG: TransactionCategory, completion: @escaping (Error?) -> (Void)) {
        guard var user = self.user else {
            let info = "Found nil when extracting user in editTransactionCategory in UserViewModel"
            completion(ApplicationError.unexpectedNil(info))
            return
        }
        
        user.transactionCategories = (user.transactionCategories?.filter({$0.id != oldTG.id}) ?? []) + [newTG]
        
        setUserData(user: user, completion: completion)
    }
    
    func deleteTransactionCategory(transactionCategory: TransactionCategory, completion: @escaping (Error?) -> (Void)) {
        guard var user = self.user else {
            let info = "Found nil when extracting user in deleteTransactionCategory in UserViewModel"
            completion(ApplicationError.unexpectedNil(info))
            return
        }
        
        user.transactionCategories = user.transactionCategories?.filter({$0.id != transactionCategory.id}) ?? []
        
        setUserData(user: user, completion: completion)
    }
}
