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
        Utility.removeListener(listener: self.listener)
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
                    self.addListener()
                    print("Successfully set standings in fetchData in StandingsViewModel")
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
    
    struct FireTransactionUpdate {
        var data: [AnyHashable: Any]
        var reference: DocumentReference
    }
    
    struct FireTransactionSet {
        var standing: Standing
        var reference: DocumentReference
    }
    
    func setStandings(transaction: Transaction, myUserName: String, myPhoneNumber: String, friends: [User], customFriends: [CustomFriend], delete: Bool = false, completion: @escaping (Error?) -> Void) {
        let standingIds = self.getStandingIds(transaction: transaction)
        
        self.db.runTransaction { fireTransaction, errorPointer in
            var updates: [FireTransactionUpdate] = .init()
            var sets: [FireTransactionSet] = .init()
            
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
                        let standingDocument: DocumentSnapshot
                        do {
                            try standingDocument = fireTransaction.getDocument(standingRef)
                        } catch let fetchError as NSError {
                            errorPointer?.pointee = fetchError
                            return nil
                        }
                        
                        if standingDocument.exists {
                            updates.append(FireTransactionUpdate(data: ["amounts.\(userId)": FieldValue.increment(amount)], reference: standingRef))
                            continue
                        }
                        guard let myId = Auth.auth().currentUser?.uid else {
                            let info = "Found nil when extracting displayName in setStandings in StandingsViewModel"
                            completion(ApplicationError.unexpectedNil(info))
                            return
                        }
                            
                        var userName1 = myUserName
                        var userName2 = myUserName
                        var phoneNumber1 = myPhoneNumber
                        var phoneNumber2 = myPhoneNumber
                            
                        if userId1 != myId {
                            guard let friend1 = self.findFriendById(userId: userId1, friends: friends, customFriends: customFriends) else {
                                let info = "Found nil when extracting friend1 in setStandings in StandingsViewModel"
                                completion(ApplicationError.unexpectedNil(info))
                                return
                            }
                            userName1 = friend1.name
                            phoneNumber1 = friend1.phone
                        }
                            
                        if userId2 != myId {
                            guard let friend2 = self.findFriendById(userId: userId2, friends: friends, customFriends: customFriends) else {
                                let info = "Found nil when extracting friend2 in setStandings in StandingsViewModel"
                                completion(ApplicationError.unexpectedNil(info))
                                return
                            }
                            userName2 = friend2.name
                            phoneNumber2 = friend2.phone
                        }
                            
                        let standing = Standing(
                            userId1: userId1,
                            userId2: userId2,
                            amount1: amount,
                            userName1: userName1,
                            userName2: userName2,
                            phoneNumber1: phoneNumber1,
                            phoneNumber2: phoneNumber2
                        )
                        sets.append(FireTransactionSet(standing: standing, reference: standingRef))
                    }
                }
            }
            
            for update in updates {
                fireTransaction.updateData(update.data, forDocument: update.reference)
            }
            for set in sets {
                do {
                    try fireTransaction.setData(from: set.standing, forDocument: set.reference)
                } catch let setError as NSError {
                    errorPointer?.pointee = setError
                    return nil
                }
            }
            
            return nil
        } completion: { _, error in
            if let error = error {
                completion(error)
                return
            }
            
            // Success
            completion(nil)
        }
    }
    
    func findFriendById(userId: String, friends: [User], customFriends: [CustomFriend]) -> (any Named)? {
        print(userId)
        for friend in friends {
            print(friend)
            if friend.id == userId {
                return friend
            }
        }
        for customFriend in customFriends {
            print(customFriend)
            if customFriend.id == userId {
                return customFriend
            }
        }
        
        return nil
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
    
    func getStandingAmount(myId: String, friendId: String) -> Double {
        for standing in self.standings {
            if standing.userIds.contains(myId) && standing.userIds.contains(friendId) {
                return standing.getStanding(myId: myId)
            }
        }
        return 0
    }
}
