//
//  UserViewModel.swift
//  Budget
//
//  Created by Samuel Ivarsson on 2022-05-11.
//

import Firebase
import FirebaseFirestore
import Foundation

class UserViewModel: ObservableObject {
    @Published var user: User = .getDummyUser()
    @Published var friends: [User] = .init()
    @Published var favouriteIds: [String] = .init()
    @Published var groupIds: [String: String] = .init()
    @Published var friendRequests: [String] = .init()
    @Published var temporaryStandings: [CustomFriend] = .init()
    
    private var db = Firestore.firestore()
    
    var listener: ListenerRegistration?
    
    func fetchData(setFriends: Bool = true, completion: @escaping (Error?) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {
            let info = "Found nil when extracting uid in fetchData in UserViewModel"
            print(info)
            completion(ApplicationError.unexpectedNil(info))
            return
        }
        self.db.collection("Users").document(uid).getDocument { snapshot, error in
            if let error = error {
                completion(error)
                return
            }
            guard let snapshot = snapshot, snapshot.exists else {
                completion(FirestoreError.documentNotExist)
                return
            }
            // Remove old listener
            Utility.removeListener(listener: self.listener)
            // Add new listener
            self.listener = self.db.collection("Users").document(uid).addSnapshotListener { documentSnapshot, error in
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
                    print("Successfully set user in fetchData in UserViewModel")
                    self.user = data
                    if !setFriends {
                        completion(nil)
                        return
                    }
                    self.setFriends(from: data) { error in
                        if let error = error {
                            completion(error)
                            return
                        }
                        
                        // Success
                        self.addListener()
                        print("Successfully set friends in fetchData in UserViewModel")
                        completion(nil)
                    }
                } catch {
                    print("No document with id \(uid) found, error message: \(error)")
                    completion(error)
                }
            }
        }
    }
    
    func addListener() {
        if let listener = self.listener {
            Utility.listeners.append(listener)
        }
    }
    
    func setFriends(from data: User, completion: @escaping (Error?) -> Void) {
        if data.friends.count < 1 {
            self.friends = .init()
            self.friendRequests = .init()
            completion(nil)
            return
        }
        
        var friendsIds: [String] = .init()
        self.favouriteIds = .init()
        self.friendRequests = .init()
        data.friends.forEach { friend in
            switch friend.status {
            case .requested:
                self.friendRequests.append(friend.documentReference.documentID)
            case .friends:
                friendsIds.append(friend.documentReference.documentID)
                if friend.favourite {
                    self.favouriteIds.append(friend.documentReference.documentID)
                }
                self.groupIds[friend.id] = friend.group
            }
        }
        
        if friendsIds.count < 1 {
            self.friends = .init()
            completion(nil)
            return
        }
        
        self.db.collection("Users").whereField(FieldPath.documentID(), in: friendsIds).getDocuments { querySnapshot, error in
            if let error = error {
                completion(error)
                return
            }
            guard let documents = querySnapshot?.documents else {
                completion(FirestoreError.documentNotExist)
                return
            }
            
            // Success
            var exit = false
            let newFriends = documents.compactMap { queryDocumentSnapshot in
                do {
                    return try queryDocumentSnapshot.data(as: User.self)
                } catch {
                    print("Something went wrong when fetching friend document: \(error)")
                    print("Friend: ")
                    print("\n\(queryDocumentSnapshot.data())")
                    completion(error)
                    exit = true
                    return nil
                }
            }
            if exit {
                return
            }
            self.friends = newFriends.sorted(by: { $0.name.lowercased() < $1.name.lowercased() })
            completion(nil)
        }
    }
    
    func setUserData(friend: User? = nil, completion: @escaping (Error?) -> Void) {
        var user = self.user
        if let friend = friend {
            user = friend
        }
        do {
            try self.db.collection("Users").document(user.id).setData(from: user, merge: true) { error in
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
    
    func getUser(from uid: String, completion: @escaping (User?, Error?) -> Void) {
        self.db.collection("Users").document(uid).getDocument { snapshot, error in
            if let error = error {
                completion(nil, error)
                return
            }
            
            // Success
            do {
                let user = try snapshot?.data(as: User.self)
                completion(user, nil)
            } catch {
                completion(nil, error)
            }
        }
    }
    
    func addTransactionCategory(newTG: TransactionCategory, useRest: Bool = false, completion: @escaping (Error?) -> Void) {
        if useRest {
            self.user.budget.transactionCategoryThatUsesRest = newTG.id
        }
        
        self.user.budget.transactionCategories = self.user.budget.transactionCategories + [newTG]
        
        self.setUserData(completion: completion)
    }
    
    func editTransactionCategory(newTG: TransactionCategory, completion: @escaping (Error?) -> Void) {
        self.user.budget.transactionCategories = self.user.budget.transactionCategories.filter { $0.id != newTG.id } + [newTG]
        
        self.setUserData(completion: completion)
    }
    
    func deleteTransactionCategory(transactionCategory: TransactionCategory, completion: @escaping (Error?) -> Void) {
        self.user.budget.transactionCategories = self.user.budget.transactionCategories.filter { $0.id != transactionCategory.id }
        
        if transactionCategory.id == self.user.budget.transactionCategoryThatUsesRest {
            let transactionCategories = self.getTransactionCategoriesSorted()
            if transactionCategories.count < 1 {
                self.user.budget.transactionCategoryThatUsesRest = ""
            } else {
                self.user.budget.transactionCategoryThatUsesRest = transactionCategories[0].id
            }
        }
        
        self.setUserData(completion: completion)
    }
    
    func getTransactionCategory(id: String) -> TransactionCategory {
        let errorCategory = TransactionCategory(name: "error", type: .expense)
        let category = self.user.budget.transactionCategories.first { $0.id == id }
        return category ?? errorCategory
    }
    
    func addBudgetAccount(account: Account, completion: @escaping (Error?) -> Void) {
        self.user.budget.accounts = self.user.budget.accounts + [account]
        
        self.setUserData(completion: completion)
    }
    
    func editBudgetAccount(account: Account, completion: @escaping (Error?) -> Void) {
        self.user.budget.accounts = self.user.budget.accounts.filter { $0.id != account.id } + [account]
        
        self.setUserData(completion: completion)
    }
    
    func deleteBudgetAccount(account: Account, completion: @escaping (Error?) -> Void) {
        guard !self.transactionCategoryUsesAccount(account: account) else {
            completion(UserError.accountIsUsedByTransactionCategory)
            return
        }
        
        self.user.budget.accounts = self.user.budget.accounts.filter { $0.id != account.id }
        
        self.setUserData(completion: completion)
    }
    
    func addOverhead(overhead: Overhead, completion: @escaping (Error?) -> Void) {
        self.user.budget.overheads = self.user.budget.overheads + [overhead]
        
        self.setUserData(completion: completion)
    }
    
    func editOverhead(overhead: Overhead, completion: @escaping (Error?) -> Void) {
        self.user.budget.overheads = self.user.budget.overheads.filter { $0.id != overhead.id } + [overhead]
        
        self.setUserData(completion: completion)
    }
    
    func deleteOverhead(overhead: Overhead, completion: @escaping (Error?) -> Void) {
        self.user.budget.overheads = self.user.budget.overheads.filter { $0.id != overhead.id }
        
        self.setUserData(completion: completion)
    }
    
    func addQuickBalanceAccount(account: QuickBalanceAccount, completion: @escaping (Error?) -> Void) {
        self.user.quickBalanceAccounts = self.user.quickBalanceAccounts.filter { $0.budgetAccountId != account.budgetAccountId } + [account]
        
        self.setUserData(completion: completion)
    }
    
    func editQuickBalanceAccount(account: QuickBalanceAccount, completion: @escaping (Error?) -> Void) {
        self.user.quickBalanceAccounts = self.user.quickBalanceAccounts.filter { $0.budgetAccountId != account.budgetAccountId } + [account]
        
        self.setUserData(completion: completion)
    }
    
    func deleteQuickBalanceAccount(account: QuickBalanceAccount, completion: @escaping (Error?) -> Void) {
        self.user.quickBalanceAccounts = self.user.quickBalanceAccounts.filter { $0.budgetAccountId != account.budgetAccountId }
        
        self.setUserData(completion: completion)
    }
    
    func addFriendRequest(friend: User, completion: @escaping (Error?) -> Void) {
        // Create Friend object of the friend with .requested status
        let newFriend = Friend(documentReference: self.db.collection("Users").document(friend.id))
        // Add the friend to our friend list
        self.user.friends = self.user.friends + [newFriend]
        
        // Update our user data
        self.setUserData(completion: completion)
    }
    
    func acceptFriendRequest(notification: Notification, completion: @escaping (Error?) -> Void) {
        let friendUid = notification.from
        // Make the new friend to a Friend object
        let newFriend = Friend(
            documentReference: self.db.collection("Users").document(friendUid),
            status: .friends
        )
        // Add the friend to our friend list
        self.user.friends = self.user.friends + [newFriend]
        
        // Update our user data
        self.setUserData { error in
            if let error = error {
                completion(error)
                return
            }
            
            // Success
            // Create a Friend object of ourselves
            let myDocRef = self.db.collection("Users").document(self.user.id)
            let meFriend = Friend(documentReference: myDocRef, status: .friends)
            
            // Get User object of the friend
            self.getUser(from: friendUid) { friend, error in
                if let error = error {
                    completion(error)
                    return
                }
                guard var friend = friend else {
                    let info = "Found nil when extracting user in deleteFriend in UserViewModel"
                    completion(ApplicationError.unexpectedNil(info))
                    return
                }
                
                // Success
                // Add ourselves to their friend list
                friend.friends = friend.friends.filter { $0.documentReference.documentID != self.user.id } + [meFriend]
                
                // Update their user data
                self.setUserData(friend: friend) { error in
                    if let error = error {
                        completion(error)
                        return
                    }
                    
                    // Success
                    completion(nil)
                }
            }
        }
    }
    
    func denyFriendRequest(notification: Notification, completion: @escaping (Error?) -> Void) {
        let friendUid = notification.from
        
        // Get User object of the friend
        self.getUser(from: friendUid) { friend, error in
            if let error = error {
                completion(error)
                return
            }
            guard var friend = friend else {
                let info = "Found nil when extracting user in deleteFriend in UserViewModel"
                completion(ApplicationError.unexpectedNil(info))
                return
            }
            
            // Success
            // Remove ourselves from their friend list
            friend.friends = friend.friends.filter { $0.documentReference.documentID != self.user.id }
            
            // Update their user data
            self.setUserData(friend: friend) { error in
                if let error = error {
                    completion(error)
                    return
                }
                
                // Success
                completion(nil)
            }
        }
    }
    
    func cancelFriendRequest(friend: User, completion: @escaping (Error?) -> Void) {
        // Remove friend from friend list
        self.user.friends = self.user.friends.filter { $0.documentReference.documentID != friend.id }
        // Update our user data
        self.setUserData(completion: completion)
    }
    
    func deleteFriend(friend: User, completion: @escaping (Error?) -> Void) {
        // Remove friend from friend list
        self.user.friends = self.user.friends.filter { $0.documentReference.documentID != friend.id }
        // Update our user data
        self.setUserData(completion: completion)
    }
    
    func addCustomFriend(friend: CustomFriend, completion: @escaping (Error?) -> Void) {
        // Add friend to friend list
        self.user.customFriends = self.user.customFriends + [friend]
        // Update our user data
        self.setUserData(completion: completion)
    }
    
    func editCustomFriend(friend: CustomFriend, completion: @escaping (Error?) -> Void) {
        // Remove and then add new version of the friend to friend list
        self.user.customFriends = self.user.customFriends.filter { $0.id != friend.id } + [friend]
        // Update our user data
        self.setUserData(completion: completion)
    }
    
    func deleteCustomFriend(customFriend: CustomFriend, completion: @escaping (Error?) -> Void) {
        // Remove friend from friend list
        self.user.customFriends = self.user.customFriends.filter { $0.id != customFriend.id }
        // Update our user data
        self.setUserData(completion: completion)
    }
    
    func toggleFriendFavourite(friendId: String, completion: @escaping (Error?) -> Void) {
        // Make friend favourite
        let newFriend = self.user.friends.first(where: { $0.documentReference.documentID == friendId })
        
        guard var newFriend = newFriend else {
            let info = "Found nil when extracting newFriend in makeFriendFavourite in UserViewModel"
            completion(ApplicationError.unexpectedNil(info))
            return
        }
        
        newFriend.favourite = !newFriend.favourite
        self.user.friends = self.user.friends.filter { $0.documentReference.documentID != friendId } + [newFriend]
        // Update our user data
        self.setUserData { error in
            if let error = error {
                completion(error)
                return
            }
            
            // Success
            self.setFriends(from: self.user, completion: completion)
        }
    }
    
    func toggleCustomFriendFavourite(friendId: String, completion: @escaping (Error?) -> Void) {
        // Make friend favourite
        let newFriend = self.user.customFriends.first(where: { $0.id == friendId })
        
        guard var newFriend = newFriend else {
            let info = "Found nil when extracting newFriend in makeFriendFavourite in UserViewModel"
            completion(ApplicationError.unexpectedNil(info))
            return
        }
        
        newFriend.favourite = !newFriend.favourite
        self.user.customFriends = self.user.customFriends.filter { $0.id != friendId } + [newFriend]
        // Update our user data
        self.setUserData(completion: completion)
    }
    
    func isUserFriend(uid: String) -> Bool {
        return self.friends.contains { $0.id == uid }
    }
    
    func isUserRequested(uid: String) -> Bool {
        return self.friendRequests.contains(uid)
    }
    
    func isFriend(uid: String) -> Bool {
        return self.friends.contains { $0.id == uid } || self.user.customFriends.contains { $0.id == uid }
    }
    
    func isFriendFavourite(user: User) -> Bool {
        return self.favouriteIds.contains(user.id)
    }
    
    func isFriendFavourite(userId: String) -> Bool {
        for customFriend in self.user.customFriends {
            if customFriend.id == userId {
                return customFriend.favourite
            }
        }
        return self.favouriteIds.contains(userId)
    }
    
    func getPhoneFromFriendsFriend(friendId: String, completion: @escaping (String?, Error?) -> Void) {
        self.friends.forEach { friend in
            friend.friends.forEach { friendsFriend in
                let documentReference: DocumentReference = friendsFriend.documentReference
                if documentReference.documentID == friendId {
                    documentReference.getDocument(as: User.self) { result in
                        switch result {
                        case .success(let user):
                            completion(user.phone, nil)
                        case .failure(let error):
                            completion(nil, error)
                        }
                    }
                    return
                }
            }
            friend.customFriends.forEach { friendsCustomFriend in
                if friendsCustomFriend.id == friendId {
                    completion(friendsCustomFriend.phone, nil)
                    return
                }
            }
        }
        completion(nil, UserError.noFriendWithId)
    }
    
    func getFavouriteFriends() -> [User] {
        return self.friends.filter(self.isFriendFavourite)
    }
    
    func getFriendsSorted() -> [User] {
        return self.friends.sorted(by: { friend1, friend2 -> Bool in
            if self.isFriendFavourite(user: friend1) != self.isFriendFavourite(user: friend2) {
                return self.isFriendFavourite(user: friend1)
            } else {
                return friend1.name < friend2.name
            }
        })
    }
    
    func getFriendsSorted(favourites: Bool) -> [User] {
        if favourites {
            return self.getFriendsSorted().filter(self.isFriendFavourite)
        }
        return self.getFriendsSorted().filter { !self.isFriendFavourite(user: $0) }
    }
    
    func getCustomFriends() -> [CustomFriend] {
        return self.user.customFriends
    }
    
    func getCustomFriendsSorted(favourites: Bool = false) -> [CustomFriend] {
        let customFriends = self.getCustomFriends().sorted(by: { friend1, friend2 -> Bool in
            friend1.name.lowercased() < friend2.name.lowercased()
        })
        if favourites {
            return customFriends.filter { $0.favourite }
        }
        return customFriends
    }
    
    func getAllFriendsSorted(exceptFor: [Participant] = []) -> [any Named] {
        let sortedFriends: [any Named] = self.getFriendsSorted() + self.getCustomFriendsSorted()
        if exceptFor.isEmpty {
            return sortedFriends
        }
        return sortedFriends.filter { friend in
            !exceptFor.contains { $0.userId == friend.id }
        }
    }
    
    func getAllNonFavouriteFriendsSorted(exceptFor: [Participant] = []) -> [any Named] {
        let sortedFriends: [any Named] = self.getFriendsSorted() + self.getCustomFriendsSorted()
        if exceptFor.isEmpty {
            return sortedFriends.filter { friend in
                !self.isFriendFavourite(userId: friend.id)
            }
        }
        return sortedFriends.filter { friend in
            !exceptFor.contains { $0.userId == friend.id } && !self.isFriendFavourite(userId: friend.id)
        }
    }
    
    func getFavouritesSorted(exceptFor: [Participant] = []) -> [any Named] {
        let sortedFriends: [any Named] = self.getFriendsSorted(favourites: true) + self.getCustomFriendsSorted(favourites: true)
        if exceptFor.isEmpty {
            return sortedFriends
        }
        return sortedFriends.filter { friend in
            !exceptFor.contains { $0.userId == friend.id }
        }
    }
    
    func getFriendFromId(id: String) -> User? {
        for friend in self.friends {
            if friend.id == id {
                return friend
            }
        }
        return nil
    }
    
    func getTransactionCategoriesSorted(type: TransactionType? = nil) -> [TransactionCategory] {
        let sortedTG = self.user.budget.transactionCategories.sorted { $0.name.lowercased() < $1.name.lowercased() }
        
        if let type = type {
            return sortedTG.filter { $0.type == type }
        }
        
        return sortedTG
    }
    
    func setIncome(income: Double, completion: @escaping (Error?) -> Void) {
        // Update the income
        self.user.budget.income = income
        // Update our user data
        self.setUserData(completion: completion)
    }
    
    func setSavingsPercentage(savingsPercentage: Double, completion: @escaping (Error?) -> Void) {
        // Update the income
        self.user.budget.savingsPercentage = savingsPercentage
        // Update our user data
        self.setUserData(completion: completion)
    }
    
    func setSavingAmount(savingAmount: Double, accountId: String, completion: @escaping (Error?) -> Void) {
        // Update the income
        self.user.budget.savingAmounts[accountId] = savingAmount
        // Update our user data
        self.setUserData(completion: completion)
    }
    
    func setMonthStartsOn(day: Int, completion: @escaping (Error?) -> Void) {
        // Update the day
        self.user.budget.monthStartsOn = day
        // Update our user data
        self.setUserData(completion: completion)
    }
    
    func getAccounts() -> [Account] {
        return self.user.budget.accounts
    }
    
    func getAccounts(type: AccountType) -> [Account] {
        return self.getAccounts().filter { $0.type == type }
    }
    
    func getAccountsSorted() -> [Account] {
        return self.user.budget.accounts.sorted { $0.name.lowercased() < $1.name.lowercased() }
    }
    
    func getAccountsSorted(type: AccountType) -> [Account] {
        return self.getAccounts(type: type).sorted { $0.name.lowercased() < $1.name.lowercased() }
    }
    
    func getFirstTransactionCategory(type: TransactionType) -> TransactionCategory {
        let errorCategory = TransactionCategory(name: "Error", type: .expense)
        return self.getTransactionCategoriesSorted(type: type).first ?? errorCategory
    }
    
    func transactionCategoryUsesAccount(account: Account) -> Bool {
        for transactionCategory in self.getTransactionCategoriesSorted() {
            if transactionCategory.takesFromAccount == account.id || transactionCategory.givesToAccount == account.id {
                return true
            }
        }
        
        return false
    }
    
    func getBalance(accountId: String, spent: Double, incomes: Double, monthsBack: Int = 0) -> Double {
        return self.user.budget.getBalance(accountId: accountId, spent: spent, incomes: incomes, monthsBack: monthsBack)
    }
    
    func getOverheads() -> [Overhead] {
        return self.user.budget.overheads
    }
    
    func getOverheadsSorted() -> [Overhead] {
        return self.getOverheads().sorted { $0.name.lowercased() < $1.name.lowercased() }
    }
    
    func getSavingAmount(accountId: String) -> Double {
        return self.user.budget.getSavingAmount(accountId: accountId)
    }
    
    func getQuickBalanceAccounts() -> [QuickBalanceAccount] {
        return self.user.quickBalanceAccounts
    }
    
    func getQuickBalanceAccount(budgetAccountId: String) -> QuickBalanceAccount? {
        let accounts = self.user.quickBalanceAccounts.filter { $0.budgetAccountId == budgetAccountId }
        return accounts.first
    }
    
    func getFriendGroupsSorted() -> [String] {
        var friendGroups = self.getFriendGroups().sorted().filter { !$0.isEmpty }
        friendGroups.append("")
        return friendGroups
    }
    
    func getFriendGroups() -> [String] {
        var result = [String]()
        self.friends.forEach { friend in
            let group = self.getFriendGroup(friendId: friend.id)
            if !group.isEmpty {
                if !result.contains(group) {
                    result.append(group)
                }
            }
        }
        self.getCustomFriendsSorted().forEach { customFriend in
            if !result.contains(customFriend.group) {
                result.append(customFriend.group)
            }
        }
        return result
    }
    
    func getFriendGroup(friendId: String) -> String {
        for customFriend in self.user.customFriends {
            if customFriend.id == friendId {
                return customFriend.group
            }
        }
            
        return self.groupIds[friendId] ?? ""
    }
    
    func setFriendGroup(group: String, friendId: String, completion: @escaping (Error?) -> Void) {
        for i in 0..<self.user.friends.count {
            if self.user.friends[i].documentReference.documentID == friendId {
                self.user.friends[i].group = group
                print("hej")
            }
        }
        
        self.setUserData { error in
            if let error = error {
                completion(error)
                return
            }
            
            // Success
            self.user.friends.forEach { friend in
                if friend.documentReference.documentID == friendId {
                    self.groupIds[friendId] = friend.group
                }
            }
            completion(nil)
        }
    }
    
    func setCustomFriendGroup(group: String, friendId: String, completion: @escaping (Error?) -> Void) {
        for i in 0..<self.user.customFriends.count {
            if self.user.customFriends[i].id == friendId {
                self.user.customFriends[i].group = group
            }
        }
        
        self.setUserData(completion: completion)
    }
    
    func getName(friendId: String) -> String? {
        for friend in self.getAllFriendsSorted() {
            if friend.id == friendId {
                return friend.name
            }
        }
        return nil
    }
}
