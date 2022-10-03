//
//  TransactionsViewModel.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2022-09-28.
//

import Foundation
import Firebase

class TransactionsViewModel: ObservableObject {
    @Published var transactions: [Transaction] = []
    
    private var db = Firestore.firestore()
    
    var listener: ListenerRegistration?
    
    func fetchData(completion: @escaping (Error?) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {
            let info = "Found nil when extracting uid in fetchData in UserViewModel"
            print(info)
            completion(ApplicationError.unexpectedNil(info))
            return
        }
        self.listener = db.collection("Transactions").whereField("participants", arrayContains: uid)
            .addSnapshotListener { querySnapshot, error in
                guard let documents = querySnapshot?.documents else {
                    print("Error fetching documents: \(error!)")
                    completion(error!)
                    return
                }
                
                do {
                    
                    let data: [Transaction] = try documents.map { snapshot in
                        try snapshot.data(as: Transaction.self)
                    }
                    
                    // Success
                    self.transactions = data
                    completion(nil)
                } catch {
                    print("Something went wrong when fetching transactions documents: \(error)")
                    completion(error)
                }
        }
    }
}
