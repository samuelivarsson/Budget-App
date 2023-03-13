//
//  TransactionsViewModel.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2022-09-28.
//

import Firebase
import Foundation

class TransactionsViewModel: ObservableObject {
    @Published var transactions: [Transaction] = []
    
    private var db = Firestore.firestore()
    
    var listener: ListenerRegistration?
    
    func fetchData(monthStartsOn: Int, completion: @escaping (Error?) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {
            let info = "Found nil when extracting uid in fetchData in TransactionsViewModel"
            print(info)
            completion(ApplicationError.unexpectedNil(info))
            return
        }
        let referenceDate: Date = Utility.getBudgetPeriod(monthStartsOn: monthStartsOn).0
        listener = db.collection("Transactions").whereField("participantIds", arrayContains: uid).whereField("date", isGreaterThanOrEqualTo: referenceDate).order(by: "date", descending: true)
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
    
    func fetchAllData(completion: @escaping (Error?) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {
            let info = "Found nil when extracting uid in fetchData in TransactionsViewModel"
            print(info)
            completion(ApplicationError.unexpectedNil(info))
            return
        }
        listener = db.collection("Transactions").whereField("participantIds", arrayContains: uid).order(by: "date", descending: true)
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
    
    func getSpent(user: User, transactionCategoryAmount: TransactionCategoryAmount) -> Double {
        var total: Double = 0
        self.transactions.forEach { transaction in
            total += transaction.getShare(user: user)
        }
        
        return total
    }
}
