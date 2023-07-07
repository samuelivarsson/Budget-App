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
        Utility.removeListener(listener: self.listener)
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
                    self.addListener()
                    print("Successfully set transactions in fetchData in TransactionsViewModel")
                    completion(nil)
                } catch {
                    print("Something went wrong when fetching transactions documents: \(error)")
                    completion(error)
                }
            }
    }
    
    func addListener() {
        if let listener = self.listener {
            Utility.listeners.append(listener)
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
                    print("Successfully set transactions in fetchAllData in TransactionsViewModel")
                    completion(nil)
                } catch {
                    print("Something went wrong when fetching transactions documents: \(error)")
                    completion(error)
                }
            }
    }
    
    func addTransaction(transaction: Transaction, completion: @escaping (Error?) -> Void) {
        do {
            try self.db.collection("Transactions").addDocument(from: transaction, completion: completion)
        } catch {
            completion(error)
        }
    }
    
    func editTransaction(transaction: Transaction, completion: @escaping (Error?) -> Void) {
        guard let documentId = transaction.documentId else {
            let info = "Found nil when extracting documentId in editTransaction in TransactionsViewModel"
            completion(ApplicationError.unexpectedNil(info))
            return
        }
        do {
            try self.db.collection("Transactions").document(documentId).setData(from: transaction, completion: completion)
        } catch {
            completion(error)
        }
    }
    
    func getSpent(user: User, transactionCategory: TransactionCategory? = nil, accountId: String? = nil, monthsBack: Int = 0) -> Double {
        var total: Double = 0
        let (from, to) = Utility.getBudgetPeriod(monthsBack: monthsBack, monthStartsOn: user.budget.monthStartsOn)
        let thisMonthsTransactions = self.getTransactions(from: from, to: to)
        thisMonthsTransactions.forEach { transaction in
            if let transactionCategory = transactionCategory {
                // Check if it's the correct transaction by id, could also be a friends category with same name
                let isNotMineButSameName = transaction.category.isNotMineButSameName(sameNameAs: transactionCategory, budget: user.budget)
                if transaction.category.id == transactionCategory.id || isNotMineButSameName {
                    total += transaction.getShare(userId: user.id)
                }
            } else if let accountId = accountId {
                let isNotMineButMainAccount = !transaction.isMine(userId: user.id) && user.budget.getMainAccountId(type: .transaction) == accountId
                if transaction.category.takesFromAccount == accountId || isNotMineButMainAccount {
                    total += transaction.getShare(userId: user.id)
                }
            }
        }
        
        return total
    }
    
    func getIncomes(user: User, accountId: String, monthsBack: Int = 0) -> Double {
        var total: Double = 0
        let (from, to) = Utility.getBudgetPeriod(monthsBack: monthsBack, monthStartsOn: user.budget.monthStartsOn)
        let thisMonthsTransactions = self.getTransactions(from: from, to: to)
        thisMonthsTransactions.forEach { transaction in
            if transaction.category.givesToAccount == accountId {
                total += transaction.getShare(userId: user.id)
            }
        }
        
        return total
    }
    
    func getTransactions(from: Date, to: Date) -> [Transaction] {
        return self.transactions.filter { $0.date >= from && $0.date < to }
    }
    
    func getTransactions(withParticipant: String) -> [Transaction] {
        return self.transactions.filter { $0.participantIds.contains(withParticipant) }
    }
    
    func getSwishInfo(myId: String, standing: Double, friend: any Named) -> String {
        var add = ""
        var sub = ""
        
        let transactionsWithFriend = self.getTransactions(withParticipant: friend.id)
        var sum: Double = 0
        for transaction in transactionsWithFriend {
            if transaction.payerId == myId {
                sum += transaction.getShare(userId: friend.id)
                if sub.count > 0 {
                    sub += "-" + transaction.desc
                } else {
                    sub = transaction.desc
                }
            } else {
                sum -= transaction.getShare(userId: myId)
                if add.count > 0 {
                    add += "+" + transaction.desc
                } else {
                    add = transaction.desc
                }
            }

            if round(sum*100) == round(standing*100) {
                let info = sub.count > 0 ? add + "-" + sub : add
                return info
            }
        }
        print(add+"-"+sub)
        
        return "squaringUpTransactions".localizeString()
    }
}
