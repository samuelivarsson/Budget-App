//
//  StandingsViewModel.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2023-03-18.
//

import Firebase
import Foundation

class StandingsViewModel: ObservableObject {
    @Published var standings: [Standing] = []
    
    private var db = Firestore.firestore()
    
    var listener: ListenerRegistration?
    
    func fetchData(completion: @escaping (Error?) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {
            let info = "Found nil when extracting uid in fetchData in TransactionsViewModel"
            print(info)
            completion(ApplicationError.unexpectedNil(info))
            return
        }
        // Remove old listener
        self.listener?.remove()
        // Add new listener
        self.listener = self.db.collection("Standings").whereField("userIds", arrayContains: uid)
            .addSnapshotListener { querySnapshot, error in
                guard let documents = querySnapshot?.documents else {
                    print("Error fetching documents: \(error!)")
                    completion(error!)
                    return
                }
                
                do {
                    let data: [Standing] = try documents.map { snapshot in
                        try snapshot.data(as: Standing.self)
                    }
                    
                    // Success
                    self.standings = data
                    print("Successfully set standings in fetchData in StandingsViewModel")
                    completion(nil)
                } catch {
                    print("Something went wrong when fetching transactions documents: \(error)")
                    completion(error)
                }
            }
    }
    
    func getStandingId(standing: Standing) -> String {
        if standing.userIds.count < 2 {
            return ""
        }
        return self.getStandingId(userId1: standing.userIds[0], userId2: standing.userIds[1])
    }
    
    func getStandingId(userId1: String, userId2: String) -> String {
        return "\(min(userId1, userId2))\(max(userId1, userId2))"
    }
    
    func getStandingIds(transaction: Transaction) -> [String] {
        var standingIds: [String] = .init()
        
        for i in 0 ..< transaction.participants.count {
            for j in (i + 1) ..< transaction.participants.count {
                standingIds += [self.getStandingId(userId1: transaction.participants[i].userId, userId2: transaction.participants[j].userId)]
            }
        }
        
        return standingIds
    }
    
    func getUserIds(transaction: Transaction) -> [String] {
        var userIds: [String] = .init()
        for participant in transaction.participants {
            userIds += [participant.userId]
        }
        return userIds
    }
    
    func setStandings(transaction: Transaction, delete: Bool = false, completion: @escaping (Error?) -> Void) {
        let standingIds = self.getStandingIds(transaction: transaction)
            
        let batch = self.db.batch()
            
        for standingId in standingIds {
            for userId in self.getUserIds(transaction: transaction) {
                if !standingId.contains(userId) {
                    continue
                }
                var amount: Double = 0
                if userId == transaction.payerId {
                    let userId1 = userId
                    let userId2 = standingId.replacingOccurrences(of: userId, with: "")
                    
                    if delete {
                        amount -= transaction.getShare(userId: userId2)
                    } else {
                        amount += transaction.getShare(userId: userId2)
                    }
                    let standingRef = self.db.collection("Standings").document(standingId)
                    
                    if let _ = self.getStanding(userId1: userId1, userId2: userId2) {
                        batch.updateData(["amounts.\(userId)": FieldValue.increment(amount)], forDocument: standingRef)
                        continue
                    }
                    do {
                        try batch.setData(from: Standing(userId1: userId1, userId2: userId2), forDocument: standingRef, mergeFields: ["userIds"])
                        batch.updateData(["amounts.\(userId)": FieldValue.increment(amount)], forDocument: standingRef)
                    } catch {
                        completion(error)
                    }
                }
            }
        }
            
        batch.commit { error in
            if let error = error {
                completion(error)
                return
            }
                
            // Success
            completion(nil)
        }
    }
    
    func squareUp(myId: String, friendId: String, completion: @escaping (Error?) -> Void) {
        let standingId = self.getStandingId(userId1: myId, userId2: friendId)
        let standing = self.getStanding(userId1: myId, userId2: friendId)
        
        guard var standing = standing else {
            let info = "Found nil when extracting standing in squareUp in StandingsViewModel"
            completion(ApplicationError.unexpectedNil(info))
            return
        }
        
        guard let friendAmount = standing.amounts[friendId] else {
            let info = "Found nil when extracting friendAmount in squareUp in StandingsViewModel"
            completion(ApplicationError.unexpectedNil(info))
            return
        }
        
        standing.amounts[myId] = friendAmount
        do {
            try self.db.collection("Standings").document(standingId).setData(from: standing, completion: completion)
        } catch {
            completion(error)
        }
    }
    
    func getStanding(userId1: String, userId2: String) -> Standing? {
        for standing in self.standings {
            if standing.userIds.contains(userId1) && standing.userIds.contains(userId2) {
                return standing
            }
        }
        return nil
    }
}
