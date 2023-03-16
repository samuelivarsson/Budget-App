//
//  TransactionsViewModel.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2022-09-28.
//

import Firebase
import Foundation

class TransactionsViewModel: ObservableObject {
    @Published var firstLoadFinished = false
    
    @Published var transactions: [Transaction] = []
    @Published var standings: [String: Double] = .init()
    
    private var db = Firestore.firestore()
    
    var listener: ListenerRegistration?
    
    func fetchData(monthStartsOn: Int, monthsBack: Int = 0, completion: @escaping (Error?) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {
            let info = "Found nil when extracting uid in fetchData in TransactionsViewModel"
            print(info)
            completion(ApplicationError.unexpectedNil(info))
            return
        }
        let referenceDate: Date = Utility.getBudgetPeriod(monthsBack: monthsBack, monthStartsOn: monthStartsOn).0
        // Remove old listener
        self.listener?.remove()
        // Add new listener
        self.listener = self.db.collection("Transactions").whereField("participantIds", arrayContains: uid).whereField("date", isGreaterThanOrEqualTo: referenceDate).order(by: "date", descending: true)
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
                    print("Successfully set transactions in TransactionsViewModel")
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
        // Remove old listener
        self.listener?.remove()
        // Add new listener
        self.listener = self.db.collection("Transactions").whereField("participantIds", arrayContains: uid).order(by: "date", descending: true)
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
                    print("Successfully set all transactions in TransactionsViewModel")
                    completion(nil)
                } catch {
                    print("Something went wrong when fetching transactions documents: \(error)")
                    completion(error)
                }
            }
    }
    
    func getSpent(user: User, transactionCategory: TransactionCategory? = nil, accountId: String? = nil) -> Double {
        var total: Double = 0
        let (from, to) = Utility.getBudgetPeriod(monthStartsOn: user.monthStartsOn)
        let thisMonthsTransactions = self.getTransactions(from: from, to: to)
        thisMonthsTransactions.forEach { transaction in
            if let transactionCategory = transactionCategory {
                if transaction.category.id == transactionCategory.id {
                    total += transaction.getShare(user: user)
                }
            }
            else if let accountId = accountId {
                if transaction.category.takesFromAccount == accountId {
                    total += transaction.getShare(user: user)
                }
            }
        }
        
        return total
    }
    
    func getTransactions(from: Date, to: Date) -> [Transaction] {
        return self.transactions.filter { $0.date >= from && $0.date < to }
    }
    
    func getStanding(friendId: String, myUid: String) -> Double {
        var total: Double = 0
        for transaction in self.transactions {
            // I am the payer
            if transaction.payerId == myUid {
                for participant in transaction.participants {
                    // Increase total if the participant is the friend in question
                    if participant.userId == friendId {
                        total += participant.amount
                    }
                }
            }
            
            // The friend is the payer
            else if transaction.payerId == friendId {
                for participant in transaction.participants {
                    // Decrease total if the participant is me
                    if participant.userId == myUid {
                        total -= participant.amount
                    }
                }
            }
        }
        
        return total
    }
}
