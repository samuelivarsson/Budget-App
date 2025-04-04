//
//  NextMonthChangesViewModel.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2024-08-07.
//

import Firebase
import FirebaseFirestore
import Foundation

class NextMonthChangesViewModel: ObservableObject {
    @Published var changes: [Any] = .init()
    
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
        self.listener = self.db.collection("NextMonthChanges").whereField("userId", isEqualTo: uid).addSnapshotListener { querySnapshot, error in
            if let error = error {
                completion(error)
                return
            }
            guard let documents = querySnapshot?.documents else {
                completion(FirestoreError.documentNotExist)
                return
            }
            
            // Succes
            self.changes = documents.compactMap { queryDocumentSnapshot in
                return queryDocumentSnapshot.data()["change"]
            }
            self.addListener()
            print("Successfully set nextMonthChanges in NextMonthChangesViewModel")
            completion(nil)
        }
    }
    
    func addListener() {
        if let listener = self.listener {
            Utility.listeners.append(listener)
        }
    }
    
    func addNextMonthChange(change: Any, completion: @escaping (Error?) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {
            let info = "Found nil when extracting uid in fetchData in NotificationsViewModel"
            print(info)
            completion(ApplicationError.unexpectedNil(info))
            return
        }
        
        let data = ["userId": uid, "change": change]
        self.db.collection("NextMonthChanges").addDocument(data: data) { error in
            if let error = error {
                completion(error)
                return
            }
            
            // Success
            completion(nil)
        }
    }
}
