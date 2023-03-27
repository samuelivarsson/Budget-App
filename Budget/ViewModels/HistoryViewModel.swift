//
//  HistoryViewModel.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2023-03-22.
//

import Firebase
import Foundation

class HistoryViewModel: ObservableObject {
    @Published var accountHistories: [AccountHistory] = .init()
    @Published var categoryHistories: [CategoryHistory] = .init()
    
    @Published var firstLoadFinished = false
    
    private var db = Firestore.firestore()
    
    var accountListener: ListenerRegistration?
    var categoryListener: ListenerRegistration?
    
    func fetchData(completion: @escaping (Error?) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {
            let info = "Found nil when extracting uid in fetchData in TransactionsViewModel"
            completion(ApplicationError.unexpectedNil(info))
            return
        }
        // Remove old listener
        self.accountListener?.remove()
        // Add new listener
        self.accountListener = self.db.collection("AccountHistories").whereField("userId", isEqualTo: uid).addSnapshotListener { querySnapshot, error in
            guard let documents = querySnapshot?.documents else {
                print("Error fetching documents: \(error!)")
                completion(error!)
                return
            }
                
            do {
                let data: [AccountHistory] = try documents.map { snapshot in
                    try snapshot.data(as: AccountHistory.self)
                }
                    
                // Success
                self.accountHistories = data
                print("Successfully set account histories in fetchData in HistoryViewModel")
                // Remove old listener
                self.categoryListener?.remove()
                // Add new listener
                self.categoryListener = self.db.collection("CategoryHistories").whereField("userId", isEqualTo: uid).addSnapshotListener { querySnapshot, error in
                    guard let documents = querySnapshot?.documents else {
                        print("Error fetching documents: \(error!)")
                        completion(error!)
                        return
                    }
                
                    do {
                        let data: [CategoryHistory] = try documents.map { snapshot in
                            try snapshot.data(as: CategoryHistory.self)
                        }
                    
                        // Success
                        self.categoryHistories = data
                        print("Successfully set category histories in fetchData in HistoryViewModel")
                        completion(nil)
                        return
                    } catch {
                        print("Something went wrong when fetching transactions documents: \(error)")
                        completion(error)
                    }
                }
            } catch {
                print("Something went wrong when fetching transactions documents: \(error)")
                completion(error)
            }
        }
    }
    
    func addHistories(accountHistories: [AccountHistory], categoryHistories: [CategoryHistory], completion: @escaping (Error?) -> Void) {
        let batch = self.db.batch()
        
        for accountHistory in accountHistories {
            let docRef = self.db.collection("AccountHistories").document()
            do {
                try batch.setData(from: accountHistory, forDocument: docRef)
            } catch {
                completion(error)
                return
            }
        }
        
        for categoryHistory in categoryHistories {
            let docRef = self.db.collection("CategoryHistories").document()
            do {
                try batch.setData(from: categoryHistory, forDocument: docRef)
            } catch {
                completion(error)
                return
            }
        }
        
        batch.commit(completion: completion)
    }
    
    func getPreviousAccountBalance(accountId: String) -> Double {
        guard let savingsAccountHistory = self.accountHistories.last(where: { $0.accountId == accountId }) else {
            return 0
        }
        return savingsAccountHistory.balance
    }
    
    func getCategoryAverage(categoryId: String) -> Double {
        if self.categoryHistories.count < 1 {
            return 0
        }
        let categoryHistory = self.categoryHistories.filter { $0.categoryId == categoryId }
        var total: Double = 0
        for history in categoryHistory {
            total += history.totalAmount
        }
        return total / Double(categoryHistory.count)
    }
    // TODO: - Add warning when deleting transaction category with history
}
